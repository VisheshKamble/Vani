// lib/screens/TranslateScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Translate Screen  · UX4G Redesign                         ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║                                                                    ║
// ║  ALL functional logic preserved exactly:                           ║
// ║  • SentenceBuilder (25 model words, all patterns)                 ║
// ║  • AutoAddEngine (stability + cooldown)                           ║
// ║  • WebSocket connection + frame capture                           ║
// ║  • TTS, translation, transcript                                   ║
// ║  • Onboarding flow                                                ║
// ║                                                                    ║
// ║  UI REFRESH:                                                       ║
// ║  • Loader: floating blobs + semicircles matching homepage          ║
// ║  • Onboarding: glass-tinted cards with blob backgrounds            ║
// ║  • Translate screen: ambient circles & patches on all panels      ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/backend_config.dart';

// ─────────────────────────────────────────────────────────────────────
//  UX4G DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

const _primary       = Color(0xFF1A56DB);
const _primaryDark   = Color(0xFF4A8EFF);

const _secondary     = Color(0xFF00796B);
const _secondaryDark = Color(0xFF26A69A);

const _purple        = Color(0xFF6200EA);
const _purpleDark    = Color(0xFF9C6BFF);

const _success       = Color(0xFF1B7340);
const _successDark   = Color(0xFF27AE60);

const _warning       = Color(0xFF7A4800);
const _warningDark   = Color(0xFFFFB300);
const _warningLight  = Color(0xFFFFF3E0);

const _danger        = Color(0xFFB71C1C);
const _dangerDark    = Color(0xFFEF5350);
const _dangerLight   = Color(0xFFFFEBEE);

const _info          = Color(0xFF0D47A1);
const _infoDark      = Color(0xFF42A5F5);
const _infoLight     = Color(0xFFE3F2FD);

// Neutral surfaces
const _lBg           = Color(0xFFF0F4FA);
const _lSurface      = Color(0xFFFFFFFF);
const _lSurface2     = Color(0xFFF0F4F8);
const _lBorder       = Color(0xFFCDD5DF);
const _lBorderSub    = Color(0xFFE4E9F0);
const _lText         = Color(0xFF111827);
const _lTextSub      = Color(0xFF374151);
const _lTextMuted    = Color(0xFF6B7280);

const _dBg           = Color(0xFF0D1117);
const _dSurface      = Color(0xFF161B22);
const _dSurface2     = Color(0xFF21262D);
const _dBorder       = Color(0xFF30363D);
const _dBorderSub    = Color(0xFF21262D);
const _dText         = Color(0xFFE6EDF3);
const _dTextSub      = Color(0xFFB0BEC5);
const _dTextMuted    = Color(0xFF8B949E);

const _sp4  = 4.0;
const _sp8  = 8.0;
const _sp10 = 10.0;
const _sp12 = 12.0;
const _sp14 = 14.0;
const _sp16 = 16.0;
const _sp18 = 18.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;
const _sp40 = 40.0;

TextStyle _display(double size, Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: size, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: -0.5);

TextStyle _heading(double size, Color c, {FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.3, letterSpacing: -0.2);

TextStyle _body(double size, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.6);

TextStyle _txtLabel(double size, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.4, letterSpacing: 0.1);

// ─────────────────────────────────────────────────────────────────────
//  WEBSOCKET CONFIG
// ─────────────────────────────────────────────────────────────────────
const int _kFrameIntervalMs = 100;
const int _kWsConnectAttempts = 3;
const Duration _kWsConnectTimeout = Duration(seconds: 4);

// ─────────────────────────────────────────────────────────────────────
//  25 MODEL WORDS
// ─────────────────────────────────────────────────────────────────────
const Set<String> _kModelWords = {
  'hello', 'how are you', 'i', 'please', 'today', 'time',
  'what', 'name', 'quiet', 'yes', 'thankyou', 'namaste',
  'bandaid', 'help', 'strong', 'mother', 'food', 'father',
  'brother', 'love', 'good', 'bad', 'sorry', 'sleeping', 'water',
};

// ─────────────────────────────────────────────────────────────────────
//  SENTENCE BUILDER (all patterns preserved exactly)
// ─────────────────────────────────────────────────────────────────────
class SentenceBuilder {
  static const Map<String, String> _solo = {
    'hello': 'Hello!', 'how are you': 'How are you?', 'i': 'I...',
    'please': 'Please.', 'today': 'Today.', 'time': 'What is the time?',
    'what': 'What?', 'name': 'What is your name?', 'quiet': 'Please be quiet.',
    'yes': 'Yes.', 'thankyou': 'Thank you.', 'namaste': 'Namaste.',
    'bandaid': 'I need medical help.', 'help': 'I need help!', 'strong': 'I am strong.',
    'mother': 'My mother.', 'food': 'I need food.', 'father': 'My father.',
    'brother': 'My brother.', 'love': 'I love you.', 'good': 'That is good.',
    'bad': 'That is bad.', 'sorry': 'I am sorry.', 'sleeping': 'I am sleeping.',
    'water': 'I need water.',
  };

  static const Map<String, String> _pairs = {
    'hello|how are you': 'Hello! How are you?', 'how are you|good': 'How are you? I am good.',
    'how are you|bad': 'How are you? I am not good.', 'namaste|hello': 'Namaste! Hello!',
    'hello|namaste': 'Hello! Namaste!', 'i|name': 'My name is...', 'what|name': 'What is your name?',
    'i|good': 'I am doing well.', 'i|bad': 'I am not feeling well.', 'i|sorry': 'I am sorry.',
    'i|strong': 'I am strong.', 'i|sleeping': 'I am sleeping.', 'i|love': 'I love you.',
    'i|help': 'I need help!', 'i|food': 'I need food.', 'i|water': 'I need water.',
    'i|bandaid': 'I need medical help.', 'i|mother': 'I want my mother.',
    'i|father': 'I want my father.', 'i|brother': 'I want my brother.',
    'please|help': 'Please help me!', 'please|food': 'Please give me food.',
    'please|water': 'Please give me water.', 'please|quiet': 'Please be quiet.',
    'please|bandaid': 'Please get me medical help.', 'please|time': 'Please tell me the time.',
    'please|good': 'Please be good.', 'please|yes': 'Please say yes.',
    'please|sorry': 'Please forgive me.', 'today|good': 'Today is a good day.',
    'today|bad': 'Today is a bad day.', 'today|what': 'What is happening today?',
    'time|what': 'What is the time?', 'time|today': 'What time is it today?',
    'what|time': 'What is the time?', 'what|today': 'What is happening today?',
    'good|today': 'I am having a good day today.', 'bad|today': 'I am having a bad day today.',
    'sorry|help': 'I am sorry, I need help.', 'quiet|please': 'Quiet, please.',
    'mother|help': 'My mother needs help.', 'father|help': 'My father needs help.',
    'brother|help': 'My brother needs help.', 'mother|food': 'My mother needs food.',
    'father|food': 'My father needs food.', 'brother|food': 'My brother needs food.',
    'mother|water': 'My mother needs water.', 'father|water': 'My father needs water.',
    'brother|water': 'My brother needs water.', 'mother|bandaid': 'My mother needs medical help.',
    'father|bandaid': 'My father needs medical help.', 'brother|bandaid': 'My brother needs medical help.',
    'mother|sleeping': 'My mother is sleeping.', 'father|sleeping': 'My father is sleeping.',
    'brother|sleeping': 'My brother is sleeping.', 'mother|good': 'My mother is good.',
    'father|good': 'My father is good.', 'brother|good': 'My brother is good.',
    'love|mother': 'I love my mother.', 'love|father': 'I love my father.',
    'love|brother': 'I love my brother.', 'thankyou|help': 'Thank you for your help.',
    'thankyou|good': 'Thank you, that is good.', 'yes|good': 'Yes, that is good.',
    'yes|thankyou': 'Yes, thank you.', 'yes|please': 'Yes please.',
    'yes|sorry': 'Yes, I am sorry.', 'no|sorry': 'No, I am sorry.',
    'bad|sorry': 'I feel bad. I am sorry.', 'help|bandaid': 'Help! I need medical help!',
    'bandaid|help': 'Medical emergency! Please help!', 'help|water': 'I need water urgently.',
    'help|food': 'I need food urgently.', 'help|mother': 'Help! I need my mother.',
    'help|father': 'Help! I need my father.',
  };

  static const Map<String, String> _triples = {
    'i|love|mother': 'I love my mother.', 'i|love|father': 'I love my father.',
    'i|love|brother': 'I love my brother.', 'please|help|i': 'Please help me!',
    'i|need|help': 'I need help.', 'hello|how are you|good': 'Hello! How are you? I am good.',
    'hello|how are you|bad': 'Hello! How are you? I am not feeling well.',
    'i|good|today': 'I am doing well today.', 'i|bad|today': 'I am not feeling well today.',
    'today|good|yes': 'Yes, today is a good day.', 'today|bad|sorry': 'Today is bad. I am sorry.',
    'please|help|bandaid': 'Please help! I need medical attention.',
    'bandaid|help|please': 'Medical emergency! Please help me!',
    'i|sorry|bad': 'I am sorry, I feel bad.', 'sorry|bad|today': 'I am sorry. It has been a bad day.',
    'i|sleeping|quiet': 'I am sleeping. Please be quiet.',
    'quiet|i|sleeping': 'Please be quiet. I am sleeping.',
    'what|time|today': 'What time is it today?', 'i|food|water': 'I need food and water.',
    'food|water|please': 'Please give me food and water.',
    'help|food|please': 'Please help me. I need food.',
    'help|water|please': 'Please help me. I need water.',
    'mother|help|please': 'Please help my mother.',
    'father|help|please': 'Please help my father.',
    'brother|help|please': 'Please help my brother.',
    'i|thankyou|good': 'I am thankful. Everything is good.',
    'namaste|how are you|good': 'Namaste! How are you? Good.',
  };

  static String build(List<String> words) {
    if (words.isEmpty) return '';
    if (words.length >= 3) {
      final key = words.sublist(0, 3).join('|');
      if (_triples.containsKey(key)) return _triples[key]!;
    }
    if (words.length >= 2) {
      final key = '${words[0]}|${words[1]}';
      if (_pairs.containsKey(key)) return _pairs[key]!;
    }
    if (words.length == 1) return _solo[words[0]] ?? _cap('${words[0]}.');
    return _buildLong(words);
  }

  static String _buildLong(List<String> words) {
    final parts = <String>[];
    int i = 0;
    while (i < words.length) {
      if (i + 2 < words.length) {
        final tk = '${words[i]}|${words[i+1]}|${words[i+2]}';
        if (_triples.containsKey(tk)) { parts.add(_triples[tk]!); i += 3; continue; }
      }
      if (i + 1 < words.length) {
        final pk = '${words[i]}|${words[i+1]}';
        if (_pairs.containsKey(pk)) { parts.add(_pairs[pk]!); i += 2; continue; }
      }
      parts.add(_solo[words[i]] ?? _cap('${words[i]}.'));
      i++;
    }
    return parts.map((p) => p.trimRight()).join(' ');
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────
//  AUTO-ADD ENGINE (unchanged logic)
// ─────────────────────────────────────────────────────────────────────
class _AutoAddEngine {
  static const int _stabilityMs     = 800;
  static const int _sameWordCooldown = 3000;
  static const int _anyWordCooldown  = 600;

  String   _stableLabel  = '';
  DateTime _stableStart  = DateTime(0);
  String   _lastAdded    = '';
  DateTime _lastAddedAt  = DateTime(0);
  DateTime _lastAnyAdded = DateTime(0);

  String? update(String label, double conf) {
    final lbl = label.toLowerCase().trim();
    if (lbl.isEmpty || lbl == '—' || lbl == 'no sign') return null;
    if (conf < 0.20) return null;
    if (!_kModelWords.contains(lbl)) return null;

    final now = DateTime.now();
    if (lbl == _stableLabel) {
      final held = now.difference(_stableStart).inMilliseconds;
      if (held >= _stabilityMs) {
        final sinceAny  = now.difference(_lastAnyAdded).inMilliseconds;
        final sinceSame = now.difference(_lastAddedAt).inMilliseconds;
        if (sinceAny  < _anyWordCooldown)  return null;
        if (lbl == _lastAdded && sinceSame < _sameWordCooldown) return null;
        _lastAdded = lbl; _lastAddedAt = now; _lastAnyAdded = now;
        _stableStart = now.add(const Duration(milliseconds: _sameWordCooldown));
        return lbl;
      }
    } else {
      _stableLabel = lbl; _stableStart = now;
    }
    return null;
  }

  void reset() {
    _stableLabel = ''; _stableStart  = DateTime(0);
    _lastAdded   = ''; _lastAddedAt  = DateTime(0);
    _lastAnyAdded = DateTime(0);
  }

  double stabilityProgress(String currentLabel) {
    if (currentLabel != _stableLabel) return 0.0;
    final held = DateTime.now().difference(_stableStart).inMilliseconds;
    return (held / _stabilityMs).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────
enum _SessionState { idle, connecting, running, stopping, error }

class _GestureToken {
  final String label;
  final double confidence;
  _GestureToken({required this.label, required this.confidence});
}

// ═════════════════════════════════════════════════════════════════════
//  AMBIENT BLOB PAINTER — matches VANI homepage circles/semicircles
// ═════════════════════════════════════════════════════════════════════
class _AmbientBlobPainter extends CustomPainter {
  final bool dark;
  final double animValue; // 0.0–1.0 for subtle float
  const _AmbientBlobPainter({required this.dark, this.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final float = math.sin(animValue * math.pi * 2) * 8.0;

    // Colour palette — light mode: soft blue/purple/teal blobs
    // Dark mode: deeper muted blobs
    final List<_BlobDef> blobs = dark ? [
      _BlobDef(dx: w * 0.92, dy: h * 0.08 + float, r: w * 0.30,
          color: const Color(0xFF1A56DB).withOpacity(0.07)),
      _BlobDef(dx: w * -0.04, dy: h * 0.55 - float * 0.5, r: w * 0.35,
          color: const Color(0xFF6200EA).withOpacity(0.06)),
      _BlobDef(dx: w * 0.50, dy: h * 0.92 + float * 0.3, r: w * 0.28,
          color: const Color(0xFF00796B).withOpacity(0.05)),
      _BlobDef(dx: w * 0.80, dy: h * 0.65, r: w * 0.18,
          color: const Color(0xFF4A8EFF).withOpacity(0.05)),
    ] : [
      _BlobDef(dx: w * 0.92, dy: h * 0.06 + float, r: w * 0.32,
          color: const Color(0xFF1A56DB).withOpacity(0.09)),
      _BlobDef(dx: w * -0.05, dy: h * 0.52 - float * 0.5, r: w * 0.36,
          color: const Color(0xFF6200EA).withOpacity(0.07)),
      _BlobDef(dx: w * 0.48, dy: h * 0.94 + float * 0.3, r: w * 0.30,
          color: const Color(0xFF00796B).withOpacity(0.06)),
      _BlobDef(dx: w * 0.78, dy: h * 0.62, r: w * 0.20,
          color: const Color(0xFF1A56DB).withOpacity(0.05)),
    ];

    for (final b in blobs) {
      final paint = Paint()
        ..color = b.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(b.dx, b.dy), b.r, paint);
    }

    // Semicircle arc — top right (like homepage)
    final arcPaint = Paint()
      ..color = (dark ? const Color(0xFF4A8EFF) : const Color(0xFF1A56DB))
          .withOpacity(dark ? 0.06 : 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dark ? 60 : 70
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w + w * 0.05, -h * 0.05), radius: w * 0.55),
      math.pi * 0.55, math.pi * 0.80, false, arcPaint,
    );

    // Small circle ring — bottom left
    final ringPaint = Paint()
      ..color = (dark ? const Color(0xFF9C6BFF) : const Color(0xFF6200EA))
          .withOpacity(dark ? 0.06 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dark ? 40 : 50
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(-w * 0.08, h * 0.88 + float * 0.4), w * 0.28, ringPaint);
  }

  @override
  bool shouldRepaint(_AmbientBlobPainter o) =>
      o.dark != dark || o.animValue != animValue;
}

class _BlobDef {
  final double dx, dy, r;
  final Color color;
  const _BlobDef({required this.dx, required this.dy,
    required this.r, required this.color});
}

// ─────────────────────────────────────────────────────────────────────
//  ATMOSPHERIC BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────
class _AtmosphericBg extends StatelessWidget {
  final bool d;
  const _AtmosphericBg({required this.d});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _AtmosphericPainter(dark: d),
          child: const SizedBox.expand(),
        ),
      );
}

class _AtmosphericPainter extends CustomPainter {
  final bool dark;
  const _AtmosphericPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final cBlue = dark ? const Color(0xFF4A8EFF) : const Color(0xFF1A56DB);
    final cPurple = dark ? const Color(0xFF9C6BFF) : const Color(0xFF6200EA);
    final cTeal = dark ? const Color(0xFF26A69A) : const Color(0xFF00796B);

    void orb(Offset c, double r, Color color, double alpha) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withOpacity(alpha), Colors.transparent],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    orb(Offset(w * 1.05, -h * 0.04), w * 0.70, cBlue, dark ? 0.14 : 0.11);
    orb(Offset(-w * 0.10, h * 1.05), w * 0.62, cPurple, dark ? 0.11 : 0.08);
    orb(Offset(w * 0.12, h * 0.48), w * 0.30, cTeal, dark ? 0.08 : 0.06);

    void ring(Offset c, double r, Color color, double alpha, double sw) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withOpacity(alpha)
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke,
      );
    }

    ring(Offset(w * 1.05, -h * 0.04), w * 0.78, cBlue, dark ? 0.10 : 0.08, 1.0);
    ring(Offset(w * 1.05, -h * 0.04), w * 0.98, cBlue, dark ? 0.06 : 0.05, 0.7);
    ring(Offset(-w * 0.10, h * 1.05), w * 0.70, cPurple, dark ? 0.08 : 0.06, 0.8);

    void floatCircle(Offset c, double r, Color color, double alpha) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withOpacity(alpha)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        c,
        r,
        Paint()..color = color.withOpacity(alpha * 0.15),
      );
    }

    floatCircle(Offset(w * 0.72, h * 0.10), w * 0.12, cBlue, dark ? 0.18 : 0.14);
    floatCircle(Offset(w * 0.90, h * 0.22), w * 0.07, cBlue, dark ? 0.12 : 0.09);
    floatCircle(Offset(w * 0.06, h * 0.32), w * 0.10, cPurple, dark ? 0.14 : 0.10);
    floatCircle(Offset(w * 0.15, h * 0.72), w * 0.15, cBlue, dark ? 0.12 : 0.09);
    floatCircle(Offset(w * 0.38, h * 0.82), w * 0.08, cTeal, dark ? 0.14 : 0.10);
    floatCircle(Offset(w * 0.80, h * 0.68), w * 0.11, cPurple, dark ? 0.12 : 0.08);
    floatCircle(Offset(w * 1.05, h * 0.88), w * 0.30, cBlue, dark ? 0.08 : 0.06);

    void dot(Offset c, double r, Color color, double alpha) {
      canvas.drawCircle(c, r, Paint()..color = color.withOpacity(alpha));
    }

    dot(Offset(w * 0.08, h * 0.17), 3.5, cBlue, dark ? 0.35 : 0.25);
    dot(Offset(w * 0.88, h * 0.62), 2.5, cPurple, dark ? 0.30 : 0.20);
    dot(Offset(w * 0.22, h * 0.88), 4.0, cTeal, dark ? 0.28 : 0.18);
    dot(Offset(w * 0.78, h * 0.30), 2.8, cBlue, dark ? 0.25 : 0.18);
    dot(Offset(w * 0.52, h * 0.06), 2.0, cPurple, dark ? 0.22 : 0.15);
  }

  @override
  bool shouldRepaint(_AtmosphericPainter o) => o.dark != dark;
}

// ─────────────────────────────────────────────────────────────────────
//  ONBOARDING FLOW — premium fullscreen layout
// ─────────────────────────────────────────────────────────────────────
class _OnboardingFlow extends StatefulWidget {
  final bool d;
  final VoidCallback onComplete;
  const _OnboardingFlow({required this.d, required this.onComplete});

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow>
    with TickerProviderStateMixin {
  int _phase = 0;
  int _step = 0;
  Timer? _timer;

  late AnimationController _loaderCtrl;
  late Animation<double> _loaderAnim;

  int _phaseIdx = 0;
  double _loadProgress = 0.0;
  static const _loadPhases = [
    (target: 0.33, ms: 900, labelKey: 'translate_loader_camera'),
    (target: 0.68, ms: 900, labelKey: 'translate_loader_ai'),
    (target: 0.92, ms: 600, labelKey: 'translate_loader_calibrate'),
    (target: 1.00, ms: 300, labelKey: 'translate_loader_ready'),
  ];
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  static const _steps = [
    (
      icon: Icons.camera_alt_outlined,
      color: Color(0xFF1A56DB),
      darkColor: Color(0xFF4A8EFF),
      titleKey: 'translate_onboard_title_1',
      bodyKey: 'translate_onboard_body_1',
    ),
    (
      icon: Icons.back_hand_outlined,
      color: Color(0xFF1B7340),
      darkColor: Color(0xFF27AE60),
      titleKey: 'translate_onboard_title_2',
      bodyKey: 'translate_onboard_body_2',
    ),
    (
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFF7A4800),
      darkColor: Color(0xFFFFB300),
      titleKey: 'translate_onboard_title_3',
      bodyKey: 'translate_onboard_body_3',
    ),
    (
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF6200EA),
      darkColor: Color(0xFF9C6BFF),
      titleKey: 'translate_onboard_title_4',
      bodyKey: 'translate_onboard_body_4',
    ),
    (
      icon: Icons.translate_outlined,
      color: Color(0xFF00796B),
      darkColor: Color(0xFF26A69A),
      titleKey: 'translate_onboard_title_5',
      bodyKey: 'translate_onboard_body_5',
    ),
  ];

  String get _currentLabelKey =>
      _phaseIdx < _loadPhases.length
          ? _loadPhases[_phaseIdx].labelKey
          : _loadPhases.last.labelKey;

  @override
  void initState() {
    super.initState();

    _loaderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _loaderAnim = CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeInOut);
    _loaderCtrl.forward();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _progressAnim = Tween<double>(begin: 0.0, end: 0.0).animate(_progressCtrl);
    _progressAnim.addListener(() {
      if (mounted) setState(() => _loadProgress = _progressAnim.value);
    });
    _kickPhase(0, 0.0);

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);

    _timer = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _phase = 1);
        _fadeCtrl.forward();
        _slideCtrl.forward();
        _iconCtrl.forward();
      });
    });
  }

  void _kickPhase(int idx, double from) {
    if (idx >= _loadPhases.length) return;
    final phase = _loadPhases[idx];
    final delay = idx == 0 ? 0 : _loadPhases[idx - 1].ms + 80;
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _phaseIdx = idx);
      _progressCtrl.duration = Duration(milliseconds: phase.ms);
      _progressAnim = Tween<double>(begin: from, end: phase.target)
          .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut))
        ..addListener(() {
          if (mounted) setState(() => _loadProgress = _progressAnim.value);
        });
      _progressCtrl
        ..reset()
        ..forward();
      _kickPhase(idx + 1, phase.target);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loaderCtrl.dispose();
    _progressCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _slideCtrl.reset();
      _iconCtrl.reset();
      _slideCtrl.forward();
      _iconCtrl.forward();
    } else {
      widget.onComplete();
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _slideCtrl.reset();
      _iconCtrl.reset();
      _slideCtrl.forward();
      _iconCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.d ? const Color(0xFF0D1117) : const Color(0xFFF0F4FB);
    return Material(
      color: bg,
      child: Stack(fit: StackFit.expand, children: [
        _AtmosphericBg(d: widget.d),
        FadeTransition(
          opacity: _fadeAnim,
          child: _phase == 0 ? _buildLoader(context) : _buildSteps(context),
        ),
      ]),
    );
  }

  Widget _buildLoader(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return screenW < 700 ? _buildLoaderMobile(context) : _buildLoaderWeb(context);
  }

  Widget _buildLoaderMobile(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.d;
    final textClr = d ? _dText : _lText;
    final mutedClr = d ? _dTextMuted : _lTextMuted;
    final cardBg = d ? const Color(0xFF161B22).withOpacity(0.88) : const Color(0xFFF4F7FC).withOpacity(0.92);
    final cardBorder = d ? Colors.white.withOpacity(0.08) : const Color(0xFFD9E2F0);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _sp16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(_sp20, _sp20, _sp20, _sp16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: cardBorder, width: 1),
                boxShadow: d
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A56DB).withOpacity(0.07),
                          blurRadius: 36,
                          spreadRadius: -10,
                          offset: const Offset(0, 12),
                        ),
                      ],
              ),
              child: AnimatedBuilder(
                animation: _loaderAnim,
                builder: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LoaderScanDots(d: d, anim: _loaderAnim),
                    const SizedBox(height: _sp18),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: _loaderAnim.value,
                          color: d ? _primaryDark : _primary,
                          track: d ? _dBorder : const Color(0xFFDDE3EE),
                        ),
                      ),
                    ),
                    const SizedBox(height: _sp20),
                    Text(
                      l.t('translate_screen_title'),
                      textAlign: TextAlign.center,
                      style: _display(24, textClr).copyWith(letterSpacing: -0.3),
                    ),
                    const SizedBox(height: _sp8),
                    Text(
                      l.t('translate_loader_tagline'),
                      textAlign: TextAlign.center,
                      style: _body(13.5, mutedClr),
                    ),
                    const SizedBox(height: _sp20),
                    _LoaderStepRowMobile(
                      icon: Icons.camera_alt_outlined,
                      label: l.t('translate_loader_camera'),
                      done: _loaderAnim.value >= 0.35,
                      active: _loaderAnim.value < 0.35,
                      d: d,
                    ),
                    const SizedBox(height: _sp8),
                    _LoaderStepRowMobile(
                      icon: Icons.psychology_outlined,
                      label: l.t('translate_loader_ai'),
                      done: _loaderAnim.value >= 0.70,
                      active: _loaderAnim.value >= 0.35 && _loaderAnim.value < 0.70,
                      d: d,
                    ),
                    const SizedBox(height: _sp8),
                    _LoaderStepRowMobile(
                      icon: Icons.tune_rounded,
                      label: l.t('translate_loader_calibrate'),
                      done: _loaderAnim.value >= 1.0,
                      active: _loaderAnim.value >= 0.70,
                      d: d,
                    ),
                    const SizedBox(height: _sp18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _loaderAnim.value,
                        minHeight: 4,
                        backgroundColor: d ? Colors.white.withOpacity(0.10) : const Color(0xFFDDE3EE),
                        valueColor: AlwaysStoppedAnimation(d ? _primaryDark : _primary),
                      ),
                    ),
                    const SizedBox(height: _sp10),
                    Text(
                      '${(_loaderAnim.value * 100).toInt()}%',
                      style: _txtLabel(13, d ? _dTextSub : _lTextSub, w: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoaderWeb(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.d;
    final textClr = d ? _dText : _lText;
    final subClr = d ? _dTextSub : _lTextSub;
    final mutedClr = d ? _dTextMuted : _lTextMuted;
    final cardBg = d ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.80);
    final cardBorder = d ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: _sp24),
        padding: const EdgeInsets.symmetric(horizontal: _sp32, vertical: 40),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 1.0),
          boxShadow: d
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1A56DB).withOpacity(0.06),
                    blurRadius: 48,
                    spreadRadius: -8,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _LoaderScanDots(d: d, anim: _loaderAnim),
          const SizedBox(height: _sp24),
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: _loaderAnim,
              builder: (_, __) => CustomPaint(
                painter: _RingPainter(
                  progress: _loaderAnim.value,
                  color: d ? _primaryDark : _primary,
                  track: d ? _dBorder : const Color(0xFFDDE3EE),
                ),
              ),
            ),
          ),
          const SizedBox(height: _sp20),
          Text(
            l.t('translate_screen_title'),
            textAlign: TextAlign.center,
            style: _display(22, textClr).copyWith(letterSpacing: -0.3, height: 1.25),
          ),
          const SizedBox(height: _sp8),
          Text(l.t('translate_loader_tagline'), textAlign: TextAlign.center, style: _body(13, mutedClr)),
          const SizedBox(height: _sp32),
          AnimatedBuilder(
            animation: _loaderAnim,
            builder: (_, __) => Column(children: [
              _LoaderStepRow(
                icon: Icons.camera_alt_outlined,
                label: l.t('translate_loader_camera'),
                done: _loaderAnim.value >= 0.35,
                active: _loaderAnim.value < 0.35,
                d: d,
              ),
              const SizedBox(height: _sp8),
              _LoaderStepRow(
                icon: Icons.psychology_outlined,
                label: l.t('translate_loader_ai'),
                done: _loaderAnim.value >= 0.70,
                active: _loaderAnim.value >= 0.35 && _loaderAnim.value < 0.70,
                d: d,
              ),
              const SizedBox(height: _sp8),
              _LoaderStepRow(
                icon: Icons.tune_rounded,
                label: l.t('translate_loader_calibrate'),
                done: _loaderAnim.value >= 1.0,
                active: _loaderAnim.value >= 0.70,
                d: d,
              ),
            ]),
          ),
          const SizedBox(height: _sp24),
          AnimatedBuilder(
            animation: _loaderAnim,
            builder: (_, __) => Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _loaderAnim.value,
                  minHeight: 4,
                  backgroundColor: d ? Colors.white.withOpacity(0.08) : const Color(0xFFDDE3EE),
                  valueColor: AlwaysStoppedAnimation(d ? _primaryDark : _primary),
                ),
              ),
              const SizedBox(height: _sp8),
              Text('${(_loaderAnim.value * 100).toInt()}%', style: _txtLabel(11, subClr)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return screenW < 700 ? _buildStepsMobile(context) : _buildStepsWeb(context);
  }

  Widget _buildStepsMobile(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final accent = widget.d ? step.darkColor : step.color;
    final textClr = widget.d ? const Color(0xFFE6EDF3) : const Color(0xFF111827);
    final subClr = widget.d ? const Color(0xFFB0BEC5) : const Color(0xFF4B5563);
    final mutedClr = widget.d ? const Color(0xFF8B949E) : const Color(0xFF9CA3AF);
    final trackClr = widget.d ? const Color(0xFF30363D) : const Color(0xFFDDE3ED);
    final screenH = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(_steps.length, (i) {
                    final isActive = i <= _step;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: i < _steps.length - 1 ? 4 : 0),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive ? accent : trackClr,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${(_step + 1).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${_steps.length.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: mutedClr,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onComplete,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          l.t('translate_skip_tutorial'),
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: mutedClr,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideCtrl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _iconAnim,
                        child: _HaloIcon(icon: step.icon, accent: accent),
                      ),
                      SizedBox(height: screenH * 0.045),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          l.t(step.titleKey),
                          key: ValueKey('title_$_step'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: textClr,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          l.t(step.bodyKey),
                          key: ValueKey('body_$_step'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: subClr,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final active = i == _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? accent : trackClr,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    if (_step > 0) ...[
                      _BackButton(onTap: _prev, d: widget.d),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _PillButton(
                        label: last ? l.t('translate_lets_begin') : l.t('translate_next'),
                        icon: last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                        accent: accent,
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsWeb(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final accent = widget.d ? step.darkColor : step.color;
    final textClr = widget.d ? const Color(0xFFE6EDF3) : const Color(0xFF111827);
    final subClr = widget.d ? const Color(0xFFB0BEC5) : const Color(0xFF4B5563);
    final mutedClr = widget.d ? const Color(0xFF8B949E) : const Color(0xFF9CA3AF);
    final trackClr = widget.d ? const Color(0xFF30363D) : const Color(0xFFDDE3ED);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(_sp20, _sp20, _sp20, _sp20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: BoxDecoration(
                color: widget.d
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.84),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.d
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFDDE3EE),
                  width: 1,
                ),
                boxShadow: widget.d
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A56DB).withOpacity(0.06),
                          blurRadius: 32,
                          spreadRadius: -8,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${(_step + 1).toString().padLeft(2, '0')}',
                              style: _txtLabel(15, accent, w: FontWeight.w700),
                            ),
                            TextSpan(
                              text: ' / ${_steps.length.toString().padLeft(2, '0')}',
                              style: _txtLabel(15, mutedClr, w: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onComplete,
                        child: Text(l.t('translate_skip_tutorial'), style: _txtLabel(13, mutedClr, w: FontWeight.w500)),
                      ),
                    ],
                  ),
                    const SizedBox(height: _sp14),
                  Row(
                    children: List.generate(_steps.length, (i) {
                      final isActive = i <= _step;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: EdgeInsets.only(right: i < _steps.length - 1 ? 4 : 0),
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isActive ? accent : trackClr,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: _iconAnim,
                        child: _HaloIcon(icon: step.icon, accent: accent),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  l.t(step.titleKey),
                                  key: ValueKey('title_web_$_step'),
                                  style: _display(30, textClr).copyWith(
                                    letterSpacing: -0.7,
                                    height: 1.12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: _sp10),
                              const SizedBox(height: _sp12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 700),
                                  child: Text(
                                    l.t(step.bodyKey),
                                    key: ValueKey('body_web_$_step'),
                                    style: _body(16, subClr).copyWith(height: 1.65),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 118,
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: _step > 0 ? _prev : null,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: mutedClr,
                                        side: BorderSide(
                                          color: mutedClr.withOpacity(0.25),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_back_rounded, size: 16),
                                          const SizedBox(width: 6),
                                          Text(l.t('common_back')),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                    const SizedBox(width: 12),
                                  Expanded(
                                    child: _PillButton(
                                      label: last ? l.t('translate_lets_begin') : l.t('translate_next'),
                                      icon: last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                                      accent: accent,
                                      onTap: _next,
                                    ),
                                  ),
                                  ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _HaloIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  const _HaloIcon({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.08), width: 1),
              color: accent.withOpacity(0.04),
            ),
          ),
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.13), width: 1),
              color: accent.withOpacity(0.06),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.22), width: 1),
              color: accent.withOpacity(0.10),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.14),
              border: Border.all(color: accent.withOpacity(0.30), width: 1.5),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _down = false;

  Color get _gradStart => widget.accent;
  Color get _gradEnd {
    final hsl = HSLColor.fromColor(widget.accent);
    return hsl.withHue((hsl.hue + 30) % 360).withSaturation(
        (hsl.saturation + 0.05).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_gradStart, _gradEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(_down ? 0.20 : 0.30),
                blurRadius: _down ? 10 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool d;
  const _BackButton({required this.onTap, required this.d});

  @override
  Widget build(BuildContext context) {
    final border = d ? const Color(0xFF30363D) : const Color(0xFFCDD5DF);
    final icon = d ? const Color(0xFFB0BEC5) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.0),
          color: Colors.transparent,
        ),
        child: Icon(Icons.arrow_back_rounded, color: icon, size: 20),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE STEP DECORATIVE PAINTER
//  Paints large ambient circles/arcs/patches per step.
//  Each step gets a unique composition so it feels like a new scene.
// ══════════════════════════════════════════════════════════════════════
class _MobileStepBlobPainter extends CustomPainter {
  final Color accent;
  final bool dark;
  final double animValue;
  final int stepIndex;

  const _MobileStepBlobPainter({
    required this.accent,
    required this.dark,
    required this.animValue,
    required this.stepIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final float = math.sin(animValue * math.pi * 2 + stepIndex * 0.35) * 8.0;
    final float2 = math.cos(animValue * math.pi * 2 + stepIndex * 0.2) * 6.0;
    final stepShift = (stepIndex % 5) * 0.02;

    final orbA = accent.withOpacity(dark ? 0.10 : 0.14);
    final orbB = accent.withOpacity(dark ? 0.07 : 0.10);
    final lineA = dark ? 0.18 : 0.15;
    final lineB = dark ? 0.14 : 0.12;
    final grid = accent.withOpacity(dark ? 0.06 : 0.07);

    void orb(double x, double y, double r, Color color, double blur) {
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    void quarterArc(Offset center, double radius, double start, double strength) {
      final glow = Paint()
        ..color = accent.withOpacity(strength * (dark ? 0.12 : 0.10))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      final stroke = Paint()
        ..color = accent.withOpacity(strength * (dark ? 0.36 : 0.30))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.pi / 2, false, glow);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.pi / 2, false, stroke);
    }

    void ring(Offset center, double radius, double strength) {
      final p = Paint()
        ..color = accent.withOpacity(strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, p);
    }

    void semiArc(Offset center, double radius, double start, double strength) {
      final p = Paint()
        ..color = accent.withOpacity(strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.pi, false, p);
    }

    void patchCluster(Offset center, double sizeFactor, double strength) {
      orb(center.dx, center.dy, sizeFactor, accent.withOpacity(strength), 22);
      orb(center.dx + sizeFactor * 0.95, center.dy - sizeFactor * 0.35, sizeFactor * 0.55,
          accent.withOpacity(strength * 0.75), 14);
      orb(center.dx - sizeFactor * 0.80, center.dy + sizeFactor * 0.45, sizeFactor * 0.48,
          accent.withOpacity(strength * 0.65), 12);
      ring(center, sizeFactor * 1.25, dark ? 0.09 : 0.08);
    }

    orb(-w * (0.16 + stepShift * 0.6), -h * 0.08 + float, w * 0.52, orbA, 82);
    orb(w * 1.04, h * (0.10 + stepShift * 0.4) + float2, w * 0.44, orbB, 74);
    orb(w * 0.50, h * 1.06 - float * 0.4, w * 0.40, orbB, 70);
    orb(w * 0.08, h * 0.24 - float2 * 0.2, w * 0.14, accent.withOpacity(dark ? 0.06 : 0.08), 24);

    semiArc(Offset(w * 1.02, -h * 0.01), w * (0.50 + stepShift * 0.4), math.pi * 0.56, lineA);
    semiArc(Offset(-w * 0.02, -h * 0.01), w * (0.49 + stepShift * 0.4), math.pi * 0.94, lineB);
    semiArc(Offset(-w * 0.04, h * 0.90), w * (0.28 + stepShift), -math.pi * 0.05, lineA);

    quarterArc(Offset.zero, w * 0.34, 0, 0.90);
    quarterArc(Offset(w, 0), w * 0.28, math.pi / 2, 0.75);
    quarterArc(Offset(0, h), w * 0.24, -math.pi / 2, 0.70);
    quarterArc(Offset(w, h), w * 0.38, math.pi, 0.95);

    ring(Offset(w * 0.84, h * 0.18 + float2 * 0.25), w * 0.14, lineA);
    ring(Offset(w * 0.16, h * 0.74 - float * 0.20), w * 0.12, lineA * 0.95);
    ring(Offset(w * 0.50, h * 0.72 + float * 0.15), w * 0.10, lineB);
    ring(Offset(w * 0.50, h * 0.36 - float2 * 0.10), w * 0.08, lineB * 0.92);

    final patchLift = <double>[-0.03, 0.0, 0.02, -0.015, 0.01][stepIndex % 5];
    patchCluster(
      Offset(w * 0.22, h * (0.26 + patchLift) + float2 * 0.10),
      w * 0.07,
      dark ? 0.10 : 0.13,
    );
    patchCluster(
      Offset(w * 0.78, h * (0.60 - patchLift) - float * 0.08),
      w * 0.065,
      dark ? 0.09 : 0.12,
    );
    patchCluster(
      Offset(w * 0.50, h * (0.84 + patchLift * 0.6) + float * 0.06),
      w * 0.055,
      dark ? 0.08 : 0.11,
    );

    final dotPaint = Paint()..color = grid;
    const spacing = 34.0;
    for (double x = 0; x < w; x += spacing) {
      for (double y = 0; y < h; y += spacing) {
        if ((x + y) % (spacing * 3) == 0) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MobileStepBlobPainter o) =>
      o.accent != accent || o.animValue != animValue ||
      o.stepIndex != stepIndex || o.dark != dark;
}

// ── Step icon with concentric pulse rings ──────────────────────────
class _MobileStepIcon extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final bool d;
  const _MobileStepIcon({
    required this.icon,
    required this.accent,
    required this.d,
  });
  @override
  State<_MobileStepIcon> createState() => _MobileStepIconState();
}

class _MobileStepIconState extends State<_MobileStepIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: Stack(alignment: Alignment.center, children: [

        // ── Outermost pulse ring
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.accent.withOpacity(
                    (1.0 - _pulse.value) * (widget.d ? 0.18 : 0.22)),
                width: 1.0,
              ),
            ),
          ),
        ),

        // ── Mid ring
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final v = ((_ctrl.value + 0.33) % 1.0);
            return Container(
              width: 108, height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accent.withOpacity(
                      (1.0 - v) * (widget.d ? 0.20 : 0.25)),
                  width: 1.0,
                ),
              ),
            );
          },
        ),

        // ── Inner filled circle
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accent.withOpacity(widget.d ? 0.12 : 0.10),
            border: Border.all(
                color: widget.accent.withOpacity(0.28), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(widget.d ? 0.20 : 0.16),
                blurRadius: 32, spreadRadius: -8,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.accent, size: 38),
        ),
      ]),
    );
  }
}

// ── Loader step row widget (web) ────────────────────────────────────
class _LoaderStepRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done, active, d;
  const _LoaderStepRow({
    required this.icon, required this.label,
    required this.done, required this.active, required this.d,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    if (done) {
      fg = d ? _successDark : _success;
      bg = fg.withOpacity(0.10);
    } else if (active) {
      fg = d ? _primaryDark : _primary;
      bg = fg.withOpacity(0.08);
    } else {
      fg = d ? _dTextMuted : _lTextMuted;
      bg = Colors.transparent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (done || active) ? fg.withOpacity(0.18) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(children: [
        Icon(done ? Icons.check_circle_rounded : icon,
            color: fg, size: 16),
        const SizedBox(width: _sp8),
        Expanded(child: Text(label,
            style: _txtLabel(12, fg,
                w: active ? FontWeight.w700 : FontWeight.w500))),
        if (active)
          SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: fg)),
      ]),
    );
  }
}

// ── Loader step row — MOBILE (full-width, larger, card-like) ─────────
class _LoaderStepRowMobile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done, active, d;
  const _LoaderStepRowMobile({
    required this.icon, required this.label,
    required this.done, required this.active, required this.d,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color border;
    if (done) {
      fg = d ? _successDark : _success;
      bg = fg.withOpacity(0.08);
      border = fg.withOpacity(0.20);
    } else if (active) {
      fg = d ? _primaryDark : _primary;
      bg = fg.withOpacity(0.08);
      border = fg.withOpacity(0.25);
    } else {
      fg = d ? _dTextMuted : _lTextMuted;
      bg = d ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.40);
      border = d ? Colors.white.withOpacity(0.06) : const Color(0xFFE4E9F0);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(children: [
        // Icon circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36, height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fg.withOpacity(done ? 0.15 : active ? 0.12 : 0.06)),
          child: Icon(
              done ? Icons.check_circle_rounded : icon,
              color: fg, size: 18),
        ),
        const SizedBox(width: _sp12),
        Expanded(child: Text(label,
            style: _txtLabel(13, fg,
                w: active ? FontWeight.w700 : FontWeight.w500))),
        if (active)
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: fg))
        else if (done)
          Icon(Icons.check_rounded, color: fg, size: 16),
      ]),
    );
  }
}

// ── Scan dots row ──────────────────────────────────────────────────
class _LoaderScanDots extends StatefulWidget {
  final bool d;
  final Animation<double> anim;
  const _LoaderScanDots({required this.d, required this.anim});
  @override State<_LoaderScanDots> createState() => _LoaderScanDotsState();
}

class _LoaderScanDotsState extends State<_LoaderScanDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
              final opacity = (math.sin(phase * math.pi)).clamp(0.25, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7, height: 7,
                decoration: BoxDecoration(
                    color: (widget.d ? _primaryDark : _primary)
                        .withOpacity(opacity),
                    shape: BoxShape.circle),
              );
            }));
      },
    );
  }
}

// ── Ring painter ────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * progress,
          colors: const [
            Color(0xFF1A56DB),
            Color(0xFF6200EA),
            Color(0xFF4A8EFF),
          ],
        ).createShader(rect)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ══════════════════════════════════════════════════════════════════════
//  TRANSLATE SCREEN
// ══════════════════════════════════════════════════════════════════════
class TranslateScreen extends StatefulWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  const TranslateScreen({super.key, required this.toggleTheme,
    required this.setLocale});
  @override State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  bool _onboardingDone = false;

  // Camera
  CameraController?        _cam;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;

  // WebSocket
  WebSocketChannel?   _channel;
  StreamSubscription? _wsSub;
  bool _wsOk = false;

  // Session
  _SessionState _state = _SessionState.idle;
  String? _error;

  // Inference
  String _label = '—'; double _conf = 0.0; int _frames = 0;

  // Language
  String _lang = 'Hindi';
  String _regional = '';
  final Map<String, String> _langCodes = {
    'Hindi':'hi','Marathi':'mr','Gujarati':'gu',
    'Tamil':'ta','Telugu':'te','Kannada':'kn','Bengali':'bn',
  };

  // Builder
  final List<_GestureToken> _tokens = [];
  String _sentence = ''; String _sentenceRegional = '';
  final _AutoAddEngine _engine = _AutoAddEngine();

  // Stability
  double _stability = 0.0;
  Timer? _stabilityTimer;

  // Frame timer
  Timer? _frameTimer;
  bool   _capturing = false;

  // Transcript
  final TextEditingController _transcriptCtrl = TextEditingController();

  // Reconnect
  int    _reconnects = 0;
  static const _kMaxReconnects = 5;
  Timer? _reconnectTimer;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool   _ttsSpeaking = false;
  String _ttsTag = '';

  // Pulse + blob anims
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _blobCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _blobCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if ((s == AppLifecycleState.inactive || s == AppLifecycleState.paused)
        && _state == _SessionState.running) _stopSession();
  }

  Future<String> _translate(String text, String code) async {
    try {
      final url = 'https://translate.googleapis.com/translate_a/single'
          '?client=gtx&sl=en&tl=$code&dt=t&q=${Uri.encodeComponent(text)}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)[0][0][0] as String;
      }
    } catch (_) {}
    return text;
  }

  Future<void> _setupCameras() async {
    try { _cameras = await availableCameras(); } catch (_) {}
  }

  Future<bool> _initCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return false;
    try {
      _cam = CameraController(_cameras![_camIndex], ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: kIsWeb ? null : ImageFormatGroup.jpeg);
      await _cam!.initialize();
      if (!mounted) return false;
      setState(() {});
      return true;
    } catch (_) { return false; }
  }

  Future<void> _disposeCamera() async {
    final c = _cam; _cam = null;
    try {
      if (!kIsWeb && c != null && c.value.isInitialized
          && c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      await c?.dispose();
    } catch (_) {}
  }

  Future<bool> _connectWs() async {
    if (!BackendConfig.websocketEnabled) {
      _wsOk = false;
      return false;
    }
    for (var attempt = 0; attempt < _kWsConnectAttempts; attempt++) {
      try {
        await _wsSub?.cancel();
        _wsSub = null;
        await _channel?.sink.close();
      } catch (_) {}

      try {
        final channel = WebSocketChannel.connect(
          Uri.parse(BackendConfig.websocketUrl),
        );
        _channel = channel;
        await channel.ready.timeout(_kWsConnectTimeout);
        _wsOk = true;
        _reconnects = 0;
        _wsSub = channel.stream.listen(
          _onMsg,
          onError: _onErr,
          onDone: _onDone,
          cancelOnError: false,
        );
        return true;
      } catch (_) {
        _wsOk = false;
        try { await _wsSub?.cancel(); } catch (_) {}
        _wsSub = null;
        try { await _channel?.sink.close(); } catch (_) {}
        _channel = null;
        if (attempt < _kWsConnectAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
    return false;
  }

  void _onMsg(dynamic raw) {
    if (!mounted) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'prediction';
      if (type == 'ping') { _channel?.sink.add('__PING__'); return; }
      if (type == 'error') {
        final l = AppLocalizations.of(context);
        setState(() {
          _state = _SessionState.error;
          _error = data['message'] as String? ?? l.t('common_error');
        });
        return;
      }
      if (type == 'prediction') {
        final lbl  = (data['label'] ?? '—').toString();
        final conf = (data['confidence'] ?? 0.0).toDouble();
        setState(() { _label = lbl; _conf = conf; _frames = data['frame'] ?? _frames; });
        final toAdd = _engine.update(lbl, conf);
        if (toAdd != null) _addToken(toAdd, conf, fromAuto: true);
        _translate(lbl, _langCodes[_lang]!)
            .then((t) { if (mounted) setState(() => _regional = t); });
      }
    } catch (_) {}
  }

  void _onErr(Object _) {
    _wsOk = false;
    if (_state == _SessionState.running) _tryReconnect();
  }
  void _onDone() {
    _wsOk = false;
    if (_state == _SessionState.running) _tryReconnect();
  }

  void _tryReconnect() {
    if (_reconnects >= _kMaxReconnects) {
      final l = AppLocalizations.of(context);
      if (mounted) setState(() {
        _state = _SessionState.error;
        _error = l.t('translate_connection_lost_restart');
      });
      return;
    }
    _reconnects++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnects * 2), () async {
      if (!mounted || _state != _SessionState.running) return;
      if (!await _connectWs()) _tryReconnect();
    });
  }

  Future<void> _closeWs() async {
    _reconnectTimer?.cancel();
    await _wsSub?.cancel(); _wsSub = null;
    try {
      _channel?.sink.add('__STOP__');
      await Future.delayed(const Duration(milliseconds: 150));
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null; _wsOk = false;
  }

  void _startFrameTimer() {
    _frameTimer?.cancel(); _capturing = false;
    _frameTimer = Timer.periodic(
        Duration(milliseconds: _kFrameIntervalMs), (_) => _captureFrame());
  }

  Future<void> _captureFrame() async {
    if (_capturing || !_wsOk) return;
    if (_cam == null || !_cam!.value.isInitialized) return;
    _capturing = true;
    try {
      final f = await _cam!.takePicture();
      _channel!.sink.add(base64Encode(await f.readAsBytes()));
    } catch (_) {} finally { _capturing = false; }
  }

  void _stopFrameTimer() {
    _frameTimer?.cancel(); _frameTimer = null; _capturing = false;
  }

  void _startStabilityTimer() {
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        _stability = _engine.stabilityProgress(_label.toLowerCase().trim());
      });
    });
  }

  void _stopStabilityTimer() {
    _stabilityTimer?.cancel(); _stabilityTimer = null; _stability = 0;
  }

  Future<void> _startSession() async {
    final l = AppLocalizations.of(context);
    if (_state != _SessionState.idle && _state != _SessionState.error) return;
    setState(() {
      _state = _SessionState.connecting;
      _error = null; _label = '—'; _conf = 0; _frames = 0;
    });
    if (!await _initCamera()) {
      setState(() { _state = _SessionState.error; _error = l.t('translate_camera_error'); });
      return;
    }
    if (!await _connectWs()) {
      await _disposeCamera();
      setState(() {
        _state = _SessionState.error;
        _error = l.t('translate_backend_unreachable');
      });
      return;
    }
    _engine.reset();
    _startFrameTimer();
    _startStabilityTimer();
    setState(() => _state = _SessionState.running);
  }

  Future<void> _stopSession() async {
    if (_state == _SessionState.idle || _state == _SessionState.stopping) return;
    setState(() => _state = _SessionState.stopping);
    _stopFrameTimer(); _stopStabilityTimer();
    await _tts.stop();
    await _closeWs();
    await _disposeCamera();
    if (!mounted) return;
    setState(() { _state = _SessionState.idle; _label = '—'; _conf = 0; });
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final was = _state == _SessionState.running;
    if (was) await _stopSession();
    _camIndex = (_camIndex + 1) % _cameras!.length;
    if (was) await _startSession();
  }

  void _addToken(String lbl, double conf, {bool fromAuto = false}) {
    final n = lbl.toLowerCase().trim();
    if (!_kModelWords.contains(n)) return;
    setState(() {
      _tokens.add(_GestureToken(label: n, confidence: conf));
      _rebuildSentence();
    });
    if (fromAuto) HapticFeedback.lightImpact();
  }

  void _addCurrentManually() {
    if (_label == '—' || _label.isEmpty) return;
    _addToken(_label, _conf);
    _engine.reset();
  }

  void _removeToken(int i) {
    setState(() { _tokens.removeAt(i); _rebuildSentence(); });
  }
  void _removeLast() {
    if (_tokens.isEmpty) return;
    setState(() { _tokens.removeLast(); _rebuildSentence(); });
  }
  void _clearBuilder() {
    setState(() { _tokens.clear(); _sentence = ''; _sentenceRegional = ''; });
  }

  void _rebuildSentence() {
    _sentence = SentenceBuilder.build(_tokens.map((t) => t.label).toList());
    if (_sentence.isNotEmpty) {
      _translate(_sentence, _langCodes[_lang]!)
          .then((t) { if (mounted) setState(() => _sentenceRegional = t); });
    } else { _sentenceRegional = ''; }
  }

  void _commitToTranscript() {
    if (_sentence.isEmpty) return;
    final t = _transcriptCtrl.text;
    _transcriptCtrl.text = t.isEmpty ? _sentence : '$t\n$_sentence';
    _transcriptCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _transcriptCtrl.text.length));
    _clearBuilder();
  }

  Future<void> _speak(String text, String langCode, String tag) async {
    if (text.isEmpty || text == '—' || text == '…') return;
    if (_ttsSpeaking && _ttsTag == tag) {
      await _tts.stop();
      setState(() { _ttsSpeaking = false; _ttsTag = ''; });
      return;
    }
    await _tts.stop();
    try {
      final result = await _tts.setLanguage(langCode);
      if (result == null || (result is bool && !result)) {
        await _tts.setLanguage('en-US');
      }
    } catch (_) { await _tts.setLanguage('en-US'); }
    await _tts.setSpeechRate(0.90);
    await _tts.setPitch(1.0);
    setState(() { _ttsSpeaking = true; _ttsTag = tag; });
    await _tts.speak(text);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() { _ttsSpeaking = false; _ttsTag = ''; });
    });
  }

  String _ttsCode(String lang) {
    const m = {
      'Hindi':'hi-IN','Marathi':'mr-IN','Gujarati':'gu-IN',
      'Tamil':'ta-IN','Telugu':'te-IN','Kannada':'kn-IN','Bengali':'bn-IN',
    };
    return m[lang] ?? 'hi-IN';
  }

  void _copy(String text) {
    if (text.isEmpty) return;
    final l = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: _sp8),
          Text(l.t('common_copied_clipboard'), style: _body(13, Colors.white)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp24),
        duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose(); _blobCtrl.dispose();
    _stabilityTimer?.cancel();
    _stopSession(); _transcriptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d   = Theme.of(context).brightness == Brightness.dark;
    final w   = MediaQuery.of(context).size.width;
    final mob = w < 700;

    if (!_onboardingDone) {
      return _OnboardingFlow(d: d,
          onComplete: () {
            if (mounted) setState(() => _onboardingDone = true);
          });
    }
    if (mob) return _buildMobile(context, d);
    return _buildWeb(context, d, w > 900);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE — fullscreen camera + structured bottom panel
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext context, bool d) {
    final l       = AppLocalizations.of(context);
    final running = _state == _SessionState.running;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(fit: StackFit.expand, children: [

        // Camera feed
        if (running && _cam != null && _cam!.value.isInitialized)
          CameraPreview(_cam!)
        else
          _CamPlaceholder(d: d, state: _state),

        // Corner brackets
        IgnorePointer(child: CustomPaint(painter: _CornerPainter(
            color: _primary.withOpacity(running ? 0.7 : 0.3)))),

        // Top bar
        Positioned(top: 0, left: 0, right: 0,
            child: SafeArea(bottom: false,
                child: _MobileTopBar(
                    d: d, state: _state, l: l,
                    onBack: () => Navigator.pop(context),
                    onFlip: _switchCamera,
                    pulse: _pulseAnim))),

        // Label overlay
        if (running && _conf > 0.15)
          Positioned(top: 72, left: 0, right: 0,
              child: Center(child: _LabelOverlay(
                  label: _label, confidence: _conf,
                  stability: _stability, d: d))),

        // State overlays
        if (_state == _SessionState.connecting)
          _ConnectingOverlay(d: d),
        if (_state == _SessionState.error)
          _ErrorOverlay(d: d),
        if (_state == _SessionState.error && _error != null)
          Positioned(bottom: 300, left: _sp16, right: _sp16,
              child: _ErrorBanner(msg: _error!, d: d)),

        // Bottom panel
        Positioned(bottom: 0, left: 0, right: 0,
            child: _MobileBottomPanel(
              d: d, state: _state, label: _label, conf: _conf,
              regional: _regional, selectedLang: _lang,
              langCodes: _langCodes,
              tokens: _tokens, sentence: _sentence,
              sentenceRegional: _sentenceRegional,
              stability: _stability,
              ttsSpeaking: _ttsSpeaking, ttsTag: _ttsTag,
              transcriptCtrl: _transcriptCtrl,
              onStart: _startSession, onStop: _stopSession,
              onAddManual: _addCurrentManually,
              onRemoveLast: _removeLast,
              onClearAll: _clearBuilder,
              onCommit: _commitToTranscript,
              onRemoveToken: _removeToken,
              onLangChanged: (v) {
                if (v != null && mounted) setState(() => _lang = v);
              },
              onCopy: _copy, onSpeak: _speak, ttsCode: _ttsCode, l: l,
              blobAnim: _blobCtrl,
            )),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  WEB — card layout with GlobalNavbar
  // ════════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext context, bool d, bool wide) {
    return Scaffold(
      backgroundColor: d ? _dBg : _lBg,
      body: Stack(children: [
        // Ambient blobs behind everything
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, __) => CustomPaint(
                painter: _AmbientBlobPainter(
                    dark: d, animValue: _blobCtrl.value)),
          ),
        ),
        SafeArea(child: Column(children: [
          GlobalNavbar(toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale, activeRoute: 'translate'),
          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(_sp24, _sp16, _sp24, _sp32),
            child: wide ? _webWide(d) : _webNarrow(d),
          )),
        ])),
      ]),
    );
  }

  Widget _webWide(bool d) => Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 6, child: _webCamera(d)),
    const SizedBox(width: _sp16),
    Expanded(flex: 5, child: Column(children: [
      _webDetection(d), const SizedBox(height: _sp16),
      _webBuilder(d),   const SizedBox(height: _sp16),
      _webTranscript(d),
    ])),
  ]);

  Widget _webNarrow(bool d) => Column(children: [
    _webCamera(d),    const SizedBox(height: _sp16),
    _webDetection(d), const SizedBox(height: _sp16),
    _webBuilder(d),   const SizedBox(height: _sp16),
    _webTranscript(d),
  ]);

  // ── Web: Camera card ─────────────────────────────────────────────────
  Widget _webCamera(bool d) {
    final l       = AppLocalizations.of(context);
    final running = _state == _SessionState.running;
    final accent  = d ? _primaryDark : _primary;
    final border  = d ? _dBorder   : _lBorder;
    final textClr = d ? _dText     : _lText;
    final subClr  = d ? _dTextSub  : _lTextSub;

    return _UX4GCard(d: d, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Card header
      Row(children: [
        _IconBadge(icon: Icons.sensors_rounded, color: accent, d: d),
        const SizedBox(width: _sp12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('translate_vision_title'),
              style: _heading(15, textClr)),
          Text(l.t('translate_vision_sub'),
              style: _body(12, subClr)),
        ])),
        _SessionStatusChip(state: _state, d: d),
      ]),
      const SizedBox(height: _sp16),

      // Camera view
      AspectRatio(aspectRatio: 16 / 10,
          child: ClipRRect(borderRadius: BorderRadius.circular(10),
              child: Container(
                color: const Color(0xFF0A0A0A),
                child: Stack(fit: StackFit.expand, children: [
                  if (running && _cam != null && _cam!.value.isInitialized)
                    CameraPreview(_cam!)
                  else
                    _WebCamPlaceholder(d: d),
                  if (running)
                    IgnorePointer(child: CustomPaint(
                        painter: _CornerPainter(
                            color: _primary.withOpacity(0.6)))),
                  if (running)
                    Positioned(top: _sp8, left: _sp8,
                        child: _LiveBadge(pulse: _pulseAnim, d: d)),
                  if (running && _conf > 0.15)
                    Positioned(bottom: _sp8, left: _sp8, right: _sp8,
                        child: _LabelOverlay(
                            label: _label, confidence: _conf,
                            stability: _stability, d: d)),
                  if (_state == _SessionState.connecting)
                    _ConnectingOverlay(d: d),
                  if (_state == _SessionState.error)
                    _ErrorOverlay(d: d),
                ]),
              ))),
      const SizedBox(height: _sp12),

      Row(children: [
        OutlinedButton.icon(
          onPressed: _switchCamera,
          icon: const Icon(Icons.flip_camera_android_rounded, size: 14),
          label: Text(l.t('translate_switch')),
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: _sp12),
        Expanded(child: _WebSessionButton(
            state: _state, d: d,
            onStart: _startSession, onStop: _stopSession)),
      ]),

      if (_state == _SessionState.error && _error != null) ...[
        const SizedBox(height: _sp12),
        _ErrorBanner(msg: _error!, d: d),
      ],
    ]));
  }

  // ── Web: Detection card ───────────────────────────────────────────────
  Widget _webDetection(bool d) {
    final l       = AppLocalizations.of(context);
    final active  = _state == _SessionState.running;
    final textClr = d ? _dText    : _lText;
    final subClr  = d ? _dTextSub : _lTextSub;
    final mutedClr = d ? _dTextMuted : _lTextMuted;

    return _UX4GCard(d: d, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _IconBadge(icon: Icons.translate_rounded,
            color: d ? _successDark : _success, d: d),
        const SizedBox(width: _sp12),
        Expanded(child: Text(l.t('translate_prediction'),
            style: _heading(14, textClr))),
        _LangDropdownWeb(value: _lang,
            options: _langCodes.keys.toList(), d: d,
            onChanged: (v) { if (v != null) setState(() => _lang = v); }),
      ]),
      const SizedBox(height: _sp16),

      _WebDetectionRow(
          code: 'EN', color: d ? _primaryDark : _primary, d: d,
          text: active ? _label : l.t('translate_waiting'),
          isActive: active,
          speaking: _ttsSpeaking && _ttsTag == 'en',
          onSpeak: active
              ? () => _speak(_label, 'en-US', 'en') : null),
      const SizedBox(height: _sp8),

      _WebDetectionRow(
          code: _lang.substring(0, 2).toUpperCase(),
          color: d ? _successDark : _success, d: d,
          text: active
              ? (_regional.isNotEmpty ? _regional : '…')
              : l.t('translate_waiting'),
          isActive: active,
          speaking: _ttsSpeaking && _ttsTag == 'regional',
          onSpeak: active && _regional.isNotEmpty
              ? () => _speak(_regional, _ttsCode(_lang), 'regional')
              : null),

      const SizedBox(height: _sp16),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l.t('obj_page_confidence').toUpperCase(),
            style: _txtLabel(10, mutedClr, w: FontWeight.w700)),
        Text(active ? '${(_conf * 100).toStringAsFixed(0)}%' : '—',
            style: _txtLabel(12, subClr)),
      ]),
      const SizedBox(height: _sp8),
      _ConfBar(value: active ? _conf : 0, d: d),

      if (active && _stability > 0) ...[
        const SizedBox(height: _sp12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${l.t('translate_frames')}: $_frames',
              style: _body(11, mutedClr)),
          Row(children: [
            SizedBox(width: 72, height: 3,
                child: ClipRRect(borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: _stability,
                        backgroundColor: d ? _dBorder : _lBorder,
                        valueColor: AlwaysStoppedAnimation(
                            _stability >= 1.0
                                ? (d ? _successDark : _success)
                                : (d ? _warningDark : _warning))))),
            const SizedBox(width: _sp8),
            Text(_stability >= 1.0
                ? l.t('translate_adding')
                : l.t('translate_hold_sign'),
                style: _txtLabel(11,
                    _stability >= 1.0
                        ? (d ? _successDark : _success)
                        : (d ? _warningDark : _warning),
                    w: FontWeight.w700)),
          ]),
        ]),
      ],
    ]));
  }

  // ── Web: Sentence builder card ────────────────────────────────────────
  Widget _webBuilder(bool d) {
    final l        = AppLocalizations.of(context);
    final accent   = d ? _purpleDark : _purple;
    final textClr  = d ? _dText    : _lText;
    final subClr   = d ? _dTextSub : _lTextSub;
    final mutedClr = d ? _dTextMuted : _lTextMuted;

    return _UX4GCard(d: d, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _IconBadge(icon: Icons.auto_awesome_outlined, color: accent, d: d),
        const SizedBox(width: _sp12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('translate_sentence_builder'), style: _heading(14, textClr)),
          Text(l.t('translate_auto_chain_subtitle'), style: _body(11.5, subClr)),
        ])),
        Semantics(
          label: l.t('translate_add_sign'), button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _addCurrentManually,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: _sp12, vertical: _sp8),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: accent.withOpacity(0.25), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: accent, size: 14),
                const SizedBox(width: _sp4),
                Text(l.t('translate_add_sign'),
                    style: _txtLabel(12, accent, w: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
      const SizedBox(height: _sp16),

      // Info box
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _sp12, vertical: _sp8),
        decoration: BoxDecoration(
            color: d ? _infoDark.withOpacity(0.10) : _infoLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: d ? _infoDark.withOpacity(0.25)
                    : _info.withOpacity(0.25), width: 1)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 14,
              color: d ? _infoDark : _info),
          const SizedBox(width: _sp8),
          Expanded(child: Text(l.t('translate_builder_info'),
              style: _body(12, d ? _infoDark : _info))),
        ]),
      ),
      const SizedBox(height: _sp16),

      if (_tokens.isEmpty)
        _EmptyBuilderWeb(d: d)
      else
        Wrap(spacing: _sp8, runSpacing: _sp8,
            children: _tokens.asMap().entries.map((e) =>
                _TokenChip(index: e.key + 1, token: e.value,
                    isLast: e.key == _tokens.length - 1, d: d,
                    onRemove: () => _removeToken(e.key))).toList()),

      if (_tokens.isNotEmpty) ...[
        const SizedBox(height: _sp16),
        Row(children: [
          Icon(Icons.arrow_downward_rounded, size: 12,
              color: d ? _dTextMuted : _lTextMuted),
          const SizedBox(width: _sp4),
          Text(l.t('translate_generated_sentence').toUpperCase(),
              style: _txtLabel(10, d ? _dTextMuted : _lTextMuted,
                  w: FontWeight.w700)),
        ]),
        const SizedBox(height: _sp8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(_sp16),
          decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: accent.withOpacity(0.25), width: 1)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _LangBadge(code: 'EN', color: accent),
              const SizedBox(width: _sp8),
              Expanded(child: Text(
                  _sentence.isNotEmpty ? _sentence : '…',
                  style: _heading(16, textClr))),
              _ActionIconBtn(
                  icon: Icons.copy_outlined, color: mutedClr,
                  tooltip: l.t('common_copy'),
                  onTap: () => _copy(_sentence)),
              _ActionIconBtn(
                  icon: _ttsSpeaking && _ttsTag == 'sentence_en'
                      ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: accent, tooltip: l.t('common_speak'),
                  onTap: () => _speak(_sentence, 'en-US', 'sentence_en')),
            ]),
            if (_sentenceRegional.isNotEmpty) ...[
              const SizedBox(height: _sp12),
              Divider(height: 1, thickness: 1,
                  color: d ? _dBorderSub : _lBorderSub),
              const SizedBox(height: _sp12),
              Row(children: [
                _LangBadge(code: _lang.substring(0, 2).toUpperCase(),
                    color: d ? _successDark : _success),
                const SizedBox(width: _sp8),
                Expanded(child: Text(_sentenceRegional,
                    style: _heading(16, d ? _successDark : _success))),
                _ActionIconBtn(
                    icon: Icons.copy_outlined, color: mutedClr,
                    tooltip: l.t('common_copy'),
                    onTap: () => _copy(_sentenceRegional)),
                _ActionIconBtn(
                    icon: _ttsSpeaking && _ttsTag == 'sentence_reg'
                        ? Icons.stop_rounded : Icons.volume_up_rounded,
                    color: d ? _successDark : _success,
                    tooltip: l.t('common_speak'),
                    onTap: () => _speak(
                        _sentenceRegional, _ttsCode(_lang), 'sentence_reg')),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: _sp12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _commitToTranscript,
            icon: const Icon(Icons.save_alt_rounded, size: 14),
            label: Text(l.t('translate_save_transcript')),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: d ? _primaryDark : _primary,
                side: BorderSide(
                    color: (d ? _primaryDark : _primary).withOpacity(0.35)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          )),
          const SizedBox(width: _sp8),
          Tooltip(message: l.t('translate_remove_last'),
              child: IconButton(
                onPressed: _removeLast,
                icon: const Icon(Icons.backspace_outlined),
                color: d ? _warningDark : _warning,
                style: IconButton.styleFrom(
                    backgroundColor:
                    (d ? _warningDark : _warning).withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              )),
          const SizedBox(width: _sp8),
          Tooltip(message: l.t('translate_clear_all'),
              child: IconButton(
                onPressed: _clearBuilder,
                icon: const Icon(Icons.delete_sweep_outlined),
                color: d ? _dangerDark : _danger,
                style: IconButton.styleFrom(
                    backgroundColor:
                    (d ? _dangerDark : _danger).withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              )),
        ]),
      ],
    ]));
  }

  // ── Web: Transcript card ──────────────────────────────────────────────
  Widget _webTranscript(bool d) {
    final l       = AppLocalizations.of(context);
    final accent  = d ? _primaryDark : _primary;
    final textClr = d ? _dText    : _lText;
    final bg2     = d ? _dSurface2 : _lSurface2;
    final border  = d ? _dBorder   : _lBorder;

    return _UX4GCard(d: d, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _IconBadge(icon: Icons.article_outlined,
            color: d ? _warningDark : _warning, d: d),
        const SizedBox(width: _sp12),
        Text(l.t('translate_transcription'), style: _heading(14, textClr)),
      ]),
      const SizedBox(height: _sp12),
      Container(
        decoration: BoxDecoration(
            color: bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1)),
        child: TextField(
          controller: _transcriptCtrl, maxLines: 5,
          style: _body(14, textClr),
          decoration: InputDecoration(
              hintText: l.t('translate_hint'),
              hintStyle: _body(13, d ? _dTextMuted : _lTextMuted),
              contentPadding: const EdgeInsets.all(_sp16),
              border: InputBorder.none),
        ),
      ),
      const SizedBox(height: _sp12),
      Row(children: [
        OutlinedButton.icon(
          onPressed: () => _copy(_transcriptCtrl.text),
          icon: const Icon(Icons.copy_outlined, size: 14),
          label: Text(l.t('translate_copy_transcript')),
          style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: _sp8),
        OutlinedButton.icon(
          onPressed: _transcriptCtrl.clear,
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          label: Text(l.t('common_clear')),
          style: OutlinedButton.styleFrom(
              foregroundColor: d ? _dangerDark : _danger,
              side: BorderSide(
                  color: (d ? _dangerDark : _danger).withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
      ]),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE COMPONENTS
// ══════════════════════════════════════════════════════════════════════

class _MobileTopBar extends StatelessWidget {
  final bool d;
  final _SessionState state;
  final AppLocalizations l;
  final Animation<double> pulse;
  final VoidCallback onBack, onFlip;
  const _MobileTopBar({required this.d, required this.state, required this.l,
    required this.pulse, required this.onBack, required this.onFlip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_sp16, _sp8, _sp16, 0),
      child: Row(children: [
        Semantics(
          label: l.t('common_back'), button: true,
          child: _CamOverlayBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
        ),
        const Spacer(),
        _StatusPillOverlay(state: state, pulse: pulse, l: l),
        const Spacer(),
        Semantics(
          label: l.t('translate_switch'), button: true,
          child: _CamOverlayBtn(
              icon: Icons.flip_camera_ios_rounded, onTap: onFlip),
        ),
      ]),
    );
  }
}

class _CamOverlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CamOverlayBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.15), width: 1)),
          child: Icon(icon, color: Colors.white, size: 20)));
}

class _StatusPillOverlay extends StatelessWidget {
  final _SessionState state;
  final Animation<double> pulse;
  final AppLocalizations l;
  const _StatusPillOverlay({required this.state, required this.pulse,
    required this.l});

  @override
  Widget build(BuildContext context) {
    Color c; String t;
    switch (state) {
      case _SessionState.running:    c = _successDark; t = l.t('common_live'); break;
      case _SessionState.connecting: c = _warningDark; t = l.t('common_connecting'); break;
      case _SessionState.error:      c = _dangerDark;  t = l.t('common_error'); break;
      default:                       c = Colors.white54; t = l.t('common_ready');
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp4),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.48),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.40), width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c,
                  boxShadow: [BoxShadow(
                      color: c.withOpacity(pulse.value * 0.6),
                      blurRadius: 5)])),
          const SizedBox(width: _sp8),
          Text(t, style: _txtLabel(11, c, w: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Mobile bottom panel ───────────────────────────────────────────────
class _MobileBottomPanel extends StatefulWidget {
  final bool d;
  final _SessionState state;
  final String label, regional, selectedLang, sentence, sentenceRegional;
  final double conf, stability;
  final Map<String, String> langCodes;
  final List<_GestureToken> tokens;
  final bool ttsSpeaking; final String ttsTag;
  final TextEditingController transcriptCtrl;
  final VoidCallback onStart, onStop, onAddManual, onRemoveLast, onClearAll, onCommit;
  final void Function(int) onRemoveToken;
  final void Function(String?) onLangChanged;
  final void Function(String) onCopy;
  final Future<void> Function(String, String, String) onSpeak;
  final String Function(String) ttsCode;
  final AppLocalizations l;
  final AnimationController blobAnim;

  const _MobileBottomPanel({
    required this.d, required this.state, required this.label,
    required this.conf, required this.regional, required this.selectedLang,
    required this.langCodes, required this.tokens, required this.sentence,
    required this.sentenceRegional, required this.stability,
    required this.ttsSpeaking, required this.ttsTag,
    required this.transcriptCtrl, required this.onStart, required this.onStop,
    required this.onAddManual, required this.onRemoveLast, required this.onClearAll,
    required this.onCommit, required this.onRemoveToken, required this.onLangChanged,
    required this.onCopy, required this.onSpeak, required this.ttsCode,
    required this.l, required this.blobAnim,
  });

  @override State<_MobileBottomPanel> createState() => _MobileBottomPanelState();
}

class _MobileBottomPanelState extends State<_MobileBottomPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l   = widget.l;
    final d   = widget.d;
    final bg  = d ? _dSurface  : _lSurface;
    final brd = d ? _dBorder   : const Color(0xFFDDE3EE);

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: brd, width: 1)),
          boxShadow: d ? [] : [
            BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.05),
              blurRadius: 32, spreadRadius: -4, offset: const Offset(0, -8),
            ),
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Padding(padding: const EdgeInsets.only(top: _sp8, bottom: _sp4),
            child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: d ? _dBorder : const Color(0xFFCDD5DF),
                    borderRadius: BorderRadius.circular(2)))),

        // Session row
        Padding(
          padding: const EdgeInsets.fromLTRB(_sp16, _sp4, _sp16, _sp12),
          child: Row(children: [
            Expanded(child: _MobileSessionBtn(state: widget.state, d: d,
                onStart: widget.onStart, onStop: widget.onStop)),
            const SizedBox(width: _sp12),
            _LangDropdownMobile(value: widget.selectedLang,
                options: widget.langCodes.keys.toList(), d: d,
                onChanged: widget.onLangChanged),
          ]),
        ),

        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _sp16),
          child: Row(children: [
            _MobileTab(label: l.t('common_output'),
                icon: Icons.translate_rounded,
                active: _tab == 0, d: d, onTap: () => setState(() => _tab = 0)),
            const SizedBox(width: _sp8),
            _MobileTab(label: l.t('common_builder'),
                icon: Icons.auto_awesome_outlined,
                active: _tab == 1, d: d, badge: widget.tokens.length,
                onTap: () => setState(() => _tab = 1)),
            const SizedBox(width: _sp8),
            _MobileTab(label: l.t('common_transcript'),
                icon: Icons.article_outlined,
                active: _tab == 2, d: d, onTap: () => setState(() => _tab = 2)),
          ]),
        ),
        const SizedBox(height: _sp12),

        // Tab content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(key: ValueKey(_tab),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, 0),
                  child: _tab == 0
                      ? _MobileOutputTab(widget: widget, d: d)
                      : _tab == 1
                      ? _MobileBuilderTab(widget: widget, d: d)
                      : _MobileTranscriptTab(widget: widget, d: d))),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + _sp8),
      ]),
    );
  }
}

class _MobileTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, d;
  final VoidCallback onTap;
  final int badge;
  const _MobileTab({required this.label, required this.icon,
    required this.active, required this.d, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final accent  = d ? _primaryDark : _primary;
    final mutedClr = d ? _dTextMuted : _lTextMuted;
    return Expanded(child: Semantics(
      selected: active, button: true, label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp8),
          decoration: BoxDecoration(
              color: active ? accent.withOpacity(0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? accent.withOpacity(0.30) : Colors.transparent,
                  width: 1)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12,
                color: active ? accent : mutedClr),
            const SizedBox(width: _sp4),
            Text(label, style: _txtLabel(11,
                active ? accent : mutedClr,
                w: active ? FontWeight.w700 : FontWeight.w400)),
            if (badge > 0) ...[
              const SizedBox(width: _sp4),
              Container(width: 16, height: 16,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Center(child: Text('$badge', style: _txtLabel(9, Colors.white,
                      w: FontWeight.w700)))),
            ],
          ]),
        ),
      ),
    ));
  }
}

class _MobileSessionBtn extends StatefulWidget {
  final _SessionState state;
  final bool d;
  final VoidCallback onStart, onStop;
  const _MobileSessionBtn({required this.state, required this.d,
    required this.onStart, required this.onStop});
  @override State<_MobileSessionBtn> createState() => _MobileSessionBtnState();
}

class _MobileSessionBtnState extends State<_MobileSessionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final running = widget.state == _SessionState.running;
    final loading = widget.state == _SessionState.connecting
        || widget.state == _SessionState.stopping;
    final err     = widget.state == _SessionState.error;

    final Color bgColor;
    final Color textColor;
    final String lbl;
    final IconData ico;

    if (running) {
      bgColor = widget.d ? _dangerDark.withOpacity(0.12) : _dangerLight;
      textColor = widget.d ? _dangerDark : _danger;
      lbl = l.t('common_stop');
      ico = Icons.stop_rounded;
    } else if (err) {
      bgColor = widget.d ? _warningDark.withOpacity(0.12) : _warningLight;
      textColor = widget.d ? _warningDark : _warning;
      lbl = l.t('common_retry');
      ico = Icons.refresh_rounded;
    } else if (loading) {
      bgColor = widget.d ? _dSurface2 : _lSurface2;
      textColor = widget.d ? _dTextSub : _lTextSub;
      lbl = widget.state == _SessionState.connecting
          ? l.t('common_connecting') : l.t('common_stopping');
      ico = Icons.hourglass_empty_rounded;
    } else {
      bgColor = widget.d ? _primaryDark : _primary;
      textColor = Colors.white;
      lbl = l.t('common_start');
      ico = Icons.videocam_rounded;
    }

    return Semantics(
      label: lbl, button: true,
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) {
          setState(() => _pressed = false);
          if (!loading) (running ? widget.onStop : widget.onStart)();
        },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 80),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: (running || err)
                      ? Border.all(color: textColor.withOpacity(0.30), width: 1)
                      : null),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (loading)
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: textColor))
                else Icon(ico, color: textColor, size: 16),
                const SizedBox(width: _sp8),
                Text(lbl, style: _txtLabel(14, textColor, w: FontWeight.w700)),
              ]),
            )),
      ),
    );
  }
}

class _LangDropdownMobile extends StatelessWidget {
  final String value;
  final List<String> options;
  final bool d;
  final void Function(String?) onChanged;
  const _LangDropdownMobile({required this.value, required this.options,
    required this.d, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp8),
      decoration: BoxDecoration(
          color: d ? _dSurface2 : _lSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isDense: true,
          dropdownColor: d ? _dSurface2 : _lSurface,
          style: _body(12, d ? _dText : _lText, w: FontWeight.w600),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: d ? _dTextSub : _lTextSub, size: 14),
          items: options.map((l) => DropdownMenuItem(
              value: l, child: Text(l))).toList(),
          onChanged: onChanged)));
}

// Mobile output tab
class _MobileOutputTab extends StatelessWidget {
  final _MobileBottomPanel widget;
  final bool d;
  const _MobileOutputTab({required this.widget, required this.d});

  @override
  Widget build(BuildContext context) {
    final l      = widget.l;
    final active = widget.state == _SessionState.running;
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      _MobileDetRow(code: 'EN', color: d ? _primaryDark : _primary, d: d,
          text: active ? widget.label : '—',
          speaking: widget.ttsSpeaking && widget.ttsTag == 'en',
          onSpeak: active
              ? () => widget.onSpeak(widget.label, 'en-US', 'en') : null),
      const SizedBox(height: _sp8),
      _MobileDetRow(
          code: widget.selectedLang.substring(0, 2).toUpperCase(),
          color: d ? _successDark : _success, d: d,
          text: active
              ? (widget.regional.isNotEmpty ? widget.regional : '…') : '—',
          speaking: widget.ttsSpeaking && widget.ttsTag == 'regional',
          onSpeak: active && widget.regional.isNotEmpty
              ? () => widget.onSpeak(widget.regional,
              widget.ttsCode(widget.selectedLang), 'regional') : null),
      if (active) ...[
        const SizedBox(height: _sp12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.t('obj_page_confidence').toUpperCase(),
              style: _txtLabel(10, d ? _dTextMuted : _lTextMuted,
                  w: FontWeight.w700)),
          Text('${(widget.conf * 100).toStringAsFixed(0)}%',
              style: _txtLabel(12, d ? _dTextSub : _lTextSub)),
        ]),
        const SizedBox(height: _sp4),
        _ConfBar(value: widget.conf, d: d),
      ],
      const SizedBox(height: _sp8),
    ]);
  }
}

class _MobileDetRow extends StatelessWidget {
  final String code, text;
  final Color color;
  final bool d, speaking;
  final VoidCallback? onSpeak;
  const _MobileDetRow({required this.code, required this.text,
    required this.color, required this.d, required this.speaking,
    this.onSpeak});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp12),
      decoration: BoxDecoration(
          color: d ? _dSurface2 : _lSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
      child: Row(children: [
        _LangBadge(code: code, color: color),
        const SizedBox(width: _sp12),
        Expanded(child: Text(text, style: _heading(18, color))),
        if (onSpeak != null)
          Semantics(
            label: speaking
                ? AppLocalizations.of(context).t('common_stop')
                : AppLocalizations.of(context).t('common_speak'),
            button: true,
            child: GestureDetector(
              onTap: onSpeak,
              child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: speaking
                          ? color.withOpacity(0.15)
                          : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withOpacity(0.25), width: 1)),
                  child: Icon(
                      speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                      color: color, size: 16)),
            ),
          ),
      ]));
}

// Mobile builder tab
class _MobileBuilderTab extends StatelessWidget {
  final _MobileBottomPanel widget;
  final bool d;
  const _MobileBuilderTab({required this.widget, required this.d});

  @override
  Widget build(BuildContext context) {
    final l      = widget.l;
    final accent = d ? _purpleDark : _purple;
    final green  = d ? _successDark : _success;

    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      if (widget.tokens.isEmpty)
        Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: _sp16),
            decoration: BoxDecoration(
                color: d ? _dSurface2 : _lSurface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
            child: Column(children: [
              Icon(Icons.gesture_rounded,
                  color: d ? _dTextMuted : _lTextMuted, size: 26),
              const SizedBox(height: _sp4),
              Text(l.t('translate_hold_sign_add'),
                  style: _body(12, d ? _dTextSub : _lTextSub)),
            ]))
      else
        Wrap(spacing: _sp8, runSpacing: _sp8,
            children: widget.tokens.asMap().entries.map((e) =>
                _TokenChip(index: e.key + 1, token: e.value,
                    isLast: e.key == widget.tokens.length - 1,
                    d: d, onRemove: () => widget.onRemoveToken(e.key))).toList()),

      if (widget.tokens.isNotEmpty) ...[
        const SizedBox(height: _sp12),
        Container(width: double.infinity, padding: const EdgeInsets.all(_sp12),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.25), width: 1)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(
                        widget.sentence.isNotEmpty ? widget.sentence : '…',
                        style: _heading(15, d ? _dText : _lText))),
                    _ActionIconBtn(
                        icon: Icons.copy_outlined,
                        color: d ? _dTextMuted : _lTextMuted,
                        tooltip: l.t('common_copy'),
                        onTap: () => widget.onCopy(widget.sentence)),
                    _ActionIconBtn(
                        icon: widget.ttsSpeaking && widget.ttsTag == 'sentence_en'
                            ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: accent, tooltip: l.t('common_speak'),
                        onTap: () => widget.onSpeak(
                            widget.sentence, 'en-US', 'sentence_en')),
                  ]),
                  if (widget.sentenceRegional.isNotEmpty) ...[
                    Divider(height: _sp12,
                        color: d ? _dBorderSub : _lBorderSub),
                    Text(widget.sentenceRegional, style: _heading(15, green)),
                  ],
                ])),
      ],

      const SizedBox(height: _sp12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: widget.onAddManual,
          icon: const Icon(Icons.add_rounded, size: 14),
          label: Text(l.t('translate_add_sign')),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: d ? _primaryDark : _primary,
              side: BorderSide(
                  color: (d ? _primaryDark : _primary).withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        )),
        if (widget.tokens.isNotEmpty) ...[
          const SizedBox(width: _sp8),
          Expanded(child: ElevatedButton.icon(
            onPressed: widget.onCommit,
            icon: const Icon(Icons.save_alt_rounded, size: 14),
            label: Text(l.t('common_save')),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: d ? _successDark : _success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          )),
          const SizedBox(width: _sp8),
          IconButton(
              onPressed: widget.onRemoveLast,
              icon: const Icon(Icons.backspace_outlined),
              color: d ? _warningDark : _warning,
              style: IconButton.styleFrom(
                  backgroundColor:
                  (d ? _warningDark : _warning).withOpacity(0.10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)))),
          const SizedBox(width: _sp4),
          IconButton(
              onPressed: widget.onClearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              color: d ? _dangerDark : _danger,
              style: IconButton.styleFrom(
                  backgroundColor:
                  (d ? _dangerDark : _danger).withOpacity(0.10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)))),
        ],
      ]),
      const SizedBox(height: _sp8),
    ]);
  }
}

// Mobile transcript tab
class _MobileTranscriptTab extends StatelessWidget {
  final _MobileBottomPanel widget;
  final bool d;
  const _MobileTranscriptTab({required this.widget, required this.d});

  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min, children: [
    Container(
        decoration: BoxDecoration(
            color: d ? _dSurface2 : _lSurface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
        child: TextField(
          controller: widget.transcriptCtrl, maxLines: 4,
          style: _body(13.5, d ? _dText : _lText),
          decoration: InputDecoration(
              hintText: widget.l.t('translate_hint'),
              hintStyle: _body(13, d ? _dTextMuted : _lTextMuted),
              contentPadding: const EdgeInsets.all(_sp12),
              border: InputBorder.none),
        )),
    const SizedBox(height: _sp8),
    Row(children: [
      OutlinedButton.icon(
        onPressed: () => widget.onCopy(widget.transcriptCtrl.text),
        icon: const Icon(Icons.copy_outlined, size: 13),
        label: Text(widget.l.t('common_copy')),
        style: OutlinedButton.styleFrom(
            foregroundColor: d ? _primaryDark : _primary,
            side: BorderSide(
                color: (d ? _primaryDark : _primary).withOpacity(0.35)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
      ),
      const SizedBox(width: _sp8),
      OutlinedButton.icon(
        onPressed: widget.transcriptCtrl.clear,
        icon: const Icon(Icons.delete_outline_rounded, size: 13),
        label: Text(widget.l.t('common_clear')),
        style: OutlinedButton.styleFrom(
            foregroundColor: d ? _dangerDark : _danger,
            side: BorderSide(
                color: (d ? _dangerDark : _danger).withOpacity(0.35)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
      ),
    ]),
    const SizedBox(height: _sp8),
  ]);
}

// ══════════════════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ══════════════════════════════════════════════════════════════════════

class _CamPlaceholder extends StatelessWidget {
  final bool d;
  final _SessionState state;
  const _CamPlaceholder({required this.d, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF080810),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                    color: Colors.white.withOpacity(0.10), width: 1)),
            child: Icon(Icons.videocam_off_rounded,
                color: Colors.white.withOpacity(0.25), size: 32)),
        const SizedBox(height: _sp16),
        Text(state == _SessionState.error
            ? l.t('translate_camera_error')
            : l.t('translate_tap_start'),
            style: _body(14, Colors.white38)),
      ])),
    );
  }
}

class _WebCamPlaceholder extends StatelessWidget {
  final bool d;
  const _WebCamPlaceholder({required this.d});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(_sp16),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05)),
          child: Icon(Icons.videocam_off_rounded,
              color: Colors.white.withOpacity(0.22), size: 28)),
      const SizedBox(height: _sp12),
      Text(l.t('translate_press_start'),
          style: _body(13, Colors.white38)),
    ]));
  }
}

class _LabelOverlay extends StatelessWidget {
  final String label;
  final double confidence, stability;
  final bool d;
  const _LabelOverlay({required this.label, required this.confidence,
    required this.stability, required this.d});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (label == '—' || label.isEmpty) return const SizedBox.shrink();
    final confColor = confidence > 0.75 ? _successDark : _warningDark;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: _sp16, vertical: _sp12),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.60),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withOpacity(0.10), width: 1)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: _heading(22, Colors.white)),
          const SizedBox(width: _sp12),
          Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: _sp8, vertical: _sp4),
              decoration: BoxDecoration(
                  color: confColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('${(confidence * 100).toStringAsFixed(0)}%',
                  style: _txtLabel(11, confColor, w: FontWeight.w700))),
        ]),
        if (stability > 0) ...[
          const SizedBox(height: _sp8),
          SizedBox(width: 140,
              child: ClipRRect(borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                      value: stability, minHeight: 3,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(
                          stability >= 1.0
                              ? _successDark : Colors.white54)))),
          const SizedBox(height: _sp4),
          Text(stability >= 1.0
              ? l.t('translate_adding')
              : l.t('translate_hold_steady'),
              style: _txtLabel(10,
                  stability >= 1.0 ? _successDark : Colors.white54,
                  w: FontWeight.w600)),
        ],
      ]),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final Animation<double> pulse;
  final bool d;
  const _LiveBadge({required this.pulse, required this.d});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _sp8, vertical: _sp4),
        decoration: BoxDecoration(
            color: _danger.withOpacity(0.90),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(
                color: _danger.withOpacity(0.4 * pulse.value),
                blurRadius: 8)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 3, backgroundColor: Colors.white),
          const SizedBox(width: _sp4),
          Text(AppLocalizations.of(context).t('common_live').toUpperCase(),
              style: _txtLabel(9, Colors.white, w: FontWeight.w800)),
        ]),
      ));
}

class _ConnectingOverlay extends StatelessWidget {
  final bool d;
  const _ConnectingOverlay({required this.d});
  @override
  Widget build(BuildContext context) => Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primary),
            strokeWidth: 2.5),
        const SizedBox(height: _sp12),
        Text(AppLocalizations.of(context)
            .t('translate_establishing_connection'),
            style: _txtLabel(13, _primaryDark, w: FontWeight.w700)),
      ])));
}

class _ErrorOverlay extends StatelessWidget {
  final bool d;
  const _ErrorOverlay({required this.d});
  @override
  Widget build(BuildContext context) => Container(
      color: Colors.black.withOpacity(0.70),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.warning_amber_rounded, color: _dangerDark, size: 32),
        const SizedBox(height: _sp8),
        Text(AppLocalizations.of(context).t('translate_connection_error'),
            style: _heading(15, Colors.white70)),
      ])));
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  final bool d;
  const _ErrorBanner({required this.msg, required this.d});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: _sp12, vertical: _sp12),
      decoration: BoxDecoration(
          color: d ? _dangerDark.withOpacity(0.12) : _dangerLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: d ? _dangerDark.withOpacity(0.30)
                  : _danger.withOpacity(0.30), width: 1)),
      child: Row(children: [
        Icon(Icons.error_outline_rounded,
            color: d ? _dangerDark : _danger, size: 16),
        const SizedBox(width: _sp8),
        Expanded(child: Text(msg,
            style: _body(12.5, d ? _dangerDark : _danger))),
      ]));
}

class _TokenChip extends StatelessWidget {
  final int index;
  final _GestureToken token;
  final bool isLast, d;
  final VoidCallback onRemove;
  const _TokenChip({required this.index, required this.token,
    required this.isLast, required this.d, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final accent = d ? _purpleDark : _purple;
    final border = d ? _dBorder    : _lBorder;
    return Container(
        decoration: BoxDecoration(
            color: isLast
                ? accent.withOpacity(0.10)
                : (d ? _dSurface2 : _lSurface2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isLast ? accent.withOpacity(0.35) : border,
                width: isLast ? 1.5 : 1.0)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.only(
              left: _sp12, top: _sp8, bottom: _sp8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$index',
                    style: _txtLabel(10, d ? _dTextMuted : _lTextMuted,
                        w: FontWeight.w600)),
                const SizedBox(width: _sp4),
                Text(token.label,
                    style: _txtLabel(12,
                        isLast ? accent : (d ? _dText : _lText),
                        w: FontWeight.w700)),
              ])),
          Semantics(
            label: AppLocalizations.of(context)
                .t('translate_remove_token')
                .replaceAll('{token}', token.label),
            button: true,
            child: GestureDetector(onTap: onRemove,
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _sp8, vertical: _sp8),
                    child: Icon(Icons.close_rounded, size: 12,
                        color: isLast
                            ? accent
                            : (d ? _dTextMuted : _lTextMuted)))),
          ),
        ]));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SHARED WEB WIDGETS
// ══════════════════════════════════════════════════════════════════════
class _UX4GCard extends StatelessWidget {
  final Widget child;
  final bool d;
  const _UX4GCard({required this.child, required this.d});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(_sp20),
      decoration: BoxDecoration(
          color: d
              ? _dSurface.withOpacity(0.90)
              : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: d ? _dBorder : const Color(0xFFDDE3EE), width: 1),
          boxShadow: d ? [] : [
            BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.04),
              blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 6),
            ),
          ]),
      child: child);
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool d;
  const _IconBadge({required this.icon, required this.color, required this.d});
  @override
  Widget build(BuildContext context) => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.22), width: 1)),
      child: Icon(icon, color: color, size: 16));
}

class _SessionStatusChip extends StatelessWidget {
  final _SessionState state;
  final bool d;
  const _SessionStatusChip({required this.state, required this.d});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color c; String t;
    switch (state) {
      case _SessionState.running:    c = d ? _successDark : _success; t = l.t('common_live'); break;
      case _SessionState.connecting: c = d ? _warningDark : _warning; t = l.t('common_connecting'); break;
      case _SessionState.error:      c = d ? _dangerDark  : _danger;  t = l.t('common_error'); break;
      default: c = d ? _dTextMuted : _lTextMuted; t = l.t('common_idle');
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withOpacity(0.25), width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: _sp4),
          Text(t, style: _txtLabel(11, c, w: FontWeight.w700)),
        ]));
  }
}

class _LangDropdownWeb extends StatelessWidget {
  final String value;
  final List<String> options;
  final bool d;
  final ValueChanged<String?> onChanged;
  const _LangDropdownWeb({required this.value, required this.options,
    required this.d, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
      decoration: BoxDecoration(
          color: d ? _dSurface2 : _lSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, dropdownColor: d ? _dSurface2 : _lSurface,
          style: _body(12, d ? _dText : _lText, w: FontWeight.w600),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: d ? _dTextSub : _lTextSub, size: 14),
          items: options.map((l) => DropdownMenuItem(
              value: l, child: Text(l))).toList(),
          onChanged: onChanged)));
}

class _WebDetectionRow extends StatelessWidget {
  final String code, text;
  final Color color;
  final bool d, isActive, speaking;
  final VoidCallback? onSpeak;
  const _WebDetectionRow({required this.code, required this.text,
    required this.color, required this.d, required this.isActive,
    required this.speaking, this.onSpeak});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
            horizontal: _sp12, vertical: _sp12),
        decoration: BoxDecoration(
            color: d ? _dSurface2 : _lSurface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive ? color.withOpacity(0.30)
                    : (d ? _dBorder : _lBorder), width: 1)),
        child: Row(children: [
          _LangBadge(code: code, color: color),
          const SizedBox(width: _sp12),
          Expanded(child: Text(text, style: _heading(19, color))),
        ]))),
    const SizedBox(width: _sp8),
    Semantics(
      label: speaking
          ? AppLocalizations.of(context).t('common_stop')
          : AppLocalizations.of(context).t('common_speak'),
      button: true,
      child: GestureDetector(
        onTap: onSpeak,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: speaking
                    ? color.withOpacity(0.18) : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: speaking
                        ? color.withOpacity(0.50) : color.withOpacity(0.20),
                    width: speaking ? 1.5 : 1.0)),
            child: Icon(
                speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: onSpeak == null
                    ? color.withOpacity(0.30) : color, size: 18)),
      ),
    ),
  ]);
}

class _WebSessionButton extends StatelessWidget {
  final _SessionState state;
  final bool d;
  final VoidCallback onStart, onStop;
  const _WebSessionButton({required this.state, required this.d,
    required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final running = state == _SessionState.running;
    final loading = state == _SessionState.connecting
        || state == _SessionState.stopping;
    final err     = state == _SessionState.error;

    final Color bgColor;
    final Color fgColor;
    final String lbl;
    final IconData ico;

    if (running) {
      bgColor = (d ? _dangerDark : _danger).withOpacity(0.10);
      fgColor = d ? _dangerDark : _danger;
      lbl = l.t('translate_stop_session');
      ico = Icons.stop_rounded;
    } else if (err) {
      bgColor = (d ? _warningDark : _warning).withOpacity(0.10);
      fgColor = d ? _warningDark : _warning;
      lbl = l.t('common_retry');
      ico = Icons.refresh_rounded;
    } else if (loading) {
      bgColor = d ? _dSurface2 : _lSurface2;
      fgColor = d ? _dTextSub : _lTextSub;
      lbl = state == _SessionState.connecting
          ? l.t('common_connecting') : l.t('common_stopping');
      ico = Icons.hourglass_empty_rounded;
    } else {
      bgColor = (d ? _primaryDark : _primary).withOpacity(0.10);
      fgColor = d ? _primaryDark : _primary;
      lbl = l.t('translate_start_session');
      ico = Icons.play_arrow_rounded;
    }

    return GestureDetector(
      onTap: loading ? null : (running ? onStop : onStart),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: _sp12),
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: fgColor.withOpacity(0.28), width: 1)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading)
              SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fgColor))
            else Icon(ico, color: fgColor, size: 16),
            const SizedBox(width: _sp8),
            Text(lbl, style: _txtLabel(13, fgColor, w: FontWeight.w700)),
          ])),
    );
  }
}

class _EmptyBuilderWeb extends StatelessWidget {
  final bool d;
  const _EmptyBuilderWeb({required this.d});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: _sp20),
        decoration: BoxDecoration(
            color: d ? _dSurface2 : _lSurface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: d ? _dBorder : _lBorder, width: 1)),
        child: Column(children: [
          Icon(Icons.gesture_rounded,
              color: d ? _dTextMuted : _lTextMuted, size: 26),
          const SizedBox(height: _sp8),
          Text(l.t('translate_hold_sign_build'),
              style: _body(12.5, d ? _dTextSub : _lTextSub)),
          const SizedBox(height: _sp4),
          Text(l.t('translate_builder_info_short'),
              style: _body(11.5, d ? _dTextMuted : _lTextMuted)),
        ]));
  }
}

class _LangBadge extends StatelessWidget {
  final String code;
  final Color color;
  const _LangBadge({required this.code, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(code, style: _txtLabel(9, color, w: FontWeight.w800)));
}

class _ConfBar extends StatelessWidget {
  final double value;
  final bool d;
  const _ConfBar({required this.value, required this.d});
  @override
  Widget build(BuildContext context) {
    final c = value > 0.75
        ? (d ? _successDark : _success)
        : value > 0.45
        ? (d ? _warningDark : _warning)
        : (d ? _primaryDark : _primary);
    return ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
            value: value, minHeight: 4,
            backgroundColor: d ? _dBorder : _lBorder,
            valueColor: AlwaysStoppedAnimation(c)));
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIconBtn({required this.icon, required this.color,
    required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip,
      child: Semantics(button: true, label: tooltip,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6),
              child: Padding(padding: const EdgeInsets.all(_sp4),
                  child: Icon(icon, size: 16, color: color)))));
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 24.0; const m = 16.0;
    canvas.drawPath(Path()
      ..moveTo(m, m + l)..lineTo(m, m)..lineTo(m + l, m), p);
    canvas.drawPath(Path()
      ..moveTo(size.width - m - l, m)
      ..lineTo(size.width - m, m)
      ..lineTo(size.width - m, m + l), p);
    canvas.drawPath(Path()
      ..moveTo(m, size.height - m - l)
      ..lineTo(m, size.height - m)
      ..lineTo(m + l, size.height - m), p);
    canvas.drawPath(Path()
      ..moveTo(size.width - m - l, size.height - m)
      ..lineTo(size.width - m, size.height - m)
      ..lineTo(size.width - m, size.height - m - l), p);
  }
  @override bool shouldRepaint(_CornerPainter o) => o.color != color;
}