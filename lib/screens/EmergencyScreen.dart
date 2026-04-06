// lib/screens/EmergencyScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Screen  · Apple-Minimal Redesign                 ║
// ║  Aesthetic: iOS 17-inspired, refined minimal depth                 ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../services/EmergencyService.dart';
import '../utils/PlatformHelper.dart';
import '../l10n/AppLocalizations.dart';
import 'EmergencySetupScreen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/EmergencyContact.dart';

// ─────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Apple iOS palette
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

// Semantic — Apple system colors
const _danger      = Color(0xFFFF3B30);
const _dangerD     = Color(0xFFFF453A);
const _dangerSoft  = Color(0xFFFFEEED);
const _warning     = Color(0xFFFF9500);
const _warningD    = Color(0xFFFF9F0A);
const _warningSoft = Color(0xFFFFF4E6);
const _success     = Color(0xFF34C759);
const _successD    = Color(0xFF32D74B);
const _successSoft = Color(0xFFEAF7EE);
const _info        = Color(0xFF007AFF);
const _infoD       = Color(0xFF0A84FF);

// Scenario accents
const _scRed    = Color(0xFFFF3B30); const _scRedD    = Color(0xFFFF453A);
const _scOrange = Color(0xFFFF6B00); const _scOrangeD = Color(0xFFFF9F0A);
const _scBlue   = Color(0xFF007AFF); const _scBlueD   = Color(0xFF0A84FF);
const _scAmber  = Color(0xFFFF9500); const _scAmberD  = Color(0xFFFFCC00);
const _scPurple = Color(0xFFAF52DE); const _scPurpleD = Color(0xFFBF5AF2);
const _scTeal   = Color(0xFF00C7BE); const _scTealD   = Color(0xFF63E6E2);

// Neutral
const _lBg       = Color(0xFFF2F2F7);
const _lSurface  = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF2F2F7);
const _lBorder   = Color(0xFFE5E5EA);
const _lSep      = Color(0xFFC6C6C8);
const _lText     = Color(0xFF000000);
const _lTextSub  = Color(0xFF3C3C43);
const _lTextMuted = Color(0xFF8E8E93);

const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dBorder   = Color(0xFF38383A);
const _dSep      = Color(0xFF48484A);
const _dText     = Color(0xFFFFFFFF);
const _dTextSub  = Color(0xFFAEAEB2);
const _dTextMuted = Color(0xFF636366);

// Spacing
const _sp2  = 2.0;
const _sp4  = 4.0;
const _sp6  = 6.0;
const _sp8  = 8.0;
const _sp10 = 10.0;
const _sp12 = 12.0;
const _sp14 = 14.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp48 = 48.0;

// ── Type helpers — Apple HIG scale ───────────────────────────────────
TextStyle _largeTitle(Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: 34, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: 0.37);

TextStyle _title2(Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w700,
    color: c, height: 1.3, letterSpacing: 0.35);

TextStyle _headline(Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: 17, fontWeight: FontWeight.w600,
    color: c, height: 1.3, letterSpacing: -0.41);

TextStyle _body(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 17, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.41);

TextStyle _callout(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.32);

TextStyle _subhead(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 15, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.23);

TextStyle _footnote(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 13, fontWeight: w,
    color: c, height: 1.4, letterSpacing: -0.08);

TextStyle _caption(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: w,
    color: c, height: 1.3, letterSpacing: 0.0);

TextStyle _caption2(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: w,
    color: c, height: 1.3, letterSpacing: 0.06);

// ─────────────────────────────────────────────────────────────────────
//  SCENARIO MODEL
// ─────────────────────────────────────────────────────────────────────
class _Scenario {
  final SOSMessageType type;
  final IconData icon;
  final String titleKey, subtitleKey, signHint,
      helpline, helplineName, smsTemplateKey;
  final Color accentLight, accentDark;
  const _Scenario({
    required this.type, required this.icon, required this.titleKey,
    required this.subtitleKey, required this.signHint, required this.helpline,
    required this.helplineName, required this.smsTemplateKey,
    required this.accentLight, required this.accentDark,
  });
  Color accent(bool dark) => dark ? accentDark : accentLight;
}

const List<_Scenario> _kScenarios = [
  _Scenario(type: SOSMessageType.generalHelp, icon: Icons.sos_rounded,
      titleKey: 'sos_general_title', subtitleKey: 'sos_general_sub',
      signHint: 'sos_sign_help', helpline: '112',
      helplineName: 'sos_helpline_emergency',
      accentLight: _scRed,  accentDark: _scRedD,
      smsTemplateKey: 'sos_sms_general_template'),
  _Scenario(type: SOSMessageType.medical, icon: Icons.medical_services_rounded,
      titleKey: 'sos_medical_title', subtitleKey: 'sos_medical_sub',
      signHint: 'sos_sign_doctor', helpline: '108',
      helplineName: 'sos_helpline_ambulance',
      accentLight: _scOrange, accentDark: _scOrangeD,
      smsTemplateKey: 'sos_sms_medical_template'),
  _Scenario(type: SOSMessageType.police, icon: Icons.shield_rounded,
      titleKey: 'sos_police_title', subtitleKey: 'sos_police_sub',
      signHint: 'sos_sign_strong', helpline: '100',
      helplineName: 'sos_helpline_police',
      accentLight: _scBlue, accentDark: _scBlueD,
      smsTemplateKey: 'sos_sms_police_template'),
  _Scenario(type: SOSMessageType.fire, icon: Icons.local_fire_department_rounded,
      titleKey: 'sos_fire_title', subtitleKey: 'sos_fire_sub',
      signHint: 'sos_sign_help_bad', helpline: '101',
      helplineName: 'sos_helpline_fire',
      accentLight: _scAmber, accentDark: _scAmberD,
      smsTemplateKey: 'sos_sms_fire_template'),
  _Scenario(type: SOSMessageType.custom, icon: Icons.directions_car_rounded,
      titleKey: 'sos_accident_title', subtitleKey: 'sos_accident_sub',
      signHint: 'sos_sign_bad_sorry', helpline: '1033',
      helplineName: 'sos_helpline_highway',
      accentLight: _scPurple, accentDark: _scPurpleD,
      smsTemplateKey: 'sos_sms_accident_template'),
  _Scenario(type: SOSMessageType.custom, icon: Icons.child_care_rounded,
      titleKey: 'sos_child_title', subtitleKey: 'sos_child_sub',
      signHint: 'sos_sign_mother', helpline: '1098',
      helplineName: 'sos_helpline_childline',
      accentLight: _scTeal, accentDark: _scTealD,
      smsTemplateKey: 'sos_sms_child_template'),
];

// ══════════════════════════════════════════════════════════════════════
//  EMERGENCY SCREEN
// ══════════════════════════════════════════════════════════════════════
class EmergencyScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final String? detectedSign;
  const EmergencyScreen({
    super.key, required this.toggleTheme, required this.setLocale,
    this.detectedSign,
  });
  @override State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  final _service = EmergencyService.instance;

  bool _isSending = false;
  int? _activeSendIndex;
  String? _statusMsg;
  bool _statusOk = false;
  _Scenario? _autoScenario;

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _pulseAnim;

  late final Box<EmergencyContact> _contactBox;

  void _onContactsChanged() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _service.updateContext(context);
    _contactBox = Hive.box<EmergencyContact>('emergency_contacts');
    _contactBox.listenable().addListener(_onContactsChanged);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 440));
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);

    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _pulseAnim  = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _entryCtrl.forward();
    if (widget.detectedSign != null) {
      _autoScenario = _matchSign(widget.detectedSign!);
    }
  }

  _Scenario? _matchSign(String sign) {
    final s = sign.toLowerCase();
    if (s.contains('help') || s.contains('sos'))         return _kScenarios[0];
    if (s.contains('doctor') || s.contains('sick'))      return _kScenarios[1];
    if (s.contains('danger') || s.contains('police'))    return _kScenarios[2];
    if (s.contains('fire') || s.contains('smoke'))       return _kScenarios[3];
    if (s.contains('accident') || s.contains('car'))     return _kScenarios[4];
    if (s.contains('child') || s.contains('mother'))     return _kScenarios[5];
    return _kScenarios[0];
  }

  @override
  void dispose() {
    _contactBox.listenable().removeListener(_onContactsChanged);
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS(int idx) async {
    final l = AppLocalizations.of(context);
    if (_isSending) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isSending = true;
      _activeSendIndex = idx;
      _statusMsg = null;
    });

    final result = await _service.triggerSOS(
      type: _kScenarios[idx].type,
      customMessage: l.t(_kScenarios[idx].smsTemplateKey),
    );

    if (mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isSending = false;
        _activeSendIndex = null;
        _statusOk  = result.success;
        _statusMsg = result.success
            ? (PlatformHelper.isMobile
            ? ((result.sentCount == 1
            ? l.t('sos_sent_mobile')
            : l.t('sos_sent_mobile_plural'))
            .replaceAll('{n}', '${result.sentCount}'))
            : l.t('sos_sent_web'))
            : result.reason;
      });
      Future.delayed(const Duration(seconds: 7),
              () { if (mounted) setState(() => _statusMsg = null); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w      = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ══════════════════════════════════════════════════════════════════
  //  MOBILE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l  = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          _MobileTopBar(
            isDark: isDark,
            pulseAnim: _pulseAnim,
            onBack: () => Navigator.pop(ctx),
            onContacts: () => _pushSetup(ctx),
          ),
          Expanded(child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    _sp16, _sp12, _sp16, _sp48),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Auto-detect
                  if (_autoScenario != null) ...[
                    _AutoDetectCard(
                      scenario: _autoScenario!, isDark: isDark,
                      signLabel: widget.detectedSign ?? '',
                      onTap: () => _triggerSOS(
                          _kScenarios.indexOf(_autoScenario!)),
                    ),
                    const SizedBox(height: _sp12),
                  ],

                  // Status
                  if (_statusMsg != null) ...[
                    _StatusBanner(
                        message: _statusMsg!, ok: _statusOk, isDark: isDark),
                    const SizedBox(height: _sp12),
                  ],

                  // No contacts warning
                  if (!_service.hasContacts) ...[
                    _NoContactsBanner(isDark: isDark,
                        onTap: () => _pushSetup(ctx)),
                    const SizedBox(height: _sp12),
                  ],

                  // Section header
                  _SectionLabel(
                      primary: l.t('sos_screen_title'),
                      secondary: l.t('sos_screen_subtitle_mobile'),
                      isDark: isDark),
                  const SizedBox(height: _sp12),

                  // Scenario grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: _sp10,
                    crossAxisSpacing: _sp10,
                    childAspectRatio: 1.02,
                    children: _kScenarios.asMap().entries.map((e) =>
                        _ScenarioCard(
                          scenario: e.value, isDark: isDark,
                          pulseAnim: _pulseAnim,
                          isSending:
                          _isSending && _activeSendIndex == e.key,
                          isDisabled:
                          _isSending && _activeSendIndex != e.key,
                          isHighlighted: _autoScenario == e.value,
                          onTap: () => _triggerSOS(e.key),
                        )).toList(),
                  ),

                  const SizedBox(height: _sp24),

                  // Helplines
                  _SectionLabel(
                      primary: l.t('sos_helpline_ref'),
                      secondary: l.t('sos_setup_contacts'),
                      isDark: isDark),
                  const SizedBox(height: _sp12),
                  _HelplinesCard(isDark: isDark),

                  if (PlatformHelper.supportsShake) ...[
                    const SizedBox(height: _sp12),
                    _ShakeCard(isDark: isDark),
                  ],
                ],
              ),
            ),
          )),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  WEB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 80.0 : 40.0;
    final bg   = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          GlobalNavbar(toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale, activeRoute: 'emergency'),
          Expanded(child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, _sp24, hPad, 64),
                physics: const BouncingScrollPhysics(),
                child: isDesktop
                    ? _webDesktopLayout(ctx, isDark)
                    : _webTabletLayout(ctx, isDark),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 300, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _WebHero(isDark: isDark, pulseAnim: _pulseAnim,
              onBack: () => Navigator.pop(ctx)),
          const SizedBox(height: _sp20),
          if (_autoScenario != null) ...[
            _AutoDetectCard(scenario: _autoScenario!, isDark: isDark,
                signLabel: widget.detectedSign ?? '',
                onTap: () => _triggerSOS(
                    _kScenarios.indexOf(_autoScenario!))),
            const SizedBox(height: _sp12),
          ],
          if (_statusMsg != null) ...[
            _StatusBanner(message: _statusMsg!, ok: _statusOk, isDark: isDark),
            const SizedBox(height: _sp12),
          ],
          if (!_service.hasContacts) ...[
            _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
            const SizedBox(height: _sp12),
          ],
          _HelplinesCard(isDark: isDark),
          const SizedBox(height: _sp12),
          if (PlatformHelper.supportsShake) ...[
            _ShakeCard(isDark: isDark),
            const SizedBox(height: _sp12),
          ],
          _ContactsButton(isDark: isDark, count: _service.contactCount,
              onTap: () => _pushSetup(ctx)),
        ])),
        const SizedBox(width: 40),
        Expanded(child: _ScenariosGrid(
          isDark: isDark, pulseAnim: _pulseAnim,
          activeSendIndex: _activeSendIndex, isSending: _isSending,
          autoScenario: _autoScenario, onTap: _triggerSOS,
        )),
      ]);

  Widget _webTabletLayout(BuildContext ctx, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _WebHero(isDark: isDark, pulseAnim: _pulseAnim,
            onBack: () => Navigator.pop(ctx)),
        const SizedBox(height: _sp20),
        if (_autoScenario != null) ...[
          _AutoDetectCard(scenario: _autoScenario!, isDark: isDark,
              signLabel: widget.detectedSign ?? '',
              onTap: () => _triggerSOS(_kScenarios.indexOf(_autoScenario!))),
          const SizedBox(height: _sp12),
        ],
        if (_statusMsg != null) ...[
          _StatusBanner(message: _statusMsg!, ok: _statusOk, isDark: isDark),
          const SizedBox(height: _sp12),
        ],
        if (!_service.hasContacts) ...[
          _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
          const SizedBox(height: _sp12),
        ],
        _ScenariosGrid(
          isDark: isDark, pulseAnim: _pulseAnim,
          activeSendIndex: _activeSendIndex, isSending: _isSending,
          autoScenario: _autoScenario, onTap: _triggerSOS,
        ),
        const SizedBox(height: _sp20),
        _HelplinesCard(isDark: isDark),
        const SizedBox(height: _sp12),
        if (PlatformHelper.supportsShake) ...[
          _ShakeCard(isDark: isDark),
          const SizedBox(height: _sp12),
        ],
        _ContactsButton(isDark: isDark, count: _service.contactCount,
            onTap: () => _pushSetup(ctx)),
      ]);

  void _pushSetup(BuildContext ctx) => Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => EmergencySetupScreen(
          toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
      transitionsBuilder: (_, a, __, c) =>
          FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 240),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE TOP BAR
// ══════════════════════════════════════════════════════════════════════
class _MobileTopBar extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnim;
  final VoidCallback onBack, onContacts;
  const _MobileTopBar({required this.isDark, required this.pulseAnim,
    required this.onBack, required this.onContacts});

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final bg      = isDark ? _dSurface.withOpacity(0.94) : Colors.white.withOpacity(0.94);
    final border  = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText   : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _dangerD : _danger;
    final navBlue = isDark ? _infoD   : _info;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp8),
      child: Row(children: [
        // Back
        Semantics(label: l.t('common_back'), button: true,
          child: GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _sp8, vertical: _sp8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chevron_left_rounded, color: navBlue, size: 28),
                Text(l.t('common_back'),
                    style: _callout(navBlue)),
              ]),
            ),
          ),
        ),
        const Spacer(),
        // Title + live dot
        Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(animation: pulseAnim, builder: (_, __) =>
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: accent,
                  boxShadow: [BoxShadow(
                      color: accent.withOpacity(pulseAnim.value * 0.6),
                      blurRadius: 8, spreadRadius: 1)],
                ),
              )),
          const SizedBox(width: _sp8),
          Text(l.t('sos_screen_title'), style: _headline(textClr)),
        ]),
        const Spacer(),
        // Contacts button
        Semantics(label: l.t('sos_setup_title'), button: true,
          child: GestureDetector(
            onTap: onContacts,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _sp8, vertical: _sp8),
              child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: isDark ? _dSurface2 : _lSurface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border, width: 0.5)),
                  child: Icon(Icons.contacts_rounded,
                      color: isDark ? _dTextSub : _lTextSub, size: 17)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SCENARIO CARD — Refined, tactile, Apple-style press feel
// ══════════════════════════════════════════════════════════════════════
class _ScenarioCard extends StatefulWidget {
  final _Scenario scenario;
  final bool isDark, isSending, isDisabled, isHighlighted;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  const _ScenarioCard({required this.scenario, required this.isDark,
    required this.pulseAnim, required this.isSending, required this.isDisabled,
    required this.isHighlighted, required this.onTap});
  @override State<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<_ScenarioCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final s      = widget.scenario;
    final isDark = widget.isDark;
    final accent = s.accent(isDark);
    final bg     = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText   : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final border  = isDark ? _dBorder : _lBorder;
    final isActive = widget.isSending || widget.isHighlighted;

    // Pressed + active visual states
    final cardBg = isActive
        ? (isDark
        ? Color.lerp(_dSurface, accent, 0.08)!
        : Color.lerp(_lSurface, accent, 0.04)!)
        : (_pressed
        ? (isDark ? _dSurface2 : const Color(0xFFF5F5F7))
        : bg);

    return Semantics(
      label: l.t(s.titleKey), button: true, enabled: !widget.isDisabled,
      child: AnimatedOpacity(
        opacity: widget.isDisabled ? 0.30 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTapDown: (_) {
            if (!widget.isDisabled) {
              HapticFeedback.lightImpact();
              setState(() => _pressed = true);
            }
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            if (!widget.isDisabled) widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(_sp16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isActive
                        ? accent.withOpacity(0.35)
                        : border,
                    width: isActive ? 1.0 : 0.5),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? accent.withOpacity(isDark ? 0.15 : 0.08)
                        : Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                    blurRadius: isActive ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: icon + helpline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container — clean square
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: widget.isSending
                              ? SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.0, color: accent))
                              : Icon(s.icon, color: accent, size: 20),
                        ),
                      ),
                      // Helpline pill — minimal
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _sp8, vertical: _sp4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s.helpline,
                            style: _caption2(accent, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    widget.isSending ? l.t('sos_sending') : l.t(s.titleKey),
                    style: _footnote(
                        widget.isSending ? accent : textClr,
                        w: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _sp2),
                  // Subtitle
                  Text(
                    widget.isSending
                        ? l.t('sos_send_to_contacts')
                        : l.t(s.subtitleKey),
                    style: _caption2(subClr),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB HERO
// ══════════════════════════════════════════════════════════════════════
class _WebHero extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnim;
  final VoidCallback onBack;
  const _WebHero({required this.isDark, required this.pulseAnim, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final textClr = isDark ? _dText   : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _dangerD : _danger;
    final navBlue = isDark ? _infoD   : _info;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Back
      GestureDetector(
        onTap: onBack,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _sp4, horizontal: _sp4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chevron_left_rounded, color: navBlue, size: 20),
            Text(l.t('sos_setup_back'),
                style: _callout(navBlue)),
          ]),
        ),
      ),
      const SizedBox(height: _sp20),

      // Live badge — subtle pill
      AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp6),
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.20), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: accent,
                boxShadow: [BoxShadow(
                    color: accent.withOpacity(pulseAnim.value * 0.50),
                    blurRadius: 6, spreadRadius: 1)],
              ),
            ),
            const SizedBox(width: _sp8),
            Text(l.t('sos_screen_badge_web'),
                style: _caption2(accent, w: FontWeight.w700)),
          ]),
        ),
      ),

      const SizedBox(height: _sp16),
      Text(l.t('sos_screen_title'), style: _largeTitle(textClr)),
      const SizedBox(height: _sp6),
      Text(l.t('sos_screen_subtitle_mobile'), style: _footnote(subClr)),
    ]);
  }
}

// ── Scenarios grid ────────────────────────────────────────────────────
class _ScenariosGrid extends StatelessWidget {
  final bool isDark, isSending;
  final Animation<double> pulseAnim;
  final int? activeSendIndex;
  final _Scenario? autoScenario;
  final void Function(int) onTap;
  const _ScenariosGrid({required this.isDark, required this.pulseAnim,
    required this.activeSendIndex, required this.isSending,
    required this.autoScenario, required this.onTap});

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, mainAxisSpacing: _sp10, crossAxisSpacing: _sp10,
    childAspectRatio: 1.20,
    children: _kScenarios.asMap().entries.map((e) => _ScenarioCard(
      scenario: e.value, isDark: isDark, pulseAnim: pulseAnim,
      isSending: isSending && activeSendIndex == e.key,
      isDisabled: isSending && activeSendIndex != e.key,
      isHighlighted: autoScenario == e.value,
      onTap: () => onTap(e.key),
    )).toList(),
  );
}

// ── Helplines card ────────────────────────────────────────────────────
class _HelplinesCard extends StatelessWidget {
  final bool isDark;
  const _HelplinesCard({required this.isDark});

  static const _items = [
    ('112', 'Emergency', _scRed,    _scRedD),
    ('108', 'Ambulance', _scOrange, _scOrangeD),
    ('100', 'Police',    _scBlue,   _scBlueD),
    ('101', 'Fire',      _scAmber,  _scAmberD),
  ];

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final sep    = isDark ? _dSep      : _lSep;
    final subClr = isDark ? _dTextMuted : _lTextMuted;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                blurRadius: 16, offset: const Offset(0, 3)),
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(child: Row(
          children: _items.asMap().entries.map((e) {
            final i     = e.key;
            final item  = e.value;
            final color = isDark ? item.$4 : item.$3;
            return Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: _sp16),
              decoration: BoxDecoration(border: i < _items.length - 1
                  ? Border(right: BorderSide(color: sep, width: 0.5))
                  : null),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$1,
                        style: TextStyle(fontFamily: _fontFamily, fontSize: 22,
                            fontWeight: FontWeight.w700, color: color,
                            letterSpacing: -0.5)),
                    const SizedBox(height: _sp4),
                    Text(item.$2, style: _caption2(subClr),
                        textAlign: TextAlign.center),
                  ]),
            ));
          }).toList(),
        )),
      ),
    );
  }
}

// ── Auto detect card ──────────────────────────────────────────────────
class _AutoDetectCard extends StatelessWidget {
  final _Scenario scenario;
  final bool isDark;
  final String signLabel;
  final VoidCallback onTap;
  const _AutoDetectCard({required this.scenario, required this.isDark,
    required this.signLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final accent = scenario.accent(isDark);
    final textClr = isDark ? _dText : _lText;
    final bg     = isDark ? _dSurface : _lSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(_sp16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.30), width: 1.0),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(isDark ? 0.10 : 0.06),
                blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(scenario.icon, color: accent, size: 20)),
          const SizedBox(width: _sp12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('sos_isl_detected').replaceAll('{sign}', signLabel),
                style: _caption2(accent, w: FontWeight.w700)),
            const SizedBox(height: _sp2),
            Text(l.t('sos_isl_suggested')
                .replaceAll('{type}', l.t(scenario.titleKey)),
                style: _subhead(textClr, w: FontWeight.w600)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 13),
        ]),
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String message;
  final bool ok, isDark;
  const _StatusBanner({required this.message, required this.ok,
    required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color  = ok ? (isDark ? _successD : _success) : (isDark ? _dangerD : _danger);
    final bgClr  = ok
        ? (isDark ? _successD.withOpacity(0.10) : _successSoft)
        : (isDark ? _dangerD.withOpacity(0.10)  : _dangerSoft);
    final borderC = color.withOpacity(0.25);
    final icon   = ok ? Icons.check_circle_rounded : Icons.error_outline_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
      ),
      child: Semantics(liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
          decoration: BoxDecoration(
              color: bgClr,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderC, width: 0.5)),
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: _sp10),
            Expanded(child: Text(message,
                style: _footnote(color, w: FontWeight.w500))),
          ]),
        ),
      ),
    );
  }
}

// ── No contacts banner ────────────────────────────────────────────────
class _NoContactsBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _NoContactsBanner({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final amber  = isDark ? _warningD : _warning;
    final bgClr  = isDark ? _warningD.withOpacity(0.08) : _warningSoft;
    final border = amber.withOpacity(0.20);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _sp14, vertical: _sp12),
        decoration: BoxDecoration(
            color: bgClr,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 0.5)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: amber, size: 16),
          const SizedBox(width: _sp10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('sos_no_contacts_title'),
                style: _caption(amber, w: FontWeight.w700)),
            const SizedBox(height: _sp2),
            Text(l.t('sos_no_contacts_body'), style: _caption2(amber)),
          ])),
          Icon(Icons.chevron_right_rounded, color: amber, size: 16),
        ]),
      ),
    );
  }
}

// ── Shake card ────────────────────────────────────────────────────────
class _ShakeCard extends StatelessWidget {
  final bool isDark;
  const _ShakeCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _infoD    : _info;

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                blurRadius: 14, offset: const Offset(0, 3)),
          ]),
      child: Row(children: [
        Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.vibration_rounded, color: accent, size: 20)),
        const SizedBox(width: _sp14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('sos_shake_title'),
              style: _subhead(textClr, w: FontWeight.w600)),
          const SizedBox(height: _sp2),
          Text(l.t('sos_shake_body'), style: _footnote(subClr)),
        ])),
      ]),
    );
  }
}

// ── Contacts button ───────────────────────────────────────────────────
class _ContactsButton extends StatefulWidget {
  final bool isDark;
  final int count;
  final VoidCallback onTap;
  const _ContactsButton({required this.isDark, required this.count,
    required this.onTap});
  @override State<_ContactsButton> createState() => _ContactsButtonState();
}

class _ContactsButtonState extends State<_ContactsButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final bg      = widget.isDark ? _dSurface  : _lSurface;
    final bgHov   = widget.isDark ? _dSurface2 : const Color(0xFFF5F5F7);
    final border  = widget.isDark ? _dBorder   : _lBorder;
    final textClr = widget.isDark ? _dText     : _lText;
    final subClr  = widget.isDark ? _dTextSub  : _lTextSub;
    final accent  = widget.isDark ? _infoD     : _info;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
              horizontal: _sp16, vertical: _sp12),
          decoration: BoxDecoration(
            color: (_hovered || _pressed) ? bgHov : bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (_hovered || _pressed)
                    ? accent.withOpacity(0.25) : border,
                width: 0.5),
          ),
          child: Row(children: [
            Icon(Icons.contacts_rounded, color: accent, size: 17),
            const SizedBox(width: _sp12),
            Expanded(child: Text(
                widget.count > 0
                    ? ((widget.count == 1
                    ? l.t('sos_contacts_configured')
                    : l.t('sos_contacts_plural'))
                    .replaceAll('{n}', '${widget.count}'))
                    : l.t('sos_setup_contacts'),
                style: _footnote(
                    widget.count > 0 ? textClr : subClr,
                    w: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, color: subClr, size: 14),
          ]),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String primary, secondary;
  final bool isDark;
  const _SectionLabel({required this.primary, required this.secondary,
    required this.isDark});

  @override
  Widget build(BuildContext context) => Semantics(header: true,
    child: Padding(
      padding: const EdgeInsets.only(left: _sp4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(primary.toUpperCase(),
            style: _caption2(isDark ? _dTextMuted : _lTextMuted,
                w: FontWeight.w700)),
        const SizedBox(height: _sp2),
        Text(secondary, style: _caption(isDark ? _dTextSub : _lTextSub)),
      ]),
    ),
  );
}