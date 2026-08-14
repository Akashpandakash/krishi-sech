import { AppError } from '../../common/app-error.js';
import type { CropRepository } from '../../crops/repositories/crop-repository.js';
import type {
  CalendarTaskInput,
  CalendarTaskRepository,
} from '../repositories/calendar-task-repository.js';

export class CalendarTaskService {
  constructor(
    private readonly repository: CalendarTaskRepository,
    private readonly cropRepository: CropRepository,
  ) {}

  async create(userId: string, input: CalendarTaskInput) {
    await this.requireOwnedCrop(input.cropId, userId);
    return this.repository.create(userId, input);
  }

  list(userId: string) {
    return this.repository.findAllByUser(userId);
  }

  async update(
    userId: string,
    id: string,
    input: Omit<CalendarTaskInput, 'id'>,
  ) {
    await this.requireTask(id, userId);
    await this.requireOwnedCrop(input.cropId, userId);
    return this.repository.update(id, userId, input);
  }

  async delete(userId: string, id: string) {
    await this.requireTask(id, userId);
    await this.repository.delete(id, userId);
  }

  private async requireTask(id: string, userId: string) {
    const task = await this.repository.findByIdAndUser(id, userId);
    if (!task) {
      throw new AppError(404, 'CALENDAR_TASK_NOT_FOUND', 'Calendar task not found');
    }
    return task;
  }

  private async requireOwnedCrop(cropId: string, userId: string) {
    const crop = await this.cropRepository.findByIdAndUser(cropId, userId);
    if (!crop) throw new AppError(404, 'CROP_NOT_FOUND', 'Crop not found');
  }
}
