import 'package:flutter/material.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/l10n/l10n.dart';

extension MarketProductText on MarketProduct {
  String name(BuildContext context) => switch (kind) {
    MarketProductKind.premiumWheatSeeds => context.l10n.premiumWheatSeeds,
    MarketProductKind.organicFertilizer => context.l10n.organicFertilizer,
    MarketProductKind.gardenSprayer => context.l10n.gardenSprayer,
    MarketProductKind.tomatoSeeds => context.l10n.tomatoSeeds,
  };

  String description(BuildContext context) => switch (kind) {
    MarketProductKind.premiumWheatSeeds =>
      context.l10n.premiumWheatSeedsDescription,
    MarketProductKind.organicFertilizer =>
      context.l10n.organicFertilizerDescription,
    MarketProductKind.gardenSprayer => context.l10n.gardenSprayerDescription,
    MarketProductKind.tomatoSeeds => context.l10n.tomatoSeedsDescription,
  };

  String categoryName(BuildContext context) => switch (category) {
    MarketCategory.seeds => context.l10n.seeds,
    MarketCategory.fertilizers => context.l10n.fertilizers,
    MarketCategory.tools => context.l10n.tools,
  };

  String unitName(BuildContext context) => switch (unit) {
    MarketUnit.bag => context.l10n.marketBag,
    MarketUnit.pack => context.l10n.marketPack,
    MarketUnit.piece => context.l10n.marketPiece,
  };

  String priceLabel(BuildContext context) =>
      context.l10n.marketPrice('₹$price', unitName(context));

  IconData get icon => switch (kind) {
    MarketProductKind.premiumWheatSeeds => Icons.grass,
    MarketProductKind.organicFertilizer => Icons.compost,
    MarketProductKind.gardenSprayer => Icons.agriculture,
    MarketProductKind.tomatoSeeds => Icons.eco,
  };
}
