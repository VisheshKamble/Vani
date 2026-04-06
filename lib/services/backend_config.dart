import 'package:flutter/foundation.dart';

class BackendConfig {
  static const bool websocketEnabled = bool.fromEnvironment(
    'ISL_WS_ENABLED',
    defaultValue: true,
  );

  static const String _websocketUrlOverride = String.fromEnvironment(
    'ISL_WS_URL',
    defaultValue: '',
  );

  static const String _websocketScheme = String.fromEnvironment(
    'ISL_WS_SCHEME',
    defaultValue: 'wss',
  );

  static const String _websocketHost = String.fromEnvironment(
    'ISL_WS_HOST',
    defaultValue: 'isl-production-57d4.up.railway.app',
  );

  static const String _websocketPath = String.fromEnvironment(
    'ISL_WS_PATH',
    defaultValue: '/ws',
  );

  static String get websocketUrl {
    final rawUrl = _websocketUrlOverride.isNotEmpty
        ? _websocketUrlOverride
        : '$_websocketScheme://$_websocketHost$_websocketPath';
    return _normalizeWebsocketUrl(rawUrl);
  }

  // Convenience URL used for preflight diagnostics.
  static String get healthUrl {
    final ws = Uri.parse(websocketUrl);
    final httpScheme = ws.scheme == 'wss' ? 'https' : 'http';
    return ws.replace(scheme: httpScheme, path: '/health').toString();
  }

  static String _normalizeWebsocketUrl(String rawUrl) {
    if (kIsWeb) return rawUrl;

    Uri parsed;
    try {
      parsed = Uri.parse(rawUrl);
    } catch (_) {
      return rawUrl;
    }

    final host = parsed.host.toLowerCase();
    final isLoopback = host == '127.0.0.1' || host == 'localhost';

    // Android emulators must reach the host machine via 10.0.2.2.
    if (isLoopback && defaultTargetPlatform == TargetPlatform.android) {
      return parsed.replace(host: '10.0.2.2').toString();
    }

    return rawUrl;
  }
}