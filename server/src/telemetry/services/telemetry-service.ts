import type { TelemetryConfig } from '../../config/telemetry-config.js';
import { GoogleAnalyticsProvider } from '../providers/analytics-provider.js';
import { CrashlyticsBigQueryProvider } from '../providers/crashlytics-provider.js';
import type {
  AnalyticsResponse,
  CrashResponse,
  NotConfigured,
} from '../telemetry-types.js';

/**
 * Fronts the two Google integrations behind one service.
 *
 * The guiding rule: never invent data. If an integration is not configured, or
 * the upstream call fails, that is reported as such — an operator must be able
 * to tell "nothing crashed" apart from "we cannot see crashes".
 */
export class TelemetryService {
  private readonly analytics: GoogleAnalyticsProvider | null;
  private readonly crashlytics: CrashlyticsBigQueryProvider | null;

  constructor(private readonly config: TelemetryConfig) {
    const { serviceAccount, ga4PropertyId, bigQueryProjectId, crashlyticsTable } =
      config;

    this.analytics =
      serviceAccount && ga4PropertyId
        ? new GoogleAnalyticsProvider(
            serviceAccount,
            ga4PropertyId,
            config.timeoutMs,
          )
        : null;

    this.crashlytics =
      serviceAccount && bigQueryProjectId && crashlyticsTable
        ? new CrashlyticsBigQueryProvider(
            serviceAccount,
            bigQueryProjectId,
            config.crashlyticsDataset,
            crashlyticsTable,
            config.timeoutMs,
          )
        : null;
  }

  private missingFor(integration: 'analytics' | 'crashlytics'): string[] {
    const missing: string[] = [];
    if (!this.config.serviceAccount) {
      missing.push('GOOGLE_TELEMETRY_SERVICE_ACCOUNT');
    }
    if (integration === 'analytics') {
      if (!this.config.ga4PropertyId) missing.push('GA4_PROPERTY_ID');
    } else {
      if (!this.config.bigQueryProjectId) missing.push('BIGQUERY_PROJECT_ID');
      if (!this.config.crashlyticsTable) {
        missing.push('CRASHLYTICS_BIGQUERY_TABLE');
      }
    }
    return missing;
  }

  private notConfigured(
    integration: 'analytics' | 'crashlytics',
    reason?: string,
  ): NotConfigured {
    const missing = this.missingFor(integration);
    return {
      configured: false,
      integration,
      reason:
        reason ??
        (missing.length > 0
          ? `Not configured: ${missing.join(', ')} ${
              missing.length === 1 ? 'is' : 'are'
            } not set.`
          : 'Not configured.'),
      missing,
    };
  }

  async analyticsReport(days: number): Promise<AnalyticsResponse> {
    if (!this.analytics) return this.notConfigured('analytics');
    try {
      return await this.analytics.report(days);
    } catch (error) {
      return this.notConfigured(
        'analytics',
        error instanceof Error ? error.message : 'Analytics request failed.',
      );
    }
  }

  async crashReport(days: number): Promise<CrashResponse> {
    if (!this.crashlytics) return this.notConfigured('crashlytics');
    try {
      return await this.crashlytics.report(days);
    } catch (error) {
      return this.notConfigured(
        'crashlytics',
        error instanceof Error ? error.message : 'Crashlytics request failed.',
      );
    }
  }
}
