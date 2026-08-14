import type {
  IrrigationRecommendationRecord,
  IrrigationRecommendationRepository,
} from './irrigation-recommendation-repository.js';

export class InMemoryIrrigationRecommendationRepository
  implements IrrigationRecommendationRepository
{
  private readonly records: IrrigationRecommendationRecord[] = [];

  async save(input: IrrigationRecommendationRecord) {
    this.records.push(input);
    return input;
  }

  async findByUserAndCrop(userId: string, cropId: string) {
    return this.records
      .filter(
        (record) => record.userId === userId && record.cropId === cropId,
      )
      .sort(
        (left, right) => right.createdAt.getTime() - left.createdAt.getTime(),
      );
  }
}
