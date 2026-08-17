import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { DeviceService } from '../services/device-service.js';
import {
  registerDeviceSchema,
  unregisterDeviceSchema,
} from '../validation/device-validation.js';

export class DeviceController {
  constructor(private readonly service: DeviceService) {}

  register = async (request: AuthenticatedRequest, response: Response) => {
    const { token, platform } = registerDeviceSchema.parse(request.body);
    const device = await this.service.register(
      request.auth!.userId,
      token,
      platform,
    );
    return sendSuccess(response, 200, 'Device registered successfully', {
      id: device.id,
      platform: device.platform,
      updatedAt: device.updatedAt,
    });
  };

  list = async (request: AuthenticatedRequest, response: Response) => {
    const devices = await this.service.list(request.auth!.userId);
    return sendSuccess(
      response,
      200,
      'Devices retrieved successfully',
      devices.map((device) => ({
        id: device.id,
        platform: device.platform,
        createdAt: device.createdAt,
        updatedAt: device.updatedAt,
      })),
    );
  };

  unregister = async (request: AuthenticatedRequest, response: Response) => {
    const { token } = unregisterDeviceSchema.parse(request.body);
    await this.service.unregister(token);
    return sendSuccess(response, 200, 'Device unregistered successfully');
  };
}
