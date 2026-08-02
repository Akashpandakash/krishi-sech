import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/language_selection/presentation/pages/language_selection_page.dart';
import 'package:krishi_sech/features/login/presentation/pages/login_page.dart';
import 'package:krishi_sech/features/location/presentation/pages/manual_location_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/add_edit_crop_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/crop_details_page.dart';
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
      AppRoutes.home => const MainNavigationPage(),
      AppRoutes.myCrop => const MainNavigationPage(initialIndex: 1),
      AppRoutes.addCrop => const AddEditCropPage(),
      AppRoutes.editCrop => AddEditCropPage(
        cropId: settings.arguments! as String,
      ),
      AppRoutes.cropDetails => CropDetailsPage(
        cropId: settings.arguments! as String,
      ),
      AppRoutes.cropCalendar => const CropCalendarPage(),
      AppRoutes.addCropTask => AddEditCropTaskPage(
        initialDate: settings.arguments as DateTime?,
      ),
      AppRoutes.editCropTask => AddEditCropTaskPage(
        taskId: settings.arguments! as String,
      ),
      AppRoutes.aiAssistant => const MainNavigationPage(initialIndex: 2),
      AppRoutes.market => const MainNavigationPage(initialIndex: 3),
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
