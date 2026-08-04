export interface AiCompletionResult {
  text: string;
  model: string;
  usage: {
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
  } | null;
}

export interface AiCompletionMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface AiCompletionProvider {
  complete(messages: AiCompletionMessage[]): Promise<AiCompletionResult>;
}

export interface AiVisionDiagnosis {
  crop: string;
  disease: string;
  confidence: number;
  severity: 'low' | 'medium' | 'high';
  symptoms: string[];
  treatment: string[];
  medicine: string[];
  organicAlternative: string[];
  prevention: string[];
  expertConsultationRecommended: boolean;
}

export interface AiVisionProvider {
  analyzeCropImage(input: {
    image: Buffer;
    mimeType: string;
    language: 'bn' | 'en' | 'hi';
    context: object;
  }): Promise<AiVisionDiagnosis>;
}
