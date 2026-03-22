// lib/screens/HomeScreen.dart
//fixed Ui for mobile
// ─────────────────────────────────────────────
//  ARCHITECTURE
//  < 700px  → _MobileShell  (native app, completely redesigned)
//  ≥ 700px  → _WebsiteShell (unchanged)
// ─────────────────────────────────────────────
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import 'TranslateScreen.dart';
import 'TwoWayScreen.dart';
import 'EmergencyScreen.dart';
import 'SignsPage.dart';
import 'objectives/AccessibilityPage.dart';
import 'objectives/BridgingGapsPage.dart';
import 'objectives/InclusivityPage.dart';
import 'objectives/PrivacyPage.dart';
import 'objectives/OfflinePage.dart';
import 'objectives/EducationPage.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _kViolet      = Color(0xFF7C3AED);
const _kVioletLight = Color(0xFFA78BFA);
const _kVioletDeep  = Color(0xFF5B21B6);
const _kVioletSoft  = Color(0xFFEDE9FE);   // light mode tint
const _kObsidian    = Color(0xFF040408);
const _kSurface     = Color(0xFF0C0C16);
const _kSurfaceUp   = Color(0xFF111120);
const _kBorder      = Color(0xFF1C1C30);
const _kBorderBrt   = Color(0xFF2C2C46);
const _kTextPri     = Color(0xFFF0EEFF);
const _kTextSec     = Color(0xFF7070A0);
const _kTextMuted   = Color(0xFF38385A);
const _kCrimson     = Color(0xFFDC2626);
const _kTeal        = Color(0xFF0891B2);
const _kTealLight   = Color(0xFF22D3EE);
const _kGreen       = Color(0xFF059669);
const _kGreenLight  = Color(0xFF34D399);
const _kAmber       = Color(0xFFD97706);

// Light palette
const _lBg        = Color(0xFFF8F7FF);    // warm-cool off-white
const _lBgAlt     = Color(0xFFF0EEFF);    // slightly violet-tinted alternate
const _lSurface   = Color(0xFFFFFFFF);
const _lSurfaceUp = Color(0xFFF4F0FF);
const _lBorder    = Color(0xFFE8E4F4);
const _lBorderBrt = Color(0xFFCCC8E0);
const _lTextPri   = Color(0xFF0A0A20);
const _lTextSec   = Color(0xFF5A5A82);
const _lTextMuted = Color(0xFFB0B0C8);

// ── Shorthand for Nunito text style ──────────
TextStyle _gs(double size, FontWeight weight, Color color, {
  double? height, double? letterSpacing}) =>
    GoogleFonts.nunito(
        fontSize: size, fontWeight: weight, color: color,
        height: height, letterSpacing: letterSpacing);

// ═════════════════════════════════════════════
//  HOME SCREEN
// ═════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const HomeScreen({super.key, required this.toggleTheme, required this.setLocale});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;   // gentle float for hero card
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;
  late Animation<double>   _pulse;
  late Animation<double>   _float;       // 0→1→0 gentle vertical bob

  final ScrollController _scroll    = ScrollController();
  bool _statsVisible = false;
  final GlobalKey _statsKey = GlobalKey();

  int _tab = 0;
  late AnimationController _tabCtrl;
  late Animation<double>   _tabFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _tabCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

    _heroFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _heroCtrl,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(begin: -4.0, end: 4.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);

    _heroCtrl.forward();
    _tabCtrl.forward();
    _scroll.addListener(_checkScroll);
  }

  void _checkScroll() {
    if (_statsVisible) return;
    final obj = _statsKey.currentContext?.findRenderObject();
    if (obj is RenderBox) {
      final pos = obj.localToGlobal(Offset.zero).dy;
      if (pos < MediaQuery.of(context).size.height * 0.9)
        setState(() => _statsVisible = true);
    }
  }

  void _switchTab(int idx) {
    if (idx == _tab) return;
    HapticFeedback.selectionClick();
    _tabCtrl.reverse().then((_) {
      if (mounted) { setState(() => _tab = idx); _tabCtrl.forward(); }
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose(); _pulseCtrl.dispose();
    _floatCtrl.dispose(); _tabCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w      = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (w < 700) return _buildMobile(context, isDark);
    return _buildWebsite(context, isDark, w);
  }

  // ══════════════════════════════════════════════
  //  MOBILE BUILD
  // ══════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    return Scaffold(
      backgroundColor: isDark ? _kObsidian : _lBg,
      extendBody: true,
      body: Stack(children: [
        // Animated mesh gradient background
        Positioned.fill(child: _MeshBg(isDark: isDark, float: _float)),
        SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _tabFade,
            child: _mobileTabBody(ctx, l, isDark),
          ),
        ),
      ]),
      bottomNavigationBar: _BottomNav(
          isDark: isDark, tab: _tab, onTap: _switchTab, l: l),
    );
  }

  Widget _mobileTabBody(BuildContext ctx, AppLocalizations l, bool isDark) {
    switch (_tab) {
      case 0: return _MobileHome(
          isDark: isDark, pulse: _pulse, float: _float,
          heroFade: _heroFade, heroSlide: _heroSlide, l: l,
          toggleTheme: widget.toggleTheme, setLocale: widget.setLocale);
      case 1: return _FeaturePage(isDark: isDark, l: l,
          title: l.t('nav_terminal'), subtitle: 'Real-time ISL sign detection & translation',
          icon: Icons.translate_rounded, accentColor: _kViolet,
          launchLabel: l.t('get_started'),
          onLaunch: () => _push(ctx, TranslateScreen(
              toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
          features: [
            (Icons.center_focus_strong_rounded, 'Camera detection',    'Point camera at signing hands'),
            (Icons.auto_fix_high_rounded,        'Hold to auto-add',    'Stability engine locks signs in'),
            (Icons.translate_rounded,            'Multilingual output', 'Hindi, Marathi, Tamil & more'),
            (Icons.article_rounded,              'Transcript log',      'Full session saved locally'),
          ]);
      case 2: return _FeaturePage(isDark: isDark, l: l,
          title: l.t('nav_signs'), subtitle: '64 ISL signs · Browse & learn',
          icon: Icons.back_hand_rounded, accentColor: _kTeal,
          launchLabel: 'Browse Signs',
          onLaunch: () => _push(ctx, SignsPage(
              toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
          features: [
            (Icons.grid_view_rounded,   '64 signs',      'Complete ISL vocabulary library'),
            (Icons.flip_rounded,        'Flip cards',    'Hand shape + meaning on each card'),
            (Icons.search_rounded,      'Search',        'Find by name, meaning, category'),
            (Icons.category_rounded,    'Filter types',  'Alphabet, numbers, or words'),
          ]);
      case 3: return _FeaturePage(isDark: isDark, l: l,
          title: l.t('nav_bridge'), subtitle: 'Two-way deaf & hearing communication',
          icon: Icons.compare_arrows_rounded, accentColor: _kGreen,
          launchLabel: 'Open Bridge',
          onLaunch: () => _push(ctx, TwoWayScreen(
              toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
          features: [
            (Icons.record_voice_over_rounded, 'Deaf person signs', 'Camera detects & sends sign'),
            (Icons.keyboard_rounded,          'Hearing types',     'Reply in any language'),
            (Icons.chat_bubble_rounded,       'Chat thread',       'Messenger-style history'),
            (Icons.flash_on_rounded,          'Quick phrases',     '12 professional pre-built phrases'),
          ]);
      default: return const SizedBox.shrink();
    }
  }

  void _push(BuildContext ctx, Widget s) => Navigator.push(ctx, PageRouteBuilder(
      pageBuilder: (_, __, ___) => s,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 300)));

  // ══════════════════════════════════════════════
  //  WEBSITE BUILD  (≥700px — unchanged)
  // ══════════════════════════════════════════════
  Widget _buildWebsite(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 96.0 : 48.0;
    final l = AppLocalizations.of(ctx);

    return Scaffold(
      backgroundColor: isDark ? _kObsidian : _lBg,
      body: Stack(children: [
        Positioned.fill(child: _GridBg(isDark: isDark)),
        Positioned(top: -200, left: -100,
            child: _Glow(color: _kViolet.withOpacity(isDark ? 0.20 : 0.08), size: 700)),
        Positioned(bottom: -300, right: -200,
            child: _Glow(color: const Color(0xFF1D4ED8).withOpacity(isDark ? 0.12 : 0.05), size: 600)),
        SafeArea(
          child: SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              GlobalNavbar(toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale, activeRoute: 'home'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(children: [
                  SizedBox(height: isDesktop ? 80 : 56),
                  FadeTransition(opacity: _heroFade,
                      child: SlideTransition(position: _heroSlide,
                          child: Column(children: [
                            _StatusChip(l: l, pulse: _pulse, isDark: isDark),
                            SizedBox(height: isDesktop ? 44 : 32),
                            _HeroText(isDesktop: isDesktop, isTablet: !isDesktop, l: l, isDark: isDark),
                            SizedBox(height: isDesktop ? 28 : 22),
                            _HeroSub(isDesktop: isDesktop, l: l, isDark: isDark),
                            SizedBox(height: isDesktop ? 52 : 40),
                            _CTAButton(label: l.t('get_started'),
                                onTap: () => _push(ctx, TranslateScreen(
                                    toggleTheme: widget.toggleTheme, setLocale: widget.setLocale))),
                          ]))),
                  SizedBox(height: isDesktop ? 120 : 88),
                  _Divider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),
                  Container(key: _statsKey,
                      child: _StatsSection(isDesktop: isDesktop,
                          isVisible: _statsVisible, l: l, isDark: isDark)),
                  SizedBox(height: isDesktop ? 120 : 96),
                  _SectionLabel(text: l.t('obj_heading'), sub: l.t('obj_sub'), isDark: isDark),
                  SizedBox(height: isDesktop ? 56 : 40),
                  _ObjGrid(isDesktop: isDesktop, l: l, isDark: isDark,
                      toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
                  SizedBox(height: isDesktop ? 120 : 96),
                  _VisionCard(l: l, isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),
                  _Footer(isDark: isDark),
                  const SizedBox(height: 48),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  ANIMATED MESH BACKGROUND  (mobile only)
// ═════════════════════════════════════════════
class _MeshBg extends StatelessWidget {
  final bool isDark;
  final Animation<double> float;
  const _MeshBg({required this.isDark, required this.float});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: float,
      builder: (_, __) => Stack(children: [
        // Base grid
        Positioned.fill(child: _GridBg(isDark: isDark)),

        // Ambient blobs that slowly shift
        Positioned(top: -60 + float.value * 0.6, left: -40,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _kViolet.withOpacity(isDark ? 0.20 : 0.10),
                    Colors.transparent,
                  ])),
            )),
        Positioned(top: 180 - float.value * 0.4, right: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _kTeal.withOpacity(isDark ? 0.12 : 0.06),
                    Colors.transparent,
                  ])),
            )),
        Positioned(bottom: 120 + float.value * 0.5, left: -60,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _kVioletLight.withOpacity(isDark ? 0.08 : 0.04),
                    Colors.transparent,
                  ])),
            )),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  MOBILE BOTTOM NAV
// ═════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final bool isDark;
  final int tab;
  final ValueChanged<int> onTap;
  final AppLocalizations l;
  const _BottomNav({required this.isDark, required this.tab,
    required this.onTap, required this.l});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded,           Icons.home_outlined,          'Home'),
      (Icons.translate_rounded,      Icons.translate_outlined,     l.t('nav_terminal')),
      (Icons.back_hand_rounded,      Icons.back_hand_outlined,     l.t('nav_signs')),
      (Icons.compare_arrows_rounded, Icons.compare_arrows_rounded, l.t('nav_bridge')),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF06060F).withOpacity(0.92)
                  : Colors.white.withOpacity(0.90),
              border: Border(top: BorderSide(
                  color: isDark ? _kBorder : _lBorder, width: 0.75))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(children: items.asMap().entries.map((e) {
                final i = e.key; final item = e.value;
                final active = tab == i;
                final accentColor = active ? _kViolet : (isDark ? _kTextSec : _lTextSec);

                return Expanded(child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: active ? 44 : 34,
                        height: active ? 44 : 34,
                        decoration: BoxDecoration(
                            color: active
                                ? _kViolet.withOpacity(isDark ? 0.18 : 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: active
                                ? Border.all(color: _kViolet.withOpacity(0.22))
                                : null),
                        child: Icon(active ? item.$1 : item.$2,
                            color: accentColor, size: active ? 22 : 20)),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.nunito(
                            color: accentColor,
                            fontSize: active ? 10.5 : 9.5,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w600),
                        child: Text(item.$3, overflow: TextOverflow.ellipsis)),
                  ]),
                ));
              }).toList()),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  MOBILE HOME TAB  — next-level redesign
// ═════════════════════════════════════════════
class _MobileHome extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulse, heroFade, float;
  final Animation<Offset> heroSlide;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  const _MobileHome({
    required this.isDark, required this.pulse, required this.heroFade,
    required this.heroSlide, required this.float, required this.l,
    required this.toggleTheme, required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Top bar ───────────────────────────
        _TopBar(isDark: isDark, l: l, pulse: pulse,
            toggleTheme: toggleTheme, setLocale: setLocale),

        // ── Hero glassmorphism card ────────────
        FadeTransition(opacity: heroFade,
            child: SlideTransition(position: heroSlide,
                child: _GlassHero(isDark: isDark, l: l, float: float,
                    toggleTheme: toggleTheme, setLocale: setLocale))),

        const SizedBox(height: 24),

        // ── "At a glance" stats row ────────────
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AnimatedStatsRow(isDark: isDark, l: l)),

        const SizedBox(height: 24),

        // ── Quick action cards ─────────────────
        Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 12),
            child: Text('Quick Access', style: _gs(
                13, FontWeight.w800, isDark ? _kTextMuted : _lTextMuted,
                letterSpacing: 1.0))),
        _QuickRow(isDark: isDark, l: l, context: context,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        // ── Objectives horizontal scroll ───────
        Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 14),
            child: Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                          colors: [_kViolet, _kVioletLight],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              const SizedBox(width: 10),
              Text('What We Stand For', style: _gs(
                  17, FontWeight.w800, isDark ? _kTextPri : _lTextPri,
                  letterSpacing: -0.2)),
            ])),
        _ObjectivesScroll(isDark: isDark, l: l,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        // ── Impact card ───────────────────────
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ImpactCard(isDark: isDark, l: l)),

        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _TopBar({required this.isDark, required this.l, required this.pulse,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final locale  = Localizations.localeOf(context);
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
      child: Row(children: [
        // Brand wordmark
        Row(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_kVioletDeep, _kViolet, _kVioletLight],
                stops: [0.0, 0.5, 1.0],
              ).createShader(b),
              child: Text('VANI', style: GoogleFonts.nunito(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 5))),
          const SizedBox(width: 6),
          AnimatedBuilder(animation: pulse, builder: (_, __) => Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kVioletLight,
                  boxShadow: [BoxShadow(
                      color: _kVioletLight.withOpacity(pulse.value * 0.8),
                      blurRadius: 8, spreadRadius: 1)]))),
        ]),
        const Spacer(),
        // Lang picker
        _LangPill(locale: locale, setLocale: setLocale,
            isDark: isDark, primary: primary),
        const SizedBox(width: 8),
        // Theme toggle
        GestureDetector(
            onTap: toggleTheme,
            child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: isDark ? _kSurfaceUp : _lSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? _kBorder : _lBorder),
                    boxShadow: [if (!isDark) BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8, offset: const Offset(0, 2))]),
                child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 17, color: isDark ? _kTextSec : _lTextSec))),
      ]),
    );
  }
}

class _LangPill extends StatelessWidget {
  final Locale locale;
  final Function(Locale) setLocale;
  final bool isDark;
  final Color primary;
  const _LangPill({required this.locale, required this.setLocale,
    required this.isDark, required this.primary});
  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧'},
      {'code': 'hi', 'flag': '🇮🇳'},
      {'code': 'mr', 'flag': '🇮🇳'},
    ];
    final cur = langs.firstWhere(
            (l) => l['code'] == locale.languageCode, orElse: () => langs[0]);
    return PopupMenuButton<String>(
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF141428) : Colors.white,
        elevation: 16,
        onSelected: (c) => setLocale(Locale(c)),
        itemBuilder: (_) => langs.map((lang) => PopupMenuItem<String>(
            value: lang['code'],
            child: Row(children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(lang['code']!.toUpperCase(), style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: lang['code'] == locale.languageCode
                      ? primary : (isDark ? Colors.white70 : Colors.black87))),
              if (lang['code'] == locale.languageCode) ...[
                const Spacer(),
                Icon(Icons.check_circle_rounded, color: primary, size: 15)],
            ]))).toList(),
        child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.18))),
            child: Center(child: Text(cur['flag']!,
                style: const TextStyle(fontSize: 18)))));
  }
}

// ─────────────────────────────────────────────
//  GLASS HERO CARD  — the centrepiece
//  Gradient background, glassmorphism surface,
//  animated orb, headline, full-width CTA.
// ─────────────────────────────────────────────
class _GlassHero extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final Animation<double> float;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _GlassHero({required this.isDark, required this.l,
    required this.float, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF1A0A38),
                  const Color(0xFF0C1628),
                  const Color(0xFF0A0A20),
                ]
                    : [
                  const Color(0xFFEDE9FE),
                  const Color(0xFFDDD6FE),
                  const Color(0xFFE0F2FE),
                ],
                stops: const [0.0, 0.55, 1.0]),
            border: Border.all(
                color: isDark
                    ? _kViolet.withOpacity(0.25)
                    : _kViolet.withOpacity(0.18),
                width: 1.0),
            boxShadow: [
              BoxShadow(
                  color: _kViolet.withOpacity(isDark ? 0.20 : 0.12),
                  blurRadius: 32, offset: const Offset(0, 12)),
              if (!isDark) BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 0, offset: const Offset(-1, -1)),
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(children: [

            // Floating orb decoration
            AnimatedBuilder(
                animation: float,
                builder: (_, __) => Positioned(
                  top: -20 + float.value,
                  right: -30,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _kVioletLight.withOpacity(isDark ? 0.22 : 0.30),
                          Colors.transparent,
                        ])),
                  ),
                )),
            AnimatedBuilder(
                animation: float,
                builder: (_, __) => Positioned(
                  bottom: -10 - float.value * 0.5,
                  left: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _kTeal.withOpacity(isDark ? 0.14 : 0.16),
                          Colors.transparent,
                        ])),
                  ),
                )),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Badge pill
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : _kViolet.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.14)
                                : _kViolet.withOpacity(0.22))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? _kVioletLight : _kViolet,
                              boxShadow: [BoxShadow(
                                  color: _kViolet.withOpacity(0.5),
                                  blurRadius: 6)])),
                      const SizedBox(width: 7),
                      Text('ISL · On-Device AI · Offline', style: GoogleFonts.nunito(
                          color: isDark ? _kVioletLight : _kVioletDeep,
                          fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ])),

                const SizedBox(height: 16),

                // Headline
                Text('Sign Language\nTo Text,', style: GoogleFonts.nunito(
                    fontSize: 32, fontWeight: FontWeight.w900, height: 1.10,
                    color: isDark ? const Color(0xFFF0EEFF) : const Color(0xFF1A0A40),
                    letterSpacing: -0.5)),

                // Gradient word
                ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: isDark
                          ? [_kVioletLight, const Color(0xFF60A5FA)]
                          : [_kViolet, const Color(0xFF0891B2)],
                    ).createShader(b),
                    child: Text('Instantly.', style: GoogleFonts.nunito(
                        fontSize: 32, fontWeight: FontWeight.w900, height: 1.10,
                        color: Colors.white, letterSpacing: -0.5))),

                const SizedBox(height: 12),

                Text(
                    'Empowering India\'s 63M+ deaf & mute\ncommunity — private, accurate, offline.',
                    style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.white.withOpacity(0.60)
                            : _kVioletDeep.withOpacity(0.65),
                        height: 1.65)),

                const SizedBox(height: 20),

                // CTA button — full width, glass style
                GestureDetector(
                    onTap: () => Navigator.push(ctx, PageRouteBuilder(
                        pageBuilder: (_, __, ___) => TranslateScreen(
                            toggleTheme: toggleTheme, setLocale: setLocale),
                        transitionsBuilder: (_, a, __, c) =>
                            FadeTransition(opacity: a, child: c),
                        transitionDuration: const Duration(milliseconds: 300))),
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: isDark
                                    ? [_kViolet, _kVioletDeep]
                                    : [_kVioletDeep, _kViolet]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                                color: _kViolet.withOpacity(isDark ? 0.45 : 0.35),
                                blurRadius: 20, offset: const Offset(0, 8))]),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.translate_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(l.t('get_started'), style: GoogleFonts.nunito(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 16),
                            ]))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED STATS ROW  (count-up animation)
// ─────────────────────────────────────────────
class _AnimatedStatsRow extends StatefulWidget {
  final bool isDark;
  final AppLocalizations l;
  const _AnimatedStatsRow({required this.isDark, required this.l});
  @override
  State<_AnimatedStatsRow> createState() => _AnimatedStatsRowState();
}

class _AnimatedStatsRowState extends State<_AnimatedStatsRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    // Start after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final d = widget.isDark;
          final stats = [
            (_fmt((63000000 * _anim.value).toInt()), '+',
            widget.l.t('stat_mute_label'), _kVioletLight),
            (_fmt((8435000 * _anim.value).toInt()), '+',
            widget.l.t('stat_isl_label'), _kVioletLight),
            ((250 * _anim.value).toInt().toString(), '',
            widget.l.t('stat_translators_label'), _kCrimson),
          ];

          return Container(
            decoration: BoxDecoration(
                color: d ? _kSurface : _lSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: d ? _kBorder : _lBorder),
                boxShadow: [if (!d) BoxShadow(
                    color: _kViolet.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 4))]),
            child: Row(children: stats.asMap().entries.map((e) {
              final s = e.value;
              final last = e.key == stats.length - 1;
              return Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                  decoration: BoxDecoration(border: last ? null : Border(
                      right: BorderSide(color: d ? _kBorder : _lBorder))),
                  child: Column(children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: s.$1, style: GoogleFonts.nunito(
                          color: s.$4, fontSize: 19,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      TextSpan(text: s.$2, style: GoogleFonts.nunito(
                          color: s.$4.withOpacity(0.60), fontSize: 13,
                          fontWeight: FontWeight.w900)),
                    ])),
                    const SizedBox(height: 4),
                    Text(s.$3, textAlign: TextAlign.center, style: GoogleFonts.nunito(
                        color: d ? _kTextSec : _lTextSec,
                        fontSize: 8.5, height: 1.3, fontWeight: FontWeight.w600)),
                  ])));
            }).toList()),
          );
        });
  }

  String _fmt(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─────────────────────────────────────────────
//  QUICK ACTION ROW
// ─────────────────────────────────────────────
class _QuickRow extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final BuildContext context;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _QuickRow({required this.isDark, required this.l, required this.context,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext ctx) {
    final cards = [
      (_kTeal,    _kTealLight,  Icons.compare_arrows_rounded, 'Bridge',  'Two-Way',
      TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_kCrimson, const Color(0xFFEF4444), Icons.emergency_rounded, 'SOS', 'Alert',
      EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_kGreen,   _kGreenLight, Icons.back_hand_rounded, 'Signs', 'Library',
      SignsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    return SizedBox(
        height: 110,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            itemBuilder: (_, i) {
              final c = cards[i];
              return Padding(
                  padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
                  child: _QuickCard(
                      color: c.$1, accent: c.$2, icon: c.$3,
                      line1: c.$4, line2: c.$5,
                      isDark: isDark,
                      onTap: () => Navigator.push(ctx, PageRouteBuilder(
                          pageBuilder: (_, __, ___) => c.$6,
                          transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ch),
                          transitionDuration: const Duration(milliseconds: 280)))));
            }));
  }
}

class _QuickCard extends StatefulWidget {
  final Color color, accent;
  final IconData icon;
  final String line1, line2;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickCard({required this.color, required this.accent,
    required this.icon, required this.line1, required this.line2,
    required this.isDark, required this.onTap});
  @override
  State<_QuickCard> createState() => _QuickCardState();
}
class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
          scale: _pressed ? 0.91 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutBack,
          child: Container(
              width: 114,
              decoration: BoxDecoration(
                  color: widget.isDark ? _kSurfaceUp : _lSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.color.withOpacity(widget.isDark ? 0.28 : 0.18),
                      width: 1.0),
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withOpacity(widget.isDark ? 0.14 : 0.09),
                        blurRadius: 18, offset: const Offset(0, 6)),
                    if (!widget.isDark) BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 0, offset: const Offset(-1, -1)),
                  ]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [
                              widget.color.withOpacity(widget.isDark ? 0.20 : 0.12),
                              widget.color.withOpacity(widget.isDark ? 0.08 : 0.05),
                            ]),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: widget.color.withOpacity(0.22))),
                    child: Icon(widget.icon, color: widget.accent, size: 20)),
                const SizedBox(height: 9),
                Text(widget.line1, style: GoogleFonts.nunito(
                    color: widget.isDark ? _kTextPri : _lTextPri,
                    fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text(widget.line2, style: GoogleFonts.nunito(
                    color: widget.isDark ? _kTextSec : _lTextSec,
                    fontSize: 10, fontWeight: FontWeight.w600)),
              ]))));
}

// ─────────────────────────────────────────────
//  OBJECTIVES HORIZONTAL SCROLL
// ─────────────────────────────────────────────
class _ObjectivesScroll extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _ObjectivesScroll({required this.isDark, required this.l,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.accessibility_new_rounded, l.t('obj_accessibility'),
      l.t('obj_accessibility_desc'), const Color(0xFF7C3AED),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.connecting_airports_rounded, l.t('obj_bridging'),
      l.t('obj_bridging_desc'), const Color(0xFF0284C7),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.people_outline_rounded, l.t('obj_inclusivity'),
      l.t('obj_inclusivity_desc'), const Color(0xFF059669),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.shield_outlined, l.t('obj_privacy'),
      l.t('obj_privacy_desc'), const Color(0xFFD97706),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.wifi_off_rounded, l.t('obj_offline'),
      l.t('obj_offline_desc'), const Color(0xFF6366F1),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.school_rounded, l.t('obj_education'),
      l.t('obj_education_desc'), const Color(0xFFDC2626),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];
    return SizedBox(height: 165, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        itemBuilder: (ctx, i) {
          final c = cards[i];
          return Padding(
              padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
              child: _ObjCard(icon: c.$1, title: c.$2, desc: c.$3,
                  color: c.$4, page: c.$5, isDark: isDark));
        }));
  }
}

class _ObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  final Widget page;
  final bool isDark;
  const _ObjCard({required this.icon, required this.title,
    required this.desc, required this.color,
    required this.page, required this.isDark});
  @override
  State<_ObjCard> createState() => _ObjCardState();
}
class _ObjCardState extends State<_ObjCard> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) {
        setState(() => _p = false);
        Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.page,
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 260)));
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
          scale: _p ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutBack,
          child: Container(
              width: 148,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: widget.isDark ? _kSurfaceUp : _lSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.color.withOpacity(widget.isDark ? 0.22 : 0.14),
                      width: 1.0),
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withOpacity(widget.isDark ? 0.10 : 0.07),
                        blurRadius: 14, offset: const Offset(0, 5)),
                    if (!widget.isDark) BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 0, offset: const Offset(-1, -1)),
                  ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [
                              widget.color.withOpacity(widget.isDark ? 0.18 : 0.10),
                              widget.color.withOpacity(widget.isDark ? 0.06 : 0.04),
                            ]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.color.withOpacity(0.18))),
                    child: Icon(widget.icon, color: widget.color, size: 16)),
                const SizedBox(height: 10),
                Text(widget.title, style: GoogleFonts.nunito(
                    color: widget.isDark ? _kTextPri : _lTextPri,
                    fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 5),
                Expanded(child: Text(widget.desc, style: GoogleFonts.nunito(
                    color: widget.isDark ? _kTextSec : _lTextSec,
                    fontSize: 10.5, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
              ]))));
}

// ─────────────────────────────────────────────
//  IMPACT CARD
// ─────────────────────────────────────────────
class _ImpactCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _ImpactCard({required this.isDark, required this.l});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark
                  ? [_kViolet.withOpacity(0.14), _kVioletDeep.withOpacity(0.06)]
                  : [_kVioletSoft, _kVioletSoft.withOpacity(0.50)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: _kViolet.withOpacity(isDark ? 0.22 : 0.14)),
          boxShadow: [BoxShadow(
              color: _kViolet.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kViolet.withOpacity(isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kViolet.withOpacity(0.20))),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: _kVioletLight, size: 16)),
          const SizedBox(width: 10),
          Text('Our Mission', style: GoogleFonts.nunito(
              color: isDark ? _kVioletLight : _kViolet,
              fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 12),
        Text(l.t('vision_title'), style: GoogleFonts.nunito(
            color: isDark ? _kVioletLight : _kVioletDeep,
            fontSize: 17, fontWeight: FontWeight.w900,
            letterSpacing: -0.3, height: 1.2)),
        const SizedBox(height: 10),
        Text(
            'With only 1 certified translator for every 33,000+ deaf individuals '
                'in India, VANI bridges the gap — delivering real-time sign language '
                'translation on your device, privately.',
            style: GoogleFonts.nunito(
                fontSize: 13, height: 1.65,
                color: isDark ? _kTextSec : _kVioletDeep.withOpacity(0.65))),
        const SizedBox(height: 14),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: _kCrimson.withOpacity(isDark ? 0.10 : 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kCrimson.withOpacity(0.25))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: _kCrimson, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('1 interpreter : 33,000+ people', style: GoogleFonts.nunito(
                  color: _kCrimson.withOpacity(0.90), fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
            ])),
      ]));
}

// ═════════════════════════════════════════════
//  FEATURE PAGE  (tabs 1-3) — refreshed with Nunito
// ═════════════════════════════════════════════
class _FeaturePage extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final String title, subtitle, launchLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onLaunch;
  final List<(IconData, String, String)> features;
  const _FeaturePage({required this.isDark, required this.l,
    required this.title, required this.subtitle, required this.icon,
    required this.accentColor, required this.onLaunch,
    required this.launchLabel, required this.features});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Feature hero
        Container(
            width: double.infinity, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(isDark ? 0.20 : 0.11),
                      accentColor.withOpacity(isDark ? 0.05 : 0.02)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: accentColor.withOpacity(isDark ? 0.30 : 0.18)),
                boxShadow: [BoxShadow(
                    color: accentColor.withOpacity(isDark ? 0.12 : 0.07),
                    blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(isDark ? 0.20 : 0.12),
                            accentColor.withOpacity(isDark ? 0.06 : 0.04)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.28))),
                  child: Icon(icon, color: accentColor, size: 26)),
              const SizedBox(height: 14),
              Text(title, style: GoogleFonts.nunito(
                  color: isDark ? _kTextPri : _lTextPri,
                  fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(subtitle, style: GoogleFonts.nunito(
                  color: isDark ? _kTextSec : _lTextSec,
                  fontSize: 13.5, height: 1.5)),
            ])),

        const SizedBox(height: 22),

        Text("What's Inside", style: GoogleFonts.nunito(
            color: isDark ? _kTextMuted : _lTextMuted,
            fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
        const SizedBox(height: 10),

        ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: isDark ? _kSurfaceUp : _lSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark ? _kBorder : _lBorder)),
                child: Row(children: [
                  Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            accentColor.withOpacity(isDark ? 0.14 : 0.09),
                            accentColor.withOpacity(isDark ? 0.04 : 0.02)]),
                          borderRadius: BorderRadius.circular(11)),
                      child: Icon(f.$1, color: accentColor, size: 17)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.$2, style: GoogleFonts.nunito(
                        color: isDark ? _kTextPri : _lTextPri,
                        fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(f.$3, style: GoogleFonts.nunito(
                        color: isDark ? _kTextSec : _lTextSec,
                        fontSize: 11.5, height: 1.4)),
                  ])),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: isDark ? _kTextMuted : _lTextMuted, size: 11),
                ])))),

        const SizedBox(height: 24),

        // Launch CTA
        GestureDetector(
            onTap: onLaunch,
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.80)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: accentColor.withOpacity(0.42),
                        blurRadius: 20, offset: const Offset(0, 8))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(launchLabel, style: GoogleFonts.nunito(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ]))),
      ]));
}

// ═════════════════════════════════════════════
//  WEBSITE COMPONENTS  (≥700px — Nunito applied)
// ═════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final AppLocalizations l; final Animation<double> pulse; final bool isDark;
  const _StatusChip({required this.l, required this.pulse, required this.isDark});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: isDark ? _kSurfaceUp : _lSurface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _kViolet.withOpacity(isDark ? 0.32 : 0.18)),
              boxShadow: [BoxShadow(
                  color: _kViolet.withOpacity(pulse.value * (isDark ? 0.14 : 0.05)),
                  blurRadius: 18)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(
                shape: BoxShape.circle, color: _kVioletLight,
                boxShadow: [BoxShadow(
                    color: _kVioletLight.withOpacity(pulse.value * 0.75),
                    blurRadius: 7, spreadRadius: 1)])),
            const SizedBox(width: 9),
            Text(l.t('badge'), style: GoogleFonts.nunito(
                color: isDark ? _kVioletLight : _kViolet,
                fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: 0.3)),
          ])));
}

class _HeroText extends StatelessWidget {
  final bool isDesktop, isTablet; final AppLocalizations l; final bool isDark;
  const _HeroText({required this.isDesktop, required this.isTablet,
    required this.l, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final fs = isDesktop ? 70.0 : 50.0;
    final ls = isDesktop ? -2.0 : -1.0;
    final color = isDark ? _kTextPri : _lTextPri;
    return Column(children: [
      Text(l.t('hero_title_1'), textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: fs, fontWeight: FontWeight.w900,
              color: color, height: 1.10, letterSpacing: ls)),
      ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [_kViolet, _kVioletLight, Color(0xFF60A5FA)],
              stops: [0.0, 0.55, 1.0]).createShader(b),
          child: Text(l.t('hero_title_highlight'), textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: fs, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1.10, letterSpacing: ls))),
      if (l.t('hero_title_2').isNotEmpty)
        Text(l.t('hero_title_2'), textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: fs, fontWeight: FontWeight.w900,
                color: color, height: 1.10, letterSpacing: ls)),
    ]);
  }
}

class _HeroSub extends StatelessWidget {
  final bool isDesktop; final AppLocalizations l; final bool isDark;
  const _HeroSub({required this.isDesktop, required this.l, required this.isDark});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 580 : 480),
      child: Text(l.t('hero_sub'), textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
              fontSize: isDesktop ? 17 : 15.5,
              color: isDark ? _kTextSec : _lTextSec,
              height: 1.75, letterSpacing: 0.1)));
}

class _CTAButton extends StatefulWidget {
  final String label; final VoidCallback onTap;
  const _CTAButton({required this.label, required this.onTap});
  @override State<_CTAButton> createState() => _CTAButtonState();
}
class _CTAButtonState extends State<_CTAButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _h
                      ? [const Color(0xFF8B5CF6), _kViolet]
                      : [_kViolet, _kVioletDeep]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kVioletLight.withOpacity(_h ? 0.4 : 0.12)),
                  boxShadow: [BoxShadow(
                      color: _kViolet.withOpacity(_h ? 0.50 : 0.28),
                      blurRadius: _h ? 44 : 22, offset: const Offset(0, 8))]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.label, style: GoogleFonts.nunito(
                    fontSize: 14.5, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 0.4)),
                const SizedBox(width: 12),
                AnimatedSlide(offset: Offset(_h ? 0.25 : 0, 0),
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16)),
              ]))));
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
      height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [
        Colors.transparent, isDark ? _kBorderBrt : const Color(0xFFCCCCE0), Colors.transparent])));
}

class _StatsSection extends StatelessWidget {
  final bool isDesktop, isVisible; final AppLocalizations l; final bool isDark;
  const _StatsSection({required this.isDesktop, required this.isVisible,
    required this.l, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final stats = [
      (value: '63000000', label: l.t('stat_mute_label'), color: _kVioletLight, suffix: '+'),
      (value: '8435000',  label: l.t('stat_isl_label'),  color: _kVioletLight, suffix: '+'),
      (value: '250',      label: l.t('stat_translators_label'), color: _kCrimson, suffix: ''),
    ];
    return IntrinsicHeight(child: Row(children: [
      for (int i = 0; i < stats.length; i++) ...[
        Expanded(child: _StatCell(value: stats[i].value, label: stats[i].label,
            color: stats[i].color, suffix: stats[i].suffix,
            isVisible: isVisible, isDark: isDark)),
        if (i < stats.length - 1)
          Container(width: 1, color: isDark ? _kBorder : const Color(0xFFDDDDEE)),
      ],
    ]));
  }
}

class _StatCell extends StatefulWidget {
  final String value, label, suffix; final Color color; final bool isVisible, isDark;
  const _StatCell({required this.value, required this.label, required this.color,
    required this.suffix, required this.isVisible, required this.isDark});
  @override State<_StatCell> createState() => _StatCellState();
}
class _StatCellState extends State<_StatCell> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _anim = Tween<double>(begin: 0, end: double.parse(widget.value))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
  }
  @override
  void didUpdateWidget(_StatCell old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: AnimatedBuilder(animation: _anim, builder: (_, __) =>
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            RichText(text: TextSpan(children: [
              TextSpan(text: _fmt(_anim.value.toInt()), style: GoogleFonts.nunito(
                  fontSize: 44, fontWeight: FontWeight.w900, color: widget.color,
                  letterSpacing: -1.5, fontFeatures: const [FontFeature.tabularFigures()])),
              TextSpan(text: widget.suffix, style: GoogleFonts.nunito(fontSize: 28,
                  fontWeight: FontWeight.w900, color: widget.color.withOpacity(0.55))),
            ])),
            const SizedBox(height: 10),
            Text(widget.label, textAlign: TextAlign.center, style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: widget.isDark ? _kTextSec : _lTextSec, letterSpacing: 0.3)),
          ])));
}

class _SectionLabel extends StatelessWidget {
  final String text, sub; final bool isDark;
  const _SectionLabel({required this.text, required this.sub, required this.isDark});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            border: Border.all(color: _kViolet.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(6)),
        child: Text('// OBJECTIVES', style: GoogleFonts.nunito(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: _kViolet.withOpacity(0.75), letterSpacing: 2.0))),
    const SizedBox(height: 16),
    Text(text, textAlign: TextAlign.center, style: GoogleFonts.nunito(
        fontSize: 34, fontWeight: FontWeight.w900,
        color: isDark ? _kTextPri : _lTextPri, letterSpacing: -0.8, height: 1.15)),
    const SizedBox(height: 10),
    Text(sub, textAlign: TextAlign.center, style: GoogleFonts.nunito(
        fontSize: 14, color: isDark ? _kTextMuted : _lTextMuted, letterSpacing: 0.15)),
  ]);
}

class _ObjGrid extends StatelessWidget {
  final bool isDesktop; final AppLocalizations l; final bool isDark;
  final VoidCallback toggleTheme; final Function(Locale) setLocale;
  const _ObjGrid({required this.isDesktop, required this.l, required this.isDark,
    required this.toggleTheme, required this.setLocale});
  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.accessibility_new_rounded,   l.t('obj_accessibility'), l.t('obj_accessibility_desc'), const Color(0xFF7C3AED),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.connecting_airports_rounded, l.t('obj_bridging'), l.t('obj_bridging_desc'), const Color(0xFF0284C7),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.people_outline_rounded,      l.t('obj_inclusivity'), l.t('obj_inclusivity_desc'), const Color(0xFF059669),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.shield_outlined,             l.t('obj_privacy'), l.t('obj_privacy_desc'), const Color(0xFFD97706),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.wifi_off_rounded,            l.t('obj_offline'), l.t('obj_offline_desc'), const Color(0xFF6366F1),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (Icons.school_rounded,              l.t('obj_education'), l.t('obj_education_desc'), const Color(0xFFDC2626),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];
    return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isDesktop ? 3 : 2,
        mainAxisSpacing: 14, crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.6 : 1.45,
        children: cards.map((c) => _WebObjCard(
            icon: c.$1, title: c.$2, desc: c.$3,
            accent: c.$4, page: c.$5, isDark: isDark)).toList());
  }
}

class _WebObjCard extends StatefulWidget {
  final IconData icon; final String title, desc;
  final bool isDark; final Color accent; final Widget page;
  const _WebObjCard({required this.icon, required this.title, required this.desc,
    required this.isDark, required this.accent, required this.page});
  @override State<_WebObjCard> createState() => _WebObjCardState();
}
class _WebObjCardState extends State<_WebObjCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___) => widget.page,
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child:
              SlideTransition(position: Tween<Offset>(
                  begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)), child: child)),
              transitionDuration: const Duration(milliseconds: 320))),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: widget.isDark
                      ? (_h ? _kSurfaceUp : _kSurface)
                      : (_h ? Colors.white : const Color(0xFFFAFAFD)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _h ? widget.accent.withOpacity(0.42) : (widget.isDark ? _kBorder : _lBorder),
                      width: _h ? 1.5 : 1.0),
                  boxShadow: _h
                      ? [BoxShadow(color: widget.accent.withOpacity(widget.isDark ? 0.16 : 0.08),
                      blurRadius: 32, offset: const Offset(0, 10))]
                      : [if (!widget.isDark) BoxShadow(color: Colors.black.withOpacity(0.03),
                      blurRadius: 10, offset: const Offset(0, 3))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: widget.accent.withOpacity(widget.isDark ? 0.14 : 0.07),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: widget.accent.withOpacity(_h ? 0.38 : 0.14))),
                          child: Icon(widget.icon, color: widget.accent, size: 18)),
                      const Spacer(),
                      AnimatedOpacity(opacity: _h ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: widget.accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(7)),
                              child: Icon(Icons.arrow_forward_rounded, color: widget.accent, size: 13))),
                    ]),
                    const SizedBox(height: 14),
                    Text(widget.title, style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2,
                        color: widget.isDark ? _kTextPri : _lTextPri)),
                    const SizedBox(height: 5),
                    Text(widget.desc, style: GoogleFonts.nunito(
                        fontSize: 12.5, height: 1.5,
                        color: widget.isDark ? _kTextSec : _lTextSec)),
                    const SizedBox(height: 10),
                    AnimatedOpacity(opacity: _h ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Text('Explore →', style: GoogleFonts.nunito(
                            fontSize: 11.5, fontWeight: FontWeight.w800,
                            color: widget.accent, letterSpacing: 0.2))),
                  ]))));
}

class _VisionCard extends StatelessWidget {
  final AppLocalizations l; final bool isDark;
  const _VisionCard({required this.l, required this.isDark});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 40),
              decoration: BoxDecoration(
                  color: isDark ? _kViolet.withOpacity(0.06) : _kViolet.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kViolet.withOpacity(isDark ? 0.18 : 0.10))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 32, height: 1, color: _kViolet.withOpacity(0.35)),
                  const SizedBox(width: 14),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _kViolet.withOpacity(0.10), shape: BoxShape.circle,
                          border: Border.all(color: _kViolet.withOpacity(0.25))),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: _kVioletLight, size: 22)),
                  const SizedBox(width: 14),
                  Container(width: 32, height: 1, color: _kViolet.withOpacity(0.35)),
                ]),
                const SizedBox(height: 24),
                Text(l.t('vision_title'), textAlign: TextAlign.center, style: GoogleFonts.nunito(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _kVioletLight,
                    letterSpacing: -0.4, height: 1.25)),
                const SizedBox(height: 14),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(l.t('vision_body'), textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: 15,
                            color: isDark ? _kTextSec : _lTextSec, height: 1.75))),
                const SizedBox(height: 28),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: _kCrimson.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kCrimson.withOpacity(0.22))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(
                          color: _kCrimson, shape: BoxShape.circle)),
                      const SizedBox(width: 9),
                      Text('1 translator : 33,000+ people', style: GoogleFonts.nunito(
                          color: _kCrimson.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ])),
              ]))));
}

class _Footer extends StatelessWidget {
  final bool isDark;
  const _Footer({required this.isDark});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(height: 1, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent,
          isDark ? _kBorderBrt : const Color(0xFFCCCCE0), Colors.transparent]))),
    const SizedBox(height: 28),
    Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20, runSpacing: 8, children: [
          ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                  colors: [_kViolet, _kVioletLight]).createShader(b),
              child: Text('VANI', style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 5))),
          Container(width: 1, height: 12,
              color: isDark ? _kBorderBrt : const Color(0xFFCCCCDD)),
          Text('© 2026 — Empowering Silence', style: GoogleFonts.nunito(
              fontSize: 11.5,
              color: isDark ? _kTextMuted : const Color(0xFFAAAAAACC),
              letterSpacing: 0.2)),
        ]),
  ]);
}

// ─────────────────────────────────────────────
//  SHARED BACKGROUND PRIMITIVES
// ─────────────────────────────────────────────
class _GridBg extends StatelessWidget {
  final bool isDark;
  const _GridBg({required this.isDark});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter(isDark: isDark));
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark
          ? const Color(0xFF18182E).withOpacity(0.55)
          : const Color(0xFFE0D8FF).withOpacity(0.60)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width;  x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final dp = Paint()..color = _kViolet.withOpacity(isDark ? 0.10 : 0.05);
    for (double x = 0; x < size.width;  x += step)
      for (double y = 0; y < size.height; y += step)
        canvas.drawCircle(Offset(x, y), 1.0, dp);
  }
  @override bool shouldRepaint(_GridPainter o) => o.isDark != isDark;
}

class _Glow extends StatelessWidget {
  final Color color; final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
          child: const SizedBox.expand()));
}