import type {
  FertilizerRecommendationDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  FertilizerRecommendationRecord,
  FertilizerRecommendationRepository,
} from './fertilizer-recommendation-repository.js';

function toRecord(
  document: FertilizerRecommendationDocument,
): FertilizerRecommendationRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoFertilizerRecommendationRepository
  implements FertilizerRecommendationRepository
{
  constructor(private readonly database: MongoDatabase) {}

  async save(
    input: FertilizerRecommendationRecord,
  ): Promise<FertilizerRecommendationRecord> {
    const { id, ...rest } = input;
    const document: FertilizerRecommendationDocument = { ...rest, _id: id };
    await this.database.fertilizerRecommendations.insertOne(document);
    return toRecord(document);
  }

  async findByUserAndCrop(
    userId: string,
    cropId: string,
  ): Promise<FertilizerRecommendationRecord[]> {
    const documents = await this.database.fertilizerRecommendations
      .find({ userId, cropId })
      .sort({ createdAt: -1 })
      .toArray();
    return documents.map(toRecord);
  }
}
