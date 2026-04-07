// lib/components/GlobalNavbar.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Global Navbar  · Premium Fintech Redesign v4               ║
// ║                                                                    ║
// ║  Design: Deep-space glass · Electric Indigo · Formal & Precise     ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║                                                                    ║
// ║  Key design moves:                                                 ║
// ║  · Glassmorphism pill with frosted-glass backdrop                 ║
// ║  · Gradient brand accent line                                     ║
// ║  · Smooth animated active underline (180ms easeOut)               ║
// ║  · SOS with dual-ring pulse animation                             ║
// ║  · Hover: text color + weight change + glow shadow                ║
// ║  · Min 44dp touch targets, WCAG AA contrast, Semantics()          ║
// ╚══════════════════════════════════════════════════════════════════════╝

// ignore_for_file: unused_element, unused_local_variable, unused_field

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/TranslateScreen.dart';
import '../screens/Signspage.dart';
import '../screens/EmergencyScreen.dart';
import '../screens/TwoWayScreen.dart';
import '../screens/ISLAssistantScreen.dart';
import '../l10n/AppLocalizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/EmergencyContact.dart';

// ─────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

// Primary accent — electric indigo
const _navIndigo   = Color(0xFF5463FF);
const _navIndigoDk = Color(0xFF7A87FF);

// Semantic nav accents
const _navPrimary    = Color(0xFF1A56DB);
const _navPrimaryD   = Color(0xFF5B8BFF);
const _navSecondary  = Color(0xFF0CA5A5);
const _navSecondaryD = Color(0xFF2DD4BF);
const _navDanger     = Color(0xFFDC2626);
const _navDangerD    = Color(0xFFF87171);
const _navInfo       = Color(0xFF6D28D9);
const _navInfoD      = Color(0xFFA78BFA);

// Dark surfaces
const _dBg       = Color(0xFF06091A);
const _dSurface  = Color(0xFF0B0F24);
const _dSurface2 = Color(0xFF111627);
const _dBorder   = Color(0xFF1C2845);
const _dBorderH  = Color(0xFF283B60);
const _dText     = Color(0xFFECF0FF);
const _dTextSub  = Color(0xFF8B9CC0);
const _dTextMuted = Color(0xFF4A5275);

// Light surfaces
const _lBg       = Color(0xFFF5F7FE);
const _lSurface  = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFEEF2FF);
const _lBorder   = Color(0xFFDAE0F0);
const _lText     = Color(0xFF08091C);
const _lTextSub  = Color(0xFF364060);
const _lTextMuted = Color(0xFF8890B0);

const _sp4  = 4.0;
const _sp6  = 6.0;
const _sp8  = 8.0;
const _sp10 = 10.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;

TextStyle _label(double sz, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: sz, fontWeight: w,
        color: c, height: 1.4, letterSpacing: 0.1);

TextStyle _body(double sz, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: sz, fontWeight: w,
        color: c, height: 1.6);

const double _kDesktopBreak = 750;

// ══════════════════════════════════════════════════════════════════════
//  GLOBAL NAVBAR
// ══════════════════════════════════════════════════════════════════════
class GlobalNavbar extends StatelessWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  final String           activeRoute;

  const GlobalNavbar({super.key,
    required this.toggleTheme,
    required this.setLocale,
    required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final l       = AppLocalizations.of(context);
    final w       = MediaQuery.of(context).size.width;
    final locale  = Localizations.localeOf(context);
    final mobile  = w <= _kDesktopBreak;

    final hMargin  = mobile ? 12.0 : (w > 900 ? 48.0 : 16.0);
    final vPadH    = mobile ? 10.0 : 18.0;
    final vPadV    = mobile ? 10.0 : 13.0;

    return Semantics(
      label: AppLocalizations.of(context).t('common_navigation_bar'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: mobile ? 8 : 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(mobile ? 14 : 18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: vPadH, vertical: vPadV),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0A1024).withOpacity(0.94),
                          const Color(0xFF111827).withOpacity(0.90),
                          const Color(0xFF0B0F24).withOpacity(0.95),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.98),
                          const Color(0xFFF5F8FF).withOpacity(0.96),
                          const Color(0xFFEFF4FF).withOpacity(0.94),
                        ],
                ),
                borderRadius: BorderRadius.circular(mobile ? 14 : 18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1C2845).withOpacity(0.82)
                      : const Color(0xFFDAE0F0).withOpacity(0.95),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF5463FF).withOpacity(0.10)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 38,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Brand(isDark: isDark),
                      if (mobile)
                        _MobileActions(
                            activeRoute: activeRoute,
                            toggleTheme: toggleTheme,
                            setLocale: setLocale,
                            currentLocale: locale,
                            isDark: isDark,
                            primary: primary,
                            l: l)
                      else
                        _DesktopActions(
                            activeRoute: activeRoute,
                            toggleTheme: toggleTheme,
                            setLocale: setLocale,
                            currentLocale: locale,
                            isDark: isDark,
                            primary: primary,
                            l: l),
                    ],
                  ),
                  SizedBox(height: mobile ? 6 : 8),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _navIndigo.withOpacity(0.0),
                          _navIndigo.withOpacity(isDark ? 0.22 : 0.14),
                          _navSecondary.withOpacity(isDark ? 0.18 : 0.10),
                          _navIndigo.withOpacity(0.0),
                        ],
                      ),
                    ),
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
//  BRAND
// ══════════════════════════════════════════════════════════════════════
class _Brand extends StatelessWidget {
  final bool isDark;
  const _Brand({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? _navIndigoDk : _navIndigo;
    final textClr = isDark ? _dText       : _lText;

    return Semantics(
      label: AppLocalizations.of(context).t('app_title_short'), button: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Gradient accent bar
          Container(
            width: 4, height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, accent.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(
                color: accent.withOpacity(0.55),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )],
            ),
          ),
          const SizedBox(width: _sp10),
          Text('VANI',
              style: _label(18, textClr, w: FontWeight.w800)
                  .copyWith(letterSpacing: 3.5)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  DESKTOP ACTIONS
// ══════════════════════════════════════════════════════════════════════
class _DesktopActions extends StatefulWidget {
  final String activeRoute;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final Locale currentLocale;
  final bool isDark;
  final Color primary;
  final AppLocalizations l;

  const _DesktopActions({
    required this.activeRoute, required this.toggleTheme,
    required this.setLocale, required this.currentLocale,
    required this.isDark, required this.primary, required this.l,
  });

  @override
  State<_DesktopActions> createState() => _DesktopActionsState();
}

class _DesktopActionsState extends State<_DesktopActions> {
  late bool _isLoggedIn;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
            (data) { if (mounted) setState(() => _isLoggedIn = data.session != null); });
  }

  @override
  void dispose() { _authSub.cancel(); super.dispose(); }

  void _push(BuildContext ctx, Widget screen) => Navigator.push(ctx,
      PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 260)));

  Future<void> _logout(BuildContext ctx) async {
    try { final box = Hive.box<EmergencyContact>('emergency_contacts'); await box.clear(); } catch (_) {}
    await Supabase.instance.client.auth.signOut();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(widget.l.t('menu_signed_out'),
              style: _body(13, Colors.white, w: FontWeight.w500)),
          backgroundColor: widget.isDark ? _dSurface2 : _lText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final accent = widget.isDark ? _navIndigoDk : _navIndigo;
    final teal   = widget.isDark ? _navSecondaryD : _navSecondary;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      _NavLink(label: widget.l.t('nav_home'),
          isDark: widget.isDark, accent: accent,
          isActive: widget.activeRoute == 'home',
          onTap: () => Navigator.of(ctx).popUntil((r) => r.isFirst)),
      _NavLink(label: widget.l.t('nav_terminal'),
          isDark: widget.isDark, accent: accent,
          isActive: widget.activeRoute == 'translate',
          onTap: () { if (widget.activeRoute != 'translate')
            _push(ctx, TranslateScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)); }),
      _NavLink(label: widget.l.t('nav_signs'),
          isDark: widget.isDark, accent: widget.isDark ? _navInfoD : _navInfo,
          isActive: widget.activeRoute == 'signs',
          onTap: () { if (widget.activeRoute != 'signs')
            _push(ctx, SignsPage(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)); }),
      _NavLink(label: widget.l.t('nav_bridge'),
          isDark: widget.isDark, accent: teal,
          isActive: widget.activeRoute == 'bridge',
          onTap: () { if (widget.activeRoute != 'bridge')
            _push(ctx, TwoWayScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)); }),
      _SOSNavLink(label: widget.l.t('nav_emergency'),
          isDark: widget.isDark,
          isActive: widget.activeRoute == 'emergency',
          onTap: () { if (widget.activeRoute != 'emergency')
            _push(ctx, EmergencyScreen(toggleTheme: widget.toggleTheme, setLocale: widget.setLocale)); }),
      _NavLink(label: widget.l.t('assistant_tab_label'),
          isDark: widget.isDark,
          accent: widget.isDark ? _navInfoD : _navInfo,
          isActive: widget.activeRoute == 'assistant',
          onTap: () => _push(ctx, ISLAssistantScreen(
              toggleTheme: widget.toggleTheme, setLocale: widget.setLocale))),
      if (_isLoggedIn)
        _NavLink(label: widget.l.t('menu_sign_out').toUpperCase(),
            isDark: widget.isDark, accent: widget.isDark ? _navDangerD : _navDanger,
            onTap: () => _logout(ctx)),
      const SizedBox(width: _sp8),
      _LangDropdown(
          currentLocale: widget.currentLocale, setLocale: widget.setLocale,
          l: widget.l, isDark: widget.isDark, primary: widget.primary),
      const SizedBox(width: _sp8),
      Container(width: 1, height: 18,
          color: widget.isDark ? _dBorder.withOpacity(0.6) : _lBorder),
      const SizedBox(width: _sp8),
      _ThemeToggle(isDark: widget.isDark, onTap: widget.toggleTheme),
    ]);
  }
}

// ── Desktop nav link ──────────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final bool isDark, isActive;
  final Color accent;
  final VoidCallback? onTap;
  const _NavLink({required this.label, required this.isDark,
    required this.accent, this.isActive = false, this.onTap});
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final base   = widget.isDark ? _dTextMuted : _lTextMuted;
    final active = widget.isActive ? widget.accent : base;
    final hover  = widget.accent;
    final cur    = _hovered ? hover : active;

    return Semantics(
      selected: widget.isActive, button: true, label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp10, vertical: _sp4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: _label(12, cur,
                    w: (widget.isActive || _hovered) ? FontWeight.w700 : FontWeight.w500),
                child: Text(widget.label),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: (widget.isActive || _hovered) ? 18 : 0,
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: _hovered || widget.isActive
                      ? [BoxShadow(color: widget.accent.withOpacity(0.5), blurRadius: 6)]
                      : [],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── SOS nav link ──────────────────────────────────────────────────────
class _SOSNavLink extends StatefulWidget {
  final String label;
  final bool isDark, isActive;
  final VoidCallback onTap;
  const _SOSNavLink({required this.label, required this.isDark,
    required this.isActive, required this.onTap});
  @override
  State<_SOSNavLink> createState() => _SOSNavLinkState();
}

class _SOSNavLinkState extends State<_SOSNavLink>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final red  = widget.isDark ? _navDangerD : _navDanger;
    final base = widget.isDark ? _dTextMuted : _lTextMuted;

    return Semantics(
      selected: widget.isActive, button: true, label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp10, vertical: _sp4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: red,
                      boxShadow: [BoxShadow(
                        color: red.withOpacity(_pulseAnim.value * 0.7),
                        blurRadius: 6, spreadRadius: 1)],
                    ),
                  ),
                ),
                const SizedBox(width: _sp6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: _label(12,
                      (_hovered || widget.isActive) ? red : base,
                      w: (widget.isActive || _hovered) ? FontWeight.w700 : FontWeight.w500),
                  child: Text(widget.label),
                ),
              ]),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: (widget.isActive || _hovered) ? 18 : 0,
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [BoxShadow(color: red.withOpacity(0.4), blurRadius: 6)],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE ACTIONS
// ══════════════════════════════════════════════════════════════════════
class _MobileActions extends StatelessWidget {
  final String activeRoute;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final Locale currentLocale;
  final bool isDark;
  final Color primary;
  final AppLocalizations l;

  const _MobileActions({
    required this.activeRoute, required this.toggleTheme,
    required this.setLocale, required this.currentLocale,
    required this.isDark, required this.primary, required this.l,
  });

  void _push(BuildContext ctx, Widget screen) => Navigator.push(ctx,
      PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 260)));

  @override
  Widget build(BuildContext ctx) {
    final teal = isDark ? _navSecondaryD : _navSecondary;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Semantics(label: l.t('bridge_screen_title'), button: true,
          child: _MobileNavIconBtn(
            icon: Icons.compare_arrows_rounded, color: teal,
            bgColor: teal.withOpacity(activeRoute == 'bridge' ? 0.15 : 0.08),
            borderColor: teal.withOpacity(activeRoute == 'bridge' ? 0.40 : 0.15),
            onTap: () { if (activeRoute != 'bridge')
              _push(ctx, TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale)); },
          )),
      const SizedBox(width: _sp6),
      Semantics(label: l.t('sos_screen_title'), button: true,
          child: _MobileSOSBtn(
              isActive: activeRoute == 'emergency',
              onTap: () { if (activeRoute != 'emergency')
                _push(ctx, EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale)); })),
      const SizedBox(width: _sp6),
      _MobileLangBtn(
          currentLocale: currentLocale, setLocale: setLocale,
          isDark: isDark, primary: primary),
      const SizedBox(width: _sp4),
      _ThemeToggle(isDark: isDark, onTap: toggleTheme),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ══════════════════════════════════════════════════════════════════════

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ThemeToggle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).t(isDark
        ? 'common_switch_to_light_mode'
        : 'common_switch_to_dark_mode'),
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: isDark ? _dSurface2 : _lSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? _dBorder : _lBorder, width: 1),
        ),
        child: Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
          size: 15,
          color: isDark ? _dTextSub : _lTextSub,
        ),
      ),
    ));
}

class _MobileNavIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor, borderColor;
  final VoidCallback onTap;
  const _MobileNavIconBtn({required this.icon, required this.color,
    required this.bgColor, required this.borderColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Icon(icon, color: color, size: 16)));
}

class _MobileSOSBtn extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _MobileSOSBtn({required this.isActive, required this.onTap});
  @override
  State<_MobileSOSBtn> createState() => _MobileSOSBtnState();
}

class _MobileSOSBtnState extends State<_MobileSOSBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 0.55)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const c = _navDanger;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: c.withOpacity(widget.isActive ? 0.18 : 0.09),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: c.withOpacity(widget.isActive ? 0.55 : 0.28), width: 1),
            boxShadow: [BoxShadow(
                color: c.withOpacity(_anim.value * 0.30), blurRadius: 10)],
          ),
          child: Center(child: Text(AppLocalizations.of(context).t('nav_emergency'),
              style: _label(9, c, w: FontWeight.w900)
                  .copyWith(letterSpacing: 1.0)))),
      ),
    );
  }
}

class _MobileLangBtn extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) setLocale;
  final bool isDark;
  final Color primary;
  const _MobileLangBtn({required this.currentLocale, required this.setLocale,
    required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧'},
      {'code': 'hi', 'flag': '🇮🇳'},
      {'code': 'mr', 'flag': '🇮🇳'},
    ];
    final cur = langs.firstWhere(
            (l) => l['code'] == currentLocale.languageCode,
        orElse: () => langs[0]);
    final bg     = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder   : _lBorder;

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).t('common_select_language'),
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1)),
      color: isDark ? _dSurface2 : _lSurface,
      elevation: 8,
      onSelected: (code) => setLocale(Locale(code)),
      itemBuilder: (_) => langs.map((lang) => PopupMenuItem<String>(
          value: lang['code'],
          height: 44,
          child: Row(children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: _sp12),
            Text(lang['code']!.toUpperCase(),
                style: _label(13,
                    lang['code'] == currentLocale.languageCode
                        ? primary : (isDark ? _dText : _lText),
                    w: lang['code'] == currentLocale.languageCode
                        ? FontWeight.w700 : FontWeight.w500)),
            if (lang['code'] == currentLocale.languageCode) ...[
              const Spacer(),
              Icon(Icons.check_rounded, color: primary, size: 14),
            ],
          ]))).toList(),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
        ),
        child: Center(child: Text(cur['flag']!,
            style: const TextStyle(fontSize: 16)))),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) setLocale;
  final AppLocalizations l;
  final bool isDark;
  final Color primary;
  const _LangDropdown({required this.currentLocale, required this.setLocale,
    required this.l, required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'label': l.t('lang_en'), 'flag': '🇬🇧'},
      {'code': 'hi', 'label': l.t('lang_hi'), 'flag': '🇮🇳'},
      {'code': 'mr', 'label': l.t('lang_mr'), 'flag': '🇮🇳'},
    ];
    final cur    = langs.firstWhere(
            (lang) => lang['code'] == currentLocale.languageCode,
        orElse: () => langs[0]);
    final accent = isDark ? _navIndigoDk : _navIndigo;
    final border = isDark ? _dBorder     : _lBorder;
    final bg     = isDark ? _dSurface2   : _lSurface2;

    return PopupMenuButton<String>(
      tooltip: l.t('nav_language'),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1)),
      color: isDark ? _dSurface2 : _lSurface,
      elevation: 8,
      onSelected: (code) => setLocale(Locale(code)),
      itemBuilder: (_) => langs.map((lang) {
        final sel = lang['code'] == currentLocale.languageCode;
        return PopupMenuItem<String>(
          value: lang['code'], height: 44,
          child: Row(children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: _sp12),
            Text(lang['label']!,
                style: _label(13,
                    sel ? accent : (isDark ? _dText : _lText),
                    w: sel ? FontWeight.w700 : FontWeight.w500)),
            if (sel) ...[
              const Spacer(),
              Icon(Icons.check_rounded, color: accent, size: 14),
            ],
          ]),
        );
      }).toList(),
      child: Semantics(
        label: AppLocalizations.of(context).t('common_select_language'), button: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cur['flag']!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: _sp8),
            Text(cur['label']!, style: _label(11, isDark ? _dText : _lText)),
            const SizedBox(width: _sp4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                color: isDark ? _dTextSub : _lTextSub),
          ]),
        ),
      ),
    );
  }
}
