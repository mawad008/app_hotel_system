import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/api_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document_check.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<RequestOptions> received = <RequestOptions>[];
  final List<int> sentBytes = <int>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    if (requestStream != null) {
      await for (final Uint8List chunk in requestStream) {
        sentBytes.addAll(chunk);
      }
    }
    final String key = '${options.method} ${options.path}';
    final (int, Map<String, dynamic>) entry =
        routes[key] ?? (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiIdentityVerificationDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiIdentityVerificationDataSource(ApiClient.withDio(dio));
}

void main() {
  test('fetchStatus parses the session', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/identity': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'reservation_id': 9,
          'status': 'document_uploaded',
          'attempts': 1,
          'latest_outcome': null,
        },
      }),
    });

    final session = await _source(adapter).fetchStatus('9');
    expect(session.status.wireValue, 'document_uploaded');
    expect(session.attempts, 1);
  });

  test('submitDocument refuses when no real capture is wired (no filePath)', () async {
    final source = _source(_FakeAdapter(<String, (int, Map<String, dynamic>)>{}));

    expect(
      source.submitDocument(const SubmitIdentityDocumentRequest(
        reservationId: '9',
        type: IdentityDocumentType.passport,
        image: CapturedImage.dummy,
      )),
      throwsA(isA<NotImplementedInPhaseException>()),
    );
  });

  test('submitDocument sends the claim fields, reports progress and parses document_check', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/identity/documents': (201, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'reservation_id': 9,
          'status': 'document_uploaded',
          'attempts': 0,
          'document_check': <String, dynamic>{
            'status': 'mismatch',
            'reasons': <String>['claim_mismatch'],
            'fields': <String, String>{'number': 'mismatch', 'birth': 'match', 'name': 'strong'},
            'can_continue': false,
            'requires_new_document': true,
            'uploads_remaining': 4,
          },
        },
      }),
    });
    final Directory dir = await Directory.systemTemp.createTemp('idv');
    final File file = File('${dir.path}/doc.jpg')..writeAsBytesSync(List<int>.filled(4096, 7));
    final List<double> progress = <double>[];

    final model = await _source(adapter).submitDocument(
      SubmitIdentityDocumentRequest(
        reservationId: '9',
        type: IdentityDocumentType.passport,
        image: CapturedImage(label: 'doc.jpg', sizeBytes: 4096, filePath: file.path),
        claim: IdentityDocumentClaim(
          fullName: 'Anna Maria Eriksson',
          documentNumber: 'L898902C3',
          dateOfBirth: DateTime(1974, 8, 12),
        ),
      ),
      onProgress: progress.add,
    );

    final String body = latin1.decode(adapter.sentBytes);
    expect(body, contains('name="full_name"'));
    expect(body, contains('Anna Maria Eriksson'));
    expect(body, contains('name="document_number"'));
    expect(body, contains('name="date_of_birth"\r\n\r\n1974-08-12'));
    expect(body, contains('name="document_type"\r\n\r\npassport'));
    expect(body, contains('name="front_image"'));
    expect(body, isNot(contains('name="back_image"')));
    expect(progress, isNotEmpty);
    expect(progress.last, 1.0);

    final check = model.toEntity().documentCheck!;
    expect(check.status, DocumentCheckStatus.mismatch);
    expect(check.requiresNewDocument, isTrue);
    expect(check.mismatchedFields, <String>['number']);
    expect(check.uploadsRemaining, 4);
    expect(model.toEntity().needsSelfie, isFalse);
    expect(model.toEntity().documentRejected, isTrue);
    await dir.delete(recursive: true);
  });

  test('the claim never prints its values and always sends Western-digit ISO dates', () {
    final claim = IdentityDocumentClaim(
      fullName: 'Secret Name',
      documentNumber: 'X123',
      dateOfBirth: DateTime(2001, 2, 3),
    );
    expect(claim.toString(), isNot(contains('Secret')));
    expect(claim.toString(), isNot(contains('X123')));
    expect(claim.toFields()['date_of_birth'], '2001-02-03');
  });

  test('documentTypes parses the catalog and ignores unknown types', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/identity/document-types': (200, <String, dynamic>{
        'success': true,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'egyptian_national_id', 'country': 'EGY', 'back_image': 'required', 'automatic_check': false},
          <String, dynamic>{'type': 'saudi_iqama', 'country': 'SAU', 'back_image': 'optional', 'automatic_check': true},
          <String, dynamic>{'type': 'martian_id', 'back_image': 'none'},
        ],
      }),
    });

    final options = await _source(adapter).documentTypes();

    expect(options, <IdentityDocumentOption>[
      const IdentityDocumentOption(type: IdentityDocumentType.egyptianNationalId, back: BackImagePolicy.required),
      const IdentityDocumentOption(type: IdentityDocumentType.saudiIqama, back: BackImagePolicy.optional, automaticCheck: true),
    ]);
  });

  test('documentTypes reads document-only mode (details_required: false)', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/identity/document-types': (200, <String, dynamic>{
        'success': true,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'passport', 'back_image': 'none', 'automatic_check': true, 'details_required': false},
        ],
      }),
    });

    final options = await _source(adapter).documentTypes();

    expect(options.single.detailsRequired, isFalse);
  });

  test('an Egyptian ID upload sends both sides and no date of birth', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/identity/documents': (201, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'reservation_id': 9, 'status': 'document_uploaded', 'attempts': 0},
      }),
    });
    final Directory dir = await Directory.systemTemp.createTemp('idv');
    final File front = File('${dir.path}/f.jpg')..writeAsBytesSync(List<int>.filled(64, 1));
    final File back = File('${dir.path}/b.jpg')..writeAsBytesSync(List<int>.filled(64, 2));

    await _source(adapter).submitDocument(SubmitIdentityDocumentRequest(
      reservationId: '9',
      type: IdentityDocumentType.egyptianNationalId,
      image: CapturedImage(label: 'front.jpg', sizeBytes: 64, filePath: front.path),
      backImage: CapturedImage(label: 'back.jpg', sizeBytes: 64, filePath: back.path),
      claim: const IdentityDocumentClaim(fullName: 'سامي منصور', documentNumber: '٢٩٠٠١١٥٠١١٢٣٥٧'),
    ));

    final String body = latin1.decode(adapter.sentBytes);
    expect(body, contains('name="front_image"'));
    expect(body, contains('name="back_image"'));
    expect(body, contains('name="document_type"\r\n\r\negyptian_national_id'));
    expect(body, contains('name="document_number"\r\n\r\n29001150112357'));
    expect(body, isNot(contains('date_of_birth')));
    await dir.delete(recursive: true);
  });

  test('a back image with no on-device file is never uploaded as empty bytes', () async {
    final source = _source(_FakeAdapter(<String, (int, Map<String, dynamic>)>{}));
    final Directory dir = await Directory.systemTemp.createTemp('idv');
    final File front = File('${dir.path}/f.jpg')..writeAsBytesSync(List<int>.filled(8, 1));

    await expectLater(
      source.submitDocument(SubmitIdentityDocumentRequest(
        reservationId: '9',
        type: IdentityDocumentType.egyptianNationalId,
        image: CapturedImage(label: 'f.jpg', sizeBytes: 8, filePath: front.path),
        backImage: CapturedImage.dummy,
      )),
      throwsA(isA<NotImplementedInPhaseException>()),
    );
    await dir.delete(recursive: true);
  });

  test('web captures (in-memory bytes, no file) upload both document sides via fromBytes', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/identity/documents': (201, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'reservation_id': 9, 'status': 'document_uploaded', 'attempts': 0},
      }),
    });

    await _source(adapter).submitDocument(SubmitIdentityDocumentRequest(
      reservationId: '9',
      type: IdentityDocumentType.egyptianNationalId,
      image: CapturedImage(
        label: 'document.jpg',
        sizeBytes: 5,
        mimeType: 'image/png',
        bytes: Uint8List.fromList(utf8.encode('FRONT')),
      ),
      backImage: CapturedImage(
        label: 'back.jpg',
        sizeBytes: 4,
        bytes: Uint8List.fromList(utf8.encode('BACK')),
      ),
    ));

    final String body = latin1.decode(adapter.sentBytes);
    expect(body, contains('name="front_image"; filename="document.jpg"'));
    expect(body, contains('content-type: image/png\r\n\r\nFRONT'));
    expect(body, contains('name="back_image"; filename="back.jpg"'));
    expect(body, contains('\r\n\r\nBACK'));
  });

  test('a web selfie (in-memory bytes) is uploaded with the idempotency key', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/identity/selfie': (201, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'reservation_id': 9, 'status': 'selfie_uploaded', 'attempts': 1},
      }),
    });

    final model = await _source(adapter).submitSelfie(SubmitSelfieRequest(
      reservationId: '9',
      image: CapturedImage(
        label: 'selfie.jpg',
        sizeBytes: 6,
        bytes: Uint8List.fromList(utf8.encode('SELFIE')),
      ),
    ));

    final String body = latin1.decode(adapter.sentBytes);
    expect(body, contains('name="selfie"; filename="selfie.jpg"'));
    expect(body, contains('\r\n\r\nSELFIE'));
    expect(adapter.received.single.headers['Idempotency-Key'], 'idv-selfie:9');
    expect(model.toEntity().attempts, 1);
  });

  test('a web capture never prints its bytes', () {
    final image = CapturedImage(
      label: 'document.jpg',
      sizeBytes: 3,
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    expect(image.hasContent, isTrue);
    expect(image.toString(), 'CapturedImage(document.jpg, 3 bytes)');
    expect(CapturedImage.dummy.hasContent, isFalse);
  });
}
