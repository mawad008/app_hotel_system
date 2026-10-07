import 'package:flutter/foundation.dart';

/// Whether a document type needs a photo of its back side.
enum BackImagePolicy {
  none('none'),
  optional('optional'),
  required('required');

  const BackImagePolicy(this.wireValue);

  final String wireValue;

  static BackImagePolicy fromWire(String? value) {
    for (final BackImagePolicy p in BackImagePolicy.values) {
      if (p.wireValue == value) return p;
    }
    return BackImagePolicy.none;
  }
}

/// The identity document the guest explicitly selects. Mirrors Laravel
/// `IdentityDocumentType` — the selection decides which server-side OCR
/// route reads the document (never guessed from the photo).
enum IdentityDocumentType {
  egyptianNationalId('egyptian_national_id', country: 'EGY', defaultBack: BackImagePolicy.required),
  saudiNationalId('saudi_national_id', country: 'SAU', defaultBack: BackImagePolicy.optional),
  saudiIqama('saudi_iqama', country: 'SAU', defaultBack: BackImagePolicy.optional),
  passport('passport', defaultBack: BackImagePolicy.none);

  const IdentityDocumentType(this.wireValue, {this.country, required this.defaultBack});

  final String wireValue;

  /// ISO alpha-3 of the issuing state when the type fixes it.
  final String? country;

  /// Used when the server's document-type catalog can't be loaded.
  final BackImagePolicy defaultBack;

  /// The Egyptian national number encodes the date of birth — the guest isn't
  /// asked for it separately.
  bool get birthDateInNumber => this == IdentityDocumentType.egyptianNationalId;

  /// Printed in Arabic: the name should be typed as on the card.
  bool get arabicDocument => this != IdentityDocumentType.passport;

  static IdentityDocumentType? tryFromWire(String? value) {
    for (final IdentityDocumentType t in IdentityDocumentType.values) {
      if (t.wireValue == value) return t;
    }
    return null;
  }

  static IdentityDocumentType fromWire(String value) =>
      tryFromWire(value) ?? IdentityDocumentType.passport;

  /// Structural check of a typed document number, mirroring the backend's
  /// request validation (digits in any script). Passports: letters/digits.
  bool isPlausibleNumber(String raw) {
    final String v = normalizeDigits(raw).replaceAll(RegExp(r'[\s-]'), '');
    switch (this) {
      case IdentityDocumentType.egyptianNationalId:
        final Match? m = RegExp(r'^([23])(\d{2})(\d{2})(\d{2})(\d{2})\d{5}$').firstMatch(v);
        if (m == null) return false;
        final int year = (m.group(1) == '2' ? 1900 : 2000) + int.parse(m.group(2)!);
        final int month = int.parse(m.group(3)!);
        final int day = int.parse(m.group(4)!);
        final int gov = int.parse(m.group(5)!);
        final DateTime d = DateTime(year, month, day);
        final bool realDate = d.year == year && d.month == month && d.day == day;
        return realDate && !d.isAfter(DateTime.now()) && ((gov >= 1 && gov <= 35) || gov == 88);
      case IdentityDocumentType.saudiNationalId:
        return RegExp(r'^1\d{9}$').hasMatch(v);
      case IdentityDocumentType.saudiIqama:
        return RegExp(r'^2\d{9}$').hasMatch(v);
      case IdentityDocumentType.passport:
        return RegExp(r'^[\p{L}\p{N}]{3,30}$', unicode: true).hasMatch(v);
    }
  }

  /// The birth date encoded in an Egyptian national number, else null.
  DateTime? birthDateFromNumber(String raw) {
    if (!birthDateInNumber || !isPlausibleNumber(raw)) return null;
    final String v = normalizeDigits(raw).replaceAll(RegExp(r'[\s-]'), '');
    final int year = (v[0] == '2' ? 1900 : 2000) + int.parse(v.substring(1, 3));
    return DateTime(year, int.parse(v.substring(3, 5)), int.parse(v.substring(5, 7)));
  }
}

/// Arabic-Indic (٠-٩) and Eastern Arabic (۰-۹) digits → Western.
String normalizeDigits(String value) {
  final StringBuffer out = StringBuffer();
  for (final int unit in value.runes) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      out.writeCharCode(0x30 + unit - 0x0660);
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      out.writeCharCode(0x30 + unit - 0x06F0);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

/// One selectable document type as served by
/// `GET /guest/identity/document-types`.
@immutable
class IdentityDocumentOption {
  const IdentityDocumentOption({
    required this.type,
    required this.back,
    this.automaticCheck = false,
    this.detailsRequired = true,
  });

  /// The built-in fallback catalog (same defaults as the backend config).
  static const List<IdentityDocumentOption> defaults = <IdentityDocumentOption>[
    IdentityDocumentOption(type: IdentityDocumentType.egyptianNationalId, back: BackImagePolicy.required),
    IdentityDocumentOption(type: IdentityDocumentType.saudiNationalId, back: BackImagePolicy.optional),
    IdentityDocumentOption(type: IdentityDocumentType.saudiIqama, back: BackImagePolicy.optional),
    IdentityDocumentOption(type: IdentityDocumentType.passport, back: BackImagePolicy.none, automaticCheck: true),
  ];

  final IdentityDocumentType type;
  final BackImagePolicy back;

  /// False when the document will be checked by staff rather than
  /// automatically (no configured model, or automatic verification off).
  final bool automaticCheck;

  /// False in the backend's document-only mode: the guest only photographs
  /// the ID — no typed details, no OCR comparison, no selfie.
  final bool detailsRequired;

  @override
  bool operator ==(Object other) =>
      other is IdentityDocumentOption &&
      other.type == type &&
      other.back == back &&
      other.automaticCheck == automaticCheck &&
      other.detailsRequired == detailsRequired;

  @override
  int get hashCode => Object.hash(type, back, automaticCheck, detailsRequired);
}

/// A locally captured image, referenced only by non-sensitive metadata.
///
/// On iOS/Android the app never keeps the image bytes in domain/state objects
/// — the photo stays in an on-device file ([filePath]) that the upload streams
/// (mobile/docs/architecture.md §8, phase brief "Security"). On the web there
/// is no file system, so the picked photo is carried as [bytes] instead. Bytes
/// are never logged ([toString] prints metadata only). In dummy mode it is a
/// fixed placeholder.
@immutable
class CapturedImage {
  const CapturedImage({
    required this.label,
    required this.sizeBytes,
    this.mimeType = 'image/jpeg',
    this.filePath,
    this.bytes,
  });

  /// A deterministic placeholder capture for dummy mode — no real bytes exist.
  static const CapturedImage dummy = CapturedImage(
    label: 'captured-image',
    sizeBytes: 128 * 1024,
  );

  /// A short, non-sensitive label for display / logs (e.g. a file name).
  final String label;

  /// Size in bytes — used only to validate against the upload limit.
  final int sizeBytes;

  final String mimeType;

  /// The local, on-device path a real camera/file-picker capture wrote the
  /// image to — the one piece of data the upload data source needs to stream
  /// real bytes to the backend. `null` in dummy mode and whenever no real
  /// capture flow has produced a file yet; never a remote URL, never held as
  /// in-memory bytes here (mobile/docs/architecture.md §8).
  final String? filePath;

  /// The image content on the web only, where [filePath] is a transient blob
  /// URL that can't be streamed from disk. Always `null` on iOS/Android.
  final Uint8List? bytes;

  /// Whether a real capture produced something the upload can send.
  bool get hasContent => filePath != null || bytes != null;

  @override
  bool operator ==(Object other) =>
      other is CapturedImage &&
      other.label == label &&
      other.sizeBytes == sizeBytes &&
      other.mimeType == mimeType &&
      other.filePath == filePath &&
      identical(other.bytes, bytes);

  @override
  int get hashCode =>
      Object.hash(label, sizeBytes, mimeType, filePath, identityHashCode(bytes));

  @override
  String toString() => 'CapturedImage($label, $sizeBytes bytes)';
}

/// What the guest says is printed on their ID document.
///
/// Sent once with the document upload so the backend can compare it with what
/// its OCR provider reads off the document. The backend never stores or
/// echoes these values back; the app keeps them only in the form's memory for
/// the current flow and never logs them — [toString] is redacted.
@immutable
class IdentityDocumentClaim {
  const IdentityDocumentClaim({
    required this.fullName,
    required this.documentNumber,
    this.dateOfBirth,
  });

  final String fullName;
  final String documentNumber;

  /// Null for an Egyptian ID — the backend reads it from the national number.
  final DateTime? dateOfBirth;

  /// `YYYY-MM-DD` with Western digits — the wire format, whatever the UI locale.
  String? get dateOfBirthWire {
    final DateTime? d = dateOfBirth;
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Multipart form fields for the upload (digits always Western).
  Map<String, String> toFields() => <String, String>{
        'full_name': fullName.trim(),
        'document_number': normalizeDigits(documentNumber.trim()),
        'date_of_birth': ?dateOfBirthWire,
      };

  @override
  bool operator ==(Object other) =>
      other is IdentityDocumentClaim &&
      other.fullName == fullName &&
      other.documentNumber == documentNumber &&
      other.dateOfBirth == dateOfBirth;

  @override
  int get hashCode => Object.hash(fullName, documentNumber, dateOfBirth);

  @override
  String toString() => 'IdentityDocumentClaim([redacted])';
}
