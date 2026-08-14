import { AppError } from '../../common/app-error.js';
import type {
  AiCompletionMessage,
  AiCompletionProvider,
  AiCompletionResult,
  AiVisionDiagnosis,
  AiVisionProvider,
} from './ai-completion-provider.js';

interface OpenAiChatResponse {
  model?: string;
  choices?: Array<{ message?: { content?: string } }>;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
    total_tokens?: number;
  };
}

interface FarmingAdvisorOutput {
  answer: string;
  context_used: string[];
  missing_context: string[];
  follow_up_question: string | null;
}

const farmingAdvisorSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    answer: { type: 'string' },
    context_used: { type: 'array', items: { type: 'string' } },
    missing_context: { type: 'array', items: { type: 'string' } },
    follow_up_question: { type: ['string', 'null'] },
  },
  required: [
    'answer',
    'context_used',
    'missing_context',
    'follow_up_question',
  ],
};

export class OpenAiCompletionProvider
  implements AiCompletionProvider, AiVisionProvider
{
  constructor(
    private readonly apiKey = process.env.OPENAI_API_KEY?.trim(),
    private readonly model = process.env.OPENAI_MODEL?.trim() || 'gpt-4o-mini',
    private readonly enabled = process.env.OPENAI_ENABLED !== 'false',
    private readonly requestTimeoutMs = 20_000,
    private readonly loggingEnabled = process.env.LOGGING_ENABLED === 'true',
  ) {}

  async complete(messages: AiCompletionMessage[]): Promise<AiCompletionResult> {
    if (!this.enabled || !this.apiKey) {
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.requestTimeoutMs);
    try {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          messages,
          temperature: 0.3,
          max_tokens: 500,
          response_format: {
            type: 'json_schema',
            json_schema: {
              name: 'smart_farming_advice',
              strict: true,
              schema: farmingAdvisorSchema,
            },
          },
        }),
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      const body = (await response.json()) as OpenAiChatResponse;
      const content = body.choices?.[0]?.message?.content?.trim();
      if (!content) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      const structured = JSON.parse(content) as FarmingAdvisorOutput;
      const text = structured.answer?.trim();
      if (!text) {
        throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      }
      return {
        text,
        model: body.model ?? this.model,
        usage: body.usage
          ? {
              inputTokens: body.usage.prompt_tokens ?? 0,
              outputTokens: body.usage.completion_tokens ?? 0,
              totalTokens: body.usage.total_tokens ?? 0,
            }
          : null,
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
    } finally {
      clearTimeout(timeout);
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
    const schema = {
      type: 'object',
      additionalProperties: false,
      properties: {
        crop: { type: 'string' },
        disease: { type: 'string' },
        confidence: { type: 'number', minimum: 0, maximum: 1 },
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
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 60_000);
    const openAiStarted = performance.now();
    try {
      this.visionLog('✓ step=7 OpenAI Vision request sent');
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          messages: [{
            role: 'user',
            content: [
              {
                type: 'text',
                text:
                  `Act as a professional crop pathologist. Respond in ${language}. ` +
                  'Analyze only visible evidence, use the farm context when relevant, ' +
                  'lower confidence when uncertain, and recommend expert consultation for severe, unclear, or safety-sensitive cases. ' +
                  `FARM_CONTEXT=${JSON.stringify(input.context)}`,
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${input.mimeType};base64,${input.image.toString('base64')}`,
                  detail: 'high',
                },
              },
            ],
          }],
          max_tokens: 900,
          response_format: {
            type: 'json_schema',
            json_schema: { name: 'crop_disease_diagnosis', strict: true, schema },
          },
        }),
        signal: controller.signal,
      });
      const responseText = await response.text();
      this.visionLog(
        `✓ step=8 OpenAI response received status=${response.status} openAiLatencyMs=${Math.round(performance.now() - openAiStarted)}`,
      );
      const responseParseStarted = performance.now();
      let body: OpenAiChatResponse & { error?: { code?: string; message?: string } };
      try {
        body = JSON.parse(responseText) as typeof body;
      } catch {
        this.visionLog('✗ step=9 OpenAI envelope JSON parsing failed');
        throw new AppError(502, 'OPENAI_INVALID_RESPONSE', 'OpenAI returned invalid JSON');
      }
      if (!response.ok) {
        const code = body.error?.code ?? `http_${response.status}`;
        const message = body.error?.message ?? 'OpenAI Vision request failed';
        this.visionLog(`✗ step=8 OpenAI error status=${response.status} code=${code} reason=${this.sanitize(message)}`);
        throw new AppError(502, code, message);
      }
      const content = body.choices?.[0]?.message?.content;
      if (!content) throw new AppError(503, 'AI_UNAVAILABLE', 'AI service is unavailable');
      const diagnosis = JSON.parse(content) as AiVisionDiagnosis;
      this.visionLog(
        `✓ step=9 diagnosis JSON parsed jsonParsingMs=${Math.round(performance.now() - responseParseStarted)}`,
      );
      return diagnosis;
    } catch (error) {
      if (error instanceof AppError) throw error;
      const reason = error instanceof Error ? error.message : 'Unknown error';
      const timedOut = error instanceof Error && error.name === 'AbortError';
      const code = timedOut ? 'OPENAI_TIMEOUT' : 'OPENAI_TRANSPORT_ERROR';
      this.visionLog(`✗ step=8 OpenAI transport failure code=${code} reason=${this.sanitize(reason)}`);
      throw new AppError(timedOut ? 504 : 503, code, timedOut ? 'OpenAI Vision request timed out' : reason);
    } finally {
      clearTimeout(timeout);
    }
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
