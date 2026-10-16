import 'connect_timeout_stub.dart'
    if (dart.library.io) 'connect_timeout_io.dart'
    as impl;

/// Gives every HTTP client the app opens — image downloads
/// (`cached_network_image`), map tiles, Dio — [timeout] to connect.
///
/// Without one, a connection the network silently drops waits until the
/// operating system gives up (about two minutes on Android), leaving a photo
/// or map tile on its placeholder that long. With it the attempt fails fast
/// and the caller's retry runs (`AppImage` retries photos, `ApiClient`
/// retries reads). A no-op on the web, where the browser owns connections.
void installConnectTimeout({Duration timeout = const Duration(seconds: 10)}) =>
    impl.installConnectTimeout(timeout);
