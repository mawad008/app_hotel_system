// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hotel System';

  @override
  String get appTagline => 'Book, verify and enter — from your phone.';

  @override
  String get foundationScreenTitle => 'Foundation & Design System';

  @override
  String get foundationScreenSubtitle =>
      'Mobile Phase 0 — architecture, theme, localization and data-layer scaffolding only. Feature screens arrive in later phases.';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionTheme => 'Appearance';

  @override
  String get sectionBackendStatus => 'Backend connectivity';

  @override
  String get sectionComponents => 'Design system components';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String environmentLabel(String name) {
    return 'Environment: $name';
  }

  @override
  String apiBaseUrlLabel(String url) {
    return 'API base URL: $url';
  }

  @override
  String get backendStatusOk => 'Reachable';

  @override
  String get backendStatusDegraded => 'Degraded';

  @override
  String get backendStatusDown => 'Unreachable';

  @override
  String backendStatusCheckedAt(String time) {
    return 'Checked at $time';
  }

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCheckAgain => 'Check again';

  @override
  String get actionPrimaryExample => 'Primary action';

  @override
  String get actionSecondaryExample => 'Secondary action';

  @override
  String get stateLoadingTitle => 'Loading…';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get stateEmptySubtitle =>
      'When there is something to show, it will appear here.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsUnreadTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count new notifications',
      one: 'You have 1 new notification',
    );
    return '$_temp0';
  }

  @override
  String get notificationsAllReadTitle => 'You\'re all caught up';

  @override
  String get notificationsBannerBody =>
      'Tap any notification to go straight to it.';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody =>
      'Updates about your bookings and stays will appear here.';

  @override
  String get notificationsNow => 'Now';

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String get notificationsUnreadLabel => 'Unread';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsOpenTooltip => 'Notifications';

  @override
  String get errorGeneric =>
      'We could not complete that request. Please try again.';

  @override
  String get errorNetwork =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorServer =>
      'The service is temporarily unavailable. Please try again later.';

  @override
  String get errorNotImplemented =>
      'This isn\'t available yet. Please try again later.';

  @override
  String get textFieldExampleLabel => 'Full name';

  @override
  String get textFieldExampleHint => 'Enter your name';

  @override
  String get brandWordmark => 'Hotel System';

  @override
  String get entryHeadline =>
      'Explore Al Waha Hotel and book from wherever you are';

  @override
  String get entrySubtext =>
      'Simply pick your favourite room at the time that suits you';

  @override
  String get entryStartAction => 'Start now';

  @override
  String get entryLanguageSwitchLabel => 'Language';

  @override
  String get languageScreenHeading => 'Choose the app language';

  @override
  String get authPhoneTitle => 'Sign in';

  @override
  String get authPhoneHeading => 'Enter your mobile number';

  @override
  String get authPhoneBody =>
      'We use it to confirm your booking and send your room entry code. We will not use it for anything else.';

  @override
  String get authPhoneFieldLabel => 'Mobile number';

  @override
  String get authPhoneFieldHint => '05 1234 5678';

  @override
  String get authPhoneHelper =>
      'We will send a verification code to this number';

  @override
  String get authPhoneTerms =>
      'By continuing you agree to the Terms and the Privacy Policy.';

  @override
  String get authPhoneSubmit => 'Send verification code';

  @override
  String get authPhoneEmpty => 'Mobile number is required';

  @override
  String get authPhoneInvalid =>
      'Enter a Saudi mobile number starting with 05 (10 digits)';

  @override
  String get authOtpTitle => 'Verification code';

  @override
  String get authOtpHeading => 'Enter the code we sent';

  @override
  String get authOtpChange => 'Change';

  @override
  String authOtpResendCountdown(String time) {
    return 'Resend in $time';
  }

  @override
  String get authOtpResendAction => 'Resend the code';

  @override
  String get authOtpSubmit => 'Confirm';

  @override
  String authOtpInvalidFormat(int length) {
    return 'Enter the $length-digit code';
  }

  @override
  String get authOtpErrorTitle => 'Incorrect code';

  @override
  String authOtpErrorBody(int count) {
    return 'Attempts remaining: $count. Use the most recent code — earlier codes stop working as soon as a new one is sent.';
  }

  @override
  String get authOtpRetry => 'Try again';

  @override
  String get authOtpChangeNumber => 'Change mobile number';

  @override
  String get authOtpLockedTitle => 'Too many attempts';

  @override
  String get authOtpLockedBody =>
      'For your security we stopped accepting codes. Request a new code to continue.';

  @override
  String get authProfileTitle => 'Complete your details';

  @override
  String get authProfileBannerTitle =>
      'Write your name exactly as it appears on your ID';

  @override
  String get authProfileBannerBody =>
      'The system matches your name against your ID during verification. Any difference may delay your check-in.';

  @override
  String get authProfileNameLabel => 'Full name';

  @override
  String get authProfileNameHint => 'Full name as on your ID';

  @override
  String get authProfileEmailLabel => 'Email';

  @override
  String get authProfileEmailHint => 'name@example.com';

  @override
  String get authProfileSubmit => 'Save and continue';

  @override
  String get authProfileNameInvalid => 'Enter your full name';

  @override
  String get authProfileEmailInvalid => 'Enter a valid email address';

  @override
  String get authSessionExpiredTitle => 'Session ended';

  @override
  String get authSessionExpiredBannerTitle => 'Your session has ended';

  @override
  String get authSessionExpiredBannerBody =>
      'Your booking is saved and was not cancelled. Sign in again and we will take you back to where you left off.';

  @override
  String get authSessionExpiredSubmit => 'Sign in';

  @override
  String get authSignOut => 'Sign out';

  @override
  String authDemoHint(String code) {
    return 'Development build: the verification code is $code.';
  }

  @override
  String get commonApply => 'Apply';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonBack => 'Back';

  @override
  String get navHome => 'Home';

  @override
  String get navBookings => 'My bookings';

  @override
  String get navServices => 'Services';

  @override
  String get navAccount => 'Account';

  @override
  String get navComingSoon => 'This section is coming in a later update.';

  @override
  String get discoverGreeting => 'Welcome';

  @override
  String discoverGreetingNamed(String name) {
    return 'Welcome, $name';
  }

  @override
  String get discoverSubtitle => 'Discover the group\'s hotels';

  @override
  String get discoverSearchHint => 'Search for a hotel or city';

  @override
  String get discoverNotificationsTooltip => 'Notifications';

  @override
  String get discoverFeaturedSection => 'Group hotels';

  @override
  String get discoverExploreRooms => 'Explore rooms';

  @override
  String get discoverUpcomingStay => 'Your upcoming stay';

  @override
  String get discoverUpcomingStayAction => 'View booking';

  @override
  String get discoverExploreHotels => 'Explore the group\'s hotels';

  @override
  String discoverSubtitleHotel(String hotel) {
    return 'Discover $hotel';
  }

  @override
  String get discoverEmptyTitle => 'No hotels to show yet';

  @override
  String get discoverEmptyBody =>
      'The group\'s hotels will appear here once they are published.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchClearTooltip => 'Clear search';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hotels available',
      one: '1 hotel available',
      zero: 'No hotels available',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsTitle => 'No hotels match your search';

  @override
  String get searchNoResultsBody =>
      'Try a different city or clear your filters.';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get sortRecommended => 'Recommended';

  @override
  String get sortTopRated => 'Top rated';

  @override
  String get sortLowestPrice => 'Best value';

  @override
  String get sortTitle => 'Sort results';

  @override
  String get sortHint => 'The order stays until you change it or search again.';

  @override
  String get sortApply => 'Apply sort';

  @override
  String get sortActiveTag => 'on';

  @override
  String get filterTitle => 'Filter results';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching hotels',
      one: '1 matching hotel',
      zero: 'No matching hotels',
    );
    return '$_temp0';
  }

  @override
  String get filterHint => 'Adjust the criteria to narrow the results.';

  @override
  String get filterCityLabel => 'City';

  @override
  String get filterValueAll => 'All';

  @override
  String filterSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get filterPriceLabel => 'Price range';

  @override
  String get filterFacilitiesLabel => 'Facilities';

  @override
  String get filterRatingLabel => 'Rating';

  @override
  String get filterApply => 'Apply filter';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterCityPickerTitle => 'City';

  @override
  String get filterCityPickerHint =>
      'You can choose more than one city. Results update when you apply.';

  @override
  String cityHotelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hotels',
      one: '1 hotel',
    );
    return '$_temp0';
  }

  @override
  String priceRangeValue(int min, int max) {
    return 'SAR $min – SAR $max';
  }

  @override
  String priceFrom(String amount) {
    return 'from SAR $amount';
  }

  @override
  String pricePerNight(String amount) {
    return 'SAR $amount / night';
  }

  @override
  String priceStayTotal(String amount) {
    return 'SAR $amount total';
  }

  @override
  String get priceFromLabel => 'from';

  @override
  String get priceNightSuffix => '/ night';

  @override
  String get priceTotalSuffix => 'total';

  @override
  String hotelRatingValue(double rating) {
    final intl.NumberFormat ratingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ratingString = ratingNumberFormat.format(rating);

    return '$ratingString';
  }

  @override
  String hotelReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get hotelAvailable => 'Available';

  @override
  String get hotelUnavailable => 'Not available right now';

  @override
  String get hotelDetailAmenities => 'Services & facilities';

  @override
  String hotelRoomTypeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count room types',
      one: '1 room type',
    );
    return '$_temp0';
  }

  @override
  String hotelPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count',
    );
    return '$_temp0';
  }

  @override
  String get hotelSelectDates => 'Select dates';

  @override
  String get hotelBookNow => 'Book now';

  @override
  String hotelGuestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String roomAreaSqm(int area) {
    return '$area m²';
  }

  @override
  String get amenityFreeWifi => 'Free Wi-Fi';

  @override
  String get amenityBreakfast => 'Breakfast';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityPool => 'Pool';

  @override
  String get amenityGym => 'Gym';

  @override
  String get amenityFamilyRooms => 'Family rooms';

  @override
  String get amenityAirportShuttle => 'Airport shuttle';

  @override
  String get amenityRoomService => 'Room service';

  @override
  String get amenityAirConditioning => 'Air conditioning';

  @override
  String get amenityCityView => 'City view';

  @override
  String get amenityBalcony => 'Balcony';

  @override
  String get amenityKitchenette => 'Kitchenette';

  @override
  String get stayDatesTitle => 'Choose your stay dates';

  @override
  String get stayDatesCheckIn => 'Check-in';

  @override
  String get stayDatesCheckOut => 'Check-out';

  @override
  String get stayDatesPick => 'Choose date';

  @override
  String get stayDatesClear => 'Clear dates';

  @override
  String get stayDatesShowRooms => 'Show available rooms';

  @override
  String stayNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get stayDatesErrorCheckoutBeforeCheckin =>
      'Check-out must be after check-in';

  @override
  String get stayDatesErrorPast => 'Choose a date from today onwards';

  @override
  String get stayDatesEditDates => 'Edit dates';

  @override
  String get guestsTitle => 'Number of guests';

  @override
  String get guestsAdults => 'Adults';

  @override
  String get guestsChildren => 'Children';

  @override
  String get guestsConfirm => 'Confirm guests';

  @override
  String get stepperDecrease => 'Decrease';

  @override
  String get stepperIncrease => 'Increase';

  @override
  String guestsAdultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return '$_temp0';
  }

  @override
  String guestsChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String get roomsTitle => 'Available rooms';

  @override
  String roomsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms available',
      one: '1 room available',
      zero: 'No rooms available',
    );
    return '$_temp0';
  }

  @override
  String get roomsSortLabel => 'Sort';

  @override
  String get roomsSortLowest => 'Lowest price';

  @override
  String get roomsSortHighest => 'Highest price';

  @override
  String roomOccupancy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get roomBreakfastIncluded => 'Breakfast included';

  @override
  String get roomFreeCancellation => 'Free cancellation';

  @override
  String get roomNonRefundable => 'Non-refundable';

  @override
  String get roomSoldOut => 'Not available for these dates';

  @override
  String get roomsAllSoldOutTitle => 'All rooms are sold out for these dates';

  @override
  String get roomsAllSoldOutBody =>
      'Try different dates and we will show the rooms that open up.';

  @override
  String get roomsNoResultsTitle => 'No rooms for these dates';

  @override
  String get roomsNoResultsBody =>
      'Try different dates or adjust the number of guests.';

  @override
  String get roomsChangeDates => 'Change dates';

  @override
  String get roomsChangeGuests => 'Change guests';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonClose => 'Close';

  @override
  String get commonEdit => 'Edit';

  @override
  String get calendarWeekdays => 'Sun,Mon,Tue,Wed,Thu,Fri,Sat';

  @override
  String stayDatesSelectedRange(String checkIn, String checkOut) {
    return '$checkIn – $checkOut';
  }

  @override
  String get stayDatesHintPickCheckIn => 'Choose your check-in date to start';

  @override
  String stayDatesHintPickCheckOut(String checkIn) {
    return '$checkIn · choose your check-out date';
  }

  @override
  String get stayDatesFieldPlaceholder => 'Choose date';

  @override
  String get roomSelect => 'Select';

  @override
  String get roomSelected => 'Selected';

  @override
  String get roomViewDetails => 'View details';

  @override
  String get roomDetailsTitle => 'Room details';

  @override
  String get roomBedType => 'Bed';

  @override
  String get roomCapacityLabel => 'Sleeps';

  @override
  String get roomPolicyLabel => 'Cancellation';

  @override
  String roomPolicyRefundable(int hours) {
    return 'Free cancellation with a full refund within $hours hours of booking, or until check-in if sooner.';
  }

  @override
  String get roomPolicyRefundableShort => 'Free cancellation available';

  @override
  String get roomPolicyNonRefundable => 'Non-refundable';

  @override
  String get roomSelectThisRoom => 'Select this room';

  @override
  String get roomRemoveSelection => 'Remove selection';

  @override
  String roomStayTotalLabel(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return 'total for $_temp0';
  }

  @override
  String get roomCardPerNight => '/ night';

  @override
  String get roomCardFreeCancellation => 'Free cancellation';

  @override
  String stayGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get roomDetailAmenitiesHeading => 'Room facilities';

  @override
  String get roomDetailCancellationHeading => 'Cancellation policy';

  @override
  String get roomDetailStayHeading => 'Your stay';

  @override
  String get roomSortTitle => 'Sort rooms';

  @override
  String get roomSortApply => 'Apply sort';

  @override
  String get roomSortActiveTag => 'on';

  @override
  String roomsSortTrigger(String label) {
    return 'Sort: $label';
  }

  @override
  String get roomsContinue => 'Continue';

  @override
  String get roomFilterWifi => 'Wi-Fi';

  @override
  String get roomsFilterCta => 'Filter';

  @override
  String get roomsNoFilterMatch => 'No rooms match these filters';

  @override
  String get roomFilterTitle => 'Filter rooms';

  @override
  String get roomFilterCancellation => 'Cancellation policy';

  @override
  String get roomFilterFreeCancellation => 'Free cancellation';

  @override
  String get roomFilterMeals => 'Meals';

  @override
  String get roomFilterBreakfast => 'Breakfast included';

  @override
  String get roomFilterFeatures => 'Features';

  @override
  String get roomFilterReset => 'Reset';

  @override
  String get roomFilterShowResults => 'Show results';

  @override
  String get roomsSelectPrompt => 'Select a room to continue';

  @override
  String get roomsSelectionClearedNotice =>
      'Your room selection was cleared because the stay details changed. Choose a room again.';

  @override
  String get reviewTitle => 'Review your selection';

  @override
  String get reviewNotBookedNotice =>
      'Nothing is booked yet. You can still change your dates, guests or room before the reservation step.';

  @override
  String get reviewHotelLabel => 'Hotel';

  @override
  String get reviewRoomLabel => 'Room';

  @override
  String get reviewStayLabel => 'Stay';

  @override
  String get reviewGuestsLabel => 'Guests';

  @override
  String get reviewCheckInLabel => 'Check-in';

  @override
  String get reviewCheckOutLabel => 'Check-out';

  @override
  String get reviewPriceLabel => 'Price';

  @override
  String reviewTotalLabel(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return 'Total for $_temp0';
  }

  @override
  String get reviewChangeSelection => 'Change selection';

  @override
  String get reviewNoSelectionTitle => 'No room selected';

  @override
  String get reviewNoSelectionBody =>
      'Go back and choose a room to see your selection here.';

  @override
  String get reviewBackToRooms => 'Back to rooms';

  @override
  String get reviewSignInToConfirm => 'Sign in to confirm';

  @override
  String get reviewSignInHint =>
      'You\'ll need an account to confirm this booking. Browsing stays free.';

  @override
  String get bookingDetailsTitle => 'Booking details';

  @override
  String get bookingDatesLabel => 'Stay dates';

  @override
  String get bookingRoomSubtotal => 'Stay subtotal';

  @override
  String get bookingServiceFee => 'Service fee';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingProceedToPayment => 'Proceed to payment';

  @override
  String get bookingRoomAvailable => 'Available';

  @override
  String get reservationConfirmCta => 'Confirm reservation';

  @override
  String get reservationConfirming => 'Confirming…';

  @override
  String get reservationConfirmHint =>
      'By confirming, you request this room for the dates above. Nothing is charged yet.';

  @override
  String get reservationCreateFailedTitle =>
      'We couldn\'t confirm your reservation';

  @override
  String get reservationStatusFieldLabel => 'Status';

  @override
  String get reservationStatusPending => 'Pending';

  @override
  String get reservationStatusConfirmed => 'Confirmed';

  @override
  String get reservationStatusDepositHeld => 'Deposit held';

  @override
  String get reservationStatusVerified => 'Verified';

  @override
  String get reservationStatusCheckedIn => 'Checked in';

  @override
  String get reservationStatusInStay => 'In stay';

  @override
  String get reservationStatusCheckoutInProgress => 'Checkout in progress';

  @override
  String get reservationStatusCheckoutBlocked => 'Checkout on hold';

  @override
  String get reservationStatusCheckedOut => 'Checked out';

  @override
  String get reservationStatusInvoiced => 'Invoiced';

  @override
  String get reservationStatusCancelled => 'Cancelled';

  @override
  String moneyAmount(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get paymentReviewTitle => 'Payment';

  @override
  String get paymentProcessingTitle => 'Processing payment';

  @override
  String get paymentResultTitle => 'Payment';

  @override
  String get paymentReservationLabel => 'Reservation';

  @override
  String get paymentStatusFieldLabel => 'Payment status';

  @override
  String get paymentPayNowCta => 'Pay now';

  @override
  String get paymentHoldExplainer =>
      'A refundable deposit hold is placed for your stay. Nothing is charged now.';

  @override
  String get paymentProcessingBody => 'Confirming your payment…';

  @override
  String get paymentDoNotClose => 'Please keep this screen open.';

  @override
  String get paymentAlreadyHeldTitle => 'Deposit already held';

  @override
  String get paymentAlreadyHeldBody =>
      'The deposit hold for this reservation is already in place.';

  @override
  String get paymentSuccessTitle => 'Deposit hold confirmed';

  @override
  String get paymentNotRequiredTitle => 'Your booking is confirmed';

  @override
  String get paymentNotRequiredBody =>
      'This hotel takes no deposit. Your stay starts at check-in.';

  @override
  String get paymentSuccessBody =>
      'Your deposit is secured. You can continue with identity verification.';

  @override
  String get paymentPendingTitle => 'Payment is processing';

  @override
  String get paymentPendingBody =>
      'Your bank hasn\'t confirmed the hold yet. You can check the status again shortly.';

  @override
  String get paymentFailedTitle => 'Payment didn\'t go through';

  @override
  String get paymentFailedBody => 'No money was taken. You can try again.';

  @override
  String get paymentCancelledTitle => 'Payment cancelled';

  @override
  String get paymentExpiredTitle => 'Payment hold expired';

  @override
  String get paymentRetryCta => 'Try again';

  @override
  String get paymentBackToReservation => 'Back to reservation';

  @override
  String get paymentUnavailableTitle => 'Payment is unavailable';

  @override
  String get paymentStatusNotStarted => 'Not started';

  @override
  String get paymentStatusHoldRequested => 'Authorizing';

  @override
  String get paymentStatusHoldActive => 'Deposit held';

  @override
  String get paymentStatusHoldFailed => 'Failed';

  @override
  String get paymentStatusCaptureRequested => 'Charging';

  @override
  String get paymentStatusCaptured => 'Charged';

  @override
  String get paymentStatusCaptureFailed => 'Charge failed';

  @override
  String get paymentStatusFinalSettlementRequested => 'Settling';

  @override
  String get paymentStatusSettled => 'Settled';

  @override
  String get paymentStatusSettlementFailed => 'Settlement failed';

  @override
  String get paymentStatusCancelled => 'Cancelled';

  @override
  String get paymentStatusExpired => 'Expired';

  @override
  String get paymentStatusRefundRequested => 'Refund pending';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get paymentStatusRefundFailed => 'Refund failed';

  @override
  String get paymentMethodTitle => 'Payment method';

  @override
  String get paymentMethodBannerTitle => 'Choose a payment method';

  @override
  String get paymentMethodBannerBody =>
      'The deposit hold is placed without a fee and released after check-out, unless extra charges are recorded.';

  @override
  String get paymentMethodApplePay => 'Apple Pay';

  @override
  String get paymentMethodSavedCard => 'Card or debit card';

  @override
  String get paymentMethodAddNewCard => 'Add a new card';

  @override
  String get paymentHoldNotice =>
      'The deposit is held, not charged, until check-in';

  @override
  String get paymentCardDetailsTitle => 'Payment';

  @override
  String get paymentCardDepositLabel => 'Deposit amount';

  @override
  String get paymentCardNumberLabel => 'Card number';

  @override
  String get paymentCardNumberHint => '4242 4242 4242 4242';

  @override
  String get paymentCardholderNameLabel => 'Name on card';

  @override
  String get paymentCardNotStoredNote =>
      'Your card details are not stored in the system.';

  @override
  String get paymentConfirmCta => 'Confirm payment';

  @override
  String get identityVerificationTitle => 'Identity verification';

  @override
  String get identityVerificationResultTitle => 'Identity verification';

  @override
  String get identityVerifyCta => 'Verify identity';

  @override
  String get identityStepDocument => 'Document';

  @override
  String get identityStepSelfie => 'Selfie';

  @override
  String get identityStepResult => 'Result';

  @override
  String get identityDocumentStepTitle => 'Upload your ID document';

  @override
  String get identityDocumentStepBody =>
      'Use your passport, national ID or residence permit. Make sure the whole document is visible and readable.';

  @override
  String get identityDocumentTypePassport => 'Passport';

  @override
  String get identityDocumentTypeNationalId => 'National ID';

  @override
  String get identityDocumentTypeResidencePermit => 'Residence permit';

  @override
  String get identityDocumentTypeLabel => 'Document type';

  @override
  String get identityDocumentCaptureCta => 'Add document photo';

  @override
  String get identityDocumentCapturedLabel => 'Document photo added';

  @override
  String get identityDocumentSubmitCta => 'Continue to selfie';

  @override
  String get identitySelfieStepTitle => 'Take a selfie';

  @override
  String get identitySelfieStepBody =>
      'Look straight at the camera in good light. We match your selfie to your ID photo.';

  @override
  String get identitySelfieCaptureCta => 'Add selfie';

  @override
  String get identitySelfieCapturedLabel => 'Selfie added';

  @override
  String get identitySelfieSubmitCta => 'Submit for verification';

  @override
  String get identityProcessingTitle => 'Verifying your identity';

  @override
  String get identityProcessingBody => 'Matching your selfie to your document…';

  @override
  String get identityApprovedTitle => 'Identity verified';

  @override
  String get identityApprovedBody =>
      'Your identity is confirmed. You\'re ready for check-in.';

  @override
  String get identityManualReviewTitle => 'Manual review in progress';

  @override
  String get identityManualReviewBody =>
      'Our team is reviewing your documents. This usually takes a short while — we\'ll notify you when it\'s done.';

  @override
  String get identityRetryTitle => 'Let\'s try that again';

  @override
  String get identityRetryBody =>
      'We couldn\'t verify your identity from those photos. Please retake them and submit again.';

  @override
  String get identityRetryCta => 'Try again';

  @override
  String get identityRejectedTitle => 'Verification not approved';

  @override
  String get identityRejectedBody =>
      'Our team could not approve your identity verification. Please contact the front desk for help.';

  @override
  String get identityRejectedRetryBody =>
      'Our team could not approve your identity verification. You can submit new photos and try again.';

  @override
  String identityAttemptCount(int count) {
    return 'Attempt $count';
  }

  @override
  String get identityBackToReservation => 'Back to reservation';

  @override
  String get identityViewResultCta => 'View result';

  @override
  String get identityUnavailableTitle => 'Verification is unavailable';

  @override
  String get identityStatusNotStarted => 'Not started';

  @override
  String get identityStatusDocumentUploaded => 'Document uploaded';

  @override
  String get identityStatusSelfieCaptured => 'Selfie captured';

  @override
  String get identityStatusMatchingInProgress => 'Matching';

  @override
  String get identityStatusAutoApproved => 'Verified';

  @override
  String get identityStatusPendingManualReview => 'In review';

  @override
  String get identityStatusStaffApproved => 'Verified';

  @override
  String get identityStatusStaffRejected => 'Not approved';

  @override
  String get identityStatusRetryAllowed => 'Retry needed';

  @override
  String get identityIntroBannerTitle => 'Quick identity check';

  @override
  String get identityIntroBannerBody =>
      'Two steps: a photo of your ID, then a live selfie. Photos are deleted once your stay ends.';

  @override
  String get identityIntroBannerBodyDocumentOnly =>
      'One step: a photo of your ID. Photos are deleted once your stay ends.';

  @override
  String get identityDocumentOnlyBody =>
      'Choose your document type, then take a clear photo of it.';

  @override
  String get identityIntroCta => 'Start verification';

  @override
  String get identityCaptureDocumentTitle => 'Photograph your ID';

  @override
  String get identityCaptureDocumentHint =>
      'Fit the ID inside the frame with all four edges visible.';

  @override
  String get identityCaptureFootnote =>
      'Camera only — no photo library uploads';

  @override
  String get identityCaptureFootnoteWeb => 'Choose a clear photo of your ID';

  @override
  String get identitySelfieFootnoteWeb => 'Choose a clear photo of your face';

  @override
  String get identityCaptureFootnoteSecurity =>
      'Your photos are stored securely and deleted once your stay ends.';

  @override
  String get identityReviewDocumentTitle => 'Confirm the ID photo';

  @override
  String get identityReviewDocumentBody =>
      'Make sure the name, number and expiry date are readable.';

  @override
  String get identityReviewContinueCta => 'Continue';

  @override
  String get identityReviewRetakeCta => 'Retake photo';

  @override
  String get identityCaptureSelfieTitle => 'Identity verification';

  @override
  String get identityCaptureSelfieHint => 'Take a live photo from the camera';

  @override
  String get identityReviewRetakeHint =>
      'You can retake it if the photo isn\'t clear';

  @override
  String get identityShutterLabel => 'Take photo';

  @override
  String get identityCameraDeniedTitle => 'Can\'t access the camera';

  @override
  String get identityCameraDeniedBody =>
      'Verification needs a live camera photo and can\'t use the photo library. Allow camera access in Settings.';

  @override
  String get identityCameraUnavailableBody =>
      'No camera is available on this device. Finish verification on another device or at reception.';

  @override
  String get identityOpenSettingsCta => 'Open Settings';

  @override
  String get identityUploadingBannerTitle => 'Uploading your photo';

  @override
  String get identityUploadingBannerBody =>
      'Don\'t close the app. This usually takes a few seconds on a good connection.';

  @override
  String get identityUploadingCancelCta => 'Cancel';

  @override
  String get identityProcessingContinueCta => 'Continue';

  @override
  String get identitySuccessBannerTitle => 'Identity verified';

  @override
  String get identitySuccessBannerBody =>
      'You won\'t be asked to upload your ID again at any hotel in the group.';

  @override
  String get identityGoToCheckInCta => 'Digital check-in';

  @override
  String get identityRejectedNoRetryBannerBody =>
      'A staff member reviewed and did not approve your submission. You can complete this in person when you arrive — your reservation is kept.';

  @override
  String get identityContactReceptionCta => 'Contact reception';

  @override
  String get identityFailedUploadBannerTitle => 'Couldn\'t upload your photos';

  @override
  String get identityFailedUploadBannerBody =>
      'The connection dropped while uploading. Your photos are saved on your device — you can retry without retaking them.';

  @override
  String get identityRetryUploadCta => 'Retry upload';

  @override
  String get identityContinueLaterCta => 'Continue later';

  @override
  String get identityFaceNotMatchedBannerTitle =>
      'We couldn\'t match your face';

  @override
  String get identityFaceNotMatchedBannerBody =>
      'The live photo didn\'t match your ID closely enough. Try again in good light, facing the camera directly.';

  @override
  String get identityRequestManualReviewCta => 'Request manual review';

  @override
  String get identityDocumentUnclearBannerTitle => 'Photo isn\'t clear';

  @override
  String get identityDocumentUnclearBannerBody =>
      'We couldn\'t read your ID details. Retake the photo with no glare and all four edges visible.';

  @override
  String get identityContactReceptionBannerTitle =>
      'Reception is available 24/7';

  @override
  String get identityContactReceptionBannerBody =>
      'Reception is available around the clock at your hotel. A staff member can complete verification in person on arrival.';

  @override
  String contactReceptionBody(String phone) {
    return 'We\'ll connect you to your hotel\'s reception directly on $phone.';
  }

  @override
  String get contactReceptionNoPhoneBody =>
      'You can reach the reception team directly at the hotel front desk.';

  @override
  String get contactReceptionCallCta => 'Call reception';

  @override
  String contactReceptionCallFailed(String phone) {
    return 'Couldn\'t start a call on this device. Reception number: $phone';
  }

  @override
  String get identityViewVerificationStatusCta => 'View verification status';

  @override
  String get identityDetailsTitle => 'Your ID details';

  @override
  String get identityDetailsBody =>
      'Enter them exactly as printed on your document. We compare them with the photo of your ID and don\'t keep them.';

  @override
  String get identityFullNameLabel => 'Full name as on the document';

  @override
  String get identityFullNameHint =>
      'For a passport, use the Latin letters printed on it';

  @override
  String get identityDocumentNumberLabel => 'Document number';

  @override
  String get identityDateOfBirthLabel => 'Date of birth';

  @override
  String get identityDateOfBirthHint => 'Select a date';

  @override
  String get identityFieldRequired => 'Required';

  @override
  String get identityDocumentNumberInvalid => 'Letters and numbers only';

  @override
  String identityUploadProgress(String percent) {
    return '$percent% uploaded';
  }

  @override
  String get identityReadingDocumentTitle => 'Reading your ID';

  @override
  String get identityReadingDocumentBody =>
      'We\'re checking the details on your document. This takes a few seconds — please keep the app open.';

  @override
  String get identityMismatchTitle => 'Your details don\'t match your ID';

  @override
  String identityMismatchFieldsBody(String fields) {
    return 'Check what you entered against your document: $fields.';
  }

  @override
  String get identityMismatchBody =>
      'What you entered doesn\'t match the document. Check your details or retake the photo.';

  @override
  String get identityFieldName => 'name';

  @override
  String get identityFieldDocumentNumber => 'document number';

  @override
  String get identityFieldDateOfBirth => 'date of birth';

  @override
  String get identityEditDetailsCta => 'Edit my details';

  @override
  String get identityExpiredTitle => 'This document has expired';

  @override
  String get identityExpiredBody =>
      'Your ID must be valid on your check-in date. Use another valid document.';

  @override
  String get identityUseAnotherDocumentCta => 'Use another document';

  @override
  String get identityUnsupportedTitle => 'This document isn\'t accepted';

  @override
  String get identityUnsupportedBody =>
      'Use your passport, national ID or residence permit.';

  @override
  String get identityDocumentTypeEgyptianId => 'Egyptian National ID';

  @override
  String get identityDocumentTypeSaudiId => 'Saudi National ID';

  @override
  String get identityDocumentTypeSaudiIqama => 'Saudi Iqama (residence)';

  @override
  String get identityDocumentSidesFrontOnly => 'Photo of the details page only';

  @override
  String get identityDocumentSidesFrontAndBack =>
      'Photos of the front and the back';

  @override
  String get identityDocumentSidesBackOptional => 'Front photo — back optional';

  @override
  String get identityDocumentStaffCheck => 'Our staff will check this document';

  @override
  String get identityFullNameArabicHint =>
      'In Arabic, exactly as printed: first name, then the rest of the name';

  @override
  String get identityBirthDateFromNumber =>
      'Your date of birth is read from the national number.';

  @override
  String get identityDocumentNumberInvalidForType =>
      'Check the number format for this document';

  @override
  String get identityCaptureBackTitle => 'Photograph the back';

  @override
  String get identityCaptureBackHint =>
      'Turn the card over and fit it inside the frame.';

  @override
  String get identityCaptureTipFrame =>
      'The whole card inside the frame, all four edges visible';

  @override
  String get identityCaptureTipLight =>
      'Good light, no flash or glare on the card';

  @override
  String get identityCaptureTipSteady =>
      'Hold the phone steady over the card so the text is sharp';

  @override
  String get identitySelfieTipFrame =>
      'Your whole face inside the frame, looking at the camera';

  @override
  String get identitySelfieTipClear =>
      'No sunglasses or face covering, in good light';

  @override
  String get identityCaptureSelfieHintWeb =>
      'Choose a recent, clear photo of your face';

  @override
  String get identityStuckContactReception =>
      'Can\'t continue? Contact reception';

  @override
  String get identitySkipBackCta => 'Skip — front only';

  @override
  String get identityReviewBothSides =>
      'Front and back photos are ready. Make sure every detail is readable.';

  @override
  String get identityDocumentAcceptedTitle => 'Document accepted';

  @override
  String get identityDocumentAcceptedBody =>
      'Your details match your document. Next, take a live selfie.';

  @override
  String get identityDocumentReviewTitle => 'Manual review required';

  @override
  String get identityDocumentReviewBody =>
      'Our staff will confirm your document. Continue with the selfie to finish your part.';

  @override
  String get identitySubmitFailedTitle => 'Couldn\'t submit your document';

  @override
  String get reservationCheckInCta => 'Check in';

  @override
  String get checkInTitle => 'Check in';

  @override
  String get checkInProcessingTitle => 'Checking you in';

  @override
  String get accessTitle => 'Room access';

  @override
  String get checkInReadyTitle => 'Ready to check in';

  @override
  String get checkInReadyBody =>
      'Your reservation is verified. Check in to get your room number and entry code.';

  @override
  String get checkInNotReadyTitle => 'Not ready to check in yet';

  @override
  String get checkInRoomNotAssigned =>
      'Your room is being prepared — check-in opens once reception assigns it.';

  @override
  String get checkInAtReception =>
      'This hotel checks guests in at reception when you arrive.';

  @override
  String get checkInIdentityPending => 'Complete identity verification first.';

  @override
  String get checkInNotReadyBody =>
      'Complete payment and identity verification first.';

  @override
  String get checkInUnavailableTitle => 'Check-in isn\'t available';

  @override
  String get checkInAlreadyDoneTitle => 'You\'re already checked in';

  @override
  String get checkInCta => 'Check in now';

  @override
  String get checkInProcessingBody => 'Issuing your digital room key…';

  @override
  String get checkInDoNotClose => 'Please keep this screen open.';

  @override
  String get checkInFailedTitle => 'Check-in didn\'t complete';

  @override
  String get checkInFailedBody =>
      'Your room key couldn\'t be issued. You can try again.';

  @override
  String get checkInPendingTitle => 'Almost there';

  @override
  String get checkInPendingBody =>
      'The front desk is finishing your check-in. Check again shortly.';

  @override
  String get checkInRetryCta => 'Try again';

  @override
  String get accessCheckedInTitle => 'You\'re checked in';

  @override
  String get accessRoomNumberLabel => 'Room number';

  @override
  String get accessEntryCodeLabel => 'Entry code';

  @override
  String accessStayEndsLabel(String date) {
    return 'Your stay ends · $date';
  }

  @override
  String get accessRoomPending => 'Assigned by reception';

  @override
  String get accessKeyNotWorking => 'Key not working?';

  @override
  String accessExpiresLabel(String date) {
    return 'Valid until your stay ends · $date';
  }

  @override
  String get accessHelpBanner => 'Code not working? Contact reception.';

  @override
  String get accessNotIssuedTitle => 'No room key yet';

  @override
  String get accessNotIssuedBody => 'Check in to get your digital room key.';

  @override
  String get accessRevokedTitle => 'Room key deactivated';

  @override
  String get accessRevokedBody =>
      'This room key is no longer active. Contact reception if you need help.';

  @override
  String get accessExpiredTitle => 'Room key expired';

  @override
  String get accessExpiredBody =>
      'Your stay has ended, so this room key no longer works.';

  @override
  String get accessFailedTitle => 'Room key unavailable';

  @override
  String get accessUnavailableTitle => 'Access is unavailable';

  @override
  String get accessBackToReservation => 'Back to reservation';

  @override
  String get accessStatusNotIssued => 'Not issued';

  @override
  String get accessStatusIssueRequested => 'Issuing';

  @override
  String get accessStatusActive => 'Active';

  @override
  String get accessStatusFailed => 'Failed';

  @override
  String get accessStatusRevokeRequested => 'Deactivating';

  @override
  String get accessStatusRevoked => 'Deactivated';

  @override
  String get accessStatusExpired => 'Expired';

  @override
  String get servicesTitle => 'Hotel services';

  @override
  String get servicesIntroBanner =>
      'Order what you need from your room. Requests go straight to reception.';

  @override
  String get servicesEmptyTitle => 'No services available';

  @override
  String get servicesEmptyBody =>
      'This hotel hasn\'t published any services yet.';

  @override
  String get servicesUnavailableTitle => 'Services are unavailable';

  @override
  String get serviceUncategorised => 'Other services';

  @override
  String get serviceFreeLabel => 'Included';

  @override
  String serviceEstimatedMinutes(int count) {
    return '~$count min';
  }

  @override
  String get serviceDetailTitle => 'Service';

  @override
  String get serviceQuantityLabel => 'Quantity';

  @override
  String get serviceNotesLabel => 'Notes (optional)';

  @override
  String get serviceNotesHint => 'Anything the team should know';

  @override
  String get serviceRequestCta => 'Request this service';

  @override
  String get serviceRequestingCta => 'Sending…';

  @override
  String get serviceEstimatedTotalLabel => 'Estimated total';

  @override
  String get serviceChargeNote =>
      'Any charge is added to your room account and settled at checkout.';

  @override
  String get serviceRequestFailedTitle => 'We couldn\'t send your request';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get myRequestsIntroBanner =>
      'Track each request. You can cancel one before the team starts it.';

  @override
  String get myRequestsEmptyTitle => 'No requests yet';

  @override
  String get myRequestsEmptyBody =>
      'Request a service and it will show up here.';

  @override
  String get newRequestCta => 'New request';

  @override
  String get serviceOrderDetailTitle => 'Request details';

  @override
  String get serviceOrderRequestedAtLabel => 'Requested';

  @override
  String get serviceOrderConfirmedAtLabel => 'Accepted';

  @override
  String get serviceCancelCta => 'Cancel request';

  @override
  String get serviceCancelConfirmTitle => 'Cancel this request?';

  @override
  String get serviceCancelConfirmBody =>
      'The team hasn\'t started this yet, so it can still be cancelled.';

  @override
  String serviceCancelConfirmTitleFor(String service) {
    return 'Cancel the $service request?';
  }

  @override
  String get serviceCancelInProgressBody =>
      'This request is already being handled. Cancelling now may not stop the team if they\'re on the way to your room.';

  @override
  String get serviceCancelConfirmCta => 'Confirm cancellation';

  @override
  String get serviceCancelKeepCta => 'Keep request';

  @override
  String get serviceCancelNotAllowed =>
      'This request can no longer be cancelled.';

  @override
  String get serviceContactReception => 'Contact reception';

  @override
  String get serviceContactReceptionHint =>
      'Call reception from your room phone or the front desk for help with this request.';

  @override
  String get serviceStatusRequested => 'Pending';

  @override
  String get serviceStatusConfirmed => 'Accepted';

  @override
  String get serviceStatusFulfilled => 'Completed';

  @override
  String get serviceStatusCancelled => 'Cancelled';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutProcessingTitle => 'Completing checkout';

  @override
  String get checkoutCompleteTitle => 'Your stay summary';

  @override
  String get invoiceTitle => 'Invoice';

  @override
  String get checkoutReadyTitle => 'Ready to check out';

  @override
  String get checkoutReadyBody => 'No pending tasks.';

  @override
  String get checkoutNotReadyTitle => 'Checkout isn\'t available yet';

  @override
  String get checkoutNotReadyBody =>
      'You can check out once your stay has started.';

  @override
  String get checkoutUnavailableTitle => 'Checkout is unavailable';

  @override
  String get folioSummaryTitle => 'Charge summary';

  @override
  String get folioAccommodationLine => 'Accommodation';

  @override
  String get folioServiceLine => 'Service charge';

  @override
  String get folioTotalLabel => 'Total';

  @override
  String get folioPaidLabel => 'Already paid';

  @override
  String get folioOutstandingLabel => 'Amount due now';

  @override
  String get checkoutSettleNote =>
      'The amount due is charged in one payment to your card on file. Your invoice is sent electronically.';

  @override
  String get checkoutCompleteCta => 'Complete checkout';

  @override
  String get checkoutProcessingBody => 'Settling your account…';

  @override
  String get checkoutDoNotClose => 'Please keep this screen open.';

  @override
  String get checkoutDoneTitle => 'Thank you for your stay';

  @override
  String get checkoutDoneBody =>
      'Your account is settled and your invoice is ready.';

  @override
  String get checkoutPendingTitle => 'Settlement is processing';

  @override
  String get checkoutPendingBody =>
      'Your bank hasn\'t confirmed the payment yet. Check the status again shortly.';

  @override
  String get checkoutFailedTitle => 'Settlement didn\'t complete';

  @override
  String get checkoutFailedBody => 'No money was taken. You can try again.';

  @override
  String get checkoutRetryCta => 'Try again';

  @override
  String get checkoutViewInvoiceCta => 'View invoice';

  @override
  String get checkoutDoneCta => 'Done';

  @override
  String get checkoutStatusInProgress => 'In progress';

  @override
  String get checkoutStatusAwaitingSettlement => 'Awaiting settlement';

  @override
  String get checkoutStatusSettlementFailed => 'Settlement failed';

  @override
  String get checkoutStatusCompleted => 'Completed';

  @override
  String get invoiceIssuedBannerTitle => 'Your e-invoice was issued';

  @override
  String get invoiceIssuedBannerBody =>
      'It was sent to your email and is always saved here — no paper invoice.';

  @override
  String get invoiceNumberLabel => 'Invoice number';

  @override
  String get invoiceIssuedLabel => 'Issued';

  @override
  String get invoiceItemsTitle => 'Items';

  @override
  String get invoiceSubtotalLabel => 'Subtotal';

  @override
  String get invoicePaymentsLabel => 'Payments';

  @override
  String get invoiceOutstandingLabel => 'Outstanding';

  @override
  String get invoiceSettledTag => 'Settled in full';

  @override
  String get invoiceNotReadyTitle => 'No invoice yet';

  @override
  String get invoiceNotReadyBody =>
      'Your invoice will be here once you check out.';

  @override
  String get invoiceUnavailableTitle => 'Invoice is unavailable';

  @override
  String get reservationLoyaltyCta => 'Loyalty & points';

  @override
  String get reservationReviewCta => 'Leave a review';

  @override
  String get reservationViewReviewCta => 'View your review';

  @override
  String get loyaltyTitle => 'Loyalty';

  @override
  String get loyaltyUnavailableTitle => 'Loyalty is unavailable';

  @override
  String get loyaltyBalanceLabel => 'Points balance';

  @override
  String loyaltyPointsValue(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pts',
      one: '1 pt',
    );
    return '$_temp0';
  }

  @override
  String get loyaltyGroupWideNote =>
      'Your points work across every hotel in the group.';

  @override
  String get loyaltyProgramOffTitle => 'The loyalty programme isn\'t active';

  @override
  String get loyaltyProgramOffBody =>
      'This hotel group hasn\'t switched on points earning yet. There\'s nothing to do here for now.';

  @override
  String get loyaltyAlreadyEarnedTitle => 'Points already added';

  @override
  String get loyaltyAlreadyEarnedBody =>
      'You\'ve already earned points for this stay.';

  @override
  String get loyaltyHistoryTitle => 'Points history';

  @override
  String get loyaltyHistoryNote =>
      'Your full points ledger is kept by the hotel group. This is a read-only copy.';

  @override
  String get loyaltyHistoryEmptyTitle => 'No points activity yet';

  @override
  String get loyaltyHistoryEmptyBody =>
      'Points you earn and redeem will show up here.';

  @override
  String loyaltyPointsAdded(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points pts',
      one: '+1 pt',
    );
    return '$_temp0';
  }

  @override
  String loyaltyPointsRemoved(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '-$points pts',
      one: '-1 pt',
    );
    return '$_temp0';
  }

  @override
  String get loyaltyTxThisStay => 'This stay';

  @override
  String get loyaltyTxEarnLabel => 'Earned';

  @override
  String get loyaltyTxRedeemLabel => 'Redeemed';

  @override
  String get loyaltyTxReverseLabel => 'Reversed';

  @override
  String get loyaltyTxAdjustLabel => 'Adjustment';

  @override
  String get loyaltyTxExpireLabel => 'Expired';

  @override
  String get loyaltyRedeemCta => 'Redeem points';

  @override
  String get loyaltyRedeemTitle => 'Redeem points';

  @override
  String get loyaltyRedeemSubmitCta => 'Redeem';

  @override
  String get loyaltyRedeemingCta => 'Redeeming…';

  @override
  String get loyaltyRedeemAmountLabel => 'Points to redeem';

  @override
  String get loyaltyRedeemNote =>
      'Points are redeemed against this booking. The hotel group confirms the final value.';

  @override
  String loyaltyRedeemMax(int points) {
    return 'Use max ($points)';
  }

  @override
  String get loyaltyRedeemedTitle => 'Points redeemed';

  @override
  String loyaltyRedeemedBody(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points were redeemed against this booking.',
      one: '1 point was redeemed against this booking.',
    );
    return '$_temp0';
  }

  @override
  String loyaltyRedeemedValueNote(String value, String currency) {
    return 'That\'s about $value $currency off this booking.';
  }

  @override
  String get loyaltyRedeemNotEligibleTitle => 'Can\'t redeem on this booking';

  @override
  String get loyaltyRedeemNotEligibleBody =>
      'Points can only be redeemed against an active booking.';

  @override
  String get loyaltyAlreadyRedeemedTitle => 'Already redeemed';

  @override
  String get loyaltyAlreadyRedeemedBody =>
      'Points were already redeemed against this booking.';

  @override
  String get loyaltyAlreadyRedeemedDifferentBody =>
      'A different number of points was already redeemed against this booking.';

  @override
  String get loyaltyInsufficientTitle => 'Not enough points';

  @override
  String get loyaltyInsufficientBody =>
      'You don\'t have enough points for that amount.';

  @override
  String get loyaltyInvalidAmountBody => 'Choose how many points to redeem.';

  @override
  String get reviewFormTitle => 'Leave a review';

  @override
  String get reviewFormPrompt => 'How was your stay?';

  @override
  String get reviewResultTitle => 'Your review';

  @override
  String get reviewProcessingTitle => 'Sending your review';

  @override
  String get reviewProcessingBody => 'Sending your review…';

  @override
  String get reviewDoNotClose =>
      'This only takes a moment. Please don\'t close the app.';

  @override
  String get reviewRatingRequired => 'Choose a rating from 1 to 5 stars.';

  @override
  String reviewStarsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get reviewCategoriesHeading => 'Rate the details of your stay';

  @override
  String get reviewCategoriesHint =>
      'Optional — rate the ones that matter to you.';

  @override
  String get reviewTextLabel => 'Your review (optional)';

  @override
  String get reviewTextHint => 'Tell other guests about your stay';

  @override
  String get reviewSubmitCta => 'Submit review';

  @override
  String get reviewSubmittingCta => 'Submitting…';

  @override
  String get reviewYourRatingLabel => 'Your rating';

  @override
  String get reviewBackToReservation => 'Back to reservation';

  @override
  String get reviewUnavailableTitle => 'Reviews are unavailable';

  @override
  String get reviewNotEligibleTitle => 'You can\'t review this stay';

  @override
  String get reviewNotEligibleBody =>
      'Reviews open once your stay is completed.';

  @override
  String get reviewSubmittedTitle => 'Thanks for your review';

  @override
  String get reviewPublishedBody => 'Your review has been posted.';

  @override
  String get reviewPendingModerationBody =>
      'Your review was received and is with our team for a quick check before it\'s published.';

  @override
  String get reviewAlreadyTitle => 'You\'ve already reviewed this stay';

  @override
  String get reviewAlreadyBody =>
      'Only one review per stay. Your existing review is shown below.';

  @override
  String get reviewRejectedTitle => 'This review wasn\'t published';

  @override
  String get reviewRejectedBody =>
      'Your review didn\'t pass our check and wasn\'t published.';

  @override
  String get reviewInvalidRatingTitle => 'Rating out of range';

  @override
  String get reviewInvalidRatingBody =>
      'A rating must be between 1 and 5 stars.';

  @override
  String get reviewFailedTitle => 'We couldn\'t send your review';

  @override
  String get reviewStatusPending => 'Pending review';

  @override
  String get reviewStatusPublished => 'Published';

  @override
  String get reviewStatusRejected => 'Not published';

  @override
  String get serviceReviewFormTitle => 'Rate this service';

  @override
  String get serviceReviewFormPrompt => 'How was this service?';

  @override
  String get serviceReviewResultTitle => 'Your service review';

  @override
  String get serviceReviewNotEligibleTitle =>
      'You can\'t review this service yet';

  @override
  String get serviceReviewNotEligibleBody =>
      'Reviews open once the service has been fulfilled.';

  @override
  String get serviceReviewTextHint => 'Tell other guests about this service';

  @override
  String hotelDetailStarRating(int count) {
    return '$count-star hotel';
  }

  @override
  String get hotelDetailReviewsHeading => 'Ratings & reviews';

  @override
  String get hotelInfoRoomTypesLabel => 'Room types';

  @override
  String get hotelInfoCountryLabel => 'Country';

  @override
  String get hotelInfoGuestsLabel => 'Guests';

  @override
  String get hotelInfoClassificationLabel => 'Classification';

  @override
  String get hotelInfoCheckInLabel => 'Check-in';

  @override
  String get hotelInfoCheckOutLabel => 'Check-out';

  @override
  String hotelTimeOfDay(String time, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'am': 'AM',
      'noon': 'PM',
      'other': 'PM',
    });
    return '$time $_temp0';
  }

  @override
  String get hotelInfoRoomsLabel => 'Rooms';

  @override
  String hotelRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
    );
    return '$_temp0';
  }

  @override
  String get hotelInfoSuitableForLabel => 'Suitable for';

  @override
  String get hotelLocationHeading => 'Location';

  @override
  String get hotelShare => 'Share';

  @override
  String get hotelShareCopied => 'Hotel details copied';

  @override
  String get hotelFavoriteAdd => 'Add to favourites';

  @override
  String get hotelFavoriteRemove => 'Remove from favourites';

  @override
  String get favoritesTitle => 'Favourites';

  @override
  String get favoritesBannerTitle => 'Your saved hotels';

  @override
  String get favoritesBannerBody =>
      'Hotels you heart appear here. Tap one to open it, or the heart to remove it.';

  @override
  String get favoritesEmptyTitle => 'No favourite hotels yet';

  @override
  String get favoritesEmptyBody =>
      'Tap the heart on any hotel or room to save its hotel here.';

  @override
  String get favoritesBrowse => 'Browse hotels';

  @override
  String get favoritesHotelUnavailable =>
      'This hotel is not available right now';

  @override
  String get favoriteSavedSnack => 'Hotel saved to favourites';

  @override
  String get favoriteRemovedSnack => 'Hotel removed from favourites';

  @override
  String get favoriteViewAction => 'View';

  @override
  String get favoriteUndoAction => 'Undo';

  @override
  String get hotelLocationMapSemantics => 'Hotel location on the map';

  @override
  String get hotelLocationMapOpenHint => 'Tap to open the full map';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String hotelNearbyPlace(String place, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$place $_temp0';
  }

  @override
  String hotelNearbyPlaceKm(String place, String distance) {
    return '$place $distance km';
  }

  @override
  String hotelNearbyPlaceMeters(String place, String distance) {
    return '$place $distance m';
  }

  @override
  String get hotelWhyChooseHeading => 'Why choose this hotel?';

  @override
  String get hotelDetailAmenitiesSubtitle =>
      'Services designed for guests\' comfort around the clock';

  @override
  String get hotelRoomsHeading => 'Available rooms';

  @override
  String get hotelRoomsSubtitle =>
      'Pick the right room for your trip and enjoy a refined stay';

  @override
  String get hotelRoomsCta => 'View available rooms';

  @override
  String get hotelReviewsSubtitle =>
      'Guest ratings reflect the quality of service and comfort during the stay';

  @override
  String get hotelOverallRating => 'Overall rating';

  @override
  String get hotelPriceFromLabel => 'From';

  @override
  String get roomSpecArea => 'Room size';

  @override
  String get roomSpecGuests => 'Guests';

  @override
  String get roomSpecBed => 'Bed type';

  @override
  String get roomSpecView => 'View';

  @override
  String get roomBookingDetailsHeading => 'Your booking details';

  @override
  String get roomStayDuration => 'Duration';

  @override
  String get roomStayDates => 'Dates';

  @override
  String get roomStayGuests => 'Guests';

  @override
  String get roomNightlyPriceLabel => 'Room rate';

  @override
  String get roomTotalLabel => 'Total';

  @override
  String get roomIncludedHeading => 'The price includes';

  @override
  String get roomAboutHeading => 'About the room';

  @override
  String get roomPoliciesHeading => 'Policies';

  @override
  String get roomCurrentPrice => 'Current price';

  @override
  String get commonShowMore => 'Show more';

  @override
  String get commonShowLess => 'Show less';

  @override
  String get bookingsPillCurrent => 'Current';

  @override
  String get bookingsPillUpcoming => 'Upcoming';

  @override
  String get bookingsPillPast => 'Past';

  @override
  String get bookingsPastTitle => 'Past stays';

  @override
  String get bookingsSectionOngoingStay => 'Ongoing stay';

  @override
  String get bookingsSectionUpcoming => 'Upcoming bookings';

  @override
  String get bookingsEmptyTitle => 'No bookings yet';

  @override
  String get bookingsEmptyBody =>
      'Your bookings will appear here once you make one.';

  @override
  String get bookingStatusPending => 'Awaiting payment';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCheckedIn => 'Checked in';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingDetailTitle => 'Booking details';

  @override
  String get bookingPaymentStatusHeading => 'Payment status';

  @override
  String get bookingCancellationPolicyHeading => 'Cancellation policy';

  @override
  String get bookingCancellationPolicyBody =>
      'Free cancellation up to 24 hours before arrival. After that, the deposit is deducted.';

  @override
  String get bookingPendingRowTitle => 'Awaiting payment';

  @override
  String get bookingPendingRowSubtitle => 'Not completed';

  @override
  String get bookingAutoCancelRowTitle =>
      'The booking auto-cancels in 30 minutes';

  @override
  String get bookingRoomHeldRowTitle => 'The room is held temporarily';

  @override
  String get bookingRoomHeldRowSubtitle => 'Not confirmed';

  @override
  String get bookingDepositHeldRowTitle => 'The deposit has been held';

  @override
  String get bookingDepositHeldRowSubtitle => 'No charge has been made yet';

  @override
  String get bookingDeductedAtCheckinRowTitle => 'Deducted at check-in';

  @override
  String get bookingExtrasChargedOnceRowTitle =>
      'Extra charges are collected on departure';

  @override
  String get bookingExtrasChargedOnceRowSubtitle => 'As a single payment';

  @override
  String get bookingIdentityVerifiedRowTitle =>
      'Your identity has been verified';

  @override
  String get bookingIdentityVerifiedRowSubtitle => 'Complete';

  @override
  String get bookingCheckInAvailableRowTitle => 'Check-in available from';

  @override
  String get bookingDepositAmountHeldRowTitle => 'Deposit amount held';

  @override
  String get bookingOngoingStayRowTitle => 'Ongoing stay';

  @override
  String bookingRoomLabel(String number) {
    return 'Room $number';
  }

  @override
  String get bookingDepartureRowTitle => 'Departure';

  @override
  String get bookingExtraChargesRowTitle => 'Extra charges';

  @override
  String get bookingCancelledRowTitle => 'Booking cancelled';

  @override
  String get bookingDepositRefundRowTitle => 'Deposit refund';

  @override
  String get bookingDepositRefundRowSubtitle => 'Within 3 business days';

  @override
  String get bookingCancellationFeeRowTitle => 'Cancellation fee';

  @override
  String get bookingCancellationFeeNone => 'None';

  @override
  String get bookingDepositNotRefunded => 'Non-refundable rate — no refund';

  @override
  String get bookingStayEndedRowTitle => 'Stay ended';

  @override
  String get bookingTotalPaidRowTitle => 'Total paid';

  @override
  String get bookingInvoiceReadyRowTitle => 'E-invoice';

  @override
  String get bookingInvoiceReadyRowSubtitle => 'Ready';

  @override
  String get bookingCtaContinuePayment => 'Continue payment';

  @override
  String get bookingCtaCancelReservation => 'Cancel booking';

  @override
  String get bookingCtaVerifyIdentity => 'Verify identity';

  @override
  String get bookingCtaDigitalCheckIn => 'Digital check-in';

  @override
  String get bookingCtaMyCurrentStay => 'My current stay';

  @override
  String get bookingCtaShowAccessCode => 'Show access code';

  @override
  String get bookingCtaBookAgain => 'Book again';

  @override
  String get bookingCtaViewInvoice => 'View invoice';

  @override
  String get bookingCancelConfirmTitle => 'Cancel this booking?';

  @override
  String get bookingCancelFullRefundBody =>
      'Cancellation is free and your full deposit will be released.';

  @override
  String get bookingCancelNoRefundBody =>
      'The deposit is not refunded if you cancel this booking.';

  @override
  String policyFreeUntil(String date) {
    return 'Free cancellation with a full refund until $date. After that it cannot be cancelled.';
  }

  @override
  String get policyWindowClosed =>
      'The free cancellation window has closed; this booking can no longer be cancelled.';

  @override
  String get policyNonRefundable =>
      'This rate is non-refundable and cannot be cancelled.';

  @override
  String get policyStayStarted =>
      'A booking cannot be cancelled once the stay has started.';

  @override
  String policyGeneral(int hours) {
    return 'Refundable rates can be cancelled free, with a full refund, within $hours hours of booking or until check-in if that is sooner. After that they cannot be cancelled. Non-refundable rates cannot be cancelled.';
  }

  @override
  String get cancelNotAllowedError =>
      'This booking can no longer be cancelled under its cancellation policy.';

  @override
  String get cancelRefundFailedError =>
      'The deposit couldn\'t be released right now, so the booking wasn\'t cancelled. Please try again.';

  @override
  String get bookingCancelConfirmBody =>
      'This can\'t be undone. Any deposit will be refunded per the cancellation policy.';

  @override
  String get bookingCancelKeepCta => 'Go back';

  @override
  String get bookingCancelConfirmCta => 'Confirm cancellation';

  @override
  String get bookingNotFoundTitle => 'Booking not found';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountPrivacyNoteBody =>
      'Your ID photos are stored securely and deleted automatically after your stay.';

  @override
  String get profilePersonalInfoTitle => 'My details';

  @override
  String get profilePersonalInfoBannerTitle => 'Your personal details';

  @override
  String get profilePersonalInfoBannerBody =>
      'Used for your bookings and invoices. To change your name or ID number, contact reception.';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profilePhoneLabel => 'Mobile number';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailAdd => 'Add';

  @override
  String get profileVerifiedIdentityLabel => 'Verified identity';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileNotVerified => 'Not verified yet';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileSave => 'Save';

  @override
  String get profileDone => 'Done';

  @override
  String get profileSaved => 'Your changes were saved.';

  @override
  String get profilePreferencesTitle => 'My preferences';

  @override
  String get profilePreferencesBannerTitle => 'Stay preferences';

  @override
  String get profilePreferencesBannerBody =>
      'We use these to prepare your room ahead of time at every hotel in the group.';

  @override
  String get profilePrefRoomType => 'Room type';

  @override
  String get profilePrefHighFloor => 'High floor';

  @override
  String get profilePrefExtraPillows => 'Extra pillows';

  @override
  String get profilePrefLanguage => 'App language';

  @override
  String get profilePrefNotifications => 'Notifications';

  @override
  String get profilePrefOn => 'On';

  @override
  String get profilePrefOff => 'Off';

  @override
  String get profilePrefOnFeminine => 'On';

  @override
  String get profilePrefOffFeminine => 'Off';

  @override
  String get profilePrivacyBannerTitle => 'How we use your data';

  @override
  String get profilePrivacyBannerBody =>
      'Your ID photos are stored encrypted and deleted automatically after your stay. They are never shared with third parties.';

  @override
  String get profilePrivacyIdPhotos => 'ID photos';

  @override
  String get profilePrivacyIdPhotosValue => 'Deleted after departure';

  @override
  String get profileIdentityDeleteAfterCheckout =>
      'Delete my ID photos after checkout (default)';

  @override
  String get profileIdentityKeepForFuture => 'Keep them for my future bookings';

  @override
  String get profileIdentityKeptValue => 'Kept for future bookings';

  @override
  String profileIdentityHotelCopyNote(int days) {
    return 'The hotel keeps the stay\'s ID copy for $days days after checkout, then it is deleted automatically.';
  }

  @override
  String get profilePrivacyPaymentData => 'Payment details';

  @override
  String get profilePrivacyPaymentDataValue => 'Not stored';

  @override
  String get profilePrivacyStayHistory => 'Stay history';

  @override
  String get profileRequestDeletion => 'Request data deletion';

  @override
  String get profileDeletionConfirmTitle => 'Delete your personal data?';

  @override
  String get profileDeletionConfirmBody =>
      'Your request goes to the hotel team, who will contact you to complete it. It does not cancel your current bookings.';

  @override
  String get profileDeletionConfirmCta => 'Send request';

  @override
  String get profileDeletionRequestedTitle =>
      'Your deletion request was received';

  @override
  String profileDeletionRequestedBody(String date) {
    return 'You sent the request on $date. The hotel team will contact you to complete it.';
  }

  @override
  String get profileDeletionRequestedCta => 'Request sent';

  @override
  String get profileSupportTitle => 'Help';

  @override
  String get profileSupportBannerTitle => 'How can we help?';

  @override
  String get profileSupportBannerBody =>
      'Support is available around the clock, and you can contact your hotel directly.';

  @override
  String get profileFaq => 'FAQ';

  @override
  String get profileFaqEmptyTitle => 'No FAQ yet';

  @override
  String get profileFaqEmptyBody =>
      'Contact your hotel directly with any question.';

  @override
  String get profileDuringStayOnly => 'Available during a stay';

  @override
  String get profileContactReceptionNoStay => 'Available with a booking';

  @override
  String get profileLogoutConfirmTitle => 'Sign out of your account?';

  @override
  String get profileLogoutConfirmBody =>
      'You\'ll need a new verification code to sign in again. Your bookings and current stay aren\'t affected.';

  @override
  String get accountLoyaltyProgramTitle => 'Loyalty program';

  @override
  String get accountLoyaltyPointsSuffix => 'points';

  @override
  String get accountLoyaltyDescription =>
      'Your points build up across every hotel in the group and can be redeemed at any branch.';

  @override
  String get accountLoyaltyPerNightLabel => 'Per night';

  @override
  String get accountTrustedGuestTitle => 'Trusted guest';

  @override
  String get accountTrustedGuestBody =>
      'You won\'t be asked to re-upload your ID at any other hotel in the group.';

  @override
  String get accountPreviousStaysLabel => 'Previous stays';

  @override
  String get accountPreferencesLabel => 'My preferences';

  @override
  String get accountPreferencesEmpty => 'Not set yet';

  @override
  String get accountPrivacyLabel => 'Privacy & data';

  @override
  String get accountHelpSupportLabel => 'Help & support';

  @override
  String get stayHomeTitle => 'Your current stay';

  @override
  String get stayHomeRoomLabel => 'Your room';

  @override
  String stayHomeHotelUntil(String hotel, String date) {
    return '$hotel · until $date';
  }

  @override
  String bookingRoomNumber(String number) {
    return 'Room $number';
  }

  @override
  String get stayHomeServicesHeading => 'Services';

  @override
  String get stayHomeRoomService => 'Room service';

  @override
  String get stayHomeRoomCleaning => 'Room cleaning';

  @override
  String get stayHomeExtendStay => 'Extend stay';

  @override
  String get stayHomeReportProblem => 'Report a problem';

  @override
  String get stayHomeExtraCharges => 'Extra charges';

  @override
  String get stayHomeExtraChargesNote => 'Deducted automatically on departure';

  @override
  String get stayHomeNoActiveStayTitle => 'No active stay';

  @override
  String get stayHomeNoActiveStayBody =>
      'Once you check in, your room, key and services will show up here.';

  @override
  String get guestSignInRequiredTitle => 'Sign in to continue';

  @override
  String get guestSignInBookingsBody =>
      'Sign in to see and manage your bookings.';

  @override
  String get guestSignInServicesBody =>
      'Sign in to reach your stay\'s services, room key and requests.';

  @override
  String get guestSignInAction => 'Sign in';

  @override
  String get extendStayTitle => 'Extend stay';

  @override
  String get extendStayNewCheckOutLabel => 'New checkout date';

  @override
  String get extendStayNightsAddedLabel => 'Nights added';

  @override
  String get extendStayCta => 'Confirm extension';

  @override
  String get extendStaySuccessTitle => 'Stay extended';

  @override
  String extendStaySuccessBody(String date, String amount) {
    return 'Your checkout date is now $date. $amount has been added to your folio.';
  }

  @override
  String get extendStayNotEligible =>
      'Extend stay is only available during your current stay.';

  @override
  String get reportProblemTitle => 'Report a problem';

  @override
  String get reportProblemCategoryHeading => 'What\'s the issue?';

  @override
  String get reportProblemCategoryBody =>
      'Choose the closest category so your report reaches the right team directly.';

  @override
  String get reportCategoryAcHeating => 'AC or heating';

  @override
  String get reportCategoryPlumbingWater => 'Plumbing or water';

  @override
  String get reportCategoryElectricityLighting => 'Electricity and lighting';

  @override
  String get reportCategoryRoomCleanliness => 'Room cleanliness';

  @override
  String get reportCategoryInternetWifi => 'Internet and Wi-Fi';

  @override
  String get reportCategoryNoiseDisturbance => 'Noise or disturbance';

  @override
  String get reportProblemContinueCta => 'Continue';

  @override
  String get reportDescriptionTitle => 'Problem description';

  @override
  String get reportUrgencyHeading => 'How urgent is this?';

  @override
  String get reportUrgencyNormal => 'Normal';

  @override
  String get reportUrgencyImportant => 'Important';

  @override
  String get reportUrgencyUrgent => 'Urgent';

  @override
  String get reportNotesLabel => 'Notes (optional)';

  @override
  String get reportNotesHint =>
      'Add any details that help our team respond faster';

  @override
  String get reportNoFeeTitle => 'No fees';

  @override
  String get reportNoFeeBody =>
      'Reporting a problem is free and will never be added to your bill.';

  @override
  String get reportSubmitCta => 'Submit report';

  @override
  String get reportSubmittingCta => 'Submitting…';

  @override
  String get reportFailedTitle => 'We couldn\'t send your report';

  @override
  String get reportSubmittedTitle => 'Submitted';

  @override
  String get reportSubmittedBannerTitle => 'Your report reached reception';

  @override
  String reportSubmittedBannerBody(String reference) {
    return 'Report $reference. Our reception team will be in touch shortly, and you can track its status anytime.';
  }

  @override
  String get reportTrackCta => 'Track report';

  @override
  String get reportDetailTitle => 'Report details';

  @override
  String get reportDetailBody =>
      'Your report has been received and our team is on it.';

  @override
  String get reportContactReceptionCta => 'Contact reception';

  @override
  String get reportStatusOpen => 'Open';

  @override
  String get reportStatusInProgress => 'In progress';

  @override
  String get reportStatusResolved => 'Resolved';

  @override
  String get reportUnavailableTitle => 'Reports are unavailable';

  @override
  String get reportNotFoundTitle => 'Report not found';

  @override
  String get myReportsTitle => 'My reports';

  @override
  String get myReportsIntroBanner =>
      'Track the status of every problem you\'ve reported.';

  @override
  String get myReportsEmptyTitle => 'No reports yet';

  @override
  String get myReportsEmptyBody => 'Report a problem and it will show up here.';

  @override
  String get newReportCta => 'New report';

  @override
  String get bookingLoyaltyWorth => 'Worth';

  @override
  String get bookingLoyaltyRedeem => 'Redeem';

  @override
  String get bookingLoyaltyPointsField => 'Points';

  @override
  String get bookingLoyaltyPointsHint => 'Enter points';

  @override
  String get bookingLoyaltyDiscountField => 'Discount';

  @override
  String get bookingLoyaltyApply => 'Apply';

  @override
  String get bookingLoyaltyRemove => 'Remove';

  @override
  String bookingLoyaltyMaxHint(String points) {
    return 'Up to $points points on this booking';
  }

  @override
  String get bookingLoyaltyAppliedNote =>
      'Redeemed when you confirm the booking';

  @override
  String get bookingLoyaltyDisabled => 'Points redemption isn\'t available yet';

  @override
  String get bookingLoyaltyNoPoints => 'You have no points to redeem yet';

  @override
  String get bookingLoyaltyDiscountRow => 'Points discount';

  @override
  String get bookingLoyaltyRedeemFailed =>
      'Your points couldn\'t be redeemed — nothing was deducted.';

  @override
  String get loyaltyAutoEarnTitle => 'Points on the way';

  @override
  String get loyaltyAutoEarnBody =>
      'Points for this stay are added to your balance automatically once it\'s complete.';

  @override
  String bookingCheckInFrom(String time) {
    return 'From $time';
  }

  @override
  String roomPolicyCheckInBody(String time) {
    return 'From $time';
  }

  @override
  String roomPolicyCheckOutBody(String time) {
    return 'Until $time';
  }

  @override
  String get roomTaxesLabel => 'Taxes & fees';

  @override
  String get roomPriceIncludedValue => 'Included';

  @override
  String get roomFinalPriceNote => 'Final price — no extra fees';

  @override
  String get roomPolicyCheckInTitle => 'Check-in';

  @override
  String get roomPolicyCheckOutTitle => 'Check-out';

  @override
  String roomMaxAdultsReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This room takes at most $count adults',
      one: 'This room takes at most 1 adult',
    );
    return '$_temp0';
  }

  @override
  String roomMaxGuestsReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This room takes at most $count guests',
      one: 'This room takes at most 1 guest',
    );
    return '$_temp0';
  }
}
