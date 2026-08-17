import {
  FcmPushDeliveryProvider,
  parseServiceAccount,
} from './fcm-push-delivery-provider.js';
import {
  InboxOnlyPushDeliveryProvider,
  type PushDeliveryProvider,
} from './push-delivery-provider.js';

/**
 * Picks the push transport from the environment. Without an FCM service
 * account, broadcasts still reach the in-app inbox, so nothing is blocked on
 * Firebase credentials being present.
 */
export function createPushDeliveryProvider(options: {
  serviceAccount: string | undefined;
  timeoutMs: number;
  loggingEnabled: boolean;
  production: boolean;
}): PushDeliveryProvider {
  let account: ReturnType<typeof parseServiceAccount> = null;
  try {
    account = parseServiceAccount(options.serviceAccount);
  } catch (error) {
    if (options.production) throw error;
    console.warn(
      JSON.stringify({
        event: 'fcm_service_account_invalid',
        message: error instanceof Error ? error.message : String(error),
      }),
    );
  }
  if (!account) return new InboxOnlyPushDeliveryProvider(options.loggingEnabled);
  return new FcmPushDeliveryProvider(account);
}
