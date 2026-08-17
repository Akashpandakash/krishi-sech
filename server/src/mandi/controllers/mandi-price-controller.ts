import type { Request, Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { MandiPriceService } from '../services/mandi-price-service.js';
import { mandiPriceQuerySchema } from '../validation/mandi-price-validation.js';

export class MandiPriceController {
  constructor(private readonly service: MandiPriceService) {}

  list = async (request: Request, response: Response) => {
    const query = mandiPriceQuerySchema.parse(request.query);
    const { prices, live } = await this.service.prices(query);
    return sendSuccess(response, 200, 'Mandi prices retrieved successfully', {
      prices,
      // An empty list is a legitimate answer — a district may simply have had
      // no arrivals — so the app needs to tell it apart from a failure.
      count: prices.length,
      // False means AGMARKNET is down and these are admin-entered rows only:
      // real prices, but an incomplete picture the app must label as such.
      live,
    });
  };
}
