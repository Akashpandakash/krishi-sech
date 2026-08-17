export const devicePlatforms = ['android', 'ios', 'web'] as const;
export type DevicePlatform = (typeof devicePlatforms)[number];

export interface DeviceRecord {
  id: string;
  userId: string;
  token: string;
  platform: DevicePlatform;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceRepository {
  /**
   * Upserts by token: a device that was signed into another account must move
   * to the current one rather than deliver that account's notifications.
   */
  register(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceRecord>;
  findByUser(userId: string): Promise<DeviceRecord[]>;
  removeTokens(tokens: string[]): Promise<void>;
  /** Registered device counts per platform, for the broadcast reach panel. */
  countByPlatform(): Promise<Record<DevicePlatform, number>>;
}
