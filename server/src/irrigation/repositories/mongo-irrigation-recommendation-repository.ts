import type {
  IrrigationRecommendationDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  IrrigationRecommendationRecord,
  IrrigationRecommendationRepository,
} from './irrigation-recommendation-repository.js';

function toRecord(
  document: IrrigationRecommendationDocument,
): IrrigationRecommendationRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoIrrigationRecommendationRepository
  implements IrrigationRecommendationRepository
{
  constructor(private readonly database: MongoDatabase) {}

  async save(
    input: IrrigationRecommendationRecord,
  ): Promise<IrrigationRecommendationRecord> {
    const { id, ...rest } = input;
    const document: IrrigationRecommendationDocument = { ...rest, _id: id };
    await this.database.irrigationRecommendations.insertOne(document);
    return toRecord(document);
  }

  async findByUserAndCrop(
    userId: string,
    cropId: string,
  ): Promise<IrrigationRecommendationRecord[]> {
    const documents = await this.database.irrigationRecommendations
      .find({ userId, cropId })
      .sort({ createdAt: -1 })
      .lean();
    return documents.map(toRecord);
  }
}
