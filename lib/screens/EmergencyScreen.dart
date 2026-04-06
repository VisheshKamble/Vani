// lib/screens/EmergencyScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Screen  · UX4G Redesign                         ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║  < 700px  → Mobile emergency shell                                ║
// ║  ≥ 700px  → Web/tablet emergency centre                           ║
// ║                                                                    ║
// ║  UX4G Principles Applied:                                         ║
// ║  • Danger semantic color for SOS actions (WCAG AA)                ║
// ║  • Min 48dp touch targets on all scenario cards                   ║
// ║  • Status/severity color coding (danger/warning/success/info)     ║
// ║  • Semantics() wrappers for screen readers                        ║
// ║  • Clear visual hierarchy: alert → action → reference             ║
// ║  • No decorative blur/glass — clarity above aesthetics            ║
// ║  • High-contrast helpline numbers (20px bold)                     ║
// ║  • Warning banner uses semantic warning color + icon              ║
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
//  UX4G DESIGN TOKENS  (shared with HomeScreen)
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

// Brand

// Status / Semantic
const _danger = Color(0xFFB71C1C);
const _dangerDark = Color(0xFFEF5350);
const _dangerLight = Color(0xFFFFEBEE);

const _warning = Color(0xFF7A4800);
const _warningDark = Color(0xFFFFB300);
const _warningLight = Color(0xFFFFF3E0);

const _success = Color(0xFF1B7340);
const _successDark = Color(0xFF27AE60);
const _successLight = Color(0xFFE6F4EC);

const _info = Color(0xFF0D47A1);
const _infoDark = Color(0xFF42A5F5);

// Scenario-specific (all WCAG AA on their light surfaces)
const _scRed = Color(0xFFB71C1C); // General / Emergency
const _scRedD = Color(0xFFEF5350);
const _scOrange = Color(0xFF7A4800); // Medical
const _scOrangeD = Color(0xFFFFB300);
const _scBlue = Color(0xFF0D47A1); // Police
const _scBlueD = Color(0xFF42A5F5);
const _scAmber = Color(0xFF6D4C00); // Fire
const _scAmberD = Color(0xFFFFA000);
const _scPurple = Color(0xFF4A148C); // Accident
const _scPurpleD = Color(0xFFCE93D8);
const _scTeal = Color(0xFF006064); // Child
const _scTealD = Color(0xFF4DD0E1);

// Neutral surfaces
const _lBg = Color(0xFFF5F7FA);
const _lSurface = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF0F4F8);
const _lBorder = Color(0xFFCDD5DF);
const _lBorderSub = Color(0xFFE4E9F0);
const _lText = Color(0xFF111827);
const _lTextSub = Color(0xFF374151);
const _lTextMuted = Color(0xFF6B7280);

const _dBg = Color(0xFF0D1117);
const _dSurface = Color(0xFF161B22);
const _dSurface2 = Color(0xFF21262D);
const _dBorder = Color(0xFF30363D);
const _dBorderSub = Color(0xFF21262D);
const _dText = Color(0xFFE6EDF3);
const _dTextSub = Color(0xFFB0BEC5);
const _dTextMuted = Color(0xFF8B949E);

// Spacing
const _sp4 = 4.0;
const _sp8 = 8.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp48 = 48.0;

// ── Text helpers ──────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
//  SCENARIO MODEL
// ─────────────────────────────────────────────────────────────────────
class _Scenario {
  final SOSMessageType type;
  final IconData icon;
  final String titleKey,
      subtitleKey,
      signHint,
      helpline,
      helplineName,
      smsTemplateKey;
  final Color accentLight, accentDark;
  const _Scenario({
    required this.type,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.signHint,
    required this.helpline,
    required this.helplineName,
    required this.smsTemplateKey,
    required this.accentLight,
    required this.accentDark,
  });
  Color accent(bool dark) => dark ? accentDark : accentLight;
}

const List<_Scenario> _kScenarios = [
  _Scenario(
    type: SOSMessageType.generalHelp,
    icon: Icons.emergency_rounded,
    titleKey: 'sos_general_title',
    subtitleKey: 'sos_general_sub',
    signHint: 'sos_sign_help',
    helpline: '112',
    helplineName: 'sos_helpline_emergency',
    accentLight: _scRed,
    accentDark: _scRedD,
    smsTemplateKey: 'sos_sms_general_template',
  ),
  _Scenario(
    type: SOSMessageType.medical,
    icon: Icons.medical_services_rounded,
    titleKey: 'sos_medical_title',
    subtitleKey: 'sos_medical_sub',
    signHint: 'sos_sign_doctor',
    helpline: '108',
    helplineName: 'sos_helpline_ambulance',
    accentLight: _scOrange,
    accentDark: _scOrangeD,
    smsTemplateKey: 'sos_sms_medical_template',
  ),
  _Scenario(
    type: SOSMessageType.police,
    icon: Icons.shield_rounded,
    titleKey: 'sos_police_title',
    subtitleKey: 'sos_police_sub',
    signHint: 'sos_sign_strong',
    helpline: '100',
    helplineName: 'sos_helpline_police',
    accentLight: _scBlue,
    accentDark: _scBlueD,
    smsTemplateKey: 'sos_sms_police_template',
  ),
  _Scenario(
    type: SOSMessageType.fire,
    icon: Icons.local_fire_department_rounded,
    titleKey: 'sos_fire_title',
    subtitleKey: 'sos_fire_sub',
    signHint: 'sos_sign_help_bad',
    helpline: '101',
    helplineName: 'sos_helpline_fire',
    accentLight: _scAmber,
    accentDark: _scAmberD,
    smsTemplateKey: 'sos_sms_fire_template',
  ),
  _Scenario(
    type: SOSMessageType.custom,
    icon: Icons.directions_car_rounded,
    titleKey: 'sos_accident_title',
    subtitleKey: 'sos_accident_sub',
    signHint: 'sos_sign_bad_sorry',
    helpline: '1033',
    helplineName: 'sos_helpline_highway',
    accentLight: _scPurple,
    accentDark: _scPurpleD,
    smsTemplateKey: 'sos_sms_accident_template',
  ),
  _Scenario(
    type: SOSMessageType.custom,
    icon: Icons.child_care_rounded,
    titleKey: 'sos_child_title',
    subtitleKey: 'sos_child_sub',
    signHint: 'sos_sign_mother',
    helpline: '1098',
    helplineName: 'sos_helpline_childline',
    accentLight: _scTeal,
    accentDark: _scTealD,
    smsTemplateKey: 'sos_sms_child_template',
  ),
];

// ══════════════════════════════════════════════════════════════════════
//  EMERGENCY SCREEN
// ══════════════════════════════════════════════════════════════════════
class EmergencyScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final String? detectedSign;
  const EmergencyScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
    this.detectedSign,
  });
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
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
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _pulseAnim;

  late final Box<EmergencyContact> _contactBox;

  void _onContactsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _service.updateContext(context);
    _contactBox = Hive.box<EmergencyContact>('emergency_contacts');
    _contactBox.listenable().addListener(_onContactsChanged);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _entryCtrl.forward();
    if (widget.detectedSign != null) {
      _autoScenario = _matchSign(widget.detectedSign!);
    }
  }

  _Scenario? _matchSign(String sign) {
    final s = sign.toLowerCase();
    if (s.contains('help') || s.contains('sos')) return _kScenarios[0];
    if (s.contains('doctor') || s.contains('sick')) return _kScenarios[1];
    if (s.contains('danger') || s.contains('police')) return _kScenarios[2];
    if (s.contains('fire') || s.contains('smoke')) return _kScenarios[3];
    if (s.contains('accident') || s.contains('car')) return _kScenarios[4];
    if (s.contains('child') || s.contains('mother')) return _kScenarios[5];
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
        _statusOk = result.success;
        _statusMsg = result.success
            ? (PlatformHelper.isMobile
                  ? ((result.sentCount == 1
                            ? l.t('sos_sent_mobile')
                            : l.t('sos_sent_mobile_plural'))
                        .replaceAll('{n}', '${result.sentCount}'))
                  : l.t('sos_sent_web'))
            : result.reason;
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _statusMsg = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ══════════════════════════════════════════════════════════════════
  //  MOBILE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _MobileEmergencyBar(
              isDark: isDark,
              pulseAnim: _pulseAnim,
              onBack: () => Navigator.pop(ctx),
              onContacts: () => _pushSetup(ctx),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _sp16,
                      _sp12,
                      _sp16,
                      _sp48,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auto-detect banner
                        if (_autoScenario != null) ...[
                          _AutoDetectBanner(
                            scenario: _autoScenario!,
                            isDark: isDark,
                            signLabel: widget.detectedSign ?? '',
                            onTap: () => _triggerSOS(
                              _kScenarios.indexOf(_autoScenario!),
                            ),
                          ),
                          const SizedBox(height: _sp12),
                        ],

                        // Status bar
                        if (_statusMsg != null) ...[
                          _StatusBar(
                            message: _statusMsg!,
                            ok: _statusOk,
                            isDark: isDark,
                          ),
                          const SizedBox(height: _sp12),
                        ],

                        // No contacts warning
                        if (!_service.hasContacts) ...[
                          _NoContactsBanner(
                            isDark: isDark,
                            onTap: () => _pushSetup(ctx),
                          ),
                          const SizedBox(height: _sp12),
                        ],

                        // Section header
                        _UX4GSectionLabel(
                          label: l.t('sos_screen_title').toUpperCase(),
                          sub: l.t('sos_screen_subtitle_mobile'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: _sp12),

                        // 2-col scenario grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: _sp12,
                          crossAxisSpacing: _sp12,
                          childAspectRatio: 1.05,
                          children: _kScenarios
                              .asMap()
                              .entries
                              .map(
                                (e) => _ScenarioCard(
                                  scenario: e.value,
                                  isDark: isDark,
                                  pulseAnim: _pulseAnim,
                                  isSending:
                                      _isSending && _activeSendIndex == e.key,
                                  isDisabled:
                                      _isSending && _activeSendIndex != e.key,
                                  isAutoDetected: _autoScenario == e.value,
                                  onTap: () => _triggerSOS(e.key),
                                ),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: _sp24),

                        // Helplines section
                        _UX4GSectionLabel(
                          label: l.t('sos_helpline_ref').toUpperCase(),
                          sub: l.t('sos_setup_contacts'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: _sp12),
                        _MobileHelplinesRow(isDark: isDark),

                        const SizedBox(height: _sp16),

                        if (PlatformHelper.supportsShake)
                          _ShakeCard(isDark: isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  WEB / TABLET
  // ══════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 80.0 : 40.0;
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            GlobalNavbar(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
              activeRoute: 'emergency',
            ),
            Expanded(
              child: FadeTransition(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WebHero(
              isDark: isDark,
              pulseAnim: _pulseAnim,
              onBack: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: _sp20),
            if (_autoScenario != null) ...[
              _AutoDetectBanner(
                scenario: _autoScenario!,
                isDark: isDark,
                signLabel: widget.detectedSign ?? '',
                onTap: () => _triggerSOS(_kScenarios.indexOf(_autoScenario!)),
              ),
              const SizedBox(height: _sp12),
            ],
            if (_statusMsg != null) ...[
              _StatusBar(message: _statusMsg!, ok: _statusOk, isDark: isDark),
              const SizedBox(height: _sp12),
            ],
            if (!_service.hasContacts) ...[
              _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
              const SizedBox(height: _sp12),
            ],
            _WebHelplinesCard(isDark: isDark),
            const SizedBox(height: _sp12),
            if (PlatformHelper.supportsShake) ...[
              _ShakeCard(isDark: isDark),
              const SizedBox(height: _sp12),
            ],
            _ContactsButton(
              isDark: isDark,
              count: _service.contactCount,
              onTap: () => _pushSetup(ctx),
            ),
          ],
        ),
      ),
      const SizedBox(width: 40),
      Expanded(
        child: _WebScenariosGrid(
          isDark: isDark,
          pulseAnim: _pulseAnim,
          activeSendIndex: _activeSendIndex,
          isSending: _isSending,
          autoScenario: _autoScenario,
          onTap: _triggerSOS,
        ),
      ),
    ],
  );

  Widget _webTabletLayout(BuildContext ctx, bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _WebHero(
        isDark: isDark,
        pulseAnim: _pulseAnim,
        onBack: () => Navigator.pop(ctx),
      ),
      const SizedBox(height: _sp20),
      if (_autoScenario != null) ...[
        _AutoDetectBanner(
          scenario: _autoScenario!,
          isDark: isDark,
          signLabel: widget.detectedSign ?? '',
          onTap: () => _triggerSOS(_kScenarios.indexOf(_autoScenario!)),
        ),
        const SizedBox(height: _sp12),
      ],
      if (_statusMsg != null) ...[
        _StatusBar(message: _statusMsg!, ok: _statusOk, isDark: isDark),
        const SizedBox(height: _sp12),
      ],
      if (!_service.hasContacts) ...[
        _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
        const SizedBox(height: _sp12),
      ],
      _WebScenariosGrid(
        isDark: isDark,
        pulseAnim: _pulseAnim,
        activeSendIndex: _activeSendIndex,
        isSending: _isSending,
        autoScenario: _autoScenario,
        onTap: _triggerSOS,
      ),
      const SizedBox(height: _sp20),
      _WebHelplinesCard(isDark: isDark),
      const SizedBox(height: _sp12),
      if (PlatformHelper.supportsShake) ...[
        _ShakeCard(isDark: isDark),
        const SizedBox(height: _sp12),
      ],
      _ContactsButton(
        isDark: isDark,
        count: _service.contactCount,
        onTap: () => _pushSetup(ctx),
      ),
    ],
  );

  void _pushSetup(BuildContext ctx) => Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => EmergencySetupScreen(
        toggleTheme: widget.toggleTheme,
        setLocale: widget.setLocale,
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 260),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE NAV BAR
//  UX4G: solid border, no blur; danger-accented live dot;
//  48dp minimum height; semantic button for contacts
// ══════════════════════════════════════════════════════════════════════
class _MobileEmergencyBar extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnim;
  final VoidCallback onBack, onContacts;
  const _MobileEmergencyBar({
    required this.isDark,
    required this.pulseAnim,
    required this.onBack,
    required this.onContacts,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final border = isDark ? _dBorder : _lBorder;
    final accent = isDark ? _dangerDark : _danger;
    final navBlue = isDark ? _infoDark : _info;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      padding: const EdgeInsets.fromLTRB(_sp16, _sp12, _sp16, _sp12),
      child: Row(
        children: [
          // Back — semantic button, min 48dp
          Semantics(
            label: l.t('common_back'),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp8,
                  vertical: _sp8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left_rounded, color: navBlue, size: 22),
                    Text(
                      l.t('common_back'),
                      style: _body(15, navBlue, w: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Centre — live dot + title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(pulseAnim.value * 0.55),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: _sp8),
              Text(l.t('sos_screen_title'), style: _heading(16, textClr)),
            ],
          ),
          const Spacer(),
          // Contacts icon — 40dp min
          Semantics(
            label: l.t('sos_setup_title'),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onContacts,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? _dSurface2 : _lSurface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 1),
                ),
                child: Icon(Icons.contacts_rounded, color: subClr, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SCENARIO CARD
//  UX4G: min 48dp, semantic color per scenario, clear icon+number+label,
//  sending state replaces icon with spinner
// ══════════════════════════════════════════════════════════════════════
class _ScenarioCard extends StatefulWidget {
  final _Scenario scenario;
  final bool isDark, isSending, isDisabled, isAutoDetected;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  const _ScenarioCard({
    required this.scenario,
    required this.isDark,
    required this.pulseAnim,
    required this.isSending,
    required this.isDisabled,
    required this.isAutoDetected,
    required this.onTap,
  });
  @override
  State<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<_ScenarioCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.scenario;
    final isDark = widget.isDark;
    final accent = s.accent(isDark);
    final bg = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final border = isDark ? _dBorder : _lBorder;

    // Active / sending state uses accent-tinted surface
    final activeBg = isDark
        ? Color.lerp(_dSurface, accent.withOpacity(0.20), 0.5)!
        : accent.withOpacity(0.06);
    final activeBorder = accent.withOpacity(
      widget.isSending || widget.isAutoDetected ? 0.55 : 0.22,
    );

    return Semantics(
      label: l.t(s.titleKey),
      button: true,
      enabled: !widget.isDisabled,
      child: AnimatedOpacity(
        opacity: widget.isDisabled ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTapDown: (_) {
            if (!widget.isDisabled) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            if (!widget.isDisabled) widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(_sp16),
              decoration: BoxDecoration(
                color: widget.isSending || widget.isAutoDetected
                    ? activeBg
                    : bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSending || widget.isAutoDetected
                      ? activeBorder
                      : border,
                  width: widget.isSending || widget.isAutoDetected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row — icon + helpline badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: widget.isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: accent,
                                  ),
                                )
                              : Icon(s.icon, color: accent, size: 22),
                        ),
                      ),
                      // Helpline number — high contrast, bold
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp8,
                          vertical: _sp4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accent.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          s.helpline,
                          style: _label(12, accent, w: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    widget.isSending ? l.t('sos_sending') : l.t(s.titleKey),
                    style: _label(
                      14,
                      widget.isSending ? accent : textClr,
                      w: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _sp4),
                  // Subtitle
                  Text(
                    widget.isSending
                        ? l.t('sos_send_to_contacts')
                        : l.t(s.subtitleKey),
                    style: _body(11, subClr),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
  const _WebHero({
    required this.isDark,
    required this.pulseAnim,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _dangerDark : _danger;
    final navBlue = isDark ? _infoDark : _info;

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back breadcrumb
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _sp4,
                horizontal: _sp4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, color: navBlue, size: 20),
                  Text(
                    l.t('sos_setup_back'),
                    style: _body(14, navBlue, w: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _sp20),

          // Live status badge (UX4G: dot + label in danger color)
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _sp12,
                vertical: _sp8,
              ),
              decoration: BoxDecoration(
                color: isDark ? _dangerDark.withOpacity(0.12) : _dangerLight,
                borderRadius: BorderRadius.circular(6),
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
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(pulseAnim.value * 0.55),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _sp8),
                  Text(
                    l.t('sos_screen_badge_web'),
                    style: _label(11, accent, w: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _sp16),
          Text(l.t('sos_screen_title'), style: _display(32, textClr)),
          const SizedBox(height: _sp8),
          Text(l.t('sos_screen_subtitle_mobile'), style: _body(14, subClr)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB SCENARIOS GRID
// ══════════════════════════════════════════════════════════════════════
class _WebScenariosGrid extends StatelessWidget {
  final bool isDark, isSending;
  final Animation<double> pulseAnim;
  final int? activeSendIndex;
  final _Scenario? autoScenario;
  final void Function(int) onTap;
  const _WebScenariosGrid({
    required this.isDark,
    required this.pulseAnim,
    required this.activeSendIndex,
    required this.isSending,
    required this.autoScenario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: _sp12,
    crossAxisSpacing: _sp12,
    childAspectRatio: 1.25,
    children: _kScenarios
        .asMap()
        .entries
        .map(
          (e) => _ScenarioCard(
            scenario: e.value,
            isDark: isDark,
            pulseAnim: pulseAnim,
            isSending: isSending && activeSendIndex == e.key,
            isDisabled: isSending && activeSendIndex != e.key,
            isAutoDetected: autoScenario == e.value,
            onTap: () => onTap(e.key),
          ),
        )
        .toList(),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  WEB HELPLINES CARD
//  UX4G: large numbers, semantic color per service, accessible labels
// ══════════════════════════════════════════════════════════════════════
class _WebHelplinesCard extends StatelessWidget {
  final bool isDark;
  const _WebHelplinesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      ('112', l.t('sos_label_emergency'), isDark ? _dangerDark : _danger),
      ('108', l.t('sos_label_ambulance'), isDark ? _scOrangeD : _scOrange),
      ('100', l.t('sos_label_police'), isDark ? _infoDark : _info),
      ('101', l.t('sos_label_fire'), isDark ? _scAmberD : _scAmber),
    ];
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final sep = isDark ? _dBorderSub : _lBorderSub;
    final sub = isDark ? _dTextSub : _lTextSub;

    return Semantics(
      label: l.t('sos_helpline_ref'),
      child: Container(
        padding: const EdgeInsets.all(_sp16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('sos_helpline_ref').toUpperCase(),
              style: _label(10, sub, w: FontWeight.w700),
            ),
            const SizedBox(height: _sp12),
            IntrinsicHeight(
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            items[i].$1,
                            style: _heading(
                              20,
                              items[i].$3,
                              w: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: _sp4),
                          Text(
                            items[i].$2,
                            style: _body(11, sub),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1) Container(width: 1, color: sep),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ══════════════════════════════════════════════════════════════════════

// ── Auto-detect banner ────────────────────────────────────────────────
class _AutoDetectBanner extends StatelessWidget {
  final _Scenario scenario;
  final bool isDark;
  final String signLabel;
  final VoidCallback onTap;
  const _AutoDetectBanner({
    required this.scenario,
    required this.isDark,
    required this.signLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = scenario.accent(isDark);
    final textClr = isDark ? _dText : _lText;
    final bg = isDark ? _dSurface : _lSurface;

    return Semantics(
      label: l.t('sos_isl_detected').replaceAll('{sign}', signLabel),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_sp16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(scenario.icon, color: accent, size: 22),
              ),
              const SizedBox(width: _sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('sos_isl_detected').replaceAll('{sign}', signLabel),
                      style: _label(10.5, accent, w: FontWeight.w700),
                    ),
                    const SizedBox(height: _sp4),
                    Text(
                      l
                          .t('sos_isl_suggested')
                          .replaceAll('{type}', l.t(scenario.titleKey)),
                      style: _heading(14, textClr),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status bar ────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final String message;
  final bool ok, isDark;
  const _StatusBar({
    required this.message,
    required this.ok,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? (isDark ? _successDark : _success)
        : (isDark ? _dangerDark : _danger);
    final bgClr = ok
        ? (isDark ? _successDark.withOpacity(0.12) : _successLight)
        : (isDark ? _dangerDark.withOpacity(0.12) : _dangerLight);
    final borderClr = ok
        ? (isDark ? _successDark.withOpacity(0.30) : _success.withOpacity(0.30))
        : (isDark ? _dangerDark.withOpacity(0.30) : _danger.withOpacity(0.30));
    final icon = ok ? Icons.check_circle_rounded : Icons.error_outline_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 6),
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _sp16,
            vertical: _sp12,
          ),
          decoration: BoxDecoration(
            color: bgClr,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderClr, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: _sp12),
              Expanded(
                child: Text(
                  message,
                  style: _body(13, color, w: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No contacts banner — warning style ───────────────────────────────
class _NoContactsBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _NoContactsBanner({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final amber = isDark ? _warningDark : _warning;
    final bgClr = isDark ? _warningDark.withOpacity(0.12) : _warningLight;
    final border = isDark
        ? _warningDark.withOpacity(0.30)
        : _warning.withOpacity(0.30);

    return Semantics(
      label: l.t('sos_no_contacts_title'),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_sp12),
          decoration: BoxDecoration(
            color: bgClr,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: amber, size: 18),
              const SizedBox(width: _sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('sos_no_contacts_title'),
                      style: _label(12, amber, w: FontWeight.w700),
                    ),
                    const SizedBox(height: _sp4),
                    Text(l.t('sos_no_contacts_body'), style: _body(11, amber)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: amber, size: 18),
            ],
          ),
        ),
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
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _infoDark : _info;

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.vibration_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: _sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('sos_shake_title'),
                  style: _label(14, textClr, w: FontWeight.w700),
                ),
                const SizedBox(height: _sp4),
                Text(l.t('sos_shake_body'), style: _body(12, subClr)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacts button ───────────────────────────────────────────────────
class _ContactsButton extends StatefulWidget {
  final bool isDark;
  final int count;
  final VoidCallback onTap;
  const _ContactsButton({
    required this.isDark,
    required this.count,
    required this.onTap,
  });
  @override
  State<_ContactsButton> createState() => _ContactsButtonState();
}

class _ContactsButtonState extends State<_ContactsButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = widget.isDark ? _dSurface : _lSurface;
    final bgHov = widget.isDark ? _dSurface2 : _lSurface2;
    final border = widget.isDark ? _dBorder : _lBorder;
    final textClr = widget.isDark ? _dText : _lText;
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    final accent = widget.isDark ? _infoDark : _info;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.count > 0
            ? l.t('sos_view_contacts')
            : l.t('sos_setup_contacts'),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: _sp16,
              vertical: _sp12,
            ),
            decoration: BoxDecoration(
              color: _hovered ? bgHov : bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? accent.withOpacity(0.35) : border,
                width: _hovered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.contacts_rounded, color: accent, size: 18),
                const SizedBox(width: _sp12),
                Expanded(
                  child: Text(
                    widget.count > 0
                        ? ((widget.count == 1
                                  ? l.t('sos_contacts_configured')
                                  : l.t('sos_contacts_plural'))
                              .replaceAll('{n}', '${widget.count}'))
                        : l.t('sos_setup_contacts'),
                    style: _body(
                      13,
                      widget.count > 0 ? textClr : subClr,
                      w: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: subClr, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile helplines row ──────────────────────────────────────────────
class _MobileHelplinesRow extends StatelessWidget {
  final bool isDark;
  const _MobileHelplinesRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      ('112', 'Emergency', isDark ? _dangerDark : _danger),
      ('108', 'Ambulance', isDark ? _scOrangeD : _scOrange),
      ('100', 'Police', isDark ? _infoDark : _info),
      ('101', 'Fire', isDark ? _scAmberD : _scAmber),
    ];
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final sep = isDark ? _dBorderSub : _lBorderSub;
    final sub = isDark ? _dTextSub : _lTextSub;

    return Semantics(
      label: l.t('sos_helpline_ref'),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: _sp16),
                  decoration: BoxDecoration(
                    border: i < items.length - 1
                        ? Border(right: BorderSide(color: sep, width: 1))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$1,
                        style: _heading(18, item.$3, w: FontWeight.w700),
                      ),
                      const SizedBox(height: _sp4),
                      Text(
                        item.$2,
                        style: _body(10, sub),
                        textAlign: TextAlign.center,
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

// ── UX4G section label ────────────────────────────────────────────────
class _UX4GSectionLabel extends StatelessWidget {
  final String label, sub;
  final bool isDark;
  const _UX4GSectionLabel({
    required this.label,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _label(
            10.5,
            isDark ? _dTextMuted : _lTextMuted,
            w: FontWeight.w700,
          ),
        ),
        const SizedBox(height: _sp4),
        Text(sub, style: _body(12, isDark ? _dTextSub : _lTextSub)),
      ],
    ),
  );
}
