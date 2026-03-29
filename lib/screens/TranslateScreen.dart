// lib/screens/TranslateScreen.dart
// ─────────────────────────────────────────────
//  APPLE-INSPIRED TRANSLATE SCREEN
//  ALL functional logic preserved exactly:
//   • SentenceBuilder (25 model words, all patterns)
//   • AutoAddEngine (stability + cooldown)
//   • WebSocket connection + frame capture
//   • TTS, translation, transcript
//
//  Mobile  (<700px): Fullscreen camera + frosted bottom panel
//  Web/Tab (≥700px): Side-by-side card layout + GlobalNavbar
//
//  UI: Google Sans (Nunito), iOS system colors, white cards,
//      hairline borders, 44px touch targets, no ripple
// ─────────────────────────────────────────────
import 'dart:ui';
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

class GoogleFonts {
  static TextStyle nunito({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: 'Google Sans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}

// ─────────────────────────────────────────────
//  WEBSOCKET CONFIG  (unchanged)
// ─────────────────────────────────────────────
// const _kDefaultWsPort  = 8000;
// const _kWsPath         = '/ws';
// const _kFrameIntervalMs = 100;

// String _getWebSocketUrl() {
//   if (kIsWeb) {
//     final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
//     final host   = Uri.base.host.isNotEmpty ? Uri.base.host : '';
//     return '$scheme://$host:$_kDefaultWsPort$_kWsPath';
//   }
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     return 'ws://10.0.2.2:$_kDefaultWsPort$_kWsPath';
//   }
//   return 'ws://127.0.0.1:$_kDefaultWsPort$_kWsPath';
// }

// ─────────────────────────────────────────────
//  WEBSOCKET CONFIG (Railway Production)
// ─────────────────────────────────────────────

// Change this to your actual Railway domain without the 'https://'
const String _kRailwayHost = 'isl-production-57d4.up.railway.app';
const String _kWsPath = '/ws';
const int _kFrameIntervalMs = 100;

String _getWebSocketUrl() {
  // For Production on Railway, we always use 'wss' (Secure WebSocket)
  // regardless of the platform.
  return 'wss://$_kRailwayHost$_kWsPath';
}

// ─────────────────────────────────────────────
//  APPLE DESIGN TOKENS
// ─────────────────────────────────────────────
class _A {
  // Light
  static const lBg       = Color(0xFFF2F2F7);
  static const lSurface  = Color(0xFFFFFFFF);
  static const lSurface2 = Color(0xFFF2F2F7);
  static const lSep      = Color(0xFFC6C6C8);
  // Dark
  static const dBg       = Color(0xFF000000);
  static const dSurface  = Color(0xFF1C1C1E);
  static const dSurface2 = Color(0xFF2C2C2E);
  static const dSep      = Color(0xFF38383A);
  // System accents
  static const indigo    = Color(0xFF5856D6);
  static const green     = Color(0xFF34C759);
  static const orange    = Color(0xFFFF9500);
  static const red       = Color(0xFFFF3B30);
  static const purple    = Color(0xFFAF52DE);
  static const teal      = Color(0xFF5AC8FA);

  static Color bg(bool d)       => d ? dBg       : lBg;
  static Color surface(bool d)  => d ? dSurface  : lSurface;
  static Color surface2(bool d) => d ? dSurface2 : lSurface2;
  static Color sep(bool d)      => d ? dSep      : lSep;
  static Color label(bool d)    => d ? Colors.white : Colors.black;
  static Color label2(bool d)   => d
      ? const Color(0xFFEBEBF5).withOpacity(0.60)
      : const Color(0xFF3C3C43).withOpacity(0.60);
  static Color label3(bool d)   => d
      ? const Color(0xFFEBEBF5).withOpacity(0.30)
      : const Color(0xFF3C3C43).withOpacity(0.30);
}

// ─────────────────────────────────────────────
//  25 MODEL WORDS — exact labels (DO NOT CHANGE)
// ─────────────────────────────────────────────
const Set<String> _kModelWords = {
  'hello', 'how are you', 'i', 'please', 'today', 'time',
  'what', 'name', 'quiet', 'yes', 'thankyou', 'namaste',
  'bandaid', 'help', 'strong', 'mother', 'food', 'father',
  'brother', 'love', 'good', 'bad', 'sorry', 'sleeping', 'water',
};

// ─────────────────────────────────────────────
//  SENTENCE BUILDER  (all patterns preserved)
// ─────────────────────────────────────────────
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
    if (words.length == 1) {
      return _solo[words[0]] ?? _capitalise('${words[0]}.');
    }
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
      parts.add(_solo[words[i]] ?? _capitalise('${words[i]}.'));
      i++;
    }
    return parts.map((p) => p.trimRight()).join(' ');
  }

  static String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────
//  AUTO-ADD ENGINE  (unchanged logic)
// ─────────────────────────────────────────────
class _AutoAddEngine {
  static const int _stabilityMs      = 800;
  static const int _sameWordCooldown  = 3000;
  static const int _anyWordCooldown   = 600;

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
        _lastAdded  = lbl; _lastAddedAt  = now; _lastAnyAdded = now;
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

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
enum _SessionState { idle, connecting, running, stopping, error }

class _GestureToken {
  final String label;
  final double confidence;
  _GestureToken({required this.label, required this.confidence});
}

// ─────────────────────────────────────────────
//  ONBOARDING FLOW  (Apple sheet design)
// ─────────────────────────────────────────────
class _OnboardingFlow extends StatefulWidget {
  final bool d;
  final VoidCallback onComplete;
  const _OnboardingFlow({required this.d, required this.onComplete});
  @override State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> with TickerProviderStateMixin {
  int    _phase = 0;
  int    _step  = 0;
  Timer? _timer;

  late AnimationController _loaderCtrl, _fadeCtrl, _sheetCtrl;
  late Animation<double>   _loaderAnim, _fadeAnim, _sheetScale, _sheetFade;

  static const _steps = [
    (icon: Icons.camera_alt_outlined,    color: _A.indigo, titleKey: 'translate_onboard_title_1', bodyKey: 'translate_onboard_body_1'),
    (icon: Icons.back_hand_outlined,     color: _A.green,  titleKey: 'translate_onboard_title_2', bodyKey: 'translate_onboard_body_2'),
    (icon: Icons.wb_sunny_outlined,      color: _A.orange, titleKey: 'translate_onboard_title_3', bodyKey: 'translate_onboard_body_3'),
    (icon: Icons.auto_awesome_outlined,  color: _A.purple, titleKey: 'translate_onboard_title_4', bodyKey: 'translate_onboard_body_4'),
    (icon: Icons.translate_outlined,     color: _A.teal,   titleKey: 'translate_onboard_title_5', bodyKey: 'translate_onboard_body_5'),
  ];

  @override
  void initState() {
    super.initState();
    _loaderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _loaderAnim = CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeInOut);
    _fadeCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
    _fadeAnim   = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _sheetCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _sheetScale = Tween<double>(begin: 0.92, end: 1.0)
      .animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutBack));
    _sheetFade  = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOut);

    _loaderCtrl.forward();
    _fadeCtrl.forward();

    _timer = Timer(const Duration(milliseconds: 3100), () {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _phase = 1);
        _fadeCtrl.forward();
        _sheetCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loaderCtrl.dispose(); _fadeCtrl.dispose(); _sheetCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) setState(() => _step++);
    else widget.onComplete();
  }
  void _prev() { if (_step > 0) setState(() => _step--); }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Material(
      color: _A.bg(d),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: _phase == 0 ? _buildLoader(d) : _buildSteps(d)));
  }

  Widget _buildLoader(bool d) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 88, height: 88,
          child: AnimatedBuilder(
            animation: _loaderAnim,
            builder: (_, __) => CustomPaint(
              painter: _RingPainter(
                progress: _loaderAnim.value,
                color:    _A.indigo,
                track:    _A.sep(d))))),
        const SizedBox(height: 28),
        Text(l.t('app_title_short'), style: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: _A.label(d), letterSpacing: 8)),
        const SizedBox(height: 6),
        Text(l.t('translate_screen_title'), style: GoogleFonts.nunito(
          fontSize: 13, color: _A.label2(d), letterSpacing: 0.5)),
        const SizedBox(height: 44),
        SizedBox(width: 200, child: AnimatedBuilder(
          animation: _loaderAnim,
          builder: (_, __) => Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:    _loaderAnim.value, minHeight: 3,
                backgroundColor: _A.sep(d),
                valueColor: const AlwaysStoppedAnimation(_A.indigo))),
            const SizedBox(height: 10),
            Text(_loaderLabel(_loaderAnim.value, l), style: GoogleFonts.nunito(
              fontSize: 12, color: _A.label2(d))),
          ]))),
      ]));
  }

  String _loaderLabel(double v, AppLocalizations l) {
    if (v < 0.35) return l.t('translate_loader_camera');
    if (v < 0.70) return l.t('translate_loader_ai');
    return l.t('translate_loader_calibrate');
  }

  Widget _buildSteps(bool d) {
    final l    = AppLocalizations.of(context);
    final step = _steps[_step];
    final last = _step == _steps.length - 1;

    return Stack(children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ScaleTransition(
            scale: _sheetScale,
            child: FadeTransition(
              opacity: _sheetFade,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: _A.surface(d),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(d ? 0.40 : 0.12),
                    blurRadius: 40, offset: const Offset(0, 12))]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Color bar
                  Container(height: 4,
                    decoration: BoxDecoration(
                      color: step.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _A.indigo.withOpacity(d ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(l.t('translate_how_to_use'), style: GoogleFonts.nunito(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: _A.indigo, letterSpacing: 1.5))),
                        const Spacer(),
                        Text('${_step + 1} / ${_steps.length}', style: GoogleFonts.nunito(
                          fontSize: 12, color: _A.label2(d))),
                      ]),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(_step),
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(d ? 0.15 : 0.08),
                            shape: BoxShape.circle),
                          child: Icon(step.icon, color: step.color, size: 30))),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(l.t(step.titleKey), key: ValueKey('t$_step'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800,
                            color: _A.label(d), letterSpacing: -0.3))),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(l.t(step.bodyKey), key: ValueKey('b$_step'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: 14, color: _A.label2(d), height: 1.6))),
                      const SizedBox(height: 22),
                      // Step dots
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_steps.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _step ? 20 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: i == _step ? _A.indigo : _A.sep(d),
                            borderRadius: BorderRadius.circular(3))))),
                      const SizedBox(height: 22),
                      Row(children: [
                        if (_step > 0) ...[
                          Expanded(child: _OButton(label: l.t('translate_back'),
                            icon: Icons.chevron_left_rounded, d: d, onTap: _prev)),
                          const SizedBox(width: 10),
                        ],
                        Expanded(flex: 2,
                          child: _PButton(
                            label: last ? l.t('translate_lets_begin') : l.t('translate_next'),
                            icon: last ? Icons.play_arrow_rounded : Icons.chevron_right_rounded,
                            onTap: _next)),
                      ]),
                      if (!last) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: widget.onComplete,
                          child: Text(l.t('translate_skip_tutorial'),
                            style: GoogleFonts.nunito(fontSize: 13, color: _A.label2(d),
                              decoration: TextDecoration.underline,
                              decorationColor: _A.label2(d)))),
                      ],
                    ]),
                  ),
                ]),
              ))))),
    ]);
  }
}

class _PButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _PButton({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _A.indigo, borderRadius: BorderRadius.circular(13),
        boxShadow: [BoxShadow(color: _A.indigo.withOpacity(0.28),
          blurRadius: 14, offset: const Offset(0, 5))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700,
          color: Colors.white)),
        const SizedBox(width: 4),
        Icon(icon, size: 16, color: Colors.white),
      ])));
}

class _OButton extends StatelessWidget {
  final String label; final IconData icon; final bool d; final VoidCallback onTap;
  const _OButton({required this.label, required this.icon, required this.d, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _A.sep(d))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: _A.label2(d)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600,
          color: _A.label2(d))),
      ])));
}

class _RingPainter extends CustomPainter {
  final double progress; final Color color; final Color track;
  const _RingPainter({required this.progress, required this.color, required this.track});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0, math.pi * 2, false,
      Paint()..color = track..strokeWidth = 2..style = PaintingStyle.stroke);
    if (progress > 0)
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = color..strokeWidth = 2.5
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ═════════════════════════════════════════════
//  TRANSLATE SCREEN
// ═════════════════════════════════════════════
class TranslateScreen extends StatefulWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  const TranslateScreen({super.key, required this.toggleTheme, required this.setLocale});
  @override State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  bool _onboardingDone = false;

  // Camera
  CameraController?      _cam;
  List<CameraDescription>? _cameras;
  int  _camIndex    = 0;

  // WebSocket
  WebSocketChannel? _channel;
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
  bool   _ttsSpeaking  = false;
  String _ttsTag       = '';

  // Pulse anim
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
      .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
      if (res.statusCode == 200) return jsonDecode(res.body)[0][0][0] as String;
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
        enableAudio: false, imageFormatGroup: kIsWeb ? null : ImageFormatGroup.jpeg);
      await _cam!.initialize();
      if (!mounted) return false;
      setState(() {});
      return true;
    } catch (_) { return false; }
  }

  Future<void> _disposeCamera() async {
    final c = _cam; _cam = null;
    try {
      if (!kIsWeb && c != null && c.value.isInitialized && c.value.isStreamingImages)
        await c.stopImageStream();
      await c?.dispose();
    } catch (_) {}
  }

  Future<bool> _connectWs() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));
      await _channel!.ready.timeout(const Duration(seconds: 3));
      _wsOk = true; _reconnects = 0;
      _wsSub = _channel!.stream.listen(_onMsg, onError: _onErr, onDone: _onDone, cancelOnError: false);
      return true;
    } catch (_) { _wsOk = false; return false; }
  }

  void _onMsg(dynamic raw) {
    if (!mounted) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'prediction';
      if (type == 'ping') { _channel?.sink.add('__PING__'); return; }
      if (type == 'error') {
        setState(() { _state = _SessionState.error; _error = data['message'] as String? ?? 'Error'; });
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

  void _onErr(Object _) { _wsOk = false; if (_state == _SessionState.running) _tryReconnect(); }
  void _onDone()        { _wsOk = false; if (_state == _SessionState.running) _tryReconnect(); }

  void _tryReconnect() {
    if (_reconnects >= _kMaxReconnects) {
      if (mounted) setState(() { _state = _SessionState.error; _error = 'Connection lost. Please restart.'; });
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
    try { _channel?.sink.add('__STOP__'); await Future.delayed(const Duration(milliseconds: 150)); await _channel?.sink.close(); } catch (_) {}
    _channel = null; _wsOk = false;
  }

  void _startFrameTimer() {
    _frameTimer?.cancel(); _capturing = false;
    _frameTimer = Timer.periodic(Duration(milliseconds: _kFrameIntervalMs), (_) => _captureFrame());
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

  void _stopFrameTimer() { _frameTimer?.cancel(); _frameTimer = null; _capturing = false; }

  void _startStabilityTimer() {
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() { _stability = _engine.stabilityProgress(_label.toLowerCase().trim()); });
    });
  }

  void _stopStabilityTimer() { _stabilityTimer?.cancel(); _stabilityTimer = null; _stability = 0; }

  Future<void> _startSession() async {
    if (_state != _SessionState.idle && _state != _SessionState.error) return;
    setState(() { _state = _SessionState.connecting; _error = null; _label = '—'; _conf = 0; _frames = 0; });
    if (!await _initCamera()) {
      setState(() { _state = _SessionState.error; _error = 'Camera unavailable'; });
      return;
    }
    if (!await _connectWs()) {
      await _disposeCamera();
      setState(() { _state = _SessionState.error; _error = 'Cannot connect to inference server.\nEnsure backend is running.'; });
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
    setState(() { _tokens.add(_GestureToken(label: n, confidence: conf)); _rebuildSentence(); });
    if (fromAuto) HapticFeedback.lightImpact();
  }

  void _addCurrentManually() {
    if (_label == '—' || _label.isEmpty) return;
    _addToken(_label, _conf);
    _engine.reset();
  }

  void _removeToken(int i) { setState(() { _tokens.removeAt(i); _rebuildSentence(); }); }
  void _removeLast()       { if (_tokens.isEmpty) return; setState(() { _tokens.removeLast(); _rebuildSentence(); }); }

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
    await _tts.setLanguage(langCode);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    setState(() { _ttsSpeaking = true; _ttsTag = tag; });
    await _tts.speak(text);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() { _ttsSpeaking = false; _ttsTag = ''; });
    });
  }

  String _ttsCode(String lang) {
    const m = {'Hindi':'hi-IN','Marathi':'mr-IN','Gujarati':'gu-IN',
      'Tamil':'ta-IN','Telugu':'te-IN','Kannada':'kn-IN','Bengali':'bn-IN'};
    return m[lang] ?? 'hi-IN';
  }

  void _copy(String text) {
    if (text.isEmpty) return;
    final l = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: _A.green, size: 15),
        const SizedBox(width: 8),
        Text(l.t('common_copied_clipboard'), style: GoogleFonts.nunito(
          fontSize: 13, color: Colors.white)),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose(); _stabilityTimer?.cancel();
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
        onComplete: () { if (mounted) setState(() => _onboardingDone = true); });
    }

    if (mob) return _buildMobile(context, d);
    return _buildWeb(context, d, w > 900);
  }

  // ══════════════════════════════════════════════
  //  MOBILE — fullscreen camera + frosted bottom panel
  // ══════════════════════════════════════════════
  Widget _buildMobile(BuildContext context, bool d) {
    final l       = AppLocalizations.of(context);
    final running = _state == _SessionState.running;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(fit: StackFit.expand, children: [

        // Camera
        if (running && _cam != null && _cam!.value.isInitialized)
          CameraPreview(_cam!)
        else
          _MobileCamPlaceholder(d: d, state: _state),

        // Corner brackets overlay
        IgnorePointer(child: CustomPaint(
          painter: _CornerPainter(
            color: _A.indigo.withOpacity(running ? 0.65 : 0.28)))),

        // Scanlines (subtle)
        if (running)
          IgnorePointer(child: CustomPaint(painter: _ScanlinePainter())),

        // Top bar
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                _CamIconBtn(icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.pop(context)),
                const Spacer(),
                _MobileStatusPill(state: _state),
                const SizedBox(width: 10),
                _CamIconBtn(icon: Icons.flip_camera_ios_rounded,
                  onTap: _switchCamera),
              ])))),

        // Live badge
        if (running)
          Positioned(top: 72, left: 16,
            child: _LiveBadge(pulse: _pulseAnim)),

        // Label overlay
        if (running && _conf > 0.15)
          Positioned(top: 72, left: 0, right: 0,
            child: Center(child: _LabelOverlay(
              label: _label, confidence: _conf,
              stability: _stability))),

        // Overlays
        if (_state == _SessionState.connecting)
          _ConnectingOverlay(d: d),
        if (_state == _SessionState.error)
          _ErrorOverlay(d: d),
        if (_state == _SessionState.error && _error != null)
          Positioned(bottom: 260, left: 20, right: 20,
            child: _ErrorBanner(msg: _error!, d: d)),

        // Bottom panel
        Positioned(bottom: 0, left: 0, right: 0,
          child: _MobileBottomPanel(
            d: d, state: _state, label: _label, conf: _conf,
            regional: _regional, selectedLang: _lang, langCodes: _langCodes,
            tokens: _tokens, sentence: _sentence, sentenceRegional: _sentenceRegional,
            stability: _stability, ttsSpeaking: _ttsSpeaking, ttsTag: _ttsTag,
            transcriptCtrl: _transcriptCtrl,
            onStart: _startSession, onStop: _stopSession,
            onAddManual: _addCurrentManually, onRemoveLast: _removeLast,
            onClearAll: _clearBuilder, onCommit: _commitToTranscript,
            onRemoveToken: _removeToken,
            onLangChanged: (v) { if (v != null && mounted) setState(() => _lang = v); },
            onCopy: _copy, onSpeak: _speak, ttsCode: _ttsCode, l: l)),
      ]));
  }

  // ══════════════════════════════════════════════
  //  WEB — card layout with GlobalNavbar
  // ══════════════════════════════════════════════
  Widget _buildWeb(BuildContext context, bool d, bool wide) {
    return Scaffold(
      backgroundColor: _A.bg(d),
      body: SafeArea(
        child: Column(children: [
          GlobalNavbar(toggleTheme: widget.toggleTheme,
            setLocale: widget.setLocale, activeRoute: 'translate'),
          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: wide ? _webWide(d) : _webNarrow(d))),
        ])));
  }

  Widget _webWide(bool d) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 6, child: _webCamera(d)),
    const SizedBox(width: 18),
    Expanded(flex: 5, child: Column(children: [
      _webDetection(d), const SizedBox(height: 14),
      _webBuilder(d),   const SizedBox(height: 14),
      _webTranscript(d),
    ])),
  ]);

  Widget _webNarrow(bool d) => Column(children: [
    _webCamera(d), const SizedBox(height: 14),
    _webDetection(d), const SizedBox(height: 14),
    _webBuilder(d),   const SizedBox(height: 14),
    _webTranscript(d),
  ]);

  // ── Web: Camera card ──
  Widget _webCamera(bool d) {
    final l       = AppLocalizations.of(context);
    final running = _state == _SessionState.running;
    return _WebCard(d: d, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _WebIconBadge(icon: Icons.sensors_rounded, color: _A.indigo, d: d),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('translate_vision_title'), style: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w700, color: _A.label(d))),
          Text(l.t('translate_vision_sub'), style: GoogleFonts.nunito(
            fontSize: 12, color: _A.label2(d))),
        ])),
        _WebStatusChip(state: _state, d: d),
      ]),
      const SizedBox(height: 16),
      AspectRatio(aspectRatio: 16 / 10,
        child: ClipRRect(borderRadius: BorderRadius.circular(14),
          child: Container(
            color: const Color(0xFF0A0A0A),
            child: Stack(fit: StackFit.expand, children: [
              if (running && _cam != null && _cam!.value.isInitialized)
                CameraPreview(_cam!)
              else
                _WebCamPlaceholder(d: d),
              if (running) IgnorePointer(child: CustomPaint(painter: _ScanlinePainter())),
              if (running) Positioned(top: 10, left: 10,
                child: _LiveBadge(pulse: _pulseAnim)),
              if (running && _conf > 0.15)
                Positioned(bottom: 10, left: 10, right: 10,
                  child: _LabelOverlay(label: _label, confidence: _conf, stability: _stability)),
              if (_state == _SessionState.connecting) _ConnectingOverlay(d: d),
              if (_state == _SessionState.error) _ErrorOverlay(d: d),
            ])))),
      const SizedBox(height: 14),
      Row(children: [
        _WebOutlineBtn(icon: Icons.flip_camera_android_rounded,
          label: l.t('translate_switch'), d: d, onTap: _switchCamera),
        const SizedBox(width: 10),
        Expanded(child: _WebSessionBtn(state: _state, d: d,
          onStart: _startSession, onStop: _stopSession)),
      ]),
      if (_state == _SessionState.error && _error != null) ...[
        const SizedBox(height: 10), _ErrorBanner(msg: _error!, d: d)],
    ]));
  }

  // ── Web: Detection card ──
  Widget _webDetection(bool d) {
    final l      = AppLocalizations.of(context);
    final active = _state == _SessionState.running;
    return _WebCard(d: d, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _WebIconBadge(icon: Icons.translate_rounded, color: _A.green, d: d),
        const SizedBox(width: 10),
        Expanded(child: Text(l.t('translate_prediction'), style: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w700, color: _A.label(d)))),
        _LangDropdown(value: _lang, options: _langCodes.keys.toList(), d: d,
          onChanged: (v) { if (v != null) setState(() => _lang = v); }),
      ]),
      const SizedBox(height: 14),
      // EN detection
      Row(children: [
        Expanded(child: _DetectionCard(code: 'EN', color: _A.indigo, d: d,
          text: active ? _label : l.t('translate_waiting'), isActive: active)),
        const SizedBox(width: 8),
        _TtsButton(color: _A.indigo, speaking: _ttsSpeaking && _ttsTag == 'en',
          onTap: active ? () => _speak(_label, 'en-US', 'en') : null),
      ]),
      const SizedBox(height: 8),
      // Regional detection
      Row(children: [
        Expanded(child: _DetectionCard(
          code: _lang.substring(0, 2).toUpperCase(), color: _A.green, d: d,
          text: active ? (_regional.isNotEmpty ? _regional : '…') : l.t('translate_waiting'),
          isActive: active)),
        const SizedBox(width: 8),
        _TtsButton(color: _A.green, speaking: _ttsSpeaking && _ttsTag == 'regional',
          onTap: active && _regional.isNotEmpty
            ? () => _speak(_regional, _ttsCode(_lang), 'regional') : null),
      ]),
      const SizedBox(height: 14),
      // Confidence
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l.t('obj_page_confidence'), style: GoogleFonts.nunito(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: _A.label3(d), letterSpacing: 1.2)),
        Text(active ? '${(_conf * 100).toStringAsFixed(0)}%' : '—',
          style: GoogleFonts.nunito(fontSize: 12, color: _A.label2(d), fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      _ConfidenceBar(value: active ? _conf : 0),
      if (active && _stability > 0) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${l.t('translate_frames')}: $_frames', style: GoogleFonts.nunito(
            fontSize: 11, color: _A.label3(d))),
          Row(children: [
            SizedBox(width: 64, height: 3,
              child: ClipRRect(borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: _stability,
                  backgroundColor: _A.sep(d),
                  valueColor: AlwaysStoppedAnimation(
                    _stability >= 1.0 ? _A.green : _A.orange)))),
            const SizedBox(width: 6),
            Text(_stability >= 1.0 ? l.t('translate_adding') : l.t('translate_hold_sign'),
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600,
                color: _stability >= 1.0 ? _A.green : _A.orange)),
          ]),
        ]),
      ],
    ]));
  }

  // ── Web: Sentence builder card ──
  Widget _webBuilder(bool d) {
    final l = AppLocalizations.of(context);
    return _WebCard(d: d, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _WebIconBadge(icon: Icons.auto_awesome_outlined, color: _A.purple, d: d),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('translate_sentence_builder'), style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w700, color: _A.label(d))),
          Text(l.t('translate_auto_chain_subtitle'), style: GoogleFonts.nunito(
            fontSize: 11.5, color: _A.label2(d))),
        ])),
        GestureDetector(onTap: _addCurrentManually,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _A.indigo.withOpacity(d ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, color: _A.indigo, size: 14),
              const SizedBox(width: 4),
              Text(l.t('translate_add_sign'), style: GoogleFonts.nunito(
                color: _A.indigo, fontSize: 12, fontWeight: FontWeight.w700)),
            ]))),
      ]),
      const SizedBox(height: 14),
      // Info
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _A.surface2(d), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _A.sep(d), width: 0.5)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 13, color: _A.label3(d)),
          const SizedBox(width: 8),
          Expanded(child: Text(l.t('translate_builder_info'),
            style: GoogleFonts.nunito(fontSize: 12, color: _A.label2(d), height: 1.4))),
        ])),
      const SizedBox(height: 14),
      // Tokens
      if (_tokens.isEmpty)
        _WebEmptyBuilder(d: d)
      else
        Wrap(spacing: 7, runSpacing: 7,
          children: _tokens.asMap().entries.map((e) => _TokenChip(
            index: e.key + 1, token: e.value,
            isLast: e.key == _tokens.length - 1,
            d: d, onRemove: () => _removeToken(e.key))).toList()),
      // Generated sentence
      if (_tokens.isNotEmpty) ...[
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.arrow_downward_rounded, size: 12, color: _A.label3(d)),
          const SizedBox(width: 5),
          Text(l.t('translate_generated_sentence'), style: GoogleFonts.nunito(
            fontSize: 11, fontWeight: FontWeight.w600, color: _A.label3(d), letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _A.purple.withOpacity(0.30))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _LangTag(code: 'EN', color: _A.purple),
              const SizedBox(width: 8),
              Expanded(child: Text(_sentence.isNotEmpty ? _sentence : '…',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700,
                  color: _A.label(d), height: 1.35))),
              _IconBtn(icon: Icons.copy_outlined, color: _A.label3(d),
                onTap: () => _copy(_sentence)),
              const SizedBox(width: 2),
              _IconBtn(
                icon: _ttsSpeaking && _ttsTag == 'sentence_en'
                  ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: _A.purple.withOpacity(0.7),
                onTap: () => _speak(_sentence, 'en-US', 'sentence_en')),
            ]),
            if (_sentenceRegional.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(height: 0.5, color: _A.sep(d)),
              const SizedBox(height: 8),
              Row(children: [
                _LangTag(code: _lang.substring(0,2).toUpperCase(), color: _A.green),
                const SizedBox(width: 8),
                Expanded(child: Text(_sentenceRegional,
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700,
                    color: _A.green, height: 1.35))),
                _IconBtn(icon: Icons.copy_outlined, color: _A.label3(d),
                  onTap: () => _copy(_sentenceRegional)),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: _ttsSpeaking && _ttsTag == 'sentence_reg'
                    ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: _A.green.withOpacity(0.7),
                  onTap: () => _speak(_sentenceRegional, _ttsCode(_lang), 'sentence_reg')),
              ]),
            ],
          ])),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: _commitToTranscript,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _A.indigo.withOpacity(d ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _A.indigo.withOpacity(0.25))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.save_alt_rounded, color: _A.indigo, size: 14),
                const SizedBox(width: 6),
                Text(l.t('translate_save_transcript'), style: GoogleFonts.nunito(
                  color: _A.indigo, fontSize: 13, fontWeight: FontWeight.w700)),
              ])))),
          const SizedBox(width: 8),
          _SmallIconBtn(icon: Icons.backspace_outlined, color: _A.orange,
            tooltip: l.t('translate_remove_last'), onTap: _removeLast),
          const SizedBox(width: 6),
          _SmallIconBtn(icon: Icons.delete_sweep_outlined, color: _A.red,
            tooltip: l.t('translate_clear_all'), onTap: _clearBuilder),
        ]),
      ],
    ]));
  }

  // ── Web: Transcript card ──
  Widget _webTranscript(bool d) {
    final l = AppLocalizations.of(context);
    return _WebCard(d: d, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _WebIconBadge(icon: Icons.article_outlined, color: _A.orange, d: d),
        const SizedBox(width: 10),
        Expanded(child: Text(l.t('translate_transcription'), style: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w700, color: _A.label(d)))),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _A.sep(d), width: 0.5)),
        child: TextField(
          controller: _transcriptCtrl, maxLines: 5,
          style: GoogleFonts.nunito(fontSize: 14, color: _A.label(d), height: 1.6),
          decoration: InputDecoration(
            hintText: l.t('translate_hint'),
            hintStyle: GoogleFonts.nunito(color: _A.label3(d), fontSize: 13),
            contentPadding: const EdgeInsets.all(14), border: InputBorder.none))),
      const SizedBox(height: 10),
      Row(children: [
        _SmallIconBtn(icon: Icons.copy_outlined, color: _A.indigo,
          tooltip: l.t('translate_copy_transcript'), onTap: () => _copy(_transcriptCtrl.text)),
        const SizedBox(width: 6),
        _SmallIconBtn(icon: Icons.delete_outline_rounded, color: _A.red,
          tooltip: l.t('common_clear'), onTap: _transcriptCtrl.clear),
      ]),
    ]));
  }
}

// ══════════════════════════════════════════════
//  MOBILE-ONLY WIDGETS
// ══════════════════════════════════════════════

class _MobileCamPlaceholder extends StatelessWidget {
  final bool d; final _SessionState state;
  const _MobileCamPlaceholder({required this.d, required this.state});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
    color: const Color(0xFF080810),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05)),
        child: const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 36)),
      const SizedBox(height: 16),
      Text(state == _SessionState.error ? l.t('translate_camera_error') : l.t('translate_tap_start'),
        style: GoogleFonts.nunito(color: Colors.white38, fontSize: 14)),
    ])));
  }
}

class _CamIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CamIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.48),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.14))),
      child: Icon(icon, color: Colors.white, size: 20)));
}

class _MobileStatusPill extends StatelessWidget {
  final _SessionState state;
  const _MobileStatusPill({required this.state});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color c; String t;
    switch (state) {
      case _SessionState.running:    c = _A.green;  t = l10n.t('common_live'); break;
      case _SessionState.connecting: c = _A.orange; t = l10n.t('common_connecting'); break;
      case _SessionState.error:      c = _A.red;    t = l10n.t('common_error'); break;
      default:                       c = Colors.white54; t = l10n.t('common_ready');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.40))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(width: 6),
        Text(t, style: GoogleFonts.nunito(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      ]));
  }
}

class _LabelOverlay extends StatelessWidget {
  final String label; final double confidence, stability;
  const _LabelOverlay({required this.label, required this.confidence, required this.stability});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (label == '—' || label.isEmpty) return const SizedBox.shrink();
    final confC = confidence > 0.75 ? _A.green : _A.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: confC.withOpacity(0.22),
              borderRadius: BorderRadius.circular(6)),
            child: Text('${(confidence * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.nunito(color: confC, fontSize: 11, fontWeight: FontWeight.w800))),
        ]),
        if (stability > 0) ...[
          const SizedBox(height: 6),
          SizedBox(width: 150, child: ClipRRect(borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: stability, minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(stability >= 1.0 ? _A.green : Colors.white54)))),
          const SizedBox(height: 3),
          Text(stability >= 1.0 ? l.t('translate_adding') : l.t('translate_hold_steady'),
            style: GoogleFonts.nunito(
              color: stability >= 1.0 ? _A.green : Colors.white54,
              fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ]));
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 2.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const l = 26.0; const m = 18.0;
    canvas.drawPath(Path()..moveTo(m, m+l)..lineTo(m, m)..lineTo(m+l, m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-l, m)..lineTo(size.width-m, m)..lineTo(size.width-m, m+l), p);
    canvas.drawPath(Path()..moveTo(m, size.height-m-l)..lineTo(m, size.height-m)..lineTo(m+l, size.height-m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-l, size.height-m)..lineTo(size.width-m, size.height-m)..lineTo(size.width-m, size.height-m-l), p);
  }
  @override bool shouldRepaint(_CornerPainter o) => o.color != color;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sl = Paint()..color = Colors.white.withOpacity(0.012)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), sl);
  }
  @override bool shouldRepaint(_) => false;
}

// ── Mobile bottom panel (frosted glass) ───────
class _MobileBottomPanel extends StatefulWidget {
  final bool d; final _SessionState state;
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

  const _MobileBottomPanel({
    required this.d, required this.state, required this.label, required this.conf,
    required this.regional, required this.selectedLang, required this.langCodes,
    required this.tokens, required this.sentence, required this.sentenceRegional,
    required this.stability, required this.ttsSpeaking, required this.ttsTag,
    required this.transcriptCtrl, required this.onStart, required this.onStop,
    required this.onAddManual, required this.onRemoveLast, required this.onClearAll,
    required this.onCommit, required this.onRemoveToken, required this.onLangChanged,
    required this.onCopy, required this.onSpeak, required this.ttsCode, required this.l});

  @override State<_MobileBottomPanel> createState() => _MobileBottomPanelState();
}

class _MobileBottomPanelState extends State<_MobileBottomPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final d = widget.d;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: d ? const Color(0xFF1C1C1E).withOpacity(0.90) : Colors.white.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: _A.sep(d), width: 0.5))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Padding(padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(width: 34, height: 4,
                decoration: BoxDecoration(
                  color: d ? Colors.white.withOpacity(0.20) : Colors.black.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(2)))),
            // Session + lang row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Row(children: [
                Expanded(child: _MobileSessionBtn(state: widget.state, d: d,
                  onStart: widget.onStart, onStop: widget.onStop)),
                const SizedBox(width: 10),
                _MobileLangPill(value: widget.selectedLang,
                  options: widget.langCodes.keys.toList(), d: d,
                  onChanged: widget.onLangChanged),
              ])),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                _PanelTab(label: l.t('common_output'), icon: Icons.translate_rounded,
                  active: _tab == 0, d: d, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _PanelTab(label: l.t('common_builder'), icon: Icons.auto_awesome_outlined,
                  active: _tab == 1, d: d, onTap: () => setState(() => _tab = 1),
                  badge: widget.tokens.length),
                const SizedBox(width: 8),
                _PanelTab(label: l.t('common_transcript'), icon: Icons.article_outlined,
                  active: _tab == 2, d: d, onTap: () => setState(() => _tab = 2)),
              ])),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(_tab),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: _tab == 0
                    ? _MobileOutputTab(widget: widget, d: d)
                    : _tab == 1
                    ? _MobileBuilderTab(widget: widget, d: d)
                    : _MobileTranscriptTab(widget: widget, d: d)))),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ]),
        ),
      ),
    );
  }
}

// Mobile session button
class _MobileSessionBtn extends StatefulWidget {
  final _SessionState state; final bool d;
  final VoidCallback onStart, onStop;
  const _MobileSessionBtn({required this.state, required this.d,
    required this.onStart, required this.onStop});
  @override State<_MobileSessionBtn> createState() => _MobileSessionBtnState();
}
class _MobileSessionBtnState extends State<_MobileSessionBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final running = widget.state == _SessionState.running;
    final loading = widget.state == _SessionState.connecting
                 || widget.state == _SessionState.stopping;
    final err     = widget.state == _SessionState.error;
    final c   = running ? _A.red : err ? _A.orange : _A.indigo;
    final lbl = loading
      ? (widget.state == _SessionState.connecting ? l.t('common_connecting') : l.t('common_stopping'))
      : running ? l.t('common_stop') : err ? l.t('common_retry') : l.t('common_start');
    final ico = loading ? Icons.hourglass_empty_rounded
      : running ? Icons.stop_rounded
      : err ? Icons.refresh_rounded : Icons.videocam_rounded;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) { setState(() => _p = false);
        if (!loading) (running ? widget.onStop : widget.onStart)(); },
      onTapCancel: ()  => setState(() => _p = false),
      child: AnimatedScale(scale: _p ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: (running || err) ? c.withOpacity(0.10) : c,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: (running || err) ? c.withOpacity(0.35) : Colors.transparent),
            boxShadow: (running || err || loading) ? [] : [BoxShadow(
              color: c.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading)
              SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(c)))
            else
              Icon(ico, color: (running || err) ? c : Colors.white, size: 16),
            const SizedBox(width: 7),
            Text(lbl, style: GoogleFonts.nunito(
              color: (running || err) ? c : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w700)),
          ]))));
  }
}

// Mobile lang pill
class _MobileLangPill extends StatelessWidget {
  final String value; final List<String> options;
  final bool d; final void Function(String?) onChanged;
  const _MobileLangPill({required this.value, required this.options,
    required this.d, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: _A.surface2(d), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _A.sep(d), width: 0.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value, isDense: true,
        dropdownColor: _A.surface(d),
        style: GoogleFonts.nunito(color: _A.label(d), fontWeight: FontWeight.w600, fontSize: 12),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _A.label2(d), size: 14),
        items: options.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: onChanged)));
}

// Panel tab chip
class _PanelTab extends StatelessWidget {
  final String label; final IconData icon;
  final bool active, d; final VoidCallback onTap; final int badge;
  const _PanelTab({required this.label, required this.icon,
    required this.active, required this.d, required this.onTap, this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _A.indigo.withOpacity(d ? 0.16 : 0.09) : _A.surface2(d),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active ? _A.indigo.withOpacity(0.35) : _A.sep(d), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: active ? _A.indigo : _A.label2(d)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.nunito(
          color: active ? _A.indigo : _A.label2(d), fontSize: 11.5,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        if (badge > 0) ...[
          const SizedBox(width: 5),
          Container(width: 16, height: 16,
            decoration: const BoxDecoration(color: _A.indigo, shape: BoxShape.circle),
            child: Center(child: Text('$badge', style: GoogleFonts.nunito(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
        ],
      ])));
}

// Output tab
class _MobileOutputTab extends StatelessWidget {
  final _MobileBottomPanel widget; final bool d;
  const _MobileOutputTab({required this.widget, required this.d});
  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final active = widget.state == _SessionState.running;
    final confC  = widget.conf > 0.75 ? _A.green : _A.orange;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      _MobileDetRow(code: 'EN', color: _A.indigo, d: d,
        text: active ? widget.label : '—',
        speaking: widget.ttsSpeaking && widget.ttsTag == 'en',
        onSpeak: active ? () => widget.onSpeak(widget.label, 'en-US', 'en') : null),
      const SizedBox(height: 8),
      _MobileDetRow(
        code: widget.selectedLang.substring(0, 2).toUpperCase(),
        color: _A.green, d: d,
        text: active ? (widget.regional.isNotEmpty ? widget.regional : '…') : '—',
        speaking: widget.ttsSpeaking && widget.ttsTag == 'regional',
        onSpeak: active && widget.regional.isNotEmpty
          ? () => widget.onSpeak(widget.regional, widget.ttsCode(widget.selectedLang), 'regional') : null),
      if (active) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.t('obj_page_confidence'), style: GoogleFonts.nunito(
            fontSize: 10.5, color: _A.label3(d), fontWeight: FontWeight.w600)),
          Text('${(widget.conf * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(fontSize: 12, color: _A.label2(d), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: widget.conf, minHeight: 3,
            backgroundColor: _A.sep(d),
            valueColor: AlwaysStoppedAnimation(confC))),
      ],
      const SizedBox(height: 6),
    ]);
  }
}

class _MobileDetRow extends StatelessWidget {
  final String code, text; final Color color;
  final bool d, speaking; final VoidCallback? onSpeak;
  const _MobileDetRow({required this.code, required this.text,
    required this.color, required this.d, required this.speaking, this.onSpeak});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _A.sep(d), width: 0.5)),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
        child: Text(code, style: GoogleFonts.nunito(
          fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.2))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.nunito(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: text == '—' ? _A.label3(d) : color, letterSpacing: -0.2))),
      if (onSpeak != null)
        GestureDetector(onTap: onSpeak,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(
              color: speaking ? color.withOpacity(0.16) : color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withOpacity(speaking ? 0.40 : 0.15))),
            child: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
              color: color, size: 15))),
    ]));
}

// Builder tab
class _MobileBuilderTab extends StatelessWidget {
  final _MobileBottomPanel widget; final bool d;
  const _MobileBuilderTab({required this.widget, required this.d});
  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (widget.tokens.isEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _A.sep(d), width: 0.5)),
          child: Column(children: [
            Icon(Icons.gesture_rounded, color: _A.label3(d), size: 26),
            const SizedBox(height: 5),
            Text(l.t('translate_hold_sign_add'),
              style: GoogleFonts.nunito(color: _A.label2(d), fontSize: 12)),
          ]))
      else
        Wrap(spacing: 7, runSpacing: 7,
          children: widget.tokens.asMap().entries.map((e) => _TokenChip(
            index: e.key + 1, token: e.value,
            isLast: e.key == widget.tokens.length - 1,
            d: d, onRemove: () => widget.onRemoveToken(e.key))).toList()),

      if (widget.tokens.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _A.purple.withOpacity(d ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _A.purple.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(widget.sentence.isNotEmpty ? widget.sentence : '…',
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700,
                  color: _A.label(d), height: 1.35))),
              _IconBtn(icon: Icons.copy_outlined, color: _A.label3(d),
                onTap: () => widget.onCopy(widget.sentence)),
              const SizedBox(width: 2),
              _IconBtn(
                icon: widget.ttsSpeaking && widget.ttsTag == 'sentence_en'
                  ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: _A.purple.withOpacity(0.70),
                onTap: () => widget.onSpeak(widget.sentence, 'en-US', 'sentence_en')),
            ]),
            if (widget.sentenceRegional.isNotEmpty) ...[
              Divider(height: 12, color: _A.sep(d)),
              Text(widget.sentenceRegional, style: GoogleFonts.nunito(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: _A.green, height: 1.35)),
            ],
          ])),
      ],
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: GestureDetector(onTap: widget.onAddManual,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: _A.indigo.withOpacity(d ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _A.indigo.withOpacity(0.22))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_rounded, color: _A.indigo, size: 14),
              const SizedBox(width: 5),
              Text(l.t('translate_add_sign'), style: GoogleFonts.nunito(
                color: _A.indigo, fontSize: 12, fontWeight: FontWeight.w700)),
            ])))),
        if (widget.tokens.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: widget.onCommit,
            child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _A.green.withOpacity(d ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _A.green.withOpacity(0.22))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.save_alt_rounded, color: _A.green, size: 14),
                const SizedBox(width: 5),
                Text(l.t('common_save'), style: GoogleFonts.nunito(
                  color: _A.green, fontSize: 12, fontWeight: FontWeight.w700)),
              ])))),
          const SizedBox(width: 6),
          _SmallIconBtn(icon: Icons.backspace_outlined, color: _A.orange,
            onTap: widget.onRemoveLast),
          const SizedBox(width: 6),
          _SmallIconBtn(icon: Icons.delete_sweep_outlined, color: _A.red,
            onTap: widget.onClearAll),
        ],
      ]),
      const SizedBox(height: 6),
    ]);
  }
}

// Transcript tab
class _MobileTranscriptTab extends StatelessWidget {
  final _MobileBottomPanel widget; final bool d;
  const _MobileTranscriptTab({required this.widget, required this.d});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      decoration: BoxDecoration(
        color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _A.sep(d), width: 0.5)),
      child: TextField(
        controller: widget.transcriptCtrl, maxLines: 4,
        style: GoogleFonts.nunito(fontSize: 13.5, color: _A.label(d), height: 1.55),
        decoration: InputDecoration(
          hintText: widget.l.t('translate_hint'),
          hintStyle: GoogleFonts.nunito(color: _A.label3(d), fontSize: 13),
          contentPadding: const EdgeInsets.all(12), border: InputBorder.none))),
    const SizedBox(height: 8),
    Row(children: [
      GestureDetector(onTap: () => widget.onCopy(widget.transcriptCtrl.text),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _A.indigo.withOpacity(d ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _A.indigo.withOpacity(0.20))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.copy_outlined, color: _A.indigo, size: 13),
            const SizedBox(width: 5),
            Text(widget.l.t('common_copy'), style: GoogleFonts.nunito(
              color: _A.indigo, fontSize: 12, fontWeight: FontWeight.w700)),
          ]))),
      const SizedBox(width: 8),
      GestureDetector(onTap: widget.transcriptCtrl.clear,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _A.red.withOpacity(d ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _A.red.withOpacity(0.20))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.delete_outline_rounded, color: _A.red, size: 13),
            const SizedBox(width: 5),
            Text(widget.l.t('common_clear'), style: GoogleFonts.nunito(
              color: _A.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ]))),
    ]),
    const SizedBox(height: 6),
  ]);
}

// ══════════════════════════════════════════════
//  SHARED / WEB COMPONENTS
// ══════════════════════════════════════════════

class _WebCard extends StatelessWidget {
  final Widget child; final bool d;
  const _WebCard({required this.child, required this.d});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _A.surface(d),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _A.sep(d), width: 0.5),
      boxShadow: [if (!d) BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 3))]),
    child: child);
}

class _WebIconBadge extends StatelessWidget {
  final IconData icon; final Color color; final bool d;
  const _WebIconBadge({required this.icon, required this.color, required this.d});
  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color: color.withOpacity(d ? 0.16 : 0.09),
      borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: color, size: 16));
}

class _WebStatusChip extends StatelessWidget {
  final _SessionState state; final bool d;
  const _WebStatusChip({required this.state, required this.d});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color c; String l;
    switch (state) {
      case _SessionState.running:    c = _A.green;  l = l10n.t('common_live'); break;
      case _SessionState.connecting: c = _A.orange; l = l10n.t('common_connecting'); break;
      case _SessionState.error:      c = _A.red;    l = l10n.t('common_error'); break;
      default:                       c = _A.label3(this.d); l = l10n.t('common_idle');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(width: 5),
        Text(l, style: GoogleFonts.nunito(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
      ]));
  }
}

class _LangDropdown extends StatelessWidget {
  final String value; final List<String> options;
  final bool d; final ValueChanged<String?> onChanged;
  const _LangDropdown({required this.value, required this.options,
    required this.d, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: _A.surface2(d), borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _A.sep(d), width: 0.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value, dropdownColor: _A.surface(d),
        style: GoogleFonts.nunito(color: _A.label(d), fontWeight: FontWeight.w600, fontSize: 12),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _A.label2(d), size: 15),
        items: options.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: onChanged)));
}

class _DetectionCard extends StatelessWidget {
  final String code, text; final Color color; final bool d, isActive;
  const _DetectionCard({required this.code, required this.text,
    required this.color, required this.d, required this.isActive});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isActive ? color.withOpacity(0.30) : _A.sep(d), width: 0.5)),
    child: Row(children: [
      _LangTag(code: code, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.nunito(
        fontSize: 19, fontWeight: FontWeight.w800,
        color: isActive ? color : _A.label3(d), letterSpacing: -0.3))),
    ]));
}

class _LangTag extends StatelessWidget {
  final String code; final Color color;
  const _LangTag({required this.code, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
    child: Text(code, style: GoogleFonts.nunito(
      fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.3)));
}

class _ConfidenceBar extends StatelessWidget {
  final double value;
  const _ConfidenceBar({required this.value});
  @override
  Widget build(BuildContext context) {
    final c = value > 0.75 ? _A.green : value > 0.45 ? _A.orange : _A.indigo;
    return ClipRRect(borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(value: value, minHeight: 4,
        backgroundColor: const Color(0x14FFFFFF),
        valueColor: AlwaysStoppedAnimation(c)));
  }
}

class _WebEmptyBuilder extends StatelessWidget {
  final bool d;
  const _WebEmptyBuilder({required this.d});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: _A.surface2(d), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _A.sep(d), width: 0.5)),
    child: Column(children: [
      Icon(Icons.gesture_rounded, color: _A.label3(d), size: 28),
      const SizedBox(height: 7),
      Text(l.t('translate_hold_sign_build'),
        style: GoogleFonts.nunito(color: _A.label2(d), fontSize: 12.5)),
      const SizedBox(height: 3),
      Text(l.t('translate_builder_info_short'),
        style: GoogleFonts.nunito(color: _A.label3(d), fontSize: 11.5)),
    ]));
  }
}

class _TokenChip extends StatelessWidget {
  final int index; final _GestureToken token;
  final bool isLast, d; final VoidCallback onRemove;
  const _TokenChip({required this.index, required this.token,
    required this.isLast, required this.d, required this.onRemove});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: isLast ? _A.purple.withOpacity(d ? 0.14 : 0.08) : _A.surface2(d),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isLast ? _A.purple.withOpacity(0.38) : _A.sep(d),
        width: isLast ? 1.0 : 0.5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.only(left: 10, top: 7, bottom: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$index', style: GoogleFonts.nunito(
            fontSize: 9.5, color: _A.label3(d), fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Text(token.label, style: GoogleFonts.nunito(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isLast ? _A.purple : _A.label(d))),
        ])),
      GestureDetector(onTap: onRemove,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Icon(Icons.close_rounded, size: 11,
            color: isLast ? _A.purple : _A.label3(d)))),
    ]));
}

class _TtsButton extends StatelessWidget {
  final Color color; final bool speaking; final VoidCallback? onTap;
  const _TtsButton({required this.color, required this.speaking, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: speaking ? color.withOpacity(0.18) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: speaking ? color.withOpacity(0.55) : color.withOpacity(0.18),
          width: speaking ? 1.0 : 0.5)),
      child: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
        color: onTap == null ? color.withOpacity(0.28) : color, size: 16)));
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(5),
      child: Icon(icon, size: 14, color: color)));
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap; final String? tooltip;
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap, this.tooltip});
  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.20))),
        child: Icon(icon, color: color, size: 15)));
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _WebSessionBtn extends StatelessWidget {
  final _SessionState state; final bool d;
  final VoidCallback onStart, onStop;
  const _WebSessionBtn({required this.state, required this.d,
    required this.onStart, required this.onStop});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = state == _SessionState.running;
    final loading = state == _SessionState.connecting || state == _SessionState.stopping;
    final err     = state == _SessionState.error;
    final c       = running ? _A.red : err ? _A.orange : _A.indigo;
    final lbl = loading
      ? (state == _SessionState.connecting ? l10n.t('common_connecting') : l10n.t('common_stopping'))
      : running ? l10n.t('translate_stop_session') : err ? l10n.t('common_retry') : l10n.t('translate_start_session');
    final ico = loading ? Icons.hourglass_empty_rounded
      : running ? Icons.stop_rounded : err ? Icons.refresh_rounded : Icons.play_arrow_rounded;
    return GestureDetector(
      onTap: loading ? null : (running ? onStop : onStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.withOpacity(0.09), borderRadius: BorderRadius.circular(11),
          border: Border.all(color: c.withOpacity(0.28))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            SizedBox(width: 13, height: 13,
              child: CircularProgressIndicator(strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(c)))
          else Icon(ico, color: c, size: 15),
          const SizedBox(width: 7),
          Text(lbl, style: GoogleFonts.nunito(
            color: c, fontSize: 13, fontWeight: FontWeight.w700)),
        ])));
  }
}

class _WebOutlineBtn extends StatelessWidget {
  final IconData icon; final String label; final bool d; final VoidCallback onTap;
  const _WebOutlineBtn({required this.icon, required this.label, required this.d, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _A.sep(d))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _A.label2(d)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.nunito(
          fontSize: 13, color: _A.label2(d), fontWeight: FontWeight.w600)),
      ])));
}

class _WebCamPlaceholder extends StatelessWidget {
  final bool d;
  const _WebCamPlaceholder({required this.d});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
        child: Icon(Icons.videocam_off_rounded, color: Colors.white.withOpacity(0.22), size: 32)),
      const SizedBox(height: 12),
      Text(l.t('translate_press_start'),
        style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.28), fontSize: 13)),
    ]));
  }
}

class _LiveBadge extends StatelessWidget {
  final Animation<double> pulse;
  const _LiveBadge({required this.pulse});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _A.red.withOpacity(0.90), borderRadius: BorderRadius.circular(7),
        boxShadow: [BoxShadow(
          color: _A.red.withOpacity(0.42 * pulse.value), blurRadius: 10)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 2.5, backgroundColor: Colors.white),
        const SizedBox(width: 5),
        Text(AppLocalizations.of(context).t('common_live').toUpperCase(), style: GoogleFonts.nunito(
          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.8)),
      ])));
}

class _ConnectingOverlay extends StatelessWidget {
  final bool d;
  const _ConnectingOverlay({required this.d});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withOpacity(0.55),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_A.indigo), strokeWidth: 2),
      const SizedBox(height: 12),
      Text(AppLocalizations.of(context).t('translate_establishing_connection'),
        style: GoogleFonts.nunito(color: _A.indigo, fontWeight: FontWeight.w700, fontSize: 13)),
    ])));
}

class _ErrorOverlay extends StatelessWidget {
  final bool d;
  const _ErrorOverlay({required this.d});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withOpacity(0.70),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.warning_amber_rounded, color: _A.red, size: 32),
      const SizedBox(height: 8),
      Text(AppLocalizations.of(context).t('translate_connection_error'), style: GoogleFonts.nunito(
        color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 15)),
    ])));
}

class _ErrorBanner extends StatelessWidget {
  final String msg; final bool d;
  const _ErrorBanner({required this.msg, required this.d});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _A.red.withOpacity(d ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _A.red.withOpacity(0.25))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: _A.red, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.nunito(
        color: _A.red, fontSize: 12.5, fontWeight: FontWeight.w500))),
    ]));
}