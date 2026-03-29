// lib/components/GlobalNavbar.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║  VANI — Global Navbar · Apple-Inspired                     ║
// ║                                                            ║
// ║  CHANGES vs original:                                      ║
// ║  • Desktop: ISL Assistant nav link added (purple accent)   ║
// ║    Sits after SOS, before API link                         ║
// ║  • Mobile: completely unchanged                            ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import '../screens/TranslateScreen.dart';
import '../screens/Signspage.dart';
import '../screens/EmergencyScreen.dart';
import '../screens/TwoWayScreen.dart';
import '../screens/ISLAssistantScreen.dart';
import '../l10n/AppLocalizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; //added
import '../components/AuthDialog.dart'; //added
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/EmergencyContact.dart';

const double _kDesktopBreak = 750;

const _navRed = Color(0xFFFF3B30);
const _navRedD = Color(0xFFFF453A);
const _navTeal = Color(0xFF32ADE6);
const _navPurple = Color(0xFFAF52DE); // ISL Assistant accent
const _navPurD = Color(0xFFBF5AF2);

TextStyle _nt(double size, FontWeight w, Color c, {double ls = 0}) => TextStyle(
  fontFamily: 'Google Sans',
  fontSize: size,
  fontWeight: w,
  color: c,
  letterSpacing: ls,
);

class GlobalNavbar extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final String activeRoute;

  const GlobalNavbar({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final l = AppLocalizations.of(context);
    final w = MediaQuery.of(context).size.width;
    final locale = Localizations.localeOf(context);
    final isMobile = w <= _kDesktopBreak;

    final hMargin = isMobile ? 12.0 : (w > 900 ? 48.0 : 16.0);
    final hPadding = isMobile ? 12.0 : 22.0;
    final vPadding = isMobile ? 10.0 : 14.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: hMargin,
        vertical: isMobile ? 12 : 20,
      ),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withOpacity(0.92)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Brand(isDark: isDark, context: context),
          if (isMobile)
            _MobileActions(
              activeRoute: activeRoute,
              toggleTheme: toggleTheme,
              setLocale: setLocale,
              currentLocale: locale,
              isDark: isDark,
              primary: primary,
              l: l,
            )
          else
            _DesktopActions(
              activeRoute: activeRoute,
              toggleTheme: toggleTheme,
              setLocale: setLocale,
              currentLocale: locale,
              isDark: isDark,
              primary: primary,
              l: l,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BRAND
// ══════════════════════════════════════════════════════════════
class _Brand extends StatelessWidget {
  final bool isDark;
  final BuildContext context;
  const _Brand({required this.isDark, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final label = isDark ? Colors.white : Colors.black;
    final accent = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    return GestureDetector(
      onTap: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text('VANI', style: _nt(19, FontWeight.w800, label, ls: 3.0)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DESKTOP ACTIONS  — ISL Assistant link added
// ══════════════════════════════════════════════════════════════
class _DesktopActions extends StatefulWidget {
  final String activeRoute;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final Locale currentLocale;
  final bool isDark;
  final Color primary;
  final AppLocalizations l;

  const _DesktopActions({
    required this.activeRoute,
    required this.toggleTheme,
    required this.setLocale,
    required this.currentLocale,
    required this.isDark,
    required this.primary,
    required this.l,
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
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _isLoggedIn = data.session != null);
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  void _push(BuildContext ctx, Widget screen) => Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );

  Future<void> _logout(BuildContext ctx) async {
    // Clear local contacts before signing out
    final box = Hive.box<EmergencyContact>('emergency_contacts');
    await box.clear();

    await Supabase.instance.client.auth.signOut();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Signed out.'),
          backgroundColor: Theme.of(ctx).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final accent = widget.isDark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
    final teal = widget.isDark ? _navTeal : const Color(0xFF0891B2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavLink(
          label: widget.l.t('nav_home'),
          isDark: widget.isDark,
          accent: accent,
          isActive: widget.activeRoute == 'home',
          onTap: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
        ),
        _NavLink(
          label: widget.l.t('nav_terminal'),
          isDark: widget.isDark,
          accent: accent,
          isActive: widget.activeRoute == 'translate',
          onTap: () {
            if (widget.activeRoute != 'translate') {
              _push(
                ctx,
                TranslateScreen(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                ),
              );
            }
          },
        ),
        _NavLink(
          label: widget.l.t('nav_signs'),
          isDark: widget.isDark,
          accent: accent,
          isActive: widget.activeRoute == 'signs',
          onTap: () {
            if (widget.activeRoute != 'signs') {
              _push(
                ctx,
                SignsPage(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                ),
              );
            }
          },
        ),
        _NavLink(
          label: widget.l.t('nav_bridge'),
          isDark: widget.isDark,
          accent: teal,
          isActive: widget.activeRoute == 'bridge',
          onTap: () {
            if (widget.activeRoute != 'bridge') {
              _push(
                ctx,
                TwoWayScreen(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                ),
              );
            }
          },
        ),
        _SOSNavLink(
          label: widget.l.t('nav_emergency'),
          isDark: widget.isDark,
          isActive: widget.activeRoute == 'emergency',
          onTap: () {
            if (widget.activeRoute != 'emergency') {
              _push(
                ctx,
                EmergencyScreen(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                ),
              );
            }
          },
        ),

        _NavLink(
          label: "ASSISTANT",
          isDark: widget.isDark,
          accent: _navPurple,
          isActive: widget.activeRoute == 'assistant',
          onTap: () {
            _push(
              ctx,
              ISLAssistantScreen(
                toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale,
              ),
            );
          },
        ),
        _NavLink(
          label: widget.l.t('nav_api'),
          isDark: widget.isDark,
          accent: accent,
        ),

        // ── Login / Logout toggle ──────────────────────────────
        _NavLink(
          label: _isLoggedIn ? 'LOGOUT' : 'LOGIN',
          isDark: widget.isDark,
          accent: accent,
          onTap: () => _isLoggedIn ? _logout(ctx) : showAuthDialog(ctx),
        ),

        const SizedBox(width: 8),
        _LangDropdown(
          currentLocale: widget.currentLocale,
          setLocale: widget.setLocale,
          l: widget.l,
          isDark: widget.isDark,
          primary: widget.primary,
        ),
        const SizedBox(width: 6),
        _VerticalDivider(isDark: widget.isDark),
        const SizedBox(width: 6),
        _ThemeToggle(isDark: widget.isDark, onTap: widget.toggleTheme),
      ],
    );
  }
}

// ── Plain nav link ────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final bool isDark, isActive;
  final Color accent;
  final VoidCallback? onTap;
  const _NavLink({
    required this.label,
    required this.isDark,
    required this.accent,
    this.isActive = false,
    this.onTap,
  });
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? Colors.white.withOpacity(0.55)
        : Colors.black.withOpacity(0.45);
    final activeColor = widget.isActive ? widget.accent : baseColor;
    final hoverColor = widget.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: _nt(
                  12,
                  widget.isActive || _hovered
                      ? FontWeight.w700
                      : FontWeight.w500,
                  _hovered ? hoverColor : activeColor,
                  ls: 0.2,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 3),
              // Active indicator line
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: widget.isActive ? 18 : 0,
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SOS link ──────────────────────────────────────────────────
class _SOSNavLink extends StatefulWidget {
  final String label;
  final bool isDark, isActive;
  final VoidCallback onTap;
  const _SOSNavLink({
    required this.label,
    required this.isDark,
    required this.isActive,
    required this.onTap,
  });
  @override
  State<_SOSNavLink> createState() => _SOSNavLinkState();
}

class _SOSNavLinkState extends State<_SOSNavLink>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = widget.isDark ? _navRedD : _navRed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: red,
                        boxShadow: [
                          BoxShadow(
                            color: red.withOpacity(_pulseAnim.value * 0.7),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: _nt(
                      12,
                      widget.isActive || _hovered
                          ? FontWeight.w700
                          : FontWeight.w500,
                      _hovered || widget.isActive
                          ? red
                          : (widget.isDark
                                ? Colors.white.withOpacity(0.55)
                                : Colors.black.withOpacity(0.45)),
                      ls: 0.2,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: widget.isActive ? 18 : 0,
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MOBILE ACTIONS  — completely unchanged
// ══════════════════════════════════════════════════════════════
class _MobileActions extends StatelessWidget {
  final String activeRoute;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final Locale currentLocale;
  final bool isDark;
  final Color primary;
  final AppLocalizations l;

  const _MobileActions({
    required this.activeRoute,
    required this.toggleTheme,
    required this.setLocale,
    required this.currentLocale,
    required this.isDark,
    required this.primary,
    required this.l,
  });

  void _push(BuildContext ctx, Widget screen) => Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MobileIconBtn(
          icon: Icons.compare_arrows_rounded,
          color: const Color(0xFF22D3EE),
          bgColor: const Color(
            0xFF0891B2,
          ).withOpacity(activeRoute == 'bridge' ? 0.18 : 0.08),
          borderColor: const Color(
            0xFF0891B2,
          ).withOpacity(activeRoute == 'bridge' ? 0.55 : 0.20),
          tooltip: l.t('bridge_screen_title'),
          onTap: () {
            if (activeRoute != 'bridge')
              _push(
                ctx,
                TwoWayScreen(toggleTheme: toggleTheme, setLocale: setLocale),
              );
          },
        ),
        const SizedBox(width: 4),
        _MobileSOSBtn(
          isActive: activeRoute == 'emergency',
          onTap: () {
            if (activeRoute != 'emergency')
              _push(
                ctx,
                EmergencyScreen(toggleTheme: toggleTheme, setLocale: setLocale),
              );
          },
        ),
        const SizedBox(width: 4),
        _MobileLangBtn(
          currentLocale: currentLocale,
          setLocale: setLocale,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(width: 2),
        _ThemeToggle(isDark: isDark, onTap: toggleTheme),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════
class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 16,
    color: isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08),
  );
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ThemeToggle({required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          size: 16,
          color: isDark
              ? Colors.white.withOpacity(0.50)
              : Colors.black.withOpacity(0.40),
        ),
      ),
    ),
  );
}

class _MobileIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor, borderColor;
  final String tooltip;
  final VoidCallback onTap;
  const _MobileIconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(child: Icon(icon, color: color, size: 16)),
      ),
    ),
  );
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
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.25,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFFF3B30);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.withOpacity(widget.isActive ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: c.withOpacity(widget.isActive ? 0.6 : 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(_anim.value * 0.30),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'SOS',
              style: TextStyle(
                color: c,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: 'Google Sans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileLangBtn extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) setLocale;
  final bool isDark;
  final Color primary;
  const _MobileLangBtn({
    required this.currentLocale,
    required this.setLocale,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'flag': '🇬🇧'},
      {'code': 'hi', 'flag': '🇮🇳'},
      {'code': 'mr', 'flag': '🇮🇳'},
    ];
    final current = langs.firstWhere(
      (l) => l['code'] == currentLocale.languageCode,
      orElse: () => langs[0],
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      elevation: 10,
      onSelected: (code) => setLocale(Locale(code)),
      itemBuilder: (_) => langs
          .map(
            (lang) => PopupMenuItem<String>(
              value: lang['code'],
              child: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    lang['code']!.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Google Sans',
                      color: lang['code'] == currentLocale.languageCode
                          ? primary
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  if (lang['code'] == currentLocale.languageCode) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, color: primary, size: 14),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withOpacity(0.18), width: 0.5),
        ),
        child: Center(
          child: Text(current['flag']!, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) setLocale;
  final AppLocalizations l;
  final bool isDark;
  final Color primary;
  const _LangDropdown({
    required this.currentLocale,
    required this.setLocale,
    required this.l,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'label': l.t('lang_en'), 'flag': '🇬🇧'},
      {'code': 'hi', 'label': l.t('lang_hi'), 'flag': '🇮🇳'},
      {'code': 'mr', 'label': l.t('lang_mr'), 'flag': '🇮🇳'},
    ];
    final current = langs.firstWhere(
      (lang) => lang['code'] == currentLocale.languageCode,
      orElse: () => langs[0],
    );
    final accent = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);

    return PopupMenuButton<String>(
      tooltip: l.t('nav_language'),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      elevation: 10,
      onSelected: (code) => setLocale(Locale(code)),
      itemBuilder: (_) => langs.map((lang) {
        final sel = lang['code'] == currentLocale.languageCode;
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Row(
            children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text(
                lang['label']!,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Google Sans',
                  color: sel
                      ? accent
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              if (sel) ...[
                const Spacer(),
                Icon(Icons.check_rounded, color: accent, size: 14),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.12), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current['flag']!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              current['label']!,
              style: _nt(11, FontWeight.w600, accent, ls: 0.3),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 14),
          ],
        ),
      ),
    );
  }
}
