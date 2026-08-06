import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_sa.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('brx'),
    Locale('doi'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('sa'),
    Locale('sat'),
    Locale('sd'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Krishi Sech'**
  String get appTitle;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'KRISHI SECH'**
  String get splashTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Farming, Secure Future'**
  String get splashTagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Krishi Sech'**
  String get onboardingWelcome;

  /// No description provided for @onboarding1HeadingLine1.
  ///
  /// In en, this message translates to:
  /// **'Smart Farming'**
  String get onboarding1HeadingLine1;

  /// No description provided for @onboarding1HeadingLine2.
  ///
  /// In en, this message translates to:
  /// **'Starts Here'**
  String get onboarding1HeadingLine2;

  /// No description provided for @onboarding1Description.
  ///
  /// In en, this message translates to:
  /// **'Manage your entire farming journey\nfrom planning to harvest in one\npowerful app.'**
  String get onboarding1Description;

  /// No description provided for @planBetter.
  ///
  /// In en, this message translates to:
  /// **'Plan\nBetter'**
  String get planBetter;

  /// No description provided for @growBetter.
  ///
  /// In en, this message translates to:
  /// **'Grow\nBetter'**
  String get growBetter;

  /// No description provided for @sellBetter.
  ///
  /// In en, this message translates to:
  /// **'Sell\nBetter'**
  String get sellBetter;

  /// No description provided for @earnBetter.
  ///
  /// In en, this message translates to:
  /// **'Earn\nBetter'**
  String get earnBetter;

  /// No description provided for @allInOneApp.
  ///
  /// In en, this message translates to:
  /// **'All in One App'**
  String get allInOneApp;

  /// No description provided for @allInOneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need as a farmer at your fingertips.'**
  String get allInOneSubtitle;

  /// No description provided for @onboarding2HeadingLine1.
  ///
  /// In en, this message translates to:
  /// **'Your AI'**
  String get onboarding2HeadingLine1;

  /// No description provided for @onboarding2HeadingLine2.
  ///
  /// In en, this message translates to:
  /// **'Farming Partner'**
  String get onboarding2HeadingLine2;

  /// No description provided for @onboarding2Description.
  ///
  /// In en, this message translates to:
  /// **'Detect crop diseases early, receive weather alerts, get fertilizer recommendations and instant AI support for every farming decision.'**
  String get onboarding2Description;

  /// No description provided for @plantDoctor.
  ///
  /// In en, this message translates to:
  /// **'Plant Doctor'**
  String get plantDoctor;

  /// No description provided for @cropLooksHealthy.
  ///
  /// In en, this message translates to:
  /// **'Crop looks healthy'**
  String get cropLooksHealthy;

  /// No description provided for @diseaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Disease\nDetection'**
  String get diseaseDetection;

  /// No description provided for @scanCrops.
  ///
  /// In en, this message translates to:
  /// **'Scan crops'**
  String get scanCrops;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather\nAlerts'**
  String get weatherAlerts;

  /// No description provided for @stayPrepared.
  ///
  /// In en, this message translates to:
  /// **'Stay prepared'**
  String get stayPrepared;

  /// No description provided for @irrigationAdvice.
  ///
  /// In en, this message translates to:
  /// **'Irrigation\nAdvice'**
  String get irrigationAdvice;

  /// No description provided for @saveWater.
  ///
  /// In en, this message translates to:
  /// **'Save water'**
  String get saveWater;

  /// No description provided for @fertilizerGuide.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer\nGuide'**
  String get fertilizerGuide;

  /// No description provided for @growBetterShort.
  ///
  /// In en, this message translates to:
  /// **'Grow better'**
  String get growBetterShort;

  /// No description provided for @aiAssistant247.
  ///
  /// In en, this message translates to:
  /// **'24×7 AI Assistant'**
  String get aiAssistant247;

  /// No description provided for @aiAssistant247Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions anytime, in your own language.'**
  String get aiAssistant247Subtitle;

  /// No description provided for @onboarding3HeadingLine1.
  ///
  /// In en, this message translates to:
  /// **'Sell Smarter.'**
  String get onboarding3HeadingLine1;

  /// No description provided for @onboarding3HeadingLine2.
  ///
  /// In en, this message translates to:
  /// **'Earn More.'**
  String get onboarding3HeadingLine2;

  /// No description provided for @onboarding3Description.
  ///
  /// In en, this message translates to:
  /// **'Sell your crops directly to buyers,\nwholesalers and exporters with secure\npayments, logistics and transparent pricing.'**
  String get onboarding3Description;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure\nPayment'**
  String get securePayment;

  /// No description provided for @localCollection.
  ///
  /// In en, this message translates to:
  /// **'Local\nCollection'**
  String get localCollection;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @wholesaler.
  ///
  /// In en, this message translates to:
  /// **'Wholesaler'**
  String get wholesaler;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @safeAndFast.
  ///
  /// In en, this message translates to:
  /// **'Safe & fast'**
  String get safeAndFast;

  /// No description provided for @smartLogistics.
  ///
  /// In en, this message translates to:
  /// **'Smart\nLogistics'**
  String get smartLogistics;

  /// No description provided for @doorstepHelp.
  ///
  /// In en, this message translates to:
  /// **'Doorstep help'**
  String get doorstepHelp;

  /// No description provided for @verifiedBuyers.
  ///
  /// In en, this message translates to:
  /// **'Verified\nBuyers'**
  String get verifiedBuyers;

  /// No description provided for @tradeSafely.
  ///
  /// In en, this message translates to:
  /// **'Trade safely'**
  String get tradeSafely;

  /// No description provided for @exportOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Export\nOpportunity'**
  String get exportOpportunity;

  /// No description provided for @reachGlobally.
  ///
  /// In en, this message translates to:
  /// **'Reach globally'**
  String get reachGlobally;

  /// No description provided for @fieldToWorld.
  ///
  /// In en, this message translates to:
  /// **'From Your Field to the World'**
  String get fieldToWorld;

  /// No description provided for @fieldToWorldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We take care of everything,\nyou focus on farming.'**
  String get fieldToWorldSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Preferred Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your language to continue'**
  String get languageSubtitle;

  /// No description provided for @searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguages;

  /// No description provided for @translationPendingReview.
  ///
  /// In en, this message translates to:
  /// **'English fallback • Translation pending review'**
  String get translationPendingReview;

  /// No description provided for @languageStatusFullyTranslated.
  ///
  /// In en, this message translates to:
  /// **'Fully translated'**
  String get languageStatusFullyTranslated;

  /// No description provided for @languageStatusEnglishFallback.
  ///
  /// In en, this message translates to:
  /// **'English fallback'**
  String get languageStatusEnglishFallback;

  /// No description provided for @translationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Translation coming soon'**
  String get translationComingSoon;

  /// No description provided for @fallbackLanguageNotice.
  ///
  /// In en, this message translates to:
  /// **'{language} is selected. Full translation is coming soon, so the app will use English for now.'**
  String fallbackLanguageNotice(String language);

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get bangla;

  /// No description provided for @banglaNative.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get banglaNative;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @hindiNative.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindiNative;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Krishi Sech'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your simple companion for smarter farming'**
  String get loginSubtitle;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @authVerifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get authVerifyOtp;

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP'**
  String get authOtpLabel;

  /// No description provided for @authOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to {phone}'**
  String authOtpSent(String phone);

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit OTP.'**
  String get authInvalidOtp;

  /// No description provided for @authOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection and retry.'**
  String get authOffline;

  /// No description provided for @authTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please retry.'**
  String get authTimeout;

  /// No description provided for @authRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication could not be completed. Please retry.'**
  String get authRequestFailed;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get enterMobileNumber;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get termsNotice;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get navMyCrops;

  /// No description provided for @navAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get navAiAssistant;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Important farming updates will appear here.'**
  String get noNotificationsDescription;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded.'**
  String get notificationsLoadError;

  /// No description provided for @notificationWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain expected today'**
  String get notificationWeatherTitle;

  /// No description provided for @notificationWeatherMessage.
  ///
  /// In en, this message translates to:
  /// **'Rain is likely this afternoon. Consider delaying irrigation.'**
  String get notificationWeatherMessage;

  /// No description provided for @notificationCropTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop task reminder'**
  String get notificationCropTaskTitle;

  /// No description provided for @notificationCropTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'Inspect your paddy crop for pests today.'**
  String get notificationCropTaskMessage;

  /// No description provided for @notificationMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market price update'**
  String get notificationMarketTitle;

  /// No description provided for @notificationMarketMessage.
  ///
  /// In en, this message translates to:
  /// **'Wheat prices have increased in the local mandi.'**
  String get notificationMarketMessage;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @productiveFarm.
  ///
  /// In en, this message translates to:
  /// **'Let’s make today productive for your farm.'**
  String get productiveFarm;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get partlyCloudy;

  /// No description provided for @humidityWind.
  ///
  /// In en, this message translates to:
  /// **'Humidity 62%  •  Wind 8 km/h'**
  String get humidityWind;

  /// No description provided for @humidityWindValues.
  ///
  /// In en, this message translates to:
  /// **'Humidity {humidity}%  •  Wind {windSpeed} km/h'**
  String humidityWindValues(int humidity, int windSpeed);

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get loadingWeather;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get weatherUnavailable;

  /// No description provided for @weatherLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a location for weather'**
  String get weatherLocationRequired;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherClear;

  /// No description provided for @weatherMainlyClear.
  ///
  /// In en, this message translates to:
  /// **'Mainly clear'**
  String get weatherMainlyClear;

  /// No description provided for @weatherOvercast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherOvercast;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Foggy'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherDetails.
  ///
  /// In en, this message translates to:
  /// **'Weather Details'**
  String get weatherDetails;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLike;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @windSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get windSpeed;

  /// No description provided for @rainProbability.
  ///
  /// In en, this message translates to:
  /// **'Rain probability'**
  String get rainProbability;

  /// No description provided for @todayMinMax.
  ///
  /// In en, this message translates to:
  /// **'Today’s min / max'**
  String get todayMinMax;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @refreshWeather.
  ///
  /// In en, this message translates to:
  /// **'Refresh weather'**
  String get refreshWeather;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @seasonalAdvice.
  ///
  /// In en, this message translates to:
  /// **'SEASONAL ADVICE'**
  String get seasonalAdvice;

  /// No description provided for @smarterIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Smarter irrigation,\nbetter harvest'**
  String get smarterIrrigation;

  /// No description provided for @irrigationRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Check today’s irrigation recommendation'**
  String get irrigationRecommendation;

  /// No description provided for @viewRecommendation.
  ///
  /// In en, this message translates to:
  /// **'View recommendation'**
  String get viewRecommendation;

  /// No description provided for @loadingAdvice.
  ///
  /// In en, this message translates to:
  /// **'Preparing today’s advice...'**
  String get loadingAdvice;

  /// No description provided for @adviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Advice is temporarily unavailable'**
  String get adviceUnavailable;

  /// No description provided for @adviceLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a location for seasonal advice'**
  String get adviceLocationRequired;

  /// No description provided for @adviceWaitingForWeather.
  ///
  /// In en, this message translates to:
  /// **'Waiting for current weather information'**
  String get adviceWaitingForWeather;

  /// No description provided for @updatedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String updatedAtTime(String time);

  /// No description provided for @adviceCategoryRain.
  ///
  /// In en, this message translates to:
  /// **'RAIN & IRRIGATION'**
  String get adviceCategoryRain;

  /// No description provided for @adviceCategoryCropHealth.
  ///
  /// In en, this message translates to:
  /// **'CROP HEALTH'**
  String get adviceCategoryCropHealth;

  /// No description provided for @adviceCategoryIrrigation.
  ///
  /// In en, this message translates to:
  /// **'IRRIGATION'**
  String get adviceCategoryIrrigation;

  /// No description provided for @adviceCategorySpraying.
  ///
  /// In en, this message translates to:
  /// **'SPRAYING'**
  String get adviceCategorySpraying;

  /// No description provided for @adviceCategoryDailyFarming.
  ///
  /// In en, this message translates to:
  /// **'DAILY FARMING'**
  String get adviceCategoryDailyFarming;

  /// No description provided for @rainAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain expected today'**
  String get rainAdviceTitle;

  /// No description provided for @humidityAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect crops from fungus'**
  String get humidityAdviceTitle;

  /// No description provided for @heatAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Irrigate at cooler hours'**
  String get heatAdviceTitle;

  /// No description provided for @windAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delay pesticide spraying'**
  String get windAdviceTitle;

  /// No description provided for @normalAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Good day for farm work'**
  String get normalAdviceTitle;

  /// No description provided for @rainAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Rain is expected today. Avoid irrigation.'**
  String get rainAdviceDescription;

  /// No description provided for @humidityAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'High humidity may increase fungal disease risk.'**
  String get humidityAdviceDescription;

  /// No description provided for @heatAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Irrigate in the early morning or evening.'**
  String get heatAdviceDescription;

  /// No description provided for @windAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Avoid pesticide spraying during strong winds.'**
  String get windAdviceDescription;

  /// No description provided for @normalAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Weather is suitable for routine farm activities.'**
  String get normalAdviceDescription;

  /// No description provided for @rainAdviceReason.
  ///
  /// In en, this message translates to:
  /// **'The forecast shows a high probability of rain today.'**
  String get rainAdviceReason;

  /// No description provided for @humidityAdviceReason.
  ///
  /// In en, this message translates to:
  /// **'High moisture allows fungal diseases to spread quickly.'**
  String get humidityAdviceReason;

  /// No description provided for @heatAdviceReason.
  ///
  /// In en, this message translates to:
  /// **'High daytime temperature increases evaporation and crop stress.'**
  String get heatAdviceReason;

  /// No description provided for @windAdviceReason.
  ///
  /// In en, this message translates to:
  /// **'Strong wind can cause spray drift and uneven pesticide coverage.'**
  String get windAdviceReason;

  /// No description provided for @normalAdviceReason.
  ///
  /// In en, this message translates to:
  /// **'Temperature, humidity, rain chance and wind are within normal working ranges.'**
  String get normalAdviceReason;

  /// No description provided for @rainAdviceAction.
  ///
  /// In en, this message translates to:
  /// **'Postpone irrigation, keep drainage channels clear and protect harvested produce.'**
  String get rainAdviceAction;

  /// No description provided for @humidityAdviceAction.
  ///
  /// In en, this message translates to:
  /// **'Inspect leaves for spots, improve airflow and avoid unnecessary overhead watering.'**
  String get humidityAdviceAction;

  /// No description provided for @heatAdviceAction.
  ///
  /// In en, this message translates to:
  /// **'Water before sunrise or after sunset and check young plants for heat stress.'**
  String get heatAdviceAction;

  /// No description provided for @windAdviceAction.
  ///
  /// In en, this message translates to:
  /// **'Wait for calmer conditions before spraying pesticides or foliar nutrients.'**
  String get windAdviceAction;

  /// No description provided for @normalAdviceAction.
  ///
  /// In en, this message translates to:
  /// **'Continue planned irrigation, field inspection and routine crop care.'**
  String get normalAdviceAction;

  /// No description provided for @seasonalAdviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Advice'**
  String get seasonalAdviceDetails;

  /// No description provided for @currentWeatherSummary.
  ///
  /// In en, this message translates to:
  /// **'Current weather'**
  String get currentWeatherSummary;

  /// No description provided for @adviceWeatherSummary.
  ///
  /// In en, this message translates to:
  /// **'{temperature}°C • Humidity {humidity}% • Wind {windSpeed} km/h'**
  String adviceWeatherSummary(int temperature, int humidity, int windSpeed);

  /// No description provided for @todaysRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Today’s recommendation'**
  String get todaysRecommendation;

  /// No description provided for @recommendationReason.
  ///
  /// In en, this message translates to:
  /// **'Why this is recommended'**
  String get recommendationReason;

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get recommendedAction;

  /// No description provided for @warningLevel.
  ///
  /// In en, this message translates to:
  /// **'Warning level'**
  String get warningLevel;

  /// No description provided for @warningLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get warningLow;

  /// No description provided for @warningMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get warningMedium;

  /// No description provided for @warningHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get warningHigh;

  /// No description provided for @refreshAdvice.
  ///
  /// In en, this message translates to:
  /// **'Refresh advice'**
  String get refreshAdvice;

  /// No description provided for @askKrishiAi.
  ///
  /// In en, this message translates to:
  /// **'Ask Krishi AI'**
  String get askKrishiAi;

  /// No description provided for @askKrishiAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get quick answers for your farming questions'**
  String get askKrishiAiSubtitle;

  /// No description provided for @myCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get myCrops;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @viewMandi.
  ///
  /// In en, this message translates to:
  /// **'View mandi'**
  String get viewMandi;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today’s Tasks'**
  String get todaysTasks;

  /// No description provided for @quickServices.
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quickServices;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @needsWater.
  ///
  /// In en, this message translates to:
  /// **'Needs water'**
  String get needsWater;

  /// No description provided for @growingWell.
  ///
  /// In en, this message translates to:
  /// **'Growing well'**
  String get growingWell;

  /// No description provided for @wheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheat;

  /// No description provided for @mustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get mustard;

  /// No description provided for @tomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get tomato;

  /// No description provided for @priceToday.
  ///
  /// In en, this message translates to:
  /// **'{change} today'**
  String priceToday(String change);

  /// No description provided for @irrigateWheatField.
  ///
  /// In en, this message translates to:
  /// **'Irrigate wheat field'**
  String get irrigateWheatField;

  /// No description provided for @todayTime.
  ///
  /// In en, this message translates to:
  /// **'Today, 5:30 PM'**
  String get todayTime;

  /// No description provided for @checkMustardCrop.
  ///
  /// In en, this message translates to:
  /// **'Check mustard crop'**
  String get checkMustardCrop;

  /// No description provided for @beforeSunset.
  ///
  /// In en, this message translates to:
  /// **'Before sunset'**
  String get beforeSunset;

  /// No description provided for @cropDoctor.
  ///
  /// In en, this message translates to:
  /// **'Crop Doctor'**
  String get cropDoctor;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @mandiRates.
  ///
  /// In en, this message translates to:
  /// **'Mandi Rates'**
  String get mandiRates;

  /// No description provided for @farmTips.
  ///
  /// In en, this message translates to:
  /// **'Farm Tips'**
  String get farmTips;

  /// No description provided for @addCrop.
  ///
  /// In en, this message translates to:
  /// **'Add crop'**
  String get addCrop;

  /// No description provided for @daysOld.
  ///
  /// In en, this message translates to:
  /// **'{days} days old'**
  String daysOld(int days);

  /// No description provided for @krishiAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Krishi AI Assistant'**
  String get krishiAiAssistant;

  /// No description provided for @onlineAskLanguage.
  ///
  /// In en, this message translates to:
  /// **'Online • Ask in your language'**
  String get onlineAskLanguage;

  /// No description provided for @assistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste! I can help with crop care, pests, weather, and farming questions. What would you like to know?'**
  String get assistantGreeting;

  /// No description provided for @tryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get tryAsking;

  /// No description provided for @identifyCropDisease.
  ///
  /// In en, this message translates to:
  /// **'Identify crop disease'**
  String get identifyCropDisease;

  /// No description provided for @whenIrrigate.
  ///
  /// In en, this message translates to:
  /// **'When should I irrigate?'**
  String get whenIrrigate;

  /// No description provided for @weatherAdvice.
  ///
  /// In en, this message translates to:
  /// **'Weather advice'**
  String get weatherAdvice;

  /// No description provided for @askAboutFarm.
  ///
  /// In en, this message translates to:
  /// **'Ask about your farm...'**
  String get askAboutFarm;

  /// No description provided for @smartFarmingCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your smart farming companion'**
  String get smartFarmingCompanion;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @aiGreetingUser.
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}!'**
  String aiGreetingUser(String name);

  /// No description provided for @aiWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask me practical questions about crops, irrigation, weather, pests, fertilizer and farm decisions.'**
  String get aiWelcomeMessage;

  /// No description provided for @aiWeatherContext.
  ///
  /// In en, this message translates to:
  /// **'{temperature}°C • Humidity {humidity}% • Rain {rain}%'**
  String aiWeatherContext(int temperature, int humidity, int rain);

  /// No description provided for @suggestedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested questions'**
  String get suggestedQuestions;

  /// No description provided for @suggestIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Should I irrigate today?'**
  String get suggestIrrigation;

  /// No description provided for @suggestYellowLeaves.
  ///
  /// In en, this message translates to:
  /// **'Why are my crop leaves turning yellow?'**
  String get suggestYellowLeaves;

  /// No description provided for @suggestFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Which fertilizer should I use?'**
  String get suggestFertilizer;

  /// No description provided for @suggestRain.
  ///
  /// In en, this message translates to:
  /// **'Will it rain today?'**
  String get suggestRain;

  /// No description provided for @suggestPests.
  ///
  /// In en, this message translates to:
  /// **'How can I control pests?'**
  String get suggestPests;

  /// No description provided for @voiceFeatureComingNext.
  ///
  /// In en, this message translates to:
  /// **'Voice input is coming next.'**
  String get voiceFeatureComingNext;

  /// No description provided for @photoFeatureComingNext.
  ///
  /// In en, this message translates to:
  /// **'Photo upload and crop analysis are coming next.'**
  String get photoFeatureComingNext;

  /// No description provided for @photoFeatureDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'No photo was uploaded and disease detection has not been performed.'**
  String get photoFeatureDisclaimer;

  /// No description provided for @scanCropDisease.
  ///
  /// In en, this message translates to:
  /// **'Scan Crop Disease'**
  String get scanCropDisease;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get imagePreview;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose Another'**
  String get chooseAnother;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing Image'**
  String get processingImage;

  /// No description provided for @addClearCropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take or choose a clear photo of the affected crop area.'**
  String get addClearCropPhoto;

  /// No description provided for @selectCropImage.
  ///
  /// In en, this message translates to:
  /// **'Select a crop image'**
  String get selectCropImage;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @chooseAnotherImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Another Image'**
  String get chooseAnotherImage;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @analyzingCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyzing crop...'**
  String get analyzingCrop;

  /// No description provided for @placeholderAnalysisNotice.
  ///
  /// In en, this message translates to:
  /// **'Phase 1 uses demonstration results only. No AI model is connected.'**
  String get placeholderAnalysisNotice;

  /// No description provided for @imageCouldNotBeOpened.
  ///
  /// In en, this message translates to:
  /// **'The image could not be opened. Please try again.'**
  String get imageCouldNotBeOpened;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis could not be completed. Please try again.'**
  String get analysisFailed;

  /// No description provided for @diseaseResult.
  ///
  /// In en, this message translates to:
  /// **'Disease Result'**
  String get diseaseResult;

  /// No description provided for @sampleDiseaseName.
  ///
  /// In en, this message translates to:
  /// **'Leaf spot (sample)'**
  String get sampleDiseaseName;

  /// No description provided for @demoResult.
  ///
  /// In en, this message translates to:
  /// **'Demo result • Placeholder data'**
  String get demoResult;

  /// No description provided for @scanCrop.
  ///
  /// In en, this message translates to:
  /// **'Scan Crop'**
  String get scanCrop;

  /// No description provided for @consultExpert.
  ///
  /// In en, this message translates to:
  /// **'Consult Expert'**
  String get consultExpert;

  /// No description provided for @imagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or photo access was denied. Allow access in app settings and try again.'**
  String get imagePermissionDenied;

  /// No description provided for @uploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {progress}%'**
  String uploadProgress(int progress);

  /// No description provided for @diseaseScanOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and retry.'**
  String get diseaseScanOffline;

  /// No description provided for @diseaseScanTimeout.
  ///
  /// In en, this message translates to:
  /// **'The scan took too long. Please retry with a stable connection.'**
  String get diseaseScanTimeout;

  /// No description provided for @diseaseScanInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The scan service returned an invalid response. Please retry.'**
  String get diseaseScanInvalidResponse;

  /// No description provided for @diseaseScanServerError.
  ///
  /// In en, this message translates to:
  /// **'The scan service is temporarily unavailable. Please retry.'**
  String get diseaseScanServerError;

  /// No description provided for @observation.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get observation;

  /// No description provided for @sampleDiseaseSummary.
  ///
  /// In en, this message translates to:
  /// **'Small discoloured spots were found in this placeholder analysis.'**
  String get sampleDiseaseSummary;

  /// No description provided for @recommendedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Recommended next step'**
  String get recommendedNextStep;

  /// No description provided for @sampleDiseaseRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Keep the leaves dry, monitor new growth, and consult a crop expert before treatment.'**
  String get sampleDiseaseRecommendation;

  /// No description provided for @notMedicalDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'This demonstration result is not a confirmed diagnosis. Consult an agricultural expert before treatment.'**
  String get notMedicalDiagnosis;

  /// No description provided for @lowConfidenceResult.
  ///
  /// In en, this message translates to:
  /// **'Low-confidence result. An expert review is recommended before taking action.'**
  String get lowConfidenceResult;

  /// No description provided for @scanConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {confidence}%'**
  String scanConfidence(int confidence);

  /// No description provided for @visibleSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Visible symptoms'**
  String get visibleSymptoms;

  /// No description provided for @recommendedActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended actions'**
  String get recommendedActions;

  /// No description provided for @expertReviewRecommended.
  ///
  /// In en, this message translates to:
  /// **'Expert review recommended'**
  String get expertReviewRecommended;

  /// No description provided for @followUpQuestions.
  ///
  /// In en, this message translates to:
  /// **'Follow-up questions'**
  String get followUpQuestions;

  /// No description provided for @retryResponse.
  ///
  /// In en, this message translates to:
  /// **'Retry response'**
  String get retryResponse;

  /// No description provided for @aiTyping.
  ///
  /// In en, this message translates to:
  /// **'Krishi AI is typing...'**
  String get aiTyping;

  /// No description provided for @aiResponseGreeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste! Tell me your crop name and what help you need today.'**
  String get aiResponseGreeting;

  /// No description provided for @aiResponseLanguageSupport.
  ///
  /// In en, this message translates to:
  /// **'Yes, I can understand Bengali. You can ask your farming question in Bangla.'**
  String get aiResponseLanguageSupport;

  /// No description provided for @aiResponseCropProblemWheat.
  ///
  /// In en, this message translates to:
  /// **'I can help with your wheat problem. Please tell me what you see, such as yellow leaves, spots, insects, weak growth, or drying.'**
  String get aiResponseCropProblemWheat;

  /// No description provided for @aiResponseCropProblemRice.
  ///
  /// In en, this message translates to:
  /// **'I can help with your rice problem. Please describe whether you see yellow leaves, spots, insects, poor tillering, wilting, or drying.'**
  String get aiResponseCropProblemRice;

  /// No description provided for @aiResponseCropProblemGeneral.
  ///
  /// In en, this message translates to:
  /// **'I can help diagnose the crop problem. Please tell me the crop name and whether you see yellow leaves, spots, insects, weak growth, wilting, or drying.'**
  String get aiResponseCropProblemGeneral;

  /// No description provided for @aiResponseIrrigationRain.
  ///
  /// In en, this message translates to:
  /// **'Rain is likely today, so delay irrigation and check soil moisture after the rain.'**
  String get aiResponseIrrigationRain;

  /// No description provided for @aiResponseIrrigationNormal.
  ///
  /// In en, this message translates to:
  /// **'No heavy rain is expected. Check soil moisture 5–7 cm deep and irrigate in the early morning if it feels dry.'**
  String get aiResponseIrrigationNormal;

  /// No description provided for @aiResponseRainExpected.
  ///
  /// In en, this message translates to:
  /// **'Rain is likely today. Keep drainage channels clear and protect harvested produce and farm inputs.'**
  String get aiResponseRainExpected;

  /// No description provided for @aiResponseWeatherNormal.
  ///
  /// In en, this message translates to:
  /// **'No strong rain signal is available right now. Continue routine work, but check the latest weather before spraying.'**
  String get aiResponseWeatherNormal;

  /// No description provided for @aiResponseFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer depends on the crop, growth stage and soil test. Avoid guessing doses; share those details or consult your local soil-testing centre.'**
  String get aiResponseFertilizer;

  /// No description provided for @aiResponsePests.
  ///
  /// In en, this message translates to:
  /// **'Inspect both sides of affected leaves, isolate badly affected plants and use traps first. Identify the pest before applying any pesticide.'**
  String get aiResponsePests;

  /// No description provided for @aiResponseYellowLeaves.
  ///
  /// In en, this message translates to:
  /// **'Yellow leaves can result from excess water, nitrogen deficiency, root damage or disease. Check soil moisture and whether yellowing starts on old or new leaves.'**
  String get aiResponseYellowLeaves;

  /// No description provided for @aiResponseCropDisease.
  ///
  /// In en, this message translates to:
  /// **'Check for spots, wilting, fungal growth and affected stem areas. Avoid unnecessary spraying until the crop and symptoms are correctly identified.'**
  String get aiResponseCropDisease;

  /// No description provided for @aiResponseMarketPrice.
  ///
  /// In en, this message translates to:
  /// **'Market prices change by crop, grade and mandi. Check the Market section and compare nearby mandis before deciding where to sell.'**
  String get aiResponseMarketPrice;

  /// No description provided for @aiResponseSowingTime.
  ///
  /// In en, this message translates to:
  /// **'The best sowing time depends on crop, variety, local rainfall and soil temperature. Tell me the crop and your area for a more useful recommendation.'**
  String get aiResponseSowingTime;

  /// No description provided for @aiResponseGovernmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Scheme eligibility varies by state and farmer category. Check your state agriculture portal or nearest agriculture office with Aadhaar, land and bank documents.'**
  String get aiResponseGovernmentSchemes;

  /// No description provided for @aiResponseAgriculturalExpert.
  ///
  /// In en, this message translates to:
  /// **'For expert help, contact your nearest Krishi Vigyan Kendra, agriculture extension officer or state agriculture helpline.'**
  String get aiResponseAgriculturalExpert;

  /// No description provided for @aiResponseGeneral.
  ///
  /// In en, this message translates to:
  /// **'Please tell me the crop name and the problem you are seeing.'**
  String get aiResponseGeneral;

  /// No description provided for @krishiMarket.
  ///
  /// In en, this message translates to:
  /// **'Krishi Market'**
  String get krishiMarket;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @marketShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get marketShop;

  /// No description provided for @mandiCropFilter.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get mandiCropFilter;

  /// No description provided for @mandiDistrictFilter.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get mandiDistrictFilter;

  /// No description provided for @mandiMarketFilter.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get mandiMarketFilter;

  /// No description provided for @mandiLoadError.
  ///
  /// In en, this message translates to:
  /// **'Mandi prices could not be loaded. Please retry.'**
  String get mandiLoadError;

  /// No description provided for @noMandiPrices.
  ///
  /// In en, this message translates to:
  /// **'No mandi prices match these filters.'**
  String get noMandiPrices;

  /// No description provided for @minimumPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimumPrice;

  /// No description provided for @maximumPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximumPrice;

  /// No description provided for @modalPrice.
  ///
  /// In en, this message translates to:
  /// **'Modal price'**
  String get modalPrice;

  /// No description provided for @mandiPriceUnit.
  ///
  /// In en, this message translates to:
  /// **'Price unit: ₹ per {unit}'**
  String mandiPriceUnit(String unit);

  /// No description provided for @mandiUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String mandiUpdatedAt(String time);

  /// No description provided for @trendUp.
  ///
  /// In en, this message translates to:
  /// **'Price trend up'**
  String get trendUp;

  /// No description provided for @trendDown.
  ///
  /// In en, this message translates to:
  /// **'Price trend down'**
  String get trendDown;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Price trend stable'**
  String get trendStable;

  /// No description provided for @paddy.
  ///
  /// In en, this message translates to:
  /// **'Paddy'**
  String get paddy;

  /// No description provided for @maize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get maize;

  /// No description provided for @potato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get potato;

  /// No description provided for @onion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get onion;

  /// No description provided for @searchMarket.
  ///
  /// In en, this message translates to:
  /// **'Search seeds, tools and fertilizers'**
  String get searchMarket;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @fertilizers.
  ///
  /// In en, this message translates to:
  /// **'Fertilizers'**
  String get fertilizers;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @premiumWheatSeeds.
  ///
  /// In en, this message translates to:
  /// **'Premium Wheat Seeds'**
  String get premiumWheatSeeds;

  /// No description provided for @organicFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Organic Fertilizer'**
  String get organicFertilizer;

  /// No description provided for @gardenSprayer.
  ///
  /// In en, this message translates to:
  /// **'Garden Sprayer'**
  String get gardenSprayer;

  /// No description provided for @tomatoSeeds.
  ///
  /// In en, this message translates to:
  /// **'Tomato Seeds'**
  String get tomatoSeeds;

  /// No description provided for @pricePerBag.
  ///
  /// In en, this message translates to:
  /// **'{price} / bag'**
  String pricePerBag(String price);

  /// No description provided for @pricePerPack.
  ///
  /// In en, this message translates to:
  /// **'{price} / pack'**
  String pricePerPack(String price);

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @marketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get marketDescription;

  /// No description provided for @marketAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get marketAvailability;

  /// No description provided for @marketSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller / Vendor'**
  String get marketSeller;

  /// No description provided for @marketInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock ({quantity} available)'**
  String marketInStock(int quantity);

  /// No description provided for @marketOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Currently out of stock'**
  String get marketOutOfStock;

  /// No description provided for @marketBag.
  ///
  /// In en, this message translates to:
  /// **'bag'**
  String get marketBag;

  /// No description provided for @marketPack.
  ///
  /// In en, this message translates to:
  /// **'pack'**
  String get marketPack;

  /// No description provided for @marketPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get marketPiece;

  /// No description provided for @marketPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} / {unit}'**
  String marketPrice(String price, String unit);

  /// No description provided for @marketLoadError.
  ///
  /// In en, this message translates to:
  /// **'Market products could not be loaded. Please retry.'**
  String get marketLoadError;

  /// No description provided for @noMarketProducts.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noMarketProducts;

  /// No description provided for @marketCheckoutComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Checkout and payment are not available yet.'**
  String get marketCheckoutComingSoon;

  /// No description provided for @premiumWheatSeedsDescription.
  ///
  /// In en, this message translates to:
  /// **'Clean, high-quality wheat seed suitable for timely sowing and dependable field establishment.'**
  String get premiumWheatSeedsDescription;

  /// No description provided for @organicFertilizerDescription.
  ///
  /// In en, this message translates to:
  /// **'Organic soil conditioner that supports soil structure and gradual nutrient availability.'**
  String get organicFertilizerDescription;

  /// No description provided for @gardenSprayerDescription.
  ///
  /// In en, this message translates to:
  /// **'Durable hand-operated sprayer for careful application of water and approved crop treatments.'**
  String get gardenSprayerDescription;

  /// No description provided for @tomatoSeedsDescription.
  ///
  /// In en, this message translates to:
  /// **'Selected tomato seeds suitable for kitchen gardens and small vegetable plots.'**
  String get tomatoSeedsDescription;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm details'**
  String get farmDetails;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @helpSupportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Help and support could not be loaded.'**
  String get helpSupportLoadError;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @faqLanguageQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I change the app language?'**
  String get faqLanguageQuestion;

  /// No description provided for @faqLanguageAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open Profile, choose Language, then select your preferred language. Your choice is saved automatically.'**
  String get faqLanguageAnswer;

  /// No description provided for @faqCropQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I add a crop?'**
  String get faqCropQuestion;

  /// No description provided for @faqCropAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open My Crops and select Add Crop. Complete the required crop, sowing date and land details, then save.'**
  String get faqCropAnswer;

  /// No description provided for @faqOfflineQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I use Krishi Sech offline?'**
  String get faqOfflineQuestion;

  /// No description provided for @faqOfflineAnswer.
  ///
  /// In en, this message translates to:
  /// **'Saved information remains available offline. Features requiring current server data will refresh when you reconnect.'**
  String get faqOfflineAnswer;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get supportEmail;

  /// No description provided for @supportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get supportPhone;

  /// No description provided for @supportContactPlaceholderNotice.
  ///
  /// In en, this message translates to:
  /// **'Placeholder contact details are shown until official support channels are configured.'**
  String get supportContactPlaceholderNotice;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportAProblem;

  /// No description provided for @reportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get reportSubject;

  /// No description provided for @reportDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportDescription;

  /// No description provided for @reportSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a subject.'**
  String get reportSubjectRequired;

  /// No description provided for @reportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem.'**
  String get reportDescriptionRequired;

  /// No description provided for @attachScreenshotOptional.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot (optional)'**
  String get attachScreenshotOptional;

  /// No description provided for @screenshotAttached.
  ///
  /// In en, this message translates to:
  /// **'Screenshot attached'**
  String get screenshotAttached;

  /// No description provided for @screenshotSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'The screenshot could not be selected.'**
  String get screenshotSelectionFailed;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @reportSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your report was saved on this device.'**
  String get reportSubmittedSuccessfully;

  /// No description provided for @reportSubmitError.
  ///
  /// In en, this message translates to:
  /// **'The report could not be saved. Please try again.'**
  String get reportSubmitError;

  /// No description provided for @supportReportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Saved reports could not be loaded.'**
  String get supportReportsLoadError;

  /// No description provided for @noSupportReports.
  ///
  /// In en, this message translates to:
  /// **'No demo reports submitted yet.'**
  String get noSupportReports;

  /// No description provided for @supportReportsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved reports on this device: {count}'**
  String supportReportsSaved(int count);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySummary.
  ///
  /// In en, this message translates to:
  /// **'Krishi Sech stores demo support reports locally on this device. Do not include passwords, OTPs or other sensitive information.'**
  String get privacyPolicySummary;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsConditionsSummary.
  ///
  /// In en, this message translates to:
  /// **'This development build provides farming information and demo services. Verify critical farming decisions with a qualified local expert.'**
  String get termsConditionsSummary;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @shorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get shorts;

  /// No description provided for @readyForImplementation.
  ///
  /// In en, this message translates to:
  /// **'{feature} is ready for implementation.'**
  String readyForImplementation(String feature);

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access needed'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to automatically show farming information for your city, district and state.'**
  String get locationPermissionMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @selectManually.
  ///
  /// In en, this message translates to:
  /// **'Select location manually'**
  String get selectManually;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting your location...'**
  String get detectingLocation;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @villageOptional.
  ///
  /// In en, this message translates to:
  /// **'Village (optional)'**
  String get villageOptional;

  /// No description provided for @chooseState.
  ///
  /// In en, this message translates to:
  /// **'Choose or search state'**
  String get chooseState;

  /// No description provided for @chooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose or search district'**
  String get chooseDistrict;

  /// No description provided for @chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose or search city'**
  String get chooseCity;

  /// No description provided for @enterVillage.
  ///
  /// In en, this message translates to:
  /// **'Enter village name'**
  String get enterVillage;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocation;

  /// No description provided for @selectRequiredLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a state, district and city.'**
  String get selectRequiredLocation;

  /// No description provided for @yourLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocationTitle;

  /// No description provided for @locationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Location not selected'**
  String get locationNotSelected;

  /// No description provided for @locationPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Use GPS or add a location manually'**
  String get locationPermissionHint;

  /// No description provided for @usingSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Using your saved location'**
  String get usingSavedLocation;

  /// No description provided for @refreshCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh current location'**
  String get refreshCurrentLocation;

  /// No description provided for @addChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Add or change location'**
  String get addChangeLocation;

  /// No description provided for @locationDeniedFriendly.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t access your location. You can retry or select it manually.'**
  String get locationDeniedFriendly;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search city, district or state'**
  String get searchLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Using current location • Accuracy: {meters} m'**
  String locationAccuracy(int meters);

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Turn them on to detect your current location.'**
  String get locationServicesDisabled;

  /// No description provided for @preciseLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Approximate location is enabled. Allow precise location for accurate city and district detection.'**
  String get preciseLocationRequired;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Enable it from app settings or select a location manually.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationDetectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'We could not get a fresh GPS reading. Move to an open area and try again.'**
  String get locationDetectionTimedOut;

  /// No description provided for @locationAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your GPS position was found, but its address could not be determined. Check your internet connection and retry.'**
  String get locationAddressUnavailable;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Location Settings'**
  String get openLocationSettings;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @cropPaddy.
  ///
  /// In en, this message translates to:
  /// **'Paddy'**
  String get cropPaddy;

  /// No description provided for @cropWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get cropWheat;

  /// No description provided for @cropMaize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get cropMaize;

  /// No description provided for @cropTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get cropTomato;

  /// No description provided for @cropBrinjal.
  ///
  /// In en, this message translates to:
  /// **'Brinjal'**
  String get cropBrinjal;

  /// No description provided for @cropChilli.
  ///
  /// In en, this message translates to:
  /// **'Chilli'**
  String get cropChilli;

  /// No description provided for @cropMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get cropMustard;

  /// No description provided for @cropPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get cropPotato;

  /// No description provided for @cropOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get cropOnion;

  /// No description provided for @cropOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cropOther;

  /// No description provided for @stageSowing.
  ///
  /// In en, this message translates to:
  /// **'Sowing'**
  String get stageSowing;

  /// No description provided for @stageGermination.
  ///
  /// In en, this message translates to:
  /// **'Germination'**
  String get stageGermination;

  /// No description provided for @stageSeedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get stageSeedling;

  /// No description provided for @stageVegetative.
  ///
  /// In en, this message translates to:
  /// **'Vegetative'**
  String get stageVegetative;

  /// No description provided for @stageFlowering.
  ///
  /// In en, this message translates to:
  /// **'Flowering'**
  String get stageFlowering;

  /// No description provided for @stageFruiting.
  ///
  /// In en, this message translates to:
  /// **'Fruiting'**
  String get stageFruiting;

  /// No description provided for @stageMaturity.
  ///
  /// In en, this message translates to:
  /// **'Maturity'**
  String get stageMaturity;

  /// No description provided for @stageHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get stageHarvested;

  /// No description provided for @healthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthHealthy;

  /// No description provided for @healthModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get healthModerate;

  /// No description provided for @healthNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get healthNeedsAttention;

  /// No description provided for @unitAcre.
  ///
  /// In en, this message translates to:
  /// **'Acre'**
  String get unitAcre;

  /// No description provided for @unitHectare.
  ///
  /// In en, this message translates to:
  /// **'Hectare'**
  String get unitHectare;

  /// No description provided for @unitBigha.
  ///
  /// In en, this message translates to:
  /// **'Bigha'**
  String get unitBigha;

  /// No description provided for @unitKatha.
  ///
  /// In en, this message translates to:
  /// **'Katha'**
  String get unitKatha;

  /// No description provided for @irrigationDrip.
  ///
  /// In en, this message translates to:
  /// **'Drip'**
  String get irrigationDrip;

  /// No description provided for @irrigationSprinkler.
  ///
  /// In en, this message translates to:
  /// **'Sprinkler'**
  String get irrigationSprinkler;

  /// No description provided for @irrigationFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get irrigationFlood;

  /// No description provided for @irrigationRainFed.
  ///
  /// In en, this message translates to:
  /// **'Rain-fed'**
  String get irrigationRainFed;

  /// No description provided for @irrigationManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get irrigationManual;

  /// No description provided for @plantAge.
  ///
  /// In en, this message translates to:
  /// **'Plant age'**
  String get plantAge;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil type'**
  String get soilType;

  /// No description provided for @irrigationMethod.
  ///
  /// In en, this message translates to:
  /// **'Irrigation method'**
  String get irrigationMethod;

  /// No description provided for @plantingMethod.
  ///
  /// In en, this message translates to:
  /// **'Planting method'**
  String get plantingMethod;

  /// No description provided for @seedBrand.
  ///
  /// In en, this message translates to:
  /// **'Seed brand'**
  String get seedBrand;

  /// No description provided for @lastFertilizerUsed.
  ///
  /// In en, this message translates to:
  /// **'Last fertilizer used'**
  String get lastFertilizerUsed;

  /// No description provided for @lastPesticideUsed.
  ///
  /// In en, this message translates to:
  /// **'Last pesticide used'**
  String get lastPesticideUsed;

  /// No description provided for @otherOption.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherOption;

  /// No description provided for @soilAlluvial.
  ///
  /// In en, this message translates to:
  /// **'Alluvial'**
  String get soilAlluvial;

  /// No description provided for @soilBlack.
  ///
  /// In en, this message translates to:
  /// **'Black soil'**
  String get soilBlack;

  /// No description provided for @soilRed.
  ///
  /// In en, this message translates to:
  /// **'Red soil'**
  String get soilRed;

  /// No description provided for @soilLaterite.
  ///
  /// In en, this message translates to:
  /// **'Laterite'**
  String get soilLaterite;

  /// No description provided for @soilSandy.
  ///
  /// In en, this message translates to:
  /// **'Sandy'**
  String get soilSandy;

  /// No description provided for @soilClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get soilClay;

  /// No description provided for @soilLoamy.
  ///
  /// In en, this message translates to:
  /// **'Loamy'**
  String get soilLoamy;

  /// No description provided for @plantingDirectSowing.
  ///
  /// In en, this message translates to:
  /// **'Direct sowing'**
  String get plantingDirectSowing;

  /// No description provided for @plantingTransplanting.
  ///
  /// In en, this message translates to:
  /// **'Transplanting'**
  String get plantingTransplanting;

  /// No description provided for @plantingBroadcasting.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting'**
  String get plantingBroadcasting;

  /// No description provided for @plantingRaisedBed.
  ///
  /// In en, this message translates to:
  /// **'Raised bed'**
  String get plantingRaisedBed;

  /// No description provided for @taskIrrigationReminder.
  ///
  /// In en, this message translates to:
  /// **'Irrigation reminder'**
  String get taskIrrigationReminder;

  /// No description provided for @taskFertilizerReminder.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer reminder'**
  String get taskFertilizerReminder;

  /// No description provided for @taskPestInspection.
  ///
  /// In en, this message translates to:
  /// **'Pest inspection'**
  String get taskPestInspection;

  /// No description provided for @taskHarvestPreparation.
  ///
  /// In en, this message translates to:
  /// **'Harvest preparation'**
  String get taskHarvestPreparation;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskCompleted;

  /// No description provided for @totalCrops.
  ///
  /// In en, this message translates to:
  /// **'Total Crops'**
  String get totalCrops;

  /// No description provided for @healthyCrops.
  ///
  /// In en, this message translates to:
  /// **'Healthy Crops'**
  String get healthyCrops;

  /// No description provided for @cropsNeedingAttention.
  ///
  /// In en, this message translates to:
  /// **'Need Attention'**
  String get cropsNeedingAttention;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @noCropsYet.
  ///
  /// In en, this message translates to:
  /// **'No crops added yet.'**
  String get noCropsYet;

  /// No description provided for @cropName.
  ///
  /// In en, this message translates to:
  /// **'Crop name'**
  String get cropName;

  /// No description provided for @otherCropName.
  ///
  /// In en, this message translates to:
  /// **'Other crop name'**
  String get otherCropName;

  /// No description provided for @variety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get variety;

  /// No description provided for @sowingDate.
  ///
  /// In en, this message translates to:
  /// **'Sowing date'**
  String get sowingDate;

  /// No description provided for @landArea.
  ///
  /// In en, this message translates to:
  /// **'Land area'**
  String get landArea;

  /// No description provided for @landAreaUnit.
  ///
  /// In en, this message translates to:
  /// **'Area unit'**
  String get landAreaUnit;

  /// No description provided for @currentGrowthStage.
  ///
  /// In en, this message translates to:
  /// **'Current growth stage'**
  String get currentGrowthStage;

  /// No description provided for @irrigationType.
  ///
  /// In en, this message translates to:
  /// **'Irrigation type'**
  String get irrigationType;

  /// No description provided for @healthStatus.
  ///
  /// In en, this message translates to:
  /// **'Health status'**
  String get healthStatus;

  /// No description provided for @villageFarmOptional.
  ///
  /// In en, this message translates to:
  /// **'Village / farm name (optional)'**
  String get villageFarmOptional;

  /// No description provided for @expectedHarvestOptional.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest date (optional)'**
  String get expectedHarvestOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @saveCrop.
  ///
  /// In en, this message translates to:
  /// **'Save Crop'**
  String get saveCrop;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @cropNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a crop name.'**
  String get cropNameRequired;

  /// No description provided for @varietyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the crop variety.'**
  String get varietyRequired;

  /// No description provided for @sowingDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select the sowing date.'**
  String get sowingDateRequired;

  /// No description provided for @landAreaPositive.
  ///
  /// In en, this message translates to:
  /// **'Land area must be greater than zero.'**
  String get landAreaPositive;

  /// No description provided for @sowingDateFutureError.
  ///
  /// In en, this message translates to:
  /// **'Sowing date cannot be in the future.'**
  String get sowingDateFutureError;

  /// No description provided for @cropDetails.
  ///
  /// In en, this message translates to:
  /// **'Crop Details'**
  String get cropDetails;

  /// No description provided for @cropAge.
  ///
  /// In en, this message translates to:
  /// **'Crop age'**
  String get cropAge;

  /// No description provided for @growthProgress.
  ///
  /// In en, this message translates to:
  /// **'Growth progress'**
  String get growthProgress;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get nextAction;

  /// No description provided for @expectedHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest date'**
  String get expectedHarvestDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @updateHealthStatus.
  ///
  /// In en, this message translates to:
  /// **'Mark Healthy / Needs Attention'**
  String get updateHealthStatus;

  /// No description provided for @updateGrowthStage.
  ///
  /// In en, this message translates to:
  /// **'Update Growth Stage'**
  String get updateGrowthStage;

  /// No description provided for @editCrop.
  ///
  /// In en, this message translates to:
  /// **'Edit Crop'**
  String get editCrop;

  /// No description provided for @deleteCrop.
  ///
  /// In en, this message translates to:
  /// **'Delete Crop'**
  String get deleteCrop;

  /// No description provided for @deleteCropConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this crop?'**
  String get deleteCropConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cropNotFound.
  ///
  /// In en, this message translates to:
  /// **'Crop not found.'**
  String get cropNotFound;

  /// No description provided for @cropHealthRecord.
  ///
  /// In en, this message translates to:
  /// **'Crop Health Record'**
  String get cropHealthRecord;

  /// No description provided for @diseaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Disease History'**
  String get diseaseHistory;

  /// No description provided for @fertilizerHistory.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer History'**
  String get fertilizerHistory;

  /// No description provided for @irrigationHistory.
  ///
  /// In en, this message translates to:
  /// **'Irrigation History'**
  String get irrigationHistory;

  /// No description provided for @sprayHistory.
  ///
  /// In en, this message translates to:
  /// **'Spray History'**
  String get sprayHistory;

  /// No description provided for @scanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanHistory;

  /// No description provided for @photoHistory.
  ///
  /// In en, this message translates to:
  /// **'Photo History'**
  String get photoHistory;

  /// No description provided for @addRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// No description provided for @editRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get deleteRecordConfirmation;

  /// No description provided for @noHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'No crop health records yet.'**
  String get noHealthRecords;

  /// No description provided for @recordType.
  ///
  /// In en, this message translates to:
  /// **'Record type'**
  String get recordType;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recordTitle;

  /// No description provided for @recordTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a record title.'**
  String get recordTitleRequired;

  /// No description provided for @recordDate.
  ///
  /// In en, this message translates to:
  /// **'Record date'**
  String get recordDate;

  /// No description provided for @recordDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get recordDetails;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// No description provided for @scanDisease.
  ///
  /// In en, this message translates to:
  /// **'Scan Disease'**
  String get scanDisease;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDays(int days);

  /// No description provided for @sownOn.
  ///
  /// In en, this message translates to:
  /// **'Sown on'**
  String get sownOn;

  /// No description provided for @cropCalendar.
  ///
  /// In en, this message translates to:
  /// **'Crop Calendar'**
  String get cropCalendar;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @taskType.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get taskType;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @taskNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get taskNotes;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save Task'**
  String get saveTask;

  /// No description provided for @selectCropForTask.
  ///
  /// In en, this message translates to:
  /// **'Please select a crop.'**
  String get selectCropForTask;

  /// No description provided for @irrigationTask.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigationTask;

  /// No description provided for @fertilizerTask.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get fertilizerTask;

  /// No description provided for @pestInspectionTask.
  ///
  /// In en, this message translates to:
  /// **'Pest inspection'**
  String get pestInspectionTask;

  /// No description provided for @harvestTask.
  ///
  /// In en, this message translates to:
  /// **'Harvest preparation'**
  String get harvestTask;

  /// No description provided for @tasksForSelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Tasks for selected date'**
  String get tasksForSelectedDate;

  /// No description provided for @upcomingCropTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Crop Tasks'**
  String get upcomingCropTasks;

  /// No description provided for @noTasksForDate.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for this date.'**
  String get noTasksForDate;

  /// No description provided for @noUpcomingCropTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming crop tasks.'**
  String get noUpcomingCropTasks;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirmation;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No crop tasks due today.'**
  String get noTasksToday;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get noCompletedTasks;

  /// No description provided for @cropTimeline.
  ///
  /// In en, this message translates to:
  /// **'Crop Timeline'**
  String get cropTimeline;

  /// No description provided for @noCropTimelineTasks.
  ///
  /// In en, this message translates to:
  /// **'No timeline tasks available.'**
  String get noCropTimelineTasks;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @selectTaskType.
  ///
  /// In en, this message translates to:
  /// **'Please select a task type.'**
  String get selectTaskType;

  /// No description provided for @cropCalendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'The crop calendar could not be loaded. Please try again.'**
  String get cropCalendarLoadError;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderTime;

  /// No description provided for @reminderAtDueTime.
  ///
  /// In en, this message translates to:
  /// **'At due time'**
  String get reminderAtDueTime;

  /// No description provided for @reminderThirtyMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get reminderThirtyMinutesBefore;

  /// No description provided for @reminderOneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminderOneHourBefore;

  /// No description provided for @reminderOneDayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get reminderOneDayBefore;

  /// No description provided for @reminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderNone;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get dueTime;

  /// No description provided for @cropTaskNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Krishi Sech Crop Task'**
  String get cropTaskNotificationTitle;

  /// No description provided for @cropTaskNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{cropName} {taskName} is due at {dueTime}. Open Krishi Sech to view the task.'**
  String cropTaskNotificationBody(
    String cropName,
    String taskName,
    String dueTime,
  );

  /// No description provided for @cropOfflineCache.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved crops. Changes will sync automatically.'**
  String get cropOfflineCache;

  /// No description provided for @cropServerError.
  ///
  /// In en, this message translates to:
  /// **'Crops could not be updated. Please retry.'**
  String get cropServerError;

  /// No description provided for @cropChangesPending.
  ///
  /// In en, this message translates to:
  /// **'Crop changes are waiting to sync.'**
  String get cropChangesPending;

  /// No description provided for @todaysSmartFarming.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Smart Farming'**
  String get todaysSmartFarming;

  /// No description provided for @smartTodaysWeather.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Weather'**
  String get smartTodaysWeather;

  /// No description provided for @smartIrrigationRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Recommendation'**
  String get smartIrrigationRecommendation;

  /// No description provided for @smartFertilizerRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Recommendation'**
  String get smartFertilizerRecommendation;

  /// No description provided for @smartTodaysCropTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Crop Tasks'**
  String get smartTodaysCropTasks;

  /// No description provided for @smartDiseaseRisk.
  ///
  /// In en, this message translates to:
  /// **'Disease Risk'**
  String get smartDiseaseRisk;

  /// No description provided for @smartDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Data unavailable'**
  String get smartDataUnavailable;

  /// No description provided for @smartOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved recommendations'**
  String get smartOfflineData;

  /// No description provided for @smartNoIrrigation.
  ///
  /// In en, this message translates to:
  /// **'No irrigation needed today'**
  String get smartNoIrrigation;

  /// No description provided for @smartIrrigationRequired.
  ///
  /// In en, this message translates to:
  /// **'Irrigate with {liters} L/acre'**
  String smartIrrigationRequired(int liters);

  /// No description provided for @smartTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks remaining'**
  String smartTaskCount(int count);

  /// No description provided for @smartRiskLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get smartRiskLow;

  /// No description provided for @smartRiskMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate risk'**
  String get smartRiskMedium;

  /// No description provided for @smartRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get smartRiskHigh;

  /// No description provided for @smartReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get smartReady;

  /// No description provided for @smartCached.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get smartCached;

  /// No description provided for @smartUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get smartUpToDate;

  /// No description provided for @smartNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get smartNeedsAttention;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @landAreaGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Land area must be greater than zero.'**
  String get landAreaGreaterThanZero;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmName;

  /// No description provided for @farmerType.
  ///
  /// In en, this message translates to:
  /// **'Farmer type'**
  String get farmerType;

  /// No description provided for @totalLandArea.
  ///
  /// In en, this message translates to:
  /// **'Total land area'**
  String get totalLandArea;

  /// No description provided for @irrigationSource.
  ///
  /// In en, this message translates to:
  /// **'Irrigation source'**
  String get irrigationSource;

  /// No description provided for @mainCrops.
  ///
  /// In en, this message translates to:
  /// **'Main crops (comma separated)'**
  String get mainCrops;

  /// No description provided for @coarseLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Coarse location (optional)'**
  String get coarseLocationOptional;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile is unavailable'**
  String get profileUnavailable;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be loaded. Pull down or tap refresh to retry.'**
  String get profileLoadError;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This option is coming soon.'**
  String get featureComingSoon;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'brx',
    'doi',
    'en',
    'gu',
    'hi',
    'kn',
    'kok',
    'ks',
    'mai',
    'ml',
    'mni',
    'mr',
    'ne',
    'or',
    'pa',
    'sa',
    'sat',
    'sd',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'sa':
      return AppLocalizationsSa();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
