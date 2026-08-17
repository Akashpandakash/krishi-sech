import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/l10n/l10n.dart';

/// AGMARKNET publishes commodity names in English only, and carries several
/// hundred of them. The app already translates the handful of staples farmers
/// filter by most, so those are mapped; anything else is shown as published
/// rather than dropped or left blank.
extension MandiPriceText on MandiPrice {
  String commodityLabel(BuildContext context) =>
      mandiCommodityLabel(context, commodity);
}

String mandiCommodityLabel(BuildContext context, String commodity) {
  return switch (commodity.trim().toLowerCase()) {
    'paddy' || 'paddy(dhan)(common)' || 'paddy(dhan)(basmati)' || 'rice' =>
      context.l10n.paddy,
    'wheat' => context.l10n.wheat,
    'maize' => context.l10n.maize,
    'mustard' || 'mustard seed' || 'rape seed' => context.l10n.mustard,
    'tomato' => context.l10n.tomato,
    'potato' => context.l10n.potato,
    'onion' => context.l10n.onion,
    _ => commodity,
  };
}
