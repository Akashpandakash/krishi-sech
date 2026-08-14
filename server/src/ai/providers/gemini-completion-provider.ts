import { AppError } from '../../common/app-error.js';
import type {
  AiCompletionMessage,
  AiCompletionProvider,
  AiCompletionResult,
  AiVisionDiagnosis,
  AiVisionProvider,
} from './ai-completion-provider.js';

interface GeminiPart {
  text?: string;
  inlineData?: { mimeType: string; data: string };
}

interface GeminiContent {
  role?: 'user' | 'model';
  parts: GeminiPart[];
}

interface GeminiResponse {
  modelVersion?: string;
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
    totalTokenCount?: number;
  };
  error?: { code?: number; status?: string; message?: string };
}

interface FarmingAdvisorOutput {
  answer: string;
  context_used: string[];
  missing_context: string[];
  follow_up_question: string | null;
}

/**
 * Gemini's responseSchema is an OpenAPI subset: it has no `additionalProperties`
 * and expresses optional values with `nullable` rather than a union type.
 */
const farmingAdvisorSchema = {
  type: 'object',
  properties: {
    answer: { type: 'string' },
    context_used: { type: 'array', items: { type: 'string' } },
    missing_context: { type: 'array', items: { type: 'string' } },
    follow_up_question: { type: 'string', nullable: true },
  },
  required: ['answer', 'context_used', 'missing_context', 'follow_up_question'],
};

const cropDiagnosisSchema = {
  type: 'object',
  properties: {
    crop: { type: 'string' },
    disease: { type: 'string' },
    confidence: { type: 'number' },
    severity: { type: 'string', enum: ['low', 'medium', 'high'] },
    symptoms: { type: 'array', items: { type: 'string' } },
    treatment: { type: 'array', items: { type: 'string' } },
    medicine: { type: 'array', items: { type: 'string' } },
    organicAlternative: { type: 'array', items: { type: 'string' } },
    prevention: { type: 'array', items: { type: 'string' } },
    expertConsultationRecommended: { type: 'boolean' },
  },
  required: [
    'crop', 'disease', 'confidence', 'severity', 'symptoms', 'treatment',
    'medicine', 'organicAlternative', 'prevention',
    'expertConsultationRecommended',
  ],
};

export class GeminiCompletionProvider
  implements AiCompletionProvider, AiVisionProvider
{
  private static readonly baseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';

  constructor(
    private readonly apiKey = process.env.GEMINI_API_KEY?.trim(),
    private readonly model = process.env.GEMINI_MODEL?.trim() ||
      'gemini-flash-latest',
    private readonly enabled = process.env.AI_ENABLED !== 'false',
    private readonly requestTimeoutMs = 20_000,
    private readonly loggingEnabled = process.env.LOGGING_ENABLED === 'true',
  ) {}

  async complete(messages: AiCompletionMessage[]): Promise<AiCompletionResult> {
    if (!this.enabled || !this.apiKey) {
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
    }
    try {
      const response = await this.generateContent(
        {
          systemInstruction: this.systemInstruction(messages),
          contents: this.conversation(messages),
          generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 2048,
            responseMimeType: 'application/json',
            responseSchema: farmingAdvisorSchema,
          },
        },
        this.requestTimeoutMs,
      );
      if (!response.ok) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      const body = (await response.json()) as GeminiResponse;
      const structured = this.parseJsonCandidate<FarmingAdvisorOutput>(body);
      const text = structured?.answer?.trim();
      if (!text) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      return {
        text,
        model: body.modelVersion ?? this.model,
        usage: body.usageMetadata
          ? {
              inputTokens: body.usageMetadata.promptTokenCount ?? 0,
              outputTokens: body.usageMetadata.candidatesTokenCount ?? 0,
              totalTokens: body.usageMetadata.totalTokenCount ?? 0,
            }
          : null,
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
    }
  }

  async analyzeCropImage(input: {
    image: Buffer;
    mimeType: string;
    language: 'bn' | 'en' | 'hi';
    context: object;
  }): Promise<AiVisionDiagnosis> {
    if (!this.enabled || !this.apiKey) {
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
    }
    const language = { bn: 'Bangla', en: 'English', hi: 'Hindi' }[
      input.language
    ];
    const geminiStarted = performance.now();
    try {
      this.visionLog('✓ step=7 Gemini Vision request sent');
      const response = await this.generateContent(
        {
          contents: [
            {
              role: 'user',
              parts: [
                {
                  text:
                    `Act as a professional crop pathologist. Respond in ${language}. ` +
                    'Analyze only visible evidence, use the farm context when relevant, ' +
                    'lower confidence when uncertain, and recommend expert consultation for severe, unclear, or safety-sensitive cases. ' +
                    'Report confidence as a number between 0 and 1. ' +
                    `FARM_CONTEXT=${JSON.stringify(input.context)}`,
                },
                {
                  inlineData: {
                    mimeType: input.mimeType,
                    data: input.image.toString('base64'),
                  },
                },
              ],
            },
          ],
          generationConfig: {
            maxOutputTokens: 4096,
            // Image diagnosis measured 84s with the model's default thinking
            // budget — past the timeout below — and 10s with it disabled.
            // A model that cannot disable thinking needs this value raised.
            thinkingConfig: { thinkingBudget: 0 },
            responseMimeType: 'application/json',
            responseSchema: cropDiagnosisSchema,
          },
        },
        60_000,
      );
      const responseText = await response.text();
      this.visionLog(
        `✓ step=8 Gemini response received status=${response.status} geminiLatencyMs=${Math.round(performance.now() - geminiStarted)}`,
      );
      const responseParseStarted = performance.now();
      let body: GeminiResponse;
      try {
        body = JSON.parse(responseText) as GeminiResponse;
      } catch {
        this.visionLog('✗ step=9 Gemini envelope JSON parsing failed');
        throw new AppError(
          502,
          'GEMINI_INVALID_RESPONSE',
          'Gemini returned invalid JSON',
        );
      }
      if (!response.ok) {
        const code = body.error?.status ?? `http_${response.status}`;
        const message = body.error?.message ?? 'Gemini Vision request failed';
        this.visionLog(
          `✗ step=8 Gemini error status=${response.status} code=${code} reason=${this.sanitize(message)}`,
        );
        throw new AppError(502, code, message);
      }
      const diagnosis = this.parseJsonCandidate<AiVisionDiagnosis>(body);
      if (!diagnosis) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      this.visionLog(
        `✓ step=9 diagnosis JSON parsed jsonParsingMs=${Math.round(performance.now() - responseParseStarted)}`,
      );
      return { ...diagnosis, confidence: this.clampConfidence(diagnosis.confidence) };
    } catch (error) {
      if (error instanceof AppError) throw error;
      const reason = error instanceof Error ? error.message : 'Unknown error';
      const timedOut = error instanceof Error && error.name === 'AbortError';
      const code = timedOut ? 'GEMINI_TIMEOUT' : 'GEMINI_TRANSPORT_ERROR';
      this.visionLog(
        `✗ step=8 Gemini transport failure code=${code} reason=${this.sanitize(reason)}`,
      );
      throw new AppError(
        timedOut ? 504 : 503,
        code,
        timedOut ? 'Gemini Vision request timed out' : reason,
      );
    }
  }

  /**
   * The shared `-latest` model aliases return a transient UNAVAILABLE under
   * load, so one retry is attempted. A timeout is never retried: it has already
   * consumed the caller's budget.
   */
  private async generateContent(
    body: {
      systemInstruction?: { parts: GeminiPart[] };
      contents: GeminiContent[];
      generationConfig: object;
    },
    timeoutMs: number,
  ): Promise<Response> {
    let lastResponse: Response | undefined;
    for (let attempt = 0; attempt < 2; attempt += 1) {
      if (attempt > 0) await this.delay(1_000);
      const response = await this.attempt(body, timeoutMs);
      if (!this.transient(response.status)) return response;
      lastResponse = response;
    }
    return lastResponse as Response;
  }

  private async attempt(
    body: object,
    timeoutMs: number,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
      return await fetch(
        `${GeminiCompletionProvider.baseUrl}/${encodeURIComponent(this.model)}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': this.apiKey ?? '',
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        },
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  /**
   * 5xx is a capacity spike a second call often clears. 429 is quota
   * exhaustion, where retrying only spends the remaining allowance twice.
   */
  private transient(status: number): boolean {
    return status >= 500;
  }

  private delay(milliseconds: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
  }

  /** Gemini splits a reply across parts; the schema makes the join valid JSON. */
  private parseJsonCandidate<T>(body: GeminiResponse): T | null {
    const text = (body.candidates?.[0]?.content?.parts ?? [])
      .map((part) => part.text ?? '')
      .join('')
      .trim();
    if (!text) return null;
    try {
      return JSON.parse(text) as T;
    } catch {
      return null;
    }
  }

  private systemInstruction(
    messages: AiCompletionMessage[],
  ): { parts: GeminiPart[] } | undefined {
    const system = messages
      .filter((message) => message.role === 'system')
      .map((message) => message.content)
      .join('\n');
    return system ? { parts: [{ text: system }] } : undefined;
  }

  private conversation(messages: AiCompletionMessage[]): GeminiContent[] {
    return messages
      .filter((message) => message.role !== 'system')
      .map((message) => ({
        role: message.role === 'assistant' ? ('model' as const) : ('user' as const),
        parts: [{ text: message.content }],
      }));
  }

  private clampConfidence(confidence: number): number {
    if (!Number.isFinite(confidence)) return 0;
    return Math.min(1, Math.max(0, confidence));
  }

  private visionLog(message: string) {
    if (this.loggingEnabled && process.env.NODE_ENV !== 'test') {
      console.log(`[AI Vision] ${message}`);
    }
  }

  private sanitize(message: string) {
    return message.replace(/\s+/g, ' ').trim().slice(0, 300);
  }
}
