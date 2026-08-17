import {
  parseGoogleServiceAccount,
  type GoogleServiceAccount,
} from '../common/google-service-account.js';

export interface TelemetryConfig {
  /** Shared by both integrations; falls back to the FCM account, which is
   *  usually the same Firebase service account. */
  serviceAccount: GoogleServiceAccount | null;
  /** Numeric GA4 property id. Not the Firebase app id, and not `G-XXXX`. */
  ga4PropertyId: string | null;
  bigQueryProjectId: string | null;
  crashlyticsDataset: string;
  crashlyticsTable: string | null;
  timeoutMs: number;
}

export function loadTelemetryConfig(
  values: NodeJS.ProcessEnv = process.env,
): TelemetryConfig {
  const raw =
    values.GOOGLE_TELEMETRY_SERVICE_ACCOUNT?.trim() ||
    values.FCM_SERVICE_ACCOUNT?.trim();

  let serviceAccount: GoogleServiceAccount | null = null;
  try {
    serviceAccount = parseGoogleServiceAccount(
      raw,
      'GOOGLE_TELEMETRY_SERVICE_ACCOUNT',
    );
  } catch (error) {
    // A malformed key must not stop the API booting — the telemetry screen
    // reports it instead.
    serviceAccount = null;
    if (values.LOGGING_ENABLED === 'true') {
      console.warn(
        JSON.stringify({
          event: 'telemetry_service_account_invalid',
          message: error instanceof Error ? error.message : String(error),
        }),
      );
    }
  }

  const timeout = Number.parseInt(values.TELEMETRY_TIMEOUT_MS ?? '', 10);

  return {
    serviceAccount,
    ga4PropertyId: values.GA4_PROPERTY_ID?.trim() || null,
    bigQueryProjectId:
      values.BIGQUERY_PROJECT_ID?.trim() || serviceAccount?.project_id || null,
    crashlyticsDataset:
      values.CRASHLYTICS_BIGQUERY_DATASET?.trim() || 'firebase_crashlytics',
    crashlyticsTable: values.CRASHLYTICS_BIGQUERY_TABLE?.trim() || null,
    timeoutMs: Number.isFinite(timeout) && timeout > 0 ? timeout : 30_000,
  };
}
