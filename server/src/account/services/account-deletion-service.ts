import { AppError } from '../../common/app-error.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import type {
  AccountDeletionRepository,
  AccountDeletionSummary,
} from '../repositories/account-deletion-repository.js';

export interface DeletionOutcome {
  userId: string;
  summary: AccountDeletionSummary;
}

export class AccountDeletionService {
  constructor(
    private readonly authService: AuthService,
    private readonly repository: AccountDeletionRepository,
    private readonly loggingEnabled = false,
  ) {}

  /** Step one of the web flow: send a one-time code to the account's number. */
  requestOtp(phone: string, requestId?: string) {
    return this.authService.sendOtp(phone, false, requestId);
  }

  /** Step two: the code proves ownership, then the account is erased. */
  async confirmWithOtp(
    phone: string,
    code: string,
    reason?: string,
  ): Promise<DeletionOutcome> {
    const user = await this.authService.confirmOtpOwnership(phone, code);
    return this.purge(user.id, 'web_otp', reason);
  }

  /** In-app deletion, already authenticated by the access token. */
  async deleteAuthenticated(
    userId: string,
    reason?: string,
  ): Promise<DeletionOutcome> {
    return this.purge(userId, 'in_app', reason);
  }

  /** Admin-initiated removal, e.g. a support request that came in by phone. */
  async deleteByAdmin(userId: string, reason: string): Promise<DeletionOutcome> {
    return this.purge(userId, 'admin', reason);
  }

  private async purge(
    userId: string,
    channel: 'web_otp' | 'in_app' | 'admin',
    reason?: string,
  ): Promise<DeletionOutcome> {
    let summary: AccountDeletionSummary;
    try {
      summary = await this.repository.purge(userId);
    } catch (error) {
      throw new AppError(
        500,
        'ACCOUNT_DELETION_FAILED',
        error instanceof Error ? error.message : 'Account deletion failed',
      );
    }
    if (this.loggingEnabled) {
      // The reason is free text from the account holder and is deliberately
      // not stored anywhere that survives the deletion.
      console.log(
        JSON.stringify({
          event: 'account_deleted',
          channel,
          hasReason: Boolean(reason?.trim()),
          removed: summary,
        }),
      );
    }
    return { userId, summary };
  }
}
