import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../components/GlobalNavbar.dart';
import '../components/SOSFloatingButton.dart';
import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import '../services/web_home_nav.dart';
import 'TranslateScreen.dart';
import 'TwoWayScreen.dart';
import 'EmergencyScreen.dart';
import 'Signspage.dart';
import 'Islassistantscreen.dart';
import 'objectives/AccessibilityPage.dart';
import 'objectives/BridgingGapsPage.dart';
import 'objectives/LocalizationPage.dart';
import 'objectives/InclusivityPage.dart';
import 'objectives/PrivacyPage.dart';
import 'objectives/EducationPage.dart';
//  DESIGN TOKENS — Fintech palette
const _ff = 'Plus Jakarta Sans';

// Electric blue family
const _elBlue = Color(0xFF2563EB);
const _elBlueD = Color(0xFF60A5FA);
const _elBlue2 = Color(0xFF1D4ED8);
// Cyan accent
const _cyan = Color(0xFF06B6D4);
const _cyanD = Color(0xFF22D3EE);
// Teal
const _teal = Color(0xFF0D9488);
const _tealD = Color(0xFF2DD4BF);
// Purple/violet
const _violet = Color(0xFF7C3AED);
const _violetD = Color(0xFFA78BFA);
// Emerald
const _emerald = Color(0xFF059669);
const _emeraldD = Color(0xFF34D399);
// Amber
const _amber = Color(0xFFD97706);
const _amberD = Color(0xFFFBBF24);
// Danger
const _red = Color(0xFFEF4444);
const _redD = Color(0xFFFCA5A5);
// Deep navy backgrounds (dark)
const _navy1 = Color(0xFF060E1F);
const _navy3 = Color(0xFF0D1628);
const _navy4 = Color(0xFF111E35);
const _navy5 = Color(0xFF152440);
const _navyB = Color(0xFF1A2D4F); // borders
// Light backgrounds
const _lBg = Color(0xFFF0F4FF);
const _lSurf = Color(0xFFFFFFFF);
const _lSurf2 = Color(0xFFF1F5FC);
const _lBorder = Color(0xFFD1DCF0);
const _lBorderSub = Color(0xFFE8EFF9);
const _lText = Color(0xFF0B1426);
const _lTextSub = Color(0xFF2D4270);
const _lTextMuted = Color(0xFF647BA8);
// Dark text
const _dText = Color(0xFFE2EAFF);
const _dTextSub = Color(0xFF8BA3CC);
const _dTextMuted = Color(0xFF4A6091);

// Spacing
const _s4 = 4.0;
const _s6 = 6.0;
const _s8 = 8.0;
const _s10 = 10.0;
const _s12 = 12.0;
const _s14 = 14.0;
const _s16 = 16.0;
const _s18 = 18.0;
const _s20 = 20.0;
const _s24 = 24.0;
const _s32 = 32.0;
const _s40 = 40.0;
const _s48 = 48.0;

TextStyle _disp(double sz, Color c) => TextStyle(
  fontFamily: _ff,
  fontSize: sz,
  fontWeight: FontWeight.w700,
  color: c,
  height: 1.15,
  letterSpacing: -0.6,
);
TextStyle _h(double sz, Color c, {FontWeight w = FontWeight.w700}) => TextStyle(
  fontFamily: _ff,
  fontSize: sz,
  fontWeight: w,
  color: c,
  height: 1.3,
  letterSpacing: -0.2,
);
TextStyle _b(double sz, Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
  fontFamily: _ff,
  fontSize: sz,
  fontWeight: w,
  color: c,
  height: 1.65,
);
TextStyle _lbl(double sz, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.4,
      letterSpacing: 0.1,
    );

TextStyle _wDisp(double sz, Color c) => TextStyle(
  fontFamily: _ff,
  fontSize: sz,
  fontWeight: FontWeight.w800,
  color: c,
  height: 1.08,
  letterSpacing: -0.9,
);

TextStyle _wHead(double sz, Color c, {FontWeight w = FontWeight.w700}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.14,
      letterSpacing: -0.45,
    );

TextStyle _wBody(double sz, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.85,
      letterSpacing: 0.0,
    );

TextStyle _wKicker(double sz, Color c, {FontWeight w = FontWeight.w700}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.3,
      letterSpacing: 1.3,
    );

Color _bg(bool d) => d ? _navy1 : _lBg;
Color _surf(bool d) => d ? _navy3 : _lSurf;
Color _surf2(bool d) => d ? _navy4 : _lSurf2;
Color _bord(bool d) => d ? _navyB : _lBorder;
Color _bordS(bool d) => d ? _navy4 : _lBorderSub;
Color _txt(bool d) => d ? _dText : _lText;
Color _txts(bool d) => d ? _dTextSub : _lTextSub;
Color _txtm(bool d) => d ? _dTextMuted : _lTextMuted;
Color _acc(bool d) => d ? _elBlueD : _elBlue;
Color _accV(bool d) => d ? _violetD : _violet;
//  HOME SCREEN
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
  late AnimationController _entCtrl,
      _pulseCtrl,
      _tabCtrl,
      _floatCtrl,
      _shimCtrl;
  late Animation<double> _fade, _pulse, _tabFade, _float, _shim;
  late Animation<Offset> _slide;
  int _tab = 0;
  final _scrollCtrl = ScrollController();
  final _heroKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _objectivesKey = GlobalKey();
  final _visionKey = GlobalKey();
  final _footerKey = GlobalKey();
  bool _revealMarquee = true;
  bool _revealFeatures = false;
  bool _revealHowItWorks = false;
  bool _revealObjectives = false;
  bool _revealVision = false;
  bool _revealFooter = false;

  @override
  void initState() {
    super.initState();

    _entCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tabFade = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shim = Tween<double>(begin: 0.0, end: 1.0).animate(_shimCtrl);

    _entCtrl.forward();
    _tabCtrl.forward();

    if (kIsWeb) {
      WebHomeNav.listenable.addListener(_onWebHomeNavRequest);
      _scrollCtrl.addListener(_updateWebRevealStates);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateWebRevealStates(),
      );
    }
  }

  void _updateWebRevealStates() {
    if (!kIsWeb || !mounted) return;
    var changed = false;

    bool visible(GlobalKey key, {double triggerRatio = 0.86}) {
      final ctx = key.currentContext;
      if (ctx == null) return false;
      final rb = ctx.findRenderObject();
      if (rb is! RenderBox || !rb.hasSize) return false;
      final top = rb.localToGlobal(Offset.zero).dy;
      final vh = MediaQuery.of(context).size.height;
      return top < vh * triggerRatio;
    }

    if (!_revealMarquee && visible(_featuresKey, triggerRatio: 1.12)) {
      _revealMarquee = true;
      changed = true;
    }
    if (!_revealFeatures && visible(_featuresKey)) {
      _revealFeatures = true;
      changed = true;
    }
    if (!_revealHowItWorks && visible(_howItWorksKey)) {
      _revealHowItWorks = true;
      changed = true;
    }
    if (!_revealObjectives && visible(_objectivesKey)) {
      _revealObjectives = true;
      changed = true;
    }
    if (!_revealVision && visible(_visionKey, triggerRatio: 0.9)) {
      _revealVision = true;
      changed = true;
    }
    if (!_revealFooter && visible(_footerKey, triggerRatio: 0.95)) {
      _revealFooter = true;
      changed = true;
    }

    if (changed) setState(() {});
  }

  void _onWebHomeNavRequest() {
    final section = WebHomeNav.requestedSection;
    if (section == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToWebSection(section);
      WebHomeNav.clear();
    });
  }

  void _scrollToWebSection(WebHomeSection section) {
    if (!_scrollCtrl.hasClients) return;

    if (section == WebHomeSection.home) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final key = switch (section) {
      WebHomeSection.features => _featuresKey,
      WebHomeSection.howItWorks => _howItWorksKey,
      WebHomeSection.objectives => _objectivesKey,
      WebHomeSection.vision => _visionKey,
      WebHomeSection.contact => _footerKey,
      WebHomeSection.home => _heroKey,
    };

    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        alignment: 0.03,
      );
    }
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
    if (kIsWeb) {
      WebHomeNav.listenable.removeListener(_onWebHomeNavRequest);
      _scrollCtrl.removeListener(_updateWebRevealStates);
    }
    _entCtrl.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _floatCtrl.dispose();
    _shimCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final d = Theme.of(context).brightness == Brightness.dark;
    return kIsWeb || w >= 700
        ? _buildWeb(context, d, w)
        : _buildMobile(context, d);
  }
  //  MOBILE
  Widget _buildMobile(BuildContext ctx, bool d) {
    final l = AppLocalizations.of(ctx);
    return Scaffold(
      backgroundColor: _bg(d),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(opacity: _tabFade, child: _mobileBody(ctx, l, d)),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: SOSFloatingButton(
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _FinTechTabBar(
        isDark: d,
        tab: _tab,
        onTap: _switchTab,
        l: l,
      ),
    );
  }

  Widget _mobileBody(BuildContext ctx, AppLocalizations l, bool d) {
    switch (_tab) {
      case 0:
        return _MobileHomeFeed(
          isDark: d,
          fade: _fade,
          slide: _slide,
          pulse: _pulse,
          shim: _shim,
          l: l,
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        );
      case 1:
        return _MobFeatureDetail(
          isDark: d,
          l: l,
          icon: Icons.translate_rounded,
          title: l.t('nav_terminal'),
          subtitle: l.t('home_terminal_sub'),
          aL: _elBlue,
          aD: _elBlueD,
          launchLabel: l.t('nav_terminal'),
          onLaunch: () => _push(
            ctx,
            TranslateScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: const [
            (
              Icons.mic_none_rounded,
              'Voice to Text',
              'Translate spoken language into accessible text in real time.',
            ),
            (
              Icons.wifi_tethering_rounded,
              'Live Session',
              'Run seamless conversation sessions with low-latency responses.',
            ),
            (
              Icons.shield_outlined,
              'Private Processing',
              'Sensitive translation runs with strong privacy defaults.',
            ),
          ],
        );
      case 2:
        return _MobFeatureDetail(
          isDark: d,
          l: l,
          icon: Icons.back_hand_rounded,
          title: l.t('nav_signs'),
          subtitle: l.t('home_signs_sub'),
          aL: _teal,
          aD: _tealD,
          launchLabel: l.t('nav_signs'),
          onLaunch: () => _push(
            ctx,
            SignsPage(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: const [
            (
              Icons.pan_tool_alt_rounded,
              'Guided Signs',
              'Browse practical ISL signs with category-based discovery.',
            ),
            (
              Icons.center_focus_strong_rounded,
              'Handshape Clarity',
              'Visual cues help maintain precise handshape and motion.',
            ),
            (
              Icons.school_rounded,
              'Practice Friendly',
              'Built for day-to-day learning and quick refresher sessions.',
            ),
          ],
        );
      case 3:
        return _MobFeatureDetail(
          isDark: d,
          l: l,
          icon: Icons.compare_arrows_rounded,
          title: l.t('nav_bridge'),
          subtitle: l.t('home_bridge_sub'),
          aL: _emerald,
          aD: _emeraldD,
          launchLabel: l.t('nav_bridge'),
          onLaunch: () => _push(
            ctx,
            TwoWayScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: const [
            (
              Icons.hearing_rounded,
              'Hearing Side',
              'Convert sign output into clear text and voice for listeners.',
            ),
            (
              Icons.sign_language_rounded,
              'Signing Side',
              'Translate speech or text into accessible sign-friendly output.',
            ),
            (
              Icons.sync_alt_rounded,
              'Bidirectional Flow',
              'Keep both participants in sync throughout the conversation.',
            ),
          ],
        );
      case 4:
        return _MobFeatureDetail(
          isDark: d,
          l: l,
          icon: Icons.auto_awesome_rounded,
          title: l.t('assistant_title'),
          subtitle: l.t('assistant_banner_desc'),
          aL: _violet,
          aD: _violetD,
          launchLabel: l.t('assistant_open'),
          onLaunch: () => _push(
            ctx,
            ISLAssistantScreen(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
            ),
          ),
          bullets: const [
            (
              Icons.psychology_alt_rounded,
              'Context Aware AI',
              'Get smart assistance tuned for accessibility and ISL usage.',
            ),
            (
              Icons.record_voice_over_rounded,
              'Voice + Sign Workflow',
              'Bridge voice and signs using one guided assistant experience.',
            ),
            (
              Icons.bolt_rounded,
              'Fast Actions',
              'Launch translation tools and workflows without extra steps.',
            ),
          ],
        );
      default:
        return _MobileHomeFeed(
          isDark: d,
          fade: _fade,
          slide: _slide,
          pulse: _pulse,
          shim: _shim,
          l: l,
          toggleTheme: widget.toggleTheme,
          setLocale: widget.setLocale,
        );
    }
  }

  void _push(BuildContext ctx, Widget p) {
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => p,
        transitionsBuilder: (_, a, _, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }
  //  WEB
  Widget _buildWeb(BuildContext ctx, bool d, double w) {
    final desktop = w > 1100;
    final compactWeb = w < 700;
    final hPad = desktop ? 88.0 : (compactWeb ? 16.0 : 44.0);
    final l = AppLocalizations.of(ctx);

    return Scaffold(
      backgroundColor: _bg(d),
      body: Stack(
        children: [
          Positioned(
            top: -200,
            left: -200,
            child: _Orb(color: _elBlue.withOpacity(d ? 0.18 : 0.12), size: 680),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: _Orb(color: _violet.withOpacity(d ? 0.14 : 0.09), size: 560),
          ),
          Positioned(
            bottom: 100,
            left: w * 0.26,
            child: _Orb(color: _cyan.withOpacity(d ? 0.12 : 0.08), size: 460),
          ),
          Positioned(
            top: 132,
            left: w * 0.34,
            child: _AmbientBeam(
              width: 420,
              height: 180,
              color: _elBlue,
              dark: d,
            ),
          ),
          Positioned(
            bottom: 180,
            right: w * 0.22,
            child: _AmbientBeam(width: 360, height: 150, color: _cyan, dark: d),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: d
                        ? [
                            Colors.white.withOpacity(0.02),
                            Colors.transparent,
                            _elBlue.withOpacity(0.02),
                          ]
                        : [
                            _elBlue.withOpacity(0.04),
                            Colors.transparent,
                            _cyan.withOpacity(0.025),
                          ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                color: d
                    ? Colors.white.withOpacity(0.025)
                    : _elBlue.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _ArcDecor(size: 300, color: _elBlue, dark: d, flip: false),
          ),
          Positioned(
            top: 14,
            right: 180,
            child: _ArcDecor(size: 220, color: _cyan, dark: d, flip: true),
          ),
          Positioned(
            bottom: 170,
            left: -42,
            child: _ArcDecor(size: 190, color: _elBlue, dark: d, flip: false),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _ArcDecor(size: 360, color: _violet, dark: d, flip: true),
          ),
          Positioned(
            top: 86,
            right: 28,
            child: _BorderCircle(
              size: 154,
              color: _elBlue,
              dark: d,
              stroke: 1.0,
            ),
          ),
          Positioned(
            bottom: 120,
            right: 58,
            child: _BorderCircle(size: 118, color: _cyan, dark: d, stroke: 0.9),
          ),
          Positioned(
            top: 268,
            left: -38,
            child: _BorderCircle(
              size: 152,
              color: _violet,
              dark: d,
              stroke: 0.95,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  GlobalNavbar(
                    toggleTheme: widget.toggleTheme,
                    setLocale: widget.setLocale,
                    activeRoute: 'home',
                  ),

                  // Hero
                  KeyedSubtree(
                    key: _heroKey,
                    child: _WebHero(
                      desktop: desktop,
                      dark: d,
                      l: l,
                      fade: _fade,
                      slide: _slide,
                      pulse: _pulse,
                      float: _float,
                      shim: _shim,
                      hPad: hPad,
                      onCTA: () => _push(
                        ctx,
                        TranslateScreen(
                          toggleTheme: widget.toggleTheme,
                          setLocale: widget.setLocale,
                        ),
                      ),
                      onAssistant: () => _push(
                        ctx,
                        ISLAssistantScreen(
                          toggleTheme: widget.toggleTheme,
                          setLocale: widget.setLocale,
                        ),
                      ),
                    ),
                  ),

                  // Marquee strip
                  _ScrollReveal(
                    visible: _revealMarquee,
                    child: _MarqueeStrip(dark: d),
                  ),

                  // Stats
                  _ScrollReveal(
                    visible: _revealMarquee,
                    delayMs: 70,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _WebStats(desktop: desktop, dark: d, l: l),
                    ),
                  ),
                  SizedBox(height: desktop ? 80 : 60),

                  // Features
                  KeyedSubtree(
                    key: _featuresKey,
                    child: _ScrollReveal(
                      visible: _revealFeatures,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _WebFeatures(
                          desktop: desktop,
                          dark: d,
                          l: l,
                          toggleTheme: widget.toggleTheme,
                          setLocale: widget.setLocale,
                          push: (p) => _push(ctx, p),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: desktop ? 80 : 60),

                  // AI Assistant Banner
                  KeyedSubtree(
                    key: _howItWorksKey,
                    child: _ScrollReveal(
                      visible: _revealHowItWorks,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _WebAIBanner(
                          desktop: desktop,
                          dark: d,
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
                    ),
                  ),
                  SizedBox(height: desktop ? 80 : 60),

                  // Objectives
                  KeyedSubtree(
                    key: _objectivesKey,
                    child: _ScrollReveal(
                      visible: _revealObjectives,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _WebObjectives(
                          desktop: desktop,
                          dark: d,
                          l: l,
                          toggleTheme: widget.toggleTheme,
                          setLocale: widget.setLocale,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: desktop ? 80 : 60),

                  // Vision
                  KeyedSubtree(
                    key: _visionKey,
                    child: _ScrollReveal(
                      visible: _revealVision,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? hPad * 0.55 : hPad * 0.8,
                        ),
                        child: _WebHoverLift(
                          lift: 8,
                          scale: 1.008,
                          child: _WebVision(dark: d, l: l),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: desktop ? 56 : 40),

                  // Footer
                  KeyedSubtree(
                    key: _footerKey,
                    child: _ScrollReveal(
                      visible: _revealFooter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _WebFooter(
                          dark: d,
                          l: l,
                          onBackToTop: () {
                            if (_scrollCtrl.hasClients) {
                              _scrollCtrl.animateTo(
                                0,
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: _s48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantMiniTag extends StatelessWidget {
  final String label;
  const _AssistantMiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? _violetD : _violet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.18), accent.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.28), width: 1),
      ),
      child: Text(label, style: _lbl(10.8, accent, w: FontWeight.w700)),
    );
  }
}
//  BACKGROUND PAINTER HELPERS
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _BorderCircle extends StatelessWidget {
  final double size;
  final Color color;
  final bool dark;
  final double stroke;
  const _BorderCircle({
    required this.size,
    required this.color,
    required this.dark,
    this.stroke = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(dark ? 0.20 : 0.14),
          width: stroke,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(dark ? 0.06 : 0.04),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _AmbientBeam extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool dark;
  const _AmbientBeam({
    required this.width,
    required this.height,
    required this.color,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.20,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              color.withOpacity(dark ? 0.06 : 0.05),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(dark ? 0.07 : 0.05),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const sp = 32.0;
    for (double x = 0; x < size.width; x += sp) {
      for (double y = 0; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class _WebHoverLift extends StatefulWidget {
  final Widget child;
  final double lift;
  final double scale;
  const _WebHoverLift({
    required this.child,
    this.lift = 10,
    this.scale = 1.012,
  });

  @override
  State<_WebHoverLift> createState() => _WebHoverLiftState();
}

class _WebHoverLiftState extends State<_WebHoverLift> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _hov ? -widget.lift : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (_, dy, child) => Transform.translate(
          offset: Offset(0, dy),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            scale: _hov ? widget.scale : 1,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ScrollReveal extends StatelessWidget {
  final Widget child;
  final bool visible;
  final int delayMs;

  const _ScrollReveal({
    required this.child,
    required this.visible,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _ArcDecor extends StatelessWidget {
  final double size;
  final Color color;
  final bool dark;
  final bool flip;
  const _ArcDecor({
    required this.size,
    required this.color,
    required this.dark,
    required this.flip,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: flip
          ? (Matrix4.identity()..rotateZ(math.pi))
          : Matrix4.identity(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ArcPainter(color: color, dark: dark),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final bool dark;
  const _ArcPainter({required this.color, required this.dark});

  @override
  void paint(Canvas canvas, Size s) {
    void arc(double r, double op) {
      final glow = Paint()
        ..color = color.withOpacity(dark ? op * 0.05 : op * 0.034)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi / 2,
        false,
        glow,
      );

      final p = Paint()
        ..color = color.withOpacity(dark ? op * 0.38 : op * 0.29)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.92;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi / 2,
        false,
        p,
      );
    }

    arc(s.width * 0.34, 0.32);
    arc(s.width * 0.66, 0.20);
    arc(s.width * 0.88, 0.11);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}
//  WEB HERO
class _WebHero extends StatelessWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  final Animation<double> fade, pulse, float, shim;
  final Animation<Offset> slide;
  final double hPad;
  final VoidCallback onCTA, onAssistant;

  const _WebHero({
    required this.desktop,
    required this.dark,
    required this.l,
    required this.fade,
    required this.slide,
    required this.pulse,
    required this.float,
    required this.shim,
    required this.hPad,
    required this.onCTA,
    required this.onAssistant,
  });

  @override
  Widget build(BuildContext context) {
    final acc = _acc(dark);
    final sub = _txts(dark);
    final title = _txt(dark);

    return Container(
      padding: EdgeInsets.only(
        left: hPad,
        right: hPad,
        top: desktop ? 78 : 60,
        bottom: desktop ? 80 : 56,
      ),
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: pulse,
                            builder: (_, _) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _surf(dark),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _bord(dark),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF10B981),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(pulse.value * 0.6),
                                          blurRadius: 7,
                                          spreadRadius: 1.2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l.t('badge'),
                                    style: _wBody(
                                      12.5,
                                      sub,
                                      w: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: _HeroText(
                              desktop: desktop,
                              dark: dark,
                              l: l,
                              align: TextAlign.left,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              l.t('hero_sub'),
                              style: _wBody(17, sub),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _GlowBtn(
                                label: l.t('get_started'),
                                icon: Icons.arrow_forward_rounded,
                                grad: [_teal, _elBlue],
                                onTap: onCTA,
                              ),
                              _OutlineBtn(
                                label: l.t('assistant_open'),
                                icon: Icons.auto_awesome_rounded,
                                accent: _accV(dark),
                                dark: dark,
                                onTap: onAssistant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Container(
                            decoration: BoxDecoration(
                              color: _surf(dark),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _bord(dark), width: 1),
                            ),
                            child: Row(
                              children: [
                                _HeroMetricTile(
                                  val: '63M+',
                                  label: l.t('stat_mute_label'),
                                  color: acc,
                                  text: title,
                                ),
                                _HeroMetricTile(
                                  val: '3',
                                  label: l.t('home_trust_indian_languages'),
                                  color: acc,
                                  text: title,
                                ),
                                _HeroMetricTile(
                                  val: 'ISL',
                                  label: l.t('home_trust_certified_signs'),
                                  color: acc,
                                  text: title,
                                ),
                                _HeroMetricTile(
                                  val: 'AI',
                                  label: l.t('home_trust_powered'),
                                  color: acc,
                                  text: title,
                                  last: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 42),
                    Expanded(
                      flex: 9,
                      child: AnimatedBuilder(
                        animation: float,
                        builder: (_, _) => Transform.translate(
                          offset: Offset(0, -float.value * 0.45),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _surf(dark),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _bord(dark), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: acc.withOpacity(dark ? 0.14 : 0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: _AIChatMockup(accent: acc, dark: dark),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _HeroText(desktop: desktop, dark: dark, l: l),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Text(
                        l.t('hero_sub'),
                        textAlign: TextAlign.center,
                        style: _wBody(15, sub),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _GlowBtn(
                          label: l.t('get_started'),
                          icon: Icons.arrow_forward_rounded,
                          grad: [_teal, _elBlue],
                          onTap: onCTA,
                        ),
                        _OutlineBtn(
                          label: l.t('assistant_open'),
                          icon: Icons.auto_awesome_rounded,
                          accent: _accV(dark),
                          dark: dark,
                          onTap: onAssistant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    _TrustStrip(dark: dark, desktop: desktop, l: l),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  final String val;
  final String label;
  final Color color;
  final Color text;
  final bool last;

  const _HeroMetricTile({
    required this.val,
    required this.label,
    required this.color,
    required this.text,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  right: BorderSide(color: color.withOpacity(0.16), width: 1),
                ),
        ),
        child: Column(
          children: [
            Text(val, style: _wHead(24, color, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: _wBody(11.5, text.withOpacity(0.62), w: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  final TextAlign align;
  const _HeroText({
    required this.desktop,
    required this.dark,
    required this.l,
    this.align = TextAlign.center,
  });
  @override
  Widget build(BuildContext context) {
    final t = _txt(dark);
    final a = _acc(dark);
    final fs = desktop ? 62.0 : 44.0;
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final t1 = l.t('hero_title_1').replaceAll('\n', ' ');
        final tH = l.t('hero_title_highlight').replaceAll('\n', ' ');
        final t2 = l.t('hero_title_2').replaceAll('\n', ' ');
        TextSpan s(double sz) => TextSpan(
          children: [
            if (t1.isNotEmpty) TextSpan(text: '$t1 ', style: _wDisp(sz, t)),
            TextSpan(text: tH, style: _wDisp(sz, a)),
            if (t2.isNotEmpty) TextSpan(text: ' $t2', style: _wDisp(sz, t)),
          ],
        );
        double sz = fs;
        for (int i = 0; i < 20; i++) {
          final tp = TextPainter(
            text: s(sz),
            textDirection: TextDirection.ltr,
            maxLines: 2,
          )..layout(maxWidth: w);
          if (!tp.didExceedMaxLines) break;
          sz -= 1;
          if (sz <= (desktop ? 38 : 28)) break;
        }
        return RichText(
          textAlign: align,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          text: s(sz),
        );
      },
    );
  }
}

class _GradientLastWordHeadline extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const _GradientLastWordHeadline({
    required this.text,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final clean = text.trim();
    final split = clean.lastIndexOf(' ');
    if (split <= 0) return Text(clean, style: style);

    final lead = clean.substring(0, split + 1);
    final tail = clean.substring(split + 1);

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: lead),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Text(tail, style: style.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  final bool dark, desktop;
  final AppLocalizations l;
  const _TrustStrip({
    required this.dark,
    required this.desktop,
    required this.l,
  });
  @override
  Widget build(BuildContext context) {
    final items = [
      ('63M+', l.t('stat_mute_label')),
      ('3', l.t('home_trust_indian_languages')),
      ('ISL', 'Certified Signs'),
      ('AI', 'Powered'),
    ];
    final a = _acc(dark);
    final m = _txtm(dark);
    final d = _bord(dark);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: _s24,
      runSpacing: _s12,
      children: items
          .asMap()
          .entries
          .map(
            (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      e.value.$1,
                      style: _h(desktop ? 20 : 16, a, w: FontWeight.w700),
                    ),
                    Text(e.value.$2, style: _lbl(11, m, w: FontWeight.w400)),
                  ],
                ),
                if (e.key < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: _s24),
                    child: Container(width: 1, height: 30, color: d),
                  ),
              ],
            ),
          )
          .toList(),
    );
  }
}
//  MARQUEE STRIP
class _MarqueeStrip extends StatefulWidget {
  final bool dark;
  const _MarqueeStrip({required this.dark});
  @override
  State<_MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<_MarqueeStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      '✦ On-Device AI',
      '✦ 3 Languages',
      '✦ ISL Certified',
      '✦ Real-Time Translation',
      '✦ Emergency SOS',
      '✦ 63M+ Users',
      '✦ ISLRTC Approved',
      '✦ Voice I/O',
      '✦ Privacy First',
    ];
    final bg = widget.dark ? _navy4 : _lSurf2;
    final bd = widget.dark ? _navyB : _lBorder;
    final a = _acc(widget.dark);
    final m = _txtm(widget.dark);

    final stripItems = [...items, ...items, ...items];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: _s24),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.symmetric(horizontal: BorderSide(color: bd, width: 1)),
      ),
      child: ClipRect(
        child: SizedBox(
          height: 24,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final offset = -_ctrl.value * 360;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: stripItems
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              s,
                              style: _lbl(
                                12,
                                s.contains('✦') ? a.withOpacity(0.70) : m,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
//  WEB STATS
class _WebStats extends StatelessWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  const _WebStats({required this.desktop, required this.dark, required this.l});
  @override
  Widget build(BuildContext context) {
    final stats = [
      ('63000000', '+', l.t('stat_mute_label'), _acc(dark), 0),
      ('8435000', '+', l.t('stat_isl_label'), dark ? _violetD : _violet, 200),
      ('250', '', l.t('stat_translators_label'), dark ? _cyanD : _cyan, 400),
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < stats.length - 1 ? _s16 : 0),
            child: _StatCard(
              value: s.$1,
              suffix: s.$2,
              label: s.$3,
              color: s.$4,
              delay: s.$5,
              dark: dark,
              desktop: desktop,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String value, suffix, label;
  final Color color;
  final int delay;
  final bool dark, desktop;
  const _StatCard({
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
    required this.delay,
    required this.dark,
    required this.desktop,
  });
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late int _target;
  bool _hov = false;
  @override
  void initState() {
    super.initState();
    _target = int.parse(widget.value);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = Tween<double>(
      begin: 0,
      end: _target.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(Duration(milliseconds: widget.delay), () {
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
  Widget build(BuildContext context) {
    final bg = _surf(widget.dark);
    final bd = _bord(widget.dark);
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _hov ? -9 : 0),
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        builder: (_, dy, child) => Transform.translate(
          offset: Offset(0, dy),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            scale: _hov ? 1.014 : 1.0,
            child: child,
          ),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => Container(
            padding: EdgeInsets.symmetric(
              vertical: widget.desktop ? 36 : 24,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bg,
                  widget.dark
                      ? _navy4.withOpacity(0.92)
                      : _lSurf2.withOpacity(0.72),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hov
                    ? widget.color.withOpacity(widget.dark ? 0.42 : 0.26)
                    : bd.withOpacity(widget.dark ? 0.88 : 0.96),
                width: _hov ? 1.4 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(
                    _hov
                        ? (widget.dark ? 0.20 : 0.15)
                        : (widget.dark ? 0.12 : 0.09),
                  ),
                  blurRadius: _hov ? 34 : 24,
                  offset: Offset(0, _hov ? 10 : 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _hov
                        ? (widget.dark ? 0.32 : 0.08)
                        : (widget.dark ? 0.26 : 0.05),
                  ),
                  blurRadius: _hov ? 30 : 20,
                  offset: Offset(0, _hov ? 18 : 12),
                ),
              ],
            ),
            child: Column(
              children: [
                // Compact accent capsule for a cleaner premium header detail.
                Container(
                  width: widget.desktop ? 92 : 74,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0.95),
                        widget.color.withOpacity(0.42),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(
                          widget.dark ? 0.28 : 0.16,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_fmt(_anim.value.toInt())}${widget.suffix}',
                  style: _h(
                    widget.desktop ? 42 : 28,
                    widget.color,
                    w: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: _s8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: _b(13, _txts(widget.dark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//  WEB FEATURES GRID
class _WebFeatures extends StatelessWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final void Function(Widget) push;
  const _WebFeatures({
    required this.desktop,
    required this.dark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
    required this.push,
  });

  @override
  Widget build(BuildContext context) {
    final feats = [
      (
        Icons.translate_rounded,
        _elBlue,
        _elBlueD,
        l.t('nav_terminal'),
        l.t('home_terminal_sub'),
        TranslateScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        ['On-device AI', 'Real-time'],
      ),
      (
        Icons.back_hand_rounded,
        _teal,
        _tealD,
        l.t('nav_signs'),
        l.t('home_signs_sub'),
        SignsPage(toggleTheme: toggleTheme, setLocale: setLocale),
        ['1000+ Signs', 'ISLRTC'],
      ),
      (
        Icons.compare_arrows_rounded,
        _emerald,
        _emeraldD,
        l.t('nav_bridge'),
        l.t('home_bridge_sub'),
        TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('bidirectional'), l.t('voice_and_signs')],
      ),
      (
        Icons.emergency_rounded,
        _red,
        _red,
        l.t('nav_emergency'),
        l.t('home_emergency_sub'),
        EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale),
        [l.t('sos_alerts'), l.t('emergency_signs')],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _acc(dark).withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _acc(dark).withOpacity(0.22),
                  width: 1,
                ),
              ),
              child: Text(
                l.t('home_features_label'),
                style: _lbl(
                  10.5,
                  _acc(dark),
                  w: FontWeight.w700,
                ).copyWith(fontFamily: _ff, letterSpacing: 1.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: _s14),
        _GradientLastWordHeadline(
          text: l.t('home_features_title'),
          style: _wHead(desktop ? 38 : 28, _txt(dark), w: FontWeight.w800),
          gradient: const LinearGradient(
            colors: [_cyan, _elBlue, _violet],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: _s8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            l.t('home_features_sub'),
            style: _wBody(15.5, _txts(dark)),
          ),
        ),
        SizedBox(height: desktop ? 48 : 36),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: desktop ? 2 : 1,
          mainAxisSpacing: desktop ? 18 : _s14,
          crossAxisSpacing: desktop ? 18 : _s14,
          childAspectRatio: desktop ? 1.96 : 2.7,
          children: feats.map((f) {
            final a = dark ? f.$3 : f.$2;
            return _WebFeatCard(
              icon: f.$1,
              accent: a,
              title: f.$4,
              desc: f.$5,
              tags: f.$7,
              page: f.$6,
              dark: dark,
              push: push,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WebFeatCard extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String title, desc;
  final List<String> tags;
  final Widget page;
  final bool dark;
  final void Function(Widget) push;
  const _WebFeatCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.tags,
    required this.page,
    required this.dark,
    required this.push,
  });
  @override
  State<_WebFeatCard> createState() => _WebFeatCardState();
}

class _WebFeatCardState extends State<_WebFeatCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final t = _txt(widget.dark);
    final s = _txts(widget.dark);
    final bd = _bord(widget.dark);
    const cardRadius = 36.0;
    final glow = widget.accent.withOpacity(widget.dark ? 0.15 : 0.10);
    final panelGradient = widget.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF111B31),
              Color.lerp(const Color(0xFF111B31), widget.accent, 0.10)!,
              const Color(0xFF0C1528),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFFFF),
              Color.lerp(const Color(0xFFF7FAFF), widget.accent, 0.07)!,
              const Color(0xFFF1F6FF),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.push(widget.page),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _hov ? -9 : 0),
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          builder: (_, dy, child) => Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              scale: _hov ? 1.012 : 1.0,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: panelGradient,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: _hov
                    ? widget.accent.withOpacity(widget.dark ? 0.34 : 0.24)
                    : bd.withOpacity(widget.dark ? 0.96 : 0.90),
                width: _hov ? 1.35 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hov
                      ? widget.accent.withOpacity(widget.dark ? 0.21 : 0.14)
                      : Colors.black.withOpacity(widget.dark ? 0.16 : 0.07),
                  blurRadius: _hov ? 34 : 20,
                  offset: Offset(0, _hov ? 16 : 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(widget.dark ? 0.17 : 0.04),
                  blurRadius: _hov ? 26 : 16,
                  offset: Offset(0, _hov ? 14 : 9),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(widget.dark ? 0.04 : 0.09),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -18,
                  top: -22,
                  child: Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [glow, Colors.transparent],
                        stops: const [0.0, 0.78],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  bottom: 14,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 4.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.accent.withOpacity(0.98),
                          widget.accent.withOpacity(0.46),
                          widget.accent.withOpacity(0.12),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.accent.withOpacity(_hov ? 0.26 : 0.19),
                              widget.accent.withOpacity(_hov ? 0.12 : 0.07),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: widget.accent.withOpacity(
                              _hov ? 0.42 : 0.24,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(
                                _hov ? 0.20 : 0.10,
                              ),
                              blurRadius: _hov ? 18 : 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: _wHead(19, t, w: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.desc,
                              style: _wBody(12.8, s),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: widget.tags
                                  .map(
                                    (tg) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.accent.withOpacity(
                                          widget.dark ? 0.15 : 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: widget.accent.withOpacity(
                                            widget.dark ? 0.32 : 0.24,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        tg,
                                        style: _lbl(
                                          11.1,
                                          widget.accent,
                                          w: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedOpacity(
                        opacity: _hov ? 1.0 : 0.88,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.accent.withOpacity(_hov ? 0.26 : 0.16),
                                widget.accent.withOpacity(_hov ? 0.14 : 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: widget.accent.withOpacity(
                                _hov ? 0.36 : 0.20,
                              ),
                              width: 1,
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//  WEB AI BANNER
class _WebAIBanner extends StatefulWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  final Animation<double> float;
  final VoidCallback onTap;
  const _WebAIBanner({
    required this.desktop,
    required this.dark,
    required this.l,
    required this.float,
    required this.onTap,
  });
  @override
  State<_WebAIBanner> createState() => _WebAIBannerState();
}

class _WebAIBannerState extends State<_WebAIBanner> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.dark ? _violetD : _violet;
    final t = _txt(widget.dark);
    final s = _txts(widget.dark);
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _hov ? -10 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (_, dy, child) => Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: _hov ? 1.012 : 1.0,
              child: child,
            ),
          ),
          child: widget.desktop
              ? _bannerDesktop(widget.l, a)
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.dark
                          ? [
                              const Color(0xFF0F1B33),
                              const Color(0xFF111E38),
                              const Color(0xFF0D172B),
                            ]
                          : [
                              const Color(0xFFFFFFFF),
                              const Color(0xFFF6F9FF),
                              const Color(0xFFEEF4FF),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _hov ? a.withOpacity(0.32) : a.withOpacity(0.16),
                      width: _hov ? 1.25 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: a.withOpacity(_hov ? 0.18 : 0.04),
                        blurRadius: _hov ? 38 : 18,
                        offset: Offset(0, _hov ? 14 : 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          widget.dark
                              ? (_hov ? 0.22 : 0.16)
                              : (_hov ? 0.08 : 0.04),
                        ),
                        blurRadius: _hov ? 44 : 24,
                        offset: Offset(0, _hov ? 20 : 16),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _bannerMobile(widget.l, a, t, s),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bannerDesktop(AppLocalizations l, Color a) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _AssistantFeatureCard(
          dark: widget.dark,
          accent: a,
          l: l,
          onTap: widget.onTap,
        ),
      ),
      const SizedBox(width: _s24),
      Expanded(
        child: AnimatedBuilder(
          animation: widget.float,
          builder: (_, _) => Transform.translate(
            offset: Offset(0, -widget.float.value * 0.5),
            child: _ISLAssistantWorkflowCard(accent: a, dark: widget.dark),
          ),
        ),
      ),
    ],
  );

  Widget _bannerMobile(AppLocalizations l, Color a, Color t, Color s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [a, _cyan.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: a.withOpacity(0.30),
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
          const SizedBox(width: _s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.t('assistant_title'), style: _h(20, t)),
                Text(
                  l.t('ten_languages'),
                  style: _lbl(12, a, w: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: _s16),
      Text(l.t('assistant_banner_desc'), style: _b(14, s)),
      const SizedBox(height: _s20),
      _GlowBtn(
        label: l.t('assistant_open'),
        icon: Icons.arrow_forward_rounded,
        grad: [a, _cyan.withOpacity(0.7)],
        onTap: widget.onTap,
      ),
    ],
  );
}

class _AIChatMockup extends StatelessWidget {
  final Color accent;
  final bool dark;
  const _AIChatMockup({required this.accent, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final txt = _txt(dark);
    final sub = _txts(dark);
    final panel = dark ? const Color(0xFF1B2740) : const Color(0xFFF7F9FF);
    final line = dark ? _navyB : const Color(0xFFDCE4F4);
    final bubble = dark ? _navy5 : const Color(0xFFEDF1F8);

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Row(
                  children: const [
                    _DotDot(Color(0xFFFF5F57)),
                    SizedBox(width: 6),
                    _DotDot(Color(0xFFFEBB2E)),
                    SizedBox(width: 6),
                    _DotDot(Color(0xFF22C55E)),
                  ],
                ),
                const Spacer(),
                Text(
                  l.t('terminal_title'),
                  style: _lbl(13, _txt(dark), w: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF06B6D4,
                    ).withOpacity(dark ? 0.24 : 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(
                        0xFF06B6D4,
                      ).withOpacity(dark ? 0.42 : 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l.t('accessibility_live'),
                    style: _lbl(
                      11.5,
                      const Color(0xFF0891B2),
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: line),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final body = Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiBadge(dark: dark, label: l.t('terminal_actor_user_short')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: bubble,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: line, width: 1),
                            ),
                            child: Text(
                              l.t('terminal_user_signs_help'),
                              style: _wBody(12.4, txt, w: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiBadge(dark: dark, label: l.t('terminal_actor_ai_short')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: bubble,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: line, width: 1),
                            ),
                            child: Text(
                              l.t('terminal_ai_conversion_confidence'),
                              style: _wBody(12.4, txt, w: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? _navy4 : const Color(0xFFE9EEF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line, width: 1),
                        ),
                        child: Text(
                          l.t('terminal_hearing_reply_back'),
                          style: _wBody(12.1, txt, w: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, thickness: 1, color: line),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FlowChip(
                          icon: Icons.front_hand_rounded,
                          label: l.t('sign_capture'),
                        ),
                        _FlowChip(
                          icon: Icons.text_fields_rounded,
                          label: l.t('text_output'),
                        ),
                        _FlowChip(
                          icon: Icons.volume_up_rounded,
                          label: l.t('voice_output'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.t('live_terminal_events'),
                        style: _lbl(10.8, sub, w: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 128,
                      child: _MockTerminalAutoScroll(dark: dark),
                    ),
                  ],
                );

                if (!constraints.hasBoundedHeight) {
                  return body;
                }

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: body,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ISLAssistantWorkflowCard extends StatelessWidget {
  final Color accent;
  final bool dark;
  const _ISLAssistantWorkflowCard({required this.accent, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final txt = _txt(dark);
    final sub = _txts(dark);
    final panel = dark ? const Color(0xFF1B2740) : const Color(0xFFF7F9FF);
    final line = dark ? _navyB : const Color(0xFFDCE4F4);
    final bubble = dark ? _navy5 : const Color(0xFFEDF1F8);

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Row(
                  children: const [
                    _DotDot(Color(0xFFFF5F57)),
                    SizedBox(width: 6),
                    _DotDot(Color(0xFFFEBB2E)),
                    SizedBox(width: 6),
                    _DotDot(Color(0xFF22C55E)),
                  ],
                ),
                const Spacer(),
                Text(
                  l.t('workflow_title'),
                  style: _lbl(13, _txt(dark), w: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF06B6D4,
                    ).withOpacity(dark ? 0.24 : 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(
                        0xFF06B6D4,
                      ).withOpacity(dark ? 0.42 : 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l.t('workflow_live'),
                    style: _lbl(
                      11.5,
                      const Color(0xFF0891B2),
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: line),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final body = Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiBadge(dark: dark, label: l.t('terminal_actor_user_short')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: bubble,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: line, width: 1),
                            ),
                            child: Text(
                              l.t('workflow_user_signs_emergency'),
                              style: _wBody(12.4, txt, w: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiBadge(dark: dark, label: l.t('terminal_actor_ai_short')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: bubble,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: line, width: 1),
                            ),
                            child: Text(
                              l.t('workflow_ai_realtime_output'),
                              style: _wBody(12.4, txt, w: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? _navy4 : const Color(0xFFE9EEF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line, width: 1),
                        ),
                        child: Text(
                          l.t('workflow_response_guidance'),
                          style: _wBody(12.1, txt, w: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, thickness: 1, color: line),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FlowChip(
                          icon: Icons.front_hand_rounded,
                          label: l.t('sign_input'),
                        ),
                        _FlowChip(
                          icon: Icons.memory_rounded,
                          label: l.t('ai_process'),
                        ),
                        _FlowChip(
                          icon: Icons.volume_up_rounded,
                          label: l.t('voice_text_out'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.t('workflow_events'),
                        style: _lbl(10.8, sub, w: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 128,
                      child: _MockTerminalAutoScroll(dark: dark),
                    ),
                  ],
                );

                if (!constraints.hasBoundedHeight) {
                  return body;
                }

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: body,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantFeatureCard extends StatefulWidget {
  final bool dark;
  final Color accent;
  final AppLocalizations l;
  final VoidCallback onTap;

  const _AssistantFeatureCard({
    required this.dark,
    required this.accent,
    required this.l,
    required this.onTap,
  });

  @override
  State<_AssistantFeatureCard> createState() => _AssistantFeatureCardState();
}

class _AssistantFeatureCardState extends State<_AssistantFeatureCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final t = _txt(widget.dark);
    final s = _txts(widget.dark);
    final bd = _bord(widget.dark);
    const cardRadius = 30.0;
    final glow = widget.accent.withOpacity(widget.dark ? 0.15 : 0.10);
    final panelGradient = widget.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF111B31),
              Color.lerp(const Color(0xFF111B31), widget.accent, 0.10)!,
              const Color(0xFF0C1528),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFFFF),
              Color.lerp(const Color(0xFFF7FAFF), widget.accent, 0.07)!,
              const Color(0xFFF1F6FF),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _hov ? -9 : 0),
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          builder: (_, dy, child) => Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              scale: _hov ? 1.012 : 1.0,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: const BoxConstraints(minHeight: 194, maxHeight: 202),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: panelGradient,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: _hov
                    ? widget.accent.withOpacity(widget.dark ? 0.34 : 0.24)
                    : bd.withOpacity(widget.dark ? 0.96 : 0.90),
                width: _hov ? 1.35 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hov
                      ? widget.accent.withOpacity(widget.dark ? 0.21 : 0.14)
                      : Colors.black.withOpacity(widget.dark ? 0.16 : 0.07),
                  blurRadius: _hov ? 34 : 20,
                  offset: Offset(0, _hov ? 16 : 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(widget.dark ? 0.17 : 0.04),
                  blurRadius: _hov ? 26 : 16,
                  offset: Offset(0, _hov ? 14 : 9),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient vignette effect from top
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          widget.accent.withOpacity(widget.dark ? 0.08 : 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Gradient vignette effect from bottom
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(widget.dark ? 0.08 : 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
                // Animated glow circle
                Positioned(
                  right: _hov ? -8 : -12,
                  top: _hov ? -8 : -12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _hov ? 116 : 104,
                    height: _hov ? 116 : 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glow.withOpacity(_hov ? 0.24 : 0.16),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.78],
                      ),
                    ),
                  ),
                ),
                // Left accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(cardRadius),
                        bottomLeft: Radius.circular(cardRadius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.accent.withOpacity(0.98),
                          widget.accent.withOpacity(_hov ? 0.48 : 0.34),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(_hov ? 0.28 : 0.18),
                          blurRadius: _hov ? 20 : 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Row
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.accent.withOpacity(
                                        _hov ? 0.20 : 0.14,
                                      ),
                                      widget.accent.withOpacity(
                                        _hov ? 0.08 : 0.03,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: widget.accent.withOpacity(
                                      _hov ? 0.32 : 0.18,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.sign_language_rounded,
                                  color: widget.accent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.l.t('assistant_title'),
                                      style: _wHead(17, t, w: FontWeight.w800)
                                          .copyWith(
                                            height: 1.08,
                                            letterSpacing: -0.06,
                                            wordSpacing: 2.0,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.l.t('assistant_feature_sub'),
                                      style: _wBody(12.7, s, w: FontWeight.w500)
                                          .copyWith(
                                            height: 1.30,
                                            letterSpacing: -0.04,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Tags Row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _AssistantMiniTag(
                                      label: widget.l.t('ten_languages'),
                                    ),
                                    _AssistantMiniTag(
                                      label: widget.l.t('voice_and_signs'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedOpacity(
                                opacity: _hov ? 1.0 : 0.82,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.accent.withOpacity(
                                          _hov ? 0.18 : 0.10,
                                        ),
                                        widget.accent.withOpacity(
                                          _hov ? 0.08 : 0.03,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: widget.accent.withOpacity(
                                        _hov ? 0.28 : 0.16,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: widget.accent,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _DotDot extends StatelessWidget {
  final Color color;
  const _DotDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AiBadge extends StatelessWidget {
  final bool dark;
  final String label;
  const _AiBadge({required this.dark, required this.label});

  @override
  Widget build(BuildContext context) {
    final a = dark ? _cyanD : _cyan;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: a.withOpacity(0.20),
        shape: BoxShape.circle,
        border: Border.all(color: a.withOpacity(0.35), width: 1),
      ),
      child: Center(
        child: Text(label, style: _lbl(10.5, a, w: FontWeight.w800)),
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FlowChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final a = d ? _cyanD : _cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: a.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: a.withOpacity(0.24), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: a),
          const SizedBox(width: 5),
          Text(label, style: _lbl(10.5, a, w: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MockTerminalAutoScroll extends StatefulWidget {
  final bool dark;
  const _MockTerminalAutoScroll({required this.dark});

  @override
  State<_MockTerminalAutoScroll> createState() =>
      _MockTerminalAutoScrollState();
}

class _MockTerminalAutoScrollState extends State<_MockTerminalAutoScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const loop = 186.0;
    final tickerContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MockTerminalBlock(dark: widget.dark),
        const SizedBox(height: 12),
        _MockTerminalBlock(dark: widget.dark),
      ],
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -_ctrl.value * loop),
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: tickerContent,
          ),
        ),
      ),
    );
  }
}

class _MockTerminalBlock extends StatelessWidget {
  final bool dark;
  const _MockTerminalBlock({required this.dark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = _txts(dark);
    final line = dark ? _navyB : const Color(0xFFDCE4F4);
    final codeBg = dark ? const Color(0xFF11243A) : const Color(0xFFEFF4FB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line, width: 1),
      ),
      child: Text(
        [
          l.t('terminal_log_frame_help'),
          l.t('terminal_log_vision_stable'),
          l.t('terminal_log_classifier_conf'),
          l.t('terminal_log_translate_help'),
          l.t('terminal_log_tts_hearing'),
          l.t('terminal_log_bridge_synced'),
          l.t('terminal_log_privacy_active'),
        ].join('\n'),
        style: _lbl(
          11.2,
          dark ? const Color(0xFF7DD3FC) : const Color(0xFF0F766E),
          w: FontWeight.w600,
        ).copyWith(height: 1.5, fontFamily: 'Plus Jakarta Sans'),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accent.withOpacity(0.25), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.front_hand_rounded, size: 10, color: accent),
        const SizedBox(width: 4),
        Text(label, style: _lbl(10, accent, w: FontWeight.w700)),
      ],
    ),
  );
}
//  WEB OBJECTIVES GRID
class _WebObjectives extends StatelessWidget {
  final bool desktop, dark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _WebObjectives({
    required this.desktop,
    required this.dark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext context) {
    final cards = _objCards(l, toggleTheme, setLocale);
    final accents = [
      [_elBlue, _elBlueD],
      [_teal, _tealD],
      [_emerald, _emeraldD],
      [_cyan, _cyanD],
      [_amber, _amberD],
      [_violet, _violetD],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _acc(dark).withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _acc(dark).withOpacity(0.22),
                  width: 1,
                ),
              ),
              child: Text(
                'OUR MISSION',
                style: _wKicker(10.5, _acc(dark), w: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: _s14),
        _GradientLastWordHeadline(
          text: l.t('obj_heading'),
          style: _wHead(desktop ? 38 : 28, _txt(dark), w: FontWeight.w800),
          gradient: const LinearGradient(
            colors: [_cyan, _elBlue, _violet],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: _s8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(l.t('obj_sub'), style: _wBody(15.5, _txts(dark))),
        ),
        SizedBox(height: desktop ? 48 : 36),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: desktop ? 3 : 2,
          mainAxisSpacing: desktop ? 16 : _s12,
          crossAxisSpacing: desktop ? 16 : _s12,
          childAspectRatio: desktop ? 1.45 : 1.24,
          children: cards.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            final a = dark ? accents[i][1] : accents[i][0];
            return _WebObjCard(
              icon: c.$2,
              title: c.$3,
              desc: c.$4,
              accent: a,
              page: c.$5,
              dark: dark,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WebObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool dark;
  const _WebObjCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
    required this.page,
    required this.dark,
  });
  @override
  State<_WebObjCard> createState() => _WebObjCardState();
}

class _WebObjCardState extends State<_WebObjCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final bg = _surf(widget.dark);
    final t = _txt(widget.dark);
    final s = _txts(widget.dark);
    final bd = _bord(widget.dark);
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => widget.page,
            transitionsBuilder: (_, a, _, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 240),
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _hov ? -8 : 0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (_, dy, child) => Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              scale: _hov ? 1.012 : 1.0,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(_s20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hov ? widget.accent.withOpacity(0.40) : bd,
                width: _hov ? 1.35 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hov
                      ? widget.accent.withOpacity(widget.dark ? 0.14 : 0.11)
                      : Colors.black.withOpacity(widget.dark ? 0.11 : 0.03),
                  blurRadius: _hov ? 28 : 14,
                  offset: Offset(0, _hov ? 12 : 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        widget.accent.withOpacity(0.92),
                        widget.accent.withOpacity(0.30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _s12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(_hov ? 0.14 : 0.09),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: widget.accent.withOpacity(_hov ? 0.28 : 0.20),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, color: widget.accent, size: 18),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hov ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: widget.accent.withOpacity(_hov ? 0.15 : 0.09),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: widget.accent.withOpacity(
                              _hov ? 0.25 : 0.17,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: widget.accent,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _s14),
                Text(widget.title, style: _wHead(18, t, w: FontWeight.w800)),
                const SizedBox(height: _s6),
                Text(
                  widget.desc,
                  style: _wBody(12.8, s),
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
//  WEB VISION
class _WebVision extends StatelessWidget {
  final bool dark;
  final AppLocalizations l;
  const _WebVision({required this.dark, required this.l});
  @override
  Widget build(BuildContext context) {
    final a = _acc(dark);
    final t = _txt(dark);
    final s = _txts(dark);
    return LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 980;

        final shellGradient = dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E182B), Color(0xFF111F36)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
              );

        final sideGradient = dark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  a.withOpacity(0.16),
                  const Color(0xFF1A2740),
                  const Color(0xFF0F1A30),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  a.withOpacity(0.09),
                  const Color(0xFFF7FAFF),
                  const Color(0xFFEFF4FF),
                ],
              );

        final trustChips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VisionChip(
              dark: dark,
              accent: a,
              icon: Icons.groups_rounded,
              text: l.t('home_trust_deaf_community'),
            ),
            _VisionChip(
              dark: dark,
              accent: a,
              icon: Icons.language_rounded,
              text: l.t('home_trust_indian_languages'),
            ),
            _VisionChip(
              dark: dark,
              accent: a,
              icon: Icons.verified_rounded,
              text: l.t('home_trust_certified_signs'),
            ),
            _VisionChip(
              dark: dark,
              accent: a,
              icon: Icons.bolt_rounded,
              text: l.t('home_trust_powered'),
            ),
          ],
        );

        final titleStyle = _wHead(compact ? 30 : 36, t, w: FontWeight.w800);
        final titleGradient = const LinearGradient(
          colors: [_cyan, _elBlue, _violet],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

        Widget buildVisionTitle() {
          final title = l.t('vision_title');
          final lower = title.toLowerCase();
          const key = 'vani ai';
          final idx = lower.indexOf(key);
          if (idx < 0) {
            return _GradientLastWordHeadline(
              text: title,
              style: titleStyle,
              gradient: titleGradient,
            );
          }

          final lead = title.substring(0, idx);
          final hit = title.substring(idx, idx + key.length);
          final tail = title.substring(idx + key.length);

          return RichText(
            text: TextSpan(
              style: titleStyle,
              children: [
                if (lead.isNotEmpty) TextSpan(text: lead),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ShaderMask(
                    shaderCallback: (bounds) => titleGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      hit,
                      style: titleStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (tail.isNotEmpty) TextSpan(text: tail),
              ],
            ),
          );
        }

        final crisisTag = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? [
                      _red.withOpacity(0.18),
                      const Color(0xFF451C26).withOpacity(0.24),
                    ]
                  : [const Color(0xFFFFEEF0), const Color(0xFFFFF7F8)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _red.withOpacity(dark ? 0.32 : 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: dark ? _redD : _red,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                l.t('obj_crisis_stat'),
                style: _lbl(12.6, dark ? _redD : _red, w: FontWeight.w700),
              ),
            ],
          ),
        );

        final leftContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: a.withOpacity(dark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: a.withOpacity(dark ? 0.26 : 0.18),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph_rounded, color: a, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    l.t('home_mission_label'),
                    style: _lbl(
                      11.2,
                      a,
                      w: FontWeight.w700,
                    ).copyWith(letterSpacing: 0.9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            buildVisionTitle(),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 760 : 700),
              child: Text(l.t('vision_body'), style: _wBody(14.1, s)),
            ),
            const SizedBox(height: 14),
            trustChips,
            const SizedBox(height: 14),
            crisisTag,
          ],
        );

        return Container(
          padding: EdgeInsets.all(compact ? 24 : 28),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: shellGradient,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _bord(dark).withOpacity(dark ? 0.95 : 0.90),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: a.withOpacity(dark ? 0.11 : 0.09),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.24 : 0.05),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: compact
              ? leftContent
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftContent),
                    const SizedBox(width: 18),
                    Container(
                      width: 248,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: sideGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: a.withOpacity(dark ? 0.24 : 0.18),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: a.withOpacity(dark ? 0.20 : 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: a,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Accessibility Index',
                                  style: _lbl(12, t, w: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '1 : 33,000+',
                            style: _wHead(
                              30,
                              dark ? _redD : _red,
                              w: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Translator coverage today',
                            style: _lbl(11.5, s, w: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _bordS(dark),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0.22,
                              alignment: Alignment.centerLeft,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [a, _cyan.withOpacity(0.85)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.t('obj_crisis_stat'),
                            style: _lbl(11.2, s, w: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _VisionChip extends StatelessWidget {
  final bool dark;
  final Color accent;
  final IconData icon;
  final String text;
  const _VisionChip({
    required this.dark,
    required this.accent,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(dark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withOpacity(dark ? 0.24 : 0.16),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(text, style: _lbl(12, accent, w: FontWeight.w600)),
        ],
      ),
    );
  }
}
//  WEB FOOTER
class _WebFooter extends StatelessWidget {
  final bool dark;
  final AppLocalizations l;
  final VoidCallback onBackToTop;
  const _WebFooter({
    required this.dark,
    required this.l,
    required this.onBackToTop,
  });
  @override
  Widget build(BuildContext context) {
    final t = _txt(dark);
    final m = _txtm(dark);
    final d = _bordS(dark);
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                d.withOpacity(0.85),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'VANI',
                    style: _lbl(
                      20,
                      t,
                      w: FontWeight.w800,
                    ).copyWith(letterSpacing: 1.7),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.t('home_footer_project_line'),
                    textAlign: TextAlign.center,
                    style: _b(13, m),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.t('home_footer_stack_line'),
                    textAlign: TextAlign.center,
                    style: _lbl(12, m, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FooterNavLink(
                      label: l.t('home_back_to_top'),
                      dark: dark,
                      onTap: onBackToTop,
                    ),
                    const SizedBox(width: 26),
                    Text(
                      l.t('home_footer_built_for_india'),
                      style: _lbl(13, _txts(dark), w: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterNavLink extends StatefulWidget {
  final String label;
  final bool dark;
  final VoidCallback onTap;
  const _FooterNavLink({
    required this.label,
    required this.dark,
    required this.onTap,
  });

  @override
  State<_FooterNavLink> createState() => _FooterNavLinkState();
}

class _FooterNavLinkState extends State<_FooterNavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = _txts(widget.dark);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 140),
          style: _lbl(
            13,
            _hover ? _acc(widget.dark) : c,
            w: _hover ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
//  CTA BUTTONS
class _GlowBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> grad;
  final VoidCallback onTap;
  const _GlowBtn({
    required this.label,
    required this.icon,
    required this.grad,
    required this.onTap,
  });
  @override
  State<_GlowBtn> createState() => _GlowBtnState();
}

class _GlowBtnState extends State<_GlowBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: widget.grad.first.withOpacity(_hov ? 0.50 : 0.30),
              blurRadius: _hov ? 22 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: _lbl(14.5, Colors.white, w: FontWeight.w700),
            ),
            const SizedBox(width: _s8),
            Icon(widget.icon, color: Colors.white, size: 16),
          ],
        ),
      ),
    ),
  );
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool dark;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.accent,
    required this.dark,
    required this.onTap,
  });
  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final bg = _surf(widget.dark);
    final bd = _bord(widget.dark);
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _hov ? widget.accent.withOpacity(0.08) : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hov ? widget.accent.withOpacity(0.42) : bd,
              width: _hov ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.accent, size: 16),
              const SizedBox(width: _s8),
              Text(
                widget.label,
                style: _lbl(14.5, widget.accent, w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//  MOBILE COMPONENTS
class _FinTechTabBar extends StatelessWidget {
  final bool isDark;
  final int tab;
  final ValueChanged<int> onTap;
  final AppLocalizations l;
  const _FinTechTabBar({
    required this.isDark,
    required this.tab,
    required this.onTap,
    required this.l,
  });
  @override
  Widget build(BuildContext context) {
    final bg = _surf(isDark);
    final bd = _bord(isDark);
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
        Icons.auto_awesome_outlined,
        Icons.auto_awesome_rounded,
        l.t('assistant_tab_label'),
      ),
    ];
    final accents = [_acc(isDark), _acc(isDark), _tealD, _emeraldD, _violetD];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: bd, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final it = e.value;
              final active = tab == i;
              final ca = isDark ? accents[i] : accents[i];
              final col = active ? ca : _txtm(isDark);
              return Expanded(
                child: Semantics(
                  label: it.$3,
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
                          width: active ? 28 : 0,
                          decoration: BoxDecoration(
                            gradient: active
                                ? LinearGradient(colors: [ca, _cyan])
                                : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: _s4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            active ? it.$2 : it.$1,
                            key: ValueKey(active),
                            size: 22,
                            color: col,
                          ),
                        ),
                        const SizedBox(height: _s4),
                        Text(
                          it.$3,
                          overflow: TextOverflow.ellipsis,
                          style: _lbl(
                            active ? 10.5 : 10,
                            col,
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

class _MobileHomeFeed extends StatelessWidget {
  final bool isDark;
  final Animation<double> fade, pulse, shim;
  final Animation<Offset> slide;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobileHomeFeed({
    required this.isDark,
    required this.fade,
    required this.slide,
    required this.pulse,
    required this.shim,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // bg orbs
        Positioned(
          top: -80,
          left: -80,
          child: _Orb(
            color: _elBlue.withOpacity(isDark ? 0.10 : 0.06),
            size: 280,
          ),
        ),
        Positioned(
          top: 200,
          right: -60,
          child: _Orb(
            color: _violet.withOpacity(isDark ? 0.08 : 0.05),
            size: 220,
          ),
        ),
        // grid
        Positioned.fill(
          child: CustomPaint(
            painter: _DotGridPainter(
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : _elBlue.withOpacity(0.03),
            ),
          ),
        ),
        // arcs
        Positioned(
          top: 0,
          left: 0,
          child: _ArcDecor(
            size: 200,
            color: _elBlue,
            dark: isDark,
            flip: false,
          ),
        ),
        Positioned(
          top: 164,
          right: -42,
          child: _BorderCircle(
            size: 108,
            color: _cyan,
            dark: isDark,
            stroke: 1.0,
          ),
        ),
        Positioned(
          bottom: 120,
          left: -22,
          child: _BorderCircle(
            size: 84,
            color: _violet,
            dark: isDark,
            stroke: 0.9,
          ),
        ),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MobTopBar(
                isDark: isDark,
                l: l,
                pulse: pulse,
                toggleTheme: toggleTheme,
                setLocale: setLocale,
              ),

              // Hero
              FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _MobHeroCard(
                      isDark: isDark,
                      l: l,
                      toggleTheme: toggleTheme,
                      setLocale: setLocale,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: _s24),

              // Stats strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MobStatsStrip(isDark: isDark, l: l),
              ),

              const SizedBox(height: _s32),

              // Marquee-style feature chips
              _MobFeatureMarquee(isDark: isDark),

              const SizedBox(height: _s32),

              // Quick actions
              _MobSectionHeader(
                text: l.t('home_quick_access'),
                isDark: isDark,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              ),
              _MobQuickAccess(
                isDark: isDark,
                l: l,
                toggleTheme: toggleTheme,
                setLocale: setLocale,
              ),

              const SizedBox(height: _s32),

              // AI Card
              _MobSectionHeader(
                text: l.t('assistant_title'),
                isDark: isDark,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MobAICard(
                  isDark: isDark,
                  toggleTheme: toggleTheme,
                  setLocale: setLocale,
                ),
              ),

              const SizedBox(height: _s32),

              // Objectives
              _MobSectionHeader(
                text: l.t('obj_heading'),
                isDark: isDark,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
              _MobObjScroll(
                isDark: isDark,
                l: l,
                toggleTheme: toggleTheme,
                setLocale: setLocale,
              ),

              const SizedBox(height: _s32),

              // Mission
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MobMissionCard(isDark: isDark, l: l),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobTopBar extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobTopBar({
    required this.isDark,
    required this.l,
    required this.pulse,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext context) {
    final t = _txt(isDark);
    final m = _txtm(isDark);
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'VANI',
                    style: _h(
                      19,
                      t,
                      w: FontWeight.w800,
                    ).copyWith(letterSpacing: 1.6),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, _) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22C55E),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withOpacity(pulse.value * 0.60),
                            blurRadius: 6,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Text(l.t('home_tagline'), style: _lbl(10.5, m)),
            ],
          ),
          const Spacer(),
          _MobLangMenuBtn(isDark: isDark, locale: locale, setLocale: setLocale),
          const SizedBox(width: 8),
          _MobThemeBtn(isDark: isDark, onTap: toggleTheme),
          const SizedBox(width: 8),
          _MobMenuBtn(isDark: isDark),
        ],
      ),
    );
  }
}

class _MobLangMenuBtn extends StatelessWidget {
  final bool isDark;
  final Locale locale;
  final Function(Locale) setLocale;
  const _MobLangMenuBtn({
    required this.isDark,
    required this.locale,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧', 'name': 'EN'},
      {'code': 'hi', 'flag': '🇮🇳', 'name': 'हि'},
      {'code': 'mr', 'flag': '🇮🇳', 'name': 'म'},
    ];
    final cur = langs.firstWhere(
      (l) => l['code'] == locale.languageCode,
      orElse: () => langs[0],
    );
    final a = _acc(isDark);
    final bd = _bord(isDark);
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: bd, width: 1),
      ),
      color: _surf(isDark),
      onSelected: (code) => setLocale(Locale(code)),
      itemBuilder: (_) => langs
          .map(
            (lang) => PopupMenuItem<String>(
              value: lang['code'],
              height: 44,
              child: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    lang['name']!,
                    style: _lbl(
                      13,
                      lang['code'] == locale.languageCode ? a : _txt(isDark),
                      w: lang['code'] == locale.languageCode
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (lang['code'] == locale.languageCode) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: a, size: 14),
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
          color: a.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: a.withOpacity(0.25), width: 1),
        ),
        child: Center(
          child: Text(cur['flag']!, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _MobThemeBtn extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _MobThemeBtn({required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _surf2(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bord(isDark), width: 1),
      ),
      child: Icon(
        isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
        size: 18,
        color: _txtm(isDark),
      ),
    ),
  );
}

class _MobMenuBtn extends StatelessWidget {
  final bool isDark;
  const _MobMenuBtn({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sub = _txts(isDark);
    final red = _red;
    final bg = _surf(isDark);
    final bd = _bord(isDark);
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: bd, width: 1),
      ),
      color: bg,
      icon: Icon(Icons.more_vert_rounded, color: _txtm(isDark), size: 20),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: red, size: 18),
              const SizedBox(width: 12),
              Text(
                l.t('menu_sign_out'),
                style: _b(14, red, w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v != 'logout') return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              l.t('menu_sign_out_confirm_title'),
              style: _h(17, _txt(isDark)),
            ),
            content: Text(
              l.t('menu_sign_out_confirm_body'),
              style: _b(14, sub),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l.t('menu_cancel'),
                  style: _b(14, sub, w: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final b = Hive.box<EmergencyContact>('emergency_contacts');
                    await b.clear();
                  } catch (_) {}
                },
                child: Text(
                  l.t('menu_sign_out'),
                  style: _b(14, red, w: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobHeroCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobHeroCard({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_s24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C162B), Color(0xFF13274A)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2F6BFF), Color(0xFF1748C8)],
              ),
        border: Border.all(
          color: isDark ? _navyB : Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _elBlue.withOpacity(isDark ? 0.20 : 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle arc keeps depth while maintaining a clean minimalist look.
          Positioned(
            right: -20,
            top: -20,
            child: _ArcDecor(
              size: 106,
              color: Colors.white,
              dark: true,
              flip: true,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.t('home_mobile_badge'),
                      style: _lbl(11, Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _s16),
              Text(l.t('hero_title_line1'), style: _disp(26, Colors.white)),
              Text(
                l.t('hero_title_line2'),
                style: _disp(26, Colors.white.withOpacity(0.80)),
              ),
              const SizedBox(height: _s10),
              Text(
                l.t('hero_sub'),
                style: _b(13.5, Colors.white.withOpacity(0.79)),
              ),
              const SizedBox(height: _s24),
              // Mini stats row
              Row(
                children: [
                  _MobHeroStat('63M+', 'Deaf Users'),
                  const SizedBox(width: _s20),
                  _MobHeroStat('3', 'Languages'),
                  const SizedBox(width: _s20),
                  _MobHeroStat('AI', 'Powered'),
                ],
              ),
              const SizedBox(height: _s20),
              // CTA
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => TranslateScreen(
                      toggleTheme: toggleTheme,
                      setLocale: setLocale,
                    ),
                    transitionsBuilder: (_, a, _, c) =>
                        FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 260),
                  ),
                ),
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.t('get_started'),
                        style: _lbl(15, _elBlue, w: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: _elBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobHeroStat extends StatelessWidget {
  final String val, lab;
  const _MobHeroStat(this.val, this.lab);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: _h(18, Colors.white, w: FontWeight.w800)),
      Text(lab, style: _lbl(10, Colors.white.withOpacity(0.65))),
    ],
  );
}

class _MobStatsStrip extends StatefulWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobStatsStrip({required this.isDark, required this.l});
  @override
  State<_MobStatsStrip> createState() => _MobStatsStripState();
}

class _MobStatsStripState extends State<_MobStatsStrip>
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

  String _f(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(0)}M'
      : n >= 1000
      ? '${(n / 1000).toStringAsFixed(0)}K'
      : '$n';
  @override
  Widget build(BuildContext context) {
    final bg = _surf(widget.isDark);
    final bd = _bord(widget.isDark);
    final sep = _bordS(widget.isDark);
    final stats = [
      (63000000, '+', widget.l.t('stat_mute_label'), _acc(widget.isDark)),
      (
        8435000,
        '+',
        widget.l.t('stat_isl_label'),
        widget.isDark ? _violetD : _violet,
      ),
      (
        250,
        '',
        widget.l.t('stat_translators_label'),
        widget.isDark ? _cyanD : _cyan,
      ),
    ];
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bd, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: stats.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: _s16,
                    horizontal: 8,
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
                        '${_f((s.$1 * _anim.value).toInt())}${s.$2}',
                        style: _h(19, s.$4, w: FontWeight.w700),
                      ),
                      const SizedBox(height: _s4),
                      Text(
                        s.$3,
                        textAlign: TextAlign.center,
                        style: _lbl(
                          9.5,
                          _txtm(widget.isDark),
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

class _MobFeatureMarquee extends StatelessWidget {
  final bool isDark;
  const _MobFeatureMarquee({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final items = [
      '✦ On-Device AI',
      '✦ 3 Languages',
      '✦ ISL Certified',
      '✦ Voice I/O',
      '✦ Emergency SOS',
      '✦ ISLRTC Approved',
      '✦ Privacy First',
    ];
    final bg = _surf2(isDark);
    final bd = _bord(isDark);
    final a = _acc(isDark);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.symmetric(horizontal: BorderSide(color: bd, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(items[i], style: _lbl(12, a.withOpacity(0.70))),
        ),
      ),
    );
  }
}

class _MobSectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  final EdgeInsets padding;
  const _MobSectionHeader({
    required this.text,
    required this.isDark,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: padding,
      child: Text(text, style: _h(18, _txt(isDark), w: FontWeight.w700)),
    ),
  );
}

class _MobQuickAccess extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobQuickAccess({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext ctx) {
    final cards = [
      (
        _teal,
        _tealD,
        Icons.compare_arrows_rounded,
        l.t('nav_bridge'),
        l.t('home_open_bridge'),
      ),
      (
        _red,
        _redD,
        Icons.emergency_share_rounded,
        l.t('nav_emergency'),
        l.t('sos_screen_title'),
      ),
      (
        _emerald,
        _emeraldD,
        Icons.back_hand_rounded,
        l.t('nav_signs'),
        l.t('home_browse_signs'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: cards.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          final a = isDark ? c.$2 : c.$1;
          Widget d() {
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
              padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
              child: _MobQuickTile(
                a: a,
                icon: c.$3,
                label: c.$4,
                sub: c.$5,
                isDark: isDark,
                onTap: () => Navigator.push(
                  ctx,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => d(),
                    transitionsBuilder: (_, a, _, ch) =>
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

class _MobQuickTile extends StatefulWidget {
  final Color a;
  final IconData icon;
  final String label, sub;
  final bool isDark;
  final VoidCallback onTap;
  const _MobQuickTile({
    required this.a,
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
    required this.onTap,
  });
  @override
  State<_MobQuickTile> createState() => _MobQuickTileState();
}

class _MobQuickTileState extends State<_MobQuickTile> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final bg = _surf(widget.isDark);
    final t = _txt(widget.isDark);
    final s = _txts(widget.isDark);
    final bd = _bord(widget.isDark);
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: bd, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.22 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.a.withOpacity(widget.isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: widget.a.withOpacity(0.24),
                      width: 1,
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.a, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: _lbl(12, t, w: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: _s4),
                Text(
                  widget.sub,
                  style: _lbl(10, s, w: FontWeight.w400),
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

class _MobAICard extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobAICard({
    required this.isDark,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<_MobAICard> createState() => _MobAICardState();
}

class _MobAICardState extends State<_MobAICard>
    with SingleTickerProviderStateMixin {
  bool _p = false;
  late AnimationController _pc;
  late Animation<double> _pa;
  @override
  void initState() {
    super.initState();
    _pc = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pa = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pc, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.isDark;
    final a = d ? _violetD : _violet;
    final bg1 = d ? const Color(0xFF141C31) : const Color(0xFFF7F9FF);
    final bg2 = d ? const Color(0xFF1B2743) : const Color(0xFFEEF3FF);
    final t = _txt(d);
    final s = _txts(d);
    return Semantics(
      label: l.t('assistant_title'),
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => ISLAssistantScreen(
                toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale,
              ),
              transitionsBuilder: (_, a, _, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 260),
            ),
          );
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
              border: Border.all(color: a.withOpacity(0.22), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(d ? 0.24 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Glowing avatar
                      AnimatedBuilder(
                        animation: _pa,
                        builder: (_, _) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [a, _cyan.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: a.withOpacity(_pa.value * 0.36),
                                blurRadius: 14,
                                spreadRadius: 1,
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(l.t('assistant_title'), style: _h(16, t)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: a.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: _lbl(9, a, w: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedBuilder(
                                  animation: _pa,
                                  builder: (_, _) => Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF22C55E),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF22C55E,
                                          ).withOpacity(_pa.value * 0.6),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.t('assistant_card_subtitle'),
                              style: _b(12, s),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: a.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: a,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: a.withOpacity(0.10)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MobAIChip(
                          Icons.mic_rounded,
                          l.t('assistant_chip_voice_io'),
                          a,
                          d,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MobAIChip(
                          Icons.front_hand_rounded,
                          l.t('assistant_chip_sign_guides'),
                          _teal,
                          d,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MobAIChip(
                          Icons.auto_awesome_rounded,
                          'VANI AI',
                          _elBlue,
                          d,
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

class _MobAIChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;
  const _MobAIChip(this.icon, this.label, this.color, this.dark);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(dark ? 0.10 : 0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.20), width: 1),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: _s4),
        Text(
          label,
          style: _lbl(9.5, color, w: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _MobObjScroll extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _MobObjScroll({
    required this.isDark,
    required this.l,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  Widget build(BuildContext context) {
    final cards = _objCards(l, toggleTheme, setLocale);
    final accs = [
      [_elBlue, _elBlueD],
      [_teal, _tealD],
      [_emerald, _emeraldD],
      [_cyan, _cyanD],
      [_amber, _amberD],
      [_violet, _violetD],
    ];
    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        itemBuilder: (ctx, i) {
          final c = cards[i];
          final a = isDark ? accs[i][1] : accs[i][0];
          return Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
            child: _MobObjCard(
              icon: c.$2,
              title: c.$3,
              desc: c.$4,
              accent: a,
              page: c.$5,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _MobObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final Widget page;
  final bool isDark;
  const _MobObjCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
    required this.page,
    required this.isDark,
  });
  @override
  State<_MobObjCard> createState() => _MobObjCardState();
}

class _MobObjCardState extends State<_MobObjCard> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final bg = _surf(widget.isDark);
    final t = _txt(widget.isDark);
    final s = _txts(widget.isDark);
    final bd = _bord(widget.isDark);
    return Semantics(
      label: widget.title,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => widget.page,
              transitionsBuilder: (_, a, _, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 240),
            ),
          );
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutBack,
          child: Container(
            width: 148,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bd, width: 1),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accent.withOpacity(0.14),
                        widget.accent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.accent.withOpacity(0.20),
                      width: 1,
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: _lbl(12.5, t, w: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: _s4),
                Expanded(
                  child: Text(
                    widget.desc,
                    style: _b(10.5, s),
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

class _MobMissionCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _MobMissionCard({required this.isDark, required this.l});
  @override
  Widget build(BuildContext context) {
    final a = _acc(isDark);
    final bg = _surf(isDark);
    final t = _txt(isDark);
    final s = _txts(isDark);
    return Container(
      padding: const EdgeInsets.all(_s20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: a.withOpacity(0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: a.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, color: a, size: 18),
              const SizedBox(width: 8),
              Text(
                l.t('home_our_mission'),
                style: _lbl(12, a, w: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.t('vision_title'), style: _h(17, t)),
          const SizedBox(height: 8),
          Text(l.t('home_mission_body'), style: _b(13, s)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isDark ? _redD : _red,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l.t('obj_crisis_stat'),
                    style: _lbl(
                      11.5,
                      isDark ? _redD : _red,
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

class _MobFeatureDetail extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  final IconData icon;
  final String title, subtitle, launchLabel;
  final Color aL, aD;
  final VoidCallback onLaunch;
  final List<(IconData, String, String)> bullets;
  const _MobFeatureDetail({
    required this.isDark,
    required this.l,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.aL,
    required this.aD,
    required this.launchLabel,
    required this.onLaunch,
    required this.bullets,
  });
  Color get _a => isDark ? aD : aL;
  @override
  Widget build(BuildContext context) {
    final t = _txt(isDark);
    final s = _txts(isDark);
    final bg = _surf(isDark);
    final bd = _bord(isDark);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
              child: Text(title, style: _disp(26, t)),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_s20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg, Color.lerp(bg, _a, isDark ? 0.08 : 0.05)!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _a.withOpacity(0.28), width: 1.25),
              boxShadow: [
                BoxShadow(
                  color: _a.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_a.withOpacity(0.18), _a.withOpacity(0.06)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _a.withOpacity(0.28), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _a.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: _a, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _h(17, t)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: _b(13, s)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FEATURES',
            style: _lbl(
              10.5,
              _txtm(isDark),
              w: FontWeight.w700,
            ).copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg, Color.lerp(bg, _a, isDark ? 0.05 : 0.03)!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bd, width: 1),
            ),
            child: Column(
              children: bullets.asMap().entries.map((e) {
                final i = e.key;
                final f = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _a.withOpacity(0.16),
                                  _a.withOpacity(0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _a.withOpacity(0.24),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _a.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(f.$1, color: _a, size: 18),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$2,
                                  style: _lbl(13.5, t, w: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(f.$3, style: _b(12, s)),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: _txtm(isDark).withOpacity(0.85),
                          ),
                        ],
                      ),
                    ),
                    if (i < bullets.length - 1)
                      Divider(
                        indent: 72,
                        height: 1,
                        thickness: 1,
                        color: _bordS(isDark),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _MobCTABtn(label: launchLabel, acc: _a, onTap: onLaunch),
        ],
      ),
    );
  }
}

class _MobCTABtn extends StatefulWidget {
  final String label;
  final Color acc;
  final VoidCallback onTap;
  const _MobCTABtn({
    required this.label,
    required this.acc,
    required this.onTap,
  });
  @override
  State<_MobCTABtn> createState() => _MobCTABtnState();
}

class _MobCTABtnState extends State<_MobCTABtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.acc, _cyan.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.acc.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: _lbl(15, Colors.white, w: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
//  OBJ CARDS DATA
List<(Color, IconData, String, String, Widget)> _objCards(
  AppLocalizations l,
  VoidCallback toggleTheme,
  Function(Locale) setLocale,
) => [
  (
    _elBlue,
    Icons.accessibility_new_rounded,
    l.t('obj_accessibility'),
    l.t('obj_accessibility_desc'),
    AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _teal,
    Icons.connecting_airports_rounded,
    l.t('obj_bridging'),
    l.t('obj_bridging_desc'),
    BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _emerald,
    Icons.people_outline_rounded,
    l.t('obj_inclusivity'),
    l.t('obj_inclusivity_desc'),
    InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _cyan,
    Icons.language_rounded,
    l.t('obj_localization'),
    l.t('obj_localization_desc'),
    LocalizationPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _amber,
    Icons.shield_outlined,
    l.t('obj_privacy'),
    l.t('obj_privacy_desc'),
    PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
  (
    _violet,
    Icons.school_rounded,
    l.t('obj_education'),
    l.t('obj_education_desc'),
    EducationPage(toggleTheme: toggleTheme, setLocale: setLocale),
  ),
];
