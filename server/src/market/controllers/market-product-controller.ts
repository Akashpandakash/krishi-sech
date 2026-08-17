import type { Request, Response } from 'express';

import { AppError } from '../../common/app-error.js';
import { sendSuccess } from '../../common/response.js';
import type { MarketProductService } from '../services/market-product-service.js';
import {
  marketProductIdSchema,
  marketProductQuerySchema,
} from '../validation/market-product-validation.js';

export class MarketProductController {
  constructor(private readonly service: MarketProductService) {}

  list = async (request: Request, response: Response) => {
    const { language, ...query } = marketProductQuerySchema.parse(
      request.query,
    );
    const products = await this.service.list(query, language);
    return sendSuccess(response, 200, 'Products retrieved successfully', {
      products,
      count: products.length,
    });
  };

  get = async (request: Request, response: Response) => {
    const { id } = marketProductIdSchema.parse(request.params);
    const { language } = marketProductQuerySchema.parse(request.query);
    const product = await this.service.get(id, language);
    if (!product) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }
    return sendSuccess(response, 200, 'Product retrieved successfully', product);
  };
}
