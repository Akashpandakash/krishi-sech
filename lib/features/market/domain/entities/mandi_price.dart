/// A set of mandi prices together with how complete it is.
///
/// When AGMARKNET is unreachable the backend still answers, with the rows an
/// operator entered by hand. Those are real prices but a sparse supplement to
/// the national feed, never a substitute for it — so the app has to show them
/// as an incomplete picture rather than as today's market.
class MandiPriceBoard {
  const MandiPriceBoard({required this.prices, required this.isLive});

  const MandiPriceBoard.live(this.prices) : isLive = true;

  final List<MandiPrice> prices;

  /// False when the national feed failed and [prices] holds operator-entered
  /// rows only. An empty list with [isLive] true is a different thing
  /// entirely: the feed answered and there were simply no arrivals.
  final bool isLive;

  bool get isPartial => !isLive && prices.isNotEmpty;
}

/// Direction of the modal price against the previous published day.
///
/// [unknown] is distinct from [stable]: the backend only reports a direction
/// once it holds an earlier price for the same market and commodity, and
/// showing "unchanged" for a comparison that was never made would be a lie.
enum PriceTrend { up, down, stable, unknown }

/// One commodity's price in one mandi, as published by AGMARKNET.
///
/// The commodity is free text rather than an enum: the national feed carries
/// several hundred commodities and it grows, so a closed set would silently
/// drop whatever a farmer actually grows.
class MandiPrice {
  const MandiPrice({
    required this.id,
    required this.commodity,
    required this.state,
    required this.district,
    required this.marketName,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
    required this.arrivalDate,
    required this.trend,
    this.variety,
    this.grade,
    this.previousModalPrice,
  });

  /// Identifies the price series (market + commodity), stable across days.
  final String id;
  final String commodity;
  final String? variety;
  final String? grade;
  final String state;
  final String district;
  final String marketName;
  final int minPrice;
  final int maxPrice;
  final int modalPrice;

  /// Always `quintal` for AGMARKNET, carried explicitly so the UI never
  /// assumes a unit the feed did not state.
  final String unit;

  /// The day the produce arrived at the mandi, which is the day the price
  /// belongs to — not the moment the app fetched it.
  final DateTime arrivalDate;
  final PriceTrend trend;
  final int? previousModalPrice;
}
