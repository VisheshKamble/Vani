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
import 'package:google_fonts/google_fonts.dart';
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
const _appFontFamily = 'Plus Jakarta Sans';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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

    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
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
        fontFamily: _appFontFamily,
        primaryColor: _kAppleBlue,
        scaffoldBackgroundColor: _lBg,
        cardColor: _lSurface,
        canvasColor: _lBg,
        dividerColor: _lSeparator.withValues(alpha: 0.36),
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

        textTheme: _buildTextTheme(Brightness.light),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: _appTextStyle(
            17,
            FontWeight.w700,
            _lLabel,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: _kAppleBlue, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _lSurface.withValues(alpha: 0.92),
          indicatorColor: _kAppleBlue.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(
            _appTextStyle(10, FontWeight.w500, _lLabel),
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
        fontFamily: _appFontFamily,
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
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: _appTextStyle(
            17,
            FontWeight.w700,
            _dLabel,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: _kAppleBlueDark, size: 22),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _dSurface.withValues(alpha: 0.92),
          indicatorColor: _kAppleBlueDark.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
            _appTextStyle(10, FontWeight.w500, _dLabel),
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

  TextStyle _appTextStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color, {
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _appFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  TextTheme _buildTextTheme(Brightness b) {
    final base = b == Brightness.dark ? _dLabel : _lLabel;
    final muted = b == Brightness.dark
        ? _dLabel2.withValues(alpha: 0.60)
        : _lLabel2.withValues(alpha: 0.60);
    return TextTheme(
      displayLarge: _appTextStyle(
        34,
        FontWeight.w700,
        base,
        letterSpacing: 0.37,
      ),
      displayMedium: _appTextStyle(
        28,
        FontWeight.w700,
        base,
        letterSpacing: 0.36,
      ),
      displaySmall: _appTextStyle(
        22,
        FontWeight.w700,
        base,
        letterSpacing: 0.35,
      ),
      headlineLarge: _appTextStyle(
        20,
        FontWeight.w700,
        base,
        letterSpacing: 0.38,
      ),
      headlineMedium: _appTextStyle(
        17,
        FontWeight.w700,
        base,
        letterSpacing: -0.41,
      ),
      bodyLarge: _appTextStyle(17, FontWeight.w400, base, letterSpacing: -0.41),
      bodyMedium: _appTextStyle(
        16,
        FontWeight.w400,
        base,
        letterSpacing: -0.32,
      ),
      bodySmall: _appTextStyle(
        15,
        FontWeight.w400,
        muted,
        letterSpacing: -0.23,
      ),
      labelLarge: _appTextStyle(
        13,
        FontWeight.w400,
        muted,
        letterSpacing: -0.08,
      ),
      labelMedium: _appTextStyle(
        12,
        FontWeight.w400,
        muted,
        letterSpacing: 0.0,
      ),
      labelSmall: _appTextStyle(
        11,
        FontWeight.w400,
        muted,
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
  const _WebEntryGate({required this.toggleTheme, required this.setLocale});

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
