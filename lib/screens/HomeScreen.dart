// lib/screens/HomeScreen.dart
//
// ╔══════════════════════════════════════════════════════╗
// ║  VANI — Apple-Inspired Premium UI                   ║
// ║  Font: Google Sans (SF Pro equivalent)              ║
// ║  < 700px  → _MobileShell  (iOS design language)    ║
// ║  ≥ 700px  → _WebShell     (macOS/iPadOS design)    ║
// ╚══════════════════════════════════════════════════════╝

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import 'TranslateScreen.dart';
import 'TwoWayScreen.dart';
import 'EmergencyScreen.dart';
import 'Signspage.dart';
import 'objectives/AccessibilityPage.dart';
import 'objectives/BridgingGapsPage.dart';
import 'objectives/InclusivityPage.dart';
import 'objectives/PrivacyPage.dart';
import 'objectives/OfflinePage.dart';
import 'objectives/EducationPage.dart';

// ─────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS  (mirroring iOS HIG exactly)
// ─────────────────────────────────────────────────────────

// System colours (light-mode values; dark variants suffixed _D)
const _blue      = Color(0xFF007AFF);
const _blue_D    = Color(0xFF0A84FF);
const _indigo    = Color(0xFF5856D6);
const _indigo_D  = Color(0xFF5E5CE6);
const _teal      = Color(0xFF32ADE6);
const _teal_D    = Color(0xFF5AC8F5);
const _green     = Color(0xFF34C759);
const _green_D   = Color(0xFF30D158);
const _red       = Color(0xFFFF3B30);
const _red_D     = Color(0xFFFF453A);
const _orange    = Color(0xFFFF9500);
const _orange_D  = Color(0xFFFF9F0A);

// Semantic surface colours — light
const _lBg       = Color(0xFFF2F2F7);   // systemGroupedBackground
const _lSurface  = Color(0xFFFFFFFF);   // secondarySystemGroupedBackground
const _lSep      = Color(0xFFC6C6C8);   // separator
const _lLabel    = Color(0xFF000000);
const _lLabel2   = Color(0x993C3C43);   // 60 % opacity
const _lLabel3   = Color(0x4D3C3C43);   // 30 % opacity
const _lFill     = Color(0x1F787880);   // systemFill

// Semantic surface colours — dark
const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dSep      = Color(0xFF38383A);
const _dLabel    = Color(0xFFFFFFFF);
const _dLabel2   = Color(0x99EBEBF5);
const _dLabel3   = Color(0x4DEBEBF5);
const _dFill     = Color(0x3A787880);

// ── Shorthand text-style builder (Google Sans = SF Pro) ──
TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

// ══════════════════════════════════════════════════════════
//  HOME SCREEN — router
// ══════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const HomeScreen({super.key, required this.toggleTheme, required this.setLocale});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Entrance animations
  late AnimationController _entranceCtrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  // Subtle ambient pulse (status indicator)
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  // Tab for mobile bottom nav
  int _tab = 0;
  late AnimationController _tabCtrl;
  late Animation<double>   _tabFade;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);

    _entranceCtrl.forward();
    _tabCtrl.forward();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    _tabCtrl.reverse().then((_) {
      if (mounted) { setState(() => _tab = i); _tabCtrl.forward(); }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w      = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ════════════════════════════════════════════
  //  MOBILE  (<700px) — iOS design language
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;
    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: Stack(children: [
        // Very subtle dot-grid ambient background
        Positioned.fill(child: _AmbientBackground(isDark: isDark)),
        SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _tabFade,
            child: _mobileBody(ctx, l, isDark),
          ),
        ),
      ]),
      bottomNavigationBar: _AppleTabBar(
          isDark: isDark, tab: _tab, onTap: _switchTab, l: l),
    );
  }

  Widget _mobileBody(BuildContext ctx, AppLocalizations l, bool isDark) {
    switch (_tab) {
      case 0:
        return _MobileHomeFeed(
            isDark: isDark, fade: _fade, slide: _slide, pulse: _pulse,
            l: l, toggleTheme: widget.toggleTheme, setLocale: widget.setLocale);
      case 1:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.translate_rounded,
            title: l.t('nav_terminal'),
            subtitle: l.t('home_terminal_sub'),
            accentLight: _blue,    accentDark: _blue_D,
            launchLabel: l.t('get_started'),
            onLaunch: () => _push(ctx, TranslateScreen(
                toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.crop_free_rounded,        l.t('home_terminal_b1_title'), l.t('home_terminal_b1_desc')),
              (Icons.lock_rounded,             l.t('home_terminal_b2_title'), l.t('home_terminal_b2_desc')),
              (Icons.translate_rounded,        l.t('home_terminal_b3_title'), l.t('home_terminal_b3_desc')),
              (Icons.receipt_long_rounded,     l.t('home_terminal_b4_title'), l.t('home_terminal_b4_desc')),
            ]);
      case 2:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.back_hand_rounded,
            title: l.t('nav_signs'),
            subtitle: l.t('home_signs_sub'),
            accentLight: _teal,   accentDark: _teal_D,
            launchLabel: l.t('home_browse_signs'),
            onLaunch: () => _push(ctx, SignsPage(
                toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.grid_view_rounded,        l.t('home_signs_b1_title'), l.t('home_signs_b1_desc')),
              (Icons.flip_to_front_rounded,    l.t('home_signs_b2_title'), l.t('home_signs_b2_desc')),
              (Icons.search_rounded,           l.t('home_signs_b3_title'), l.t('home_signs_b3_desc')),
              (Icons.sort_rounded,             l.t('home_signs_b4_title'), l.t('home_signs_b4_desc')),
            ]);
      case 3:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.compare_arrows_rounded,
            title: l.t('nav_bridge'),
            subtitle: l.t('home_bridge_sub'),
            accentLight: _green,  accentDark: _green_D,
            launchLabel: l.t('home_open_bridge'),
            onLaunch: () => _push(ctx, TwoWayScreen(
                toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.sign_language_rounded,      l.t('home_bridge_b1_title'), l.t('home_bridge_b1_desc')),
              (Icons.keyboard_alt_rounded,       l.t('home_bridge_b2_title'), l.t('home_bridge_b2_desc')),
              (Icons.chat_bubble_outline_rounded,l.t('home_bridge_b3_title'), l.t('home_bridge_b3_desc')),
              (Icons.flash_on_rounded,           l.t('home_bridge_b4_title'), l.t('home_bridge_b4_desc')),
            ]);
      default: return const SizedBox.shrink();
    }
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 280)));

  // ════════════════════════════════════════════
  //  WEB / TABLET  (≥700px) — macOS HIG feel
  // ════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 96.0 : 52.0;
    final l = AppLocalizations.of(ctx);

    return Scaffold(
      backgroundColor: isDark ? _dBg : _lBg,
      body: Stack(children: [
        Positioned.fill(child: _AmbientBackground(isDark: isDark)),
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              // ── Navbar ───────────────────────────────────────
              GlobalNavbar(toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale, activeRoute: 'home'),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(children: [
                  SizedBox(height: isDesktop ? 80 : 56),

                  // ── Hero ──────────────────────────────────────
                  FadeTransition(opacity: _fade,
                      child: SlideTransition(position: _slide,
                          child: _WebHero(
                              isDesktop: isDesktop, isDark: isDark, l: l,
                              pulse: _pulse,
                              onCTA: () => _push(ctx, TranslateScreen(
                                  toggleTheme: widget.toggleTheme,
                                  setLocale: widget.setLocale))))),

                  SizedBox(height: isDesktop ? 96 : 72),
                  _WebDivider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),

                  // ── Stats ─────────────────────────────────────
                  _WebStats(isDesktop: isDesktop, isDark: isDark, l: l),

                  SizedBox(height: isDesktop ? 96 : 72),
                  _WebDivider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),

                  // ── Objectives ────────────────────────────────
                  _WebSectionHeader(
                      label: l.t('obj_heading').toUpperCase(),
                      title: l.t('obj_heading'),
                      sub: l.t('obj_sub'),
                      isDark: isDark),
                  SizedBox(height: isDesktop ? 52 : 40),
                  _WebObjectivesGrid(
                      isDesktop: isDesktop, isDark: isDark, l: l,
                      toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),

                  SizedBox(height: isDesktop ? 96 : 72),

                  // ── Vision card ───────────────────────────────
                  _WebVisionCard(isDark: isDark, l: l),

                  SizedBox(height: isDesktop ? 72 : 56),
                  _WebFooter(isDark: isDark),
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

// ══════════════════════════════════════════════════════════
//  AMBIENT BACKGROUND  — very subtle, Apple-like
// ══════════════════════════════════════════════════════════
class _AmbientBackground extends StatelessWidget {
  final bool isDark;
  const _AmbientBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter(isDark: isDark));
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.035)
          : Colors.black.withOpacity(0.030);
    const step = 28.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter o) => o.isDark != isDark;
}

// ══════════════════════════════════════════════════════════
//  APPLE TAB BAR  — iOS exact proportions
// ══════════════════════════════════════════════════════════
class _AppleTabBar extends StatelessWidget {
  final bool isDark;
  final int  tab;
  final ValueChanged<int> onTap;
  final AppLocalizations l;
  const _AppleTabBar({
    required this.isDark, required this.tab,
    required this.onTap, required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _blue_D : _blue;
    final items  = [
      (Icons.house_rounded,           Icons.house_outlined,           l.t('nav_home')),
      (Icons.translate_rounded,       Icons.translate_outlined,       l.t('nav_terminal')),
      (Icons.back_hand_rounded,       Icons.back_hand_outlined,       l.t('nav_signs')),
      (Icons.compare_arrows_rounded,  Icons.compare_arrows_outlined,  l.t('nav_bridge')),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
              color: isDark
                  ? _dSurface.withOpacity(0.80)
                  : _lSurface.withOpacity(0.88),
              border: Border(top: BorderSide(
                  color: isDark ? _dSep : _lSep.withOpacity(0.50),
                  width: 0.5))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 49,
              child: Row(children: items.asMap().entries.map((e) {
                final i      = e.key;
                final item   = e.value;
                final active = tab == i;
                final color  = active ? accent : (isDark ? _dLabel2 : _lLabel2);

                return Expanded(child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                              active ? item.$1 : item.$2,
                              key: ValueKey(active),
                              size: 24, color: color)),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                              fontFamily:  'Google Sans',
                              fontSize:    10,
                              fontWeight:  active ? FontWeight.w600 : FontWeight.w400,
                              color:       color,
                              letterSpacing: -0.1),
                          child: Text(item.$3,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ));
              }).toList()),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MOBILE HOME FEED
// ══════════════════════════════════════════════════════════
class _MobileHomeFeed extends StatelessWidget {
  final bool isDark;
  final Animation<double> fade, pulse;
  final Animation<Offset> slide;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  const _MobileHomeFeed({
    required this.isDark, required this.fade, required this.slide,
    required this.pulse, required this.l,
    required this.toggleTheme, required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Navigation bar area ─────────────────────
        _MobileNavBar(isDark: isDark, l: l, pulse: pulse,
            toggleTheme: toggleTheme, setLocale: setLocale),

        // ── Hero card ──────────────────────────────
        FadeTransition(opacity: fade,
            child: SlideTransition(position: slide,
                child: _MobileHeroCard(isDark: isDark, l: l,
                    toggleTheme: toggleTheme, setLocale: setLocale))),

        const SizedBox(height: 20),

        // ── Stats strip ────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MobileStatsStrip(isDark: isDark, l: l),
        ),

        const SizedBox(height: 28),

        // ── Section: Quick Access ───────────────────
        _SectionTitle(text: l.t('home_quick_access'), isDark: isDark,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12)),
        _QuickAccessRow(isDark: isDark, l: l,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        // ── Section: Objectives ─────────────────────
        _SectionTitle(text: l.t('obj_heading'), isDark: isDark,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14)),
        _MobileObjectivesScroll(isDark: isDark, l: l,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        // ── Mission card ────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MobileMissionCard(isDark: isDark, l: l),
        ),

        const SizedBox(height: 12),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE NAV BAR  (iOS large-title style top bar)
// ─────────────────────────────────────────────
class _MobileNavBar extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileNavBar({required this.isDark, required this.l,
    required this.pulse, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _blue_D : _blue;
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Logotype
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.t('app_title_short'), style: _t(26, FontWeight.w700, isDark ? _dLabel : _lLabel,
                ls: 4.0)),
            const SizedBox(width: 8),
            AnimatedBuilder(
                animation: pulse,
                builder: (_, __) => Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: accent,
                        boxShadow: [BoxShadow(
                            color: accent.withOpacity(pulse.value * 0.6),
                            blurRadius: 6, spreadRadius: 1)]))),
          ]),
            Text(l.t('home_tagline'),
              style: _t(11, FontWeight.w400, isDark ? _dLabel2 : _lLabel2, ls: 0.2)),
        ]),
        const Spacer(),
        // Lang selector
        _LangButton(locale: locale, setLocale: setLocale,
          isDark: isDark, accent: accent, l: l),
        const SizedBox(width: 8),
        // Theme toggle — iOS-style filled circle button
        _IconPill(
            icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            isDark: isDark,
            onTap: toggleTheme),
      ]),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconPill({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: isDark ? _dFill : _lFill,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17,
              color: isDark ? _dLabel2 : _lLabel2)),
    );
  }
}

class _LangButton extends StatelessWidget {
  final Locale locale;
  final Function(Locale) setLocale;
  final bool isDark;
  final Color accent;
  final AppLocalizations l;
  const _LangButton({required this.locale, required this.setLocale,
    required this.isDark, required this.accent, required this.l});

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧', 'name': l.t('lang_en')},
      {'code': 'hi', 'flag': '🇮🇳', 'name': l.t('lang_hi')},
      {'code': 'mr', 'flag': '🇮🇳', 'name': l.t('lang_mr')},
    ];
    final cur = langs.firstWhere(
            (l) => l['code'] == locale.languageCode, orElse: () => langs[0]);
    return PopupMenuButton<String>(
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? _dSurface2 : _lSurface,
        elevation: 12,
        onSelected: (c) => setLocale(Locale(c)),
        itemBuilder: (_) => langs.map((lang) => PopupMenuItem<String>(
            value: lang['code'],
            child: Row(children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text(lang['name']!, style: _t(13.5, FontWeight.w500,
                  lang['code'] == locale.languageCode ? accent
                      : (isDark ? _dLabel : _lLabel))),
              if (lang['code'] == locale.languageCode) ...[
                const Spacer(),
                Icon(Icons.check_rounded, color: accent, size: 16)],
            ]))).toList(),
        child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
            child: Center(child: Text(cur['flag']!,
                style: const TextStyle(fontSize: 17)))));
  }
}

// ─────────────────────────────────────────────
//  MOBILE HERO CARD
//  Glass morphism, Apple feel:
//  white/slightly-tinted card, crisp shadow,
//  blue CTA button (system blue)
// ─────────────────────────────────────────────
class _MobileHeroCard extends StatefulWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileHeroCard({required this.isDark, required this.l,
    required this.toggleTheme, required this.setLocale});
  @override
  State<_MobileHeroCard> createState() => _MobileHeroCardState();
}

class _MobileHeroCardState extends State<_MobileHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _aCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _aCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _anim  = CurvedAnimation(parent: _aCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _aCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? _blue_D : _blue;
    final bg     = widget.isDark ? _dSurface : _lSurface;
    final label  = widget.isDark ? _dLabel   : _lLabel;
    final label2 = widget.isDark ? _dLabel2  : _lLabel2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.45 : 0.10),
                    blurRadius: 32, offset: const Offset(0, 12)),
                if (!widget.isDark)
                  BoxShadow(
                      color: accent.withOpacity(0.06),
                      blurRadius: 48, offset: const Offset(0, 16)),
              ],
              border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  width: 0.5)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(children: [
              // Gentle ambient gradient
              Positioned(
                top: -40 + _anim.value * 8, right: -40,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        accent.withOpacity(widget.isDark ? 0.12 : 0.08),
                        Colors.transparent,
                      ])),
                ),
              ),
              Positioned(
                bottom: -30 - _anim.value * 6, left: -20,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _indigo.withOpacity(widget.isDark ? 0.08 : 0.05),
                        Colors.transparent,
                      ])),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: child!,
              ),
            ]),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            _AppleBadge(
              label: widget.l.t('home_mobile_badge'),
                accent: widget.isDark ? _blue_D : _blue,
                isDark: widget.isDark),
            const SizedBox(height: 16),

            // Headline — SF Display style
            Text(widget.l.t('hero_title_line1'), style: _t(
                34, FontWeight.w700, label, ls: -0.5, h: 1.08)),
            // Accent word in system blue
            Text(widget.l.t('hero_title_line2'), style: _t(34, FontWeight.w700, accent, ls: -0.5, h: 1.08)),

            const SizedBox(height: 12),

            Text(widget.l.t('hero_sub'),
              style: _t(14, FontWeight.w400, label2, ls: -0.2, h: 1.55)),

            const SizedBox(height: 22),

            // CTA — system-blue filled button (iOS standard)
            _AppleFilledButton(
                label: widget.l.t('get_started'),
                icon: Icons.arrow_forward_rounded,
                accent: widget.isDark ? _blue_D : _blue,
                onTap: () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => TranslateScreen(
                        toggleTheme: widget.toggleTheme,
                        setLocale: widget.setLocale),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 280)))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE STATS STRIP  — iOS info-strip style
// ─────────────────────────────────────────────
class _MobileStatsStrip extends StatefulWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobileStatsStrip({required this.isDark, required this.l});
  @override
  State<_MobileStatsStrip> createState() => _MobileStatsStripState();
}

class _MobileStatsStripState extends State<_MobileStatsStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(0)}M'
      : n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? _dSurface  : _lSurface;
    final sep    = widget.isDark ? _dSep      : _lSep.withOpacity(0.4);
    final label2 = widget.isDark ? _dLabel2   : _lLabel2;

    final stats = [
      (63000000,  '+', widget.l.t('stat_mute_label'),         widget.isDark ? _blue_D  : _blue),
      (8435000,   '+', widget.l.t('stat_isl_label'),          widget.isDark ? _indigo_D : _indigo),
      (250,       '',  widget.l.t('stat_translators_label'),  _red),
    ];

    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.06),
                  blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: stats.asMap().entries.map((e) {
            final i  = e.key; final s = e.value;
            final last = i == stats.length - 1;
            return Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(border: last ? null : Border(
                  right: BorderSide(color: sep, width: 0.5))),
              child: Column(children: [
                Text('${_fmt((s.$1 * _anim.value).toInt())}${s.$2}',
                    style: _t(18, FontWeight.w700, s.$4, ls: -0.5)),
                const SizedBox(height: 3),
                Text(s.$3, textAlign: TextAlign.center,
                    style: _t(9.5, FontWeight.w400, label2, h: 1.3)),
              ]),
            ));
          }).toList()),
        ));
  }
}

// ─────────────────────────────────────────────
//  QUICK ACCESS ROW  — iOS app-icon grid style
// ─────────────────────────────────────────────
// class _QuickAccessRow extends StatelessWidget {
//   final bool isDark;
//   final AppLocalizations l;
//   final VoidCallback toggleTheme;
//   final Function(Locale) setLocale;
//   const _QuickAccessRow({required this.isDark, required this.l,
//     required this.toggleTheme, required this.setLocale});

//   @override
//   Widget build(BuildContext ctx) {
//     final cards = [
//       (_teal,   _teal_D,   Icons.compare_arrows_rounded, l.t('nav_bridge'),    l.t('home_open_bridge'),
//       TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale)),
//       (_red,    _red_D,    Icons.emergency_share_rounded, l.t('nav_emergency'),      l.t('sos_screen_title'),
//       EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale)),
//       (_green,  _green_D,  Icons.back_hand_rounded,       l.t('nav_signs'),    l.t('home_browse_signs'),
//       SignsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
//     ];

//     return SizedBox(
//       height: 108,
//       child: ListView.builder(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           physics: const BouncingScrollPhysics(),
//           itemCount: cards.length,
//           itemBuilder: (_, i) {
//             final c = cards[i];
//             return Padding(
//                 padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
//                 child: _QuickTile(
//                     colorLight: c.$1, colorDark: c.$2,
//                     icon: c.$3, label: c.$4, sub: c.$5,
//                     isDark: isDark,
//                     onTap: () => Navigator.push(ctx, PageRouteBuilder(
//                         pageBuilder: (_, __, ___) => c.$6,
//                         transitionsBuilder: (_, a, __, ch) =>
//                             FadeTransition(opacity: a, child: ch),
//                         transitionDuration: const Duration(milliseconds: 260)))));
//           }),
//     );
//   }
// }

class _QuickAccessRow extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _QuickAccessRow({required this.isDark, required this.l,
    required this.toggleTheme, required this.setLocale});
 
  @override
  Widget build(BuildContext ctx) {
    // accent colours: light / dark
    final cards = [
      // (accentLight, accentDark, icon, label, sub)
      (_teal,   _teal_D,  Icons.compare_arrows_rounded, l.t('nav_bridge'),    l.t('home_open_bridge')),
      (_red,    _red_D,   Icons.emergency_share_rounded, l.t('nav_emergency'), l.t('sos_screen_title')),
      (_green,  _green_D, Icons.back_hand_rounded,       l.t('nav_signs'),     l.t('home_browse_signs')),
    ];
 
    return Padding(
      // same 16px horizontal padding as the rest of the feed
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: cards.asMap().entries.map((e) {
          final i = e.key; final c = e.value;
          final accent = isDark ? c.$2 : c.$1;
 
          // destination widget
          Widget dest() {
            switch (i) {
              case 0: return TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale);
              case 1: return EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale);
              default: return SignsPage(toggleTheme: toggleTheme, setLocale: setLocale);
            }
          }
 
          return Expanded(
            child: Padding(
              // small gap between tiles; last tile has no trailing gap
              padding: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
              child: _QuickTile(
                accent: accent, icon: c.$3,
                label: c.$4, sub: c.$5,
                isDark: isDark,
                onTap: () => Navigator.push(ctx, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => dest(),
                    transitionsBuilder: (_, a, __, ch) =>
                        FadeTransition(opacity: a, child: ch),
                    transitionDuration: const Duration(milliseconds: 260))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
 
// ── REPLACE your existing _QuickTile + _QuickTileState with this ──
 
class _QuickTile extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String label, sub;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickTile({required this.accent, required this.icon,
    required this.label, required this.sub,
    required this.isDark, required this.onTap});
  @override
  State<_QuickTile> createState() => _QuickTileState();
}
 
class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;
 
  @override
  Widget build(BuildContext context) {
    final bg    = widget.isDark ? _dSurface : _lSurface;
    final label = widget.isDark ? _dLabel   : _lLabel;
    final sub   = widget.isDark ? _dLabel2  : _lLabel2;
 
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutBack,
        child: Container(
          // aspect ratio drives height — tile is always square-ish
          // regardless of screen width. Using AspectRatio here so
          // the tile height adapts to whatever width Expanded gives it.
          child: AspectRatio(
            aspectRatio: 0.95,
            child: Container(
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: widget.accent.withOpacity(0.18), width: 0.5),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(widget.isDark ? 0.28 : 0.07),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: widget.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13)),
                      child: Icon(widget.icon, color: widget.accent, size: 20)),
                  const SizedBox(height: 8),
                  Text(widget.label,
                      style: _t(11.5, FontWeight.w700, label),
                      textAlign: TextAlign.center),
                  Text(widget.sub,
                      style: _t(9.5, FontWeight.w400, sub),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 

// class _QuickTile extends StatefulWidget {
//   final Color colorLight, colorDark;
//   final IconData icon;
//   final String label, sub;
//   final bool isDark;
//   final VoidCallback onTap;
//   const _QuickTile({required this.colorLight, required this.colorDark,
//     required this.icon, required this.label, required this.sub,
//     required this.isDark, required this.onTap});
//   @override
//   State<_QuickTile> createState() => _QuickTileState();
// }

// class _QuickTileState extends State<_QuickTile> {
//   bool _pressed = false;
//   Color get _accent => widget.isDark ? widget.colorDark : widget.colorLight;

//   @override
//   Widget build(BuildContext context) {
//     final bg     = widget.isDark ? _dSurface  : _lSurface;
//     final label  = widget.isDark ? _dLabel    : _lLabel;
//     final label2 = widget.isDark ? _dLabel2   : _lLabel2;

//     return GestureDetector(
//       onTapDown:   (_) => setState(() => _pressed = true),
//       onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
//       onTapCancel: ()  => setState(() => _pressed = false),
//       child: AnimatedScale(
//         scale: _pressed ? 0.93 : 1.0,
//         duration: const Duration(milliseconds: 80),
//         curve: Curves.easeOutBack,
//         child: Container(
//           width: 108,
//           decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                   color: _accent.withOpacity(0.18), width: 0.5),
//               boxShadow: [BoxShadow(
//                   color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.07),
//                   blurRadius: 14, offset: const Offset(0, 5))]),
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             Container(
//                 width: 44, height: 44,
//                 decoration: BoxDecoration(
//                     color: _accent.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(13)),
//                 child: Icon(widget.icon, color: _accent, size: 20)),
//             const SizedBox(height: 8),
//             Text(widget.label, style: _t(11.5, FontWeight.w600, label)),
//             Text(widget.sub,   style: _t(10,   FontWeight.w400, label2)),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────
//  OBJECTIVES HORIZONTAL SCROLL
// ─────────────────────────────────────────────
class _MobileObjectivesScroll extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileObjectivesScroll({required this.isDark, required this.l,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (_blue,   Icons.accessibility_new_rounded,    l.t('obj_accessibility'), l.t('obj_accessibility_desc'),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_teal,   Icons.connecting_airports_rounded,  l.t('obj_bridging'),      l.t('obj_bridging_desc'),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_green,  Icons.people_outline_rounded,       l.t('obj_inclusivity'),   l.t('obj_inclusivity_desc'),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_orange, Icons.shield_outlined,              l.t('obj_privacy'),       l.t('obj_privacy_desc'),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_indigo, Icons.wifi_off_rounded,             l.t('obj_offline'),       l.t('obj_offline_desc'),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_red,    Icons.school_rounded,               l.t('obj_education'),     l.t('obj_education_desc'),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    return SizedBox(
      height: 162,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final c = cards[i];
            final accent = isDark ? _darkVariant(c.$1) : c.$1;
            return Padding(
                padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
                child: _ObjCard(
                    icon: c.$2, title: c.$3, desc: c.$4,
                    accent: accent, page: c.$5, isDark: isDark));
          }),
    );
  }

  Color _darkVariant(Color c) {
    if (c == _blue)   return _blue_D;
    if (c == _teal)   return _teal_D;
    if (c == _green)  return _green_D;
    if (c == _orange) return _orange_D;
    if (c == _indigo) return _indigo_D;
    if (c == _red)    return _red_D;
    return c;
  }
}

class _ObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _ObjCard({required this.icon, required this.title,
    required this.desc, required this.accent,
    required this.page, required this.isDark});
  @override
  State<_ObjCard> createState() => _ObjCardState();
}

class _ObjCardState extends State<_ObjCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg    = widget.isDark ? _dSurface  : _lSurface;
    final label = widget.isDark ? _dLabel    : _lLabel;
    final sub   = widget.isDark ? _dLabel2   : _lLabel2;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.page,
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 240)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutBack,
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.accent.withOpacity(0.16), width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.06),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.icon, color: widget.accent, size: 16)),
            const SizedBox(height: 10),
            Text(widget.title, style: _t(12.5, FontWeight.w600, label, h: 1.2)),
            const SizedBox(height: 4),
            Expanded(child: Text(widget.desc,
                style: _t(10.5, FontWeight.w400, sub, h: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE MISSION CARD  — iOS info card style
// ─────────────────────────────────────────────
class _MobileMissionCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobileMissionCard({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface  : _lSurface;
    final label = isDark ? _dLabel    : _lLabel;
    final sub   = isDark ? _dLabel2   : _lLabel2;
    final accent = isDark ? _blue_D : _blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
              blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.volunteer_activism_rounded, color: accent, size: 15)),
          const SizedBox(width: 10),
          Text(l.t('home_our_mission'), style: _t(11, FontWeight.w600, accent, ls: 0.4)),
        ]),
        const SizedBox(height: 12),
        Text(l.t('vision_title'),
            style: _t(17, FontWeight.w700, label, ls: -0.3, h: 1.2)),
        const SizedBox(height: 8),
        Text(l.t('home_mission_body'),
            style: _t(13, FontWeight.w400, sub, ls: -0.1, h: 1.6)),
        const SizedBox(height: 14),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.20), width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5,
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
              const SizedBox(width: 7),
                Text(l.t('obj_crisis_stat'),
                  style: _t(11.5, FontWeight.w600, _red)),
            ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MOBILE FEATURE DETAIL PAGE  (tabs 1-3)
// ══════════════════════════════════════════════════════════
class _FeatureDetail extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final IconData icon;
  final String title, subtitle, launchLabel;
  final Color accentLight, accentDark;
  final VoidCallback onLaunch;
  final List<(IconData, String, String)> bullets;

  const _FeatureDetail({
    required this.isDark, required this.l,
    required this.icon, required this.title, required this.subtitle,
    required this.accentLight, required this.accentDark,
    required this.launchLabel, required this.onLaunch, required this.bullets,
  });

  Color get _accent => isDark ? accentDark : accentLight;

  @override
  Widget build(BuildContext context) {
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final bg     = isDark ? _dSurface: _lSurface;

    return Scaffold(
      backgroundColor: isDark ? _dBg : _lBg,
      body: Stack(children: [
        Positioned.fill(child: _AmbientBackground(isDark: isDark)),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Page title — iOS large title style
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 22),
                child: Text(title, style: _t(28, FontWeight.w700, label, ls: -0.5)),
              ),

              // Hero summary card
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _accent.withOpacity(0.16), width: 0.5),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
                          blurRadius: 14, offset: const Offset(0, 4))]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(icon, color: _accent, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: _t(17, FontWeight.w700, label, ls: -0.3)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: _t(13, FontWeight.w400, label2, ls: -0.1, h: 1.5)),
                    ])),
                  ])),

              const SizedBox(height: 24),

              // "Inside" label — iOS grouped list header style
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(l.t('page_section_header'),
                    style: _t(11, FontWeight.w600,
                        isDark ? _dLabel3 : _lLabel3, ls: 0.6)),
              ),

              // Bullet rows — iOS list cell style
              Container(
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        blurRadius: 10, offset: const Offset(0, 3))]),
                child: Column(children: bullets.asMap().entries.map((e) {
                  final i = e.key; final f = e.value;
                  final isLast = i == bullets.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(children: [
                        Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: _accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(f.$1, color: _accent, size: 16)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$2, style: _t(14, FontWeight.w600, label, ls: -0.2)),
                              const SizedBox(height: 2),
                              Text(f.$3, style: _t(12, FontWeight.w400, label2, ls: -0.1, h: 1.4)),
                            ])),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: isDark ? _dLabel3 : _lLabel3),
                      ]),
                    ),
                    if (!isLast) Divider(indent: 66, height: 0,
                        color: isDark ? _dSep : _lSep.withOpacity(0.5),
                        thickness: 0.5),
                  ]);
                }).toList()),
              ),

              const SizedBox(height: 28),

              // Launch CTA
              _AppleFilledButton(
                  label: launchLabel,
                  icon: Icons.arrow_forward_rounded,
                  accent: _accent,
                  onTap: onLaunch),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SHARED APPLE COMPONENTS
// ══════════════════════════════════════════════════════════

class _AppleBadge extends StatelessWidget {
  final String label;
  final Color  accent;
  final bool   isDark;
  const _AppleBadge({required this.label, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
        const SizedBox(width: 6),
        Text(label, style: _t(10.5, FontWeight.w600, accent, ls: 0.1)),
      ]));
}

class _AppleFilledButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _AppleFilledButton({
    required this.label, required this.icon,
    required this.accent, required this.onTap,
  });
  @override
  State<_AppleFilledButton> createState() => _AppleFilledButtonState();
}

class _AppleFilledButtonState extends State<_AppleFilledButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedOpacity(
          opacity: _pressed ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(widget.label,
                    style: _t(15, FontWeight.w600, Colors.white, ls: -0.2)),
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: 16),
              ]))));
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final EdgeInsets padding;
  const _SectionTitle({required this.text, required this.isDark,
    required this.padding});

  @override
  Widget build(BuildContext context) => Padding(
      padding: padding,
      child: Text(text,
          style: _t(20, FontWeight.w700, isDark ? _dLabel : _lLabel, ls: -0.3)));
}

// ══════════════════════════════════════════════════════════
//  WEB / DESKTOP COMPONENTS  (≥700px)
// ══════════════════════════════════════════════════════════

class _WebHero extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback onCTA;
  const _WebHero({required this.isDesktop, required this.isDark,
    required this.l, required this.pulse, required this.onCTA});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _blue_D : _blue;
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final fs     = isDesktop ? 62.0 : 44.0;
    final title1 = l.t('hero_title_1').replaceAll('\n', ' ');
    final titleH = l.t('hero_title_highlight').replaceAll('\n', ' ');
    final title2 = l.t('hero_title_2').replaceAll('\n', ' ');

    return Column(children: [
      // Status pill — macOS "menu bar extra" feel
      AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: isDark ? _dSurface : _lSurface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: accent.withOpacity(0.22), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
                        blurRadius: 12, offset: const Offset(0, 3)),
                    BoxShadow(
                        color: accent.withOpacity(pulse.value * 0.12),
                        blurRadius: 20),
                  ]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: accent,
                        boxShadow: [BoxShadow(
                            color: accent.withOpacity(pulse.value * 0.7),
                            blurRadius: 6, spreadRadius: 1)])),
                const SizedBox(width: 10),
                Text(l.t('badge'),
                    style: _t(11.5, FontWeight.w500, label2, ls: 0.2)),
              ]))),

      SizedBox(height: isDesktop ? 24 : 18),

      // Web headline: clamp to two lines and autoshrink if needed.
      ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 760),
          child: LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final gradient = LinearGradient(
              colors: isDark ? [_blue_D, _indigo_D] : [_blue, _indigo],
            );

            double size = fs;
            TextSpan spanFor(double fontSize) {
              final base = _t(fontSize, FontWeight.w700, label, ls: -1.6, h: 1.02);
              final highlight = base.copyWith(
                color: null,
                foreground: (Paint()
                  ..shader = gradient.createShader(
                    Rect.fromLTWH(0, 0, maxWidth, fontSize * 1.8),
                  )),
              );

              return TextSpan(children: [
                if (title1.isNotEmpty) TextSpan(text: '$title1 ', style: base),
                TextSpan(text: titleH, style: highlight),
                if (title2.isNotEmpty) TextSpan(text: ' $title2', style: base),
              ]);
            }

            for (int i = 0; i < 28; i++) {
              final tp = TextPainter(
                text: spanFor(size),
                textDirection: TextDirection.ltr,
                maxLines: 2,
              )..layout(maxWidth: maxWidth);
              if (!tp.didExceedMaxLines) break;
              size -= 1;
              if (size <= (isDesktop ? 40 : 30)) break;
            }

            return RichText(
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: spanFor(size),
            );
          })),

        SizedBox(height: isDesktop ? 14 : 10),

      ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 560 : 460),
          child: Text(l.t('hero_sub'),
              textAlign: TextAlign.center,
              style: _t(isDesktop ? 17 : 15.5, FontWeight.w400, label2,
                  ls: -0.2, h: 1.75))),

      SizedBox(height: isDesktop ? 28 : 22),

      // CTA — large filled blue button (system-blue Apple style)
      _WebCTAButton(label: l.t('get_started'), onTap: onCTA,
          isDark: isDark),
    ]);
  }
}

class _WebCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _WebCTAButton({required this.label, required this.onTap, required this.isDark});
  @override
  State<_WebCTAButton> createState() => _WebCTAButtonState();
}

class _WebCTAButtonState extends State<_WebCTAButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? _blue_D : _blue;
    return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onTap,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 17),
                decoration: BoxDecoration(
                    color: _hovered ? accent.withOpacity(0.88) : accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: accent.withOpacity(_hovered ? 0.40 : 0.22),
                        blurRadius: _hovered ? 28 : 14,
                        offset: const Offset(0, 6))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.label,
                      style: _t(15, FontWeight.w600, Colors.white, ls: -0.2)),
                  const SizedBox(width: 10),
                  AnimatedSlide(
                      offset: Offset(_hovered ? 0.3 : 0, 0),
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 16)),
                ]))));
  }
}

class _WebDivider extends StatelessWidget {
  final bool isDark;
  const _WebDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 0.5,
      color: isDark ? _dSep : _lSep.withOpacity(0.5));
}

class _WebStats extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  const _WebStats({required this.isDesktop, required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('63,000,000', '+', l.t('stat_mute_label'),        isDark ? _blue_D  : _blue),
      ('8,435,000',  '+', l.t('stat_isl_label'),         isDark ? _indigo_D : _indigo),
      ('250',        '',  l.t('stat_translators_label'), _red),
    ];
    final bg  = isDark ? _dSurface : _lSurface;
    final sep = isDark ? _dSep : _lSep.withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
              blurRadius: 20, offset: const Offset(0, 6))]),
      child: IntrinsicHeight(child: Row(children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: _WebStatCell(
              value: stats[i].$1, suffix: stats[i].$2,
              label: stats[i].$3, color: stats[i].$4,
              isDark: isDark, isDesktop: isDesktop)),
          if (i < stats.length - 1)
            Container(width: 0.5, color: sep),
        ]
      ])),
    );
  }
}

class _WebStatCell extends StatefulWidget {
  final String value, suffix, label;
  final Color color;
  final bool isDark, isDesktop;
  const _WebStatCell({required this.value, required this.suffix,
    required this.label, required this.color,
    required this.isDark, required this.isDesktop});
  @override
  State<_WebStatCell> createState() => _WebStatCellState();
}

class _WebStatCellState extends State<_WebStatCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  late int _target;

  @override
  void initState() {
    super.initState();
    _target = int.parse(widget.value.replaceAll(',', ''));
    _ctrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2200));
    _anim   = Tween<double>(begin: 0, end: _target.toDouble())
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
          padding: EdgeInsets.symmetric(
              vertical: widget.isDesktop ? 44 : 32, horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            RichText(text: TextSpan(children: [
              TextSpan(text: _fmt(_anim.value.toInt()),
                  style: _t(widget.isDesktop ? 48 : 36, FontWeight.w700,
                      widget.color, ls: -1.5)),
              TextSpan(text: widget.suffix,
                  style: _t(widget.isDesktop ? 28 : 22, FontWeight.w700,
                      widget.color.withOpacity(0.55), ls: -1.0)),
            ])),
            const SizedBox(height: 8),
            Text(widget.label, textAlign: TextAlign.center,
                style: _t(13, FontWeight.w400,
                    widget.isDark ? _dLabel2 : _lLabel2, ls: 0.1)),
          ])));
}

class _WebSectionHeader extends StatelessWidget {
  final String label, title, sub;
  final bool isDark;
  const _WebSectionHeader({required this.label, required this.title,
    required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _blue_D : _blue;
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
          child: Text(label, style: _t(9.5, FontWeight.w600, accent, ls: 1.5))),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center,
          style: _t(34, FontWeight.w700, isDark ? _dLabel : _lLabel, ls: -0.8, h: 1.1)),
      const SizedBox(height: 10),
      Text(sub, textAlign: TextAlign.center,
          style: _t(14, FontWeight.w400, isDark ? _dLabel2 : _lLabel2, ls: -0.1)),
    ]);
  }
}

class _WebObjectivesGrid extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _WebObjectivesGrid({required this.isDesktop, required this.isDark,
    required this.l, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (_blue,   Icons.accessibility_new_rounded,    l.t('obj_accessibility'), l.t('obj_accessibility_desc'),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_teal,   Icons.connecting_airports_rounded,  l.t('obj_bridging'),      l.t('obj_bridging_desc'),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_green,  Icons.people_outline_rounded,       l.t('obj_inclusivity'),   l.t('obj_inclusivity_desc'),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_orange, Icons.shield_outlined,              l.t('obj_privacy'),       l.t('obj_privacy_desc'),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_indigo, Icons.wifi_off_rounded,             l.t('obj_offline'),       l.t('obj_offline_desc'),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_red,    Icons.school_rounded,               l.t('obj_education'),     l.t('obj_education_desc'),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    Color accent(Color c) => isDark ? _darkOf(c) : c;

    return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isDesktop ? 3 : 2,
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.7 : 1.45,
        children: cards.map((c) => _WebObjCard(
            icon: c.$2, title: c.$3, desc: c.$4,
            accent: accent(c.$1), page: c.$5,
            isDark: isDark)).toList());
  }

  Color _darkOf(Color c) {
    if (c == _blue)   return _blue_D;
    if (c == _teal)   return _teal_D;
    if (c == _green)  return _green_D;
    if (c == _orange) return _orange_D;
    if (c == _indigo) return _indigo_D;
    if (c == _red)    return _red_D;
    return c;
  }
}

class _WebObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _WebObjCard({required this.icon, required this.title,
    required this.desc, required this.accent,
    required this.page, required this.isDark});
  @override
  State<_WebObjCard> createState() => _WebObjCardState();
}

class _WebObjCardState extends State<_WebObjCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg    = widget.isDark
        ? (_hovered ? _dSurface2 : _dSurface)
        : (_hovered ? Colors.white : _lSurface);
    final label = widget.isDark ? _dLabel  : _lLabel;
    final sub   = widget.isDark ? _dLabel2 : _lLabel2;

    return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: () => Navigator.push(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => widget.page,
                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                transitionDuration: const Duration(milliseconds: 260))),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _hovered
                            ? widget.accent.withOpacity(0.35)
                            : Colors.black.withOpacity(widget.isDark ? 0.0 : 0.05),
                        width: _hovered ? 1.0 : 0.5),
                    boxShadow: _hovered
                        ? [BoxShadow(
                        color: widget.accent.withOpacity(widget.isDark ? 0.14 : 0.08),
                        blurRadius: 24, offset: const Offset(0, 8))]
                        : [BoxShadow(
                        color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.05),
                        blurRadius: 12, offset: const Offset(0, 3))]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: widget.accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(11)),
                            child: Icon(widget.icon, color: widget.accent, size: 18)),
                        const Spacer(),
                        AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: widget.accent, size: 16)),
                      ]),
                      const SizedBox(height: 14),
                      Text(widget.title,
                          style: _t(15, FontWeight.w600, label, ls: -0.2)),
                      const SizedBox(height: 4),
                      Text(widget.desc,
                          style: _t(12.5, FontWeight.w400, sub, ls: -0.1, h: 1.5)),
                    ]))));
  }
}

class _WebVisionCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _WebVisionCard({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _blue_D : _blue;
    final label  = isDark ? _dLabel  : _lLabel;
    final sub    = isDark ? _dLabel2 : _lLabel2;

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 44),
        decoration: BoxDecoration(
            color: isDark ? _dSurface : _lSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), width: 0.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
                blurRadius: 24, offset: const Offset(0, 8))]),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
              child: Icon(Icons.volunteer_activism_rounded, color: accent, size: 24)),
          const SizedBox(height: 22),
          Text(l.t('vision_title'), textAlign: TextAlign.center,
              style: _t(22, FontWeight.w700, label, ls: -0.4, h: 1.2)),
          const SizedBox(height: 14),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Text(l.t('vision_body'), textAlign: TextAlign.center,
                  style: _t(15, FontWeight.w400, sub, ls: -0.1, h: 1.75))),
          const SizedBox(height: 28),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withOpacity(0.18), width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(l.t('obj_crisis_stat'),
                    style: _t(12.5, FontWeight.w600, _red)),
              ])),
        ]));
  }
}

class _WebFooter extends StatelessWidget {
  final bool isDark;
  const _WebFooter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? _dLabel2 : _lLabel2;
    return Column(children: [
      Divider(height: 1, thickness: 0.5,
          color: isDark ? _dSep : _lSep.withOpacity(0.5)),
      const SizedBox(height: 24),
      Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16, runSpacing: 6,
          children: [
            Text(AppLocalizations.of(context).t('app_title_short'), style: _t(12, FontWeight.w700,
                isDark ? _blue_D : _blue, ls: 4.0)),
            Container(width: 1, height: 11,
                color: isDark ? _dSep : _lSep.withOpacity(0.5)),
            Text('© 2026 — ${AppLocalizations.of(context).t('home_footer')}',
                style: _t(11.5, FontWeight.w400, sub, ls: 0.1)),
          ]),
    ]);
  }
}