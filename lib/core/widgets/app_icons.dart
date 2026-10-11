import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Centralised icon vocabulary for the Guest App.
///
/// The Figma uses the **Iconsax** set ("Hicon / Bold" and "Hicon / Linear" in
/// the `.fig` component tree — e.g. `Hicon / Bold / Home 1`, `… / Ticket 1`,
/// `… / Category`, `… / Profile 1`, `… / Star 1`, `… / Shield Tick`,
/// `… / Danger Triangle`, `… / Information Circle`). `iconsax_plus` bundles that
/// exact set as a font, in a Bold and a Linear (outline) weight.
///
/// Screens reference `AppIcons.<meaning>` — never `IconsaxPlus*` or `Icons.*`
/// directly — so the whole vocabulary can be re-pointed in one file. Bottom-nav
/// destinations get a Linear (unselected) + Bold (selected) pair.
abstract final class AppIcons {
  // ── Navigation / chrome ────────────────────────────────────────────────
  static const IconData back = IconsaxPlusLinear.arrow_left_2;
  static const IconData backRtl = IconsaxPlusLinear.arrow_right_3;
  static const IconData close = IconsaxPlusLinear.close_circle;

  /// The v2 app-bar dismiss ✕ (14px glyph, 1.5 stroke).
  static const IconData dismiss = _Lucide.x;
  static const IconData chevron = IconsaxPlusLinear.arrow_right_3;
  static const IconData chevronRtl = IconsaxPlusLinear.arrow_left_2;
  static const IconData notifications = IconsaxPlusLinear.notification;
  static const IconData search = IconsaxPlusLinear.search_normal_1;
  static const IconData filter = IconsaxPlusLinear.filter;
  static const IconData sort = IconsaxPlusLinear.sort;
  static const IconData edit = IconsaxPlusLinear.edit_2;

  // ── Bottom navigation (Linear = unselected, Bold = selected) ───────────
  static const IconData navHome = IconsaxPlusBold.home_2;
  static const IconData navHomeOutline = IconsaxPlusLinear.home_2;
  static const IconData navBookings = IconsaxPlusBold.ticket_star;
  static const IconData navBookingsOutline = IconsaxPlusLinear.ticket_star;
  static const IconData navServices = IconsaxPlusBold.category_2;
  static const IconData navServicesOutline = IconsaxPlusLinear.category_2;
  static const IconData navAccount = IconsaxPlusBold.profile_circle;
  static const IconData navAccountOutline = IconsaxPlusLinear.profile_circle;

  // ── v2 tab bar (Figma `Tab Bar`: Hicon Linear = unselected, Bold =
  // selected — mapped to the same-named Iconsax glyphs). Separate from the
  // `nav*` set above, which other screens reuse as content icons.
  static const IconData tabHome = IconsaxPlusBold.home_1;
  static const IconData tabHomeOutline = IconsaxPlusLinear.home_1;
  static const IconData tabBookings = IconsaxPlusBold.ticket;
  static const IconData tabBookingsOutline = IconsaxPlusLinear.ticket;
  static const IconData tabServices = IconsaxPlusBold.category;
  static const IconData tabServicesOutline = IconsaxPlusLinear.category;
  static const IconData tabAccount = IconsaxPlusBold.profile;
  static const IconData tabAccountOutline = IconsaxPlusLinear.profile;

  // ── v2 Home (`HOME_Default`) ───────────────────────────────────────────
  /// Header bell (Hicon `Notification 1` — a bell; Iconsax's `notification_1`
  /// is a dotted square, so the plain `notification` bell is the match).
  static const IconData homeNotifications = IconsaxPlusLinear.notification;

  /// Hotel-card "open" arrow (Hicon Bold `Up 1` — a plain stemmed arrow —
  /// turned to point forward). Iconsax's Bold arrows are filled discs, so the
  /// stroked Linear arrow is the shape match.
  static IconData homeCardArrowFor(TextDirection direction) =>
      direction == TextDirection.rtl
      ? IconsaxPlusLinear.arrow_left
      : IconsaxPlusLinear.arrow_right;

  // ── v2 room detail (Premium) — room amenity glyphs ──────────────────────
  static const IconData coffee = IconsaxPlusLinear.coffee;
  static const IconData airConditioning = IconsaxPlusLinear.wind;
  static const IconData cityView = IconsaxPlusLinear.buildings;
  static const IconData balcony = IconsaxPlusLinear.sun_1;

  /// Hotel-card rating star (Hicon Bold `Star 1`).
  static const IconData homeRatingStar = IconsaxPlusBold.star_1;

  // ── Status / feedback ─────────────────────────────────────────────────
  static const IconData success = IconsaxPlusBold.tick_circle;
  static const IconData check = IconsaxPlusLinear.tick_square;
  static const IconData error = IconsaxPlusBold.danger;
  static const IconData warning = IconsaxPlusBold.warning_2;
  static const IconData info = IconsaxPlusBold.info_circle;
  /// v2 `Message` glyph ("Information Circle", 1.5 stroke).
  static const IconData infoOutline = _Lucide.info;
  static const IconData successOutline = IconsaxPlusLinear.tick_circle;
  /// An unselected option (radio-style row).
  static const IconData radioOff = IconsaxPlusLinear.record;
  static const IconData errorOutline = _Lucide.circleAlert;
  /// `Hicon / Linear / Shield Tick` — the trusted-guest card glyph.
  static const IconData shieldTickOutline = IconsaxPlusLinear.shield_tick;
  static const IconData pending = IconsaxPlusLinear.clock;
  static const IconData locked = IconsaxPlusLinear.lock_1;
  static const IconData time = IconsaxPlusLinear.clock_1;
  static const IconData shieldCheck = IconsaxPlusBold.shield_tick;

  // ── Domain ────────────────────────────────────────────────────────────
  static const IconData hotel = IconsaxPlusLinear.buildings_2;
  static const IconData room = IconsaxPlusLinear.building_3;
  static const IconData bed = IconsaxPlusLinear.building_3;
  static const IconData location = IconsaxPlusLinear.location;
  static const IconData guests = IconsaxPlusLinear.profile;
  static const IconData area = IconsaxPlusLinear.maximize_3;
  static const IconData wifi = IconsaxPlusLinear.wifi;
  static const IconData calendar = IconsaxPlusLinear.calendar_2;
  static const IconData rating = IconsaxPlusBold.star_1;
  static const IconData ratingOutline = IconsaxPlusLinear.star_1;

  /// The flower/sparkle glyph on the `HOTEL_Detail` hero's second circular
  /// button (matches the [rating] pill's mark in the reference screenshot).
  /// No product behaviour is wired to it — see `hotel_detail_page.dart`.
  static const IconData sparkle = IconsaxPlusBold.magic_star;
  static const IconData payment = IconsaxPlusLinear.card;
  static const IconData wallet = IconsaxPlusLinear.wallet_3;
  static const IconData identity = IconsaxPlusLinear.personalcard;
  static const IconData key = IconsaxPlusBold.key_square;
  static const IconData roomService = IconsaxPlusLinear.coffee;
  // STAY_Home tiles (Hicon Linear): Cup · Setting · Message 1 · Alarm.
  static const IconData cleaning = IconsaxPlusLinear.setting_2;
  static const IconData extendStay = IconsaxPlusLinear.clock;
  static const IconData report = IconsaxPlusLinear.message;
  static const IconData checkout = IconsaxPlusLinear.logout;
  static const IconData invoice = IconsaxPlusLinear.receipt_text;
  static const IconData loyalty = IconsaxPlusLinear.medal_star;
  /// `Hicon / Bold / Arrow Swap Horizontal` — points ⇄ discount.
  static const IconData arrowSwap = IconsaxPlusBold.arrow_swap_horizontal;
  static const IconData review = IconsaxPlusLinear.star_1;
  static const IconData camera = IconsaxPlusBold.camera;
  /// `Hicon / Linear / Camera 1` — the identity capture shutter glyph.
  static const IconData cameraLinear = IconsaxPlusLinear.camera;
  static const IconData gallery = IconsaxPlusLinear.gallery;
  static const IconData language = IconsaxPlusLinear.global;
  static const IconData shield = IconsaxPlusBold.shield_tick;
  static const IconData refresh = IconsaxPlusLinear.refresh;
  static const IconData support = IconsaxPlusLinear.messages_2;
  static const IconData privacy = IconsaxPlusLinear.lock_1;
  static const IconData help = IconsaxPlusLinear.message_question;
  static const IconData logout = IconsaxPlusLinear.logout;
  static const IconData phone = IconsaxPlusLinear.call;

  // v2 profile list rows (`PROFILE_*` tiles, Hicon Linear set).
  static const IconData email = IconsaxPlusLinear.sms;
  static const IconData whatsapp = IconsaxPlusLinear.message_text;
  static const IconData website = IconsaxPlusLinear.global;
  static const IconData document = IconsaxPlusLinear.document_text;
  static const IconData profileRow = IconsaxPlusLinear.profile;
  static const IconData settings = IconsaxPlusLinear.setting_2;
  static const IconData ticket = IconsaxPlusLinear.ticket;
  static const IconData faq = IconsaxPlusLinear.message_question;
  static const IconData cancelPolicy = IconsaxPlusLinear.close_circle;
  static const IconData problem = IconsaxPlusLinear.danger;
  static const IconData highFloor = IconsaxPlusLinear.arrow_up_3;
  static const IconData pillow = IconsaxPlusLinear.moon;

  // Report-a-problem categories.
  static const IconData climate = IconsaxPlusLinear.wind_2;
  static const IconData plumbing = IconsaxPlusLinear.drop;
  static const IconData electrical = IconsaxPlusLinear.flash_1;
  static const IconData noise = IconsaxPlusLinear.volume_high;

  // Plain add/remove for the guest stepper — the Figma stepper uses a bare
  // hairline +/−. Kept as Material glyphs (also matched by two widget tests).
  static const IconData add = Icons.add;
  static const IconData remove = Icons.remove;

  // Hotel Detail (`HOTEL_Detail_Premium`). The Figma draws the section glyphs
  // with **Lucide** (layer names `clock-3`, `bed-double`, `users`, `waves`,
  // `plane`, …) at a 1px stroke on 18–20px — Lucide weight 300 (1.5 @ 24) is
  // the matching thickness. The hero controls and map pin are Hicon
  // (Iconsax): `Outline / Heart 3`, `Linear / Location`, lucide `share-2`.
  static const IconData checkInOut = _Lucide.clock3;
  static const IconData detailRooms = _Lucide.bedDouble;
  static const IconData suitableFor = _Lucide.users;
  static const IconData mapPin = IconsaxPlusLinear.location;
  static const IconData favorite = IconsaxPlusLinear.heart;
  static const IconData favoriteActive = IconsaxPlusBold.heart;
  static const IconData share = _Lucide.share2;

  /// Hicon `Linear / Right 1` — the hero's back arrow (`→` in RTL, `←` LTR).
  static IconData heroBackFor(TextDirection direction) =>
      direction == TextDirection.rtl ? _Lucide.arrowRight : _Lucide.arrowLeft;

  /// Glyph for an operator-set icon **key** on a hotel highlight,
  /// nearby place or facility. Supports both the Figma/Lucide keys offered by
  /// the Hotel form and the Keenicons keys offered by the Facility form. The
  /// API stores the selected key; this adapter maps it to the matching bundled
  /// glyph while the widget keeps its Figma size, colour and container.
  /// Unknown or missing keys get [fallback], never an error.
  static IconData forDetailKey(String? key, {IconData fallback = detailCheck}) {
    final String? normalized = _normalizeDetailKey(key);
    return normalized == null
        ? fallback
        : _detailKeyIcons[normalized] ?? fallback;
  }

  /// A hotel facility's glyph: the operator's icon key, else the Figma glyph
  /// for its catalog `key` (the seeded catalog has no icon keys), else a
  /// neutral check.
  static IconData forFacility(String? icon, String key) {
    final IconData fallback = _facilityKeyIcons[key] ?? detailCheck;
    return forDetailKey(icon, fallback: fallback);
  }

  static const IconData detailCheck = _Lucide.circleCheck;

  static const Map<String, IconData> _facilityKeyIcons = <String, IconData>{
    'free_wifi': _Lucide.wifi,
    'breakfast': _Lucide.coffee,
    'parking': _Lucide.carFront,
    'pool': _Lucide.waves,
    'gym': _Lucide.dumbbell,
    'family_rooms': _Lucide.users,
    'airport_shuttle': _Lucide.plane,
    'room_service': _Lucide.utensilsCrossed,
    'air_conditioning': _Lucide.snowflake,
    'restaurant': _Lucide.utensils,
    'spa': _Lucide.flower2,
    'business_center': _Lucide.briefcaseBusiness,
    'reception_24h': _Lucide.headset,
    'daily_housekeeping': _Lucide.sparkles,
    'elevator': _Lucide.arrowUpDown,
    'in_room_safe': _Lucide.shieldCheck,
  };

  /// Fallback glyph for a nearby place's backend `NearbyPlaceCategory`.
  static IconData forNearbyCategory(String? category) =>
      _nearbyCategoryIcons[category] ?? _Lucide.mapPin;

  static const Map<String?, IconData> _nearbyCategoryIcons =
      <String?, IconData>{
        'airport': _Lucide.plane,
        'transport': _Lucide.bus,
        'landmark': _Lucide.landmark,
        'attraction': _Lucide.star,
        'shopping': _Lucide.shoppingBag,
        'dining': _Lucide.utensils,
        'beach': _Lucide.treePalm,
        'business': _Lucide.briefcaseBusiness,
        'health': _Lucide.hospital,
        'worship': _Lucide.building2,
      };

  /// Operator icon keys → Lucide (the keys ARE Lucide names — the dashboard's
  /// `GUEST_DETAIL_ICON_KEYS` were taken from the Figma layers) plus the
  /// facility form's Keenicons names mapped to their Lucide counterpart.
  /// Mirrored in `dashboard/app/utils/guestAppIcons.ts` (the dashboard's icon
  /// picker previews) — change both together.
  static String? _normalizeDetailKey(String? key) {
    final String normalized = key?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return null;
    return normalized.startsWith('ki-') ? normalized.substring(3) : normalized;
  }

  static final Map<String, IconData> _detailKeyIcons = <String, IconData>{
    'waves': _Lucide.waves,
    'utensils': _Lucide.utensils,
    'utensils-crossed': _Lucide.utensilsCrossed,
    'coffee': _Lucide.coffee,
    'wifi': _Lucide.wifi,
    'car-front': _Lucide.carFront,
    'dumbbell': _Lucide.dumbbell,
    'spa': _Lucide.flower2,
    'sparkles': _Lucide.sparkles,
    'headset': _Lucide.headset,
    'snowflake': _Lucide.snowflake,
    'bed-double': _Lucide.bedDouble,
    'users': _Lucide.users,
    'briefcase-business': _Lucide.briefcaseBusiness,
    'shield-check': _Lucide.shieldCheck,
    'plane': _Lucide.plane,
    'map-pin': _Lucide.mapPin,
    'building': _Lucide.building,
    'shopping-bag': _Lucide.shoppingBag,
    'landmark': _Lucide.landmark,
    'train': _Lucide.trainFront,
    'beach': _Lucide.treePalm,
    'pool': _Lucide.waves,
    'restaurant': _Lucide.utensils,
    'garden': _Lucide.treePalm,
    'laundry': _Lucide.washingMachine,
    'shuttle': _Lucide.bus,
    'concierge': _Lucide.conciergeBell,
    'clock': _Lucide.clock3,
    'healthcare': _Lucide.hospital,
    'tv': _Lucide.tv,
    'arrow-up-down': _Lucide.arrowUpDown,
    'moon': _Lucide.moon,
    'wallet': _Lucide.wallet,
    'star': _Lucide.star,
    // FacilityForm's selectable Keenicons keys. Keep this list in sync with
    // dashboard/app/components/FacilityForm.vue so every selected icon is
    // rendered as its corresponding lightweight Lucide glyph here.
    'car': _Lucide.carFront,
    'pulse': _Lucide.activity,
    'ocean': _Lucide.waves,
    'shop': _Lucide.store,
    'home-2': _Lucide.house,
    'thermometer': _Lucide.thermometer,
    'screen': _Lucide.tv,
    'setting': _Lucide.settings,
    'up-down': _Lucide.arrowUpDown,
    'security-user': _Lucide.shieldCheck,
    'notification': _Lucide.bell,
    'office-bag': _Lucide.briefcaseBusiness,
    // Room facilities (Figma ROOM_Detail_Premium).
    'fan': _Lucide.fan,
    'bath': _Lucide.bath,
    'bottle-wine': _Lucide.bottleWine,
    'app-window': _Lucide.appWindow,
    'vault': _Lucide.vault,
    // Facility catalog icons (dashboard FacilityForm, Keenicons names).
    'parking': _Lucide.carFront,
    'gym': _Lucide.dumbbell,
    'bed': _Lucide.bedDouble,
    'air-conditioning': _Lucide.snowflake,
    'washing-machine': _Lucide.washingMachine,
    'elevator': _Lucide.arrowUpDown,
    'security': _Lucide.shieldCheck,
    'bell': _Lucide.conciergeBell,
  };

  /// Direction-aware back glyph — `←` in LTR, `→` in RTL (the Figma Arabic
  /// frames show `→`).
  static IconData backFor(TextDirection direction) =>
      direction == TextDirection.rtl ? backRtl : back;

  /// Direction-aware forward/disclosure chevron.
  static IconData chevronFor(TextDirection direction) =>
      direction == TextDirection.rtl ? chevronRtl : chevron;
}

/// The Lucide glyphs the Hotel Detail uses, at stroke weight 300 (the
/// Figma's 1px line on 18–20px). Declared here against the
/// `lucide_icons_flutter` **font** rather than importing its ~130k-line
/// `lucide_icons.dart`, which every test file would otherwise compile.
/// Code points from that package's `LucideIcons.<name>300`.
abstract final class _Lucide {
  static const IconData activity = IconData(
    57400,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData bell = IconData(57433, fontFamily: _f, fontPackage: _p);
  static const IconData info = IconData(57593, fontFamily: _f, fontPackage: _p);
  static const IconData circleAlert = IconData(
    57463,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData x = IconData(57778, fontFamily: _f, fontPackage: _p);
  static const IconData fan = IconData(58233, fontFamily: _f, fontPackage: _p);
  static const IconData bath = IconData(58027, fontFamily: _f, fontPackage: _p);
  static const IconData bottleWine = IconData(
    59003,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData appWindow = IconData(
    58406,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData vault = IconData(58767, fontFamily: _f, fontPackage: _p);
  static const IconData arrowLeft = IconData(
    57416,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData arrowRight = IconData(
    57417,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData arrowUpDown = IconData(
    58237,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData bedDouble = IconData(
    58050,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData briefcaseBusiness = IconData(
    58837,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData building = IconData(
    57804,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData building2 = IconData(
    58000,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData bus = IconData(57812, fontFamily: _f, fontPackage: _p);
  static const IconData carFront = IconData(
    58621,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData circleCheck = IconData(
    57894,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData clock3 = IconData(
    57936,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData coffee = IconData(
    57494,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData conciergeBell = IconData(
    58232,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData dumbbell = IconData(
    58273,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData flower2 = IconData(
    58068,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData headset = IconData(
    58813,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData house = IconData(
    57589,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData hospital = IconData(
    58840,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData landmark = IconData(
    57914,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData mapPin = IconData(
    57617,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData moon = IconData(57630, fontFamily: _f, fontPackage: _p);
  static const IconData plane = IconData(
    57822,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData share2 = IconData(
    57686,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData settings = IconData(
    57684,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData shieldCheck = IconData(
    57855,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData shoppingBag = IconData(
    57691,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData snowflake = IconData(
    57701,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData store = IconData(
    58340,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData thermometer = IconData(
    57734,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData sparkles = IconData(
    58386,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData star = IconData(57718, fontFamily: _f, fontPackage: _p);
  static const IconData trainFront = IconData(
    58630,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData treePalm = IconData(
    57985,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData tv = IconData(57749, fontFamily: _f, fontPackage: _p);
  static const IconData users = IconData(
    57764,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData utensils = IconData(
    58102,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData utensilsCrossed = IconData(
    58103,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData wallet = IconData(
    57860,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData washingMachine = IconData(
    58768,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData waves = IconData(
    57987,
    fontFamily: _f,
    fontPackage: _p,
  );
  static const IconData wifi = IconData(57774, fontFamily: _f, fontPackage: _p);

  static const String _f = 'Lucide300';
  static const String _p = 'lucide_icons_flutter';
}
