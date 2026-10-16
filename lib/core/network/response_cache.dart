import 'dart:collection';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last good response of selected public `GET`s (the hotel list, a
/// hotel's details, the city list), so browsing still works when the network
/// doesn't: [ApiClient.getJson] serves the saved copy when a request fails for
/// connectivity reasons — offline, a timeout, or the server being down — and
/// never otherwise (a 4xx is a real answer, not a reason to show old data).
///
/// Never used for the guest's own data or for anything priced live
/// (availability), which must not be shown stale.
abstract interface class ResponseCache {
  Future<Map<String, dynamic>?> read(String key);

  Future<void> write(String key, Map<String, dynamic> json);
}

/// Process-lifetime cache — the default (tests, and before `bootstrap()`
/// installs [PersistentResponseCache]).
class InMemoryResponseCache implements ResponseCache {
  final Map<String, Map<String, dynamic>> _entries =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, Map<String, dynamic> json) async =>
      _entries[key] = json;
}

/// Device storage, survives restarts. Keeps the [capacity] most recently
/// written responses (a few hundred KB at most) and drops older ones.
class PersistentResponseCache implements ResponseCache {
  PersistentResponseCache({SharedPreferencesAsync? storage, this.capacity = 40})
      : _storage = storage ?? SharedPreferencesAsync();

  static const String _prefix = 'api_cache:';
  static const String _indexKey = 'api_cache_index';

  final SharedPreferencesAsync _storage;
  final int capacity;

  /// Keys, oldest first — loaded lazily from [_indexKey].
  LinkedHashSet<String>? _index;

  Future<LinkedHashSet<String>> _loadIndex() async {
    final LinkedHashSet<String>? loaded = _index;
    if (loaded != null) return loaded;
    final List<String> saved =
        await _storage.getStringList(_indexKey) ?? const <String>[];
    return _index = LinkedHashSet<String>.of(saved);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final String? raw = await _storage.getString('$_prefix$key');
      if (raw == null) return null;
      final Object? json = jsonDecode(raw);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null; // unreadable entry: as if absent
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> json) async {
    try {
      await _storage.setString('$_prefix$key', jsonEncode(json));
      final LinkedHashSet<String> index = await _loadIndex();
      index
        ..remove(key)
        ..add(key);
      while (index.length > capacity) {
        final String oldest = index.first;
        index.remove(oldest);
        await _storage.remove('$_prefix$oldest');
      }
      await _storage.setStringList(_indexKey, index.toList());
    } catch (_) {
      // Best effort: a failed write only costs the offline fallback.
    }
  }
}
