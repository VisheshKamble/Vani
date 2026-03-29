// lib/components/SOSFloatingButton.dart
// Persistent SOS floating action button.
// Tap → expand quick-action menu.
// Long-press → immediate General Help alert.
// Always visible regardless of which screen is open.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/EmergencyService.dart';
import '../screens/EmergencyScreen.dart';
import '../l10n/AppLocalizations.dart';

class SOSFloatingButton extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const SOSFloatingButton({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  State<SOSFloatingButton> createState() => _SOSFloatingButtonState();
}

class _SOSFloatingButtonState extends State<SOSFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _pulseAnim;
  bool _expanded = false;

  // Tracks if an alert is currently being sent
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.06)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    HapticFeedback.lightImpact();
  }

  Future<void> _quickSend(SOSMessageType type) async {
    setState(() { _expanded = false; _sending = true; });
    HapticFeedback.heavyImpact();
    await EmergencyService.instance.triggerSOS(type: type);
    if (mounted) setState(() => _sending = false);
  }

  void _openFullScreen() {
    setState(() => _expanded = false);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EmergencyScreen(
          toggleTheme: widget.toggleTheme,
          setLocale:   widget.setLocale,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss menu on outside tap
    return GestureDetector(
      onTap: _expanded ? _toggle : null,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ── Quick-action menu (shown when expanded) ────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? _QuickMenu(
                l: AppLocalizations.of(context),
                    onGeneralHelp: () => _quickSend(SOSMessageType.generalHelp),
                    onMedical:     () => _quickSend(SOSMessageType.medical),
                    onPolice:      () => _quickSend(SOSMessageType.police),
                    onFullScreen:  _openFullScreen,
                  )
                : const SizedBox.shrink(),
          ),

          if (_expanded) const SizedBox(height: 10),

          // ── Main SOS button ────────────────────────────────
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: (_expanded || _sending) ? 1.0 : _pulseAnim.value,
              child: child,
            ),
            child: GestureDetector(
              onTap:      _toggle,
              onLongPress: () {
                if (!_expanded) {
                  setState(() => _expanded = false);
                  _quickSend(SOSMessageType.generalHelp);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: _sending ? const Color(0xFFB91C1C) : const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626)
                          .withOpacity(_expanded ? 0.25 : 0.45),
                      blurRadius: _expanded ? 14 : 22,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _expanded
                              ? const Icon(Icons.close_rounded,
                                  key: ValueKey('close'),
                                  color: Colors.white, size: 22)
                              : Column(
                                  key: const ValueKey('sos'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(height: 1),
                                    Text(AppLocalizations.of(context).t('nav_emergency'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                        letterSpacing: 0.8,
                                      )),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK MENU  (expands above the main button)
//  No emojis — Material icons only.
// ─────────────────────────────────────────────

class _QuickMenu extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onGeneralHelp;
  final VoidCallback onMedical;
  final VoidCallback onPolice;
  final VoidCallback onFullScreen;
  const _QuickMenu({
    required this.l,
    required this.onGeneralHelp,
    required this.onMedical,
    required this.onPolice,
    required this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickBtn(
          label:   l.t('sos_general_title'),
          icon:    Icons.emergency_rounded,
          color:   const Color(0xFFDC2626),
          isDark:  isDark,
          onTap:   onGeneralHelp,
        ),
        const SizedBox(height: 8),
        _QuickBtn(
          label:   l.t('sos_medical_title'),
          icon:    Icons.medical_services_rounded,
          color:   const Color(0xFFEA580C),
          isDark:  isDark,
          onTap:   onMedical,
        ),
        const SizedBox(height: 8),
        _QuickBtn(
          label:   l.t('sos_police_title'),
          icon:    Icons.shield_rounded,
          color:   const Color(0xFF0284C7),
          isDark:  isDark,
          onTap:   onPolice,
        ),
        const SizedBox(height: 8),
        _QuickBtn(
          label:   l.t('sos_full_screen'),
          icon:    Icons.open_in_full_rounded,
          color:   const Color(0xFF7C3AED),
          isDark:  isDark,
          onTap:   onFullScreen,
        ),
      ],
    );
  }
}

class _QuickBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.label, required this.icon, required this.color,
    required this.isDark, required this.onTap,
  });
  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF0D0D1A).withOpacity(0.92)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withOpacity(widget.isDark ? 0.28 : 0.22)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(widget.isDark ? 0.14 : 0.08),
                blurRadius: 16, offset: const Offset(0, 4)),
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.40 : 0.08),
                blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(widget.isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: widget.color.withOpacity(0.22))),
              child: Icon(widget.icon, color: widget.color, size: 14)),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.isDark
                    ? const Color(0xFFE8E8FF)
                    : const Color(0xFF0A0A20),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}