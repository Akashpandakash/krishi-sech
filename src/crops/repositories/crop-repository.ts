export const growthStages = [
  'sowing',
  'germination',
  'seedling',
  'vegetative',
  'flowering',
  'fruiting',
  'maturity',
  'harvested',
] as const;
export const landUnits = ['acre', 'hectare', 'bigha', 'katha'] as const;
export const soilTypes = [
  'alluvial',
  'black',
  'red',
  'laterite',
  'sandy',
  'clay',
  'loamy',
  'other',
] as const;
export const irrigationMethods = [
  'drip',
  'sprinkler',
  'flood',
  'rainFed',
  'manual',
] as const;
export const cropHealthStatuses = [
  'healthy',
  'moderate',
  'needsAttention',
] as const;

export interface CropInput {
  cropName: string;
  variety: string;
  sowingDate: Date;
  growthStage: (typeof growthStages)[number];
  landArea: number;
  landUnit: (typeof landUnits)[number];
  soilType: (typeof soilTypes)[number];
  irrigationMethod: (typeof irrigationMethods)[number];
  expectedHarvestDate: Date | null;
  healthStatus: (typeof cropHealthStatuses)[number];
  notes: string | null;
}

export interface CropRecord extends CropInput {
  id: string;
  userId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CropRepository {
  create(userId: string, input: CropInput, id?: string): Promise<CropRecord>;
  findAllByUser(userId: string): Promise<CropRecord[]>;
  findByIdAndUser(id: string, userId: string): Promise<CropRecord | null>;
  update(id: string, userId: string, input: CropInput): Promise<CropRecord>;
  delete(id: string, userId: string): Promise<void>;
}
