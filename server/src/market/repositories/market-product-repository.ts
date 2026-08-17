export const marketCategories = ['seeds', 'fertilizers', 'tools'] as const;
export const marketUnits = [
  'bag',
  'pack',
  'piece',
  'kg',
  'litre',
] as const;

export type MarketCategory = (typeof marketCategories)[number];
export type MarketUnit = (typeof marketUnits)[number];

/**
 * Seller-authored text per language code. `en` is required and acts as the
 * fallback for any locale a seller has not translated — a product name is
 * free text, so it cannot come from the app's compiled ARB catalogue.
 */
export type LocalizedText = { en: string } & Record<string, string>;

export interface MarketProductInput {
  name: LocalizedText;
  description: LocalizedText;
  category: MarketCategory;
  /** Whole rupees. */
  price: number;
  unit: MarketUnit;
  stockQuantity: number;
  vendor: string;
  /** Delisted products stay for order history but leave the catalogue. */
  isActive: boolean;
}

export interface MarketProductRecord extends MarketProductInput {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface MarketProductQuery {
  category?: MarketCategory;
  /** Substring match against the English name and the vendor. */
  search?: string;
}

export interface MarketProductRepository {
  listActive(query: MarketProductQuery): Promise<MarketProductRecord[]>;
  listAll(): Promise<MarketProductRecord[]>;
  findById(id: string): Promise<MarketProductRecord | null>;
  create(input: MarketProductInput, id?: string): Promise<MarketProductRecord>;
  update(id: string, input: MarketProductInput): Promise<MarketProductRecord>;
  delete(id: string): Promise<void>;
}
