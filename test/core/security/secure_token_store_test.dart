import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/security/secure_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test('a written token is readable by a new store instance (survives restart)',
      () async {
    await SecureTokenStore().writeAccessToken('abc');
    expect(await SecureTokenStore().readAccessToken(), 'abc');
  });

  test('clear removes the token', () async {
    final SecureTokenStore store = SecureTokenStore();
    await store.writeAccessToken('abc');
    await store.clear();
    expect(await SecureTokenStore().readAccessToken(), isNull);
  });

  test('reads null when nothing was stored', () async {
    expect(await SecureTokenStore().readAccessToken(), isNull);
  });
}
