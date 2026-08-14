import { AppError } from '../../common/app-error.js';
import type {
  CropInput,
  CropRepository,
} from '../repositories/crop-repository.js';

export class CropService {
  constructor(private readonly repository: CropRepository) {}

  create(userId: string, input: CropInput, idempotencyKey?: string) {
    return this.repository.create(userId, input, idempotencyKey);
  }

  list(userId: string) {
    return this.repository.findAllByUser(userId);
  }

  async get(userId: string, id: string) {
    const crop = await this.repository.findByIdAndUser(id, userId);
    if (!crop) throw this.notFound();
    return crop;
  }

  async update(userId: string, id: string, input: CropInput) {
    await this.get(userId, id);
    return this.repository.update(id, userId, input);
  }

  async delete(userId: string, id: string): Promise<void> {
    await this.get(userId, id);
    await this.repository.delete(id, userId);
  }

  private notFound() {
    return new AppError(404, 'CROP_NOT_FOUND', 'Crop not found');
  }
}
