import type {
  LocalizedText,
  MarketCategory,
  MarketProductInput,
  MarketProductQuery,
  MarketProductRecord,
  MarketProductRepository,
  MarketUnit,
} from '../repositories/market-product-repository.js';

/** One product as the app renders it: text already resolved to one language. */
export interface MarketProductView {
  id: string;
  name: string;
  description: string;
  category: MarketCategory;
  price: number;
  unit: MarketUnit;
  stockQuantity: number;
  vendor: string;
  isAvailable: boolean;
}

function resolve(text: LocalizedText, language: string | undefined): string {
  if (!language) return text.en;
  // `pa_IN` and `pa` are the same catalogue entry as far as a seller is
  // concerned, so match the base subtag before giving up on English.
  const base = language.toLowerCase().split(/[-_]/)[0]!;
  return text[language] ?? text[base] ?? text.en;
}

export class MarketProductService {
  constructor(private readonly repository: MarketProductRepository) {}

  async list(
    query: MarketProductQuery,
    language?: string,
  ): Promise<MarketProductView[]> {
    const products = await this.repository.listActive(query);
    return products.map((product) => this.toView(product, language));
  }

  async get(
    id: string,
    language?: string,
  ): Promise<MarketProductView | null> {
    const product = await this.repository.findById(id);
    if (!product || !product.isActive) return null;
    return this.toView(product, language);
  }

  listAll(): Promise<MarketProductRecord[]> {
    return this.repository.listAll();
  }

  create(input: MarketProductInput): Promise<MarketProductRecord> {
    return this.repository.create(input);
  }

  update(id: string, input: MarketProductInput): Promise<MarketProductRecord> {
    return this.repository.update(id, input);
  }

  delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }

  private toView(
    product: MarketProductRecord,
    language: string | undefined,
  ): MarketProductView {
    return {
      id: product.id,
      name: resolve(product.name, language),
      description: resolve(product.description, language),
      category: product.category,
      price: product.price,
      unit: product.unit,
      stockQuantity: product.stockQuantity,
      vendor: product.vendor,
      isAvailable: product.stockQuantity > 0,
    };
  }
}
