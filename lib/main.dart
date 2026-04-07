// lib/main.dart
//
// Fix: Supabase.initialize() was called TWICE (once in main() and again
// inside AppInitializer). Calling it twice throws a StateError at runtime.
// Solution: initialize only in main(), remove AppInitializer entirely,
// and go straight to VaniApp.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/AppLocalizations.dart';
import 'models/EmergencyContact.dart';
import 'services/EmergencyService.dart';
import 'screens/HomeScreen.dart';
import 'screens/SplashScreen.dart';
import 'components/SOSFloatingButton.dart';
import 'components/AuthDialog.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Apple-style: transparent status bar, light icons on dark, dark icons on light
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const VaniApp());
}

class AppBootstrap {
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  static Future<void> _initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmergencyContactAdapter());
    }
    if (!Hive.isBoxOpen('emergency_contacts')) {
      await Hive.openBox<EmergencyContact>('emergency_contacts');
    }

    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Run with --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }
}

// ─────────────────────────────────────────────
//  APPLE DESIGN TOKENS
// ─────────────────────────────────────────────

// iOS / macOS system blue — the definitive Apple accent
const _kAppleBlue = Color(0xFF007AFF);
const _kAppleBlueDark = Color(0xFF0A84FF); // dark-mode system blue
const _kAppleIndigo = Color(0xFF5856D6);
const _kAppleTeal = Color(0xFF32ADE6);
const _kAppleRed = Color(0xFFFF3B30);

// Light mode surface hierarchy (iOS exact)
const _lBg = Color(0xFFF2F2F7); // systemGroupedBackground
const _lSurface = Color(0xFFFFFFFF); // secondarySystemGroupedBackground
const _lSurface2 = Color(0xFFF2F2F7); // tertiarySystemGroupedBackground
const _lSeparator = Color(0xFFC6C6C8); // separator
const _lLabel = Color(0xFF000000); // label
const _lLabel2 = Color(0xFF3C3C43); // secondaryLabel (with 60% opacity applied)

// Dark mode surface hierarchy (iOS exact)
const _dBg = Color(0xFF000000); // systemBackground
const _dSurface = Color(0xFF1C1C1E); // secondarySystemBackground
const _dSurface2 = Color(0xFF2C2C2E); // tertiarySystemBackground
const _dSeparator = Color(0xFF38383A); // separator
const _dLabel = Color(0xFFFFFFFF); // label
const _dLabel2 = Color(0xFFEBEBF5); // secondaryLabel

class VaniApp extends StatefulWidget {
  const VaniApp({super.key});
  @override
  State<VaniApp> createState() => _VaniAppState();
}

class _VaniAppState extends State<VaniApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    // Update system chrome to match
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: _themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: _themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: _themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    // Google Sans — used as Apple SF Pro equivalent
    const appFont = 'Google Sans';

    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).t('app_title'),
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── LIGHT THEME — iOS / macOS exact ──────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: appFont,
        primaryColor: _kAppleBlue,
        scaffoldBackgroundColor: _lBg,
        cardColor: _lSurface,
        canvasColor: _lBg,
        dividerColor: _lSeparator.withOpacity(0.36),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        colorScheme: const ColorScheme.light(
          primary: _kAppleBlue,
          secondary: _kAppleIndigo,
          tertiary: _kAppleTeal,
          surface: _lSurface,
          onSurface: _lLabel,
          outline: _lSeparator,
          error: _kAppleRed,
          surfaceContainer: _lSurface2,
        ),

        textTheme: _buildTextTheme(Brightness.light, appFont),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: appFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _lLabel,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: _kAppleBlue, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _lSurface.withOpacity(0.92),
          indicatorColor: _kAppleBlue.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: appFont,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // ── DARK THEME — iOS / macOS dark mode exact ─────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: appFont,
        primaryColor: _kAppleBlueDark,
        scaffoldBackgroundColor: _dBg,
        cardColor: _dSurface,
        canvasColor: _dBg,
        dividerColor: _dSeparator,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: _kAppleBlueDark,
          secondary: _kAppleIndigo,
          tertiary: _kAppleTeal,
          surface: _dSurface,
          onSurface: _dLabel,
          outline: _dSeparator,
          error: _kAppleRed,
          surfaceContainer: _dSurface2,
        ),
        textTheme: _buildTextTheme(Brightness.dark, appFont),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: appFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _dLabel,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: _kAppleBlueDark, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _dSurface.withOpacity(0.92),
          indicatorColor: _kAppleBlueDark.withOpacity(0.18),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: appFont,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: kIsWeb
          ? _WebEntryGate(toggleTheme: toggleTheme, setLocale: setLocale)
          : SplashScreen(toggleTheme: toggleTheme, setLocale: setLocale),
    );
  }

  /// Builds a Google Sans text theme mirroring Apple SF Pro scales
  TextTheme _buildTextTheme(Brightness b, String font) {
    final base = b == Brightness.dark ? _dLabel : _lLabel;
    final muted = b == Brightness.dark
        ? _dLabel2.withOpacity(0.60)
        : _lLabel2.withOpacity(0.60);
    return TextTheme(
      // Large Title — 34pt, regular
      displayLarge: TextStyle(
        fontFamily: font,
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: 0.37,
      ),
      // Title 1 — 28pt
      displayMedium: TextStyle(
        fontFamily: font,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: 0.36,
      ),
      // Title 2 — 22pt
      displaySmall: TextStyle(
        fontFamily: font,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: 0.35,
      ),
      // Title 3 — 20pt
      headlineLarge: TextStyle(
        fontFamily: font,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: 0.38,
      ),
      // Headline — 17pt semibold
      headlineMedium: TextStyle(
        fontFamily: font,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: base,
        letterSpacing: -0.41,
      ),
      // Body — 17pt regular
      bodyLarge: TextStyle(
        fontFamily: font,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: -0.41,
      ),
      // Callout — 16pt regular
      bodyMedium: TextStyle(
        fontFamily: font,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: base,
        letterSpacing: -0.32,
      ),
      // Subheadline — 15pt regular
      bodySmall: TextStyle(
        fontFamily: font,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: muted,
        letterSpacing: -0.23,
      ),
      // Footnote — 13pt regular
      labelLarge: TextStyle(
        fontFamily: font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        letterSpacing: -0.08,
      ),
      // Caption 1 — 12pt regular
      labelMedium: TextStyle(
        fontFamily: font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        letterSpacing: 0.0,
      ),
      // Caption 2 — 11pt regular
      labelSmall: TextStyle(
        fontFamily: font,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: muted,
        letterSpacing: 0.07,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ROOT SHELL (used by SplashScreen after init)
// ─────────────────────────────────────────────
class RootShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const RootShell({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<RootShell> createState() => _RootShellState();
}

class _WebEntryGate extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _WebEntryGate({
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  State<_WebEntryGate> createState() => _WebEntryGateState();
}

class _WebEntryGateState extends State<_WebEntryGate> {
  bool _ready = false;
  bool _isLoggedIn = false;
  Object? _error;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await AppBootstrap.ensureInitialized();
      if (!mounted) return;
      _isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        setState(() => _isLoggedIn = data.session != null);
      });
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${AppLocalizations.of(context).t('splash_startup_failed')}: $_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return RootShell(
        toggleTheme: widget.toggleTheme,
        setLocale: widget.setLocale,
      );
    }

    return AuthScreen(
      onAuthenticated: () {
        if (!mounted) return;
        setState(() => _isLoggedIn = true);
      },
    );
  }
}

class _RootShellState extends State<RootShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EmergencyService.instance.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showShellFab = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HomeScreen(
        toggleTheme: widget.toggleTheme,
        setLocale: widget.setLocale,
      ),
      floatingActionButton: showShellFab
          ? SOSFloatingButton(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
