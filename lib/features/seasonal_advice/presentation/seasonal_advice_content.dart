import 'package:flutter/material.dart';
import 'package:krishi_sech/features/seasonal_advice/domain/entities/seasonal_advice.dart';
import 'package:krishi_sech/l10n/l10n.dart';

extension SeasonalAdviceContent on SeasonalAdvice {
  String category(BuildContext context) => switch (type) {
    SeasonalAdviceType.rain => context.l10n.adviceCategoryRain,
    SeasonalAdviceType.humidity => context.l10n.adviceCategoryCropHealth,
    SeasonalAdviceType.heat => context.l10n.adviceCategoryIrrigation,
    SeasonalAdviceType.wind => context.l10n.adviceCategorySpraying,
    SeasonalAdviceType.normal => context.l10n.adviceCategoryDailyFarming,
  };

  String title(BuildContext context) => switch (type) {
    SeasonalAdviceType.rain => context.l10n.rainAdviceTitle,
    SeasonalAdviceType.humidity => context.l10n.humidityAdviceTitle,
    SeasonalAdviceType.heat => context.l10n.heatAdviceTitle,
    SeasonalAdviceType.wind => context.l10n.windAdviceTitle,
    SeasonalAdviceType.normal => context.l10n.normalAdviceTitle,
  };

  String description(BuildContext context) => switch (type) {
    SeasonalAdviceType.rain => context.l10n.rainAdviceDescription,
    SeasonalAdviceType.humidity => context.l10n.humidityAdviceDescription,
    SeasonalAdviceType.heat => context.l10n.heatAdviceDescription,
    SeasonalAdviceType.wind => context.l10n.windAdviceDescription,
    SeasonalAdviceType.normal => context.l10n.normalAdviceDescription,
  };

  String reason(BuildContext context) => switch (type) {
    SeasonalAdviceType.rain => context.l10n.rainAdviceReason,
    SeasonalAdviceType.humidity => context.l10n.humidityAdviceReason,
    SeasonalAdviceType.heat => context.l10n.heatAdviceReason,
    SeasonalAdviceType.wind => context.l10n.windAdviceReason,
    SeasonalAdviceType.normal => context.l10n.normalAdviceReason,
  };

  String action(BuildContext context) => switch (type) {
    SeasonalAdviceType.rain => context.l10n.rainAdviceAction,
    SeasonalAdviceType.humidity => context.l10n.humidityAdviceAction,
    SeasonalAdviceType.heat => context.l10n.heatAdviceAction,
    SeasonalAdviceType.wind => context.l10n.windAdviceAction,
    SeasonalAdviceType.normal => context.l10n.normalAdviceAction,
  };

  IconData get icon => switch (type) {
    SeasonalAdviceType.rain => Icons.umbrella_outlined,
    SeasonalAdviceType.humidity => Icons.health_and_safety_outlined,
    SeasonalAdviceType.heat => Icons.water_drop_outlined,
    SeasonalAdviceType.wind => Icons.air,
    SeasonalAdviceType.normal => Icons.agriculture,
  };

  String warningLabel(BuildContext context) => switch (warningLevel) {
    AdviceWarningLevel.low => context.l10n.warningLow,
    AdviceWarningLevel.medium => context.l10n.warningMedium,
    AdviceWarningLevel.high => context.l10n.warningHigh,
  };
}
