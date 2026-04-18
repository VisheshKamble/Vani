import 'package:flutter/foundation.dart';

class BackendConfig {
  static const String defaultWebsocketHost =
      'vani-production.up.railway.app';

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'ISL_API_BASE_URL',
    defaultValue: '',
  );

  static const String _apiMobileBaseUrlOverride = String.fromEnvironment(
    'ISL_API_MOBILE_BASE_URL',
    defaultValue: '',
  );

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
    defaultValue: defaultWebsocketHost,
  );

  static const String _websocketPath = String.fromEnvironment(
    'ISL_WS_PATH',
    defaultValue: '/ws',
  );

  // Optional explicit mobile endpoint (for real devices on LAN), e.g.
  // ws://192.168.1.20:8000/ws
  static const String _websocketMobileUrlOverride = String.fromEnvironment(
    'ISL_WS_MOBILE_URL',
    defaultValue: '',
  );

  static String get websocketUrl {
    final rawUrl = _websocketUrlOverride.isNotEmpty
        ? _websocketUrlOverride
        : '$_websocketScheme://$_websocketHost$_websocketPath';
    return resolveWebsocketUrl(rawUrl);
  }

  static List<String> get websocketCandidates {
    final rawUrl = _websocketUrlOverride.isNotEmpty
        ? _websocketUrlOverride
        : '$_websocketScheme://$_websocketHost$_websocketPath';
    return resolveWebsocketCandidates(rawUrl);
  }

  // Convenience URL used for preflight diagnostics.
  static String get healthUrl {
    try {
      final ws = Uri.parse(websocketUrl);
      final httpScheme = ws.scheme == 'wss' ? 'https' : 'http';
      return ws.replace(scheme: httpScheme, path: '/health').toString();
    } catch (_) {
      return 'https://$defaultWebsocketHost/health';
    }
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    try {
      final ws = Uri.parse(websocketUrl);
      final scheme = ws.scheme == 'wss' ? 'https' : 'http';
      return ws.replace(scheme: scheme, path: '', query: '').toString();
    } catch (_) {
      return 'https://$defaultWebsocketHost';
    }
  }

  static List<String> get apiBaseCandidates {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return [_apiBaseUrlOverride];
    }

    final candidates = <String>[];
    final seen = <String>{};
    for (final wsUrl in websocketCandidates) {
      try {
        final ws = Uri.parse(wsUrl);
        final scheme = ws.scheme == 'wss' ? 'https' : 'http';
        final apiBase = ws
            .replace(scheme: scheme, path: '', query: '')
            .toString();
        if (seen.add(apiBase)) {
          candidates.add(apiBase);
        }
      } catch (_) {}
    }

    if (_apiMobileBaseUrlOverride.isNotEmpty &&
        seen.add(_apiMobileBaseUrlOverride)) {
      candidates.add(_apiMobileBaseUrlOverride);
    }

    if (candidates.isEmpty) {
      candidates.add('https://$defaultWebsocketHost');
    }

    return candidates;
  }

  static String resolveWebsocketUrl(
    String rawUrl, {
    bool? isWeb,
    TargetPlatform? platform,
  }) {
    if (isWeb ?? kIsWeb) return rawUrl;

    Uri parsed;
    try {
      parsed = Uri.parse(rawUrl);
    } catch (_) {
      return rawUrl;
    }

    final host = parsed.host.toLowerCase();
    final isLoopback = host == '127.0.0.1' || host == 'localhost';

    // Android emulators must reach the host machine via 10.0.2.2.
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    if (isLoopback && resolvedPlatform == TargetPlatform.android) {
      return parsed.replace(host: '10.0.2.2').toString();
    }

    return rawUrl;
  }

  static List<String> resolveWebsocketCandidates(
    String rawUrl, {
    bool? isWeb,
    TargetPlatform? platform,
  }) {
    if (isWeb ?? kIsWeb) {
      return [rawUrl];
    }

    Uri parsed;
    try {
      parsed = Uri.parse(rawUrl);
    } catch (_) {
      return [rawUrl];
    }

    final candidates = <String>[];
    final resolvedPlatform = platform ?? defaultTargetPlatform;

    void addIfValid(String url) {
      if (url.isEmpty) return;
      if (!candidates.contains(url)) candidates.add(url);
    }

    // 1) Keep original first for adb reverse or desktop runs.
    addIfValid(rawUrl);

    // 2) Explicit mobile URL override for real devices on LAN.
    addIfValid(_websocketMobileUrlOverride);

    final host = parsed.host.toLowerCase();
    final isLoopback = host == '127.0.0.1' || host == 'localhost';

    // 3) Android emulator candidates.
    if (isLoopback && resolvedPlatform == TargetPlatform.android) {
      addIfValid(parsed.replace(host: '10.0.2.2').toString());
      addIfValid(parsed.replace(host: '10.0.3.2').toString());
    }

    return candidates;
  }
}