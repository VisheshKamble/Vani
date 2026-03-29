// lib/screens/EmergencyScreen.dart
//
// ╔══════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Screen  · Apple-Inspired Premium UI  ║
// ║  Font: Google Sans (SF Pro equivalent)                 ║
// ║  < 700px  → iOS native emergency shell                 ║
// ║  ≥ 700px  → macOS/web emergency centre                 ║
// ╚══════════════════════════════════════════════════════════╝

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

// ─────────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _red = Color(0xFFFF3B30);
const _red_D = Color(0xFFFF453A);
const _orange = Color(0xFFFF9500);
const _orange_D = Color(0xFFFF9F0A);
const _blue = Color(0xFF007AFF);
const _blue_D = Color(0xFF0A84FF);
const _green = Color(0xFF34C759);
const _green_D = Color(0xFF30D158);
const _indigo = Color(0xFF5856D6);
const _indigo_D = Color(0xFF5E5CE6);
const _teal = Color(0xFF32ADE6);
const _teal_D = Color(0xFF5AC8F5);
const _purple = Color(0xFFAF52DE);
const _purple_D = Color(0xFFBF5AF2);
const _amber = Color(0xFFFF9500); // same as orange
const _amber_D = Color(0xFFFF9F0A);

// Light surfaces
const _lBg = Color(0xFFF2F2F7);
const _lSurface = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFEFEFF4);
const _lSep = Color(0xFFC6C6C8);
const _lLabel = Color(0xFF000000);
const _lLabel2 = Color(0x993C3C43);
const _lLabel3 = Color(0x4D3C3C43);
const _lFill = Color(0x1F787880);

// Dark surfaces
const _dBg = Color(0xFF000000);
const _dSurface = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dSep = Color(0xFF38383A);
const _dLabel = Color(0xFFFFFFFF);
const _dLabel2 = Color(0x99EBEBF5);
const _dLabel3 = Color(0x4DEBEBF5);
const _dFill = Color(0x3A787880);

TextStyle _t(double size, FontWeight w, Color c, {double ls = 0, double? h}) =>
    TextStyle(
      fontFamily: 'Google Sans',
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
      height: h,
    );

// ─────────────────────────────────────────────────────────────
//  SCENARIO MODEL
// ─────────────────────────────────────────────────────────────
class _Scenario {
  final SOSMessageType type;
  final IconData icon;
  final String titleKey,
      subtitleKey,
      signHint,
      helpline,
      helplineName,
      smsTemplate;
  final Color accentLight, accentDark;
  const _Scenario({
    required this.type,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.signHint,
    required this.helpline,
    required this.helplineName,
    required this.smsTemplate,
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
    accentLight: _red,
    accentDark: _red_D,
    smsTemplate:
        'URGENT — EMERGENCY ALERT\n\n'
        'Sent via VANI. The sender is DEAF or MUTE and cannot call for help.\n\n'
        'Actions:\n  1. Call them back.\n  2. Go to their location.\n  3. Dial 112.\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
  _Scenario(
    type: SOSMessageType.medical,
    icon: Icons.medical_services_rounded,
    titleKey: 'sos_medical_title',
    subtitleKey: 'sos_medical_sub',
    signHint: 'sos_sign_doctor',
    helpline: '108',
    helplineName: 'sos_helpline_ambulance',
    accentLight: _orange,
    accentDark: _orange_D,
    smsTemplate:
        'URGENT — MEDICAL EMERGENCY\n\n'
        'Sent via VANI. Sender is DEAF or MUTE — cannot call verbally.\n\n'
        'Actions:\n  1. Dial 108 (ambulance).\n  2. Go to their location.\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
  _Scenario(
    type: SOSMessageType.police,
    icon: Icons.shield_rounded,
    titleKey: 'sos_police_title',
    subtitleKey: 'sos_police_sub',
    signHint: 'sos_sign_strong',
    helpline: '100',
    helplineName: 'sos_helpline_police',
    accentLight: _blue,
    accentDark: _blue_D,
    smsTemplate:
        'URGENT — SAFETY EMERGENCY\n\n'
        'Sent via VANI. Sender is DEAF or MUTE — cannot call police verbally.\n\n'
        'Actions:\n  1. Dial 100 (police).\n  2. Go to their location.\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
  _Scenario(
    type: SOSMessageType.fire,
    icon: Icons.local_fire_department_rounded,
    titleKey: 'sos_fire_title',
    subtitleKey: 'sos_fire_sub',
    signHint: 'sos_sign_help_bad',
    helpline: '101',
    helplineName: 'sos_helpline_fire',
    accentLight: _amber,
    accentDark: _amber_D,
    smsTemplate:
        'URGENT — FIRE / SMOKE EMERGENCY\n\n'
        'Sent via VANI. Sender is DEAF or MUTE — cannot call fire brigade verbally.\n\n'
        'Actions:\n  1. Dial 101 (fire).\n  2. Evacuate the area.\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
  _Scenario(
    type: SOSMessageType.custom,
    icon: Icons.directions_car_rounded,
    titleKey: 'sos_accident_title',
    subtitleKey: 'sos_accident_sub',
    signHint: 'sos_sign_bad_sorry',
    helpline: '1033',
    helplineName: 'sos_helpline_highway',
    accentLight: _purple,
    accentDark: _purple_D,
    smsTemplate:
        'URGENT — ROAD ACCIDENT\n\n'
        'Sent via VANI. Sender is DEAF or MUTE.\n\n'
        'Actions:\n  1. Dial 108 (ambulance).\n  2. Dial 1033 (highway).\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
  _Scenario(
    type: SOSMessageType.custom,
    icon: Icons.child_care_rounded,
    titleKey: 'sos_child_title',
    subtitleKey: 'sos_child_sub',
    signHint: 'sos_sign_mother',
    helpline: '1098',
    helplineName: 'sos_helpline_childline',
    accentLight: _teal,
    accentDark: _teal_D,
    smsTemplate:
        'URGENT — CHILD SAFETY ALERT\n\n'
        'Sent via VANI. Sender is DEAF or MUTE.\n\n'
        'Actions:\n  1. Dial 1098 (Childline).\n  2. Dial 100 (police).\n\n'
        'Location: {LOCATION}\nTime: {TIME}\n\n— VANI Emergency SOS',
  ),
];

// ══════════════════════════════════════════════════════════════
//  EMERGENCY SCREEN
// ══════════════════════════════════════════════════════════════
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

  // ── Hive box listener ──────────────────────
  late final Box<EmergencyContact> _contactBox;

  void _onContactsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _service.updateContext(context);

    // Listen to Hive box so UI rebuilds after sync on login
    _contactBox = Hive.box<EmergencyContact>('emergency_contacts');
    _contactBox.listenable().addListener(_onContactsChanged);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
      customMessage: _kScenarios[idx].smsTemplate,
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

  // ════════════════════════════════════════════
  //  MOBILE  (<700px)  — iOS emergency style
  //  Compact nav bar, 2-col scenario grid,
  //  helplines pill row, shake card at bottom.
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Mobile nav bar ───────────────────
            _MobileEmergencyBar(
              isDark: isDark,
              pulseAnim: _pulseAnim,
              onBack: () => Navigator.pop(ctx),
              onContacts: () => Navigator.push(
                ctx,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EmergencySetupScreen(
                    toggleTheme: widget.toggleTheme,
                    setLocale: widget.setLocale,
                  ),
                  transitionsBuilder: (_, a, __, c) =>
                      FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 260),
                ),
              ),
            ),

            // ── Scrollable body ──────────────────
            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
                          const SizedBox(height: 12),
                        ],

                        // Status bar
                        if (_statusMsg != null) ...[
                          _StatusBar(
                            message: _statusMsg!,
                            ok: _statusOk,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // No contacts warning
                        if (!_service.hasContacts) ...[
                          _NoContactsBanner(
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              ctx,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    EmergencySetupScreen(
                                      toggleTheme: widget.toggleTheme,
                                      setLocale: widget.setLocale,
                                    ),
                                transitionsBuilder: (_, a, __, c) =>
                                    FadeTransition(opacity: a, child: c),
                                transitionDuration: const Duration(
                                  milliseconds: 260,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Section label
                        _MobileSectionLabel(
                          label: l.t('sos_screen_title').toUpperCase(),
                          sub: l.t('sos_screen_subtitle_mobile'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // 2-col grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.10,
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

                        const SizedBox(height: 22),

                        // Helplines section
                        _MobileSectionLabel(
                          label: l.t('sos_helpline_ref').toUpperCase(),
                          sub: l.t('sos_setup_contacts'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _MobileHelplinesRow(isDark: isDark),

                        const SizedBox(height: 16),

                        // Shake card
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

  // ════════════════════════════════════════════
  //  WEB / TABLET  (≥700px)
  // ════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 96.0 : 52.0;
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Subtle ambient glow — barely visible, premium not flashy
          Positioned(
            top: -200,
            left: w * 0.1,
            child: _AmbientGlow(
              color: (isDark ? _red_D : _red).withOpacity(0.06),
              size: 500,
            ),
          ),
          SafeArea(
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
                        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 64),
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
        ],
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left — info + utilities
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
            const SizedBox(height: 20),
            if (_autoScenario != null) ...[
              _AutoDetectBanner(
                scenario: _autoScenario!,
                isDark: isDark,
                signLabel: widget.detectedSign ?? '',
                onTap: () => _triggerSOS(_kScenarios.indexOf(_autoScenario!)),
              ),
              const SizedBox(height: 12),
            ],
            if (_statusMsg != null) ...[
              _StatusBar(message: _statusMsg!, ok: _statusOk, isDark: isDark),
              const SizedBox(height: 12),
            ],
            if (!_service.hasContacts) ...[
              _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
              const SizedBox(height: 12),
            ],
            _WebHelplinesCard(isDark: isDark),
            const SizedBox(height: 12),
            if (PlatformHelper.supportsShake) ...[
              _ShakeCard(isDark: isDark),
              const SizedBox(height: 12),
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
      // Right — scenario grid
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
      const SizedBox(height: 20),
      if (_autoScenario != null) ...[
        _AutoDetectBanner(
          scenario: _autoScenario!,
          isDark: isDark,
          signLabel: widget.detectedSign ?? '',
          onTap: () => _triggerSOS(_kScenarios.indexOf(_autoScenario!)),
        ),
        const SizedBox(height: 12),
      ],
      if (_statusMsg != null) ...[
        _StatusBar(message: _statusMsg!, ok: _statusOk, isDark: isDark),
        const SizedBox(height: 12),
      ],
      if (!_service.hasContacts) ...[
        _NoContactsBanner(isDark: isDark, onTap: () => _pushSetup(ctx)),
        const SizedBox(height: 12),
      ],
      _WebScenariosGrid(
        isDark: isDark,
        pulseAnim: _pulseAnim,
        activeSendIndex: _activeSendIndex,
        isSending: _isSending,
        autoScenario: _autoScenario,
        onTap: _triggerSOS,
      ),
      const SizedBox(height: 20),
      _WebHelplinesCard(isDark: isDark),
      const SizedBox(height: 12),
      if (PlatformHelper.supportsShake) ...[
        _ShakeCard(isDark: isDark),
        const SizedBox(height: 12),
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

// ══════════════════════════════════════════════════════════════
//  MOBILE NAV BAR
// ══════════════════════════════════════════════════════════════
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
    final label = isDark ? _dLabel : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final sep = isDark ? _dSep : _lSep.withOpacity(0.5);
    final accent = isDark ? _red_D : _red;
    final blueA = isDark ? _blue_D : _blue;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: sep, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left_rounded, color: blueA, size: 28),
                Text(l.t('common_back'), style: _t(15, FontWeight.w400, blueA)),
              ],
            ),
          ),
          const Spacer(),
          // Centre — title with live dot
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(pulseAnim.value * 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.t('sos_screen_title'),
                style: _t(16, FontWeight.w600, label, ls: -0.2),
              ),
            ],
          ),
          const Spacer(),
          // Contacts icon
          GestureDetector(
            onTap: onContacts,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? _dFill : _lFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.contacts_rounded, color: label2, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SCENARIO CARD  — the core UI unit
// ══════════════════════════════════════════════════════════════
class _ScenarioCard extends StatefulWidget {
  final _Scenario scenario;
  final bool isDark;
  final Animation<double> pulseAnim;
  final bool isSending, isDisabled, isAutoDetected;
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

class _ScenarioCardState extends State<_ScenarioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hCtrl;
  late Animation<double> _hAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _hAnim = CurvedAnimation(parent: _hCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.scenario;
    final isDark = widget.isDark;
    final accent = s.accent(isDark);
    final bg = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled) _hCtrl.forward();
      },
      onExit: (_) => _hCtrl.reverse(),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isDisabled) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!widget.isDisabled) widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _hAnim,
          builder: (_, __) {
            final hv = _hAnim.value;
            final elevated =
                widget.isSending || widget.isAutoDetected || hv > 0.1;
            return AnimatedScale(
              scale: _pressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: widget.isDisabled ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevated
                        ? Color.lerp(
                            bg,
                            accent.withOpacity(0.08),
                            hv.clamp(0.0, 1.0),
                          )
                        : bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: elevated
                          ? accent.withOpacity(
                              widget.isSending || widget.isAutoDetected
                                  ? 0.40
                                  : hv * 0.30,
                            )
                          : Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                      width: (widget.isSending || widget.isAutoDetected)
                          ? 1.0
                          : 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
                        blurRadius: elevated ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                      if (elevated)
                        BoxShadow(
                          color: accent.withOpacity(isDark ? 0.12 : 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                    ],
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
                          // Icon container
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: widget.isSending
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accent,
                                      ),
                                    )
                                  : Icon(s.icon, color: accent, size: 20),
                            ),
                          ),
                          // Helpline number badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.helpline,
                              style: _t(11, FontWeight.w700, accent),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        widget.isSending ? l.t('sos_sending') : l.t(s.titleKey),
                        style: _t(
                          14,
                          FontWeight.w600,
                          widget.isSending ? accent : label,
                          ls: -0.2,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtitle
                      Text(
                        widget.isSending
                            ? l.t('sos_send_to_contacts')
                            : l.t(s.subtitleKey),
                        style: _t(
                          10.5,
                          FontWeight.w400,
                          widget.isSending ? accent.withOpacity(0.6) : label2,
                          h: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ISL sign hint — shown on hover / auto-detected
                      if (widget.isAutoDetected || hv > 0.3) ...[
                        const SizedBox(height: 6),
                        AnimatedOpacity(
                          opacity: widget.isAutoDetected ? 1.0 : hv,
                          duration: const Duration(milliseconds: 130),
                          child: Text(
                            l.t(s.signHint),
                            style: _t(
                              9,
                              FontWeight.w600,
                              accent.withOpacity(0.70),
                              ls: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB COMPONENTS
// ══════════════════════════════════════════════════════════════

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
    final label = isDark ? _dLabel : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final accent = isDark ? _red_D : _red;
    final blueA = isDark ? _blue_D : _blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back breadcrumb
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded, color: blueA, size: 20),
              Text(
                l.t('sos_setup_back'),
                style: _t(14, FontWeight.w400, blueA),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live status badge
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.18), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(pulseAnim.value * 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.t('sos_screen_badge_web'),
                  style: _t(10, FontWeight.w700, accent, ls: 1.0),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          l.t('sos_screen_title'),
          style: _t(36, FontWeight.w700, label, ls: -1.0, h: 1.08),
        ),

        const SizedBox(height: 10),

        Text(
          l.t('sos_screen_subtitle_mobile'),
          style: _t(14, FontWeight.w400, label2, ls: -0.1, h: 1.65),
        ),
      ],
    );
  }
}

class _WebScenariosGrid extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnim;
  final int? activeSendIndex;
  final bool isSending;
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
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.30,
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
}

class _WebHelplinesCard extends StatelessWidget {
  final bool isDark;
  const _WebHelplinesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      ('112', 'Emergency', isDark ? _red_D : _red),
      ('108', 'Ambulance', isDark ? _orange_D : _orange),
      ('100', 'Police', isDark ? _blue_D : _blue),
      ('101', 'Fire', isDark ? _amber_D : _amber),
    ];
    final bg = isDark ? _dSurface : _lSurface;
    final sub = isDark ? _dLabel2 : _lLabel2;
    final sep = isDark ? _dSep : _lSep.withOpacity(0.4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('sos_helpline_ref').toUpperCase(),
            style: _t(10, FontWeight.w600, sub, ls: 0.8),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          items[i].$1,
                          style: _t(18, FontWeight.w700, items[i].$3, ls: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: _t(10, FontWeight.w400, sub),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1) Container(width: 0.5, color: sep),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED COMPONENTS  (mobile + web)
// ══════════════════════════════════════════════════════════════

// ── Auto-detect banner ────────────────────────────────────────
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
    final label = isDark ? _dLabel : _lLabel;
    final bg = isDark ? _dSurface : _lSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.30), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.10 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(scenario.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('sos_isl_detected').replaceAll('{sign}', signLabel),
                    style: _t(10, FontWeight.w600, accent, ls: 0.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l
                        .t('sos_isl_suggested')
                        .replaceAll('{type}', l.t(scenario.titleKey)),
                    style: _t(13, FontWeight.w600, label, ls: -0.2),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Status bar ────────────────────────────────────────────────
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
    final color = ok ? (isDark ? _green_D : _green) : (isDark ? _red_D : _red);
    final icon = ok ? Icons.check_circle_rounded : Icons.error_outline_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 8),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: _t(13, FontWeight.w500, color, h: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No contacts banner ────────────────────────────────────────
class _NoContactsBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _NoContactsBanner({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final amber = isDark ? _amber_D : _amber;
    final bg = isDark ? _dSurface : _lSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: amber.withOpacity(0.25), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: amber, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('sos_no_contacts_title'),
                    style: _t(12, FontWeight.w600, amber),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.t('sos_no_contacts_body'),
                    style: _t(
                      11,
                      FontWeight.w400,
                      amber.withOpacity(0.70),
                      h: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: amber, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Shake card ────────────────────────────────────────────────
class _ShakeCard extends StatelessWidget {
  final bool isDark;
  const _ShakeCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final accent = isDark ? _indigo_D : _indigo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.vibration_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('sos_shake_title'),
                  style: _t(13.5, FontWeight.w600, label, ls: -0.2),
                ),
                const SizedBox(height: 2),
                Text(
                  l.t('sos_shake_body'),
                  style: _t(12, FontWeight.w400, label2, h: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacts button ───────────────────────────────────────────
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
    final label = widget.isDark ? _dLabel : _lLabel;
    final sub = widget.isDark ? _dLabel2 : _lLabel2;
    final sep = widget.isDark ? _dSep : _lSep.withOpacity(0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered ? (widget.isDark ? _dSurface2 : _lSurface2) : bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? sep
                  : Colors.black.withOpacity(widget.isDark ? 0.0 : 0.04),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.contacts_rounded,
                color: widget.isDark ? _blue_D : _blue,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.count > 0
                      ? ((widget.count == 1
                                ? l.t('sos_contacts_configured')
                                : l.t('sos_contacts_plural'))
                            .replaceAll('{n}', '${widget.count}'))
                      : l.t('sos_setup_contacts'),
                  style: _t(
                    13,
                    FontWeight.w500,
                    widget.count > 0 ? label : sub,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: sub, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile helplines row ──────────────────────────────────────
class _MobileHelplinesRow extends StatelessWidget {
  final bool isDark;
  const _MobileHelplinesRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('112', 'Emergency', isDark ? _red_D : _red),
      ('108', 'Ambulance', isDark ? _orange_D : _orange),
      ('100', 'Police', isDark ? _blue_D : _blue),
      ('101', 'Fire', isDark ? _amber_D : _amber),
    ];
    final bg = isDark ? _dSurface : _lSurface;
    final sub = isDark ? _dLabel2 : _lLabel2;

    return Row(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item.$1,
                    style: _t(17, FontWeight.w700, item.$3, ls: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(item.$2, style: _t(9, FontWeight.w400, sub)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mobile section label ──────────────────────────────────────
class _MobileSectionLabel extends StatelessWidget {
  final String label, sub;
  final bool isDark;
  const _MobileSectionLabel({
    required this.label,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: _t(10, FontWeight.w600, isDark ? _dLabel3 : _lLabel3, ls: 0.6),
      ),
      const SizedBox(height: 2),
      Text(sub, style: _t(12, FontWeight.w400, isDark ? _dLabel2 : _lLabel2)),
    ],
  );
}

// ── Ambient glow ──────────────────────────────────────────────
class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: const SizedBox.expand(),
    ),
  );
}
