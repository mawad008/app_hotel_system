import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// Product name shown in the app bar and app metadata.
  ///
  /// In en, this message translates to:
  /// **'Hotel System'**
  String get appName;

  /// One-line promise shown on the foundation screen.
  ///
  /// In en, this message translates to:
  /// **'Book, verify and enter — from your phone.'**
  String get appTagline;

  /// Title of the Phase 0 placeholder screen.
  ///
  /// In en, this message translates to:
  /// **'Foundation & Design System'**
  String get foundationScreenTitle;

  /// No description provided for @foundationScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile Phase 0 — architecture, theme, localization and data-layer scaffolding only. Feature screens arrive in later phases.'**
  String get foundationScreenSubtitle;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @sectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionTheme;

  /// No description provided for @sectionBackendStatus.
  ///
  /// In en, this message translates to:
  /// **'Backend connectivity'**
  String get sectionBackendStatus;

  /// No description provided for @sectionComponents.
  ///
  /// In en, this message translates to:
  /// **'Design system components'**
  String get sectionComponents;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @environmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment: {name}'**
  String environmentLabel(String name);

  /// No description provided for @apiBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API base URL: {url}'**
  String apiBaseUrlLabel(String url);

  /// No description provided for @backendStatusOk.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get backendStatusOk;

  /// No description provided for @backendStatusDegraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get backendStatusDegraded;

  /// No description provided for @backendStatusDown.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get backendStatusDown;

  /// No description provided for @backendStatusCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked at {time}'**
  String backendStatusCheckedAt(String time);

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get actionCheckAgain;

  /// No description provided for @actionPrimaryExample.
  ///
  /// In en, this message translates to:
  /// **'Primary action'**
  String get actionPrimaryExample;

  /// No description provided for @actionSecondaryExample.
  ///
  /// In en, this message translates to:
  /// **'Secondary action'**
  String get actionSecondaryExample;

  /// No description provided for @stateLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stateLoadingTitle;

  /// No description provided for @stateEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmptyTitle;

  /// No description provided for @stateEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When there is something to show, it will appear here.'**
  String get stateEmptySubtitle;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsUnreadTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 new notification} other{You have {count} new notifications}}'**
  String notificationsUnreadTitle(int count);

  /// No description provided for @notificationsAllReadTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsAllReadTitle;

  /// No description provided for @notificationsBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Tap any notification to go straight to it.'**
  String get notificationsBannerBody;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Updates about your bookings and stays will appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get notificationsNow;

  /// No description provided for @notificationsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsYesterday;

  /// No description provided for @notificationsUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnreadLabel;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsOpenTooltip;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that request. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t available yet. Please try again later.'**
  String get errorNotImplemented;

  /// No description provided for @textFieldExampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get textFieldExampleLabel;

  /// No description provided for @textFieldExampleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get textFieldExampleHint;

  /// Latin brand wordmark under the logo on the splash — the v2 Figma shows it untranslated in both languages.
  ///
  /// In en, this message translates to:
  /// **'Hotel System'**
  String get brandWordmark;

  /// Onboarding headline (v2 ENTRY_Onboarding). EN is a translation of the Figma AR copy — pending designer review.
  ///
  /// In en, this message translates to:
  /// **'Explore Al Waha Hotel and book from wherever you are'**
  String get entryHeadline;

  /// No description provided for @entrySubtext.
  ///
  /// In en, this message translates to:
  /// **'Simply pick your favourite room at the time that suits you'**
  String get entrySubtext;

  /// No description provided for @entryStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get entryStartAction;

  /// No description provided for @entryLanguageSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get entryLanguageSwitchLabel;

  /// No description provided for @languageScreenHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get languageScreenHeading;

  /// No description provided for @authPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get authPhoneHeading;

  /// No description provided for @authPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'We use it to confirm your booking and send your room entry code. We will not use it for anything else.'**
  String get authPhoneBody;

  /// No description provided for @authPhoneFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneFieldLabel;

  /// No description provided for @authPhoneFieldHint.
  ///
  /// In en, this message translates to:
  /// **'05 1234 5678'**
  String get authPhoneFieldHint;

  /// No description provided for @authPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'We will send a verification code to this number'**
  String get authPhoneHelper;

  /// No description provided for @authPhoneTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms and the Privacy Policy.'**
  String get authPhoneTerms;

  /// No description provided for @authPhoneSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get authPhoneSubmit;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a Saudi mobile number starting with 05 (10 digits)'**
  String get authPhoneInvalid;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpTitle;

  /// No description provided for @authOtpHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent'**
  String get authOtpHeading;

  /// No description provided for @authOtpChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get authOtpChange;

  /// No description provided for @authOtpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String authOtpResendCountdown(String time);

  /// No description provided for @authOtpResendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend the code'**
  String get authOtpResendAction;

  /// No description provided for @authOtpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get authOtpSubmit;

  /// No description provided for @authOtpInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter the {length}-digit code'**
  String authOtpInvalidFormat(int length);

  /// No description provided for @authOtpErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code'**
  String get authOtpErrorTitle;

  /// No description provided for @authOtpErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Attempts remaining: {count}. Use the most recent code — earlier codes stop working as soon as a new one is sent.'**
  String authOtpErrorBody(int count);

  /// No description provided for @authOtpRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get authOtpRetry;

  /// No description provided for @authOtpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get authOtpChangeNumber;

  /// No description provided for @authOtpLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get authOtpLockedTitle;

  /// No description provided for @authOtpLockedBody.
  ///
  /// In en, this message translates to:
  /// **'For your security we stopped accepting codes. Request a new code to continue.'**
  String get authOtpLockedBody;

  /// No description provided for @authProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your details'**
  String get authProfileTitle;

  /// No description provided for @authProfileBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Write your name exactly as it appears on your ID'**
  String get authProfileBannerTitle;

  /// No description provided for @authProfileBannerBody.
  ///
  /// In en, this message translates to:
  /// **'The system matches your name against your ID during verification. Any difference may delay your check-in.'**
  String get authProfileBannerBody;

  /// No description provided for @authProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authProfileNameLabel;

  /// No description provided for @authProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mahmoud Nabil'**
  String get authProfileNameHint;

  /// No description provided for @authProfileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authProfileEmailLabel;

  /// No description provided for @authProfileEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get authProfileEmailHint;

  /// No description provided for @authProfileSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get authProfileSubmit;

  /// No description provided for @authProfileNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authProfileNameInvalid;

  /// No description provided for @authProfileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authProfileEmailInvalid;

  /// No description provided for @authSessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get authSessionExpiredTitle;

  /// No description provided for @authSessionExpiredBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended'**
  String get authSessionExpiredBannerTitle;

  /// No description provided for @authSessionExpiredBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking is saved and was not cancelled. Sign in again and we will take you back to where you left off.'**
  String get authSessionExpiredBannerBody;

  /// No description provided for @authSessionExpiredSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSessionExpiredSubmit;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Development build: the verification code is {code}.'**
  String authDemoHint(String code);

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get navBookings;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Snackbar shown when a not-yet-built bottom-nav tab is tapped.
  ///
  /// In en, this message translates to:
  /// **'This section is coming in a later update.'**
  String get navComingSoon;

  /// No description provided for @discoverGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get discoverGreeting;

  /// No description provided for @discoverGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String discoverGreetingNamed(String name);

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover the group\'s hotels'**
  String get discoverSubtitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a hotel or city'**
  String get discoverSearchHint;

  /// No description provided for @discoverNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get discoverNotificationsTooltip;

  /// No description provided for @discoverFeaturedSection.
  ///
  /// In en, this message translates to:
  /// **'Group hotels'**
  String get discoverFeaturedSection;

  /// No description provided for @discoverExploreRooms.
  ///
  /// In en, this message translates to:
  /// **'Explore rooms'**
  String get discoverExploreRooms;

  /// No description provided for @discoverUpcomingStay.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming stay'**
  String get discoverUpcomingStay;

  /// Button on the Home next-stay card (v2 Frame 38 layout; that frame shows the current-stay "extend" action).
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get discoverUpcomingStayAction;

  /// Home section title above the hotel cards (v2 HOME_Default explore header); tapping it opens search.
  ///
  /// In en, this message translates to:
  /// **'Explore the group\'s hotels'**
  String get discoverExploreHotels;

  /// No description provided for @discoverSubtitleHotel.
  ///
  /// In en, this message translates to:
  /// **'Discover {hotel}'**
  String discoverSubtitleHotel(String hotel);

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No hotels to show yet'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The group\'s hotels will appear here once they are published.'**
  String get discoverEmptyBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearTooltip;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hotels available} =1{1 hotel available} other{{count} hotels available}}'**
  String searchResultsCount(int count);

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No hotels match your search'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different city or clear your filters.'**
  String get searchNoResultsBody;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @sortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sortRecommended;

  /// No description provided for @sortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get sortTopRated;

  /// No description provided for @sortLowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get sortLowestPrice;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort results'**
  String get sortTitle;

  /// No description provided for @sortHint.
  ///
  /// In en, this message translates to:
  /// **'The order stays until you change it or search again.'**
  String get sortHint;

  /// No description provided for @sortApply.
  ///
  /// In en, this message translates to:
  /// **'Apply sort'**
  String get sortApply;

  /// No description provided for @sortActiveTag.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get sortActiveTag;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get filterTitle;

  /// No description provided for @filterMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matching hotels} =1{1 matching hotel} other{{count} matching hotels}}'**
  String filterMatchCount(int count);

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust the criteria to narrow the results.'**
  String get filterHint;

  /// No description provided for @filterCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCityLabel;

  /// No description provided for @filterValueAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterValueAll;

  /// No description provided for @filterSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String filterSelectedCount(int count);

  /// No description provided for @filterPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get filterPriceLabel;

  /// No description provided for @filterFacilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get filterFacilitiesLabel;

  /// No description provided for @filterRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterRatingLabel;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filter'**
  String get filterApply;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// No description provided for @filterCityPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCityPickerTitle;

  /// No description provided for @filterCityPickerHint.
  ///
  /// In en, this message translates to:
  /// **'You can choose more than one city. Results update when you apply.'**
  String get filterCityPickerHint;

  /// No description provided for @cityHotelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hotel} other{{count} hotels}}'**
  String cityHotelCount(int count);

  /// No description provided for @priceRangeValue.
  ///
  /// In en, this message translates to:
  /// **'SAR {min} – SAR {max}'**
  String priceRangeValue(int min, int max);

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'from SAR {amount}'**
  String priceFrom(String amount);

  /// No description provided for @pricePerNight.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount} / night'**
  String pricePerNight(String amount);

  /// No description provided for @priceStayTotal.
  ///
  /// In en, this message translates to:
  /// **'SAR {amount} total'**
  String priceStayTotal(String amount);

  /// No description provided for @priceFromLabel.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get priceFromLabel;

  /// No description provided for @priceNightSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get priceNightSuffix;

  /// No description provided for @priceTotalSuffix.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get priceTotalSuffix;

  /// No description provided for @hotelRatingValue.
  ///
  /// In en, this message translates to:
  /// **'{rating}'**
  String hotelRatingValue(double rating);

  /// No description provided for @hotelReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String hotelReviewCount(int count);

  /// No description provided for @hotelAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get hotelAvailable;

  /// No description provided for @hotelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available right now'**
  String get hotelUnavailable;

  /// No description provided for @hotelDetailAmenities.
  ///
  /// In en, this message translates to:
  /// **'Services & facilities'**
  String get hotelDetailAmenities;

  /// No description provided for @hotelRoomTypeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room type} other{{count} room types}}'**
  String hotelRoomTypeCount(int count);

  /// No description provided for @hotelPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{+{count}}}'**
  String hotelPhotoCount(int count);

  /// No description provided for @hotelSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Select dates'**
  String get hotelSelectDates;

  /// No description provided for @hotelBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get hotelBookNow;

  /// No description provided for @hotelGuestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String hotelGuestCount(int count);

  /// No description provided for @roomAreaSqm.
  ///
  /// In en, this message translates to:
  /// **'{area} m²'**
  String roomAreaSqm(int area);

  /// No description provided for @amenityFreeWifi.
  ///
  /// In en, this message translates to:
  /// **'Free Wi-Fi'**
  String get amenityFreeWifi;

  /// No description provided for @amenityBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get amenityBreakfast;

  /// No description provided for @amenityParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get amenityParking;

  /// No description provided for @amenityPool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get amenityPool;

  /// No description provided for @amenityGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get amenityGym;

  /// No description provided for @amenityFamilyRooms.
  ///
  /// In en, this message translates to:
  /// **'Family rooms'**
  String get amenityFamilyRooms;

  /// No description provided for @amenityAirportShuttle.
  ///
  /// In en, this message translates to:
  /// **'Airport shuttle'**
  String get amenityAirportShuttle;

  /// No description provided for @amenityRoomService.
  ///
  /// In en, this message translates to:
  /// **'Room service'**
  String get amenityRoomService;

  /// No description provided for @amenityAirConditioning.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get amenityAirConditioning;

  /// No description provided for @amenityCityView.
  ///
  /// In en, this message translates to:
  /// **'City view'**
  String get amenityCityView;

  /// No description provided for @amenityBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get amenityBalcony;

  /// No description provided for @amenityKitchenette.
  ///
  /// In en, this message translates to:
  /// **'Kitchenette'**
  String get amenityKitchenette;

  /// No description provided for @stayDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your stay dates'**
  String get stayDatesTitle;

  /// No description provided for @stayDatesCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get stayDatesCheckIn;

  /// No description provided for @stayDatesCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get stayDatesCheckOut;

  /// No description provided for @stayDatesPick.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get stayDatesPick;

  /// No description provided for @stayDatesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get stayDatesClear;

  /// No description provided for @stayDatesShowRooms.
  ///
  /// In en, this message translates to:
  /// **'Show available rooms'**
  String get stayDatesShowRooms;

  /// No description provided for @stayNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String stayNights(int count);

  /// No description provided for @stayDatesErrorCheckoutBeforeCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in'**
  String get stayDatesErrorCheckoutBeforeCheckin;

  /// No description provided for @stayDatesErrorPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a date from today onwards'**
  String get stayDatesErrorPast;

  /// No description provided for @stayDatesEditDates.
  ///
  /// In en, this message translates to:
  /// **'Edit dates'**
  String get stayDatesEditDates;

  /// No description provided for @guestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Number of guests'**
  String get guestsTitle;

  /// No description provided for @guestsAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get guestsAdults;

  /// No description provided for @guestsChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get guestsChildren;

  /// No description provided for @guestsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm guests'**
  String get guestsConfirm;

  /// No description provided for @stepperDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get stepperDecrease;

  /// No description provided for @stepperIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get stepperIncrease;

  /// No description provided for @guestsAdultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adult} other{{count} adults}}'**
  String guestsAdultsCount(int count);

  /// No description provided for @guestsChildrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child} other{{count} children}}'**
  String guestsChildrenCount(int count);

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available rooms'**
  String get roomsTitle;

  /// No description provided for @roomsAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rooms available} =1{1 room available} other{{count} rooms available}}'**
  String roomsAvailableCount(int count);

  /// No description provided for @roomsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get roomsSortLabel;

  /// No description provided for @roomsSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get roomsSortLowest;

  /// No description provided for @roomsSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get roomsSortHighest;

  /// No description provided for @roomOccupancy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String roomOccupancy(int count);

  /// No description provided for @roomBreakfastIncluded.
  ///
  /// In en, this message translates to:
  /// **'Breakfast included'**
  String get roomBreakfastIncluded;

  /// No description provided for @roomFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get roomFreeCancellation;

  /// No description provided for @roomNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get roomNonRefundable;

  /// No description provided for @roomSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Not available for these dates'**
  String get roomSoldOut;

  /// No description provided for @roomsAllSoldOutTitle.
  ///
  /// In en, this message translates to:
  /// **'All rooms are sold out for these dates'**
  String get roomsAllSoldOutTitle;

  /// No description provided for @roomsAllSoldOutBody.
  ///
  /// In en, this message translates to:
  /// **'Try different dates and we will show the rooms that open up.'**
  String get roomsAllSoldOutBody;

  /// No description provided for @roomsNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No rooms for these dates'**
  String get roomsNoResultsTitle;

  /// No description provided for @roomsNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try different dates or adjust the number of guests.'**
  String get roomsNoResultsBody;

  /// No description provided for @roomsChangeDates.
  ///
  /// In en, this message translates to:
  /// **'Change dates'**
  String get roomsChangeDates;

  /// No description provided for @roomsChangeGuests.
  ///
  /// In en, this message translates to:
  /// **'Change guests'**
  String get roomsChangeGuests;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Seven short weekday names, Sunday first, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'Sun,Mon,Tue,Wed,Thu,Fri,Sat'**
  String get calendarWeekdays;

  /// Selected check-in – check-out summary; dates are pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'{checkIn} – {checkOut}'**
  String stayDatesSelectedRange(String checkIn, String checkOut);

  /// No description provided for @stayDatesHintPickCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Choose your check-in date to start'**
  String get stayDatesHintPickCheckIn;

  /// No description provided for @stayDatesHintPickCheckOut.
  ///
  /// In en, this message translates to:
  /// **'{checkIn} · choose your check-out date'**
  String stayDatesHintPickCheckOut(String checkIn);

  /// No description provided for @stayDatesFieldPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get stayDatesFieldPlaceholder;

  /// No description provided for @roomSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get roomSelect;

  /// No description provided for @roomSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get roomSelected;

  /// No description provided for @roomViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get roomViewDetails;

  /// No description provided for @roomDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Room details'**
  String get roomDetailsTitle;

  /// No description provided for @roomBedType.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get roomBedType;

  /// No description provided for @roomCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleeps'**
  String get roomCapacityLabel;

  /// No description provided for @roomPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get roomPolicyLabel;

  /// No description provided for @roomPolicyRefundable.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation with a full refund within {hours} hours of booking, or until check-in if sooner.'**
  String roomPolicyRefundable(int hours);

  /// No description provided for @roomPolicyRefundableShort.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation available'**
  String get roomPolicyRefundableShort;

  /// No description provided for @roomPolicyNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get roomPolicyNonRefundable;

  /// No description provided for @roomSelectThisRoom.
  ///
  /// In en, this message translates to:
  /// **'Select this room'**
  String get roomSelectThisRoom;

  /// No description provided for @roomRemoveSelection.
  ///
  /// In en, this message translates to:
  /// **'Remove selection'**
  String get roomRemoveSelection;

  /// No description provided for @roomStayTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'total for {nights, plural, =1{1 night} other{{nights} nights}}'**
  String roomStayTotalLabel(int nights);

  /// No description provided for @roomCardPerNight.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get roomCardPerNight;

  /// No description provided for @roomCardFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get roomCardFreeCancellation;

  /// No description provided for @stayGuestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String stayGuestsCount(int count);

  /// No description provided for @roomDetailAmenitiesHeading.
  ///
  /// In en, this message translates to:
  /// **'Room facilities'**
  String get roomDetailAmenitiesHeading;

  /// No description provided for @roomDetailCancellationHeading.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get roomDetailCancellationHeading;

  /// No description provided for @roomDetailStayHeading.
  ///
  /// In en, this message translates to:
  /// **'Your stay'**
  String get roomDetailStayHeading;

  /// No description provided for @roomSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort rooms'**
  String get roomSortTitle;

  /// No description provided for @roomSortApply.
  ///
  /// In en, this message translates to:
  /// **'Apply sort'**
  String get roomSortApply;

  /// No description provided for @roomSortActiveTag.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get roomSortActiveTag;

  /// No description provided for @roomsSortTrigger.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String roomsSortTrigger(String label);

  /// No description provided for @roomsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get roomsContinue;

  /// No description provided for @roomFilterWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get roomFilterWifi;

  /// No description provided for @roomsFilterCta.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get roomsFilterCta;

  /// No description provided for @roomsNoFilterMatch.
  ///
  /// In en, this message translates to:
  /// **'No rooms match these filters'**
  String get roomsNoFilterMatch;

  /// No description provided for @roomFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter rooms'**
  String get roomFilterTitle;

  /// No description provided for @roomFilterCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get roomFilterCancellation;

  /// No description provided for @roomFilterFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get roomFilterFreeCancellation;

  /// No description provided for @roomFilterMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get roomFilterMeals;

  /// No description provided for @roomFilterBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast included'**
  String get roomFilterBreakfast;

  /// No description provided for @roomFilterFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get roomFilterFeatures;

  /// No description provided for @roomFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get roomFilterReset;

  /// No description provided for @roomFilterShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get roomFilterShowResults;

  /// No description provided for @roomsSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a room to continue'**
  String get roomsSelectPrompt;

  /// No description provided for @roomsSelectionClearedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your room selection was cleared because the stay details changed. Choose a room again.'**
  String get roomsSelectionClearedNotice;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your selection'**
  String get reviewTitle;

  /// No description provided for @reviewNotBookedNotice.
  ///
  /// In en, this message translates to:
  /// **'Nothing is booked yet. You can still change your dates, guests or room before the reservation step.'**
  String get reviewNotBookedNotice;

  /// No description provided for @reviewHotelLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get reviewHotelLabel;

  /// No description provided for @reviewRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get reviewRoomLabel;

  /// No description provided for @reviewStayLabel.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get reviewStayLabel;

  /// No description provided for @reviewGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get reviewGuestsLabel;

  /// No description provided for @reviewCheckInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get reviewCheckInLabel;

  /// No description provided for @reviewCheckOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get reviewCheckOutLabel;

  /// No description provided for @reviewPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get reviewPriceLabel;

  /// No description provided for @reviewTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total for {nights, plural, =1{1 night} other{{nights} nights}}'**
  String reviewTotalLabel(int nights);

  /// No description provided for @reviewChangeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change selection'**
  String get reviewChangeSelection;

  /// No description provided for @reviewNoSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No room selected'**
  String get reviewNoSelectionTitle;

  /// No description provided for @reviewNoSelectionBody.
  ///
  /// In en, this message translates to:
  /// **'Go back and choose a room to see your selection here.'**
  String get reviewNoSelectionBody;

  /// No description provided for @reviewBackToRooms.
  ///
  /// In en, this message translates to:
  /// **'Back to rooms'**
  String get reviewBackToRooms;

  /// Primary CTA on the review screen for a guest who has not signed in yet.
  ///
  /// In en, this message translates to:
  /// **'Sign in to confirm'**
  String get reviewSignInToConfirm;

  /// Helper line under the review summary explaining why sign-in is required at this step.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need an account to confirm this booking. Browsing stays free.'**
  String get reviewSignInHint;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailsTitle;

  /// No description provided for @bookingDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stay dates'**
  String get bookingDatesLabel;

  /// No description provided for @bookingRoomSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Stay subtotal'**
  String get bookingRoomSubtotal;

  /// No description provided for @bookingServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get bookingServiceFee;

  /// No description provided for @bookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// No description provided for @bookingProceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to payment'**
  String get bookingProceedToPayment;

  /// No description provided for @bookingRoomAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get bookingRoomAvailable;

  /// No description provided for @reservationConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm reservation'**
  String get reservationConfirmCta;

  /// No description provided for @reservationConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get reservationConfirming;

  /// No description provided for @reservationConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'By confirming, you request this room for the dates above. Nothing is charged yet.'**
  String get reservationConfirmHint;

  /// No description provided for @reservationCreateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm your reservation'**
  String get reservationCreateFailedTitle;

  /// No description provided for @reservationStatusFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reservationStatusFieldLabel;

  /// No description provided for @reservationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reservationStatusPending;

  /// Guest-facing umbrella label for a secured booking (design-system content/status/confirmed). ReservationStatus itself has no `confirmed` member; used on the confirmation screen and future Bookings-list filter.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get reservationStatusConfirmed;

  /// No description provided for @reservationStatusDepositHeld.
  ///
  /// In en, this message translates to:
  /// **'Deposit held'**
  String get reservationStatusDepositHeld;

  /// No description provided for @reservationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get reservationStatusVerified;

  /// No description provided for @reservationStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get reservationStatusCheckedIn;

  /// No description provided for @reservationStatusInStay.
  ///
  /// In en, this message translates to:
  /// **'In stay'**
  String get reservationStatusInStay;

  /// No description provided for @reservationStatusCheckoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'Checkout in progress'**
  String get reservationStatusCheckoutInProgress;

  /// No description provided for @reservationStatusCheckoutBlocked.
  ///
  /// In en, this message translates to:
  /// **'Checkout on hold'**
  String get reservationStatusCheckoutBlocked;

  /// No description provided for @reservationStatusCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get reservationStatusCheckedOut;

  /// No description provided for @reservationStatusInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Invoiced'**
  String get reservationStatusInvoiced;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reservationStatusCancelled;

  /// A currency amount, e.g. 'SAR 900'.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String moneyAmount(String currency, String amount);

  /// No description provided for @paymentReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentReviewTitle;

  /// No description provided for @paymentProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing payment'**
  String get paymentProcessingTitle;

  /// No description provided for @paymentResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentResultTitle;

  /// No description provided for @paymentReservationLabel.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get paymentReservationLabel;

  /// No description provided for @paymentStatusFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatusFieldLabel;

  /// No description provided for @paymentPayNowCta.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get paymentPayNowCta;

  /// No description provided for @paymentHoldExplainer.
  ///
  /// In en, this message translates to:
  /// **'A refundable deposit hold is placed for your stay. Nothing is charged now.'**
  String get paymentHoldExplainer;

  /// No description provided for @paymentProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Confirming your payment…'**
  String get paymentProcessingBody;

  /// No description provided for @paymentDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please keep this screen open.'**
  String get paymentDoNotClose;

  /// No description provided for @paymentAlreadyHeldTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit already held'**
  String get paymentAlreadyHeldTitle;

  /// No description provided for @paymentAlreadyHeldBody.
  ///
  /// In en, this message translates to:
  /// **'The deposit hold for this reservation is already in place.'**
  String get paymentAlreadyHeldBody;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit hold confirmed'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentNotRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking is confirmed'**
  String get paymentNotRequiredTitle;

  /// No description provided for @paymentNotRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This hotel takes no deposit. Your stay starts at check-in.'**
  String get paymentNotRequiredBody;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your deposit is secured. You can continue with identity verification.'**
  String get paymentSuccessBody;

  /// No description provided for @paymentPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment is processing'**
  String get paymentPendingTitle;

  /// No description provided for @paymentPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your bank hasn\'t confirmed the hold yet. You can check the status again shortly.'**
  String get paymentPendingBody;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment didn\'t go through'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'No money was taken. You can try again.'**
  String get paymentFailedBody;

  /// No description provided for @paymentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelledTitle;

  /// No description provided for @paymentExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment hold expired'**
  String get paymentExpiredTitle;

  /// No description provided for @paymentRetryCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paymentRetryCta;

  /// No description provided for @paymentBackToReservation.
  ///
  /// In en, this message translates to:
  /// **'Back to reservation'**
  String get paymentBackToReservation;

  /// No description provided for @paymentUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment is unavailable'**
  String get paymentUnavailableTitle;

  /// No description provided for @paymentStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get paymentStatusNotStarted;

  /// No description provided for @paymentStatusHoldRequested.
  ///
  /// In en, this message translates to:
  /// **'Authorizing'**
  String get paymentStatusHoldRequested;

  /// No description provided for @paymentStatusHoldActive.
  ///
  /// In en, this message translates to:
  /// **'Deposit held'**
  String get paymentStatusHoldActive;

  /// No description provided for @paymentStatusHoldFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusHoldFailed;

  /// No description provided for @paymentStatusCaptureRequested.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get paymentStatusCaptureRequested;

  /// No description provided for @paymentStatusCaptured.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get paymentStatusCaptured;

  /// No description provided for @paymentStatusCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Charge failed'**
  String get paymentStatusCaptureFailed;

  /// No description provided for @paymentStatusFinalSettlementRequested.
  ///
  /// In en, this message translates to:
  /// **'Settling'**
  String get paymentStatusFinalSettlementRequested;

  /// No description provided for @paymentStatusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get paymentStatusSettled;

  /// No description provided for @paymentStatusSettlementFailed.
  ///
  /// In en, this message translates to:
  /// **'Settlement failed'**
  String get paymentStatusSettlementFailed;

  /// No description provided for @paymentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentStatusCancelled;

  /// No description provided for @paymentStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get paymentStatusExpired;

  /// No description provided for @paymentStatusRefundRequested.
  ///
  /// In en, this message translates to:
  /// **'Refund pending'**
  String get paymentStatusRefundRequested;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @paymentStatusRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed'**
  String get paymentStatusRefundFailed;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodTitle;

  /// No description provided for @paymentMethodBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method'**
  String get paymentMethodBannerTitle;

  /// No description provided for @paymentMethodBannerBody.
  ///
  /// In en, this message translates to:
  /// **'The deposit hold is placed without a fee and released after check-out, unless extra charges are recorded.'**
  String get paymentMethodBannerBody;

  /// No description provided for @paymentMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get paymentMethodApplePay;

  /// No description provided for @paymentMethodSavedCard.
  ///
  /// In en, this message translates to:
  /// **'Card or debit card'**
  String get paymentMethodSavedCard;

  /// No description provided for @paymentMethodAddNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add a new card'**
  String get paymentMethodAddNewCard;

  /// No description provided for @paymentHoldNotice.
  ///
  /// In en, this message translates to:
  /// **'The deposit is held, not charged, until check-in'**
  String get paymentHoldNotice;

  /// No description provided for @paymentCardDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentCardDetailsTitle;

  /// No description provided for @paymentCardDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit amount'**
  String get paymentCardDepositLabel;

  /// No description provided for @paymentCardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get paymentCardNumberLabel;

  /// No description provided for @paymentCardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'4242 4242 4242 4242'**
  String get paymentCardNumberHint;

  /// No description provided for @paymentCardholderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get paymentCardholderNameLabel;

  /// No description provided for @paymentCardNotStoredNote.
  ///
  /// In en, this message translates to:
  /// **'Your card details are not stored in the system.'**
  String get paymentCardNotStoredNote;

  /// No description provided for @paymentConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get paymentConfirmCta;

  /// No description provided for @identityVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityVerificationTitle;

  /// No description provided for @identityVerificationResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityVerificationResultTitle;

  /// No description provided for @identityVerifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get identityVerifyCta;

  /// No description provided for @identityStepDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get identityStepDocument;

  /// No description provided for @identityStepSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get identityStepSelfie;

  /// No description provided for @identityStepResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get identityStepResult;

  /// No description provided for @identityDocumentStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your ID document'**
  String get identityDocumentStepTitle;

  /// No description provided for @identityDocumentStepBody.
  ///
  /// In en, this message translates to:
  /// **'Use your passport, national ID or residence permit. Make sure the whole document is visible and readable.'**
  String get identityDocumentStepBody;

  /// No description provided for @identityDocumentTypePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get identityDocumentTypePassport;

  /// No description provided for @identityDocumentTypeNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get identityDocumentTypeNationalId;

  /// No description provided for @identityDocumentTypeResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence permit'**
  String get identityDocumentTypeResidencePermit;

  /// No description provided for @identityDocumentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get identityDocumentTypeLabel;

  /// No description provided for @identityDocumentCaptureCta.
  ///
  /// In en, this message translates to:
  /// **'Add document photo'**
  String get identityDocumentCaptureCta;

  /// No description provided for @identityDocumentCapturedLabel.
  ///
  /// In en, this message translates to:
  /// **'Document photo added'**
  String get identityDocumentCapturedLabel;

  /// No description provided for @identityDocumentSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Continue to selfie'**
  String get identityDocumentSubmitCta;

  /// No description provided for @identitySelfieStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie'**
  String get identitySelfieStepTitle;

  /// No description provided for @identitySelfieStepBody.
  ///
  /// In en, this message translates to:
  /// **'Look straight at the camera in good light. We match your selfie to your ID photo.'**
  String get identitySelfieStepBody;

  /// No description provided for @identitySelfieCaptureCta.
  ///
  /// In en, this message translates to:
  /// **'Add selfie'**
  String get identitySelfieCaptureCta;

  /// No description provided for @identitySelfieCapturedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selfie added'**
  String get identitySelfieCapturedLabel;

  /// No description provided for @identitySelfieSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get identitySelfieSubmitCta;

  /// No description provided for @identityProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verifying your identity'**
  String get identityProcessingTitle;

  /// No description provided for @identityProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Matching your selfie to your document…'**
  String get identityProcessingBody;

  /// No description provided for @identityApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get identityApprovedTitle;

  /// No description provided for @identityApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity is confirmed. You\'re ready for check-in.'**
  String get identityApprovedBody;

  /// No description provided for @identityManualReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual review in progress'**
  String get identityManualReviewTitle;

  /// No description provided for @identityManualReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing your documents. This usually takes a short while — we\'ll notify you when it\'s done.'**
  String get identityManualReviewBody;

  /// No description provided for @identityRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try that again'**
  String get identityRetryTitle;

  /// No description provided for @identityRetryBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify your identity from those photos. Please retake them and submit again.'**
  String get identityRetryBody;

  /// No description provided for @identityRetryCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get identityRetryCta;

  /// No description provided for @identityRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification not approved'**
  String get identityRejectedTitle;

  /// No description provided for @identityRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Our team could not approve your identity verification. Please contact the front desk for help.'**
  String get identityRejectedBody;

  /// No description provided for @identityRejectedRetryBody.
  ///
  /// In en, this message translates to:
  /// **'Our team could not approve your identity verification. You can submit new photos and try again.'**
  String get identityRejectedRetryBody;

  /// No description provided for @identityAttemptCount.
  ///
  /// In en, this message translates to:
  /// **'Attempt {count}'**
  String identityAttemptCount(int count);

  /// No description provided for @identityBackToReservation.
  ///
  /// In en, this message translates to:
  /// **'Back to reservation'**
  String get identityBackToReservation;

  /// No description provided for @identityViewResultCta.
  ///
  /// In en, this message translates to:
  /// **'View result'**
  String get identityViewResultCta;

  /// No description provided for @identityUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification is unavailable'**
  String get identityUnavailableTitle;

  /// No description provided for @identityStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get identityStatusNotStarted;

  /// No description provided for @identityStatusDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded'**
  String get identityStatusDocumentUploaded;

  /// No description provided for @identityStatusSelfieCaptured.
  ///
  /// In en, this message translates to:
  /// **'Selfie captured'**
  String get identityStatusSelfieCaptured;

  /// No description provided for @identityStatusMatchingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get identityStatusMatchingInProgress;

  /// No description provided for @identityStatusAutoApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get identityStatusAutoApproved;

  /// No description provided for @identityStatusPendingManualReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get identityStatusPendingManualReview;

  /// No description provided for @identityStatusStaffApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get identityStatusStaffApproved;

  /// No description provided for @identityStatusStaffRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get identityStatusStaffRejected;

  /// No description provided for @identityStatusRetryAllowed.
  ///
  /// In en, this message translates to:
  /// **'Retry needed'**
  String get identityStatusRetryAllowed;

  /// No description provided for @identityIntroBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick identity check'**
  String get identityIntroBannerTitle;

  /// No description provided for @identityIntroBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Two steps: a photo of your ID, then a live selfie. Photos are deleted once your stay ends.'**
  String get identityIntroBannerBody;

  /// No description provided for @identityIntroBannerBodyDocumentOnly.
  ///
  /// In en, this message translates to:
  /// **'One step: a photo of your ID. Photos are deleted once your stay ends.'**
  String get identityIntroBannerBodyDocumentOnly;

  /// No description provided for @identityDocumentOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your document type, then take a clear photo of it.'**
  String get identityDocumentOnlyBody;

  /// No description provided for @identityIntroCta.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get identityIntroCta;

  /// No description provided for @identityCaptureDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph your ID'**
  String get identityCaptureDocumentTitle;

  /// No description provided for @identityCaptureDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the ID inside the frame with all four edges visible.'**
  String get identityCaptureDocumentHint;

  /// No description provided for @identityCaptureFootnote.
  ///
  /// In en, this message translates to:
  /// **'Camera only — no photo library uploads'**
  String get identityCaptureFootnote;

  /// No description provided for @identityCaptureFootnoteWeb.
  ///
  /// In en, this message translates to:
  /// **'Choose a clear photo of your ID'**
  String get identityCaptureFootnoteWeb;

  /// No description provided for @identitySelfieFootnoteWeb.
  ///
  /// In en, this message translates to:
  /// **'Choose a clear photo of your face'**
  String get identitySelfieFootnoteWeb;

  /// No description provided for @identityCaptureFootnoteSecurity.
  ///
  /// In en, this message translates to:
  /// **'Your photos are stored securely and deleted once your stay ends.'**
  String get identityCaptureFootnoteSecurity;

  /// No description provided for @identityReviewDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the ID photo'**
  String get identityReviewDocumentTitle;

  /// No description provided for @identityReviewDocumentBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure the name, number and expiry date are readable.'**
  String get identityReviewDocumentBody;

  /// No description provided for @identityReviewContinueCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get identityReviewContinueCta;

  /// No description provided for @identityReviewRetakeCta.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get identityReviewRetakeCta;

  /// No description provided for @identityCaptureSelfieTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityCaptureSelfieTitle;

  /// No description provided for @identityCaptureSelfieHint.
  ///
  /// In en, this message translates to:
  /// **'Take a live photo from the camera'**
  String get identityCaptureSelfieHint;

  /// No description provided for @identityReviewRetakeHint.
  ///
  /// In en, this message translates to:
  /// **'You can retake it if the photo isn\'t clear'**
  String get identityReviewRetakeHint;

  /// No description provided for @identityShutterLabel.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get identityShutterLabel;

  /// No description provided for @identityCameraDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t access the camera'**
  String get identityCameraDeniedTitle;

  /// No description provided for @identityCameraDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Verification needs a live camera photo and can\'t use the photo library. Allow camera access in Settings.'**
  String get identityCameraDeniedBody;

  /// No description provided for @identityCameraUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device. Finish verification on another device or at reception.'**
  String get identityCameraUnavailableBody;

  /// No description provided for @identityOpenSettingsCta.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get identityOpenSettingsCta;

  /// No description provided for @identityUploadingBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploading your photo'**
  String get identityUploadingBannerTitle;

  /// No description provided for @identityUploadingBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t close the app. This usually takes a few seconds on a good connection.'**
  String get identityUploadingBannerBody;

  /// No description provided for @identityUploadingCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get identityUploadingCancelCta;

  /// No description provided for @identityProcessingContinueCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get identityProcessingContinueCta;

  /// No description provided for @identitySuccessBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get identitySuccessBannerTitle;

  /// No description provided for @identitySuccessBannerBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be asked to upload your ID again at any hotel in the group.'**
  String get identitySuccessBannerBody;

  /// No description provided for @identityGoToCheckInCta.
  ///
  /// In en, this message translates to:
  /// **'Digital check-in'**
  String get identityGoToCheckInCta;

  /// No description provided for @identityRejectedNoRetryBannerBody.
  ///
  /// In en, this message translates to:
  /// **'A staff member reviewed and did not approve your submission. You can complete this in person when you arrive — your reservation is kept.'**
  String get identityRejectedNoRetryBannerBody;

  /// No description provided for @identityContactReceptionCta.
  ///
  /// In en, this message translates to:
  /// **'Contact reception'**
  String get identityContactReceptionCta;

  /// No description provided for @identityFailedUploadBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your photos'**
  String get identityFailedUploadBannerTitle;

  /// No description provided for @identityFailedUploadBannerBody.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped while uploading. Your photos are saved on your device — you can retry without retaking them.'**
  String get identityFailedUploadBannerBody;

  /// No description provided for @identityRetryUploadCta.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get identityRetryUploadCta;

  /// No description provided for @identityContinueLaterCta.
  ///
  /// In en, this message translates to:
  /// **'Continue later'**
  String get identityContinueLaterCta;

  /// No description provided for @identityFaceNotMatchedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t match your face'**
  String get identityFaceNotMatchedBannerTitle;

  /// No description provided for @identityFaceNotMatchedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'The live photo didn\'t match your ID closely enough. Try again in good light, facing the camera directly.'**
  String get identityFaceNotMatchedBannerBody;

  /// No description provided for @identityRequestManualReviewCta.
  ///
  /// In en, this message translates to:
  /// **'Request manual review'**
  String get identityRequestManualReviewCta;

  /// No description provided for @identityDocumentUnclearBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo isn\'t clear'**
  String get identityDocumentUnclearBannerTitle;

  /// No description provided for @identityDocumentUnclearBannerBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read your ID details. Retake the photo with no glare and all four edges visible.'**
  String get identityDocumentUnclearBannerBody;

  /// No description provided for @identityContactReceptionBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Reception is available 24/7'**
  String get identityContactReceptionBannerTitle;

  /// No description provided for @identityContactReceptionBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Reception is available around the clock at your hotel. A staff member can complete verification in person on arrival.'**
  String get identityContactReceptionBannerBody;

  /// No description provided for @contactReceptionBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll connect you to your hotel\'s reception directly on {phone}.'**
  String contactReceptionBody(String phone);

  /// No description provided for @contactReceptionNoPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'You can reach the reception team directly at the hotel front desk.'**
  String get contactReceptionNoPhoneBody;

  /// No description provided for @contactReceptionCallCta.
  ///
  /// In en, this message translates to:
  /// **'Call reception'**
  String get contactReceptionCallCta;

  /// No description provided for @contactReceptionCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start a call on this device. Reception number: {phone}'**
  String contactReceptionCallFailed(String phone);

  /// No description provided for @identityViewVerificationStatusCta.
  ///
  /// In en, this message translates to:
  /// **'View verification status'**
  String get identityViewVerificationStatusCta;

  /// No description provided for @identityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your ID details'**
  String get identityDetailsTitle;

  /// No description provided for @identityDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Enter them exactly as printed on your document. We compare them with the photo of your ID and don\'t keep them.'**
  String get identityDetailsBody;

  /// No description provided for @identityFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name as on the document'**
  String get identityFullNameLabel;

  /// No description provided for @identityFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'For a passport, use the Latin letters printed on it'**
  String get identityFullNameHint;

  /// No description provided for @identityDocumentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get identityDocumentNumberLabel;

  /// No description provided for @identityDateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get identityDateOfBirthLabel;

  /// No description provided for @identityDateOfBirthHint.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get identityDateOfBirthHint;

  /// No description provided for @identityFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get identityFieldRequired;

  /// No description provided for @identityDocumentNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers only'**
  String get identityDocumentNumberInvalid;

  /// No description provided for @identityUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% uploaded'**
  String identityUploadProgress(String percent);

  /// No description provided for @identityReadingDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading your ID'**
  String get identityReadingDocumentTitle;

  /// No description provided for @identityReadingDocumentBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re checking the details on your document. This takes a few seconds — please keep the app open.'**
  String get identityReadingDocumentBody;

  /// No description provided for @identityMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details don\'t match your ID'**
  String get identityMismatchTitle;

  /// No description provided for @identityMismatchFieldsBody.
  ///
  /// In en, this message translates to:
  /// **'Check what you entered against your document: {fields}.'**
  String identityMismatchFieldsBody(String fields);

  /// No description provided for @identityMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'What you entered doesn\'t match the document. Check your details or retake the photo.'**
  String get identityMismatchBody;

  /// No description provided for @identityFieldName.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get identityFieldName;

  /// No description provided for @identityFieldDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'document number'**
  String get identityFieldDocumentNumber;

  /// No description provided for @identityFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'date of birth'**
  String get identityFieldDateOfBirth;

  /// No description provided for @identityEditDetailsCta.
  ///
  /// In en, this message translates to:
  /// **'Edit my details'**
  String get identityEditDetailsCta;

  /// No description provided for @identityExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This document has expired'**
  String get identityExpiredTitle;

  /// No description provided for @identityExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your ID must be valid on your check-in date. Use another valid document.'**
  String get identityExpiredBody;

  /// No description provided for @identityUseAnotherDocumentCta.
  ///
  /// In en, this message translates to:
  /// **'Use another document'**
  String get identityUseAnotherDocumentCta;

  /// No description provided for @identityUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'This document isn\'t accepted'**
  String get identityUnsupportedTitle;

  /// No description provided for @identityUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Use your passport, national ID or residence permit.'**
  String get identityUnsupportedBody;

  /// No description provided for @identityDocumentTypeEgyptianId.
  ///
  /// In en, this message translates to:
  /// **'Egyptian National ID'**
  String get identityDocumentTypeEgyptianId;

  /// No description provided for @identityDocumentTypeSaudiId.
  ///
  /// In en, this message translates to:
  /// **'Saudi National ID'**
  String get identityDocumentTypeSaudiId;

  /// No description provided for @identityDocumentTypeSaudiIqama.
  ///
  /// In en, this message translates to:
  /// **'Saudi Iqama (residence)'**
  String get identityDocumentTypeSaudiIqama;

  /// No description provided for @identityDocumentSidesFrontOnly.
  ///
  /// In en, this message translates to:
  /// **'Photo of the details page only'**
  String get identityDocumentSidesFrontOnly;

  /// No description provided for @identityDocumentSidesFrontAndBack.
  ///
  /// In en, this message translates to:
  /// **'Photos of the front and the back'**
  String get identityDocumentSidesFrontAndBack;

  /// No description provided for @identityDocumentSidesBackOptional.
  ///
  /// In en, this message translates to:
  /// **'Front photo — back optional'**
  String get identityDocumentSidesBackOptional;

  /// No description provided for @identityDocumentStaffCheck.
  ///
  /// In en, this message translates to:
  /// **'Our staff will check this document'**
  String get identityDocumentStaffCheck;

  /// No description provided for @identityFullNameArabicHint.
  ///
  /// In en, this message translates to:
  /// **'In Arabic, exactly as printed: first name, then the rest of the name'**
  String get identityFullNameArabicHint;

  /// No description provided for @identityBirthDateFromNumber.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth is read from the national number.'**
  String get identityBirthDateFromNumber;

  /// No description provided for @identityDocumentNumberInvalidForType.
  ///
  /// In en, this message translates to:
  /// **'Check the number format for this document'**
  String get identityDocumentNumberInvalidForType;

  /// No description provided for @identityCaptureBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph the back'**
  String get identityCaptureBackTitle;

  /// No description provided for @identityCaptureBackHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the card over and fit it inside the frame.'**
  String get identityCaptureBackHint;

  /// No description provided for @identityCaptureTipFrame.
  ///
  /// In en, this message translates to:
  /// **'The whole card inside the frame, all four edges visible'**
  String get identityCaptureTipFrame;

  /// No description provided for @identityCaptureTipLight.
  ///
  /// In en, this message translates to:
  /// **'Good light, no flash or glare on the card'**
  String get identityCaptureTipLight;

  /// No description provided for @identityCaptureTipSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone steady over the card so the text is sharp'**
  String get identityCaptureTipSteady;

  /// No description provided for @identitySelfieTipFrame.
  ///
  /// In en, this message translates to:
  /// **'Your whole face inside the frame, looking at the camera'**
  String get identitySelfieTipFrame;

  /// No description provided for @identitySelfieTipClear.
  ///
  /// In en, this message translates to:
  /// **'No sunglasses or face covering, in good light'**
  String get identitySelfieTipClear;

  /// No description provided for @identityCaptureSelfieHintWeb.
  ///
  /// In en, this message translates to:
  /// **'Choose a recent, clear photo of your face'**
  String get identityCaptureSelfieHintWeb;

  /// No description provided for @identityStuckContactReception.
  ///
  /// In en, this message translates to:
  /// **'Can\'t continue? Contact reception'**
  String get identityStuckContactReception;

  /// No description provided for @identitySkipBackCta.
  ///
  /// In en, this message translates to:
  /// **'Skip — front only'**
  String get identitySkipBackCta;

  /// No description provided for @identityReviewBothSides.
  ///
  /// In en, this message translates to:
  /// **'Front and back photos are ready. Make sure every detail is readable.'**
  String get identityReviewBothSides;

  /// No description provided for @identityDocumentAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Document accepted'**
  String get identityDocumentAcceptedTitle;

  /// No description provided for @identityDocumentAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'Your details match your document. Next, take a live selfie.'**
  String get identityDocumentAcceptedBody;

  /// No description provided for @identityDocumentReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual review required'**
  String get identityDocumentReviewTitle;

  /// No description provided for @identityDocumentReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Our staff will confirm your document. Continue with the selfie to finish your part.'**
  String get identityDocumentReviewBody;

  /// No description provided for @identitySubmitFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your document'**
  String get identitySubmitFailedTitle;

  /// No description provided for @reservationCheckInCta.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get reservationCheckInCta;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkInTitle;

  /// No description provided for @checkInProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking you in'**
  String get checkInProcessingTitle;

  /// No description provided for @accessTitle.
  ///
  /// In en, this message translates to:
  /// **'Room access'**
  String get accessTitle;

  /// No description provided for @checkInReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to check in'**
  String get checkInReadyTitle;

  /// No description provided for @checkInReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your reservation is verified. Check in to get your room number and entry code.'**
  String get checkInReadyBody;

  /// No description provided for @checkInNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not ready to check in yet'**
  String get checkInNotReadyTitle;

  /// No description provided for @checkInRoomNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Your room is being prepared — check-in opens once reception assigns it.'**
  String get checkInRoomNotAssigned;

  /// No description provided for @checkInAtReception.
  ///
  /// In en, this message translates to:
  /// **'This hotel checks guests in at reception when you arrive.'**
  String get checkInAtReception;

  /// No description provided for @checkInIdentityPending.
  ///
  /// In en, this message translates to:
  /// **'Complete identity verification first.'**
  String get checkInIdentityPending;

  /// No description provided for @checkInNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete payment and identity verification first.'**
  String get checkInNotReadyBody;

  /// No description provided for @checkInUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in isn\'t available'**
  String get checkInUnavailableTitle;

  /// No description provided for @checkInAlreadyDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re already checked in'**
  String get checkInAlreadyDoneTitle;

  /// No description provided for @checkInCta.
  ///
  /// In en, this message translates to:
  /// **'Check in now'**
  String get checkInCta;

  /// No description provided for @checkInProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Issuing your digital room key…'**
  String get checkInProcessingBody;

  /// No description provided for @checkInDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please keep this screen open.'**
  String get checkInDoNotClose;

  /// No description provided for @checkInFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in didn\'t complete'**
  String get checkInFailedTitle;

  /// No description provided for @checkInFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your room key couldn\'t be issued. You can try again.'**
  String get checkInFailedBody;

  /// No description provided for @checkInPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get checkInPendingTitle;

  /// No description provided for @checkInPendingBody.
  ///
  /// In en, this message translates to:
  /// **'The front desk is finishing your check-in. Check again shortly.'**
  String get checkInPendingBody;

  /// No description provided for @checkInRetryCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get checkInRetryCta;

  /// No description provided for @accessCheckedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re checked in'**
  String get accessCheckedInTitle;

  /// No description provided for @accessRoomNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Room number'**
  String get accessRoomNumberLabel;

  /// No description provided for @accessEntryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry code'**
  String get accessEntryCodeLabel;

  /// No description provided for @accessStayEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your stay ends · {date}'**
  String accessStayEndsLabel(String date);

  /// No description provided for @accessRoomPending.
  ///
  /// In en, this message translates to:
  /// **'Assigned by reception'**
  String get accessRoomPending;

  /// No description provided for @accessKeyNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Key not working?'**
  String get accessKeyNotWorking;

  /// No description provided for @accessExpiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid until your stay ends · {date}'**
  String accessExpiresLabel(String date);

  /// No description provided for @accessHelpBanner.
  ///
  /// In en, this message translates to:
  /// **'Code not working? Contact reception.'**
  String get accessHelpBanner;

  /// No description provided for @accessNotIssuedTitle.
  ///
  /// In en, this message translates to:
  /// **'No room key yet'**
  String get accessNotIssuedTitle;

  /// No description provided for @accessNotIssuedBody.
  ///
  /// In en, this message translates to:
  /// **'Check in to get your digital room key.'**
  String get accessNotIssuedBody;

  /// No description provided for @accessRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Room key deactivated'**
  String get accessRevokedTitle;

  /// No description provided for @accessRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'This room key is no longer active. Contact reception if you need help.'**
  String get accessRevokedBody;

  /// No description provided for @accessExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Room key expired'**
  String get accessExpiredTitle;

  /// No description provided for @accessExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your stay has ended, so this room key no longer works.'**
  String get accessExpiredBody;

  /// No description provided for @accessFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Room key unavailable'**
  String get accessFailedTitle;

  /// No description provided for @accessUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Access is unavailable'**
  String get accessUnavailableTitle;

  /// No description provided for @accessBackToReservation.
  ///
  /// In en, this message translates to:
  /// **'Back to reservation'**
  String get accessBackToReservation;

  /// No description provided for @accessStatusNotIssued.
  ///
  /// In en, this message translates to:
  /// **'Not issued'**
  String get accessStatusNotIssued;

  /// No description provided for @accessStatusIssueRequested.
  ///
  /// In en, this message translates to:
  /// **'Issuing'**
  String get accessStatusIssueRequested;

  /// No description provided for @accessStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accessStatusActive;

  /// No description provided for @accessStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get accessStatusFailed;

  /// No description provided for @accessStatusRevokeRequested.
  ///
  /// In en, this message translates to:
  /// **'Deactivating'**
  String get accessStatusRevokeRequested;

  /// No description provided for @accessStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get accessStatusRevoked;

  /// No description provided for @accessStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accessStatusExpired;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotel services'**
  String get servicesTitle;

  /// No description provided for @servicesIntroBanner.
  ///
  /// In en, this message translates to:
  /// **'Order what you need from your room. Requests go straight to reception.'**
  String get servicesIntroBanner;

  /// No description provided for @servicesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get servicesEmptyTitle;

  /// No description provided for @servicesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This hotel hasn\'t published any services yet.'**
  String get servicesEmptyBody;

  /// No description provided for @servicesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Services are unavailable'**
  String get servicesUnavailableTitle;

  /// No description provided for @serviceUncategorised.
  ///
  /// In en, this message translates to:
  /// **'Other services'**
  String get serviceUncategorised;

  /// No description provided for @serviceFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get serviceFreeLabel;

  /// No description provided for @serviceEstimatedMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{count} min'**
  String serviceEstimatedMinutes(int count);

  /// No description provided for @serviceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceDetailTitle;

  /// No description provided for @serviceQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get serviceQuantityLabel;

  /// No description provided for @serviceNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get serviceNotesLabel;

  /// No description provided for @serviceNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the team should know'**
  String get serviceNotesHint;

  /// No description provided for @serviceRequestCta.
  ///
  /// In en, this message translates to:
  /// **'Request this service'**
  String get serviceRequestCta;

  /// No description provided for @serviceRequestingCta.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get serviceRequestingCta;

  /// No description provided for @serviceEstimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get serviceEstimatedTotalLabel;

  /// No description provided for @serviceChargeNote.
  ///
  /// In en, this message translates to:
  /// **'Any charge is added to your room account and settled at checkout.'**
  String get serviceChargeNote;

  /// No description provided for @serviceRequestFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your request'**
  String get serviceRequestFailedTitle;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequestsTitle;

  /// No description provided for @myRequestsIntroBanner.
  ///
  /// In en, this message translates to:
  /// **'Track each request. You can cancel one before the team starts it.'**
  String get myRequestsIntroBanner;

  /// No description provided for @myRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get myRequestsEmptyTitle;

  /// No description provided for @myRequestsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Request a service and it will show up here.'**
  String get myRequestsEmptyBody;

  /// No description provided for @newRequestCta.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequestCta;

  /// No description provided for @serviceOrderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get serviceOrderDetailTitle;

  /// No description provided for @serviceOrderRequestedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get serviceOrderRequestedAtLabel;

  /// No description provided for @serviceOrderConfirmedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get serviceOrderConfirmedAtLabel;

  /// No description provided for @serviceCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get serviceCancelCta;

  /// No description provided for @serviceCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get serviceCancelConfirmTitle;

  /// No description provided for @serviceCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The team hasn\'t started this yet, so it can still be cancelled.'**
  String get serviceCancelConfirmBody;

  /// No description provided for @serviceCancelConfirmTitleFor.
  ///
  /// In en, this message translates to:
  /// **'Cancel the {service} request?'**
  String serviceCancelConfirmTitleFor(String service);

  /// No description provided for @serviceCancelInProgressBody.
  ///
  /// In en, this message translates to:
  /// **'This request is already being handled. Cancelling now may not stop the team if they\'re on the way to your room.'**
  String get serviceCancelInProgressBody;

  /// No description provided for @serviceCancelConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get serviceCancelConfirmCta;

  /// No description provided for @serviceCancelKeepCta.
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get serviceCancelKeepCta;

  /// No description provided for @serviceCancelNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This request can no longer be cancelled.'**
  String get serviceCancelNotAllowed;

  /// No description provided for @serviceContactReception.
  ///
  /// In en, this message translates to:
  /// **'Contact reception'**
  String get serviceContactReception;

  /// No description provided for @serviceContactReceptionHint.
  ///
  /// In en, this message translates to:
  /// **'Call reception from your room phone or the front desk for help with this request.'**
  String get serviceContactReceptionHint;

  /// No description provided for @serviceStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get serviceStatusRequested;

  /// No description provided for @serviceStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get serviceStatusConfirmed;

  /// No description provided for @serviceStatusFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceStatusFulfilled;

  /// No description provided for @serviceStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get serviceStatusCancelled;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Completing checkout'**
  String get checkoutProcessingTitle;

  /// No description provided for @checkoutCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your stay summary'**
  String get checkoutCompleteTitle;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTitle;

  /// No description provided for @checkoutReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to check out'**
  String get checkoutReadyTitle;

  /// No description provided for @checkoutReadyBody.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks.'**
  String get checkoutReadyBody;

  /// No description provided for @checkoutNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout isn\'t available yet'**
  String get checkoutNotReadyTitle;

  /// No description provided for @checkoutNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'You can check out once your stay has started.'**
  String get checkoutNotReadyBody;

  /// No description provided for @checkoutUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout is unavailable'**
  String get checkoutUnavailableTitle;

  /// No description provided for @folioSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Charge summary'**
  String get folioSummaryTitle;

  /// No description provided for @folioAccommodationLine.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get folioAccommodationLine;

  /// No description provided for @folioServiceLine.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get folioServiceLine;

  /// No description provided for @folioTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get folioTotalLabel;

  /// No description provided for @folioPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get folioPaidLabel;

  /// No description provided for @folioOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount due now'**
  String get folioOutstandingLabel;

  /// No description provided for @checkoutSettleNote.
  ///
  /// In en, this message translates to:
  /// **'The amount due is charged in one payment to your card on file. Your invoice is sent electronically.'**
  String get checkoutSettleNote;

  /// No description provided for @checkoutCompleteCta.
  ///
  /// In en, this message translates to:
  /// **'Complete checkout'**
  String get checkoutCompleteCta;

  /// No description provided for @checkoutProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Settling your account…'**
  String get checkoutProcessingBody;

  /// No description provided for @checkoutDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please keep this screen open.'**
  String get checkoutDoNotClose;

  /// No description provided for @checkoutDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your stay'**
  String get checkoutDoneTitle;

  /// No description provided for @checkoutDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is settled and your invoice is ready.'**
  String get checkoutDoneBody;

  /// No description provided for @checkoutPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement is processing'**
  String get checkoutPendingTitle;

  /// No description provided for @checkoutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your bank hasn\'t confirmed the payment yet. Check the status again shortly.'**
  String get checkoutPendingBody;

  /// No description provided for @checkoutFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement didn\'t complete'**
  String get checkoutFailedTitle;

  /// No description provided for @checkoutFailedBody.
  ///
  /// In en, this message translates to:
  /// **'No money was taken. You can try again.'**
  String get checkoutFailedBody;

  /// No description provided for @checkoutRetryCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get checkoutRetryCta;

  /// No description provided for @checkoutViewInvoiceCta.
  ///
  /// In en, this message translates to:
  /// **'View invoice'**
  String get checkoutViewInvoiceCta;

  /// No description provided for @checkoutDoneCta.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get checkoutDoneCta;

  /// No description provided for @checkoutStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get checkoutStatusInProgress;

  /// No description provided for @checkoutStatusAwaitingSettlement.
  ///
  /// In en, this message translates to:
  /// **'Awaiting settlement'**
  String get checkoutStatusAwaitingSettlement;

  /// No description provided for @checkoutStatusSettlementFailed.
  ///
  /// In en, this message translates to:
  /// **'Settlement failed'**
  String get checkoutStatusSettlementFailed;

  /// No description provided for @checkoutStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get checkoutStatusCompleted;

  /// No description provided for @invoiceIssuedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your e-invoice was issued'**
  String get invoiceIssuedBannerTitle;

  /// No description provided for @invoiceIssuedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'It was sent to your email and is always saved here — no paper invoice.'**
  String get invoiceIssuedBannerBody;

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumberLabel;

  /// No description provided for @invoiceIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get invoiceIssuedLabel;

  /// No description provided for @invoiceItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get invoiceItemsTitle;

  /// No description provided for @invoiceSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceSubtotalLabel;

  /// No description provided for @invoicePaymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get invoicePaymentsLabel;

  /// No description provided for @invoiceOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get invoiceOutstandingLabel;

  /// No description provided for @invoiceSettledTag.
  ///
  /// In en, this message translates to:
  /// **'Settled in full'**
  String get invoiceSettledTag;

  /// No description provided for @invoiceNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoice yet'**
  String get invoiceNotReadyTitle;

  /// No description provided for @invoiceNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your invoice will be here once you check out.'**
  String get invoiceNotReadyBody;

  /// No description provided for @invoiceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice is unavailable'**
  String get invoiceUnavailableTitle;

  /// No description provided for @reservationLoyaltyCta.
  ///
  /// In en, this message translates to:
  /// **'Loyalty & points'**
  String get reservationLoyaltyCta;

  /// No description provided for @reservationReviewCta.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reservationReviewCta;

  /// No description provided for @reservationViewReviewCta.
  ///
  /// In en, this message translates to:
  /// **'View your review'**
  String get reservationViewReviewCta;

  /// No description provided for @loyaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyaltyTitle;

  /// No description provided for @loyaltyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty is unavailable'**
  String get loyaltyUnavailableTitle;

  /// No description provided for @loyaltyBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Points balance'**
  String get loyaltyBalanceLabel;

  /// No description provided for @loyaltyPointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{1 pt} other{{points} pts}}'**
  String loyaltyPointsValue(int points);

  /// No description provided for @loyaltyGroupWideNote.
  ///
  /// In en, this message translates to:
  /// **'Your points work across every hotel in the group.'**
  String get loyaltyGroupWideNote;

  /// No description provided for @loyaltyProgramOffTitle.
  ///
  /// In en, this message translates to:
  /// **'The loyalty programme isn\'t active'**
  String get loyaltyProgramOffTitle;

  /// No description provided for @loyaltyProgramOffBody.
  ///
  /// In en, this message translates to:
  /// **'This hotel group hasn\'t switched on points earning yet. There\'s nothing to do here for now.'**
  String get loyaltyProgramOffBody;

  /// No description provided for @loyaltyAlreadyEarnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Points already added'**
  String get loyaltyAlreadyEarnedTitle;

  /// No description provided for @loyaltyAlreadyEarnedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already earned points for this stay.'**
  String get loyaltyAlreadyEarnedBody;

  /// No description provided for @loyaltyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points history'**
  String get loyaltyHistoryTitle;

  /// No description provided for @loyaltyHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'Your full points ledger is kept by the hotel group. This is a read-only copy.'**
  String get loyaltyHistoryNote;

  /// No description provided for @loyaltyHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No points activity yet'**
  String get loyaltyHistoryEmptyTitle;

  /// No description provided for @loyaltyHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Points you earn and redeem will show up here.'**
  String get loyaltyHistoryEmptyBody;

  /// No description provided for @loyaltyPointsAdded.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{+1 pt} other{+{points} pts}}'**
  String loyaltyPointsAdded(int points);

  /// No description provided for @loyaltyPointsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{-1 pt} other{-{points} pts}}'**
  String loyaltyPointsRemoved(int points);

  /// No description provided for @loyaltyTxThisStay.
  ///
  /// In en, this message translates to:
  /// **'This stay'**
  String get loyaltyTxThisStay;

  /// No description provided for @loyaltyTxEarnLabel.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get loyaltyTxEarnLabel;

  /// No description provided for @loyaltyTxRedeemLabel.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get loyaltyTxRedeemLabel;

  /// No description provided for @loyaltyTxReverseLabel.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get loyaltyTxReverseLabel;

  /// No description provided for @loyaltyTxAdjustLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get loyaltyTxAdjustLabel;

  /// No description provided for @loyaltyTxExpireLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get loyaltyTxExpireLabel;

  /// No description provided for @loyaltyRedeemCta.
  ///
  /// In en, this message translates to:
  /// **'Redeem points'**
  String get loyaltyRedeemCta;

  /// No description provided for @loyaltyRedeemTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem points'**
  String get loyaltyRedeemTitle;

  /// No description provided for @loyaltyRedeemSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get loyaltyRedeemSubmitCta;

  /// No description provided for @loyaltyRedeemingCta.
  ///
  /// In en, this message translates to:
  /// **'Redeeming…'**
  String get loyaltyRedeemingCta;

  /// No description provided for @loyaltyRedeemAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Points to redeem'**
  String get loyaltyRedeemAmountLabel;

  /// No description provided for @loyaltyRedeemNote.
  ///
  /// In en, this message translates to:
  /// **'Points are redeemed against this booking. The hotel group confirms the final value.'**
  String get loyaltyRedeemNote;

  /// No description provided for @loyaltyRedeemMax.
  ///
  /// In en, this message translates to:
  /// **'Use max ({points})'**
  String loyaltyRedeemMax(int points);

  /// No description provided for @loyaltyRedeemedTitle.
  ///
  /// In en, this message translates to:
  /// **'Points redeemed'**
  String get loyaltyRedeemedTitle;

  /// No description provided for @loyaltyRedeemedBody.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{1 point was redeemed against this booking.} other{{points} points were redeemed against this booking.}}'**
  String loyaltyRedeemedBody(int points);

  /// No description provided for @loyaltyRedeemedValueNote.
  ///
  /// In en, this message translates to:
  /// **'That\'s about {value} {currency} off this booking.'**
  String loyaltyRedeemedValueNote(String value, String currency);

  /// No description provided for @loyaltyRedeemNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t redeem on this booking'**
  String get loyaltyRedeemNotEligibleTitle;

  /// No description provided for @loyaltyRedeemNotEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'Points can only be redeemed against an active booking.'**
  String get loyaltyRedeemNotEligibleBody;

  /// No description provided for @loyaltyAlreadyRedeemedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already redeemed'**
  String get loyaltyAlreadyRedeemedTitle;

  /// No description provided for @loyaltyAlreadyRedeemedBody.
  ///
  /// In en, this message translates to:
  /// **'Points were already redeemed against this booking.'**
  String get loyaltyAlreadyRedeemedBody;

  /// No description provided for @loyaltyAlreadyRedeemedDifferentBody.
  ///
  /// In en, this message translates to:
  /// **'A different number of points was already redeemed against this booking.'**
  String get loyaltyAlreadyRedeemedDifferentBody;

  /// No description provided for @loyaltyInsufficientTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get loyaltyInsufficientTitle;

  /// No description provided for @loyaltyInsufficientBody.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough points for that amount.'**
  String get loyaltyInsufficientBody;

  /// No description provided for @loyaltyInvalidAmountBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how many points to redeem.'**
  String get loyaltyInvalidAmountBody;

  /// No description provided for @reviewFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reviewFormTitle;

  /// No description provided for @reviewFormPrompt.
  ///
  /// In en, this message translates to:
  /// **'How was your stay?'**
  String get reviewFormPrompt;

  /// No description provided for @reviewResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get reviewResultTitle;

  /// No description provided for @reviewProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sending your review'**
  String get reviewProcessingTitle;

  /// No description provided for @reviewProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Sending your review…'**
  String get reviewProcessingBody;

  /// No description provided for @reviewDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'This only takes a moment. Please don\'t close the app.'**
  String get reviewDoNotClose;

  /// No description provided for @reviewRatingRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a rating from 1 to 5 stars.'**
  String get reviewRatingRequired;

  /// No description provided for @reviewStarsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String reviewStarsLabel(int count);

  /// No description provided for @reviewCategoriesHeading.
  ///
  /// In en, this message translates to:
  /// **'Rate the details of your stay'**
  String get reviewCategoriesHeading;

  /// No description provided for @reviewCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — rate the ones that matter to you.'**
  String get reviewCategoriesHint;

  /// No description provided for @reviewTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Your review (optional)'**
  String get reviewTextLabel;

  /// No description provided for @reviewTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tell other guests about your stay'**
  String get reviewTextHint;

  /// No description provided for @reviewSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get reviewSubmitCta;

  /// No description provided for @reviewSubmittingCta.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reviewSubmittingCta;

  /// No description provided for @reviewYourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get reviewYourRatingLabel;

  /// No description provided for @reviewBackToReservation.
  ///
  /// In en, this message translates to:
  /// **'Back to reservation'**
  String get reviewBackToReservation;

  /// No description provided for @reviewUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews are unavailable'**
  String get reviewUnavailableTitle;

  /// No description provided for @reviewNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t review this stay'**
  String get reviewNotEligibleTitle;

  /// No description provided for @reviewNotEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews open once your stay is completed.'**
  String get reviewNotEligibleBody;

  /// No description provided for @reviewSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review'**
  String get reviewSubmittedTitle;

  /// No description provided for @reviewPublishedBody.
  ///
  /// In en, this message translates to:
  /// **'Your review has been posted.'**
  String get reviewPublishedBody;

  /// No description provided for @reviewPendingModerationBody.
  ///
  /// In en, this message translates to:
  /// **'Your review was received and is with our team for a quick check before it\'s published.'**
  String get reviewPendingModerationBody;

  /// No description provided for @reviewAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reviewed this stay'**
  String get reviewAlreadyTitle;

  /// No description provided for @reviewAlreadyBody.
  ///
  /// In en, this message translates to:
  /// **'Only one review per stay. Your existing review is shown below.'**
  String get reviewAlreadyBody;

  /// No description provided for @reviewRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'This review wasn\'t published'**
  String get reviewRejectedTitle;

  /// No description provided for @reviewRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your review didn\'t pass our check and wasn\'t published.'**
  String get reviewRejectedBody;

  /// No description provided for @reviewInvalidRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating out of range'**
  String get reviewInvalidRatingTitle;

  /// No description provided for @reviewInvalidRatingBody.
  ///
  /// In en, this message translates to:
  /// **'A rating must be between 1 and 5 stars.'**
  String get reviewInvalidRatingBody;

  /// No description provided for @reviewFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your review'**
  String get reviewFailedTitle;

  /// No description provided for @reviewStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get reviewStatusPending;

  /// No description provided for @reviewStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get reviewStatusPublished;

  /// No description provided for @reviewStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get reviewStatusRejected;

  /// No description provided for @serviceReviewFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this service'**
  String get serviceReviewFormTitle;

  /// No description provided for @serviceReviewFormPrompt.
  ///
  /// In en, this message translates to:
  /// **'How was this service?'**
  String get serviceReviewFormPrompt;

  /// No description provided for @serviceReviewResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your service review'**
  String get serviceReviewResultTitle;

  /// No description provided for @serviceReviewNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t review this service yet'**
  String get serviceReviewNotEligibleTitle;

  /// No description provided for @serviceReviewNotEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews open once the service has been fulfilled.'**
  String get serviceReviewNotEligibleBody;

  /// No description provided for @serviceReviewTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tell other guests about this service'**
  String get serviceReviewTextHint;

  /// No description provided for @hotelDetailStarRating.
  ///
  /// In en, this message translates to:
  /// **'{count}-star hotel'**
  String hotelDetailStarRating(int count);

  /// No description provided for @hotelDetailReviewsHeading.
  ///
  /// In en, this message translates to:
  /// **'Ratings & reviews'**
  String get hotelDetailReviewsHeading;

  /// No description provided for @hotelInfoRoomTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Room types'**
  String get hotelInfoRoomTypesLabel;

  /// No description provided for @hotelInfoCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get hotelInfoCountryLabel;

  /// No description provided for @hotelInfoGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelInfoGuestsLabel;

  /// No description provided for @hotelInfoClassificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get hotelInfoClassificationLabel;

  /// No description provided for @hotelInfoCheckInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get hotelInfoCheckInLabel;

  /// No description provided for @hotelInfoCheckOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get hotelInfoCheckOutLabel;

  /// No description provided for @hotelTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'{time} {period, select, am{AM} noon{PM} other{PM}}'**
  String hotelTimeOfDay(String time, String period);

  /// No description provided for @hotelInfoRoomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get hotelInfoRoomsLabel;

  /// No description provided for @hotelRoomCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room} other{{count} rooms}}'**
  String hotelRoomCount(int count);

  /// No description provided for @hotelInfoSuitableForLabel.
  ///
  /// In en, this message translates to:
  /// **'Suitable for'**
  String get hotelInfoSuitableForLabel;

  /// No description provided for @hotelLocationHeading.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get hotelLocationHeading;

  /// No description provided for @hotelShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get hotelShare;

  /// No description provided for @hotelShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Hotel details copied'**
  String get hotelShareCopied;

  /// No description provided for @hotelFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get hotelFavoriteAdd;

  /// No description provided for @hotelFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get hotelFavoriteRemove;

  /// No description provided for @hotelLocationMapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hotel location on the map'**
  String get hotelLocationMapSemantics;

  /// No description provided for @hotelLocationMapOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the full map'**
  String get hotelLocationMapOpenHint;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @hotelNearbyPlace.
  ///
  /// In en, this message translates to:
  /// **'{place} {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String hotelNearbyPlace(String place, int minutes);

  /// Nearby place with its distance in kilometres (shown when no travel time is on file).
  ///
  /// In en, this message translates to:
  /// **'{place} {distance} km'**
  String hotelNearbyPlaceKm(String place, String distance);

  /// Nearby place with its distance in metres (shown when no travel time is on file).
  ///
  /// In en, this message translates to:
  /// **'{place} {distance} m'**
  String hotelNearbyPlaceMeters(String place, String distance);

  /// No description provided for @hotelWhyChooseHeading.
  ///
  /// In en, this message translates to:
  /// **'Why choose this hotel?'**
  String get hotelWhyChooseHeading;

  /// No description provided for @hotelDetailAmenitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Services designed for guests\' comfort around the clock'**
  String get hotelDetailAmenitiesSubtitle;

  /// No description provided for @hotelRoomsHeading.
  ///
  /// In en, this message translates to:
  /// **'Available rooms'**
  String get hotelRoomsHeading;

  /// No description provided for @hotelRoomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the right room for your trip and enjoy a refined stay'**
  String get hotelRoomsSubtitle;

  /// No description provided for @hotelRoomsCta.
  ///
  /// In en, this message translates to:
  /// **'View available rooms'**
  String get hotelRoomsCta;

  /// No description provided for @hotelReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guest ratings reflect the quality of service and comfort during the stay'**
  String get hotelReviewsSubtitle;

  /// No description provided for @hotelOverallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall rating'**
  String get hotelOverallRating;

  /// No description provided for @hotelPriceFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get hotelPriceFromLabel;

  /// No description provided for @roomSpecArea.
  ///
  /// In en, this message translates to:
  /// **'Room size'**
  String get roomSpecArea;

  /// No description provided for @roomSpecGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get roomSpecGuests;

  /// No description provided for @roomSpecBed.
  ///
  /// In en, this message translates to:
  /// **'Bed type'**
  String get roomSpecBed;

  /// No description provided for @roomSpecView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get roomSpecView;

  /// No description provided for @roomBookingDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Your booking details'**
  String get roomBookingDetailsHeading;

  /// No description provided for @roomStayDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get roomStayDuration;

  /// No description provided for @roomStayDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get roomStayDates;

  /// No description provided for @roomStayGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get roomStayGuests;

  /// No description provided for @roomNightlyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Room rate'**
  String get roomNightlyPriceLabel;

  /// No description provided for @roomTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get roomTotalLabel;

  /// No description provided for @roomIncludedHeading.
  ///
  /// In en, this message translates to:
  /// **'The price includes'**
  String get roomIncludedHeading;

  /// No description provided for @roomAboutHeading.
  ///
  /// In en, this message translates to:
  /// **'About the room'**
  String get roomAboutHeading;

  /// No description provided for @roomPoliciesHeading.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get roomPoliciesHeading;

  /// No description provided for @roomCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get roomCurrentPrice;

  /// No description provided for @commonShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get commonShowMore;

  /// No description provided for @commonShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get commonShowLess;

  /// No description provided for @bookingsPillCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bookingsPillCurrent;

  /// No description provided for @bookingsPillUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingsPillUpcoming;

  /// No description provided for @bookingsPillPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingsPillPast;

  /// No description provided for @bookingsPastTitle.
  ///
  /// In en, this message translates to:
  /// **'Past stays'**
  String get bookingsPastTitle;

  /// No description provided for @bookingsSectionOngoingStay.
  ///
  /// In en, this message translates to:
  /// **'Ongoing stay'**
  String get bookingsSectionOngoingStay;

  /// No description provided for @bookingsSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get bookingsSectionUpcoming;

  /// No description provided for @bookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get bookingsEmptyTitle;

  /// No description provided for @bookingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your bookings will appear here once you make one.'**
  String get bookingsEmptyBody;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get bookingStatusCheckedIn;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailTitle;

  /// No description provided for @bookingPaymentStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get bookingPaymentStatusHeading;

  /// No description provided for @bookingCancellationPolicyHeading.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get bookingCancellationPolicyHeading;

  /// No description provided for @bookingCancellationPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation up to 24 hours before arrival. After that, the deposit is deducted.'**
  String get bookingCancellationPolicyBody;

  /// No description provided for @bookingPendingRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get bookingPendingRowTitle;

  /// No description provided for @bookingPendingRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get bookingPendingRowSubtitle;

  /// No description provided for @bookingAutoCancelRowTitle.
  ///
  /// In en, this message translates to:
  /// **'The booking auto-cancels in 30 minutes'**
  String get bookingAutoCancelRowTitle;

  /// No description provided for @bookingRoomHeldRowTitle.
  ///
  /// In en, this message translates to:
  /// **'The room is held temporarily'**
  String get bookingRoomHeldRowTitle;

  /// No description provided for @bookingRoomHeldRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get bookingRoomHeldRowSubtitle;

  /// No description provided for @bookingDepositHeldRowTitle.
  ///
  /// In en, this message translates to:
  /// **'The deposit has been held'**
  String get bookingDepositHeldRowTitle;

  /// No description provided for @bookingDepositHeldRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No charge has been made yet'**
  String get bookingDepositHeldRowSubtitle;

  /// No description provided for @bookingDeductedAtCheckinRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Deducted at check-in'**
  String get bookingDeductedAtCheckinRowTitle;

  /// No description provided for @bookingExtrasChargedOnceRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra charges are collected on departure'**
  String get bookingExtrasChargedOnceRowTitle;

  /// No description provided for @bookingExtrasChargedOnceRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'As a single payment'**
  String get bookingExtrasChargedOnceRowSubtitle;

  /// No description provided for @bookingIdentityVerifiedRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified'**
  String get bookingIdentityVerifiedRowTitle;

  /// No description provided for @bookingIdentityVerifiedRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get bookingIdentityVerifiedRowSubtitle;

  /// No description provided for @bookingCheckInAvailableRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in available from'**
  String get bookingCheckInAvailableRowTitle;

  /// No description provided for @bookingDepositAmountHeldRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit amount held'**
  String get bookingDepositAmountHeldRowTitle;

  /// No description provided for @bookingOngoingStayRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Ongoing stay'**
  String get bookingOngoingStayRowTitle;

  /// No description provided for @bookingRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String bookingRoomLabel(String number);

  /// No description provided for @bookingDepartureRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get bookingDepartureRowTitle;

  /// No description provided for @bookingExtraChargesRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra charges'**
  String get bookingExtraChargesRowTitle;

  /// No description provided for @bookingCancelledRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelledRowTitle;

  /// No description provided for @bookingDepositRefundRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit refund'**
  String get bookingDepositRefundRowTitle;

  /// No description provided for @bookingDepositRefundRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Within 3 business days'**
  String get bookingDepositRefundRowSubtitle;

  /// No description provided for @bookingCancellationFeeRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee'**
  String get bookingCancellationFeeRowTitle;

  /// No description provided for @bookingCancellationFeeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get bookingCancellationFeeNone;

  /// No description provided for @bookingDepositNotRefunded.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable rate — no refund'**
  String get bookingDepositNotRefunded;

  /// No description provided for @bookingStayEndedRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay ended'**
  String get bookingStayEndedRowTitle;

  /// No description provided for @bookingTotalPaidRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get bookingTotalPaidRowTitle;

  /// No description provided for @bookingInvoiceReadyRowTitle.
  ///
  /// In en, this message translates to:
  /// **'E-invoice'**
  String get bookingInvoiceReadyRowTitle;

  /// No description provided for @bookingInvoiceReadyRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bookingInvoiceReadyRowSubtitle;

  /// No description provided for @bookingCtaContinuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue payment'**
  String get bookingCtaContinuePayment;

  /// No description provided for @bookingCtaCancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get bookingCtaCancelReservation;

  /// No description provided for @bookingCtaVerifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get bookingCtaVerifyIdentity;

  /// No description provided for @bookingCtaDigitalCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Digital check-in'**
  String get bookingCtaDigitalCheckIn;

  /// No description provided for @bookingCtaMyCurrentStay.
  ///
  /// In en, this message translates to:
  /// **'My current stay'**
  String get bookingCtaMyCurrentStay;

  /// No description provided for @bookingCtaShowAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Show access code'**
  String get bookingCtaShowAccessCode;

  /// No description provided for @bookingCtaBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookingCtaBookAgain;

  /// No description provided for @bookingCtaViewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View invoice'**
  String get bookingCtaViewInvoice;

  /// No description provided for @bookingCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get bookingCancelConfirmTitle;

  /// No description provided for @bookingCancelFullRefundBody.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is free and your full deposit will be released.'**
  String get bookingCancelFullRefundBody;

  /// No description provided for @bookingCancelNoRefundBody.
  ///
  /// In en, this message translates to:
  /// **'The deposit is not refunded if you cancel this booking.'**
  String get bookingCancelNoRefundBody;

  /// No description provided for @policyFreeUntil.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation with a full refund until {date}. After that it cannot be cancelled.'**
  String policyFreeUntil(String date);

  /// No description provided for @policyWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'The free cancellation window has closed; this booking can no longer be cancelled.'**
  String get policyWindowClosed;

  /// No description provided for @policyNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'This rate is non-refundable and cannot be cancelled.'**
  String get policyNonRefundable;

  /// No description provided for @policyStayStarted.
  ///
  /// In en, this message translates to:
  /// **'A booking cannot be cancelled once the stay has started.'**
  String get policyStayStarted;

  /// No description provided for @policyGeneral.
  ///
  /// In en, this message translates to:
  /// **'Refundable rates can be cancelled free, with a full refund, within {hours} hours of booking or until check-in if that is sooner. After that they cannot be cancelled. Non-refundable rates cannot be cancelled.'**
  String policyGeneral(int hours);

  /// No description provided for @cancelNotAllowedError.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be cancelled under its cancellation policy.'**
  String get cancelNotAllowedError;

  /// No description provided for @cancelRefundFailedError.
  ///
  /// In en, this message translates to:
  /// **'The deposit couldn\'t be released right now, so the booking wasn\'t cancelled. Please try again.'**
  String get cancelRefundFailedError;

  /// No description provided for @bookingCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Any deposit will be refunded per the cancellation policy.'**
  String get bookingCancelConfirmBody;

  /// No description provided for @bookingCancelKeepCta.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get bookingCancelKeepCta;

  /// No description provided for @bookingCancelConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get bookingCancelConfirmCta;

  /// No description provided for @bookingNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get bookingNotFoundTitle;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountPrivacyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Your ID photos are stored securely and deleted automatically after your stay.'**
  String get accountPrivacyNoteBody;

  /// No description provided for @profilePersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get profilePersonalInfoTitle;

  /// No description provided for @profilePersonalInfoBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal details'**
  String get profilePersonalInfoBannerTitle;

  /// No description provided for @profilePersonalInfoBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Used for your bookings and invoices. To change your name or ID number, contact reception.'**
  String get profilePersonalInfoBannerBody;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profilePhoneLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileEmailAdd;

  /// No description provided for @profileVerifiedIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified identity'**
  String get profileVerifiedIdentityLabel;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get profileNotVerified;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileDone;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your changes were saved.'**
  String get profileSaved;

  /// No description provided for @profilePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'My preferences'**
  String get profilePreferencesTitle;

  /// No description provided for @profilePreferencesBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay preferences'**
  String get profilePreferencesBannerTitle;

  /// No description provided for @profilePreferencesBannerBody.
  ///
  /// In en, this message translates to:
  /// **'We use these to prepare your room ahead of time at every hotel in the group.'**
  String get profilePreferencesBannerBody;

  /// No description provided for @profilePrefRoomType.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get profilePrefRoomType;

  /// No description provided for @profilePrefHighFloor.
  ///
  /// In en, this message translates to:
  /// **'High floor'**
  String get profilePrefHighFloor;

  /// No description provided for @profilePrefExtraPillows.
  ///
  /// In en, this message translates to:
  /// **'Extra pillows'**
  String get profilePrefExtraPillows;

  /// No description provided for @profilePrefLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profilePrefLanguage;

  /// No description provided for @profilePrefNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profilePrefNotifications;

  /// No description provided for @profilePrefOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profilePrefOn;

  /// No description provided for @profilePrefOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profilePrefOff;

  /// No description provided for @profilePrefOnFeminine.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profilePrefOnFeminine;

  /// No description provided for @profilePrefOffFeminine.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profilePrefOffFeminine;

  /// No description provided for @profilePrivacyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'How we use your data'**
  String get profilePrivacyBannerTitle;

  /// No description provided for @profilePrivacyBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Your ID photos are stored encrypted and deleted automatically after your stay. They are never shared with third parties.'**
  String get profilePrivacyBannerBody;

  /// No description provided for @profilePrivacyIdPhotos.
  ///
  /// In en, this message translates to:
  /// **'ID photos'**
  String get profilePrivacyIdPhotos;

  /// No description provided for @profilePrivacyIdPhotosValue.
  ///
  /// In en, this message translates to:
  /// **'Deleted after departure'**
  String get profilePrivacyIdPhotosValue;

  /// No description provided for @profileIdentityDeleteAfterCheckout.
  ///
  /// In en, this message translates to:
  /// **'Delete my ID photos after checkout (default)'**
  String get profileIdentityDeleteAfterCheckout;

  /// No description provided for @profileIdentityKeepForFuture.
  ///
  /// In en, this message translates to:
  /// **'Keep them for my future bookings'**
  String get profileIdentityKeepForFuture;

  /// No description provided for @profileIdentityKeptValue.
  ///
  /// In en, this message translates to:
  /// **'Kept for future bookings'**
  String get profileIdentityKeptValue;

  /// No description provided for @profileIdentityHotelCopyNote.
  ///
  /// In en, this message translates to:
  /// **'The hotel keeps the stay\'s ID copy for {days} days after checkout, then it is deleted automatically.'**
  String profileIdentityHotelCopyNote(int days);

  /// No description provided for @profilePrivacyPaymentData.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get profilePrivacyPaymentData;

  /// No description provided for @profilePrivacyPaymentDataValue.
  ///
  /// In en, this message translates to:
  /// **'Not stored'**
  String get profilePrivacyPaymentDataValue;

  /// No description provided for @profilePrivacyStayHistory.
  ///
  /// In en, this message translates to:
  /// **'Stay history'**
  String get profilePrivacyStayHistory;

  /// No description provided for @profileRequestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request data deletion'**
  String get profileRequestDeletion;

  /// No description provided for @profileDeletionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your personal data?'**
  String get profileDeletionConfirmTitle;

  /// No description provided for @profileDeletionConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your request goes to the hotel team, who will contact you to complete it. It does not cancel your current bookings.'**
  String get profileDeletionConfirmBody;

  /// No description provided for @profileDeletionConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get profileDeletionConfirmCta;

  /// No description provided for @profileDeletionRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request was received'**
  String get profileDeletionRequestedTitle;

  /// No description provided for @profileDeletionRequestedBody.
  ///
  /// In en, this message translates to:
  /// **'You sent the request on {date}. The hotel team will contact you to complete it.'**
  String profileDeletionRequestedBody(String date);

  /// No description provided for @profileDeletionRequestedCta.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get profileDeletionRequestedCta;

  /// No description provided for @profileSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileSupportTitle;

  /// No description provided for @profileSupportBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get profileSupportBannerTitle;

  /// No description provided for @profileSupportBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Support is available around the clock, and you can contact your hotel directly.'**
  String get profileSupportBannerBody;

  /// No description provided for @profileFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get profileFaq;

  /// No description provided for @profileFaqEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No FAQ yet'**
  String get profileFaqEmptyTitle;

  /// No description provided for @profileFaqEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Contact your hotel directly with any question.'**
  String get profileFaqEmptyBody;

  /// No description provided for @profileDuringStayOnly.
  ///
  /// In en, this message translates to:
  /// **'Available during a stay'**
  String get profileDuringStayOnly;

  /// No description provided for @profileContactReceptionNoStay.
  ///
  /// In en, this message translates to:
  /// **'Available with a booking'**
  String get profileContactReceptionNoStay;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need a new verification code to sign in again. Your bookings and current stay aren\'t affected.'**
  String get profileLogoutConfirmBody;

  /// No description provided for @accountLoyaltyProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty program'**
  String get accountLoyaltyProgramTitle;

  /// No description provided for @accountLoyaltyPointsSuffix.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get accountLoyaltyPointsSuffix;

  /// No description provided for @accountLoyaltyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your points build up across every hotel in the group and can be redeemed at any branch.'**
  String get accountLoyaltyDescription;

  /// No description provided for @accountLoyaltyPerNightLabel.
  ///
  /// In en, this message translates to:
  /// **'Per night'**
  String get accountLoyaltyPerNightLabel;

  /// No description provided for @accountTrustedGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted guest'**
  String get accountTrustedGuestTitle;

  /// No description provided for @accountTrustedGuestBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be asked to re-upload your ID at any other hotel in the group.'**
  String get accountTrustedGuestBody;

  /// No description provided for @accountPreviousStaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous stays'**
  String get accountPreviousStaysLabel;

  /// No description provided for @accountPreferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'My preferences'**
  String get accountPreferencesLabel;

  /// No description provided for @accountPreferencesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get accountPreferencesEmpty;

  /// No description provided for @accountPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get accountPrivacyLabel;

  /// No description provided for @accountHelpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get accountHelpSupportLabel;

  /// No description provided for @stayHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your current stay'**
  String get stayHomeTitle;

  /// No description provided for @stayHomeRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Your room'**
  String get stayHomeRoomLabel;

  /// No description provided for @stayHomeHotelUntil.
  ///
  /// In en, this message translates to:
  /// **'{hotel} · until {date}'**
  String stayHomeHotelUntil(String hotel, String date);

  /// No description provided for @bookingRoomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String bookingRoomNumber(String number);

  /// No description provided for @stayHomeServicesHeading.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get stayHomeServicesHeading;

  /// No description provided for @stayHomeRoomService.
  ///
  /// In en, this message translates to:
  /// **'Room service'**
  String get stayHomeRoomService;

  /// No description provided for @stayHomeRoomCleaning.
  ///
  /// In en, this message translates to:
  /// **'Room cleaning'**
  String get stayHomeRoomCleaning;

  /// No description provided for @stayHomeExtendStay.
  ///
  /// In en, this message translates to:
  /// **'Extend stay'**
  String get stayHomeExtendStay;

  /// No description provided for @stayHomeReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get stayHomeReportProblem;

  /// No description provided for @stayHomeExtraCharges.
  ///
  /// In en, this message translates to:
  /// **'Extra charges'**
  String get stayHomeExtraCharges;

  /// No description provided for @stayHomeExtraChargesNote.
  ///
  /// In en, this message translates to:
  /// **'Deducted automatically on departure'**
  String get stayHomeExtraChargesNote;

  /// No description provided for @stayHomeNoActiveStayTitle.
  ///
  /// In en, this message translates to:
  /// **'No active stay'**
  String get stayHomeNoActiveStayTitle;

  /// No description provided for @stayHomeNoActiveStayBody.
  ///
  /// In en, this message translates to:
  /// **'Once you check in, your room, key and services will show up here.'**
  String get stayHomeNoActiveStayBody;

  /// No description provided for @guestSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get guestSignInRequiredTitle;

  /// No description provided for @guestSignInBookingsBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see and manage your bookings.'**
  String get guestSignInBookingsBody;

  /// No description provided for @guestSignInServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to reach your stay\'s services, room key and requests.'**
  String get guestSignInServicesBody;

  /// No description provided for @guestSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get guestSignInAction;

  /// No description provided for @extendStayTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend stay'**
  String get extendStayTitle;

  /// No description provided for @extendStayNewCheckOutLabel.
  ///
  /// In en, this message translates to:
  /// **'New checkout date'**
  String get extendStayNewCheckOutLabel;

  /// No description provided for @extendStayNightsAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Nights added'**
  String get extendStayNightsAddedLabel;

  /// No description provided for @extendStayCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm extension'**
  String get extendStayCta;

  /// No description provided for @extendStaySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay extended'**
  String get extendStaySuccessTitle;

  /// No description provided for @extendStaySuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your checkout date is now {date}. {amount} has been added to your folio.'**
  String extendStaySuccessBody(String date, String amount);

  /// No description provided for @extendStayNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Extend stay is only available during your current stay.'**
  String get extendStayNotEligible;

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblemTitle;

  /// No description provided for @reportProblemCategoryHeading.
  ///
  /// In en, this message translates to:
  /// **'What\'s the issue?'**
  String get reportProblemCategoryHeading;

  /// No description provided for @reportProblemCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the closest category so your report reaches the right team directly.'**
  String get reportProblemCategoryBody;

  /// No description provided for @reportCategoryAcHeating.
  ///
  /// In en, this message translates to:
  /// **'AC or heating'**
  String get reportCategoryAcHeating;

  /// No description provided for @reportCategoryPlumbingWater.
  ///
  /// In en, this message translates to:
  /// **'Plumbing or water'**
  String get reportCategoryPlumbingWater;

  /// No description provided for @reportCategoryElectricityLighting.
  ///
  /// In en, this message translates to:
  /// **'Electricity and lighting'**
  String get reportCategoryElectricityLighting;

  /// No description provided for @reportCategoryRoomCleanliness.
  ///
  /// In en, this message translates to:
  /// **'Room cleanliness'**
  String get reportCategoryRoomCleanliness;

  /// No description provided for @reportCategoryInternetWifi.
  ///
  /// In en, this message translates to:
  /// **'Internet and Wi-Fi'**
  String get reportCategoryInternetWifi;

  /// No description provided for @reportCategoryNoiseDisturbance.
  ///
  /// In en, this message translates to:
  /// **'Noise or disturbance'**
  String get reportCategoryNoiseDisturbance;

  /// No description provided for @reportProblemContinueCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reportProblemContinueCta;

  /// No description provided for @reportDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get reportDescriptionTitle;

  /// No description provided for @reportUrgencyHeading.
  ///
  /// In en, this message translates to:
  /// **'How urgent is this?'**
  String get reportUrgencyHeading;

  /// No description provided for @reportUrgencyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get reportUrgencyNormal;

  /// No description provided for @reportUrgencyImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get reportUrgencyImportant;

  /// No description provided for @reportUrgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get reportUrgencyUrgent;

  /// No description provided for @reportNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get reportNotesLabel;

  /// No description provided for @reportNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any details that help our team respond faster'**
  String get reportNotesHint;

  /// No description provided for @reportNoFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'No fees'**
  String get reportNoFeeTitle;

  /// No description provided for @reportNoFeeBody.
  ///
  /// In en, this message translates to:
  /// **'Reporting a problem is free and will never be added to your bill.'**
  String get reportNoFeeBody;

  /// No description provided for @reportSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmitCta;

  /// No description provided for @reportSubmittingCta.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reportSubmittingCta;

  /// No description provided for @reportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your report'**
  String get reportFailedTitle;

  /// No description provided for @reportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reportSubmittedTitle;

  /// No description provided for @reportSubmittedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your report reached reception'**
  String get reportSubmittedBannerTitle;

  /// No description provided for @reportSubmittedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Report {reference}. Our reception team will be in touch shortly, and you can track its status anytime.'**
  String reportSubmittedBannerBody(String reference);

  /// No description provided for @reportTrackCta.
  ///
  /// In en, this message translates to:
  /// **'Track report'**
  String get reportTrackCta;

  /// No description provided for @reportDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetailTitle;

  /// No description provided for @reportDetailBody.
  ///
  /// In en, this message translates to:
  /// **'Your report has been received and our team is on it.'**
  String get reportDetailBody;

  /// No description provided for @reportContactReceptionCta.
  ///
  /// In en, this message translates to:
  /// **'Contact reception'**
  String get reportContactReceptionCta;

  /// No description provided for @reportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reportStatusOpen;

  /// No description provided for @reportStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get reportStatusInProgress;

  /// No description provided for @reportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get reportStatusResolved;

  /// No description provided for @reportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports are unavailable'**
  String get reportUnavailableTitle;

  /// No description provided for @reportNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Report not found'**
  String get reportNotFoundTitle;

  /// No description provided for @myReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReportsTitle;

  /// No description provided for @myReportsIntroBanner.
  ///
  /// In en, this message translates to:
  /// **'Track the status of every problem you\'ve reported.'**
  String get myReportsIntroBanner;

  /// No description provided for @myReportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get myReportsEmptyTitle;

  /// No description provided for @myReportsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Report a problem and it will show up here.'**
  String get myReportsEmptyBody;

  /// No description provided for @newReportCta.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get newReportCta;

  /// No description provided for @bookingLoyaltyWorth.
  ///
  /// In en, this message translates to:
  /// **'Worth'**
  String get bookingLoyaltyWorth;

  /// No description provided for @bookingLoyaltyRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get bookingLoyaltyRedeem;

  /// No description provided for @bookingLoyaltyPointsField.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get bookingLoyaltyPointsField;

  /// No description provided for @bookingLoyaltyPointsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter points'**
  String get bookingLoyaltyPointsHint;

  /// No description provided for @bookingLoyaltyDiscountField.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get bookingLoyaltyDiscountField;

  /// No description provided for @bookingLoyaltyApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get bookingLoyaltyApply;

  /// No description provided for @bookingLoyaltyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bookingLoyaltyRemove;

  /// No description provided for @bookingLoyaltyMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {points} points on this booking'**
  String bookingLoyaltyMaxHint(String points);

  /// No description provided for @bookingLoyaltyAppliedNote.
  ///
  /// In en, this message translates to:
  /// **'Redeemed when you confirm the booking'**
  String get bookingLoyaltyAppliedNote;

  /// No description provided for @bookingLoyaltyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Points redemption isn\'t available yet'**
  String get bookingLoyaltyDisabled;

  /// No description provided for @bookingLoyaltyNoPoints.
  ///
  /// In en, this message translates to:
  /// **'You have no points to redeem yet'**
  String get bookingLoyaltyNoPoints;

  /// No description provided for @bookingLoyaltyDiscountRow.
  ///
  /// In en, this message translates to:
  /// **'Points discount'**
  String get bookingLoyaltyDiscountRow;

  /// No description provided for @bookingLoyaltyRedeemFailed.
  ///
  /// In en, this message translates to:
  /// **'Your points couldn\'t be redeemed — nothing was deducted.'**
  String get bookingLoyaltyRedeemFailed;

  /// No description provided for @loyaltyAutoEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Points on the way'**
  String get loyaltyAutoEarnTitle;

  /// No description provided for @loyaltyAutoEarnBody.
  ///
  /// In en, this message translates to:
  /// **'Points for this stay are added to your balance automatically once it\'s complete.'**
  String get loyaltyAutoEarnBody;

  /// No description provided for @bookingCheckInFrom.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String bookingCheckInFrom(String time);

  /// No description provided for @roomPolicyCheckInBody.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String roomPolicyCheckInBody(String time);

  /// No description provided for @roomPolicyCheckOutBody.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String roomPolicyCheckOutBody(String time);

  /// No description provided for @roomTaxesLabel.
  ///
  /// In en, this message translates to:
  /// **'Taxes & fees'**
  String get roomTaxesLabel;

  /// No description provided for @roomPriceIncludedValue.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get roomPriceIncludedValue;

  /// No description provided for @roomFinalPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Final price — no extra fees'**
  String get roomFinalPriceNote;

  /// No description provided for @roomPolicyCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get roomPolicyCheckInTitle;

  /// No description provided for @roomPolicyCheckOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get roomPolicyCheckOutTitle;

  /// Booking summary: the adults stepper hit the chosen room's capacity.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This room takes at most 1 adult} other{This room takes at most {count} adults}}'**
  String roomMaxAdultsReached(int count);

  /// Booking summary: the party hit the chosen room's total occupancy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This room takes at most 1 guest} other{This room takes at most {count} guests}}'**
  String roomMaxGuestsReached(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
