import 'web_app_icon_stub.dart'
    if (dart.library.js_interop) 'web_app_icon_web.dart'
    as impl;

/// Points the web app's favicon and home-screen (apple-touch) icon at [url] —
/// the dashboard-managed app icon. A no-op on Android / iOS, whose launcher
/// icons are build-time assets.
void applyWebAppIcon(String url) => impl.applyWebAppIcon(url);
