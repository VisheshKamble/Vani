// lib/screens/HomeScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — UX4G Redesign v2  · Premium Web + Refined Mobile          ║
// ║                                                                    ║
// ║  Web: Apple/Linear-level premium aesthetics                        ║
// ║  Mobile: Refined ISL Assistant card post quick-actions             ║
// ╚══════════════════════════════════════════════════════════════════════╝

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
import 'objectives/EducationPage.dart';

// ─────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _primary = Color(0xFF1A56DB);
const _primaryDark = Color(0xFF4A8EFF);
const _primarySurface = Color(0xFFE8F0FE);

const _secondary = Color(0xFF00796B);
const _secondaryDark = Color(0xFF26A69A);

const _success = Color(0xFF1B7340);
const _successDark = Color(0xFF27AE60);
const _warning = Color(0xFF7A4800);
const _warningDark = Color(0xFFFFB300);
const _danger = Color(0xFFB71C1C);
const _dangerLight = Color(0xFFFFEBEE);
const _dangerDark = Color(0xFFEF5350);
const _info = Color(0xFF0D47A1);

const _purple = Color(0xFF6200EA);
const _purpleDark = Color(0xFF9C6BFF);
const _purpleSurface = Color(0xFFF3E5F5);
const _purpleSurfD = Color(0xFF2A1047);
const _purpleDeep = Color(0xFF4C1D95);

const _lBg = Color(0xFFF8F9FC);
const _lSurface = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF0F4F8);
const _lSurface3 = Color(0xFFEAEEF4);
const _lBorder = Color(0xFFDDE3ED);
const _lBorderSub = Color(0xFFEDF0F5);
const _lText = Color(0xFF0D1117);
const _lTextSub = Color(0xFF374151);
const _lTextMuted = Color(0xFF6B7280);

const _dBg = Color(0xFF080C12);
const _dSurface = Color(0xFF0F1520);
const _dSurface2 = Color(0xFF161D2A);
const _dSurface3 = Color(0xFF1C2535);
const _dBorder = Color(0xFF252F40);
const _dBorderSub = Color(0xFF1C2535);
const _dText = Color(0xFFECF0F7);
const _dTextSub = Color(0xFFB0BEC5);
const _dTextMuted = Color(0xFF6B7A90);

const _fontFamily = 'Google Sans';

TextStyle _display(double size, Color c) => TextStyle(
  fontFamily: _fontFamily,
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: c,
  height: 1.2,
  letterSpacing: -0.5,
);

TextStyle _heading(double size, Color c, {FontWeight w = FontWeight.w600}) =>
    TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.3,
      letterSpacing: -0.2,
    );

TextStyle _body(double size, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.6,
    );

TextStyle _label(double size, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.4,
      letterSpacing: 0.1,
    );

const _sp4 = 4.0;
const _sp6 = 6.0;
const _sp8 = 8.0;
const _sp10 = 10.0;
const _sp12 = 12.0;
const _sp14 = 14.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;
const _sp48 = 48.0;

// ══════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ══════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  int _tab = 0;
  late AnimationController _tabCtrl;
  late Animation<double> _tabFade;

  final ScrollController _scrollCtrl = ScrollController();
  // For web hero subtle animation
  late AnimationController _floatCtrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
    _tabCtrl.forward();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    _tabCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _tab = i);
        _tabCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ══════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT — unchanged structure, refined ISL card
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;
    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _tabFade,
          child: _mobileBody(ctx, l, isDark),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: SOSFloatingButton(
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _UX4GTabBar(
        isDark: isDark,
        tab: _tab,
        onTap: _switchTab,
        l: l,
      ),
    );
  }

  Widget _mobileBody(BuildContext ctx, AppLocalizations l, bool isDark) {
    switch (_tab) {
      case 0:
        return _MobileHomeFeed(
          isDark: isDark,
          fade: _fade,
          slide: _slide,
          pulse: _pulse,
          l: l,
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        );
      case 1:
        return _FeatureDetail(
          isDark: isDark,
          l: l,
          icon: Icons.translate_rounded,
          title: l.t('nav_terminal'),
          subtitle: l.t('home_terminal_sub'),
          accentLight: _primary,
          accentDark: _primaryDark,
          launchLabel: l.t('get_started'),
          onLaunch: () => _push(
            ctx,
            TranslateScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: [
            (
              Icons.crop_free_rounded,
              l.t('home_terminal_b1_title'),
              l.t('home_terminal_b1_desc'),
            ),
            (
              Icons.lock_rounded,
              l.t('home_terminal_b2_title'),
              l.t('home_terminal_b2_desc'),
            ),
            (
              Icons.translate_rounded,
              l.t('home_terminal_b3_title'),
              l.t('home_terminal_b3_desc'),
            ),
            (
              Icons.receipt_long_rounded,
              l.t('home_terminal_b4_title'),
              l.t('home_terminal_b4_desc'),
            ),
          ],
        );
      case 2:
        return _FeatureDetail(
          isDark: isDark,
          l: l,
          icon: Icons.back_hand_rounded,
          title: l.t('nav_signs'),
          subtitle: l.t('home_signs_sub'),
          accentLight: _secondary,
          accentDark: _secondaryDark,
          launchLabel: l.t('home_browse_signs'),
          onLaunch: () => _push(
            ctx,
            SignsPage(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: [
            (
              Icons.grid_view_rounded,
              l.t('home_signs_b1_title'),
              l.t('home_signs_b1_desc'),
            ),
            (
              Icons.flip_to_front_rounded,
              l.t('home_signs_b2_title'),
              l.t('home_signs_b2_desc'),
            ),
            (
              Icons.search_rounded,
              l.t('home_signs_b3_title'),
              l.t('home_signs_b3_desc'),
            ),
            (
              Icons.sort_rounded,
              l.t('home_signs_b4_title'),
              l.t('home_signs_b4_desc'),
            ),
          ],
        );
      case 3:
        return _FeatureDetail(
          isDark: isDark,
          l: l,
          icon: Icons.compare_arrows_rounded,
          title: l.t('nav_bridge'),
          subtitle: l.t('home_bridge_sub'),
          accentLight: _success,
          accentDark: _successDark,
          launchLabel: l.t('home_open_bridge'),
          onLaunch: () => _push(
            ctx,
            TwoWayScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: [
            (
              Icons.sign_language_rounded,
              l.t('home_bridge_b1_title'),
              l.t('home_bridge_b1_desc'),
            ),
            (
              Icons.keyboard_alt_rounded,
              l.t('home_bridge_b2_title'),
              l.t('home_bridge_b2_desc'),
            ),
            (
              Icons.chat_bubble_outline_rounded,
              l.t('home_bridge_b3_title'),
              l.t('home_bridge_b3_desc'),
            ),
            (
              Icons.flash_on_rounded,
              l.t('home_bridge_b4_title'),
              l.t('home_bridge_b4_desc'),
            ),
          ],
        );
      case 4:
        return _FeatureDetail(
          isDark: isDark,
          l: l,
          icon: Icons.sign_language_rounded,
          title: l.t('assistant_title'),
          subtitle: l.t('assistant_feature_sub'),
          accentLight: _purple,
          accentDark: _purpleDark,
          launchLabel: l.t('assistant_open'),
          onLaunch: () => _push(
            ctx,
            ISLAssistantScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: [
            (
              Icons.auto_awesome_rounded,
              l.t('assistant_bullet_ai_title'),
              l.t('assistant_bullet_ai_desc'),
            ),
            (
              Icons.mic_rounded,
              l.t('assistant_bullet_voice_input_title'),
              l.t('assistant_bullet_voice_input_desc'),
            ),
            (
              Icons.record_voice_over_rounded,
              l.t('assistant_bullet_voice_output_title'),
              l.t('assistant_bullet_voice_output_desc'),
            ),
            (
              Icons.front_hand_rounded,
              l.t('assistant_bullet_sign_steps_title'),
              l.t('assistant_bullet_sign_steps_desc'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _push(BuildContext ctx, Widget page) => Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 260),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — Premium, Apple-inspired
  // ══════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 88.0 : 44.0;
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Navbar ────────────────────────────────────────────────
              GlobalNavbar(
                toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale,
                activeRoute: 'home',
              ),

              // ── Hero Section ──────────────────────────────────────────
              _WebHeroSection(
                isDesktop: isDesktop,
                isDark: isDark,
                l: l,
                fade: _fade,
                slide: _slide,
                pulse: _pulse,
                float: _float,
                hPad: hPad,
                onCTA: () => _push(
                  ctx,
                  TranslateScreen(
                    toggleTheme: widget.toggleTheme,
                    setLocale: widget.setLocale,
                  ),
                ),
              ),

              // ── Stats Row ─────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _WebStatsRow(isDesktop: isDesktop, isDark: isDark, l: l),
              ),
              SizedBox(height: isDesktop ? 80 : 60),

              // ── Features Section ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  children: [
                    _WebSectionLabel(
                      text: l.t('home_features_label'),
                      isDark: isDark,
                    ),
                    SizedBox(height: isDesktop ? 16 : 12),
                    _WebSectionTitle(
                      title: l.t('home_features_title'),
                      sub: l.t('home_features_sub'),
                      isDark: isDark,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 56 : 40),
                    _WebFeaturesGrid(
                      isDesktop: isDesktop,
                      isDark: isDark,
                      l: l,
                      toggleTheme: widget.toggleTheme,
                      setLocale: widget.setLocale,
                      push: (p) => _push(ctx, p),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 80 : 60),

              // ── ISL Assistant Banner ──────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _WebAssistantSection(
                  isDesktop: isDesktop,
                  isDark: isDark,
                  l: l,
                  float: _float,
                  onTap: () => _push(
                    ctx,
                    ISLAssistantScreen(
                      toggleTheme: widget.toggleTheme,
                      setLocale: widget.setLocale,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 80 : 60),

              // ── Objectives ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  children: [
                    _WebSectionLabel(
                      text: l.t('home_mission_label'),
                      isDark: isDark,
                    ),
                    SizedBox(height: isDesktop ? 16 : 12),
                    _WebSectionTitle(
                      title: l.t('obj_heading'),
                      sub: l.t('obj_sub'),
                      isDark: isDark,
                      isDesktop: isDesktop,
                    ),
                    SizedBox(height: isDesktop ? 48 : 36),
                    _WebObjectivesGrid(
                      isDesktop: isDesktop,
                      isDark: isDark,
                      l: l,
                      toggleTheme: widget.toggleTheme,
                      setLocale: widget.setLocale,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 80 : 60),

              // ── Vision ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _WebVisionSection(isDark: isDark, l: l),
              ),
              SizedBox(height: isDesktop ? 56 : 40),

              // ── Footer ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _WebFooter(isDark: isDark),
              ),
              const SizedBox(height: _sp48),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB HERO SECTION — Premium immersive design
// ══════════════════════════════════════════════════════════════════════
class _WebHeroSection extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final Animation<double> fade, pulse, float;
  final Animation<Offset> slide;
  final double hPad;
  final VoidCallback onCTA;

  const _WebHeroSection({
    required this.isDesktop,
    required this.isDark,
    required this.l,
    required this.fade,
    required this.slide,
    required this.pulse,
    required this.float,
    required this.hPad,
    required this.onCTA,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _primaryDark : _primary;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final bgGrad1 = isDark ? Color(0xFF080C12) : Color(0xFFF8F9FC);
    final bgGrad2 = isDark ? Color(0xFF0A1020) : Color(0xFFEDF2FF);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgGrad1, bgGrad2],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: hPad,
          right: hPad,
          top: isDesktop ? 80 : 56,
          bottom: isDesktop ? 80 : 56,
        ),
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Column(
              children: [
                // ── Status pill ─────────────────────────────────────────
                _StatusPill(isDark: isDark, accent: accent, pulse: pulse, l: l),
                SizedBox(height: isDesktop ? 28 : 20),

                // ── Hero headline ────────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 820 : 680),
                  child: _HeroHeadline(
                    isDesktop: isDesktop,
                    isDark: isDark,
                    l: l,
                    accent: accent,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 14),

                // ── Subtext ─────────────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 520 : 440),
                  child: Text(
                    l.t('hero_sub'),
                    textAlign: TextAlign.center,
                    style: _body(isDesktop ? 17 : 15, subClr),
                  ),
                ),
                SizedBox(height: isDesktop ? 36 : 28),

                // ── CTA row ─────────────────────────────────────────────
                Align(
                  alignment: Alignment.center,
                  child: _WebPrimaryBtn(
                    label: l.t('get_started'),
                    icon: Icons.arrow_forward_rounded,
                    bgColor: accent,
                    textColor: Colors.white,
                    onTap: onCTA,
                  ),
                ),
                SizedBox(height: isDesktop ? 56 : 40),

                // ── Trust indicators ─────────────────────────────────────
                _HeroTrustRow(isDark: isDark, l: l, isDesktop: isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Animation<double> pulse;
  final AppLocalizations l;
  const _StatusPill({
    required this.isDark,
    required this.accent,
    required this.pulse,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF22C55E),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF22C55E).withOpacity(pulse.value * 0.55),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _sp8),
            Text(l.t('badge'), style: _body(12.5, subClr)),
          ],
        ),
      ),
    );
  }
}

class _HeroHeadline extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final Color accent;
  const _HeroHeadline({
    required this.isDesktop,
    required this.isDark,
    required this.l,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textClr = isDark ? _dText : _lText;
    final fs = isDesktop ? 60.0 : 44.0;

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final title1 = l.t('hero_title_1').replaceAll('\n', ' ');
        final titleH = l.t('hero_title_highlight').replaceAll('\n', ' ');
        final title2 = l.t('hero_title_2').replaceAll('\n', ' ');

        TextSpan spanFor(double size) => TextSpan(
          children: [
            if (title1.isNotEmpty)
              TextSpan(text: '$title1 ', style: _display(size, textClr)),
            TextSpan(text: titleH, style: _display(size, accent)),
            if (title2.isNotEmpty)
              TextSpan(text: ' $title2', style: _display(size, textClr)),
          ],
        );

        double size = fs;
        for (int i = 0; i < 20; i++) {
          final tp = TextPainter(
            text: spanFor(size),
            textDirection: TextDirection.ltr,
            maxLines: 2,
          )..layout(maxWidth: w);
          if (!tp.didExceedMaxLines) break;
          size -= 1;
          if (size <= (isDesktop ? 38 : 28)) break;
        }
        return RichText(
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          text: spanFor(size),
        );
      },
    );
  }
}

class _HeroTrustRow extends StatelessWidget {
  final bool isDark, isDesktop;
  final AppLocalizations l;
  const _HeroTrustRow({
    required this.isDark,
    required this.l,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final divClr = isDark ? _dBorder : _lBorder;
    final items = [
      ('63M+', l.t('home_trust_deaf_community')),
      ('10', l.t('home_trust_indian_languages')),
      ('ISL', l.t('home_trust_certified_signs')),
      ('AI', l.t('home_trust_powered')),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: _sp24,
      runSpacing: _sp12,
      children: items.asMap().entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Text(
                  e.value.$1,
                  style: _heading(
                    isDesktop ? 18 : 15,
                    isDark ? _primaryDark : _primary,
                    w: FontWeight.w700,
                  ),
                ),
                Text(
                  e.value.$2,
                  style: _label(10.5, mutedClr, w: FontWeight.w400),
                ),
              ],
            ),
            if (e.key < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: _sp24),
                child: Container(width: 1, height: 28, color: divClr),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB STATS ROW — Animated counters
// ══════════════════════════════════════════════════════════════════════
class _WebStatsRow extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  const _WebStatsRow({
    required this.isDesktop,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final sep = isDark ? _dBorderSub : _lBorderSub;
    final stats = [
      (
        '63000000',
        '+',
        l.t('stat_mute_label'),
        isDark ? _primaryDark : _primary,
      ),
      ('8435000', '+', l.t('stat_isl_label'), isDark ? _purpleDark : _purple),
      (
        '250',
        '',
        l.t('stat_translators_label'),
        isDark ? _dangerDark : _danger,
      ),
    ];

    return Semantics(
      label: l.t('common_statistics'),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: _WebStatCell(
                    value: stats[i].$1,
                    suffix: stats[i].$2,
                    label: stats[i].$3,
                    color: stats[i].$4,
                    isDark: isDark,
                    isDesktop: isDesktop,
                  ),
                ),
                if (i < stats.length - 1) Container(width: 1, color: sep),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WebStatCell extends StatefulWidget {
  final String value, suffix, label;
  final Color color;
  final bool isDark, isDesktop;
  const _WebStatCell({
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isDesktop,
  });
  @override
  State<_WebStatCell> createState() => _WebStatCellState();
}

class _WebStatCellState extends State<_WebStatCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late int _target;

  @override
  void initState() {
    super.initState();
    _target = int.parse(widget.value.replaceAll(',', ''));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = Tween<double>(
      begin: 0,
      end: _target.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.isDesktop ? 40 : 28,
        horizontal: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_fmt(_anim.value.toInt())}${widget.suffix}',
            style: _heading(
              widget.isDesktop ? 44 : 32,
              widget.color,
              w: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _sp8),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: _body(13, widget.isDark ? _dTextSub : _lTextSub),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  WEB SECTION HELPERS
// ══════════════════════════════════════════════════════════════════════
class _WebSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _WebSectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _primaryDark : _primary;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp14, vertical: _sp6),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.20), width: 1),
        ),
        child: Text(
          text,
          style: _label(
            10.5,
            accent,
            w: FontWeight.w700,
          ).copyWith(letterSpacing: 1.5),
        ),
      ),
    );
  }
}

class _WebSectionTitle extends StatelessWidget {
  final String title, sub;
  final bool isDark, isDesktop;
  const _WebSectionTitle({
    required this.title,
    required this.sub,
    required this.isDark,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: _heading(isDesktop ? 36 : 28, isDark ? _dText : _lText),
      ),
      const SizedBox(height: _sp12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          sub,
          textAlign: TextAlign.center,
          style: _body(15, isDark ? _dTextSub : _lTextSub),
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════
//  WEB FEATURES GRID — Premium cards
// ══════════════════════════════════════════════════════════════════════
class _WebFeaturesGrid extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final void Function(Widget) push;

  const _WebFeaturesGrid({
    required this.isDesktop,
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
    required this.push,
  });

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.translate_rounded,
        _primary,
        _primaryDark,
        l.t('nav_terminal'),
        l.t('home_terminal_sub'),
        TranslateScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('home_terminal_b1_title'), l.t('home_terminal_b2_title')],
      ),
      (
        Icons.back_hand_rounded,
        _secondary,
        _secondaryDark,
        l.t('nav_signs'),
        l.t('home_signs_sub'),
        SignsPage(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('home_signs_b1_title'), l.t('home_signs_b2_title')],
      ),
      (
        Icons.compare_arrows_rounded,
        _success,
        _successDark,
        l.t('nav_bridge'),
        l.t('home_bridge_sub'),
        TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('home_bridge_b1_title'), l.t('home_bridge_b2_title')],
      ),
      (
        Icons.emergency_rounded,
        _danger,
        _dangerDark,
        l.t('nav_emergency'),
        l.t('home_bridge_sub'),
        EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('home_tag_life_saving_signs'), l.t('home_tag_one_tap_sos')],
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 2 : 1,
      mainAxisSpacing: _sp16,
      crossAxisSpacing: _sp16,
      childAspectRatio: isDesktop ? 2.0 : 2.8,
      children: features.map((f) {
        final accent = isDark ? f.$3 : f.$2;
        return _WebFeatureCard(
          icon: f.$1,
          accent: accent,
          title: f.$4,
          desc: f.$5,
          tags: f.$7,
          page: f.$6,
          isDark: isDark,
          push: push,
        );
      }).toList(),
    );
  }
}

class _WebFeatureCard extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String title, desc;
  final List<String> tags;
  final Widget page;
  final bool isDark;
  final void Function(Widget) push;

  const _WebFeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.tags,
    required this.page,
    required this.isDark,
    required this.push,
  });

  @override
  State<_WebFeatureCard> createState() => _WebFeatureCardState();
}

class _WebFeatureCardState extends State<_WebFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _dSurface : _lSurface;
    final bgHov = widget.isDark ? _dSurface2 : _lSurface2;
    final textClr = widget.isDark ? _dText : _lText;
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    final border = widget.isDark ? _dBorder : _lBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.push(widget.page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(_sp24),
          decoration: BoxDecoration(
            color: _hovered ? bgHov : bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? widget.accent.withOpacity(0.40) : border,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.accent.withOpacity(0.10)
                    : Colors.black.withOpacity(widget.isDark ? 0.15 : 0.04),
                blurRadius: _hovered ? 24 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(_hovered ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 28),
              ),
              const SizedBox(width: _sp20),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title, style: _heading(17, textClr)),
                    const SizedBox(height: _sp6),
                    Text(
                      widget.desc,
                      style: _body(13, subClr),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: _sp12),
                    Wrap(
                      spacing: _sp6,
                      runSpacing: _sp6,
                      children: widget.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _sp8,
                                vertical: _sp4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: widget.accent.withOpacity(0.20),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                t,
                                style: _label(
                                  11,
                                  widget.accent,
                                  w: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Arrow
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.accent,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB ASSISTANT SECTION — Premium showcase
// ══════════════════════════════════════════════════════════════════════
class _WebAssistantSection extends StatefulWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final Animation<double> float;
  final VoidCallback onTap;

  const _WebAssistantSection({
    required this.isDesktop,
    required this.isDark,
    required this.l,
    required this.float,
    required this.onTap,
  });

  @override
  State<_WebAssistantSection> createState() => _WebAssistantSectionState();
}

class _WebAssistantSectionState extends State<_WebAssistantSection> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? _purpleDark : _purple;
    final bg = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final border = isDark ? _dBorder : _lBorder;
    final l = widget.l;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Color(0xFF130B25), Color(0xFF1A0D35)]
                  : [Color(0xFFF5F0FF), Color(0xFFEDE8FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered
                  ? accent.withOpacity(0.50)
                  : accent.withOpacity(0.20),
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(_hovered ? 0.15 : 0.06),
                blurRadius: _hovered ? 40 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isDesktop ? 44 : 28),
            child: widget.isDesktop
                ? _assistantDesktop(l, accent, textClr, subClr)
                : _assistantMobile(l, accent, textClr, subClr),
          ),
        ),
      ),
    );
  }

  Widget _assistantDesktop(
    AppLocalizations l,
    Color accent,
    Color textClr,
    Color subClr,
  ) {
    return Row(
      children: [
        // Left content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp12,
                  vertical: _sp6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: accent),
                    const SizedBox(width: _sp6),
                    Text(
                      l.t('assistant_ai_powered_isl'),
                      style: _label(11, accent, w: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sp20),
              Text(l.t('assistant_banner_title'), style: _display(32, textClr)),
              const SizedBox(height: _sp12),
              Text(l.t('assistant_banner_desc'), style: _body(15, subClr)),
              const SizedBox(height: _sp24),
              // Language count badge
              Row(
                children: [
                  Icon(Icons.language_rounded, size: 14, color: accent),
                  const SizedBox(width: _sp8),
                  Text(
                    l.t('assistant_supports_10_languages'),
                    style: _label(13, accent, w: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: _sp24),
              _WebPrimaryBtn(
                label: l.t('assistant_open'),
                icon: Icons.arrow_forward_rounded,
                bgColor: accent,
                textColor: Colors.white,
                onTap: widget.onTap,
              ),
            ],
          ),
        ),
        const SizedBox(width: _sp48),
        // Right — decorative card cluster
        Expanded(
          flex: 2,
          child: _AssistantDecorPanel(
            accent: accent,
            isDark: widget.isDark,
            float: widget.float,
          ),
        ),
      ],
    );
  }

  Widget _assistantMobile(
    AppLocalizations l,
    Color accent,
    Color textClr,
    Color subClr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: _sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.t('assistant_title'), style: _heading(20, textClr)),
                  Text(
                    l.t('assistant_10_languages'),
                    style: _label(12, accent, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: _sp16),
        Text(l.t('assistant_banner_desc'), style: _body(14, subClr)),
        const SizedBox(height: _sp20),
        _WebPrimaryBtn(
          label: l.t('assistant_open'),
          icon: Icons.arrow_forward_rounded,
          bgColor: accent,
          textColor: Colors.white,
          onTap: widget.onTap,
        ),
      ],
    );
  }
}

class _AssistantDecorPanel extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final Animation<double> float;
  const _AssistantDecorPanel({
    required this.accent,
    required this.isDark,
    required this.float,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? Color(0xFF1C1430) : Color(0xFFEDE8FF);
    final bg2 = isDark ? Color(0xFF150F25) : Color(0xFFF0EBFF);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return AnimatedBuilder(
      animation: float,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -float.value * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mock chat bubble 1
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp16,
                  vertical: _sp12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l.t('assistant_mock_user_message'),
                  style: _body(13, Colors.white),
                ),
              ),
            ),
            const SizedBox(height: _sp12),
            // Mock AI response bubble
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp16,
                  vertical: _sp14,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: accent.withOpacity(0.20), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.sign_language_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                        const SizedBox(width: _sp8),
                        Text(
                          l.t('app_title_short'),
                          style: _label(11, accent, w: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: _sp8),
                    Text(
                      l.t('assistant_mock_ai_message'),
                      style: _body(12, subClr),
                      maxLines: 2,
                    ),
                    const SizedBox(height: _sp8),
                    Wrap(
                      spacing: _sp6,
                      children: [
                        _MiniChip(l.t('assistant_mock_chip_help'), accent),
                        _MiniChip(l.t('assistant_mock_chip_emergency'), accent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _sp12),
            // Language row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _sp12,
                vertical: _sp10,
              ),
              decoration: BoxDecoration(
                color: bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.15), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['EN', 'हि', 'म', 'বাং', 'தமி']
                    .map(
                      (lang) => Text(
                        lang,
                        style: _label(12, accent, w: FontWeight.w700),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color accent;
  const _MiniChip(this.label, this.accent);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: 3),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withOpacity(0.25), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.front_hand_rounded, size: 10, color: accent),
        const SizedBox(width: 4),
        Text(label, style: _label(10, accent, w: FontWeight.w700)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  WEB CTA BUTTONS
// ══════════════════════════════════════════════════════════════════════
class _WebPrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color bgColor, textColor;
  final VoidCallback onTap;
  const _WebPrimaryBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });
  @override
  State<_WebPrimaryBtn> createState() => _WebPrimaryBtnState();
}

class _WebPrimaryBtnState extends State<_WebPrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: _sp24),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: widget.bgColor.withOpacity(_hovered ? 0.40 : 0.25),
              blurRadius: _hovered ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: _label(14.5, widget.textColor, w: FontWeight.w700),
            ),
            const SizedBox(width: _sp8),
            Icon(widget.icon, color: widget.textColor, size: 16),
          ],
        ),
      ),
    ),
  );
}

class _WebSecondaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  const _WebSecondaryBtn({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });
  @override
  State<_WebSecondaryBtn> createState() => _WebSecondaryBtnState();
}

class _WebSecondaryBtnState extends State<_WebSecondaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _dSurface : _lSurface;
    final border = widget.isDark ? _dBorder : _lBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: _sp24),
          decoration: BoxDecoration(
            color: _hovered ? widget.accent.withOpacity(0.08) : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.accent.withOpacity(0.40) : border,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.accent, size: 16),
              const SizedBox(width: _sp8),
              Text(
                widget.label,
                style: _label(14.5, widget.accent, w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB OBJECTIVES GRID
// ══════════════════════════════════════════════════════════════════════
class _WebObjectivesGrid extends StatelessWidget {
  final bool isDesktop, isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _WebObjectivesGrid({
    required this.isDesktop,
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _objCards(l, toggleTheme, setLocale);
    final accents = [
      [_primary, _primaryDark],
      [_secondary, _secondaryDark],
      [_success, _successDark],
      [_warning, _warningDark],
      [_purple, _purpleDark],
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 2,
      mainAxisSpacing: _sp14,
      crossAxisSpacing: _sp14,
      childAspectRatio: isDesktop ? 1.55 : 1.35,
      children: cards.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        final accent = isDark ? accents[i][1] : accents[i][0];
        return _WebObjCard(
          icon: c.$2,
          title: c.$3,
          desc: c.$4,
          accent: accent,
          page: c.$5,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _WebObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _WebObjCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
    required this.page,
    required this.isDark,
  });
  @override
  State<_WebObjCard> createState() => _WebObjCardState();
}

class _WebObjCardState extends State<_WebObjCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _dSurface : _lSurface;
    final bgHov = widget.isDark ? _dSurface2 : _lSurface2;
    final textClr = widget.isDark ? _dText : _lText;
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    final border = widget.isDark ? _dBorder : _lBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        label: widget.title,
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => widget.page,
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 240),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(_sp20),
            decoration: BoxDecoration(
              color: _hovered ? bgHov : bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered ? widget.accent.withOpacity(0.40) : border,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? widget.accent.withOpacity(0.10)
                      : Colors.black.withOpacity(widget.isDark ? 0.12 : 0.03),
                  blurRadius: _hovered ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(
                          _hovered ? 0.15 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.accent, size: 18),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: widget.accent,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _sp14),
                Text(
                  widget.title,
                  style: _label(14.5, textClr, w: FontWeight.w700),
                ),
                const SizedBox(height: _sp6),
                Text(
                  widget.desc,
                  style: _body(12, subClr),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB VISION SECTION — Refined
// ══════════════════════════════════════════════════════════════════════
class _WebVisionSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _WebVisionSection({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _primaryDark : _primary;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 44),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.20), width: 1),
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(height: _sp20),
          Text(
            l.t('vision_title'),
            textAlign: TextAlign.center,
            style: _heading(24, textClr),
          ),
          const SizedBox(height: _sp12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              l.t('vision_body'),
              textAlign: TextAlign.center,
              style: _body(15, subClr),
            ),
          ),
          const SizedBox(height: _sp24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _sp16,
              vertical: _sp10,
            ),
            decoration: BoxDecoration(
              color: isDark ? _dangerDark.withOpacity(0.12) : _dangerLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? _dangerDark.withOpacity(0.28)
                    : _danger.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isDark ? _dangerDark : _danger,
                  size: 15,
                ),
                const SizedBox(width: _sp8),
                Text(
                  l.t('obj_crisis_stat'),
                  style: _label(
                    12.5,
                    isDark ? _dangerDark : _danger,
                    w: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB FOOTER — Refined minimal
// ══════════════════════════════════════════════════════════════════════
class _WebFooter extends StatelessWidget {
  final bool isDark;
  const _WebFooter({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _primaryDark : _primary;
    final sub = isDark ? _dTextMuted : _lTextMuted;
    final div = isDark ? _dBorderSub : _lBorderSub;

    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: div),
        const SizedBox(height: _sp24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Brand
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: _sp8),
                Text(
                  'VANI',
                  style: _label(
                    16,
                    isDark ? _dText : _lText,
                    w: FontWeight.w800,
                  ).copyWith(letterSpacing: 3.0),
                ),
              ],
            ),
            // Center
            Text(
              '© 2026 — ${AppLocalizations.of(context).t('home_footer')}',
              style: _body(12, sub),
            ),
            // Right
            Text(
              'Built for India 🇮🇳',
              style: _label(12, sub, w: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SKIP TO MAIN CONTENT
// ══════════════════════════════════════════════════════════════════════
class _SkipToMainContent extends StatelessWidget {
  final bool isDark;
  const _SkipToMainContent({required this.isDark});
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).t('home_skip_main_content'),
    button: true,
    child: const SizedBox.shrink(),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  UX4G TAB BAR — unchanged from original
// ══════════════════════════════════════════════════════════════════════
class _UX4GTabBar extends StatelessWidget {
  final bool isDark;
  final int tab;
  final ValueChanged<int> onTap;
  final AppLocalizations l;
  const _UX4GTabBar({
    required this.isDark,
    required this.tab,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final activeClr = isDark ? _primaryDark : _primary;
    final inactiveClr = isDark ? _dTextMuted : _lTextMuted;

    final items = [
      (Icons.home_outlined, Icons.home_rounded, l.t('nav_home')),
      (Icons.translate_outlined, Icons.translate_rounded, l.t('nav_terminal')),
      (Icons.back_hand_outlined, Icons.back_hand_rounded, l.t('nav_signs')),
      (
        Icons.compare_arrows_rounded,
        Icons.compare_arrows_rounded,
        l.t('nav_bridge'),
      ),
      (
        Icons.sign_language_outlined,
        Icons.sign_language_rounded,
        l.t('assistant_tab_label'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = tab == i;
              final tabAccent = (i == 4)
                  ? (isDark ? _purpleDark : _purple)
                  : activeClr;
              final color = active ? tabAccent : inactiveClr;

              return Expanded(
                child: Semantics(
                  label: item.$3,
                  selected: active,
                  button: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: active ? 24 : 0,
                          decoration: BoxDecoration(
                            color: tabAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: _sp4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            active ? item.$2 : item.$1,
                            key: ValueKey(active),
                            size: 22,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: _sp4),
                        Text(
                          item.$3,
                          overflow: TextOverflow.ellipsis,
                          style: _label(
                            active ? 10.5 : 10,
                            color,
                            w: active ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE HOME FEED — refined ISL card placement
// ══════════════════════════════════════════════════════════════════════
class _MobileHomeFeed extends StatelessWidget {
  final bool isDark;
  final Animation<double> fade, pulse;
  final Animation<Offset> slide;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  const _MobileHomeFeed({
    required this.isDark,
    required this.fade,
    required this.slide,
    required this.pulse,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileTopBar(
            isDark: isDark,
            l: l,
            pulse: pulse,
            toggleTheme: toggleTheme,
            setLocale: setLocale,
          ),

          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_sp16, _sp8, _sp16, 0),
                child: _MobileHeroCard(
                  isDark: isDark,
                  l: l,
                  toggleTheme: toggleTheme,
                  setLocale: setLocale,
                ),
              ),
            ),
          ),

          const SizedBox(height: _sp24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp16),
            child: _MobileStatsStrip(isDark: isDark, l: l),
          ),

          const SizedBox(height: _sp32),

          _SectionHeader(
            text: l.t('home_quick_access'),
            isDark: isDark,
            padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp12),
          ),
          _QuickAccessRow(
            isDark: isDark,
            l: l,
            toggleTheme: toggleTheme,
            setLocale: setLocale,
          ),

          const SizedBox(height: _sp32),

          // ── ISL ASSISTANT — Premium refined card ─────────────────────
          _SectionHeader(
            text: l.t('assistant_title'),
            isDark: isDark,
            padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp16),
            child: _MobileAssistantCardPremium(
              isDark: isDark,
              toggleTheme: toggleTheme,
              setLocale: setLocale,
            ),
          ),

          const SizedBox(height: _sp32),

          _SectionHeader(
            text: l.t('obj_heading'),
            isDark: isDark,
            padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp16),
          ),
          _MobileObjectivesScroll(
            isDark: isDark,
            l: l,
            toggleTheme: toggleTheme,
            setLocale: setLocale,
          ),

          const SizedBox(height: _sp32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp16),
            child: _MobileMissionCard(isDark: isDark, l: l),
          ),

          const SizedBox(height: _sp12),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE TOP BAR
// ══════════════════════════════════════════════════════════════════════
class _MobileTopBar extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  const _MobileTopBar({
    required this.isDark,
    required this.l,
    required this.pulse,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _primaryDark : _primary;
    final locale = Localizations.localeOf(context);
    final textClr = isDark ? _dText : _lText;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_sp16, _sp16, _sp12, _sp12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.t('app_title_short'),
                      style: _display(22, textClr).copyWith(letterSpacing: 3),
                    ),
                    const SizedBox(width: _sp8),
                    Semantics(
                      label: l.t('home_service_active'),
                      child: AnimatedBuilder(
                        animation: pulse,
                        builder: (_, __) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _success,
                            boxShadow: [
                              BoxShadow(
                                color: _success.withOpacity(pulse.value * 0.55),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(l.t('home_tagline'), style: _label(11, mutedClr)),
              ],
            ),
            const Spacer(),
            _LangButton(
              locale: locale,
              setLocale: setLocale,
              isDark: isDark,
              accent: accent,
              l: l,
            ),
            const SizedBox(width: _sp8),
            Tooltip(
              message: l.t(
                isDark
                    ? 'common_switch_to_light_mode'
                    : 'common_switch_to_dark_mode',
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: toggleTheme,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? _dSurface2 : _lSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? _dBorderSub : _lBorderSub,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    size: 18,
                    color: isDark ? _dTextSub : _lTextSub,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _sp8),
            _TopLogoutMenu(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE HERO CARD
// ══════════════════════════════════════════════════════════════════════
class _MobileHeroCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileHeroCard({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${l.t('hero_title_line1')} ${l.t('hero_title_line2')}. ${l.t('hero_sub')}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_sp24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF0F1A30), Color(0xFF1A2540)]
                : [_primary, Color(0xFF0D47A1)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _sp12,
                vertical: _sp5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.t('home_mobile_badge'),
                style: _label(11, Colors.white),
              ),
            ),

            const SizedBox(height: _sp16),
            Text(l.t('hero_title_line1'), style: _display(26, Colors.white)),
            Text(
              l.t('hero_title_line2'),
              style: _display(26, Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: _sp12),
            Text(
              l.t('hero_sub'),
              style: _body(13.5, Colors.white.withOpacity(0.80)),
            ),
            const SizedBox(height: _sp24),
            _PrimaryButton(
              label: l.t('get_started'),
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => TranslateScreen(
                    toggleTheme: toggleTheme,
                    setLocale: setLocale,
                  ),
                  transitionsBuilder: (_, a, __, c) =>
                      FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 260),
                ),
              ),
              bgColor: Colors.white,
              textColor: isDark ? _lText : _primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

const _sp5 = 5.0;

// ══════════════════════════════════════════════════════════════════════
//  MOBILE ISL ASSISTANT CARD — PREMIUM REDESIGN
// ══════════════════════════════════════════════════════════════════════
class _MobileAssistantCardPremium extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileAssistantCardPremium({
    required this.isDark,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<_MobileAssistantCardPremium> createState() =>
      _MobileAssistantCardPremiumState();
}

class _MobileAssistantCardPremiumState
    extends State<_MobileAssistantCardPremium>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final accent = isDark ? _purpleDark : _purple;
    final accentSurf = isDark ? _purpleSurfD : _purpleSurface;
    final bg1 = isDark ? Color(0xFF130B25) : Color(0xFFF7F3FF);
    final bg2 = isDark ? Color(0xFF1A0D35) : Color(0xFFEFE8FF);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Semantics(
      label: l.t('assistant_title'),
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ISLAssistantScreen(
                toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale,
              ),
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 260),
            ),
          );
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
              border: Border.all(color: accent.withOpacity(0.30), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(_sp16),
                  child: Row(
                    children: [
                      // Glowing avatar
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(
                                  _pulseAnim.value * 0.40,
                                ),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sign_language_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: _sp14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l.t('assistant_title'),
                                  style: _heading(16, textClr),
                                ),
                                const SizedBox(width: _sp8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _sp6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentSurf,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: _label(
                                      9,
                                      accent,
                                      w: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _sp6),
                                // Live pulse dot
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (_, __) => Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF22C55E),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(
                                            0xFF22C55E,
                                          ).withOpacity(_pulseAnim.value * 0.5),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: _sp4),
                            Text(
                              l.t('assistant_card_subtitle'),
                              style: _body(12, subClr),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Divider ──────────────────────────────────────────────
                Divider(
                  height: 1,
                  thickness: 1,
                  color: accent.withOpacity(0.12),
                ),

                // ── Feature chips ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(_sp12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AssistantFeatureChipSmall(
                          Icons.mic_rounded,
                          l.t('assistant_chip_voice_io'),
                          accent,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: _sp8),
                      Expanded(
                        child: _AssistantFeatureChipSmall(
                          Icons.front_hand_rounded,
                          l.t('assistant_chip_sign_guides'),
                          _secondary,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: _sp8),
                      Expanded(
                        child: _AssistantFeatureChipSmall(
                          Icons.auto_awesome_rounded,
                          'Vani AI',
                          _info,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantFeatureChipSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _AssistantFeatureChipSmall(
    this.icon,
    this.label,
    this.color,
    this.isDark,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: _sp8, horizontal: _sp6),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.10 : 0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.20), width: 1),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: _sp4),
        Text(
          label,
          style: _label(9.5, color, w: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE STATS STRIP (animated)
// ══════════════════════════════════════════════════════════════════════
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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(0)}M'
      : n >= 1000
      ? '${(n / 1000).toStringAsFixed(0)}K'
      : '$n';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final sep = isDark ? _dBorderSub : _lBorderSub;
    final stats = [
      (
        63000000,
        '+',
        widget.l.t('stat_mute_label'),
        isDark ? _primaryDark : _primary,
      ),
      (
        8435000,
        '+',
        widget.l.t('stat_isl_label'),
        isDark ? _purpleDark : _purple,
      ),
      (
        250,
        '',
        widget.l.t('stat_translators_label'),
        isDark ? _dangerDark : _danger,
      ),
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: stats.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: _sp16,
                    horizontal: _sp8,
                  ),
                  decoration: BoxDecoration(
                    border: i < stats.length - 1
                        ? Border(right: BorderSide(color: sep, width: 1))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_fmt((s.$1 * _anim.value).toInt())}${s.$2}',
                        style: _heading(19, s.$4, w: FontWeight.w700),
                      ),
                      const SizedBox(height: _sp4),
                      Text(
                        s.$3,
                        textAlign: TextAlign.center,
                        style: _label(
                          9.5,
                          isDark ? _dTextMuted : _lTextMuted,
                          w: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SECTION HEADER
// ══════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  final EdgeInsets padding;
  const _SectionHeader({
    required this.text,
    required this.isDark,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: padding,
      child: Text(
        text,
        style: _heading(18, isDark ? _dText : _lText, w: FontWeight.w700),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  QUICK ACCESS ROW
// ══════════════════════════════════════════════════════════════════════
class _QuickAccessRow extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _QuickAccessRow({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext ctx) {
    final cards = [
      (
        _secondary,
        _secondaryDark,
        Icons.compare_arrows_rounded,
        l.t('nav_bridge'),
        l.t('home_open_bridge'),
      ),
      (
        _danger,
        _dangerDark,
        Icons.emergency_share_rounded,
        l.t('nav_emergency'),
        l.t('sos_screen_title'),
      ),
      (
        _success,
        _successDark,
        Icons.back_hand_rounded,
        l.t('nav_signs'),
        l.t('home_browse_signs'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sp16),
      child: Row(
        children: cards.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          final accent = isDark ? c.$2 : c.$1;
          Widget dest() {
            switch (i) {
              case 0:
                return TwoWayScreen(
                  toggleTheme: toggleTheme,
                  setLocale: setLocale,
                );
              case 1:
                return EmergencyScreen(
                  toggleTheme: toggleTheme,
                  setLocale: setLocale,
                );
              default:
                return SignsPage(
                  toggleTheme: toggleTheme,
                  setLocale: setLocale,
                );
            }
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < cards.length - 1 ? _sp12 : 0),
              child: _QuickTile(
                accent: accent,
                icon: c.$3,
                label: c.$4,
                sub: c.$5,
                isDark: isDark,
                onTap: () => Navigator.push(
                  ctx,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => dest(),
                    transitionsBuilder: (_, a, __, ch) =>
                        FadeTransition(opacity: a, child: ch),
                    transitionDuration: const Duration(milliseconds: 240),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String label, sub;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickTile({
    required this.accent,
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
    required this.onTap,
  });
  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _dSurface : _lSurface;
    final label = widget.isDark ? _dText : _lText;
    final sub = widget.isDark ? _dTextSub : _lTextSub;
    final border = widget.isDark ? _dBorder : _lBorder;

    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(_sp14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 20),
                ),
                const SizedBox(height: _sp12),
                Text(
                  widget.label,
                  style: _label(12, label, w: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: _sp4),
                Text(
                  widget.sub,
                  style: _label(10, sub, w: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE OBJECTIVES SCROLL
// ══════════════════════════════════════════════════════════════════════
class _MobileObjectivesScroll extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileObjectivesScroll({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _objCards(l, toggleTheme, setLocale);
    final accents = [
      [_primary, _primaryDark],
      [_secondary, _secondaryDark],
      [_success, _successDark],
      [_warning, _warningDark],
      [_purple, _purpleDark],
      [_danger, _dangerDark],
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _sp16),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        itemBuilder: (ctx, i) {
          final c = cards[i];
          final accent = isDark ? accents[i][1] : accents[i][0];
          return Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? _sp12 : 0),
            child: _ObjCard(
              icon: c.$2,
              title: c.$3,
              desc: c.$4,
              accent: accent,
              page: c.$5,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

List<(Color, IconData, String, String, Widget)> _objCards(
  AppLocalizations l,
  VoidCallback toggleTheme,
  Function(Locale) setLocale,
) => [
  (
    _primary,
    Icons.accessibility_new_rounded,
    l.t('obj_accessibility'),
    l.t('obj_accessibility_desc'),
    AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _secondary,
    Icons.connecting_airports_rounded,
    l.t('obj_bridging'),
    l.t('obj_bridging_desc'),
    BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _success,
    Icons.people_outline_rounded,
    l.t('obj_inclusivity'),
    l.t('obj_inclusivity_desc'),
    InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _warning,
    Icons.shield_outlined,
    l.t('obj_privacy'),
    l.t('obj_privacy_desc'),
    PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _danger,
    Icons.school_rounded,
    l.t('obj_education'),
    l.t('obj_education_desc'),
    EducationPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
];

class _ObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _ObjCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
    required this.page,
    required this.isDark,
  });
  @override
  State<_ObjCard> createState() => _ObjCardState();
}

class _ObjCardState extends State<_ObjCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _dSurface : _lSurface;
    final label = widget.isDark ? _dText : _lText;
    final sub = widget.isDark ? _dTextSub : _lTextSub;
    final border = widget.isDark ? _dBorder : _lBorder;

    return Semantics(
      label: widget.title,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => widget.page,
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 240),
            ),
          );
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            width: 144,
            padding: const EdgeInsets.all(_sp14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 18),
                ),
                const SizedBox(height: _sp10),
                Text(
                  widget.title,
                  style: _label(12.5, label, w: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: _sp4),
                Expanded(
                  child: Text(
                    widget.desc,
                    style: _body(10.5, sub),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE MISSION CARD
// ══════════════════════════════════════════════════════════════════════
class _MobileMissionCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobileMissionCard({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dSurface : _primarySurface;
    final border = isDark ? _dBorder : _primary.withOpacity(0.20);
    final accent = isDark ? _primaryDark : _primary;
    final textClr = isDark ? _dText : _info;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Container(
      padding: const EdgeInsets.all(_sp20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, color: accent, size: 18),
              const SizedBox(width: _sp8),
              Text(
                l.t('home_our_mission'),
                style: _label(11.5, accent, w: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: _sp12),
          Text(l.t('vision_title'), style: _heading(17, textClr)),
          const SizedBox(height: _sp8),
          Text(l.t('home_mission_body'), style: _body(13, subClr)),
          const SizedBox(height: _sp16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _sp12,
              vertical: _sp8,
            ),
            decoration: BoxDecoration(
              color: isDark ? _dangerDark.withOpacity(0.12) : _dangerLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? _dangerDark.withOpacity(0.30)
                    : _danger.withOpacity(0.30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isDark ? _dangerDark : _danger,
                  size: 14,
                ),
                const SizedBox(width: _sp8),
                Flexible(
                  child: Text(
                    l.t('obj_crisis_stat'),
                    style: _label(
                      11.5,
                      isDark ? _dangerDark : _danger,
                      w: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  FEATURE DETAIL (mobile tabs)
// ══════════════════════════════════════════════════════════════════════
class _FeatureDetail extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final IconData icon;
  final String title, subtitle, launchLabel;
  final Color accentLight, accentDark;
  final VoidCallback onLaunch;
  final List<(IconData, String, String)> bullets;

  const _FeatureDetail({
    required this.isDark,
    required this.l,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentLight,
    required this.accentDark,
    required this.launchLabel,
    required this.onLaunch,
    required this.bullets,
  });

  Color get _accent => isDark ? accentDark : accentLight;

  @override
  Widget build(BuildContext context) {
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, _sp24, 0, _sp20),
              child: Text(title, style: _display(26, textClr)),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_sp20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.30), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _accent, size: 26),
                ),
                const SizedBox(width: _sp16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _heading(17, textClr)),
                      const SizedBox(height: _sp4),
                      Text(subtitle, style: _body(13, subClr)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: _sp24),
          Text(
            l.t('page_section_header').toUpperCase(),
            style: _label(
              10.5,
              isDark ? _dTextMuted : _lTextMuted,
              w: FontWeight.w700,
            ).copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: _sp12),

          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1),
            ),
            child: Column(
              children: bullets.asMap().entries.map((e) {
                final i = e.key;
                final f = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sp16,
                        vertical: _sp14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(f.$1, color: _accent, size: 18),
                          ),
                          const SizedBox(width: _sp16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$2,
                                  style: _label(
                                    13.5,
                                    textClr,
                                    w: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: _sp4),
                                Text(f.$3, style: _body(12, subClr)),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: isDark ? _dTextMuted : _lTextMuted,
                          ),
                        ],
                      ),
                    ),
                    if (i < bullets.length - 1)
                      Divider(
                        indent: 72,
                        height: 1,
                        thickness: 1,
                        color: isDark ? _dBorderSub : _lBorderSub,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: _sp24),
          _PrimaryButton(
            label: launchLabel,
            icon: Icons.arrow_forward_rounded,
            onTap: onLaunch,
            bgColor: _accent,
            textColor: Colors.white,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  PRIMARY BUTTON
// ══════════════════════════════════════════════════════════════════════
class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor, textColor;
  final bool fullWidth;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    this.fullWidth = false,
  });
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: _sp24),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.bgColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: _label(14.5, widget.textColor, w: FontWeight.w700),
              ),
              const SizedBox(width: _sp8),
              Icon(widget.icon, color: widget.textColor, size: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  LANG BUTTON & LOGOUT (unchanged from original)
// ══════════════════════════════════════════════════════════════════════
class _LangButton extends StatelessWidget {
  final Locale locale;
  final Function(Locale) setLocale;
  final bool isDark;
  final Color accent;
  final AppLocalizations l;
  const _LangButton({
    required this.locale,
    required this.setLocale,
    required this.isDark,
    required this.accent,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧', 'name': l.t('lang_en')},
      {'code': 'hi', 'flag': '🇮🇳', 'name': l.t('lang_hi')},
      {'code': 'mr', 'flag': '🇮🇳', 'name': l.t('lang_mr')},
    ];
    final cur = langs.firstWhere(
      (x) => x['code'] == locale.languageCode,
      orElse: () => langs[0],
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? _dBorder : _lBorder, width: 1),
      ),
      color: isDark ? _dSurface2 : _lSurface,
      elevation: 8,
      onSelected: (c) => setLocale(Locale(c)),
      itemBuilder: (_) => langs
          .map(
            (lang) => PopupMenuItem<String>(
              value: lang['code'],
              height: 44,
              child: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: _sp12),
                  Text(
                    lang['name']!,
                    style: _body(
                      14,
                      lang['code'] == locale.languageCode
                          ? accent
                          : (isDark ? _dText : _lText),
                    ),
                  ),
                  if (lang['code'] == locale.languageCode) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: accent, size: 16),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.25), width: 1),
        ),
        child: Center(
          child: Text(cur['flag']!, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _TopLogoutMenu extends StatelessWidget {
  final bool isDark;
  const _TopLogoutMenu({required this.isDark});

  Future<void> _logout(BuildContext context) async {
    try {
      final box = Hive.box<EmergencyContact>('emergency_contacts');
      await box.clear();
    } catch (_) {}
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('menu_signed_out')),
        backgroundColor: isDark ? _dSurface2 : _lText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subClr = isDark ? _dTextSub : _lTextSub;
    final redClr = isDark ? _dangerDark : _danger;
    final bg = isDark ? _dSurface2 : _lSurface;

    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? _dBorder : _lBorder, width: 1),
      ),
      color: bg,
      elevation: 8,
      tooltip: l.t('common_more_options'),
      icon: Icon(Icons.more_vert_rounded, color: subClr, size: 20),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: redClr, size: 18),
              const SizedBox(width: _sp12),
              Text(
                l.t('menu_sign_out'),
                style: _body(14, redClr, w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value != 'logout') return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              l.t('menu_sign_out_confirm_title'),
              style: _heading(17, isDark ? _dText : _lText),
            ),
            content: Text(
              l.t('menu_sign_out_confirm_body'),
              style: _body(14, subClr),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l.t('menu_cancel'),
                  style: _body(14, subClr, w: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logout(context);
                },
                child: Text(
                  l.t('menu_sign_out'),
                  style: _body(14, redClr, w: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
