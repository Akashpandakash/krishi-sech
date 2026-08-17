export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface PushDeliveryResult {
  delivered: number;
  failed: number;
  /** Tokens the transport reported as permanently invalid, safe to delete. */
  staleTokens: string[];
  failureReason: string | null;
}

export interface PushDeliveryProvider {
  readonly name: string;
  readonly configured: boolean;
  send(tokens: string[], message: PushMessage): Promise<PushDeliveryResult>;
}

/**
 * Used when no push transport is configured. Broadcasts still land in the
 * in-app inbox, which the app polls, so the feature degrades rather than fails.
 */
export class InboxOnlyPushDeliveryProvider implements PushDeliveryProvider {
  readonly name = 'inbox-only';
  readonly configured = false;

  constructor(private readonly loggingEnabled = false) {}

  async send(
    tokens: string[],
    message: PushMessage,
  ): Promise<PushDeliveryResult> {
    if (this.loggingEnabled) {
      console.log(
        JSON.stringify({
          event: 'push_delivery_skipped',
          reason: 'no_transport_configured',
          tokens: tokens.length,
          title: message.title,
        }),
      );
    }
    return {
      delivered: 0,
      failed: 0,
      staleTokens: [],
      failureReason: null,
    };
  }
}
