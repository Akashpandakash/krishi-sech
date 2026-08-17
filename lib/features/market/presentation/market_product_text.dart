import 'package:flutter/material.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/l10n/l10n.dart';

extension MarketProductText on MarketProduct {
  String categoryName(BuildContext context) => switch (category) {
    MarketCategory.seeds => context.l10n.seeds,
    MarketCategory.fertilizers => context.l10n.fertilizers,
    MarketCategory.tools => context.l10n.tools,
  };

  String unitName(BuildContext context) => switch (unit) {
    MarketUnit.bag => context.l10n.marketBag,
    MarketUnit.pack => context.l10n.marketPack,
    MarketUnit.piece => context.l10n.marketPiece,
    MarketUnit.kg => context.l10n.marketKilogram,
    MarketUnit.litre => context.l10n.marketLitre,
  };

  String priceLabel(BuildContext context) =>
      context.l10n.marketPrice('₹$price', unitName(context));

  /// Products are seller-authored, so there is no per-product artwork to key
  /// on — the category is the only thing the app can illustrate honestly.
  IconData get icon => switch (category) {
    MarketCategory.seeds => Icons.grass,
    MarketCategory.fertilizers => Icons.compost,
    MarketCategory.tools => Icons.agriculture,
  };
}
