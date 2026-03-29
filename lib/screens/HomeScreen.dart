// lib/screens/HomeScreen.dart
//
// ╔══════════════════════════════════════════════════════╗
// ║  VANI — Apple-Inspired Premium UI                   ║
// ║  Font: Google Sans (SF Pro equivalent)              ║
// ║  < 700px  → _MobileShell  (iOS design language)    ║
// ║  ≥ 700px  → _WebShell     (macOS/iPadOS design)    ║
// ║                                                    ║
// ║  CHANGES vs original:                              ║
// ║  • Import ISLAssistantScreen                       ║
// ║  • _AppleTabBar: 5th tab "Assistant" (purple)      ║
// ║  • _mobileBody: case 4 → ISL Assistant detail      ║
// ║  • _MobileHomeFeed: _MobileAssistantCard inserted  ║
// ║    between Quick Access and Objectives             ║
// ║  • _buildWeb: _WebAssistantBanner inserted between ║
// ║    Stats and Objectives sections                   ║
// ║  • GlobalNavbar: activeRoute 'assistant' supported ║
// ╚══════════════════════════════════════════════════════╝

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/GlobalNavbar.dart';
import '../components/SOSFloatingButton.dart';
import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import 'TranslateScreen.dart';
import 'TwoWayScreen.dart';
import 'EmergencyScreen.dart';
import 'Signspage.dart';
import 'ISLAssistantScreen.dart';
import 'objectives/AccessibilityPage.dart';
import 'objectives/BridgingGapsPage.dart';
import 'objectives/InclusivityPage.dart';
import 'objectives/PrivacyPage.dart';
import 'objectives/OfflinePage.dart';
import 'objectives/EducationPage.dart';

// ─────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS  (mirroring iOS HIG exactly)
// ─────────────────────────────────────────────────────────
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
// ISL Assistant accent — Apple system purple
const _purple    = Color(0xFFAF52DE);
const _purple_D  = Color(0xFFBF5AF2);

const _lBg       = Color(0xFFF2F2F7);
const _lSurface  = Color(0xFFFFFFFF);
const _lSep      = Color(0xFFC6C6C8);
const _lLabel    = Color(0xFF000000);
const _lLabel2   = Color(0x993C3C43);
const _lLabel3   = Color(0x4D3C3C43);
const _lFill     = Color(0x1F787880);

const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dSep      = Color(0xFF38383A);
const _dLabel    = Color(0xFFFFFFFF);
const _dLabel2   = Color(0x99EBEBF5);
const _dLabel3   = Color(0x4DEBEBF5);
const _dFill     = Color(0x3A787880);

TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

// ══════════════════════════════════════════════════════════
//  HOME SCREEN
// ══════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const HomeScreen({super.key, required this.toggleTheme, required this.setLocale});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;
  int _tab = 0;
  late AnimationController _tabCtrl;
  late Animation<double>   _tabFade;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _tabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
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
    return w < 700 ? _buildMobile(context, isDark) : _buildWeb(context, isDark, w);
  }

  // ════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l  = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;
    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: Stack(children: [
        Positioned.fill(child: _AmbientBackground(isDark: isDark)),
        SafeArea(
          bottom: false,
          child: FadeTransition(opacity: _tabFade, child: _mobileBody(ctx, l, isDark)),
        ),
      ]),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: SOSFloatingButton(
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        ),
      ),
      bottomNavigationBar: _AppleTabBar(
        isDark: isDark,
        tab: _tab,
        onTap: _switchTab,
        l: l,
        setLocale: widget.setLocale,
        toggleTheme: widget.toggleTheme,
      ),
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
            accentLight: _blue, accentDark: _blue_D,
            launchLabel: l.t('get_started'),
            onLaunch: () => _push(ctx, TranslateScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.crop_free_rounded,    l.t('home_terminal_b1_title'), l.t('home_terminal_b1_desc')),
              (Icons.lock_rounded,         l.t('home_terminal_b2_title'), l.t('home_terminal_b2_desc')),
              (Icons.translate_rounded,    l.t('home_terminal_b3_title'), l.t('home_terminal_b3_desc')),
              (Icons.receipt_long_rounded, l.t('home_terminal_b4_title'), l.t('home_terminal_b4_desc')),
            ]);
      case 2:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.back_hand_rounded,
            title: l.t('nav_signs'),
            subtitle: l.t('home_signs_sub'),
            accentLight: _teal, accentDark: _teal_D,
            launchLabel: l.t('home_browse_signs'),
            onLaunch: () => _push(ctx, SignsPage(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.grid_view_rounded,     l.t('home_signs_b1_title'), l.t('home_signs_b1_desc')),
              (Icons.flip_to_front_rounded, l.t('home_signs_b2_title'), l.t('home_signs_b2_desc')),
              (Icons.search_rounded,        l.t('home_signs_b3_title'), l.t('home_signs_b3_desc')),
              (Icons.sort_rounded,          l.t('home_signs_b4_title'), l.t('home_signs_b4_desc')),
            ]);
      case 3:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.compare_arrows_rounded,
            title: l.t('nav_bridge'),
            subtitle: l.t('home_bridge_sub'),
            accentLight: _green, accentDark: _green_D,
            launchLabel: l.t('home_open_bridge'),
            onLaunch: () => _push(ctx, TwoWayScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.sign_language_rounded,       l.t('home_bridge_b1_title'), l.t('home_bridge_b1_desc')),
              (Icons.keyboard_alt_rounded,        l.t('home_bridge_b2_title'), l.t('home_bridge_b2_desc')),
              (Icons.chat_bubble_outline_rounded, l.t('home_bridge_b3_title'), l.t('home_bridge_b3_desc')),
              (Icons.flash_on_rounded,            l.t('home_bridge_b4_title'), l.t('home_bridge_b4_desc')),
            ]);

      // ── NEW: Tab 4 — ISL Assistant ──────────────────────────
      case 4:
        return _FeatureDetail(
            isDark: isDark, l: l,
            icon: Icons.sign_language_rounded,
            title: 'ISL Assistant',
            subtitle: 'Multilingual AI powered by Gemini — voice input & output in Hindi, Marathi, Tamil, English and more',
            accentLight: _purple, accentDark: _purple_D,
            launchLabel: 'Open ISL Assistant',
            onLaunch: () => _push(ctx, ISLAssistantScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
            bullets: [
              (Icons.auto_awesome_rounded,   'Gemini 2.0 Flash',   'State-of-the-art AI with deep ISL knowledge'),
              (Icons.mic_rounded,            'Voice input',        'Speak in Hindi, Marathi, Tamil or English'),
              (Icons.record_voice_over_rounded, 'Voice output',    'Responses read aloud in your language'),
              (Icons.front_hand_rounded,     'Step-by-step signs', 'Guides you through every ISL handshape & movement'),
            ]);

      default:
        return const SizedBox.shrink();
    }
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 280)));

  // ════════════════════════════════════════════
  //  WEB / TABLET
  // ════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad      = isDesktop ? 96.0 : 52.0;
    final l         = AppLocalizations.of(ctx);

    return Scaffold(
      backgroundColor: isDark ? _dBg : _lBg,
      body: Stack(children: [
        Positioned.fill(child: _AmbientBackground(isDark: isDark)),
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              GlobalNavbar(toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale, activeRoute: 'home'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(children: [
                  SizedBox(height: isDesktop ? 80 : 56),

                  // Hero
                  FadeTransition(opacity: _fade,
                      child: SlideTransition(position: _slide,
                          child: _WebHero(isDesktop: isDesktop, isDark: isDark, l: l,
                              pulse: _pulse,
                              onCTA: () => _push(ctx, TranslateScreen(
                                  toggleTheme: widget.toggleTheme, setLocale: widget.setLocale))))),

                  SizedBox(height: isDesktop ? 96 : 72),
                  _WebDivider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),

                  // Stats
                  _WebStats(isDesktop: isDesktop, isDark: isDark, l: l),

                  SizedBox(height: isDesktop ? 80 : 60),
                  _WebDivider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 60),

                  // ── NEW: ISL Assistant Banner ──────────────────
                  _WebAssistantBanner(
                    isDesktop: isDesktop, isDark: isDark,
                    onTap: () => _push(ctx, ISLAssistantScreen(
                        toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)),
                  ),

                  SizedBox(height: isDesktop ? 80 : 60),
                  _WebDivider(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : 64),

                  // Objectives
                  _WebSectionHeader(
                      label: l.t('obj_heading').toUpperCase(),
                      title: l.t('obj_heading'),
                      sub: l.t('obj_sub'),
                      isDark: isDark),
                  SizedBox(height: isDesktop ? 52 : 40),
                  _WebObjectivesGrid(isDesktop: isDesktop, isDark: isDark, l: l,
                      toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),

                  SizedBox(height: isDesktop ? 96 : 72),

                  // Vision
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
//  AMBIENT BACKGROUND
// ══════════════════════════════════════════════════════════
class _AmbientBackground extends StatelessWidget {
  final bool isDark;
  const _AmbientBackground({required this.isDark});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotGridPainter(isDark: isDark));
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.035) : Colors.black.withOpacity(0.030);
    const step = 28.0;
    for (double x = step; x < size.width;  x += step)
    for (double y = step; y < size.height; y += step)
      canvas.drawCircle(Offset(x, y), 0.8, p);
  }
  @override
  bool shouldRepaint(_DotGridPainter o) => o.isDark != isDark;
}

// ══════════════════════════════════════════════════════════
//  APPLE TAB BAR — 5 tabs (index 4 = ISL Assistant, purple)
// ══════════════════════════════════════════════════════════
class _AppleTabBar extends StatelessWidget {
  final bool isDark;
  final int  tab;
  final ValueChanged<int> onTap;
  final AppLocalizations l;
  final Function(Locale) setLocale;
  final VoidCallback toggleTheme;
  const _AppleTabBar({required this.isDark, required this.tab,
    required this.onTap, required this.l,
    required this.setLocale, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final accent = isDark ? _blue_D : _blue;
    // Tab 4 uses purple to visually distinguish the AI assistant
    final items = [
      (Icons.house_rounded,          Icons.house_outlined,          l.t('nav_home'),     accent),
      (Icons.translate_rounded,      Icons.translate_outlined,      l.t('nav_terminal'), accent),
      (Icons.back_hand_rounded,      Icons.back_hand_outlined,      l.t('nav_signs'),    accent),
      (Icons.compare_arrows_rounded, Icons.compare_arrows_outlined, l.t('nav_bridge'),   accent),
      (Icons.sign_language_rounded,  Icons.sign_language_outlined,  'Assistant',         isDark ? _purple_D : _purple),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
              color: isDark ? _dSurface.withOpacity(0.80) : _lSurface.withOpacity(0.88),
              border: Border(top: BorderSide(
                  color: isDark ? _dSep : _lSep.withOpacity(0.50), width: 0.5))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 49,
              child: Row(children: [
                ...items.asMap().entries.map((e) {
                  final i      = e.key;
                  final item   = e.value;
                  final active = tab == i;
                  final color  = active ? item.$4 : (isDark ? _dLabel2 : _lLabel2);
                  return Expanded(child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(active ? item.$1 : item.$2,
                              key: ValueKey(active), size: 24, color: color)),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                              fontFamily: 'Google Sans', fontSize: 10,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: color, letterSpacing: -0.1),
                          child: Text(item.$3, overflow: TextOverflow.ellipsis)),
                    ]),
                  ));
                }),
                _ThreeDotMenu(
                  isDark: isDark,
                  locale: locale,
                  setLocale: setLocale,
                  toggleTheme: toggleTheme,
                ),
              ]),
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

        _MobileNavBar(isDark: isDark, l: l, pulse: pulse,
            toggleTheme: toggleTheme, setLocale: setLocale),

        FadeTransition(opacity: fade,
            child: SlideTransition(position: slide,
                child: _MobileHeroCard(isDark: isDark, l: l,
                    toggleTheme: toggleTheme, setLocale: setLocale))),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MobileStatsStrip(isDark: isDark, l: l),
        ),

        const SizedBox(height: 28),

        _SectionTitle(text: l.t('home_quick_access'), isDark: isDark,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12)),
        _QuickAccessRow(isDark: isDark, l: l,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        // ── NEW: ISL Assistant card in home feed ──────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MobileAssistantCard(
              isDark: isDark, toggleTheme: toggleTheme, setLocale: setLocale),
        ),

        const SizedBox(height: 28),

        _SectionTitle(text: l.t('obj_heading'), isDark: isDark,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14)),
        _MobileObjectivesScroll(isDark: isDark, l: l,
            toggleTheme: toggleTheme, setLocale: setLocale),

        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MobileMissionCard(isDark: isDark, l: l),
        ),

        const SizedBox(height: 12),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MOBILE ASSISTANT CARD  ← NEW
// ══════════════════════════════════════════════════════════
class _MobileAssistantCard extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileAssistantCard({required this.isDark,
    required this.toggleTheme, required this.setLocale});
  @override State<_MobileAssistantCard> createState() => _MobileAssistantCardState();
}

class _MobileAssistantCardState extends State<_MobileAssistantCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? _dSurface : _lSurface;
    final label  = widget.isDark ? _dLabel   : _lLabel;
    final label2 = widget.isDark ? _dLabel2  : _lLabel2;
    final accent = widget.isDark ? _purple_D : _purple;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => ISLAssistantScreen(
                toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 280)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.20), width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.28 : 0.07),
                  blurRadius: 14, offset: const Offset(0, 4))]),
          child: Column(children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [accent, _blue],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('ISL Assistant', style: _t(16, FontWeight.w700, label, ls: -0.2)),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(width: 6, height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: accent,
                              boxShadow: [BoxShadow(
                                  color: accent.withOpacity(_pulseAnim.value * 0.6),
                                  blurRadius: 5, spreadRadius: 1)]))),
                  ]),
                  const SizedBox(height: 3),
                  Text('Multilingual AI · Voice · Sign Guides',
                      style: _t(12, FontWeight.w400, label2, ls: -0.1)),
                ])),
                Icon(Icons.chevron_right_rounded,
                    color: widget.isDark ? _dLabel3 : _lLabel3, size: 20),
              ]),
            ),
            // Divider
            Container(height: 0.5,
                color: widget.isDark ? _dSep : _lSep.withOpacity(0.4)),
            // Chips row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(children: [
                _AssistantChip('Voice I/O',    Icons.mic_rounded,          accent,    widget.isDark),
                const SizedBox(width: 8),
                _AssistantChip('Sign Guides',  Icons.front_hand_rounded,   _teal,     widget.isDark),
                const SizedBox(width: 8),
                _AssistantChip('3 Languages',  Icons.language_rounded,     _green,    widget.isDark),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AssistantChip extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final bool isDark;
  const _AssistantChip(this.label, this.icon, this.color, this.isDark);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18), width: 0.5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color), const SizedBox(width: 5),
      Text(label, style: _t(10.5, FontWeight.w600, color)),
    ]));
}

class _ThreeDotMenu extends StatelessWidget {
  final bool isDark; final Locale locale;
  final Function(Locale) setLocale; final VoidCallback toggleTheme;
  const _ThreeDotMenu({required this.isDark, required this.locale,
    required this.setLocale, required this.toggleTheme});

  Future<void> _logout(BuildContext context) async {
    try {
      final box = Hive.box<EmergencyContact>('emergency_contacts');
      await box.clear();
    } catch (_) {
      // Continue logout even if local cache cleanup fails.
    }

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Signed out.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final accent = isDark ? _blue_D  : _blue;
    final red    = isDark ? _red_D   : _red;
    final bg     = isDark ? _dSurface2 : _lSurface;
    final langs  = [
      {'code':'en','flag':'🇬🇧','name':'English'},
      {'code':'hi','flag':'🇮🇳','name':'हिन्दी'},
      {'code':'mr','flag':'🇮🇳','name':'मराठी'},
    ];
    return PopupMenuButton<String>(
      offset: const Offset(0, -190),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bg, elevation: 16,
      icon: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.more_horiz_rounded, color: label2, size: 20)),
      itemBuilder: (_) => [
        PopupMenuItem<String>(enabled: false, height: 28,
            child: Text('LANGUAGE', style: _t(9.5, FontWeight.w600, label2, ls: 0.8))),
        ...langs.map((lang) => PopupMenuItem<String>(
            value: 'lang_${lang['code']}', height: 42,
            child: Row(children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text(lang['name']!, style: _t(13.5, FontWeight.w500,
                  lang['code'] == locale.languageCode ? accent
                      : (isDark ? _dLabel : _lLabel))),
              if (lang['code'] == locale.languageCode) ...[
                const Spacer(), Icon(Icons.check_rounded, color: accent, size: 14)],
            ]))),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'theme', height: 42,
            child: Row(children: [
              Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: label2, size: 17),
              const SizedBox(width: 10),
              Text(isDark ? 'Light Mode' : 'Dark Mode',
                  style: _t(13.5, FontWeight.w500, isDark ? _dLabel : _lLabel)),
            ])),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'logout', height: 42,
            child: Row(children: [
              Icon(Icons.logout_rounded, color: red, size: 17),
              const SizedBox(width: 10),
              Text('Sign Out', style: _t(13.5, FontWeight.w500, red)),
            ])),
      ],
      onSelected: (value) {
        if (value.startsWith('lang_')) {
          setLocale(Locale(value.replaceFirst('lang_', '')));
        } else if (value == 'theme') {
          toggleTheme();
        } else if (value == 'logout') {
          showDialog(context: context, builder: (_) => AlertDialog(
            backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Sign Out', style: _t(17, FontWeight.w600, isDark ? _dLabel : _lLabel)),
            content: Text('Are you sure?', style: _t(14, FontWeight.w400, label2)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: _t(15, FontWeight.w500, accent))),
              TextButton(onPressed: () async {
                    Navigator.pop(context);
                    await _logout(context);
                  },
                  child: Text('Sign Out', style: _t(15, FontWeight.w600, red))),
            ]));
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE NAV BAR
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.t('app_title_short'),
                style: _t(26, FontWeight.w700, isDark ? _dLabel : _lLabel, ls: 4.0)),
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
        _LangButton(locale: locale, setLocale: setLocale, isDark: isDark, accent: accent, l: l),
        const SizedBox(width: 8),
        _IconPill(
            icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            isDark: isDark, onTap: toggleTheme),
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
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: isDark ? _dFill : _lFill,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: isDark ? _dLabel2 : _lLabel2)));
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
            (x) => x['code'] == locale.languageCode, orElse: () => langs[0]);
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
  late Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _aCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
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
                BoxShadow(color: Colors.black.withOpacity(widget.isDark ? 0.45 : 0.10),
                    blurRadius: 32, offset: const Offset(0, 12)),
                if (!widget.isDark)
                  BoxShadow(color: accent.withOpacity(0.06), blurRadius: 48, offset: const Offset(0, 16)),
              ],
              border: Border.all(
                  color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  width: 0.5)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(children: [
              Positioned(top: -40 + _anim.value * 8, right: -40,
                  child: Container(width: 200, height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            accent.withOpacity(widget.isDark ? 0.12 : 0.08), Colors.transparent])))),
              Positioned(bottom: -30 - _anim.value * 6, left: -20,
                  child: Container(width: 140, height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _indigo.withOpacity(widget.isDark ? 0.08 : 0.05), Colors.transparent])))),
              Padding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 22), child: child!),
            ]),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _AppleBadge(label: widget.l.t('home_mobile_badge'),
              accent: widget.isDark ? _blue_D : _blue, isDark: widget.isDark),
          const SizedBox(height: 16),
          Text(widget.l.t('hero_title_line1'),
              style: _t(34, FontWeight.w700, label, ls: -0.5, h: 1.08)),
          Text(widget.l.t('hero_title_line2'),
              style: _t(34, FontWeight.w700, accent, ls: -0.5, h: 1.08)),
          const SizedBox(height: 12),
          Text(widget.l.t('hero_sub'),
              style: _t(14, FontWeight.w400, label2, ls: -0.2, h: 1.55)),
          const SizedBox(height: 22),
          _AppleFilledButton(
              label: widget.l.t('get_started'),
              icon: Icons.arrow_forward_rounded,
              accent: widget.isDark ? _blue_D : _blue,
              onTap: () => Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => TranslateScreen(
                      toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
                  transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 280)))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE STATS STRIP
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(0)}M'
      : n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? _dSurface : _lSurface;
    final sep    = widget.isDark ? _dSep : _lSep.withOpacity(0.4);
    final label2 = widget.isDark ? _dLabel2  : _lLabel2;
    final stats  = [
      (63000000, '+', widget.l.t('stat_mute_label'),        widget.isDark ? _blue_D : _blue),
      (8435000,  '+', widget.l.t('stat_isl_label'),         widget.isDark ? _indigo_D : _indigo),
      (250,      '',  widget.l.t('stat_translators_label'), _red),
    ];

    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.06),
                  blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: stats.asMap().entries.map((e) {
            final i = e.key; final s = e.value;
            return Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(border: i < stats.length - 1
                  ? Border(right: BorderSide(color: sep, width: 0.5)) : null),
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
//  QUICK ACCESS ROW
// ─────────────────────────────────────────────
class _QuickAccessRow extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _QuickAccessRow({required this.isDark, required this.l,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext ctx) {
    final cards = [
      (_teal,  _teal_D,  Icons.compare_arrows_rounded,  l.t('nav_bridge'),     l.t('home_open_bridge')),
      (_red,   _red_D,   Icons.emergency_share_rounded,  l.t('nav_emergency'),  l.t('sos_screen_title')),
      (_green, _green_D, Icons.back_hand_rounded,         l.t('nav_signs'),      l.t('home_browse_signs')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: cards.asMap().entries.map((e) {
        final i = e.key; final c = e.value;
        final accent = isDark ? c.$2 : c.$1;
        Widget dest() {
          switch (i) {
            case 0:  return TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale);
            case 1:  return EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale);
            default: return SignsPage(toggleTheme: toggleTheme, setLocale: setLocale);
          }
        }
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
          child: _QuickTile(accent: accent, icon: c.$3, label: c.$4, sub: c.$5,
              isDark: isDark,
              onTap: () => Navigator.push(ctx, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => dest(),
                  transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ch),
                  transitionDuration: const Duration(milliseconds: 260)))),
        ));
      }).toList()),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String label, sub;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickTile({required this.accent, required this.icon,
    required this.label, required this.sub, required this.isDark, required this.onTap});
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
        child: AspectRatio(
          aspectRatio: 0.95,
          child: Container(
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.accent.withOpacity(0.18), width: 0.5),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.28 : 0.07),
                    blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(widget.icon, color: widget.accent, size: 20)),
              const SizedBox(height: 8),
              Text(widget.label, style: _t(11.5, FontWeight.w700, label),
                  textAlign: TextAlign.center),
              Text(widget.sub, style: _t(9.5, FontWeight.w400, sub),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}

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
      (_blue,   Icons.accessibility_new_rounded,   l.t('obj_accessibility'), l.t('obj_accessibility_desc'),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_teal,   Icons.connecting_airports_rounded, l.t('obj_bridging'),      l.t('obj_bridging_desc'),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_green,  Icons.people_outline_rounded,      l.t('obj_inclusivity'),   l.t('obj_inclusivity_desc'),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_orange, Icons.shield_outlined,             l.t('obj_privacy'),       l.t('obj_privacy_desc'),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_indigo, Icons.wifi_off_rounded,            l.t('obj_offline'),       l.t('obj_offline_desc'),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_red,    Icons.school_rounded,              l.t('obj_education'),     l.t('obj_education_desc'),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    Color dv(Color c) {
      if (c == _blue)   return _blue_D;
      if (c == _teal)   return _teal_D;
      if (c == _green)  return _green_D;
      if (c == _orange) return _orange_D;
      if (c == _indigo) return _indigo_D;
      if (c == _red)    return _red_D;
      return c;
    }

    return SizedBox(
      height: 162,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final c = cards[i];
            return Padding(
                padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
                child: _ObjCard(
                    icon: c.$2, title: c.$3, desc: c.$4,
                    accent: isDark ? dv(c.$1) : c.$1, page: c.$5, isDark: isDark));
          }),
    );
  }
}

class _ObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _ObjCard({required this.icon, required this.title, required this.desc,
    required this.accent, required this.page, required this.isDark});
  @override
  State<_ObjCard> createState() => _ObjCardState();
}

class _ObjCardState extends State<_ObjCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final bg    = widget.isDark ? _dSurface : _lSurface;
    final label = widget.isDark ? _dLabel   : _lLabel;
    final sub   = widget.isDark ? _dLabel2  : _lLabel2;
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
          width: 148, padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.accent.withOpacity(0.16), width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.06),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 36,
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
//  MOBILE MISSION CARD
// ─────────────────────────────────────────────
class _MobileMissionCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobileMissionCard({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface : _lSurface;
    final label  = isDark ? _dLabel   : _lLabel;
    final sub    = isDark ? _dLabel2  : _lLabel2;
    final accent = isDark ? _blue_D   : _blue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
              blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.volunteer_activism_rounded, color: accent, size: 15)),
          const SizedBox(width: 10),
          Text(l.t('home_our_mission'), style: _t(11, FontWeight.w600, accent, ls: 0.4)),
        ]),
        const SizedBox(height: 12),
        Text(l.t('vision_title'), style: _t(17, FontWeight.w700, label, ls: -0.3, h: 1.2)),
        const SizedBox(height: 8),
        Text(l.t('home_mission_body'), style: _t(13, FontWeight.w400, sub, ls: -0.1, h: 1.6)),
        const SizedBox(height: 14),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.20), width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5,
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(l.t('obj_crisis_stat'), style: _t(11.5, FontWeight.w600, _red)),
            ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MOBILE FEATURE DETAIL PAGE  (tabs 1–4)
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 22),
                child: Text(title, style: _t(28, FontWeight.w700, label, ls: -0.5)),
              ),
              // Hero summary card
              Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent.withOpacity(0.16), width: 0.5),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
                          blurRadius: 14, offset: const Offset(0, 4))]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(icon, color: _accent, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: _t(17, FontWeight.w700, label, ls: -0.3)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: _t(13, FontWeight.w400, label2, ls: -0.1, h: 1.5)),
                    ])),
                  ])),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(l.t('page_section_header'),
                    style: _t(11, FontWeight.w600, isDark ? _dLabel3 : _lLabel3, ls: 0.6)),
              ),
              Container(
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        blurRadius: 10, offset: const Offset(0, 3))]),
                child: Column(children: bullets.asMap().entries.map((e) {
                  final i = e.key; final f = e.value;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(children: [
                        Container(width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: _accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(f.$1, color: _accent, size: 16)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.$2, style: _t(14, FontWeight.w600, label, ls: -0.2)),
                          const SizedBox(height: 2),
                          Text(f.$3, style: _t(12, FontWeight.w400, label2, ls: -0.1, h: 1.4)),
                        ])),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: isDark ? _dLabel3 : _lLabel3),
                      ]),
                    ),
                    if (i < bullets.length - 1)
                      Divider(indent: 66, height: 0,
                          color: isDark ? _dSep : _lSep.withOpacity(0.5), thickness: 0.5),
                  ]);
                }).toList()),
              ),
              const SizedBox(height: 28),
              _AppleFilledButton(
                  label: launchLabel, icon: Icons.arrow_forward_rounded,
                  accent: _accent, onTap: onLaunch),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  WEB ASSISTANT BANNER  ← NEW
// ══════════════════════════════════════════════════════════
class _WebAssistantBanner extends StatefulWidget {
  final bool isDesktop, isDark;
  final VoidCallback onTap;
  const _WebAssistantBanner(
      {required this.isDesktop, required this.isDark, required this.onTap});
  @override
  State<_WebAssistantBanner> createState() => _WebAssistantBannerState();
}

class _WebAssistantBannerState extends State<_WebAssistantBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double>   _anim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ac   = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? _purple_D : _purple;
    final bg     = widget.isDark ? _dSurface  : _lSurface;
    final label  = widget.isDark ? _dLabel    : _lLabel;
    final label2 = widget.isDark ? _dLabel2   : _lLabel2;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: _hovered ? accent.withOpacity(0.45) : accent.withOpacity(0.18),
                    width: _hovered ? 1.0 : 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(widget.isDark ? 0.40 : 0.08),
                      blurRadius: _hovered ? 40 : 24, offset: const Offset(0, 8)),
                  BoxShadow(color: accent.withOpacity(_hovered ? 0.14 : 0.06),
                      blurRadius: 48, offset: const Offset(0, 12)),
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(children: [
                Positioned(top: -60 + _anim.value * 20, right: -60,
                    child: Container(width: 300, height: 300,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              accent.withOpacity(widget.isDark ? 0.14 : 0.09),
                              Colors.transparent])))),
                Positioned(bottom: -40 - _anim.value * 10, left: 80,
                    child: Container(width: 200, height: 200,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _blue.withOpacity(widget.isDark ? 0.10 : 0.06),
                              Colors.transparent])))),
                Padding(
                  padding: EdgeInsets.all(widget.isDesktop ? 44 : 32),
                  child: child!,
                ),
              ]),
            ),
          ),
          child: widget.isDesktop
              ? _bannerDesktop(accent, label, label2)
              : _bannerTablet(accent, label, label2),
        ),
      ),
    );
  }

  Widget _bannerDesktop(Color accent, Color label, Color label2) =>
      Row(children: [
        // Icon
        Container(width: 80, height: 80,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, _blue],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 38)),
        const SizedBox(width: 32),
        // Text
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.22), width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
                const SizedBox(width: 6),
                Text('NEW · Gemini 2.0 Flash · Voice I/O · Multilingual',
                    style: _t(10.5, FontWeight.w600, accent, ls: 0.1)),
              ])),
          const SizedBox(height: 14),
          Text('ISL Assistant — Vani', style: _t(28, FontWeight.w700, label, ls: -0.5)),
          const SizedBox(height: 8),
          Text('Ask anything about Indian Sign Language — voice input and output '
              'in Hindi, Marathi, Tamil, English and more. Step-by-step sign guides, '
              'emergency phrases, and learning support powered by Gemini 2.0 Flash.',
              style: _t(14.5, FontWeight.w400, label2, ls: -0.1, h: 1.6)),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _WebChip('🎙 Voice Input',   accent),
            _WebChip('🔊 Voice Output',  accent),
            _WebChip('🌐 8 Languages',   accent),
            _WebChip('🤟 Sign Guides',   accent),
            _WebChip('🚨 Emergency',     accent),
          ]),
        ])),
        const SizedBox(width: 32),
        // CTA
        _WebBannerCTA(accent: accent, hovered: _hovered),
      ]);

  Widget _bannerTablet(Color accent, Color label, Color label2) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, _blue],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ISL Assistant', style: _t(22, FontWeight.w700, label, ls: -0.4)),
            Text('Vani · Gemini 2.0 Flash', style: _t(13, FontWeight.w400, label2)),
          ])),
        ]),
        const SizedBox(height: 14),
        Text('Ask anything in ISL — voice in & out, sign guides, emergency phrases, '
            'and 8 Indian languages.',
            style: _t(14, FontWeight.w400, label2, ls: -0.1, h: 1.6)),
        const SizedBox(height: 16),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _WebChip('🎙 Voice I/O',   accent),
          _WebChip('🌐 8 Langs',    accent),
          _WebChip('🤟 Sign Guides', accent),
          _WebChip('🚨 Emergency',   accent),
        ]),
        const SizedBox(height: 20),
        _WebBannerCTA(accent: accent, hovered: _hovered),
      ]);
}

class _WebBannerCTA extends StatelessWidget {
  final Color accent;
  final bool hovered;
  const _WebBannerCTA({required this.accent, required this.hovered});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, _blue],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: accent.withOpacity(hovered ? 0.40 : 0.22),
              blurRadius: hovered ? 28 : 14, offset: const Offset(0, 6))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Open ISL Assistant', style: _t(14, FontWeight.w600, Colors.white, ls: -0.2)),
        const SizedBox(width: 10),
        AnimatedSlide(
            offset: Offset(hovered ? 0.3 : 0, 0),
            duration: const Duration(milliseconds: 150),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15)),
      ]));
}

class _WebChip extends StatelessWidget {
  final String label;
  final Color accent;
  const _WebChip(this.label, this.accent);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
      child: Text(label, style: _t(12, FontWeight.w500, accent)));
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
          color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
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
  const _AppleFilledButton(
      {required this.label, required this.icon, required this.accent, required this.onTap});
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
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                  color: widget.accent, borderRadius: BorderRadius.circular(14)),
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
  const _SectionTitle({required this.text, required this.isDark, required this.padding});
  @override
  Widget build(BuildContext context) => Padding(
      padding: padding,
      child: Text(text, style: _t(20, FontWeight.w700, isDark ? _dLabel : _lLabel, ls: -0.3)));
}

// ══════════════════════════════════════════════════════════
//  WEB COMPONENTS
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
      AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: isDark ? _dSurface : _lSurface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: accent.withOpacity(0.22), width: 0.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
                        blurRadius: 12, offset: const Offset(0, 3)),
                    BoxShadow(color: accent.withOpacity(pulse.value * 0.12), blurRadius: 20),
                  ]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent,
                        boxShadow: [BoxShadow(
                            color: accent.withOpacity(pulse.value * 0.7),
                            blurRadius: 6, spreadRadius: 1)])),
                const SizedBox(width: 10),
                Text(l.t('badge'), style: _t(11.5, FontWeight.w500, label2, ls: 0.2)),
              ]))),
      SizedBox(height: isDesktop ? 24 : 18),
      ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 760),
          child: LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final gradient = LinearGradient(
                colors: isDark ? [_blue_D, _indigo_D] : [_blue, _indigo]);
            double size = fs;
            TextSpan spanFor(double fontSize) {
              final base = _t(fontSize, FontWeight.w700, label, ls: -1.6, h: 1.02);
              final hl = base.copyWith(color: null,
                  foreground: Paint()..shader = gradient.createShader(
                      Rect.fromLTWH(0, 0, maxWidth, fontSize * 1.8)));
              return TextSpan(children: [
                if (title1.isNotEmpty) TextSpan(text: '$title1 ', style: base),
                TextSpan(text: titleH, style: hl),
                if (title2.isNotEmpty) TextSpan(text: ' $title2', style: base),
              ]);
            }
            for (int i = 0; i < 28; i++) {
              final tp = TextPainter(text: spanFor(size),
                  textDirection: TextDirection.ltr, maxLines: 2)..layout(maxWidth: maxWidth);
              if (!tp.didExceedMaxLines) break;
              size -= 1;
              if (size <= (isDesktop ? 40 : 30)) break;
            }
            return RichText(textAlign: TextAlign.center, maxLines: 2,
                overflow: TextOverflow.ellipsis, text: spanFor(size));
          })),
      SizedBox(height: isDesktop ? 14 : 10),
      ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 560 : 460),
          child: Text(l.t('hero_sub'), textAlign: TextAlign.center,
              style: _t(isDesktop ? 17 : 15.5, FontWeight.w400, label2, ls: -0.2, h: 1.75))),
      SizedBox(height: isDesktop ? 28 : 22),
      _WebCTAButton(label: l.t('get_started'), onTap: onCTA, isDark: isDark),
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
                        blurRadius: _hovered ? 28 : 14, offset: const Offset(0, 6))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.label, style: _t(15, FontWeight.w600, Colors.white, ls: -0.2)),
                  const SizedBox(width: 10),
                  AnimatedSlide(
                      offset: Offset(_hovered ? 0.3 : 0, 0),
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16)),
                ]))));
  }
}

class _WebDivider extends StatelessWidget {
  final bool isDark;
  const _WebDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 0.5, color: isDark ? _dSep : _lSep.withOpacity(0.5));
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
          color: bg, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
              blurRadius: 20, offset: const Offset(0, 6))]),
      child: IntrinsicHeight(child: Row(children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: _WebStatCell(value: stats[i].$1, suffix: stats[i].$2,
              label: stats[i].$3, color: stats[i].$4,
              isDark: isDark, isDesktop: isDesktop)),
          if (i < stats.length - 1) Container(width: 0.5, color: sep),
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
    required this.label, required this.color, required this.isDark, required this.isDesktop});
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
    _ctrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _anim   = Tween<double>(begin: 0, end: _target.toDouble())
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

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
                style: _t(13, FontWeight.w400, widget.isDark ? _dLabel2 : _lLabel2, ls: 0.1)),
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
              color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(6),
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
      (_blue,   Icons.accessibility_new_rounded,   l.t('obj_accessibility'), l.t('obj_accessibility_desc'),
      AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_teal,   Icons.connecting_airports_rounded, l.t('obj_bridging'),      l.t('obj_bridging_desc'),
      BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_green,  Icons.people_outline_rounded,      l.t('obj_inclusivity'),   l.t('obj_inclusivity_desc'),
      InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_orange, Icons.shield_outlined,             l.t('obj_privacy'),       l.t('obj_privacy_desc'),
      PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_indigo, Icons.wifi_off_rounded,            l.t('obj_offline'),       l.t('obj_offline_desc'),
      OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (_red,    Icons.school_rounded,              l.t('obj_education'),     l.t('obj_education_desc'),
      EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    Color dOf(Color c) {
      if (c == _blue)   return _blue_D;
      if (c == _teal)   return _teal_D;
      if (c == _green)  return _green_D;
      if (c == _orange) return _orange_D;
      if (c == _indigo) return _indigo_D;
      if (c == _red)    return _red_D;
      return c;
    }

    return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isDesktop ? 3 : 2,
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.7 : 1.45,
        children: cards.map((c) => _WebObjCard(
            icon: c.$2, title: c.$3, desc: c.$4,
            accent: isDark ? dOf(c.$1) : c.$1, page: c.$5,
            isDark: isDark)).toList());
  }
}

class _WebObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _WebObjCard({required this.icon, required this.title, required this.desc,
    required this.accent, required this.page, required this.isDark});
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
                    color: bg, borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _hovered
                            ? widget.accent.withOpacity(0.35)
                            : Colors.black.withOpacity(widget.isDark ? 0.0 : 0.05),
                        width: _hovered ? 1.0 : 0.5),
                    boxShadow: _hovered
                        ? [BoxShadow(color: widget.accent.withOpacity(widget.isDark ? 0.14 : 0.08),
                        blurRadius: 24, offset: const Offset(0, 8))]
                        : [BoxShadow(color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.05),
                        blurRadius: 12, offset: const Offset(0, 3))]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(10),
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
                      Text(widget.title, style: _t(15, FontWeight.w600, label, ls: -0.2)),
                      const SizedBox(height: 4),
                      Text(widget.desc, style: _t(12.5, FontWeight.w400, sub, ls: -0.1, h: 1.5)),
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
            border: Border.all(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
                blurRadius: 24, offset: const Offset(0, 8))]),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.08), shape: BoxShape.circle,
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
                  color: _red.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withOpacity(0.18), width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(l.t('obj_crisis_stat'), style: _t(12.5, FontWeight.w600, _red)),
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
      Divider(height: 1, thickness: 0.5, color: isDark ? _dSep : _lSep.withOpacity(0.5)),
      const SizedBox(height: 24),
      Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16, runSpacing: 6,
          children: [
            Text(AppLocalizations.of(context).t('app_title_short'),
                style: _t(12, FontWeight.w700, isDark ? _blue_D : _blue, ls: 4.0)),
            Container(width: 1, height: 11, color: isDark ? _dSep : _lSep.withOpacity(0.5)),
            Text('© 2026 — ${AppLocalizations.of(context).t('home_footer')}',
                style: _t(11.5, FontWeight.w400, sub, ls: 0.1)),
          ]),
    ]);
  }
}