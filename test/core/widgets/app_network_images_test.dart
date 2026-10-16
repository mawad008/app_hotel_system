import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';
import 'package:hotel_guest_app/core/widgets/app_image.dart';

void main() {
  group('AppNetworkImages.provider', () {
    tearDown(() => AppNetworkImages.diskCache = false);

    test('uses the disk cache in the app', () {
      AppNetworkImages.diskCache = true;
      expect(
        AppNetworkImages.provider('https://x.test/a.jpg'),
        isA<CachedNetworkImageProvider>(),
      );
    });

    test('decodes at the requested width, capped for huge uploads', () {
      final ResizeImage small = AppNetworkImages.provider(
        'https://x.test/a.jpg',
        decodeWidth: 600,
      ) as ResizeImage;
      expect(small.width, 600);
      expect(small.height, isNull, reason: 'height follows the aspect ratio');

      final ResizeImage huge = AppNetworkImages.provider(
        'https://x.test/a.jpg',
        decodeWidth: 9000,
      ) as ResizeImage;
      expect(huge.width, AppNetworkImages.maxDecodePx);
    });
  });

  testWidgets('AppImage.network decodes for the box it is shown in', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Center(
          child: SizedBox(
            width: 120,
            height: 80,
            child: AppImage.network(url: 'https://x.test/hotel.jpg'),
          ),
        ),
      ),
    );
    final Image image = tester.widget<Image>(find.byType(Image));
    // The longer edge (120) at 3x.
    expect((image.image as ResizeImage).width, 360);
  });

  testWidgets('a failed photo is retried twice, then the placeholder stays', (
    WidgetTester tester,
  ) async {
    // Every request fails under test: the test HTTP client answers 400.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Center(
          child: SizedBox(
            width: 120,
            height: 80,
            child: AppImage.network(url: 'https://x.test/missing.jpg'),
          ),
        ),
      ),
    );
    Key? attempt() => tester.widget<Image>(find.byType(Image)).key;
    // Debug builds mark a failed load with a broken-image icon (release
    // builds show the plain placeholder).
    final Finder failed = find.byIcon(Icons.broken_image_outlined);

    await tester.pumpAndSettle();
    expect(failed, findsOneWidget);
    expect(attempt(), const ValueKey<int>(0));

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(attempt(), const ValueKey<int>(1), reason: 'first retry after 2 s');
    expect(failed, findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(attempt(), const ValueKey<int>(2), reason: 'second retry after 6 s');

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(attempt(), const ValueKey<int>(2), reason: 'no third retry');
    expect(failed, findsOneWidget);
  });
}
