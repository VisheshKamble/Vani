// lib/screens/SplashScreen.dart
//
// ╔══════════════════════════════════════════════════════════╗
// ║  VANI — Splash Screen  · Apple-Inspired Premium UI     ║
// ║  Font: Google Sans (SF Pro equivalent)                 ║
// ║                                                        ║
// ║  PHILOSOPHY                                            ║
// ║  Pure white canvas. Surgical timing. No noise.        ║
// ║  Exactly how Apple does it — logo, wordmark, done.    ║
// ║                                                        ║
// ║  TIMELINE                                             ║
// ║  0 ms      White canvas                               ║
// ║  120 ms    App icon scales in (spring, iOS feel)      ║
// ║  680 ms    "VANI" fades + slides up                   ║
// ║  980 ms    Tagline fades in                           ║
// ║  2000 ms   Everything fades out                       ║
// ║  2480 ms   Navigate — zero transition                 ║
// ╚══════════════════════════════════════════════════════════╝

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'HomeScreen.dart';
import '../l10n/AppLocalizations.dart';
import '../components/SOSFloatingButton.dart';
import '../services/EmergencyService.dart';

// ─────────────────────────────────────────────
//  APPLE PALETTE  (splash is always light)
// ─────────────────────────────────────────────
const _white  = Color(0xFFFFFFFF);
const _blue   = Color(0xFF007AFF);   // iOS system blue
const _blue2  = Color(0xFF0055FF);   // deeper shade for gradient
const _label  = Color(0xFF000000);   // iOS label
const _label2 = Color(0x993C3C43);   // iOS secondary label

TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c,
        letterSpacing: ls, height: h);

// ══════════════════════════════════════════════════════════
//  SPLASH SCREEN
// ══════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  const SplashScreen({
    super.key, required this.toggleTheme, required this.setLocale,
  });
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────
  late final AnimationController _iconCtrl;   // app icon entrance
  late final AnimationController _textCtrl;   // wordmark + tagline
  late final AnimationController _exitCtrl;   // full-screen fade-out

  // ── Icon animations ─────────────────────────
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _arcProgress;
  late final Animation<double> _handFade;
  late final Animation<double> _handScale;

  // ── Text animations ──────────────────────────
  late final Animation<double> _nameFade;
  late final Animation<Offset>  _nameSlide;
  late final Animation<double> _tagFade;

  // ── Exit ─────────────────────────────────────
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Force light status bar throughout splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:     Brightness.light,
    ));

    _iconCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _exitCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 480));

    // Icon: spring scale + fade
    _iconScale = Tween<double>(begin: 0.60, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl,
            curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack)));
    _iconFade  = CurvedAnimation(parent: _iconCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut));

    // Arc draws after icon appears
    _arcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl,
            curve: const Interval(0.05, 0.90, curve: Curves.easeOutCubic)));

    // Hand inside arc
    _handFade  = CurvedAnimation(parent: _iconCtrl,
        curve: const Interval(0.30, 0.85, curve: Curves.easeOut));
    _handScale = Tween<double>(begin: 0.30, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl,
            curve: const Interval(0.30, 0.90, curve: Curves.easeOutBack)));

    // Wordmark — iOS "slides up like SMS app name"
    _nameFade  = CurvedAnimation(parent: _textCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _nameSlide = Tween<Offset>(
        begin: const Offset(0, 0.30), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic)));

    // Tagline slightly delayed
    _tagFade = CurvedAnimation(parent: _textCtrl,
        curve: const Interval(0.38, 0.90, curve: Curves.easeOut));

    // Exit fades entire screen to white
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInOut));

    _schedule();
  }

  void _schedule() {
    // Beat 1 — icon
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _iconCtrl.forward();
      HapticFeedback.lightImpact();
    });

    // Beat 2 — wordmark
    Future.delayed(const Duration(milliseconds: 680), () {
      if (!mounted) return;
      _textCtrl.forward();
    });

    // Beat 3 — fade out + navigate
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _exitCtrl.forward().then((_) {
        if (mounted) _navigate();
      });
    });
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _AppShell(
          toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
    ));
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_iconCtrl, _textCtrl, _exitCtrl]),
        builder: (_, __) => FadeTransition(
          opacity: _exitFade,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── App Icon ─────────────────────────
                  // Mirrors the Apple app icon: square with
                  // rounded corners, solid white bg, blue elements.
                  ScaleTransition(
                    scale: _iconScale,
                    child: FadeTransition(
                      opacity: _iconFade,
                      child: SizedBox(
                        width: 100, height: 100,
                        child: CustomPaint(
                          painter: _AppIconPainter(
                            arcProgress: _arcProgress.value,
                            handOpacity: _handFade.value,
                            handScale:   _handScale.value,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── App name ─────────────────────────
                  // Apple style: black, heavy weight, tight spacing
                  SlideTransition(
                    position: _nameSlide,
                    child: FadeTransition(
                      opacity: _nameFade,
                      child: Text(l.t('app_title_short'),
                          style: _t(44, FontWeight.w700, _label, ls: 8.0)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Tagline ───────────────────────────
                  FadeTransition(
                    opacity: _tagFade,
                    child: Text(l.t('tagline_main'),
                        style: _t(13, FontWeight.w400, _label2, ls: 0.5)),
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

// ══════════════════════════════════════════════════════════
//  APP ICON PAINTER
//  iOS-style rounded-square icon with system-blue elements.
//  White background, blue arc ring, hand silhouette.
// ══════════════════════════════════════════════════════════
class _AppIconPainter extends CustomPainter {
  final double arcProgress;
  final double handOpacity;
  final double handScale;
  const _AppIconPainter({
    required this.arcProgress,
    required this.handOpacity,
    required this.handScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Rounded-square background (iOS icon shape) ──
    final iconRadius = w * 0.225;  // iOS standard corner radius ratio
    final iconRect   = Rect.fromLTWH(0, 0, w, h);
    final iconRRect  = RRect.fromRectAndRadius(
        iconRect, Radius.circular(iconRadius));

    // Drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 3, w, h),
          Radius.circular(iconRadius)),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // White fill
    canvas.drawRRect(iconRRect,
        Paint()..color = const Color(0xFFF8F8F8));

    // Subtle border
    canvas.drawRRect(iconRRect,
        Paint()
          ..color = Colors.black.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

    // ── Blue arc ring ─────────────────────────
    if (arcProgress > 0) {
      final arcR  = w * 0.36;
      final sweep = 2 * math.pi * arcProgress;

      // Track (ghost ring)
      canvas.drawCircle(Offset(cx, cy), arcR,
          Paint()
            ..color = _blue.withOpacity(0.07)
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke);

      // Active arc with system-blue gradient
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: arcR),
        -math.pi / 2, sweep, false,
        Paint()
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle:   -math.pi / 2 + sweep,
            colors:     [_blue2, _blue, const Color(0xFF5AC8F5)],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: arcR))
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Leading dot — the "progress indicator" tip
      if (arcProgress > 0.03) {
        final tipA = -math.pi / 2 + sweep;
        final tx   = cx + arcR * math.cos(tipA);
        final ty   = cy + arcR * math.sin(tipA);
        canvas.drawCircle(Offset(tx, ty), 3.5,
            Paint()..color = const Color(0xFF5AC8F5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(tx, ty), 2.0,
            Paint()..color = _blue);
      }
    }

    // ── Hand silhouette ───────────────────────
    if (handOpacity > 0) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(handScale * 0.52);
      canvas.translate(-cx, -cy);

      final handColor = _blue.withOpacity(handOpacity * 0.90);

      // Palm
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy + 7), width: 28, height: 17),
            const Radius.circular(5)),
        Paint()..color = handColor,
      );

      // Fingers — stagger appearance
      final fingers = [
        (-11.0, 22.0, 0.00),
        (-3.7,  26.0, 0.18),
        ( 3.7,  26.0, 0.34),
        ( 11.0, 20.0, 0.50),
      ];
      for (final f in fingers) {
        final fp = ((handOpacity - f.$3) / 0.36).clamp(0.0, 1.0);
        if (fp <= 0) continue;
        final fH = f.$2 * fp;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx + f.$1 - 3.5, cy - fH - 1, 7, fH + 1),
              const Radius.circular(3.5)),
          Paint()..color = _blue.withOpacity(handOpacity * fp * 0.90),
        );
      }

      // Thumb
      final tp = ((handOpacity - 0.55) / 0.45).clamp(0.0, 1.0);
      if (tp > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - 20, cy - 2, 8, 14 * tp),
              const Radius.circular(4)),
          Paint()..color = handColor,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AppIconPainter old) =>
      old.arcProgress != arcProgress ||
          old.handOpacity != handOpacity ||
          old.handScale   != handScale;
}

// ══════════════════════════════════════════════════════════
//  APP SHELL  (post-splash host)
// ══════════════════════════════════════════════════════════
class _AppShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _AppShell({required this.toggleTheme, required this.setLocale});
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EmergencyService.instance.init(context);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: HomeScreen(
        toggleTheme: widget.toggleTheme,
        setLocale:   widget.setLocale),
    floatingActionButton: SOSFloatingButton(
        toggleTheme: widget.toggleTheme,
        setLocale:   widget.setLocale),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}