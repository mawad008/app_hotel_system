import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/l10n.dart';
import '../../core/widgets/hotel_app_bar.dart';
import '../../core/widgets/message_view.dart';
import '../../features/authentication/presentation/pages/auth_splash_page.dart';
import '../../features/authentication/presentation/pages/complete_profile_page.dart';
import '../../features/authentication/presentation/pages/entry_welcome_page.dart';
import '../../features/authentication/presentation/pages/language_selection_page.dart';
import '../../features/authentication/presentation/pages/otp_verification_page.dart';
import '../../features/authentication/presentation/pages/phone_login_page.dart';
import '../../features/authentication/presentation/pages/session_expired_page.dart';
import '../../features/authentication/presentation/state/auth_controller.dart';
import '../../features/authentication/presentation/state/auth_state.dart';
import '../../features/authentication/presentation/state/language_selection_controller.dart';
import '../../features/authentication/presentation/state/post_auth_redirect_controller.dart';
import '../../features/bookings/presentation/pages/bookings_list_page.dart';
import '../../features/profile/presentation/pages/account_home_page.dart';
import '../../features/stay_home/presentation/pages/extend_stay_page.dart';
import '../../features/stay_home/presentation/pages/stay_home_page.dart';
import '../../features/discovery/presentation/pages/available_rooms_page.dart';
import '../../features/discovery/presentation/pages/discover_page.dart';
import '../../features/discovery/presentation/pages/hotel_detail_page.dart';
import '../../features/discovery/presentation/pages/hotel_search_page.dart';
import '../../features/discovery/presentation/pages/room_detail_page.dart';
import '../../features/discovery/presentation/pages/room_selection_review_page.dart';
import '../../features/discovery/presentation/pages/stay_dates_page.dart';
import '../../features/checkout/presentation/pages/checkout_completion_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/checkout_processing_page.dart';
import '../../features/checkout/presentation/pages/invoice_page.dart';
import '../../features/digital_access/presentation/pages/check_in_page.dart';
import '../../features/digital_access/presentation/pages/check_in_processing_page.dart';
import '../../features/digital_access/presentation/pages/digital_access_page.dart';
import '../../features/identity_verification/presentation/pages/identity_verification_page.dart';
import '../../features/loyalty/presentation/pages/loyalty_page.dart';
import '../../features/loyalty/presentation/pages/loyalty_redeem_page.dart';
import '../../features/reviews/presentation/pages/review_form_page.dart';
import '../../features/reviews/presentation/pages/review_processing_page.dart';
import '../../features/reviews/presentation/pages/review_result_page.dart';
import '../../features/identity_verification/presentation/pages/identity_verification_result_page.dart';
import '../../features/payment/presentation/pages/payment_card_details_page.dart';
import '../../features/payment/presentation/pages/payment_method_page.dart';
import '../../features/payment/presentation/pages/payment_processing_page.dart';
import '../../features/payment/presentation/pages/payment_result_page.dart';
import '../../features/payment/presentation/pages/payment_review_page.dart';
import '../../features/problem_reports/domain/entities/problem_category.dart';
import '../../features/problem_reports/presentation/pages/my_problem_reports_page.dart';
import '../../features/problem_reports/presentation/pages/problem_report_detail_page.dart';
import '../../features/problem_reports/presentation/pages/report_problem_category_page.dart';
import '../../features/problem_reports/presentation/pages/report_problem_description_page.dart';
import '../../features/problem_reports/presentation/pages/report_problem_submitted_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/cancellation_policy_page.dart';
import '../../features/profile/presentation/pages/faq_page.dart';
import '../../features/profile/presentation/pages/logout_confirm_page.dart';
import '../../features/profile/presentation/pages/personal_info_page.dart';
import '../../features/profile/presentation/pages/preferences_page.dart';
import '../../features/profile/presentation/pages/privacy_page.dart';
import '../../features/profile/presentation/pages/support_page.dart';
import '../../features/reservation/presentation/pages/contact_reception_page.dart';
import '../../features/reservation/presentation/pages/reservation_detail_page.dart';
import '../../features/stay_services/presentation/pages/my_service_requests_page.dart';
import '../../features/stay_services/presentation/pages/service_detail_page.dart';
import '../../features/stay_services/presentation/pages/service_order_detail_page.dart';
import '../../features/stay_services/presentation/pages/service_review_form_page.dart';
import '../../features/stay_services/presentation/pages/service_review_processing_page.dart';
import '../../features/stay_services/presentation/pages/service_review_result_page.dart';
import '../../features/stay_services/presentation/pages/stay_services_page.dart';
import '../foundation_home_page.dart';
import 'app_routes.dart';

/// Bridges [authControllerProvider] to a [Listenable] so `GoRouter` re-runs its
/// redirect whenever the authentication state changes.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _authRouterRefreshProvider = Provider<_AuthRouterRefresh>((Ref ref) {
  final _AuthRouterRefresh refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});

/// The app's [GoRouter]. Kept behind a provider so feature modules can
/// contribute routes and tests can build a router with overridden deps.
final appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: ref.watch(_authRouterRefreshProvider),
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authControllerProvider);
      final String loc = state.matchedLocation;
      // The route *pattern* (e.g. `/discover/hotel/:hotelId`), for matching
      // parametrised routes against the public/auth route sets.
      final String pattern = state.fullPath ?? loc;
      final bool onAuthSurface = AppRoutes.authSurface.contains(loc);
      final bool onProfile = loc == AppRoutes.completeProfile;
      final bool onSplash = loc == AppRoutes.splash;

      final bool languageChosen = ref.read(languageSelectedProvider);
      final bool onboarded = ref.read(onboardingCompletedProvider);
      // Where a signed-out guest enters the app: onboarding on the first run,
      // straight to browsing once it has been completed on any earlier launch.
      final String entry = onboarded ? AppRoutes.discover : AppRoutes.welcome;

      return auth.map(
        unknown: () => onSplash ? null : AppRoutes.splash,
        unauthenticated: () {
          // Language + onboarding are first-run only.
          if (onboarded &&
              (loc == AppRoutes.language || loc == AppRoutes.welcome)) {
            return entry;
          }
          // First run: the language screen sits before everything else on the
          // unauthenticated surface.
          if (loc == AppRoutes.language) {
            return languageChosen ? AppRoutes.welcome : null;
          }
          if (!languageChosen) return AppRoutes.language;
          if (onSplash) return entry;
          if (loc == AppRoutes.sessionExpired) return entry;
          if (onAuthSurface) return null;
          // Account is an explicit sign-in entry point for guests. Keep the
          // rest of the app's deferred-auth browsing flow unchanged.
          if (loc == AppRoutes.account) return AppRoutes.signIn;
          // Deferred auth: a guest may browse discovery + the booking review
          // without an account (docs/mobile-deferred-auth.md). Sign-in is
          // requested from the "confirm" action, not the router. The Bookings
          // and Services tabs are reachable too and show a sign-in prompt.
          if (AppRoutes.isPublic(pattern)) return null;
          return entry;
        },
        awaitingProfile: (_) => onProfile ? null : AppRoutes.completeProfile,
        authenticated: (_) {
          if (onSplash || onAuthSurface || onProfile) {
            // If the guest signed in mid-booking, return them to where they
            // were (the review screen); otherwise land on the app home.
            return ref.read(postAuthRedirectProvider.notifier).consume() ??
                AppRoutes.authenticatedHome;
          }
          return null;
        },
        sessionExpired: () =>
            loc == AppRoutes.sessionExpired ? null : AppRoutes.sessionExpired,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (_, _) => const AuthSplashPage(),
      ),
      GoRoute(
        path: AppRoutes.language,
        name: AppRoutes.languageName,
        builder: (_, _) => const LanguageSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcomeName,
        builder: (_, _) => const EntryWelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRoutes.signInName,
        builder: (_, _) => const PhoneLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: AppRoutes.otpName,
        builder: (_, _) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        name: AppRoutes.completeProfileName,
        builder: (_, _) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.sessionExpired,
        name: AppRoutes.sessionExpiredName,
        builder: (_, _) => const SessionExpiredPage(),
      ),
      // Foundation diagnostics (demo buttons) — never shipped in release.
      if (!kReleaseMode)
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (_, _) => const FoundationHomePage(),
        ),
      GoRoute(
        path: AppRoutes.discover,
        name: AppRoutes.discoverName,
        builder: (_, _) => const DiscoverPage(),
      ),
      GoRoute(
        path: AppRoutes.hotelSearch,
        name: AppRoutes.hotelSearchName,
        builder: (_, _) => const HotelSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.hotelDetail,
        name: AppRoutes.hotelDetailName,
        builder: (BuildContext context, GoRouterState state) =>
            HotelDetailPage(hotelId: state.pathParameters['hotelId']!),
      ),
      GoRoute(
        path: AppRoutes.stayDates,
        name: AppRoutes.stayDatesName,
        builder: (BuildContext context, GoRouterState state) =>
            StayDatesPage(hotelId: state.pathParameters['hotelId']!),
      ),
      GoRoute(
        path: AppRoutes.availableRooms,
        name: AppRoutes.availableRoomsName,
        builder: (BuildContext context, GoRouterState state) =>
            AvailableRoomsPage(hotelId: state.pathParameters['hotelId']!),
      ),
      GoRoute(
        path: AppRoutes.roomDetail,
        name: AppRoutes.roomDetailName,
        builder: (BuildContext context, GoRouterState state) => RoomDetailPage(
          hotelId: state.pathParameters['hotelId']!,
          roomTypeId: state.pathParameters['roomTypeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.roomSelectionReview,
        name: AppRoutes.roomSelectionReviewName,
        builder: (BuildContext context, GoRouterState state) =>
            RoomSelectionReviewPage(hotelId: state.pathParameters['hotelId']!),
      ),
      GoRoute(
        path: AppRoutes.reservationDetail,
        name: AppRoutes.reservationDetailName,
        builder: (BuildContext context, GoRouterState state) =>
            ReservationDetailPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.contactReception,
        name: AppRoutes.contactReceptionName,
        builder: (BuildContext context, GoRouterState state) => ContactReceptionPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentReview,
        name: AppRoutes.paymentReviewName,
        builder: (BuildContext context, GoRouterState state) => PaymentReviewPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        name: AppRoutes.paymentMethodName,
        builder: (BuildContext context, GoRouterState state) => PaymentMethodPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentCardDetails,
        name: AppRoutes.paymentCardDetailsName,
        builder: (BuildContext context, GoRouterState state) =>
            PaymentCardDetailsPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentProcessing,
        name: AppRoutes.paymentProcessingName,
        builder: (BuildContext context, GoRouterState state) =>
            PaymentProcessingPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentResult,
        name: AppRoutes.paymentResultName,
        builder: (BuildContext context, GoRouterState state) => PaymentResultPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.identityVerification,
        name: AppRoutes.identityVerificationName,
        builder: (BuildContext context, GoRouterState state) =>
            IdentityVerificationPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.identityVerificationResult,
        name: AppRoutes.identityVerificationResultName,
        builder: (BuildContext context, GoRouterState state) =>
            IdentityVerificationResultPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkIn,
        name: AppRoutes.checkInName,
        builder: (BuildContext context, GoRouterState state) => CheckInPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkInProcessing,
        name: AppRoutes.checkInProcessingName,
        builder: (BuildContext context, GoRouterState state) =>
            CheckInProcessingPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.digitalAccess,
        name: AppRoutes.digitalAccessName,
        builder: (BuildContext context, GoRouterState state) =>
            DigitalAccessPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.stayServices,
        name: AppRoutes.stayServicesName,
        builder: (BuildContext context, GoRouterState state) => StayServicesPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        name: AppRoutes.serviceDetailName,
        builder: (BuildContext context, GoRouterState state) => ServiceDetailPage(
          reservationId: state.pathParameters['reservationId']!,
          serviceId: state.pathParameters['serviceId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceOrders,
        name: AppRoutes.serviceOrdersName,
        builder: (BuildContext context, GoRouterState state) =>
            MyServiceRequestsPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceOrderDetail,
        name: AppRoutes.serviceOrderDetailName,
        builder: (BuildContext context, GoRouterState state) =>
            ServiceOrderDetailPage(
          reservationId: state.pathParameters['reservationId']!,
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: AppRoutes.checkoutName,
        builder: (BuildContext context, GoRouterState state) => CheckoutPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkoutProcessing,
        name: AppRoutes.checkoutProcessingName,
        builder: (BuildContext context, GoRouterState state) =>
            CheckoutProcessingPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkoutComplete,
        name: AppRoutes.checkoutCompleteName,
        builder: (BuildContext context, GoRouterState state) =>
            CheckoutCompletionPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.invoice,
        name: AppRoutes.invoiceName,
        builder: (BuildContext context, GoRouterState state) => InvoicePage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.loyalty,
        name: AppRoutes.loyaltyName,
        builder: (BuildContext context, GoRouterState state) => LoyaltyPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.loyaltyRedeem,
        name: AppRoutes.loyaltyRedeemName,
        builder: (BuildContext context, GoRouterState state) => LoyaltyRedeemPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reviewForm,
        name: AppRoutes.reviewFormName,
        builder: (BuildContext context, GoRouterState state) => ReviewFormPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reviewProcessing,
        name: AppRoutes.reviewProcessingName,
        builder: (BuildContext context, GoRouterState state) =>
            ReviewProcessingPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reviewResult,
        name: AppRoutes.reviewResultName,
        builder: (BuildContext context, GoRouterState state) => ReviewResultPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceReviewForm,
        name: AppRoutes.serviceReviewFormName,
        builder: (BuildContext context, GoRouterState state) =>
            ServiceReviewFormPage(
          reservationId: state.pathParameters['reservationId']!,
          serviceOrderId: state.pathParameters['serviceOrderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceReviewProcessing,
        name: AppRoutes.serviceReviewProcessingName,
        builder: (BuildContext context, GoRouterState state) =>
            ServiceReviewProcessingPage(
          reservationId: state.pathParameters['reservationId']!,
          serviceOrderId: state.pathParameters['serviceOrderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceReviewResult,
        name: AppRoutes.serviceReviewResultName,
        builder: (BuildContext context, GoRouterState state) =>
            ServiceReviewResultPage(
          reservationId: state.pathParameters['reservationId']!,
          serviceOrderId: state.pathParameters['serviceOrderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        name: AppRoutes.bookingsName,
        builder: (_, _) => const BookingsListPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePersonalInfo,
        name: AppRoutes.profilePersonalInfoName,
        builder: (BuildContext context, GoRouterState state) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePreferences,
        name: AppRoutes.profilePreferencesName,
        builder: (BuildContext context, GoRouterState state) => const PreferencesPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePrivacy,
        name: AppRoutes.profilePrivacyName,
        builder: (BuildContext context, GoRouterState state) => const PrivacyPage(),
      ),
      GoRoute(
        path: AppRoutes.profileSupport,
        name: AppRoutes.profileSupportName,
        builder: (BuildContext context, GoRouterState state) => const SupportPage(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: AppRoutes.faqName,
        builder: (BuildContext context, GoRouterState state) => const FaqPage(),
      ),
      GoRoute(
        path: AppRoutes.cancellationPolicy,
        name: AppRoutes.cancellationPolicyName,
        builder: (BuildContext context, GoRouterState state) => const CancellationPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.logoutConfirm,
        name: AppRoutes.logoutConfirmName,
        builder: (BuildContext context, GoRouterState state) => const LogoutConfirmPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.account,
        name: AppRoutes.accountName,
        builder: (_, _) => const AccountHomePage(),
      ),
      GoRoute(
        path: AppRoutes.stayHome,
        name: AppRoutes.stayHomeName,
        builder: (_, _) => const StayHomePage(),
      ),
      GoRoute(
        path: AppRoutes.extendStay,
        name: AppRoutes.extendStayName,
        builder: (BuildContext context, GoRouterState state) => ExtendStayPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reportProblem,
        name: AppRoutes.reportProblemName,
        builder: (BuildContext context, GoRouterState state) =>
            ReportProblemCategoryPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reportProblemDescribe,
        name: AppRoutes.reportProblemDescribeName,
        builder: (BuildContext context, GoRouterState state) =>
            ReportProblemDescriptionPage(
          reservationId: state.pathParameters['reservationId']!,
          category: ProblemCategory.fromWire(state.pathParameters['category']),
        ),
      ),
      GoRoute(
        path: AppRoutes.reportProblemSubmitted,
        name: AppRoutes.reportProblemSubmittedName,
        builder: (BuildContext context, GoRouterState state) =>
            ReportProblemSubmittedPage(
          reservationId: state.pathParameters['reservationId']!,
          reportId: state.pathParameters['reportId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.problemReportDetail,
        name: AppRoutes.problemReportDetailName,
        builder: (BuildContext context, GoRouterState state) =>
            ProblemReportDetailPage(
          reservationId: state.pathParameters['reservationId']!,
          reportId: state.pathParameters['reportId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.problemReports,
        name: AppRoutes.problemReportsName,
        builder: (BuildContext context, GoRouterState state) =>
            MyProblemReportsPage(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: HotelAppBar(title: context.l10n.appName),
      body: ErrorView(
        title: context.l10n.stateErrorTitle,
        message: context.l10n.errorGeneric,
      ),
    ),
  );
});
