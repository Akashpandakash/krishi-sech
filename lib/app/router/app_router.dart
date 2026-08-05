import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/language_selection/presentation/pages/language_selection_page.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_processing_page.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_result_page.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_scan_page.dart';
import 'package:krishi_sech/features/login/presentation/pages/login_page.dart';
import 'package:krishi_sech/features/login/presentation/pages/otp_page.dart';
import 'package:krishi_sech/features/location/presentation/pages/manual_location_page.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/presentation/pages/product_details_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/add_edit_crop_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/crop_details_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/add_edit_crop_health_record_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/crop_health_records_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/crop_calendar_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/add_edit_crop_task_page.dart';
import 'package:krishi_sech/features/weather/presentation/pages/weather_details_page.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/pages/seasonal_advice_details_page.dart';
import 'package:krishi_sech/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:krishi_sech/features/onboarding/presentation/pages/onboarding_second_placeholder_page.dart';
import 'package:krishi_sech/features/onboarding/presentation/pages/onboarding_third_page.dart';
import 'package:krishi_sech/features/shorts/presentation/pages/shorts_page.dart';
import 'package:krishi_sech/features/splash/presentation/pages/splash_page.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/pages/main_navigation_page.dart';

abstract final class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.splash => const SplashPage(),
      AppRoutes.onboarding => const OnboardingPage(),
      AppRoutes.onboardingSecond => const OnboardingSecondPlaceholderPage(),
      AppRoutes.onboardingThird => const OnboardingThirdPage(),
      AppRoutes.languageSelection => const LanguageSelectionPage(),
      AppRoutes.manualLocation => const ManualLocationPage(),
      AppRoutes.weatherDetails => const WeatherDetailsPage(),
      AppRoutes.seasonalAdviceDetails => const SeasonalAdviceDetailsPage(),
      AppRoutes.login => const LoginPage(),
      AppRoutes.otp => switch (settings.arguments) {
        final OtpPageArguments arguments => OtpPage(arguments: arguments),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.home => const MainNavigationPage(),
      AppRoutes.myCrop => const MainNavigationPage(initialIndex: 1),
      AppRoutes.addCrop => const AddEditCropPage(),
      AppRoutes.editCrop => switch (settings.arguments) {
        final String cropId => AddEditCropPage(cropId: cropId),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.cropDetails => switch (settings.arguments) {
        final String cropId => CropDetailsPage(cropId: cropId),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.cropHealthRecords => switch (settings.arguments) {
        final String cropId => CropHealthRecordsPage(cropId: cropId),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.addCropHealthRecord ||
      AppRoutes.editCropHealthRecord => switch (settings.arguments) {
        final CropHealthRecordFormArguments arguments =>
          AddEditCropHealthRecordPage(arguments: arguments),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.cropCalendar => const CropCalendarPage(),
      AppRoutes.addCropTask => AddEditCropTaskPage(
        initialDate: settings.arguments as DateTime?,
      ),
      AppRoutes.editCropTask => switch (settings.arguments) {
        final String taskId => AddEditCropTaskPage(taskId: taskId),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.aiAssistant => const MainNavigationPage(initialIndex: 2),
      AppRoutes.diseasePreview => switch (settings.arguments) {
        final DiseaseScanImageArguments arguments => DiseaseScanPage(
          arguments: arguments,
        ),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.diseaseProcessing => switch (settings.arguments) {
        final DiseaseScanImageArguments arguments => DiseaseProcessingPage(
          arguments: arguments,
        ),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.diseaseResult => switch (settings.arguments) {
        final DiseaseResultArguments arguments => DiseaseResultPage(
          arguments: arguments,
        ),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.market => const MainNavigationPage(initialIndex: 3),
      AppRoutes.marketProductDetails => switch (settings.arguments) {
        final MarketProduct product => ProductDetailsPage(product: product),
        _ => const _UnknownRoutePage(),
      },
      AppRoutes.shorts => const ShortsPage(),
      AppRoutes.profile => const MainNavigationPage(initialIndex: 4),
      _ => const _UnknownRoutePage(),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.l10n.pageNotFound)));
  }
}
