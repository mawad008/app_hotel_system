import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../models/identity_verification_models.dart';
import 'identity_verification_data_source.dart';

/// API-backed identity-verification source.
///
/// Real, authenticated guest contract, reusing the shared
/// `IdentityVerificationResource`:
/// `POST /guest/reservations/{reservation}/identity/documents`,
/// `POST .../identity/selfie`, `GET .../identity`. There is no guest
/// equivalent of the staff `review` (manual approve/reject) action.
///
/// The document upload also carries the guest's [IdentityDocumentClaim]
/// (name / number / date of birth). The backend runs a real OCR check
/// (Azure AI Document Intelligence in production) and returns only outcome
/// codes in `document_check`. No OCR runs and no provider credential exists
/// in the app.
///
/// A [CapturedImage] without a real on-device file (dummy placeholder) cannot
/// be uploaded: [submitDocument]/[submitSelfie] throw
/// [NotImplementedInPhaseException] rather than upload zero bytes.
class ApiIdentityVerificationDataSource
    implements IdentityVerificationDataSource, RemoteDataSource {
  ApiIdentityVerificationDataSource(this._client);

  final ApiClient _client;

  static const String _noCaptureReason =
      'No real camera/file-picker capture is wired yet — CapturedImage has no '
      'file to upload';

  @override
  Future<IdentityVerificationSessionModel> fetchStatus(
    String reservationId,
  ) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/identity',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return IdentityVerificationSessionModel.fromJson(data);
  }

  @override
  Future<List<IdentityDocumentOption>> documentTypes() async {
    final Map<String, dynamic> json = await _client.getJson('/guest/identity/document-types');
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return <IdentityDocumentOption>[
      for (final Object? row in rows)
        if (row is Map && IdentityDocumentType.tryFromWire(row['type'] as String?) != null)
          IdentityDocumentOption(
            type: IdentityDocumentType.tryFromWire(row['type'] as String?)!,
            back: BackImagePolicy.fromWire(row['back_image'] as String?),
            automaticCheck: row['automatic_check'] == true,
            // Older servers don't send it — they always want the details.
            detailsRequired: row['details_required'] != false,
          ),
    ];
  }

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) async {
    final CapturedImage? back = request.backImage;
    if (!request.image.hasContent || (back != null && !back.hasContent)) {
      throw const NotImplementedInPhaseException(_noCaptureReason);
    }

    final Map<String, dynamic> json = await _client.postMultipart(
      '/guest/reservations/${request.reservationId}/identity/documents',
      files: <String, MultipartFile>{
        'front_image': await _multipart(request.image),
        if (back != null) 'back_image': await _multipart(back),
      },
      fields: <String, dynamic>{
        'document_type': request.type.wireValue,
        ...?request.claim?.toFields(),
      },
      onSendProgress: _progress(onProgress),
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return IdentityVerificationSessionModel.fromJson(data);
  }

  @override
  Future<IdentityVerificationSessionModel> submitSelfie(
    SubmitSelfieRequest request, {
    UploadProgress? onProgress,
  }) async {
    if (!request.image.hasContent) {
      throw const NotImplementedInPhaseException(_noCaptureReason);
    }

    final Map<String, dynamic> json = await _client.postMultipart(
      '/guest/reservations/${request.reservationId}/identity/selfie',
      files: <String, MultipartFile>{
        'selfie': await _multipart(request.image),
      },
      headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
      onSendProgress: _progress(onProgress),
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return IdentityVerificationSessionModel.fromJson(data);
  }

  /// The upload part for a capture: in-memory bytes on the web, streamed
  /// from the on-device file on iOS/Android.
  static Future<MultipartFile> _multipart(CapturedImage image) async {
    final MediaType contentType = MediaType.parse(image.mimeType);
    final Uint8List? bytes = image.bytes;
    if (bytes != null) {
      return MultipartFile.fromBytes(
        bytes,
        filename: image.label,
        contentType: contentType,
      );
    }
    return MultipartFile.fromFile(
      image.filePath!,
      filename: image.label,
      contentType: contentType,
    );
  }

  static void Function(int, int)? _progress(UploadProgress? onProgress) {
    if (onProgress == null) return null;
    return (int sent, int total) {
      if (total > 0) onProgress((sent / total).clamp(0.0, 1.0));
    };
  }
}
