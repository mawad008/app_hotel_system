import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Re-points every `<link rel="icon">` / `apple-touch-icon` in `index.html`.
void applyWebAppIcon(String url) {
  final JSObject document = globalContext['document']! as JSObject;
  final JSObject links = document.callMethod<JSObject>(
    'querySelectorAll'.toJS,
    "link[rel~='icon'], link[rel='apple-touch-icon']".toJS,
  );
  final int count = (links['length']! as JSNumber).toDartInt;
  for (int i = 0; i < count; i++) {
    final JSObject link = links.callMethod<JSObject>('item'.toJS, i.toJS);
    link['href'] = url.toJS;
    // The uploaded icon's own type, not index.html's `image/png`.
    link.callMethod<JSAny?>('removeAttribute'.toJS, 'type'.toJS);
  }
}
