// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'فندق سيستم';

  @override
  String get appTagline => 'احجز، تحقّق، وادخل غرفتك من هاتفك.';

  @override
  String get foundationScreenTitle => 'الأساس ونظام التصميم';

  @override
  String get foundationScreenSubtitle =>
      'المرحلة صفر من التطبيق — بنية المشروع، السمة، الترجمة، وطبقة البيانات فقط. شاشات الميزات تأتي في المراحل التالية.';

  @override
  String get sectionLanguage => 'اللغة';

  @override
  String get sectionTheme => 'المظهر';

  @override
  String get sectionBackendStatus => 'الاتصال بالخادم';

  @override
  String get sectionComponents => 'مكوّنات نظام التصميم';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String environmentLabel(String name) {
    return 'البيئة: $name';
  }

  @override
  String apiBaseUrlLabel(String url) {
    return 'عنوان الـ API: $url';
  }

  @override
  String get backendStatusOk => 'متصل';

  @override
  String get backendStatusDegraded => 'متذبذب';

  @override
  String get backendStatusDown => 'غير متصل';

  @override
  String backendStatusCheckedAt(String time) {
    return 'آخر فحص: $time';
  }

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionCheckAgain => 'افحص مجددًا';

  @override
  String get actionPrimaryExample => 'إجراء رئيسي';

  @override
  String get actionSecondaryExample => 'إجراء ثانوي';

  @override
  String get stateLoadingTitle => 'جارٍ التحميل…';

  @override
  String get stateEmptyTitle => 'لا يوجد شيء بعد';

  @override
  String get stateEmptySubtitle => 'عند توفّر بيانات لعرضها ستظهر هنا.';

  @override
  String get stateErrorTitle => 'حدث خطأ ما';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String notificationsUnreadTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لديك $count إشعار جديد',
      many: 'لديك $count إشعاراً جديداً',
      few: 'لديك $count إشعارات جديدة',
      two: 'لديك إشعاران جديدان',
      one: 'لديك إشعار جديد',
    );
    return '$_temp0';
  }

  @override
  String get notificationsAllReadTitle => 'لا توجد إشعارات جديدة';

  @override
  String get notificationsBannerBody =>
      'اضغط أي إشعار للانتقال مباشرة إلى موضوعه.';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات بعد';

  @override
  String get notificationsEmptyBody => 'ستظهر هنا تحديثات حجوزاتك وإقامتك.';

  @override
  String get notificationsNow => 'الآن';

  @override
  String get notificationsYesterday => 'أمس';

  @override
  String get notificationsUnreadLabel => 'غير مقروء';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationsOpenTooltip => 'الإشعارات';

  @override
  String get errorGeneric => 'تعذّر إكمال الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get errorNetwork =>
      'يبدو أنك غير متصل بالإنترنت. تحقّق من الاتصال وحاول مجددًا.';

  @override
  String get errorTimeout =>
      'استغرق الطلب وقتًا طويلًا. يرجى المحاولة مرة أخرى.';

  @override
  String get errorUnauthorized => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorServer => 'الخدمة غير متاحة مؤقتًا. يرجى المحاولة لاحقًا.';

  @override
  String get errorNotImplemented =>
      'هذه الميزة غير متاحة بعد. يرجى المحاولة لاحقًا.';

  @override
  String get textFieldExampleLabel => 'الاسم الكامل';

  @override
  String get textFieldExampleHint => 'أدخل اسمك';

  @override
  String get brandWordmark => 'Hotel System';

  @override
  String get entryHeadline => 'استكشف فنادقنا واحجز إقامتك من مكانك';

  @override
  String get entrySubtext => 'ببساطة اختر غرفتك المفضلة في وقتك المفضل';

  @override
  String get entryStartAction => 'ابدأ الآن';

  @override
  String get entryLanguageSwitchLabel => 'اللغة';

  @override
  String get languageScreenHeading => 'اختر لغة التطبيق';

  @override
  String get authPhoneTitle => 'تسجيل الدخول';

  @override
  String get authPhoneHeading => 'أدخل رقم جوالك';

  @override
  String get authPhoneBody =>
      'نحتاجه لتأكيد حجزك وإرسال رمز دخول غرفتك. لن نستخدمه لأي شيء آخر.';

  @override
  String get authPhoneFieldLabel => 'رقم الجوال';

  @override
  String get authPhoneFieldHint => '05 1234 5678';

  @override
  String get authPhoneHelper => 'سنرسل رمز تحقق على هذا الرقم';

  @override
  String get authPhoneTerms =>
      'بالمتابعة أنت توافق على الشروط وسياسة الخصوصية.';

  @override
  String get authPhoneSubmit => 'إرسال رمز التحقق';

  @override
  String get authPhoneEmpty => 'رقم الجوال مطلوب';

  @override
  String get authPhoneInvalid =>
      'أدخل رقم جوال سعودي يبدأ بـ 05 ويتكون من 10 أرقام';

  @override
  String get authOtpTitle => 'رمز التحقق';

  @override
  String get authOtpHeading => 'أدخل الرمز المرسل';

  @override
  String get authOtpChange => 'تغيير';

  @override
  String authOtpResendCountdown(String time) {
    return 'إعادة الإرسال خلال $time';
  }

  @override
  String get authOtpResendAction => 'إعادة إرسال الرمز';

  @override
  String get authOtpSubmit => 'تأكيد';

  @override
  String authOtpInvalidFormat(int length) {
    return 'أدخل الرمز المكوّن من $length أرقام';
  }

  @override
  String get authOtpErrorTitle => 'الرمز غير صحيح';

  @override
  String authOtpErrorBody(int count) {
    return 'المحاولات المتبقية: $count. تأكد من الرمز الأخير المرسل — الرموز السابقة تنتهي صلاحيتها فور إرسال رمز جديد.';
  }

  @override
  String get authOtpRetry => 'إعادة المحاولة';

  @override
  String get authOtpChangeNumber => 'تغيير رقم الجوال';

  @override
  String get authOtpLockedTitle => 'محاولات كثيرة';

  @override
  String get authOtpLockedBody =>
      'لحماية حسابك أوقفنا قبول الرموز. اطلب رمزًا جديدًا للمتابعة.';

  @override
  String get authProfileTitle => 'إكمال البيانات';

  @override
  String get authProfileBannerTitle => 'اكتب اسمك كما في الهوية';

  @override
  String get authProfileBannerBody =>
      'يقارن النظام اسمك بصورة بطاقتك عند التحقق. أي اختلاف قد يؤخر تسجيل دخولك.';

  @override
  String get authProfileNameLabel => 'الاسم الكامل';

  @override
  String get authProfileNameHint => 'الاسم بالكامل كما في الهوية';

  @override
  String get authProfileEmailLabel => 'البريد الإلكتروني';

  @override
  String get authProfileEmailHint => 'name@example.com';

  @override
  String get authProfileSubmit => 'حفظ ومتابعة';

  @override
  String get authProfileNameInvalid => 'أدخل اسمك الكامل';

  @override
  String get authProfileEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get authSessionExpiredTitle => 'انتهت الجلسة';

  @override
  String get authSessionExpiredBannerTitle => 'انتهت جلستك';

  @override
  String get authSessionExpiredBannerBody =>
      'حجزك محفوظ ولم يُلغَ. سجّل دخولك مرة أخرى وسنعود إلى نفس الخطوة التي توقفت عندها.';

  @override
  String get authSessionExpiredSubmit => 'تسجيل الدخول';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String authDemoHint(String code) {
    return 'نسخة التطوير: رمز التحقق هو $code.';
  }

  @override
  String get commonApply => 'تطبيق';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonReset => 'إعادة تعيين';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonSeeAll => 'عرض الكل';

  @override
  String get commonBack => 'رجوع';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navBookings => 'حجوزاتي';

  @override
  String get navServices => 'الخدمات';

  @override
  String get navAccount => 'حسابي';

  @override
  String get navComingSoon => 'هذا القسم قيد الإنشاء وسيتوفّر في تحديث لاحق.';

  @override
  String get discoverGreeting => 'أهلاً بك';

  @override
  String discoverGreetingNamed(String name) {
    return 'أهلاً $name';
  }

  @override
  String get discoverSubtitle => 'اكتشف فنادق المجموعة';

  @override
  String get discoverSearchHint => 'ابحث عن فندق أو مدينة';

  @override
  String get discoverNotificationsTooltip => 'الإشعارات';

  @override
  String get discoverFeaturedSection => 'فنادق المجموعة';

  @override
  String get discoverExploreRooms => 'استكشف الغرف';

  @override
  String get discoverUpcomingStay => 'إقامتك القادمة';

  @override
  String get discoverUpcomingStayAction => 'عرض الحجز';

  @override
  String get discoverExploreHotels => 'اكتشف فنادق المجموعة';

  @override
  String discoverSubtitleHotel(String hotel) {
    return 'اكتشف $hotel';
  }

  @override
  String get discoverEmptyTitle => 'لا توجد فنادق للعرض بعد';

  @override
  String get discoverEmptyBody => 'ستظهر فنادق المجموعة هنا بمجرد نشرها.';

  @override
  String get searchTitle => 'البحث';

  @override
  String get searchClearTooltip => 'مسح البحث';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فندقاً متاحاً',
      one: 'فندق واحد متاح',
      zero: 'لا فنادق متاحة',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsTitle => 'لا فنادق تطابق بحثك';

  @override
  String get searchNoResultsBody => 'جرّب مدينة أخرى أو امسح عوامل التصفية.';

  @override
  String get searchClearFilters => 'مسح عوامل التصفية';

  @override
  String get sortRecommended => 'المُوصى به';

  @override
  String get sortTopRated => 'الأعلى تقييماً';

  @override
  String get sortLowestPrice => 'الأوفر سعراً';

  @override
  String get sortTitle => 'ترتيب النتائج';

  @override
  String get sortHint => 'يبقى الترتيب مفعّلاً حتى تغيّره أو تعيد البحث.';

  @override
  String get sortApply => 'تطبيق الترتيب';

  @override
  String get sortActiveTag => 'مفعّل';

  @override
  String get filterTitle => 'تصفية النتائج';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فندقاً مطابقاً',
      one: 'فندق واحد مطابق',
      zero: 'لا فنادق مطابقة',
    );
    return '$_temp0';
  }

  @override
  String get filterHint => 'عدّل المعايير لتضييق النتائج.';

  @override
  String get filterCityLabel => 'المدينة';

  @override
  String get filterValueAll => 'الكل';

  @override
  String filterSelectedCount(int count) {
    return '$count مختارة';
  }

  @override
  String get filterPriceLabel => 'نطاق السعر';

  @override
  String get filterFacilitiesLabel => 'المرافق';

  @override
  String get filterRatingLabel => 'التقييم';

  @override
  String get filterApply => 'تطبيق التصفية';

  @override
  String get filterClearAll => 'مسح الكل';

  @override
  String get filterCityPickerTitle => 'المدينة';

  @override
  String get filterCityPickerHint =>
      'يمكنك اختيار أكثر من مدينة. تُحدّث النتائج فور التطبيق.';

  @override
  String cityHotelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فنادق',
      one: 'فندق واحد',
    );
    return '$_temp0';
  }

  @override
  String priceRangeValue(int min, int max) {
    return '$min – $max ﷼';
  }

  @override
  String priceFrom(String amount) {
    return 'من $amount ﷼';
  }

  @override
  String pricePerNight(String amount) {
    return '$amount ﷼ / الليلة';
  }

  @override
  String priceStayTotal(String amount) {
    return '$amount ﷼ الإجمالي';
  }

  @override
  String get priceFromLabel => 'من';

  @override
  String get priceNightSuffix => '/ ليلة';

  @override
  String get priceTotalSuffix => 'للإقامة';

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
      other: '$count مراجعة',
      one: 'مراجعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get hotelAvailable => 'متاحة';

  @override
  String get hotelUnavailable => 'غير متاحة حاليًا';

  @override
  String get hotelDetailAmenities => 'الخدمات والمرافق';

  @override
  String hotelRoomTypeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أنواع غرف',
      one: 'نوع غرفة واحد',
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
  String get hotelSelectDates => 'اختيار التواريخ';

  @override
  String get hotelBookNow => 'احجز الآن';

  @override
  String hotelGuestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نزلاء',
      two: 'نزيلان',
      one: 'نزيل واحد',
    );
    return '$_temp0';
  }

  @override
  String roomAreaSqm(int area) {
    return '$area م²';
  }

  @override
  String get amenityFreeWifi => 'واي فاي مجاني';

  @override
  String get amenityBreakfast => 'إفطار';

  @override
  String get amenityParking => 'موقف سيارات';

  @override
  String get amenityPool => 'مسبح';

  @override
  String get amenityGym => 'نادٍ رياضي';

  @override
  String get amenityFamilyRooms => 'غرف عائلية';

  @override
  String get amenityAirportShuttle => 'نقل المطار';

  @override
  String get amenityRoomService => 'خدمة الغرف';

  @override
  String get amenityAirConditioning => 'تكييف';

  @override
  String get amenityCityView => 'إطلالة على المدينة';

  @override
  String get amenityBalcony => 'شرفة';

  @override
  String get amenityKitchenette => 'مطبخ صغير';

  @override
  String get stayDatesTitle => 'اختيار تاريخ الإقامة';

  @override
  String get stayDatesCheckIn => 'تاريخ الوصول';

  @override
  String get stayDatesCheckOut => 'تاريخ المغادرة';

  @override
  String get stayDatesPick => 'اختر التاريخ';

  @override
  String get stayDatesClear => 'مسح التواريخ';

  @override
  String get stayDatesShowRooms => 'عرض الغرف المتاحة';

  @override
  String stayNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليالٍ',
      two: 'ليلتان',
      one: 'ليلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get stayDatesErrorCheckoutBeforeCheckin =>
      'تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول';

  @override
  String get stayDatesErrorPast => 'اختر تاريخًا من اليوم فأكثر';

  @override
  String get stayDatesEditDates => 'تعديل التواريخ';

  @override
  String get guestsTitle => 'عدد الضيوف';

  @override
  String get guestsAdults => 'بالغون';

  @override
  String get guestsChildren => 'أطفال';

  @override
  String get guestsConfirm => 'تأكيد الضيوف';

  @override
  String get stepperDecrease => 'إنقاص';

  @override
  String get stepperIncrease => 'زيادة';

  @override
  String guestsAdultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بالغين',
      two: 'بالغان',
      one: 'بالغ واحد',
    );
    return '$_temp0';
  }

  @override
  String guestsChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أطفال',
      two: 'طفلان',
      one: 'طفل واحد',
      zero: 'بدون أطفال',
    );
    return '$_temp0';
  }

  @override
  String get roomsTitle => 'الغرف المتاحة';

  @override
  String roomsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غرفة متاحة',
      few: '$count غرف متاحة',
      two: 'غرفتان متاحتان',
      one: 'غرفة واحدة متاحة',
      zero: 'لا غرف متاحة',
    );
    return '$_temp0';
  }

  @override
  String get roomsSortLabel => 'الترتيب';

  @override
  String get roomsSortLowest => 'الأقل سعراً';

  @override
  String get roomsSortHighest => 'الأكثر سعراً';

  @override
  String roomOccupancy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أشخاص',
      two: 'ضيفان',
      one: 'ضيف واحد',
    );
    return '$_temp0';
  }

  @override
  String get roomBreakfastIncluded => 'إفطار مجاني';

  @override
  String get roomFreeCancellation => 'إمكانية الإلغاء المجاني';

  @override
  String get roomNonRefundable => 'غير قابلة للاسترداد';

  @override
  String get roomSoldOut => 'غير متاحة في هذه التواريخ';

  @override
  String get roomsAllSoldOutTitle => 'جميع الغرف غير متاحة في هذه التواريخ';

  @override
  String get roomsAllSoldOutBody =>
      'جرّب تواريخ أخرى وسنعرض الغرف التي تتوفّر.';

  @override
  String get roomsNoResultsTitle => 'لا توجد غرف متاحة في التواريخ المحددة';

  @override
  String get roomsNoResultsBody => 'جرّب تغيير التواريخ أو تعديل عدد الضيوف.';

  @override
  String get roomsChangeDates => 'تغيير التواريخ';

  @override
  String get roomsChangeGuests => 'تعديل عدد الضيوف';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get calendarWeekdays => 'أحد,إثنين,ثلاثاء,أربعاء,خميس,جمعة,سبت';

  @override
  String stayDatesSelectedRange(String checkIn, String checkOut) {
    return '$checkIn – $checkOut';
  }

  @override
  String get stayDatesHintPickCheckIn => 'اختر تاريخ الوصول للبدء';

  @override
  String stayDatesHintPickCheckOut(String checkIn) {
    return '$checkIn · اختر تاريخ المغادرة';
  }

  @override
  String get stayDatesFieldPlaceholder => 'اختر التاريخ';

  @override
  String get roomSelect => 'اختيار';

  @override
  String get roomSelected => 'محدَّدة';

  @override
  String get roomViewDetails => 'عرض التفاصيل';

  @override
  String get roomDetailsTitle => 'تفاصيل الغرفة';

  @override
  String get roomBedType => 'السرير';

  @override
  String get roomCapacityLabel => 'تتّسع لـ';

  @override
  String get roomPolicyLabel => 'الإلغاء';

  @override
  String roomPolicyRefundable(int hours) {
    return 'إلغاء مجاني مع استرداد كامل خلال $hours ساعة من الحجز أو حتى موعد تسجيل الدخول إن كان أقرب.';
  }

  @override
  String get roomPolicyRefundableShort => 'قابلة للإلغاء المجاني';

  @override
  String get roomPolicyNonRefundable => 'غير قابلة للاسترداد';

  @override
  String get roomSelectThisRoom => 'اختيار هذه الغرفة';

  @override
  String get roomRemoveSelection => 'إلغاء الاختيار';

  @override
  String roomStayTotalLabel(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: 'الإجمالي لـ$nights ليلة',
      few: 'الإجمالي لـ$nights ليالٍ',
      two: 'الإجمالي لليلتين',
      one: 'الإجمالي لليلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get roomCardPerNight => '/ الليلة';

  @override
  String get roomCardFreeCancellation => 'إلغاء مجاني';

  @override
  String stayGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ضيوف',
      one: 'ضيف واحد',
    );
    return '$_temp0';
  }

  @override
  String get roomDetailAmenitiesHeading => 'مرافق الغرفة';

  @override
  String get roomDetailCancellationHeading => 'سياسة الإلغاء';

  @override
  String get roomDetailStayHeading => 'إقامتك';

  @override
  String get roomSortTitle => 'ترتيب الغرف';

  @override
  String get roomSortApply => 'تطبيق الترتيب';

  @override
  String get roomSortActiveTag => 'مفعّل';

  @override
  String roomsSortTrigger(String label) {
    return 'الترتيب: $label';
  }

  @override
  String get roomsContinue => 'متابعة';

  @override
  String get roomFilterWifi => 'واي فاي';

  @override
  String get roomsFilterCta => 'تصفية';

  @override
  String get roomsNoFilterMatch => 'لا توجد غرف تطابق التصفية';

  @override
  String get roomFilterTitle => 'تصفية الغرف';

  @override
  String get roomFilterCancellation => 'قابلية الإلغاء';

  @override
  String get roomFilterFreeCancellation => 'إلغاء مجاني';

  @override
  String get roomFilterMeals => 'الوجبات';

  @override
  String get roomFilterBreakfast => 'إفطار مجاني';

  @override
  String get roomFilterFeatures => 'الميزات';

  @override
  String get roomFilterReset => 'إعادة تعيين';

  @override
  String get roomFilterShowResults => 'عرض النتائج';

  @override
  String get roomsSelectPrompt => 'اختر غرفة للمتابعة';

  @override
  String get roomsSelectionClearedNotice =>
      'أُلغي اختيار الغرفة لتغيّر تفاصيل الإقامة. الرجاء اختيار غرفة من جديد.';

  @override
  String get reviewTitle => 'مراجعة اختيارك';

  @override
  String get reviewNotBookedNotice =>
      'لم يتم الحجز بعد. لا يزال بإمكانك تغيير التواريخ أو الضيوف أو الغرفة قبل خطوة الحجز.';

  @override
  String get reviewHotelLabel => 'الفندق';

  @override
  String get reviewRoomLabel => 'الغرفة';

  @override
  String get reviewStayLabel => 'الإقامة';

  @override
  String get reviewGuestsLabel => 'الضيوف';

  @override
  String get reviewCheckInLabel => 'تاريخ الوصول';

  @override
  String get reviewCheckOutLabel => 'تاريخ المغادرة';

  @override
  String get reviewPriceLabel => 'السعر';

  @override
  String reviewTotalLabel(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights ليالٍ',
      two: 'ليلتين',
      one: 'ليلة واحدة',
    );
    return 'الإجمالي لـ $_temp0';
  }

  @override
  String get reviewChangeSelection => 'تغيير الاختيار';

  @override
  String get reviewNoSelectionTitle => 'لم تُختر غرفة';

  @override
  String get reviewNoSelectionBody => 'ارجع واختر غرفة لتظهر هنا.';

  @override
  String get reviewBackToRooms => 'العودة إلى الغرف';

  @override
  String get reviewSignInToConfirm => 'سجّل الدخول لتأكيد الحجز';

  @override
  String get reviewSignInHint =>
      'تحتاج حساباً لتأكيد هذا الحجز. التصفّح يبقى بلا تسجيل.';

  @override
  String get bookingDetailsTitle => 'تفاصيل الحجز';

  @override
  String get bookingDatesLabel => 'تواريخ الإقامة';

  @override
  String get bookingRoomSubtotal => 'قيمة الإقامة';

  @override
  String get bookingServiceFee => 'رسوم الخدمة';

  @override
  String bookingTaxRow(String rate) {
    return 'الضريبة ($rate٪)';
  }

  @override
  String get bookingTotal => 'الإجمالي';

  @override
  String get bookingProceedToPayment => 'المتابعة للدفع';

  @override
  String get bookingRoomAvailable => 'متاحة';

  @override
  String get reservationConfirmCta => 'تأكيد الحجز';

  @override
  String get reservationConfirming => 'جارٍ التأكيد…';

  @override
  String get reservationConfirmHint =>
      'بالتأكيد، أنت تطلب هذه الغرفة للتواريخ أعلاه. لن يُخصم أي مبلغ الآن.';

  @override
  String get reservationCreateFailedTitle => 'تعذّر تأكيد حجزك';

  @override
  String get reservationStatusFieldLabel => 'الحالة';

  @override
  String get reservationStatusPending => 'قيد الانتظار';

  @override
  String get reservationStatusConfirmed => 'مؤكد';

  @override
  String get reservationStatusDepositHeld => 'تم حجز التأمين';

  @override
  String get reservationStatusVerified => 'تم التحقق';

  @override
  String get reservationStatusCheckedIn => 'تم تسجيل الدخول';

  @override
  String get reservationStatusInStay => 'أثناء الإقامة';

  @override
  String get reservationStatusCheckoutInProgress => 'جارٍ تسجيل المغادرة';

  @override
  String get reservationStatusCheckoutBlocked => 'المغادرة معلّقة';

  @override
  String get reservationStatusCheckedOut => 'تمت المغادرة';

  @override
  String get reservationStatusInvoiced => 'تمت الفوترة';

  @override
  String get reservationStatusCancelled => 'ملغى';

  @override
  String moneyAmount(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get paymentReviewTitle => 'الدفع';

  @override
  String get paymentProcessingTitle => 'جارٍ معالجة الدفع';

  @override
  String get paymentResultTitle => 'الدفع';

  @override
  String get paymentReservationLabel => 'الحجز';

  @override
  String get paymentStatusFieldLabel => 'حالة الدفع';

  @override
  String get paymentPayNowCta => 'ادفع الآن';

  @override
  String get paymentHoldExplainer =>
      'يُحجَز مبلغ تأمين قابل للاسترداد لإقامتك. لن يُخصَم أي مبلغ الآن.';

  @override
  String get paymentProcessingBody => 'جارٍ تأكيد عملية الدفع…';

  @override
  String get paymentDoNotClose => 'يرجى إبقاء هذه الشاشة مفتوحة.';

  @override
  String get paymentAlreadyHeldTitle => 'تم حجز التأمين مسبقًا';

  @override
  String get paymentAlreadyHeldBody => 'حجز التأمين لهذا الحجز قائم بالفعل.';

  @override
  String get paymentSuccessTitle => 'تم تأكيد حجز التأمين';

  @override
  String get paymentNotRequiredTitle => 'تم تأكيد حجزك';

  @override
  String get paymentNotRequiredBody =>
      'لا يتطلب هذا الفندق مبلغ تأمين. تبدأ إقامتك عند تسجيل الدخول.';

  @override
  String get paymentSuccessBody =>
      'تم تأمين مبلغ التأمين. يمكنك المتابعة إلى التحقق من الهوية.';

  @override
  String get paymentPendingTitle => 'جارٍ معالجة الدفع';

  @override
  String get paymentPendingBody =>
      'لم يؤكد البنك الحجز بعد. يمكنك التحقق من الحالة بعد قليل.';

  @override
  String get paymentFailedTitle => 'تعذّر إتمام الدفع';

  @override
  String get paymentFailedBody => 'لم يُخصَم أي مبلغ. يمكنك المحاولة مرة أخرى.';

  @override
  String get paymentCancelledTitle => 'تم إلغاء الدفع';

  @override
  String get paymentExpiredTitle => 'انتهت صلاحية حجز التأمين';

  @override
  String get paymentRetryCta => 'حاول مرة أخرى';

  @override
  String get paymentBackToReservation => 'العودة إلى الحجز';

  @override
  String get paymentUnavailableTitle => 'الدفع غير متاح';

  @override
  String get paymentStatusNotStarted => 'لم يبدأ';

  @override
  String get paymentStatusHoldRequested => 'جارٍ التفويض';

  @override
  String get paymentStatusHoldActive => 'تم حجز التأمين';

  @override
  String get paymentStatusHoldFailed => 'فشل';

  @override
  String get paymentStatusCaptureRequested => 'جارٍ الخصم';

  @override
  String get paymentStatusCaptured => 'تم الخصم';

  @override
  String get paymentStatusCaptureFailed => 'فشل الخصم';

  @override
  String get paymentStatusFinalSettlementRequested => 'جارٍ التسوية';

  @override
  String get paymentStatusSettled => 'تمت التسوية';

  @override
  String get paymentStatusSettlementFailed => 'فشلت التسوية';

  @override
  String get paymentStatusCancelled => 'ملغى';

  @override
  String get paymentStatusExpired => 'منتهٍ';

  @override
  String get paymentStatusRefundRequested => 'استرداد قيد المعالجة';

  @override
  String get paymentStatusRefunded => 'تم الاسترداد';

  @override
  String get paymentStatusRefundFailed => 'فشل الاسترداد';

  @override
  String get paymentMethodTitle => 'وسيلة الدفع';

  @override
  String get paymentMethodBannerTitle => 'اختر وسيلة الدفع';

  @override
  String get paymentMethodBannerBody =>
      'يُحجز مبلغ التأمين دون خصمه، ويُفرج عنه بعد المغادرة ما لم تُسجَّل رسوم إضافية.';

  @override
  String get paymentMethodApplePay => 'Apple Pay';

  @override
  String get paymentMethodSavedCard => 'بطاقة مدى أو ائتمانية';

  @override
  String get paymentMethodAddNewCard => 'إضافة بطاقة جديدة';

  @override
  String get paymentHoldNotice =>
      'يُحجز مبلغ التأمين دون خصمه حتى تسجيل الدخول';

  @override
  String get paymentCardDetailsTitle => 'الدفع';

  @override
  String get paymentBreakdownHeading => 'تفاصيل التكلفة';

  @override
  String get paymentNightsLabel => 'عدد الليالي';

  @override
  String get paymentBookingTotalLabel => 'إجمالي الحجز';

  @override
  String get paymentDepositHint => 'يُحجَز الآن كتأمين قابل للاسترداد';

  @override
  String get paymentCardDepositLabel => 'مبلغ التأمين';

  @override
  String get paymentCardNumberLabel => 'رقم البطاقة';

  @override
  String get paymentCardNumberHint => '4242 4242 4242 4242';

  @override
  String get paymentCardholderNameLabel => 'الاسم على البطاقة';

  @override
  String get paymentCardNotStoredNote =>
      'لا يتم حفظ بيانات بطاقتك داخل النظام.';

  @override
  String get paymentConfirmCta => 'تأكيد الدفع';

  @override
  String get identityVerificationTitle => 'التحقق من الهوية';

  @override
  String get identityVerificationResultTitle => 'التحقق من الهوية';

  @override
  String get identityVerifyCta => 'تحقّق من الهوية';

  @override
  String get identityStepDocument => 'المستند';

  @override
  String get identityStepSelfie => 'صورة ذاتية';

  @override
  String get identityStepResult => 'النتيجة';

  @override
  String get identityDocumentStepTitle => 'ارفع مستند هويتك';

  @override
  String get identityDocumentStepBody =>
      'استخدم جواز السفر أو الهوية الوطنية أو تصريح الإقامة. تأكد من ظهور المستند كاملًا وواضحًا.';

  @override
  String get identityDocumentTypePassport => 'جواز السفر';

  @override
  String get identityDocumentTypeNationalId => 'الهوية الوطنية';

  @override
  String get identityDocumentTypeResidencePermit => 'الإقامة';

  @override
  String get identityDocumentTypeLabel => 'نوع الوثيقة';

  @override
  String get identityDocumentCaptureCta => 'أضف صورة المستند';

  @override
  String get identityDocumentCapturedLabel => 'تمت إضافة صورة المستند';

  @override
  String get identityDocumentSubmitCta => 'المتابعة إلى الصورة الذاتية';

  @override
  String get identitySelfieStepTitle => 'التقط صورة ذاتية';

  @override
  String get identitySelfieStepBody =>
      'انظر مباشرة إلى الكاميرا في إضاءة جيدة. نطابق صورتك الذاتية مع صورة هويتك.';

  @override
  String get identitySelfieCaptureCta => 'أضف صورة ذاتية';

  @override
  String get identitySelfieCapturedLabel => 'تمت إضافة الصورة الذاتية';

  @override
  String get identitySelfieSubmitCta => 'إرسال للتحقق';

  @override
  String get identityProcessingTitle => 'جارٍ التحقق من هويتك';

  @override
  String get identityProcessingBody => 'جارٍ مطابقة صورتك الذاتية مع مستندك…';

  @override
  String get identityApprovedTitle => 'تم التحقق من الهوية';

  @override
  String get identityApprovedBody => 'تم تأكيد هويتك. أنت جاهز لتسجيل الدخول.';

  @override
  String get identityManualReviewTitle => 'المراجعة اليدوية قيد التنفيذ';

  @override
  String get identityManualReviewBody =>
      'يقوم فريقنا بمراجعة مستنداتك. تستغرق هذه العملية وقتًا قصيرًا عادةً — سنُعلمك عند اكتمالها.';

  @override
  String get identityRetryTitle => 'لنجرب ذلك مرة أخرى';

  @override
  String get identityRetryBody =>
      'لم نتمكن من التحقق من هويتك من تلك الصور. يرجى إعادة التقاطها وإرسالها مجددًا.';

  @override
  String get identityRetryCta => 'حاول مرة أخرى';

  @override
  String get identityRejectedTitle => 'لم تتم الموافقة على التحقق';

  @override
  String get identityRejectedBody =>
      'لم يتمكن فريقنا من الموافقة على التحقق من هويتك. يرجى التواصل مع مكتب الاستقبال للمساعدة.';

  @override
  String get identityRejectedRetryBody =>
      'لم يتمكن فريقنا من الموافقة على التحقق من هويتك. يمكنك إرسال صور جديدة والمحاولة مرة أخرى.';

  @override
  String identityAttemptCount(int count) {
    return 'المحاولة $count';
  }

  @override
  String get identityBackToReservation => 'العودة إلى الحجز';

  @override
  String get identityViewResultCta => 'عرض النتيجة';

  @override
  String get identityUnavailableTitle => 'التحقق غير متاح';

  @override
  String get identityStatusNotStarted => 'لم يبدأ';

  @override
  String get identityStatusDocumentUploaded => 'تم رفع المستند';

  @override
  String get identityStatusSelfieCaptured => 'تم التقاط الصورة الذاتية';

  @override
  String get identityStatusMatchingInProgress => 'جارٍ المطابقة';

  @override
  String get identityStatusAutoApproved => 'تم التحقق';

  @override
  String get identityStatusPendingManualReview => 'قيد المراجعة';

  @override
  String get identityStatusStaffApproved => 'تم التحقق';

  @override
  String get identityStatusStaffRejected => 'غير موافق عليه';

  @override
  String get identityStatusRetryAllowed => 'يلزم إعادة المحاولة';

  @override
  String get identityIntroBannerTitle => 'تحقق سريع من هويتك';

  @override
  String get identityIntroBannerBody =>
      'خطوتان: صورة لهويتك، ثم صورة حية لوجهك. تُحذف الصور بعد انتهاء إقامتك.';

  @override
  String get identityIntroBannerBodyDocumentOnly =>
      'خطوة واحدة: صورة لهويتك. تُحذف الصور بعد انتهاء إقامتك.';

  @override
  String get identityDocumentOnlyBody =>
      'اختر نوع وثيقتك، ثم التقط صورة واضحة لها.';

  @override
  String get identityIntroCta => 'ابدأ التحقق';

  @override
  String get identityCaptureDocumentTitle => 'صوّر هويتك';

  @override
  String get identityCaptureDocumentHint =>
      'ضع الهوية داخل الإطار مع ظهور الحواف الأربع';

  @override
  String get identityCaptureFootnote => 'الكاميرا فقط — لا رفع من المعرض';

  @override
  String get identityCaptureFootnoteWeb => 'اختر صورة واضحة للهوية';

  @override
  String get identitySelfieFootnoteWeb => 'اختر صورة واضحة لوجهك';

  @override
  String get identityCaptureFootnoteSecurity =>
      'تُحفظ صورك بشكل آمن وتُحذف بعد انتهاء إقامتك';

  @override
  String get identityReviewDocumentTitle => 'تأكيد صورة الهوية';

  @override
  String get identityReviewDocumentBody =>
      'تأكد من وضوح الاسم والرقم وتاريخ الانتهاء';

  @override
  String get identityReviewContinueCta => 'متابعة';

  @override
  String get identityReviewRetakeCta => 'إعادة التصوير';

  @override
  String get identityCaptureSelfieTitle => 'التحقق من الهوية';

  @override
  String get identityCaptureSelfieHint => 'التقط صورة حية من الكاميرا';

  @override
  String get identityReviewRetakeHint =>
      'يمكنك إعادة التصوير إن كانت الصورة غير واضحة';

  @override
  String get identityShutterLabel => 'التقاط صورة';

  @override
  String get identityCameraDeniedTitle => 'لا يمكن الوصول إلى الكاميرا';

  @override
  String get identityCameraDeniedBody =>
      'التحقق يتطلب صورة حية من الكاميرا ولا يمكن رفعها من المعرض. فعّل إذن الكاميرا من الإعدادات.';

  @override
  String get identityCameraUnavailableBody =>
      'لا توجد كاميرا متاحة على هذا الجهاز. أكمل التحقق من جهاز آخر أو لدى الاستقبال.';

  @override
  String get identityOpenSettingsCta => 'فتح الإعدادات';

  @override
  String get identityUploadingBannerTitle => 'جارٍ رفع صورك';

  @override
  String get identityUploadingBannerBody =>
      'لا تغلق التطبيق. يستغرق الرفع عادةً ثوانٍ قليلة على اتصال جيد.';

  @override
  String get identityUploadingCancelCta => 'إلغاء';

  @override
  String get identityProcessingContinueCta => 'متابعة';

  @override
  String get identitySuccessBannerTitle => 'تم التحقق';

  @override
  String get identitySuccessBannerBody =>
      'لن يُطلب رفع هويتك مرة أخرى في أي فندق بالمجموعة.';

  @override
  String get identityGoToCheckInCta => 'تسجيل الدخول الرقمي';

  @override
  String get identityRejectedNoRetryBannerBody =>
      'راجع موظف الفندق طلبك ولم يُقبل. يمكنك إتمام الإجراء عند الاستقبال فور وصولك، وحجزك محفوظ.';

  @override
  String get identityContactReceptionCta => 'تواصل مع الاستقبال';

  @override
  String get identityFailedUploadBannerTitle => 'تعذر رفع الصور';

  @override
  String get identityFailedUploadBannerBody =>
      'انقطع الاتصال أثناء الرفع. صورك محفوظة على جهازك، ويمكنك إعادة الرفع دون تصوير من جديد.';

  @override
  String get identityRetryUploadCta => 'إعادة الرفع';

  @override
  String get identityContinueLaterCta => 'المتابعة لاحقاً';

  @override
  String get identityFaceNotMatchedBannerTitle => 'لم نتمكن من مطابقة وجهك';

  @override
  String get identityFaceNotMatchedBannerBody =>
      'الصورة الحية لا تطابق صورة الهوية بدرجة كافية. أعد المحاولة في إضاءة جيدة ودون غطاء للوجه.';

  @override
  String get identityRequestManualReviewCta => 'طلب مراجعة يدوية';

  @override
  String get identityDocumentUnclearBannerTitle => 'الصورة غير واضحة';

  @override
  String get identityDocumentUnclearBannerBody =>
      'تعذرت قراءة بيانات الهوية. صوّر في إضاءة جيدة دون انعكاس، مع ظهور الحواف الأربع كاملة.';

  @override
  String get identityContactReceptionBannerTitle =>
      'الاستقبال متاح على مدار الساعة';

  @override
  String get identityContactReceptionBannerBody =>
      'سنوصلك بفندقك مباشرة. يمكن لموظف الاستقبال إتمام التحقق يدوياً عند الوصول.';

  @override
  String contactReceptionBody(String phone) {
    return 'سنوصلك باستقبال فندق إقامتك مباشرة على الرقم $phone.';
  }

  @override
  String get contactReceptionNoPhoneBody =>
      'يمكنك التواصل مع موظف الاستقبال مباشرة في مكتب الاستقبال بالفندق.';

  @override
  String get contactReceptionCallCta => 'اتصال بالاستقبال';

  @override
  String contactReceptionCallFailed(String phone) {
    return 'تعذّر فتح الاتصال على هذا الجهاز. رقم الاستقبال: $phone';
  }

  @override
  String get identityViewVerificationStatusCta => 'عرض حالة التحقق';

  @override
  String get identityDetailsTitle => 'بيانات الهوية';

  @override
  String get identityDetailsBody =>
      'أدخلها كما هي مطبوعة في وثيقتك تمامًا. نقارنها بصورة الهوية ولا نحتفظ بها.';

  @override
  String get identityFullNameLabel => 'الاسم الكامل كما في الوثيقة';

  @override
  String get identityFullNameHint =>
      'في جواز السفر: اكتبه بالأحرف اللاتينية كما هو مطبوع';

  @override
  String get identityDocumentNumberLabel => 'رقم الوثيقة';

  @override
  String get identityDateOfBirthLabel => 'تاريخ الميلاد';

  @override
  String get identityDateOfBirthHint => 'اختر التاريخ';

  @override
  String get identityFieldRequired => 'مطلوب';

  @override
  String get identityDocumentNumberInvalid => 'أحرف وأرقام فقط';

  @override
  String identityUploadProgress(String percent) {
    return 'تم رفع $percent٪';
  }

  @override
  String get identityReadingDocumentTitle => 'جارٍ قراءة هويتك';

  @override
  String get identityReadingDocumentBody =>
      'نتحقق من بيانات وثيقتك، يستغرق ذلك بضع ثوانٍ — أبقِ التطبيق مفتوحًا.';

  @override
  String get identityMismatchTitle => 'البيانات لا تطابق هويتك';

  @override
  String identityMismatchFieldsBody(String fields) {
    return 'راجع ما أدخلته مقابل وثيقتك: $fields.';
  }

  @override
  String get identityMismatchBody =>
      'ما أدخلته لا يطابق الوثيقة. راجع بياناتك أو أعد التصوير.';

  @override
  String get identityFieldName => 'الاسم';

  @override
  String get identityFieldDocumentNumber => 'رقم الوثيقة';

  @override
  String get identityFieldDateOfBirth => 'تاريخ الميلاد';

  @override
  String get identityEditDetailsCta => 'تعديل البيانات';

  @override
  String get identityExpiredTitle => 'الوثيقة منتهية الصلاحية';

  @override
  String get identityExpiredBody =>
      'يجب أن تكون الهوية سارية في تاريخ الوصول. استخدم وثيقة أخرى سارية.';

  @override
  String get identityUseAnotherDocumentCta => 'استخدام وثيقة أخرى';

  @override
  String get identityUnsupportedTitle => 'هذه الوثيقة غير مقبولة';

  @override
  String get identityUnsupportedBody =>
      'استخدم جواز السفر أو الهوية الوطنية أو الإقامة.';

  @override
  String get identityDocumentTypeEgyptianId => 'بطاقة الرقم القومي المصرية';

  @override
  String get identityDocumentTypeSaudiId => 'الهوية الوطنية السعودية';

  @override
  String get identityDocumentTypeSaudiIqama => 'الإقامة السعودية';

  @override
  String get identityDocumentSidesFrontOnly => 'صورة صفحة البيانات فقط';

  @override
  String get identityDocumentSidesFrontAndBack => 'صورة الوجه والخلف';

  @override
  String get identityDocumentSidesBackOptional => 'صورة الوجه — والخلف اختياري';

  @override
  String get identityDocumentStaffCheck => 'سيراجع موظفونا هذه الوثيقة';

  @override
  String get identityFullNameArabicHint =>
      'اكتبه بالعربية كما هو مطبوع: الاسم الأول ثم باقي الاسم';

  @override
  String get identityBirthDateFromNumber =>
      'يُقرأ تاريخ ميلادك من الرقم القومي.';

  @override
  String get identityDocumentNumberInvalidForType =>
      'تحقق من صيغة الرقم لهذه الوثيقة';

  @override
  String get identityCaptureBackTitle => 'صوّر خلف البطاقة';

  @override
  String get identityCaptureBackHint => 'اقلب البطاقة وضعها داخل الإطار.';

  @override
  String get identityCaptureTipFrame =>
      'البطاقة كاملة داخل الإطار وحوافها الأربع ظاهرة';

  @override
  String get identityCaptureTipLight =>
      'إضاءة جيدة، بدون فلاش أو انعكاس على البطاقة';

  @override
  String get identityCaptureTipSteady =>
      'ثبّت الهاتف فوق البطاقة حتى تظهر الكتابة واضحة';

  @override
  String get identitySelfieTipFrame =>
      'وجهك كامل داخل الإطار وانظر مباشرة للكاميرا';

  @override
  String get identitySelfieTipClear =>
      'بدون نظارة شمسية أو غطاء للوجه، وفي إضاءة جيدة';

  @override
  String get identityCaptureSelfieHintWeb => 'اختر صورة حديثة وواضحة لوجهك';

  @override
  String get identityStuckContactReception =>
      'لا تستطيع المتابعة؟ تواصل مع الاستقبال';

  @override
  String get identitySkipBackCta => 'تخطَّ — الوجه فقط';

  @override
  String get identityReviewBothSides =>
      'صورتا الوجه والخلف جاهزتان. تأكد من وضوح كل البيانات.';

  @override
  String get identityDocumentAcceptedTitle => 'تم قبول الوثيقة';

  @override
  String get identityDocumentAcceptedBody =>
      'بياناتك مطابقة لوثيقتك. الخطوة التالية: صورة سيلفي حية.';

  @override
  String get identityDocumentReviewTitle => 'مطلوب مراجعة يدوية';

  @override
  String get identityDocumentReviewBody =>
      'سيؤكد موظفونا وثيقتك. أكمل بصورة السيلفي لإنهاء خطوتك.';

  @override
  String get identitySubmitFailedTitle => 'تعذّر إرسال وثيقتك';

  @override
  String get reservationCheckInCta => 'تسجيل الدخول';

  @override
  String get checkInTitle => 'تسجيل الدخول';

  @override
  String get checkInProcessingTitle => 'جارٍ تسجيل دخولك';

  @override
  String get accessTitle => 'الدخول إلى الغرفة';

  @override
  String get checkInReadyTitle => 'جاهز لتسجيل الدخول';

  @override
  String get checkInReadyBody =>
      'تم التحقق من حجزك. سجّل الدخول للحصول على رقم غرفتك ورمز الدخول.';

  @override
  String get checkInNotReadyTitle => 'لست جاهزًا لتسجيل الدخول بعد';

  @override
  String get checkInRoomNotAssigned =>
      'غرفتك قيد التجهيز — يُفتح تسجيل الدخول بعد أن يخصّصها الاستقبال.';

  @override
  String get checkInAtReception =>
      'تسجيل الدخول في هذا الفندق يتم لدى الاستقبال عند وصولك.';

  @override
  String get checkInIdentityPending => 'أكمل التحقق من هويتك أولاً.';

  @override
  String get checkInNotReadyBody => 'أكمل الدفع والتحقق من الهوية أولاً.';

  @override
  String get checkInUnavailableTitle => 'تسجيل الدخول غير متاح';

  @override
  String get checkInAlreadyDoneTitle => 'لقد سجّلت دخولك بالفعل';

  @override
  String get checkInCta => 'سجّل الدخول الآن';

  @override
  String get checkInProcessingBody => 'جارٍ إصدار مفتاح غرفتك الرقمي…';

  @override
  String get checkInDoNotClose => 'يرجى إبقاء هذه الشاشة مفتوحة.';

  @override
  String get checkInFailedTitle => 'لم يكتمل تسجيل الدخول';

  @override
  String get checkInFailedBody =>
      'تعذّر إصدار مفتاح غرفتك. يمكنك المحاولة مرة أخرى.';

  @override
  String get checkInPendingTitle => 'أوشكت على الانتهاء';

  @override
  String get checkInPendingBody =>
      'يقوم مكتب الاستقبال بإنهاء تسجيل دخولك. تحقق مرة أخرى بعد قليل.';

  @override
  String get checkInRetryCta => 'حاول مرة أخرى';

  @override
  String get accessCheckedInTitle => 'تم تسجيل دخولك';

  @override
  String get accessRoomNumberLabel => 'رقم الغرفة';

  @override
  String get accessEntryCodeLabel => 'رمز الدخول';

  @override
  String accessStayEndsLabel(String date) {
    return 'انتهاء إقامتك · $date';
  }

  @override
  String get accessRoomPending => 'يُخصَّص عند الاستقبال';

  @override
  String get accessKeyNotWorking => 'لم يعمل الرمز؟';

  @override
  String accessExpiresLabel(String date) {
    return 'ساري حتى انتهاء إقامتك · $date';
  }

  @override
  String get accessHelpBanner => 'لم يعمل الرمز؟ تواصل مع الاستقبال.';

  @override
  String get accessNotIssuedTitle => 'لا يوجد مفتاح غرفة بعد';

  @override
  String get accessNotIssuedBody =>
      'سجّل الدخول للحصول على مفتاح غرفتك الرقمي.';

  @override
  String get accessRevokedTitle => 'تم إلغاء مفتاح الغرفة';

  @override
  String get accessRevokedBody =>
      'لم يعد مفتاح الغرفة هذا نشطًا. تواصل مع الاستقبال إذا احتجت للمساعدة.';

  @override
  String get accessExpiredTitle => 'انتهت صلاحية مفتاح الغرفة';

  @override
  String get accessExpiredBody =>
      'انتهت إقامتك، لذا لم يعد مفتاح الغرفة هذا يعمل.';

  @override
  String get accessFailedTitle => 'مفتاح الغرفة غير متاح';

  @override
  String get accessUnavailableTitle => 'الدخول غير متاح';

  @override
  String get accessBackToReservation => 'العودة إلى الحجز';

  @override
  String get accessStatusNotIssued => 'لم يُصدر';

  @override
  String get accessStatusIssueRequested => 'جارٍ الإصدار';

  @override
  String get accessStatusActive => 'نشط';

  @override
  String get accessStatusFailed => 'فشل';

  @override
  String get accessStatusRevokeRequested => 'جارٍ الإلغاء';

  @override
  String get accessStatusRevoked => 'ملغى';

  @override
  String get accessStatusExpired => 'منتهٍ';

  @override
  String get servicesTitle => 'خدمات الفندق';

  @override
  String get servicesIntroBanner =>
      'اطلب ما تحتاجه من غرفتك. تصل الطلبات إلى الاستقبال مباشرة.';

  @override
  String get servicesEmptyTitle => 'لا توجد خدمات متاحة';

  @override
  String get servicesEmptyBody => 'لم ينشر هذا الفندق أي خدمات بعد.';

  @override
  String get servicesUnavailableTitle => 'الخدمات غير متاحة';

  @override
  String get serviceUncategorised => 'خدمات أخرى';

  @override
  String get serviceFreeLabel => 'مشمول';

  @override
  String serviceEstimatedMinutes(int count) {
    return '~$count دقيقة';
  }

  @override
  String get serviceDetailTitle => 'الخدمة';

  @override
  String get serviceQuantityLabel => 'الكمية';

  @override
  String get serviceNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get serviceNotesHint => 'أي شيء يجب أن يعرفه الفريق';

  @override
  String get serviceRequestCta => 'اطلب هذه الخدمة';

  @override
  String get serviceRequestingCta => 'جارٍ الإرسال…';

  @override
  String get serviceEstimatedTotalLabel => 'الإجمالي المقدّر';

  @override
  String get serviceChargeNote =>
      'تُضاف أي رسوم إلى حساب غرفتك وتُسوّى عند المغادرة.';

  @override
  String get serviceRequestFailedTitle => 'تعذّر إرسال طلبك';

  @override
  String get myRequestsTitle => 'طلباتي';

  @override
  String get myRequestsIntroBanner =>
      'تابع حالة كل طلب. يمكنك إلغاء الطلب قبل أن يبدأ الفريق تنفيذه.';

  @override
  String get myRequestsEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get myRequestsEmptyBody => 'اطلب خدمة وستظهر هنا.';

  @override
  String get newRequestCta => 'طلب جديد';

  @override
  String get serviceOrderDetailTitle => 'تفاصيل الطلب';

  @override
  String get serviceOrderRequestedAtLabel => 'تاريخ الطلب';

  @override
  String get serviceOrderConfirmedAtLabel => 'تاريخ القبول';

  @override
  String get serviceCancelCta => 'إلغاء الطلب';

  @override
  String get serviceCancelConfirmTitle => 'إلغاء هذا الطلب؟';

  @override
  String get serviceCancelConfirmBody =>
      'لم يبدأ الفريق تنفيذ هذا الطلب بعد، لذا لا يزال بالإمكان إلغاؤه.';

  @override
  String serviceCancelConfirmTitleFor(String service) {
    return 'إلغاء طلب $service؟';
  }

  @override
  String get serviceCancelInProgressBody =>
      'الطلب قيد التنفيذ حالياً. الإلغاء الآن قد لا يوقف الفريق إن كان في الطريق إلى غرفتك.';

  @override
  String get serviceCancelConfirmCta => 'تأكيد الإلغاء';

  @override
  String get serviceCancelKeepCta => 'الإبقاء على الطلب';

  @override
  String get serviceCancelNotAllowed => 'لم يعد بالإمكان إلغاء هذا الطلب.';

  @override
  String get serviceContactReception => 'تواصل مع الاستقبال';

  @override
  String get serviceContactReceptionHint =>
      'اتصل بالاستقبال من هاتف غرفتك أو من مكتب الاستقبال للمساعدة في هذا الطلب.';

  @override
  String get serviceStatusRequested => 'قيد الانتظار';

  @override
  String get serviceStatusConfirmed => 'مقبول';

  @override
  String get serviceStatusFulfilled => 'مكتمل';

  @override
  String get serviceStatusCancelled => 'ملغى';

  @override
  String get checkoutTitle => 'المغادرة';

  @override
  String get checkoutProcessingTitle => 'جارٍ إتمام المغادرة';

  @override
  String get checkoutCompleteTitle => 'ملخص إقامتك';

  @override
  String get invoiceTitle => 'الفاتورة';

  @override
  String get checkoutReadyTitle => 'جاهز للمغادرة';

  @override
  String get checkoutReadyBody => 'لا مهام معلّقة.';

  @override
  String get checkoutNotReadyTitle => 'المغادرة غير متاحة بعد';

  @override
  String get checkoutNotReadyBody => 'يمكنك تسجيل المغادرة بعد أن تبدأ إقامتك.';

  @override
  String get checkoutUnavailableTitle => 'المغادرة غير متاحة';

  @override
  String get folioSummaryTitle => 'ملخص الرسوم';

  @override
  String get folioAccommodationLine => 'قيمة الإقامة';

  @override
  String get folioServiceLine => 'رسوم الخدمة';

  @override
  String get folioTotalLabel => 'الإجمالي';

  @override
  String get folioPaidLabel => 'المدفوع مسبقًا';

  @override
  String get folioOutstandingLabel => 'المبلغ المستحق الآن';

  @override
  String get checkoutSettleNote =>
      'يُخصم المبلغ المستحق دفعة واحدة من بطاقتك المسجّلة، وتُرسل فاتورتك إلكترونياً.';

  @override
  String get stayCheckoutCta => 'تسجيل المغادرة';

  @override
  String checkoutEarlyDepartureNote(String date) {
    return 'ستغادر قبل موعد المغادرة المحجوز ($date). تُحتسب الإقامة على الليالي التي أقمتها فقط.';
  }

  @override
  String get checkoutCompleteCta => 'إتمام المغادرة';

  @override
  String get checkoutProcessingBody => 'جارٍ تسوية حسابك…';

  @override
  String get checkoutDoNotClose => 'يرجى إبقاء هذه الشاشة مفتوحة.';

  @override
  String get checkoutDoneTitle => 'شكراً لإقامتك';

  @override
  String get checkoutDoneBody => 'تمت تسوية حسابك وفاتورتك جاهزة.';

  @override
  String get checkoutPendingTitle => 'جارٍ معالجة التسوية';

  @override
  String get checkoutPendingBody =>
      'لم يؤكد البنك الدفع بعد. تحقق من الحالة مرة أخرى بعد قليل.';

  @override
  String get checkoutFailedTitle => 'لم تكتمل التسوية';

  @override
  String get checkoutFailedBody => 'لم يُخصم أي مبلغ. يمكنك المحاولة مرة أخرى.';

  @override
  String get checkoutRetryCta => 'حاول مرة أخرى';

  @override
  String get checkoutViewInvoiceCta => 'عرض الفاتورة';

  @override
  String get checkoutDoneCta => 'تم';

  @override
  String get checkoutStatusInProgress => 'قيد التنفيذ';

  @override
  String get checkoutStatusAwaitingSettlement => 'بانتظار التسوية';

  @override
  String get checkoutStatusSettlementFailed => 'فشلت التسوية';

  @override
  String get checkoutStatusCompleted => 'مكتمل';

  @override
  String get invoiceIssuedBannerTitle => 'صدرت فاتورتك الإلكترونية';

  @override
  String get invoiceIssuedBannerBody =>
      'أُرسلت إلى بريدك الإلكتروني وهي محفوظة هنا دائماً — لا فاتورة ورقية.';

  @override
  String get invoiceNumberLabel => 'رقم الفاتورة';

  @override
  String get invoiceIssuedLabel => 'تاريخ الإصدار';

  @override
  String get invoiceItemsTitle => 'البنود';

  @override
  String get invoiceSubtotalLabel => 'المجموع الفرعي';

  @override
  String get invoicePaymentsLabel => 'المدفوعات';

  @override
  String get invoiceOutstandingLabel => 'المتبقي';

  @override
  String get invoiceSettledTag => 'مُسدّدة بالكامل';

  @override
  String get invoiceNotReadyTitle => 'لا توجد فاتورة بعد';

  @override
  String get invoiceNotReadyBody => 'ستظهر فاتورتك هنا بعد تسجيل مغادرتك.';

  @override
  String get invoiceUnavailableTitle => 'الفاتورة غير متاحة';

  @override
  String get reservationLoyaltyCta => 'الولاء والنقاط';

  @override
  String get reservationReviewCta => 'أضف تقييماً';

  @override
  String get reservationViewReviewCta => 'عرض تقييمك';

  @override
  String get loyaltyTitle => 'الولاء';

  @override
  String get loyaltyUnavailableTitle => 'الولاء غير متاح';

  @override
  String get loyaltyBalanceLabel => 'رصيد النقاط';

  @override
  String loyaltyPointsValue(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points نقطة',
      one: 'نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get loyaltyGroupWideNote => 'نقاطك صالحة في جميع فنادق المجموعة.';

  @override
  String get loyaltyProgramOffTitle => 'برنامج الولاء غير مُفعّل';

  @override
  String get loyaltyProgramOffBody =>
      'لم تُفعّل مجموعة الفنادق كسب النقاط بعد. لا يوجد إجراء مطلوب هنا حالياً.';

  @override
  String get loyaltyAlreadyEarnedTitle => 'النقاط مُضافة بالفعل';

  @override
  String get loyaltyAlreadyEarnedBody =>
      'لقد كسبت نقاطاً عن هذه الإقامة بالفعل.';

  @override
  String get loyaltyHistoryTitle => 'سجل النقاط';

  @override
  String get loyaltyHistoryNote =>
      'سجل نقاطك الكامل محفوظ لدى مجموعة الفنادق. هذه نسخة للعرض فقط.';

  @override
  String get loyaltyHistoryEmptyTitle => 'لا نشاط نقاط بعد';

  @override
  String get loyaltyHistoryEmptyBody =>
      'ستظهر هنا النقاط التي تكسبها وتستبدلها.';

  @override
  String loyaltyPointsAdded(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points نقطة',
      one: '+نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String loyaltyPointsRemoved(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '-$points نقطة',
      one: '-نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get loyaltyTxThisStay => 'هذه الإقامة';

  @override
  String get loyaltyTxEarnLabel => 'مكتسبة';

  @override
  String get loyaltyTxRedeemLabel => 'مُستبدلة';

  @override
  String get loyaltyTxReverseLabel => 'معكوسة';

  @override
  String get loyaltyTxAdjustLabel => 'تسوية';

  @override
  String get loyaltyTxExpireLabel => 'منتهية';

  @override
  String get loyaltyRedeemCta => 'استبدل النقاط';

  @override
  String get loyaltyRedeemTitle => 'استبدال النقاط';

  @override
  String get loyaltyRedeemSubmitCta => 'استبدال';

  @override
  String get loyaltyRedeemingCta => 'جارٍ الاستبدال…';

  @override
  String get loyaltyRedeemAmountLabel => 'النقاط المراد استبدالها';

  @override
  String get loyaltyRedeemNote =>
      'تُستبدل النقاط مقابل هذا الحجز. تؤكد مجموعة الفنادق القيمة النهائية.';

  @override
  String loyaltyRedeemMax(int points) {
    return 'استخدم الحد الأقصى ($points)';
  }

  @override
  String get loyaltyRedeemedTitle => 'تم استبدال النقاط';

  @override
  String loyaltyRedeemedBody(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'تم استبدال $points نقطة مقابل هذا الحجز.',
      one: 'تم استبدال نقطة واحدة مقابل هذا الحجز.',
    );
    return '$_temp0';
  }

  @override
  String loyaltyRedeemedValueNote(String value, String currency) {
    return 'هذا يعادل نحو $value $currency خصماً على هذا الحجز.';
  }

  @override
  String get loyaltyRedeemNotEligibleTitle => 'لا يمكن الاستبدال على هذا الحجز';

  @override
  String get loyaltyRedeemNotEligibleBody =>
      'لا يمكن استبدال النقاط إلا مقابل حجز نشط.';

  @override
  String get loyaltyAlreadyRedeemedTitle => 'مُستبدلة بالفعل';

  @override
  String get loyaltyAlreadyRedeemedBody => 'سبق استبدال نقاط مقابل هذا الحجز.';

  @override
  String get loyaltyAlreadyRedeemedDifferentBody =>
      'سبق استبدال عدد مختلف من النقاط مقابل هذا الحجز.';

  @override
  String get loyaltyInsufficientTitle => 'النقاط غير كافية';

  @override
  String get loyaltyInsufficientBody => 'ليس لديك نقاط كافية لهذا المبلغ.';

  @override
  String get loyaltyInvalidAmountBody => 'اختر عدد النقاط المراد استبدالها.';

  @override
  String get reviewFormTitle => 'أضف تقييماً';

  @override
  String get reviewFormPrompt => 'كيف كانت إقامتك؟';

  @override
  String get reviewResultTitle => 'تقييمك';

  @override
  String get reviewProcessingTitle => 'جارٍ إرسال تقييمك';

  @override
  String get reviewProcessingBody => 'جارٍ إرسال تقييمك…';

  @override
  String get reviewDoNotClose =>
      'لن يستغرق هذا سوى لحظة. من فضلك لا تغلق التطبيق.';

  @override
  String get reviewRatingRequired => 'اختر تقييماً من 1 إلى 5 نجوم.';

  @override
  String reviewStarsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجوم',
      one: 'نجمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewCategoriesHeading => 'قيّم تفاصيل إقامتك';

  @override
  String get reviewCategoriesHint => 'اختياري — قيّم ما يهمّك منها.';

  @override
  String get reviewTextLabel => 'تقييمك (اختياري)';

  @override
  String get reviewTextHint => 'أخبر النزلاء الآخرين عن إقامتك';

  @override
  String get reviewSubmitCta => 'إرسال التقييم';

  @override
  String get reviewSubmittingCta => 'جارٍ الإرسال…';

  @override
  String get reviewYourRatingLabel => 'تقييمك';

  @override
  String get reviewBackToReservation => 'العودة إلى الحجز';

  @override
  String get reviewUnavailableTitle => 'التقييمات غير متاحة';

  @override
  String get reviewNotEligibleTitle => 'لا يمكنك تقييم هذه الإقامة';

  @override
  String get reviewNotEligibleBody => 'تُفتح التقييمات بعد اكتمال إقامتك.';

  @override
  String get reviewSubmittedTitle => 'شكراً لتقييمك';

  @override
  String get reviewPublishedBody => 'تم نشر تقييمك.';

  @override
  String get reviewPendingModerationBody =>
      'تم استلام تقييمك وهو قيد المراجعة السريعة من فريقنا قبل نشره.';

  @override
  String get reviewAlreadyTitle => 'لقد قيّمت هذه الإقامة بالفعل';

  @override
  String get reviewAlreadyBody =>
      'تقييم واحد لكل إقامة. يظهر تقييمك الحالي أدناه.';

  @override
  String get reviewRejectedTitle => 'لم يُنشر هذا التقييم';

  @override
  String get reviewRejectedBody => 'لم يجتز تقييمك مراجعتنا ولم يُنشر.';

  @override
  String get reviewInvalidRatingTitle => 'التقييم خارج النطاق';

  @override
  String get reviewInvalidRatingBody => 'يجب أن يكون التقييم بين 1 و5 نجوم.';

  @override
  String get reviewFailedTitle => 'تعذّر إرسال تقييمك';

  @override
  String get reviewStatusPending => 'قيد المراجعة';

  @override
  String get reviewStatusPublished => 'منشور';

  @override
  String get reviewStatusRejected => 'غير منشور';

  @override
  String get serviceReviewFormTitle => 'قيّم هذه الخدمة';

  @override
  String get serviceReviewFormPrompt => 'كيف كانت هذه الخدمة؟';

  @override
  String get serviceReviewResultTitle => 'تقييمك للخدمة';

  @override
  String get serviceReviewNotEligibleTitle => 'لا يمكنك تقييم هذه الخدمة بعد';

  @override
  String get serviceReviewNotEligibleBody =>
      'تُفتح التقييمات بعد تسليم الخدمة.';

  @override
  String get serviceReviewTextHint => 'أخبر النزلاء الآخرين عن هذه الخدمة';

  @override
  String hotelDetailStarRating(int count) {
    return 'فندق $count نجوم';
  }

  @override
  String get hotelDetailReviewsHeading => 'التقييم والمراجعات';

  @override
  String get hotelInfoRoomTypesLabel => 'أنواع الغرف';

  @override
  String get hotelInfoCountryLabel => 'الدولة';

  @override
  String get hotelInfoGuestsLabel => 'الضيوف';

  @override
  String get hotelInfoClassificationLabel => 'التصنيف';

  @override
  String get hotelInfoCheckInLabel => 'تسجيل دخول';

  @override
  String get hotelInfoCheckOutLabel => 'تسجيل خروج';

  @override
  String hotelTimeOfDay(String time, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'am': 'صباحًا',
      'noon': 'ظهرًا',
      'other': 'مساءً',
    });
    return '$time $_temp0';
  }

  @override
  String get hotelInfoRoomsLabel => 'عدد الغرف';

  @override
  String hotelRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غرفة',
      few: '$count غرف',
      two: 'غرفتان',
      one: 'غرفة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get hotelInfoSuitableForLabel => 'مناسب لـ';

  @override
  String get hotelLocationHeading => 'الموقع';

  @override
  String get hotelShare => 'مشاركة';

  @override
  String get hotelShareCopied => 'تم نسخ بيانات الفندق';

  @override
  String get hotelFavoriteAdd => 'أضف إلى المفضلة';

  @override
  String get hotelFavoriteRemove => 'إزالة من المفضلة';

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get favoritesBannerTitle => 'غرفك وفنادقك المحفوظة';

  @override
  String get favoritesBannerBody =>
      'تظهر هنا الغرف والفنادق التي حفظتها بالضغط على القلب. اضغط على أي منها لفتحه، أو على القلب لإزالته.';

  @override
  String get favoritesEmptyTitle => 'لا توجد عناصر مفضلة بعد';

  @override
  String get favoritesEmptyBody =>
      'اضغط على القلب في صفحة أي غرفة أو فندق لحفظها هنا.';

  @override
  String get favoritesBrowse => 'تصفح الفنادق';

  @override
  String get favoritesHotelUnavailable => 'هذا الفندق غير متاح حاليًا';

  @override
  String get favoriteSavedSnack => 'تم حفظ الفندق في المفضلة';

  @override
  String get favoriteRemovedSnack => 'تمت إزالة الفندق من المفضلة';

  @override
  String get favoriteViewAction => 'عرض';

  @override
  String get favoriteUndoAction => 'تراجع';

  @override
  String get favoritesRoomsSection => 'الغرف';

  @override
  String get favoritesHotelsSection => 'الفنادق';

  @override
  String get favoriteRoomSavedSnack => 'تم حفظ الغرفة في المفضلة';

  @override
  String get favoriteRoomRemovedSnack => 'تمت إزالة الغرفة من المفضلة';

  @override
  String get roomFavoriteAdd => 'حفظ الغرفة في المفضلة';

  @override
  String get roomFavoriteRemove => 'إزالة الغرفة من المفضلة';

  @override
  String get roomDetailNeedsDatesTitle => 'اختر تواريخ إقامتك';

  @override
  String get roomDetailNeedsDatesBody =>
      'حدّد تاريخي الوصول والمغادرة لعرض سعر هذه الغرفة وتوفرها.';

  @override
  String get roomDetailChooseDates => 'اختيار التواريخ';

  @override
  String get hotelLocationMapSemantics => 'موقع الفندق على الخريطة';

  @override
  String get hotelLocationMapOpenHint => 'اضغط لفتح الخريطة كاملة';

  @override
  String get mapAttribution => '© مساهمو OpenStreetMap';

  @override
  String hotelNearbyPlace(String place, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$place $_temp0';
  }

  @override
  String hotelNearbyPlaceKm(String place, String distance) {
    return '$place $distance كم';
  }

  @override
  String hotelNearbyPlaceMeters(String place, String distance) {
    return '$place $distance م';
  }

  @override
  String get hotelWhyChooseHeading => 'لماذا تختار هذا الفندق؟';

  @override
  String get hotelDetailAmenitiesSubtitle =>
      'خدمات مصممة لراحة النزلاء على مدار الساعة';

  @override
  String get hotelRoomsHeading => 'الغرف المتاحة';

  @override
  String get hotelRoomsSubtitle =>
      'اختر الغرفة المناسبة لرحلتك واستمتع بتجربة إقامة راقية';

  @override
  String get hotelRoomsCta => 'عرض الغرف المتاحة';

  @override
  String get hotelReviewsSubtitle =>
      'تقييمات النزلاء تعكس جودة الخدمة والراحة خلال الإقامة';

  @override
  String get hotelOverallRating => 'تقييم عام';

  @override
  String get hotelPriceFromLabel => 'ابتداءً من';

  @override
  String get roomSpecArea => 'مساحة الغرفة';

  @override
  String get roomSpecGuests => 'عدد النزلاء';

  @override
  String get roomSpecBed => 'نوع السرير';

  @override
  String get roomSpecView => 'الإطلالة';

  @override
  String get roomBookingDetailsHeading => 'تفاصيل حجزك';

  @override
  String get roomStayDuration => 'المدة';

  @override
  String get roomStayDates => 'التاريخ';

  @override
  String get roomStayGuests => 'النزلاء';

  @override
  String get roomNightlyPriceLabel => 'سعر الغرفة';

  @override
  String get roomTotalLabel => 'الإجمالي';

  @override
  String get roomIncludedHeading => 'السعر يشمل';

  @override
  String get roomAboutHeading => 'عن الغرفة';

  @override
  String get roomPoliciesHeading => 'السياسات';

  @override
  String get roomCurrentPrice => 'السعر الحالي';

  @override
  String get commonShowMore => 'عرض المزيد';

  @override
  String get commonShowLess => 'عرض أقل';

  @override
  String get bookingsPillCurrent => 'الحالية';

  @override
  String get bookingsPillUpcoming => 'القادمة';

  @override
  String get bookingsPillPast => 'السابقة';

  @override
  String get bookingsPastTitle => 'إقامات سابقة';

  @override
  String get bookingsSectionOngoingStay => 'إقامة جارية';

  @override
  String get bookingsSectionUpcoming => 'حجوزات قادمة';

  @override
  String get bookingsEmptyTitle => 'لا توجد حجوزات';

  @override
  String get bookingsEmptyBody => 'ستظهر حجوزاتك هنا بمجرد إتمام أول حجز.';

  @override
  String get bookingStatusPending => 'قيد الانتظار';

  @override
  String get bookingStatusConfirmed => 'مؤكد';

  @override
  String get bookingStatusCheckedIn => 'تم تسجيل الدخول';

  @override
  String get bookingStatusCompleted => 'مكتملة';

  @override
  String get bookingStatusCancelled => 'ملغاة';

  @override
  String get bookingDetailTitle => 'تفاصيل الحجز';

  @override
  String get bookingPaymentStatusHeading => 'حالة الدفع';

  @override
  String get bookingCancellationPolicyHeading => 'سياسة الإلغاء';

  @override
  String get bookingCancellationPolicyBody =>
      'إلغاء مجاني حتى 24 ساعة قبل الوصول. بعدها يُخصم مبلغ التأمين.';

  @override
  String get bookingPendingRowTitle => 'بانتظار إتمام الدفع';

  @override
  String get bookingPendingRowSubtitle => 'لم يكتمل';

  @override
  String get bookingAutoCancelRowTitle => 'يُلغى الحجز تلقائياً خلال 30 دقيقة';

  @override
  String get bookingRoomHeldRowTitle => 'الغرفة محجوزة مؤقتاً';

  @override
  String get bookingRoomHeldRowSubtitle => 'غير مؤكدة';

  @override
  String get bookingDepositHeldRowTitle => 'تم حجز مبلغ التأمين';

  @override
  String get bookingDepositHeldRowSubtitle => 'دون خصم فعلي';

  @override
  String get bookingDeductedAtCheckinRowTitle => 'يُخصم عند تسجيل الدخول';

  @override
  String get bookingExtrasChargedOnceRowTitle =>
      'تُجمع المصاريف الإضافية عند المغادرة';

  @override
  String get bookingExtrasChargedOnceRowSubtitle => 'دفعة واحدة';

  @override
  String get bookingIdentityVerifiedRowTitle => 'تم التحقق من هويتك';

  @override
  String get bookingIdentityVerifiedRowSubtitle => 'مكتمل';

  @override
  String get bookingCheckInAvailableRowTitle => 'تسجيل الدخول متاح من';

  @override
  String get bookingDepositAmountHeldRowTitle => 'مبلغ التأمين محجوز';

  @override
  String get bookingOngoingStayRowTitle => 'إقامة جارية';

  @override
  String bookingRoomLabel(String number) {
    return 'غرفة $number';
  }

  @override
  String get bookingDepartureRowTitle => 'المغادرة';

  @override
  String get bookingExtraChargesRowTitle => 'المصاريف الإضافية';

  @override
  String get bookingCancelledRowTitle => 'ألغي الحجز';

  @override
  String get bookingDepositRefundRowTitle => 'استرداد مبلغ التأمين';

  @override
  String get bookingDepositRefundRowSubtitle => 'خلال 3 أيام عمل';

  @override
  String get bookingCancellationFeeRowTitle => 'رسوم الإلغاء';

  @override
  String get bookingCancellationFeeNone => 'لا توجد';

  @override
  String get bookingDepositNotRefunded =>
      'سعر غير قابل للاسترداد — لا يوجد استرداد';

  @override
  String get bookingStayEndedRowTitle => 'انتهت الإقامة';

  @override
  String get bookingTotalPaidRowTitle => 'الإجمالي المدفوع';

  @override
  String get bookingInvoiceReadyRowTitle => 'الفاتورة الإلكترونية';

  @override
  String get bookingInvoiceReadyRowSubtitle => 'جاهزة';

  @override
  String get bookingCtaContinuePayment => 'متابعة الدفع';

  @override
  String get bookingCtaCancelReservation => 'إلغاء الحجز';

  @override
  String get bookingCtaVerifyIdentity => 'التحقق من الهوية';

  @override
  String get bookingCtaDigitalCheckIn => 'تسجيل الدخول الرقمي';

  @override
  String get bookingCtaMyCurrentStay => 'إقامتي الحالية';

  @override
  String get bookingCtaShowAccessCode => 'عرض رمز الدخول';

  @override
  String get bookingCtaBookAgain => 'احجز مرة أخرى';

  @override
  String get bookingCtaViewInvoice => 'عرض الفاتورة';

  @override
  String get bookingCancelConfirmTitle => 'إلغاء الحجز؟';

  @override
  String get bookingCancelFullRefundBody =>
      'الإلغاء مجاني وسيُفرج عن مبلغ التأمين بالكامل.';

  @override
  String get bookingCancelNoRefundBody =>
      'لن يُسترد مبلغ التأمين عند إلغاء هذا الحجز.';

  @override
  String policyFreeUntil(String date) {
    return 'إلغاء مجاني مع استرداد كامل حتى $date. بعدها لا يمكن الإلغاء.';
  }

  @override
  String get policyWindowClosed =>
      'انتهت فترة الإلغاء المجاني، ولم يعد بالإمكان إلغاء هذا الحجز.';

  @override
  String get policyNonRefundable =>
      'هذا السعر غير قابل للاسترداد ولا يمكن إلغاؤه.';

  @override
  String get policyStayStarted => 'لا يمكن إلغاء الحجز بعد بدء الإقامة.';

  @override
  String policyGeneral(int hours) {
    return 'الأسعار القابلة للاسترداد يمكن إلغاؤها مجاناً مع استرداد كامل خلال $hours ساعة من الحجز، أو حتى موعد تسجيل الدخول إن كان أقرب. بعدها لا يمكن الإلغاء. الأسعار غير القابلة للاسترداد لا يمكن إلغاؤها.';
  }

  @override
  String get cancelNotAllowedError =>
      'لم يعد بالإمكان إلغاء هذا الحجز وفق سياسة الإلغاء.';

  @override
  String get cancelRefundFailedError =>
      'تعذّر تحرير مبلغ التأمين حالياً، ولم يُلغَ الحجز. حاول مرة أخرى.';

  @override
  String get bookingCancelConfirmBody =>
      'لا يمكن التراجع عن هذا الإجراء. سيُسترد مبلغ التأمين وفق سياسة الإلغاء.';

  @override
  String get bookingCancelKeepCta => 'تراجع';

  @override
  String get bookingCancelConfirmCta => 'تأكيد الإلغاء';

  @override
  String get bookingNotFoundTitle => 'الحجز غير موجود';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountPrivacyNoteBody =>
      'تُحفظ صور هويتك بشكل آمن وتُحذف تلقائياً بعد انتهاء إقامتك.';

  @override
  String get profilePersonalInfoTitle => 'بياناتي';

  @override
  String get profilePersonalInfoBannerTitle => 'بياناتك الشخصية';

  @override
  String get profilePersonalInfoBannerBody =>
      'تُستخدم هذه البيانات في الحجز والفاتورة. لتعديل الاسم أو رقم الهوية تواصل مع الاستقبال.';

  @override
  String get profileNameLabel => 'الاسم';

  @override
  String get profilePhoneLabel => 'رقم الجوال';

  @override
  String get profileEmailLabel => 'البريد الإلكتروني';

  @override
  String get profileEmailAdd => 'إضافة';

  @override
  String get profileVerifiedIdentityLabel => 'هوية موثّقة';

  @override
  String get profileVerified => 'موثّق';

  @override
  String get profileNotVerified => 'غير موثّق بعد';

  @override
  String get profileSaveChanges => 'حفظ التعديلات';

  @override
  String get profileSave => 'حفظ';

  @override
  String get profileDone => 'تم';

  @override
  String get profileSaved => 'تم حفظ التعديلات.';

  @override
  String get profilePreferencesTitle => 'تفضيلاتي';

  @override
  String get profilePreferencesBannerTitle => 'تفضيلات الإقامة';

  @override
  String get profilePreferencesBannerBody =>
      'نستخدمها لتجهيز غرفتك مسبقاً في كل فنادق المجموعة.';

  @override
  String get profilePrefRoomType => 'نوع الغرفة';

  @override
  String get profilePrefHighFloor => 'دور مرتفع';

  @override
  String get profilePrefExtraPillows => 'وسائد إضافية';

  @override
  String get profilePrefLanguage => 'لغة التطبيق';

  @override
  String get profilePrefNotifications => 'الإشعارات';

  @override
  String get profilePrefOn => 'مفعّل';

  @override
  String get profilePrefOff => 'غير مفعّل';

  @override
  String get profilePrefOnFeminine => 'مفعّلة';

  @override
  String get profilePrefOffFeminine => 'متوقفة';

  @override
  String get profilePrivacyBannerTitle => 'كيف نستخدم بياناتك';

  @override
  String get profilePrivacyBannerBody =>
      'تُحفظ صور هويتك مشفّرة وتُحذف تلقائياً بعد انتهاء إقامتك. لا تُشارك مع أطراف خارجية.';

  @override
  String get profilePrivacyIdPhotos => 'صور الهوية';

  @override
  String get profilePrivacyIdPhotosValue => 'تُحذف بعد المغادرة';

  @override
  String get profileIdentityDeleteAfterCheckout =>
      'حذف صور هويتي بعد المغادرة (افتراضي)';

  @override
  String get profileIdentityKeepForFuture => 'الاحتفاظ بها لحجوزاتي القادمة';

  @override
  String get profileIdentityKeptValue => 'محفوظة لحجوزاتك القادمة';

  @override
  String profileIdentityHotelCopyNote(int days) {
    return 'يحتفظ الفندق بنسخة وثيقة الإقامة $days يوماً بعد المغادرة، ثم تُحذف تلقائياً.';
  }

  @override
  String get profilePrivacyPaymentData => 'بيانات الدفع';

  @override
  String get profilePrivacyPaymentDataValue => 'لا تُحفظ';

  @override
  String get profilePrivacyStayHistory => 'سجل الإقامات';

  @override
  String get profileRequestDeletion => 'طلب حذف بياناتي';

  @override
  String get profileDeletionConfirmTitle => 'حذف بياناتك الشخصية؟';

  @override
  String get profileDeletionConfirmBody =>
      'سيصل طلبك إلى فريق الفندق ليتواصل معك ويُتمّ الحذف. لا يُلغي الطلب حجوزاتك الحالية.';

  @override
  String get profileDeletionConfirmCta => 'إرسال الطلب';

  @override
  String get profileDeletionRequestedTitle => 'تم استلام طلب حذف بياناتك';

  @override
  String profileDeletionRequestedBody(String date) {
    return 'أرسلت الطلب في $date. سيتواصل معك فريق الفندق لإتمامه.';
  }

  @override
  String get profileDeletionRequestedCta => 'تم إرسال الطلب';

  @override
  String get profileSupportTitle => 'المساعدة';

  @override
  String get profileSupportBannerTitle => 'كيف نساعدك؟';

  @override
  String get profileSupportBannerBody =>
      'فريق الدعم متاح على مدار الساعة، ويمكنك التواصل مع فندق إقامتك مباشرة.';

  @override
  String get profileFaq => 'الأسئلة الشائعة';

  @override
  String get profileFaqEmptyTitle => 'لا توجد أسئلة شائعة بعد';

  @override
  String get profileFaqEmptyBody => 'تواصل مع فندقك مباشرة لأي استفسار.';

  @override
  String get profileDuringStayOnly => 'متاح أثناء الإقامة';

  @override
  String get profileContactReceptionNoStay => 'متاح عند وجود حجز';

  @override
  String get profileLogoutConfirmTitle => 'تسجيل الخروج من حسابك؟';

  @override
  String get profileLogoutConfirmBody =>
      'ستحتاج إلى رمز تحقق جديد عند الدخول مرة أخرى. حجوزاتك وإقامتك الحالية لن تتأثر.';

  @override
  String get accountLoyaltyProgramTitle => 'برنامج الولاء';

  @override
  String get accountLoyaltyPointsSuffix => 'نقطة';

  @override
  String get accountLoyaltyDescription =>
      'نقاطك تُجمع من كل فنادق المجموعة وتُصرف في أي فرع.';

  @override
  String get accountLoyaltyPerNightLabel => 'لكل ليلة';

  @override
  String get accountTrustedGuestTitle => 'نزيل موثوق';

  @override
  String get accountTrustedGuestBody =>
      'لن يُطلب منك رفع صور الهوية مرة أخرى في أي فندق آخر بالمجموعة.';

  @override
  String get accountPreviousStaysLabel => 'إقامات سابقة';

  @override
  String get accountPreferencesLabel => 'تفضيلاتي';

  @override
  String get accountPreferencesEmpty => 'لم تُحدد بعد';

  @override
  String get accountPrivacyLabel => 'الخصوصية وبياناتي';

  @override
  String get accountHelpSupportLabel => 'المساعدة والدعم';

  @override
  String get stayHomeTitle => 'إقامتك الحالية';

  @override
  String get stayHomeRoomLabel => 'غرفتك';

  @override
  String stayHomeHotelUntil(String hotel, String date) {
    return '$hotel · حتى $date';
  }

  @override
  String bookingRoomNumber(String number) {
    return 'غرفة $number';
  }

  @override
  String get stayHomeServicesHeading => 'الخدمات';

  @override
  String get stayHomeRoomService => 'خدمة الغرف';

  @override
  String get stayHomeRoomCleaning => 'تنظيف الغرفة';

  @override
  String get stayHomeExtendStay => 'تمديد الإقامة';

  @override
  String get stayHomeReportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get stayHomeExtraCharges => 'مصاريف إضافية';

  @override
  String get stayHomeExtraChargesNote => 'تُخصم تلقائياً عند المغادرة';

  @override
  String get stayHomeNoActiveStayTitle => 'لا توجد إقامة حالية';

  @override
  String get stayHomeNoActiveStayBody =>
      'بمجرد تسجيل دخولك، ستظهر هنا غرفتك ورمز الدخول والخدمات.';

  @override
  String get guestSignInRequiredTitle => 'سجّل الدخول للمتابعة';

  @override
  String get guestSignInBookingsBody => 'سجّل دخولك لعرض حجوزاتك ومتابعتها.';

  @override
  String get guestSignInServicesBody =>
      'سجّل دخولك للوصول إلى خدمات إقامتك ومفتاح غرفتك وطلباتك.';

  @override
  String get guestSignInAction => 'تسجيل الدخول';

  @override
  String get extendStayTitle => 'تمديد الإقامة';

  @override
  String get extendStayNewCheckOutLabel => 'تاريخ المغادرة الجديد';

  @override
  String get extendStayNightsAddedLabel => 'عدد الليالي المضافة';

  @override
  String get extendStayCta => 'تأكيد التمديد';

  @override
  String get extendStaySuccessTitle => 'تم تمديد الإقامة';

  @override
  String extendStaySuccessBody(String date, String amount) {
    return 'تاريخ مغادرتك الآن $date. تمت إضافة $amount إلى فاتورتك.';
  }

  @override
  String get extendStayNotEligible =>
      'تمديد الإقامة متاح فقط أثناء إقامتك الحالية.';

  @override
  String get reportProblemTitle => 'الإبلاغ عن مشكلة';

  @override
  String get reportProblemCategoryHeading => 'ما نوع المشكلة؟';

  @override
  String get reportProblemCategoryBody =>
      'اختر التصنيف الأقرب حتى يصل البلاغ للفريق المختص مباشرة.';

  @override
  String get reportCategoryAcHeating => 'تكييف أو تدفئة';

  @override
  String get reportCategoryPlumbingWater => 'سباكة أو مياه';

  @override
  String get reportCategoryElectricityLighting => 'كهرباء وإضاءة';

  @override
  String get reportCategoryRoomCleanliness => 'نظافة الغرفة';

  @override
  String get reportCategoryInternetWifi => 'إنترنت وواي فاي';

  @override
  String get reportCategoryNoiseDisturbance => 'ضوضاء أو إزعاج';

  @override
  String get reportProblemContinueCta => 'متابعة';

  @override
  String get reportDescriptionTitle => 'وصف المشكلة';

  @override
  String get reportUrgencyHeading => 'ما مدى إلحاح المشكلة؟';

  @override
  String get reportUrgencyNormal => 'عادي';

  @override
  String get reportUrgencyImportant => 'مهم';

  @override
  String get reportUrgencyUrgent => 'عاجل';

  @override
  String get reportNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get reportNotesHint =>
      'أضِف أي تفاصيل تساعد فريقنا على الاستجابة بسرعة';

  @override
  String get reportNoFeeTitle => 'بدون رسوم';

  @override
  String get reportNoFeeBody =>
      'الإبلاغ عن مشكلة مجاني ولن يُضاف إلى فاتورتك أبدًا.';

  @override
  String get reportSubmitCta => 'إرسال البلاغ';

  @override
  String get reportSubmittingCta => 'جارٍ الإرسال…';

  @override
  String get reportFailedTitle => 'تعذّر إرسال بلاغك';

  @override
  String get reportSubmittedTitle => 'تم الإرسال';

  @override
  String get reportSubmittedBannerTitle => 'وصل بلاغك للاستقبال';

  @override
  String reportSubmittedBannerBody(String reference) {
    return 'رقم البلاغ $reference. سيتواصل معك فريق الاستقبال قريبًا، ويمكنك متابعة الحالة في أي وقت.';
  }

  @override
  String get reportTrackCta => 'تتبّع البلاغ';

  @override
  String get reportDetailTitle => 'تفاصيل البلاغ';

  @override
  String get reportDetailBody => 'تم استلام بلاغك وفريقنا يتابعه الآن.';

  @override
  String get reportContactReceptionCta => 'تواصل مع الاستقبال';

  @override
  String get reportStatusOpen => 'مفتوح';

  @override
  String get reportStatusInProgress => 'قيد المعالجة';

  @override
  String get reportStatusResolved => 'تم الحل';

  @override
  String get reportUnavailableTitle => 'تعذّر عرض البلاغات';

  @override
  String get reportNotFoundTitle => 'البلاغ غير موجود';

  @override
  String get myReportsTitle => 'بلاغاتي';

  @override
  String get myReportsIntroBanner => 'تابع حالة كل مشكلة أبلغت عنها.';

  @override
  String get myReportsEmptyTitle => 'لا توجد بلاغات بعد';

  @override
  String get myReportsEmptyBody => 'أبلغ عن مشكلة وستظهر هنا.';

  @override
  String get newReportCta => 'بلاغ جديد';

  @override
  String get bookingLoyaltyWorth => 'يعادل';

  @override
  String get bookingLoyaltyRedeem => 'استبدال';

  @override
  String get bookingLoyaltyPointsField => 'قيمة النقاط';

  @override
  String get bookingLoyaltyPointsHint => 'ادخل قيمة النقاط';

  @override
  String get bookingLoyaltyDiscountField => 'قيمة الخصم';

  @override
  String get bookingLoyaltyApply => 'تطبيق';

  @override
  String get bookingLoyaltyRemove => 'إزالة';

  @override
  String bookingLoyaltyMaxHint(String points) {
    return 'حتى $points نقطة لهذا الحجز';
  }

  @override
  String get bookingLoyaltyAppliedNote => 'تُستبدل عند تأكيد الحجز';

  @override
  String get bookingLoyaltyDisabled => 'استبدال النقاط غير متاح حالياً';

  @override
  String get bookingLoyaltyNoPoints => 'لا توجد لديك نقاط قابلة للاستبدال بعد';

  @override
  String get bookingLoyaltyDiscountRow => 'خصم النقاط';

  @override
  String get bookingLoyaltyRedeemFailed =>
      'تعذّر استبدال نقاطك — لم يُخصم أي شيء.';

  @override
  String get loyaltyAutoEarnTitle => 'نقاطك في الطريق';

  @override
  String get loyaltyAutoEarnBody =>
      'تُضاف نقاط هذه الإقامة إلى رصيدك تلقائياً عند اكتمالها.';

  @override
  String bookingCheckInFrom(String time) {
    return 'من $time';
  }

  @override
  String roomPolicyCheckInBody(String time) {
    return 'من الساعة $time';
  }

  @override
  String roomPolicyCheckOutBody(String time) {
    return 'حتى الساعة $time';
  }

  @override
  String get roomTaxesLabel => 'الضرائب';

  @override
  String get roomPriceIncludedValue => 'شاملة';

  @override
  String get roomFinalPriceNote => 'السعر النهائي لا توجد رسوم إضافية';

  @override
  String get roomPolicyCheckInTitle => 'تسجيل الدخول';

  @override
  String get roomPolicyCheckOutTitle => 'تسجيل الخروج';

  @override
  String roomMaxAdultsReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الحد الأقصى لهذه الغرفة هو $count بالغين',
      two: 'الحد الأقصى لهذه الغرفة هو 2 بالغين',
      one: 'الحد الأقصى لهذه الغرفة هو بالغ واحد',
    );
    return '$_temp0';
  }

  @override
  String roomMaxGuestsReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الحد الأقصى لهذه الغرفة هو $count ضيوف',
      one: 'الحد الأقصى لهذه الغرفة هو ضيف واحد',
    );
    return '$_temp0';
  }

  @override
  String get roomCapacityChangeRoomHint => 'لإضافة ضيوف أكثر، اختر غرفة أكبر.';
}
