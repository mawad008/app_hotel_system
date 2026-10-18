import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../data/datasources/api_app_content_data_source.dart';
import '../../data/datasources/app_content_data_source.dart';
import '../../data/datasources/dummy_app_content_data_source.dart';
import '../../data/repositories/app_content_repository_impl.dart';
import '../../domain/entities/app_content.dart';
import '../../domain/repositories/app_content_repository.dart';

final appContentDataSourceProvider = Provider<AppContentDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? const DummyAppContentDataSource()
      : ApiAppContentDataSource(
          ref.watch(apiClientProvider),
          ref.watch(appPreferencesProvider),
        );
});

/// The content this device last received (persisted), or null on a first
/// launch / with dummy data. Read synchronously at startup so the app title,
/// brand colour and icon are the hotel's from the first frame.
final cachedAppContentProvider = Provider<AppContent?>((Ref ref) {
  final AppContentDataSource source = ref.watch(appContentDataSourceProvider);
  return source is ApiAppContentDataSource ? source.cachedContent() : null;
});

final appContentRepositoryProvider = Provider<AppContentRepository>(
  (Ref ref) =>
      AppContentRepositoryImpl(ref.watch(appContentDataSourceProvider)),
);

/// How long the entry screens wait for dashboard content before settling on
/// the bundled defaults. The splash already holds for 1.6s, so a normal
/// response lands well inside this.
const Duration appContentTimeout = Duration(seconds: 3);

/// The Guest App's dashboard-managed branding + entry content, fetched once
/// per launch and again on every app resume (see `HotelGuestApp`).
///
/// Branding must never block entry: any failure or a slow response resolves
/// to the last content this device received, else [AppContent.empty] — so
/// every screen falls back to its bundled defaults only when nothing was
/// ever fetched.
final appContentProvider = FutureProvider<AppContent>((Ref ref) async {
  try {
    return await ref
        .watch(appContentRepositoryProvider)
        .content()
        .timeout(appContentTimeout);
  } catch (error) {
    final AppContent? cached = ref.read(cachedAppContentProvider);
    if (kDebugMode) {
      debugPrint(
        'appContent: using ${cached == null ? 'bundled defaults' : 'cached content'} — $error',
      );
    }
    return cached ?? AppContent.empty;
  }
});

/// App-wide branding that never waits: the fresh content once loaded, the
/// cached one meanwhile, else the bundled defaults. For chrome that must
/// render immediately (app title, theme colour, web icon, support / legal
/// links) and the brand logo (`ManagedBrandLogo`).
final brandingProvider = Provider<AppContent>((Ref ref) {
  return ref.watch(appContentProvider).value ??
      ref.watch(cachedAppContentProvider) ??
      AppContent.empty;
});

/// Whether [brandingProvider] holds real content yet (fresh, cached or the
/// settled fallback) rather than the placeholder used while the first fetch
/// is in flight. The brand logo waits on it so it never swaps in front of the
/// guest.
final brandingKnownProvider = Provider<bool>((Ref ref) {
  return ref.watch(appContentProvider).hasValue ||
      ref.watch(cachedAppContentProvider) != null;
});

/// The FAQ for `PROFILE_Support` — fetched fresh, and unlike
/// [appContentProvider] a failure is surfaced (with retry) instead of
/// silently showing "no questions".
final faqProvider = FutureProvider.autoDispose<List<FaqEntry>>((Ref ref) async {
  final AppContent content = await ref
      .watch(appContentRepositoryProvider)
      .content();
  return content.faq;
});
