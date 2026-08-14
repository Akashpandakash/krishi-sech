import type {
  FertilizerRecommendationRecord,
  FertilizerRecommendationRepository,
} from './fertilizer-recommendation-repository.js';

export class InMemoryFertilizerRecommendationRepository
  implements FertilizerRecommendationRepository
{
  private readonly records: FertilizerRecommendationRecord[] = [];

  async save(input: FertilizerRecommendationRecord) {
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
