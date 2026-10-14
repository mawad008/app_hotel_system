import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/identity_document.dart';

/// Which camera a capture uses: the ID photo is taken with the rear camera,
/// the live selfie with the front one (`IDENTITY_CaptureID` / `IDENTITY_Selfie`).
enum IdentityCaptureTarget { document, selfie }

/// The outcome of one capture attempt.
sealed class IdentityCaptureResult {
  const IdentityCaptureResult();
}

/// A real photo was taken and written to a local file.
class IdentityCaptured extends IdentityCaptureResult {
  const IdentityCaptured(this.image);
  final CapturedImage image;
}

/// The guest closed the camera without taking a photo.
class IdentityCaptureCancelled extends IdentityCaptureResult {
  const IdentityCaptureCancelled();
}

/// The camera can't be used — permission denied (`IDENTITY_CameraDenied`) or
/// no camera on the device.
class IdentityCameraUnavailable extends IdentityCaptureResult {
  const IdentityCameraUnavailable({required this.permissionDenied});
  final bool permissionDenied;
}

/// Device seam for taking the identity photos. Camera only on iOS/Android —
/// the Figma capture screens state "الكاميرا فقط — لا رفع من المعرض" (no
/// gallery upload). The web has no reliable camera source (desktop browsers
/// open a file chooser either way), so there the guest picks an image file.
abstract interface class IdentityCamera {
  Future<IdentityCaptureResult> capture(IdentityCaptureTarget target);

  /// The photo a [capture] took while Android killed the app in the
  /// background (the system camera is a separate activity), recovered on the
  /// next launch. `null` when there is none (always, off Android).
  Future<IdentityCaptured?> recoverLostCapture(IdentityCaptureTarget target);
}

/// [IdentityCamera] backed by the platform camera via `image_picker`. On
/// iOS/Android the photo stays on device as a temp file until the upload
/// streams it (mobile/docs/architecture.md §8 — never held as in-memory
/// bytes); on the web it is read into [CapturedImage.bytes].
class ImagePickerIdentityCamera implements IdentityCamera {
  ImagePickerIdentityCamera([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Keeps uploads well under the backend's size limit while leaving the ID
  /// text readable for the verification provider.
  static const double _maxDimension = 2000;
  static const int _jpegQuality = 85;

  @override
  Future<IdentityCaptureResult> capture(IdentityCaptureTarget target) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: target == IdentityCaptureTarget.selfie
            ? CameraDevice.front
            : CameraDevice.rear,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _jpegQuality,
        requestFullMetadata: false,
      );
      if (file == null) return const IdentityCaptureCancelled();
      final String label =
          target == IdentityCaptureTarget.selfie ? 'selfie.jpg' : 'document.jpg';
      if (kIsWeb) {
        final Uint8List bytes = await file.readAsBytes();
        return IdentityCaptured(
          CapturedImage(
            label: label,
            sizeBytes: bytes.length,
            mimeType: file.mimeType ?? 'image/jpeg',
            bytes: bytes,
          ),
        );
      }
      return IdentityCaptured(
        CapturedImage(
          label: label,
          sizeBytes: await file.length(),
          mimeType: 'image/jpeg',
          filePath: file.path,
        ),
      );
    } on PlatformException catch (e) {
      // image_picker reports `camera_access_denied` (iOS/Android) when the
      // guest refused the permission; anything else (e.g. no camera on a
      // simulator) is treated as the camera being unavailable.
      debugPrint('Identity capture failed: ${e.code}');
      return IdentityCameraUnavailable(
        permissionDenied: e.code == 'camera_access_denied',
      );
    }
  }

  @override
  Future<IdentityCaptured?> recoverLostCapture(IdentityCaptureTarget target) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final LostDataResponse lost = await _picker.retrieveLostData();
      final XFile? file = lost.file;
      if (lost.isEmpty || file == null) return null;
      return IdentityCaptured(
        CapturedImage(
          label: target == IdentityCaptureTarget.selfie ? 'selfie.jpg' : 'document.jpg',
          sizeBytes: await file.length(),
          mimeType: 'image/jpeg',
          filePath: file.path,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Identity capture recovery failed: ${e.code}');
      return null;
    }
  }
}
