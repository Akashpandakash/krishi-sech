/** One market's price for one commodity on one arrival date, as published. */
export interface MandiPriceQuote {
  state: string;
  district: string;
  market: string;
  commodity: string;
  variety: string | null;
  grade: string | null;
  /** Date the produce arrived at the mandi, normalised to UTC midnight. */
  arrivalDate: Date;
  /** Rupees per quintal, as published by AGMARKNET. */
  minPrice: number;
  maxPrice: number;
  modalPrice: number;
}

export interface MandiPriceQuery {
  state: string;
  district?: string;
  commodity?: string;
}

export interface MandiPriceProvider {
  /** Latest published quotes for a state, optionally narrowed further. */
  fetchQuotes(query: MandiPriceQuery): Promise<MandiPriceQuote[]>;
}
