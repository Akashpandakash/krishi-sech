import type {
  DevicePlatform,
  DeviceRecord,
  DeviceRepository,
} from '../repositories/device-repository.js';

export class DeviceService {
  constructor(private readonly repository: DeviceRepository) {}

  register(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceRecord> {
    return this.repository.register(userId, token, platform);
  }

  list(userId: string): Promise<DeviceRecord[]> {
    return this.repository.findByUser(userId);
  }

  /**
   * Unregistering is deliberately not scoped to the caller: the token proves
   * possession of the device, and a handset must be able to stop delivery on
   * logout even after the account it was attached to changed.
   */
  async unregister(token: string): Promise<void> {
    await this.repository.removeTokens([token]);
  }
}
