import 'dart:convert';

import '../../../../app/router/app_routes.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../data/device/identity_camera.dart';
import '../../domain/entities/identity_document.dart';

/// An identity photo the system camera (`image_picker`) is taking.
///
/// The system camera is a separate Android activity; while it is in front,
/// Android may kill the app's process. The app then cold-starts on the next
/// launch and would land on the home screen, dropping the guest out of the
/// booking flow mid-verification. Saving this marker before the camera opens
/// lets the router reopen the identity step, and the page recover the photo
/// (`IdentityCamera.recoverLostCapture`) and carry on from where it was.
///
/// Holds no image data or ID details — only where the guest was.
class PendingIdentityCapture {
  const PendingIdentityCapture({
    required this.reservationId,
    required this.target,
    required this.back,
    required this.documentType,
  });

  final String reservationId;
  final IdentityCaptureTarget target;

  /// The back of the ID card was being taken (the front, held in memory, is
  /// lost with the process — that step restarts from the front).
  final bool back;

  final IdentityDocumentType documentType;

  /// The identity step this capture belongs to.
  String get location =>
      AppRoutes.identityVerification.replaceFirst(':reservationId', reservationId);

  static PendingIdentityCapture? read(AppPreferences prefs) {
    final String? raw = prefs.pendingIdentityCapture;
    if (raw == null) return null;
    try {
      final Map<String, Object?> json = jsonDecode(raw) as Map<String, Object?>;
      final IdentityDocumentType? type =
          IdentityDocumentType.tryFromWire(json['document_type'] as String?);
      final String? reservationId = json['reservation_id'] as String?;
      if (reservationId == null || type == null) return null;
      return PendingIdentityCapture(
        reservationId: reservationId,
        target: json['target'] == 'selfie'
            ? IdentityCaptureTarget.selfie
            : IdentityCaptureTarget.document,
        back: json['back'] == true,
        documentType: type,
      );
    } on Object {
      return null;
    }
  }

  Future<void> save(AppPreferences prefs) =>
      prefs.setPendingIdentityCapture(jsonEncode(<String, Object?>{
        'reservation_id': reservationId,
        'target': target == IdentityCaptureTarget.selfie ? 'selfie' : 'document',
        'back': back,
        'document_type': documentType.wireValue,
      }));

  static Future<void> clear(AppPreferences prefs) =>
      prefs.setPendingIdentityCapture(null);
}
