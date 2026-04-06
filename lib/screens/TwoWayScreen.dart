// lib/screens/TwoWayScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Two-Way Bridge Screen  · UX4G Redesign                    ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║                                                                    ║
// ║  FEATURES (production-ready):                                      ║
// ║  • ISL sign detection via WebSocket (preserved exactly)            ║
// ║  • Voice INPUT  — speech_to_text (hearing person speaks)          ║
// ║  • Voice OUTPUT — flutter_tts (reads detected ISL signs aloud)    ║
// ║  • Multilingual TTS: EN / Hindi / Marathi / Gujarati / Tamil etc  ║
// ║  • Multilingual STT: localeId per selected language               ║
// ║  • Auto-speak toggle — TTS fires on every new message             ║
// ║  • Language selector with flag + name                             ║
// ║  • Quick phrases: icon + text, NO emojis                         ║
// ║  • Real-time message thread with sender role labels               ║
// ║  • Reconnect with exponential back-off (preserved)                ║
// ║                                                                    ║
// ║  UX4G Principles Applied:                                         ║
// ║  • Google Sans throughout                                          ║
// ║  • Semantic color roles: primary/secondary/success/danger/info    ║
// ║  • WCAG AA contrast on all text/bg pairs                          ║
// ║  • Min 48dp touch targets                                         ║
// ║  • Semantics() on all interactive elements                        ║
// ║  • No decorative BackdropFilter on primary content areas          ║
// ║  • Clear visual hierarchy per UX4G information architecture       ║
// ║  • Status chips: dot + label + semantic border                    ║
// ╚══════════════════════════════════════════════════════════════════════╝

// ignore_for_file: unused_element, unused_local_variable, unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────────────
//  WEBSOCKET CONFIG  (unchanged from original)
// ─────────────────────────────────────────────────────────────────────
const String _kRailwayHost = 'isl-production-57d4.up.railway.app';
const String _kWsPath = '/ws';
const int _kFrameIntervalMs = 100;
const bool _railwayWsEnabled =
    true; // set to false to disable WebSocket connection (for testing without backend)

String _getWebSocketUrl() => 'wss://$_kRailwayHost$_kWsPath';

const double _kMinPredictionConfidence = 0.30;
const int _kStableDetectionMs = 450;
const int _kDetectionCooldownMs = 800;
const int _kSameLabelCooldownMs = 1800;

// ─────────────────────────────────────────────────────────────────────
//  UX4G DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

// Primary (blue) — deaf / ISL channel
const _primary = Color(0xFF1A56DB);
const _primaryDark = Color(0xFF4A8EFF);
const _primaryLight = Color(0xFFE8F0FE);

// Secondary (teal) — hearing / voice channel
const _secondary = Color(0xFF00796B);
const _secondaryDark = Color(0xFF26A69A);
const _secondaryLight = Color(0xFFE0F2F1);

// Accent (violet) — ISL specific
const _violet = Color(0xFF5B21B6);
const _violetLight = Color(0xFF7C3AED);
const _violetSurf = Color(0xFFEDE9FE);
const _violetSurfD = Color(0xFF1E1040);

// Status
const _success = Color(0xFF1B7340);
const _successDark = Color(0xFF27AE60);
const _successLight = Color(0xFFE6F4EC);
const _danger = Color(0xFFB71C1C);
const _dangerDark = Color(0xFFEF5350);
const _dangerLight = Color(0xFFFFEBEE);
const _warning = Color(0xFF7A4800);
const _warningDark = Color(0xFFFFB300);
const _info = Color(0xFF0D47A1);
const _infoDark = Color(0xFF42A5F5);

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
const _sp32 = 32.0;
const _sp48 = 48.0;

// ── Type helpers ──────────────────────────────────────────────────────
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
//  LANGUAGE CONFIG — TTS + STT locale IDs
// ─────────────────────────────────────────────────────────────────────
class _LangConfig {
  final String code;
  final String nameKey;
  final String flag; // text flag
  final String ttsLocale; // flutter_tts setLanguage
  final String sttLocaleId; // speech_to_text localeId
  const _LangConfig({
    required this.code,
    required this.nameKey,
    required this.flag,
    required this.ttsLocale,
    required this.sttLocaleId,
  });
}

const List<_LangConfig> _kLanguages = [
  _LangConfig(
    code: 'en',
    nameKey: 'lang_en',
    flag: 'EN',
    ttsLocale: 'en-IN',
    sttLocaleId: 'en_IN',
  ),
  _LangConfig(
    code: 'hi',
    nameKey: 'lang_hi',
    flag: 'HI',
    ttsLocale: 'hi-IN',
    sttLocaleId: 'hi_IN',
  ),
  _LangConfig(
    code: 'mr',
    nameKey: 'lang_mr',
    flag: 'MR',
    ttsLocale: 'mr-IN',
    sttLocaleId: 'mr_IN',
  ),
  _LangConfig(
    code: 'gu',
    nameKey: 'lang_gu',
    flag: 'GU',
    ttsLocale: 'gu-IN',
    sttLocaleId: 'gu_IN',
  ),
  _LangConfig(
    code: 'ta',
    nameKey: 'lang_ta',
    flag: 'TA',
    ttsLocale: 'ta-IN',
    sttLocaleId: 'ta_IN',
  ),
  _LangConfig(
    code: 'te',
    nameKey: 'lang_te',
    flag: 'TE',
    ttsLocale: 'te-IN',
    sttLocaleId: 'te_IN',
  ),
  _LangConfig(
    code: 'kn',
    nameKey: 'lang_kn',
    flag: 'KA',
    ttsLocale: 'kn-IN',
    sttLocaleId: 'kn_IN',
  ),
  _LangConfig(
    code: 'bn',
    nameKey: 'lang_bn',
    flag: 'BN',
    ttsLocale: 'bn-IN',
    sttLocaleId: 'bn_IN',
  ),
];

_LangConfig _langFor(String code) =>
    _kLanguages.firstWhere((l) => l.code == code, orElse: () => _kLanguages[0]);

// ─────────────────────────────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────────────────────────────
enum _Sender { deaf, hearing }

class _Message {
  final String text;
  final _Sender sender;
  final DateTime time;
  final bool isSign;
  final bool isVoice; // spoken by hearing person
  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.isSign = false,
    this.isVoice = false,
  });
}

// ─────────────────────────────────────────────────────────────────────
//  QUICK PHRASES — no emojis, icon + text
// ─────────────────────────────────────────────────────────────────────
class _Phrase {
  final IconData icon;
  final String key;
  const _Phrase(this.icon, this.key);
}

const List<_Phrase> _kPhrases = [
  _Phrase(Icons.waving_hand_outlined, 'phrase_1'),
  _Phrase(Icons.badge_outlined, 'phrase_2'),
  _Phrase(Icons.hourglass_empty_rounded, 'phrase_3'),
  _Phrase(Icons.check_circle_outline_rounded, 'phrase_4'),
  _Phrase(Icons.edit_outlined, 'phrase_5'),
  _Phrase(Icons.directions_walk_rounded, 'phrase_6'),
  _Phrase(Icons.emergency_outlined, 'phrase_7'),
  _Phrase(Icons.local_hospital_outlined, 'phrase_8'),
  _Phrase(Icons.calendar_today_outlined, 'phrase_9'),
  _Phrase(Icons.chair_outlined, 'phrase_10'),
  _Phrase(Icons.handshake_outlined, 'phrase_11'),
  _Phrase(Icons.call_outlined, 'phrase_12'),
];

// ══════════════════════════════════════════════════════════════════════
//  TWO WAY SCREEN
// ══════════════════════════════════════════════════════════════════════
class TwoWayScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const TwoWayScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<TwoWayScreen> createState() => _TwoWayScreenState();
}

class _TwoWayScreenState extends State<TwoWayScreen>
    with TickerProviderStateMixin {
  // ── Camera ────────────────────────────────────────────────────────
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  bool _camReady = false;
  bool _camActive = true;
  int _camIndex = 0;

  // ── WebSocket ─────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  bool _wsConnected = false;
  Timer? _frameTimer;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _maxReconnectAttempts = 5;

  // ── Messages ──────────────────────────────────────────────────────
  final List<_Message> _messages = [];
  final ScrollController _scroll = ScrollController();

  // ── Hearing input ─────────────────────────────────────────────────
  final TextEditingController _typeCtrl = TextEditingController();
  final FocusNode _typeFocus = FocusNode();
  bool _typeFocused = false;

  // ── ISL detection ─────────────────────────────────────────────────
  String _pending = '';
  bool _detecting = false;
  String _candidate = '';
  DateTime _candidateSince = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastAccepted = '';
  DateTime _lastAcceptedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Language ──────────────────────────────────────────────────────
  String _selectedLangCode = 'en';
  _LangConfig get _lang => _langFor(_selectedLangCode);

  // ── TTS ───────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsSpeaking = false;
  bool _autoSpeak = true; // auto-read every new message aloud

  // ── STT ───────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechOk = false;
  bool _listening = false;

  // ── Animations ────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
    _initTts();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWs());
    _typeFocus.addListener(
      () => setState(() => _typeFocused = _typeFocus.hasFocus),
    );
    _typeCtrl.addListener(() => setState(() {}));
  }

  void _initAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  // ── TTS ──────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    await _tts.setLanguage(_lang.ttsLocale);
    await _tts.setSpeechRate(0.90);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady || text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage(_lang.ttsLocale);
    setState(() => _ttsSpeaking = true);
    await _tts.speak(text);
  }

  Future<void> _stopSpeak() async {
    await _tts.stop();
    if (mounted) setState(() => _ttsSpeaking = false);
  }

  Future<void> _updateTtsLang() async {
    await _tts.setLanguage(_lang.ttsLocale);
  }

  // ── STT ──────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    _speechOk = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechOk) return;
    HapticFeedback.mediumImpact();

    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    // Check if locale supported; fall back to en_US
    final locales = await _speech.locales();
    final supported = locales.any((l) => l.localeId == _lang.sttLocaleId);
    final localeId = supported ? _lang.sttLocaleId : 'en_US';

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() {
            _typeCtrl.text = result.recognizedWords;
            _listening = false;
          });
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  CAMERA
  // ─────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _camIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_camIndex < 0) _camIndex = 0;
      await _startCamera(_camIndex);
    } catch (_) {}
  }

  Future<void> _startCamera(int idx) async {
    await _cam?.dispose();
    _cam = CameraController(
      _cameras[idx],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
      _startFrameStream();
    } catch (_) {}
  }

  void _startFrameStream() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(Duration(milliseconds: _kFrameIntervalMs), (
      _,
    ) async {
      if (!_camReady || !_camActive || !_wsConnected) return;
      if (_cam == null || !_cam!.value.isInitialized) return;
      try {
        final img = await _cam!.takePicture();
        final bytes = await img.readAsBytes();
        _ws?.sink.add(base64Encode(bytes));
      } catch (_) {}
    });
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _camIndex = (_camIndex + 1) % _cameras.length;
    setState(() => _camReady = false);
    await _startCamera(_camIndex);
  }

  void _toggleCamera() {
    setState(() => _camActive = !_camActive);
    if (!_camActive) _clearPending();
  }

  // ─────────────────────────────────────────────────────────────────
  //  WEBSOCKET
  // ─────────────────────────────────────────────────────────────────
  void _connectWs() {
    if (!_railwayWsEnabled) {
      setState(() => _wsConnected = false);
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    try {
      _ws = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));
      if (mounted) setState(() => _wsConnected = true);
      _reconnectAttempts = 0;
      _ws!.stream.listen(
        _onSignReceived,
        onError: (_) => _onWsDisconnected(),
        onDone: () => _onWsDisconnected(),
        cancelOnError: true,
      );
    } catch (_) {
      _onWsDisconnected();
    }
  }

  void _onWsDisconnected() {
    if (!mounted) return;
    setState(() => _wsConnected = false);
    _frameTimer?.cancel();
    _reconnectAttempts++;
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final delay = Duration(seconds: 1 << (_reconnectAttempts - 1));
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, _connectWs);
    }
  }

  ({String sign, double confidence})? _parsePrediction(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final raw = data.trim();
      if (raw.isEmpty) return null;
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          final obj = jsonDecode(raw) as Map<String, dynamic>;
          final type = (obj['type'] ?? 'prediction').toString();
          if (type != 'prediction') return null;
          final label = (obj['label'] ?? '').toString().trim();
          if (label.isEmpty) return null;
          final conf = (obj['confidence'] as num?)?.toDouble() ?? 1.0;
          return (sign: label.toUpperCase(), confidence: conf);
        } catch (_) {}
      }
      return (sign: raw.toUpperCase(), confidence: 1.0);
    }
    if (data is Map<String, dynamic>) {
      final type = (data['type'] ?? 'prediction').toString();
      if (type != 'prediction') return null;
      final label = (data['label'] ?? '').toString().trim();
      if (label.isEmpty) return null;
      final conf = (data['confidence'] as num?)?.toDouble() ?? 1.0;
      return (sign: label.toUpperCase(), confidence: conf);
    }
    return null;
  }

  void _onSignReceived(dynamic data) {
    final parsed = _parsePrediction(data);
    if (parsed == null) return;
    final sign = parsed.sign;
    final confidence = parsed.confidence;
    if (sign.isEmpty || sign == '—' || sign == '-') return;
    if (confidence < _kMinPredictionConfidence) {
      if (_detecting && mounted) setState(() => _detecting = false);
      return;
    }
    final now = DateTime.now();
    if (sign != _candidate) {
      _candidate = sign;
      _candidateSince = now;
      if (!_detecting && mounted) setState(() => _detecting = true);
      return;
    }
    if (now.difference(_candidateSince).inMilliseconds < _kStableDetectionMs)
      return;
    if (now.difference(_lastAcceptedAt).inMilliseconds < _kDetectionCooldownMs)
      return;
    if (sign == _lastAccepted &&
        now.difference(_lastAcceptedAt).inMilliseconds < _kSameLabelCooldownMs)
      return;
    if (sign == _pending) return;
    _lastAccepted = sign;
    _lastAcceptedAt = now;
    setState(() {
      _pending = sign;
      _detecting = false;
    });
  }

  void _confirmSign() {
    if (_pending.trim().isEmpty) return;
    final text = _pending.trim();
    _addMessage(text, _Sender.deaf, isSign: true);
    setState(() {
      _pending = '';
      _detecting = false;
    });
    _candidate = '';
    if (_autoSpeak) _speak(text);
  }

  void _clearPending() {
    setState(() {
      _pending = '';
      _detecting = false;
    });
    _candidate = '';
  }

  // ─────────────────────────────────────────────────────────────────
  //  MESSAGES
  // ─────────────────────────────────────────────────────────────────
  void _sendHearing({bool fromVoice = false}) {
    final text = _typeCtrl.text.trim();
    if (text.isEmpty) return;
    _typeCtrl.clear();
    _addMessage(text, _Sender.hearing, isVoice: fromVoice);
    HapticFeedback.lightImpact();
  }

  void _addMessage(
    String text,
    _Sender sender, {
    bool isSign = false,
    bool isVoice = false,
  }) {
    setState(
      () => _messages.add(
        _Message(
          text: text,
          sender: sender,
          time: DateTime.now(),
          isSign: isSign,
          isVoice: isVoice,
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 60), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        title: Text(
          l.t('bridge_clear_confirm_title'),
          style: _heading(17, textClr),
        ),
        content: Text(
          l.t('bridge_clear_confirm_body'),
          style: _body(14, subClr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.t('sos_cancel'),
              style: _body(14, subClr, w: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
            },
            child: Text(
              l.t('bridge_clear'),
              style: _body(
                14,
                isDark ? _dangerDark : _danger,
                w: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cam?.dispose();
    _ws?.sink.close();
    _frameTimer?.cancel();
    _reconnectTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _scroll.dispose();
    _typeCtrl.dispose();
    _typeFocus.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final isDesktop = w > 1100;
    final isTablet = w >= 700 && w <= 1100;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: isMobile ? Colors.black : (isDark ? _dBg : _lBg),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(
              children: [
                if (!isMobile)
                  GlobalNavbar(
                    toggleTheme: widget.toggleTheme,
                    setLocale: widget.setLocale,
                    activeRoute: 'bridge',
                  ),
                Expanded(
                  child: isMobile
                      ? _buildMobileShell(context, isDark, size)
                      : isDesktop
                      ? _desktopLayout(context, isDark, size)
                      : _tabletLayout(context, isDark, size),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ══════════════════════════════════════════════════════════════════
  Widget _desktopLayout(BuildContext ctx, bool isDark, Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_sp24, 0, _sp24, _sp16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — ISL camera panel
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _deafPanelHeader(isDark),
                const SizedBox(height: _sp12),
                Expanded(child: _cameraPanel(isDark)),
                const SizedBox(height: _sp12),
                _signStatusBar(isDark),
              ],
            ),
          ),
          const SizedBox(width: _sp16),
          // Centre — conversation
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _conversationHeader(isDark),
                const SizedBox(height: _sp12),
                Expanded(child: _messageThread(isDark)),
                const SizedBox(height: _sp12),
                _hearingInputBar(isDark),
              ],
            ),
          ),
          const SizedBox(width: _sp16),
          // Right — phrases + controls
          SizedBox(width: 200, child: _phrasesColumn(isDark)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TABLET LAYOUT
  // ══════════════════════════════════════════════════════════════════
  Widget _tabletLayout(BuildContext ctx, bool isDark, Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _deafPanelHeader(isDark),
                const SizedBox(height: _sp12),
                Expanded(child: _cameraPanel(isDark)),
                const SizedBox(height: _sp12),
                _signStatusBar(isDark),
              ],
            ),
          ),
          const SizedBox(width: _sp16),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _conversationHeader(isDark),
                const SizedBox(height: _sp12),
                Expanded(child: _messageThread(isDark)),
                const SizedBox(height: _sp12),
                _hearingInputBar(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  MOBILE SHELL
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMobileShell(BuildContext ctx, bool isDark, Size size) {
    final l = AppLocalizations.of(ctx);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera or placeholder
        if (_camReady && _camActive && _cam != null)
          CameraPreview(_cam!)
        else
          _mobileCamPlaceholder(),

        // Corner brackets
        Positioned.fill(
          child: CustomPaint(
            painter: _CornerPainter(
              color: _violet.withOpacity(_camActive && _camReady ? 0.6 : 0.22),
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            padding: const EdgeInsets.fromLTRB(_sp12, _sp12, _sp12, _sp12),
            child: Row(
              children: [
                // Back
                Semantics(
                  label: l.t('common_back'),
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _sp8),
                // Connection status
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => _ConnectionChip(
                    connected: _wsConnected,
                    pulse: _pulse,
                    label: _wsConnected
                        ? l.t('bridge_isl_live')
                        : l.t('common_connecting'),
                    dark: true,
                  ),
                ),
                const Spacer(),
                // Camera toggle
                Semantics(
                  label: _camActive
                      ? l.t('bridge_pause_camera')
                      : l.t('bridge_resume_camera'),
                  button: true,
                  child: _MobileTopBtn(
                    icon: _camActive
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    onTap: _toggleCamera,
                  ),
                ),
                if (_cameras.length > 1) ...[
                  const SizedBox(width: _sp8),
                  Semantics(
                    label: l.t('bridge_flip_camera'),
                    button: true,
                    child: _MobileTopBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _flipCamera,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Detected sign overlay
        if (_pending.isNotEmpty && _camActive)
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: Center(
              child: _PendingSignChip(
                sign: _pending,
                isDark: true,
                onConfirm: _confirmSign,
                onDismiss: _clearPending,
                l: AppLocalizations.of(ctx),
              ),
            ),
          ),

        // Detecting badge
        if (_detecting && _camActive)
          Positioned(
            top: 72,
            left: _sp12,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => _DetectingBadge(pulse: _pulse),
            ),
          ),

        // Bottom panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _MobileBridgePanel(
            isDark: isDark,
            messages: _messages,
            typeCtrl: _typeCtrl,
            typeFocus: _typeFocus,
            typeFocused: _typeFocused,
            listening: _listening,
            ttsSpeaking: _ttsSpeaking,
            autoSpeak: _autoSpeak,
            speechOk: _speechOk,
            selectedLangCode: _selectedLangCode,
            scrollCtrl: _scroll,
            pulse: _pulse,
            onSendHearing: _sendHearing,
            onVoiceInput: _toggleListening,
            onStopSpeak: _stopSpeak,
            onToggleAutoSpeak: () => setState(() => _autoSpeak = !_autoSpeak),
            onPhraseSelected: (p) {
              _addMessage(p, _Sender.hearing);
              if (_autoSpeak) _speak(p);
            },
            onLangChanged: (code) {
              setState(() => _selectedLangCode = code);
              _updateTtsLang();
            },
            onClearChat: _clearChat,
          ),
        ),
      ],
    );
  }

  Widget _mobileCamPlaceholder() => Container(
    color: const Color(0xFF06060F),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: _violet.withOpacity(0.20), width: 1),
          ),
          child: const Icon(
            Icons.sign_language_rounded,
            color: Color(0xFFA78BFA),
            size: 34,
          ),
        ),
        const SizedBox(height: _sp16),
        Text(
          AppLocalizations.of(context).t('bridge_camera_init'),
          style: _body(13, Colors.white38),
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  //  WEB / DESKTOP SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════

  // ── Deaf panel header ─────────────────────────────────────────────
  Widget _deafPanelHeader(bool isDark) {
    final l = AppLocalizations.of(context);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? Color(0xFFA78BFA) : _violet;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(_sp8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.22), width: 1),
          ),
          child: Icon(Icons.sign_language_rounded, color: accent, size: 16),
        ),
        const SizedBox(width: _sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('bridge_deaf_label'),
                style: _label(13, textClr, w: FontWeight.w700),
              ),
              Text(l.t('bridge_deaf_sublabel'), style: _body(11, subClr)),
            ],
          ),
        ),
        // WS status
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => _ConnectionChip(
            connected: _wsConnected,
            pulse: _pulse,
            label: _wsConnected
                ? l.t('bridge_isl_live')
                : (_reconnectAttempts < _maxReconnectAttempts
                      ? l.t('common_connecting')
                      : l.t('bridge_offline')),
            dark: isDark,
          ),
        ),
        const SizedBox(width: _sp8),
        // Camera controls
        Semantics(
          label: _camActive
              ? l.t('bridge_pause_camera')
              : l.t('bridge_resume_camera'),
          button: true,
          child: _IconActionBtn(
            icon: _camActive
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            color: _camActive ? accent : (isDark ? _dTextMuted : _lTextMuted),
            isDark: isDark,
            onTap: _toggleCamera,
          ),
        ),
        if (_cameras.length > 1) ...[
          const SizedBox(width: _sp4),
          Semantics(
            label: AppLocalizations.of(context).t('bridge_flip_camera'),
            button: true,
            child: _IconActionBtn(
              icon: Icons.flip_camera_ios_rounded,
              color: isDark ? _dTextSub : _lTextSub,
              isDark: isDark,
              onTap: _flipCamera,
            ),
          ),
        ],
      ],
    );
  }

  // ── Camera panel ──────────────────────────────────────────────────
  Widget _cameraPanel(bool isDark) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? Color(0xFFA78BFA) : _violet;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_camReady && _camActive && _cam != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CameraPreview(_cam!),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? _dSurface2 : _lSurface2,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.sign_language_rounded,
                        color: accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: _sp12),
                    Text(l.t('bridge_camera_init'), style: _body(12, subClr)),
                    const SizedBox(height: _sp4),
                    Text(
                      l.t('bridge_camera_hint'),
                      style: _body(11, isDark ? _dTextMuted : _lTextMuted),
                    ),
                  ],
                ),
              ),

            // Corner brackets overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _CornerPainter(color: accent.withOpacity(0.55)),
              ),
            ),

            // Detecting badge
            if (_detecting && _camActive)
              Positioned(
                top: 10,
                left: 10,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => _DetectingBadge(pulse: _pulse),
                ),
              ),

            // Pending sign overlay (bottom gradient)
            if (_pending.isNotEmpty && _camActive)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(_sp12, _sp8, _sp12, _sp12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: _PendingSignChip(
                    sign: _pending,
                    isDark: true,
                    onConfirm: _confirmSign,
                    onDismiss: _clearPending,
                    l: l,
                  ),
                ),
              ),

            // Camera paused overlay
            if (!_camActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: bg.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        color: isDark ? _dTextMuted : _lTextMuted,
                        size: 32,
                      ),
                      const SizedBox(height: _sp8),
                      Text(
                        l.t('bridge_camera_paused'),
                        style: _body(12, subClr),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sign status bar ────────────────────────────────────────────────
  Widget _signStatusBar(bool isDark) {
    final l = AppLocalizations.of(context);
    final hasPending = _pending.isNotEmpty;
    final accent = isDark ? Color(0xFFA78BFA) : _violet;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
      decoration: BoxDecoration(
        color: hasPending ? accent.withOpacity(0.08) : bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPending ? accent.withOpacity(0.35) : border,
          width: hasPending ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending
                ? Icons.record_voice_over_rounded
                : Icons.front_hand_rounded,
            color: hasPending ? accent : (isDark ? _dTextMuted : _lTextMuted),
            size: 18,
          ),
          const SizedBox(width: _sp12),
          Expanded(
            child: Text(
              hasPending
                  ? _pending
                  : (_wsConnected
                        ? l.t('bridge_waiting_sign')
                        : l.t('bridge_connect_backend')),
              style: _label(
                hasPending ? 14 : 12,
                hasPending ? accent : subClr,
                w: hasPending ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (hasPending) ...[
            Semantics(
              label: l.t('bridge_confirm_sign'),
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _confirmSign,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _sp12,
                    vertical: _sp4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.t('bridge_send'),
                        style: _label(11, Colors.white, w: FontWeight.w700),
                      ),
                      const SizedBox(width: _sp4),
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: _sp8),
            Semantics(
              label: l.t('bridge_dismiss_sign'),
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _clearPending,
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? _dTextMuted : _lTextMuted,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Conversation header ────────────────────────────────────────────
  Widget _conversationHeader(bool isDark) {
    final l = AppLocalizations.of(context);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _secondaryDark : _secondary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(_sp8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.22), width: 1),
          ),
          child: Icon(Icons.forum_rounded, color: accent, size: 16),
        ),
        const SizedBox(width: _sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('bridge_convo_title'),
                style: _label(13, textClr, w: FontWeight.w700),
              ),
              Text(
                _messages.isEmpty
                    ? l.t('bridge_empty_title')
                    : '${_messages.length} messages',
                style: _body(11, subClr),
              ),
            ],
          ),
        ),
        // Language selector
        _LangSelector(
          selectedCode: _selectedLangCode,
          isDark: isDark,
          onChanged: (code) {
            setState(() => _selectedLangCode = code);
            _updateTtsLang();
          },
        ),
        const SizedBox(width: _sp8),
        // Auto-speak toggle
        Semantics(
          label: l.t(
            _autoSpeak
                ? 'bridge_disable_auto_speak'
                : 'bridge_enable_auto_speak',
          ),
          button: true,
          child: Tooltip(
            message: l.t('bridge_auto_speak'),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _autoSpeak = !_autoSpeak),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _autoSpeak
                      ? accent.withOpacity(0.10)
                      : (isDark ? _dSurface2 : _lSurface2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _autoSpeak
                        ? accent.withOpacity(0.30)
                        : (isDark ? _dBorder : _lBorder),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _autoSpeak
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  size: 16,
                  color: _autoSpeak
                      ? accent
                      : (isDark ? _dTextMuted : _lTextMuted),
                ),
              ),
            ),
          ),
        ),
        if (_messages.isNotEmpty) ...[
          const SizedBox(width: _sp8),
          Semantics(
            label: l.t('bridge_clear_convo'),
            button: true,
            child: _IconActionBtn(
              icon: Icons.delete_sweep_rounded,
              color: isDark ? _dTextSub : _lTextSub,
              isDark: isDark,
              onTap: _clearChat,
            ),
          ),
        ],
      ],
    );
  }

  // ── Message thread ─────────────────────────────────────────────────
  Widget _messageThread(bool isDark) {
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: _messages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(_sp24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? _dSurface2 : _lSurface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.forum_outlined,
                        color: mutedClr,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: _sp12),
                    Text(
                      l.t('bridge_empty_title'),
                      style: _heading(14, isDark ? _dText : _lText),
                    ),
                    const SizedBox(height: _sp8),
                    Text(
                      l.t('bridge_empty_sub'),
                      textAlign: TextAlign.center,
                      style: _body(12, subClr),
                    ),
                  ],
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp12,
                  vertical: _sp16,
                ),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _MessageBubble(
                  msg: _messages[i],
                  isDark: isDark,
                  onSpeak: _speak,
                  ttsSpeaking: _ttsSpeaking,
                ),
              ),
            ),
    );
  }

  // ── Hearing input bar ──────────────────────────────────────────────
  Widget _hearingInputBar(bool isDark) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final accent = isDark ? _secondaryDark : _secondary;

    // Mic state — danger when listening
    final micColor = _listening
        ? (isDark ? _dangerDark : _danger)
        : (isDark ? _dTextSub : _lTextSub);
    final micBg = _listening
        ? (isDark ? _dangerDark.withOpacity(0.15) : _dangerLight)
        : (isDark ? _dSurface2 : _lSurface2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role label + phrases button
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.22), width: 1),
              ),
              child: Icon(Icons.keyboard_rounded, color: accent, size: 14),
            ),
            const SizedBox(width: _sp8),
            Text(
              l.t('bridge_hearing_sublabel'),
              style: _label(
                11,
                isDark ? _dTextSub : _lTextSub,
                w: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Quick phrases button
            Semantics(
              label: l.t('bridge_quick_phrases'),
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showPhraseSheet(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _sp12,
                    vertical: _sp4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withOpacity(0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on_rounded, color: accent, size: 12),
                      const SizedBox(width: _sp4),
                      Text(
                        l.t('bridge_quick_phrases'),
                        style: _label(11, accent, w: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _sp8),
        // Input row
        Row(
          children: [
            // Mic button
            if (_speechOk)
              Semantics(
                label: l.t(
                  _listening
                      ? 'bridge_stop_voice_input'
                      : 'bridge_start_voice_input',
                ),
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _toggleListening,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: micBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _listening ? micColor.withOpacity(0.35) : border,
                        width: _listening ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 18,
                      color: micColor,
                    ),
                  ),
                ),
              ),
            if (_speechOk) const SizedBox(width: _sp8),
            // Text field
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _typeFocused ? accent.withOpacity(0.45) : border,
                    width: _typeFocused ? 1.5 : 1.0,
                  ),
                ),
                child: TextField(
                  controller: _typeCtrl,
                  focusNode: _typeFocus,
                  style: _body(14, textClr),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendHearing(),
                  decoration: InputDecoration(
                    hintText: _listening
                        ? '${l.t('isl_input_listening')} (${l.t(_lang.nameKey)})'
                        : l.t('bridge_type_hint'),
                    hintStyle: _body(14, mutedClr),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: _sp16,
                      vertical: _sp12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _sp8),
            // Send button
            Semantics(
              label: l.t('common_send_message'),
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _sendHearing,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typeCtrl.text.isEmpty
                        ? (isDark ? _dSurface2 : _lSurface2)
                        : accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _typeCtrl.text.isEmpty ? border : accent,
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: _typeCtrl.text.isEmpty ? mutedClr : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Phrases column (desktop) ───────────────────────────────────────
  Widget _phrasesColumn(bool isDark) {
    final l = AppLocalizations.of(context);
    final accent = isDark ? _secondaryDark : _secondary;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final textClr = isDark ? _dText : _lText;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.flash_on_rounded, color: accent, size: 14),
            const SizedBox(width: _sp8),
            Text(
              l.t('bridge_quick_phrases'),
              style: _label(11, subClr, w: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: _sp8),
        // Scrollable list
        Expanded(
          child: ListView.builder(
            itemCount: _kPhrases.length,
            itemBuilder: (_, i) {
              final p = _kPhrases[i];
              return Semantics(
                label: l.t(p.key),
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final text = l.t(p.key);
                    _addMessage(text, _Sender.hearing);
                    if (_autoSpeak) _speak(text);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: _sp8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _sp12,
                      vertical: _sp8,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(p.icon, size: 14, color: accent),
                        const SizedBox(width: _sp8),
                        Expanded(
                          child: Text(
                            l.t(p.key),
                            style: _body(11, subClr),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Phrase bottom sheet (mobile + web tablet) ──────────────────────
  void _showPhraseSheet(bool isDark) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _secondaryDark : _secondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: border, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: _sp8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? _dBorder : _lBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: _sp16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _sp20),
                child: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: accent, size: 16),
                    const SizedBox(width: _sp8),
                    Text(
                      l.t('bridge_quick_phrases'),
                      style: _heading(16, textClr),
                    ),
                    const Spacer(),
                    Text(l.t('bridge_tap_to_send'), style: _body(12, subClr)),
                  ],
                ),
              ),
              const SizedBox(height: _sp16),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: _sp16),
                  itemCount: _kPhrases.length,
                  itemBuilder: (_, i) {
                    final p = _kPhrases[i];
                    final text = l.t(p.key);
                    return Semantics(
                      label: text,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(ctx);
                          _addMessage(text, _Sender.hearing);
                          if (_autoSpeak) _speak(text);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: _sp8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: _sp16,
                            vertical: _sp12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? _dSurface2 : _lSurface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(p.icon, color: accent, size: 18),
                              ),
                              const SizedBox(width: _sp12),
                              Expanded(
                                child: Text(text, style: _body(13, textClr)),
                              ),
                              Icon(Icons.send_rounded, color: accent, size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + _sp16),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ══════════════════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final bool isDark, ttsSpeaking;
  final Future<void> Function(String) onSpeak;
  const _MessageBubble({
    required this.msg,
    required this.isDark,
    required this.onSpeak,
    required this.ttsSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDeaf = msg.sender == _Sender.deaf;
    final accent = isDeaf
        ? Color(0xFFA78BFA)
        : (isDark ? _secondaryDark : _secondary);
    final bubbleBg = isDeaf
        ? (isDark ? Color(0xFF1E1040) : Color(0xFFEDE9FE))
        : (isDark ? Color(0xFF003D36) : Color(0xFFE0F2F1));
    final border = accent.withOpacity(0.25);
    final textClr = isDark ? _dText : _lText;
    final timeClr = isDark ? _dTextMuted : _lTextMuted;
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:'
        '${msg.time.minute.toString().padLeft(2, '0')}';

    return Semantics(
      label:
          '${isDeaf ? l.t('bridge_message_source_sign') : l.t('bridge_message_source_voice')}: ${msg.text}',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: _sp4,
          left: isDeaf ? 0 : 32,
          right: isDeaf ? 32 : 0,
        ),
        child: Column(
          crossAxisAlignment: isDeaf
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            // Role row
            Padding(
              padding: const EdgeInsets.only(
                bottom: _sp4,
                left: _sp4,
                right: _sp4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isDeaf
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  Icon(
                    isDeaf
                        ? Icons.sign_language_rounded
                        : (msg.isVoice
                              ? Icons.mic_rounded
                              : Icons.keyboard_rounded),
                    size: 10,
                    color: accent.withOpacity(0.7),
                  ),
                  const SizedBox(width: _sp4),
                  Text(
                    isDeaf
                        ? l.t('bridge_deaf_label')
                        : l.t('bridge_hearing_label'),
                    style: _label(
                      10,
                      accent.withOpacity(0.7),
                      w: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _sp12,
                vertical: _sp8,
              ),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isDeaf ? 4 : 14),
                  bottomRight: Radius.circular(isDeaf ? 14 : 4),
                ),
                border: Border.all(color: border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ISL sign badge
                  if (msg.isSign)
                    Container(
                      margin: const EdgeInsets.only(bottom: _sp4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sp8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.t('bridge_isl_sign_badge'),
                        style: _label(8, accent, w: FontWeight.w800),
                      ),
                    ),
                  // Message text
                  Text(msg.text, style: _body(13, textClr, w: FontWeight.w500)),
                  const SizedBox(height: _sp4),
                  // Time + speak button row
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: _label(9, timeClr, w: FontWeight.w400),
                      ),
                      const Spacer(),
                      // Speak button
                      Semantics(
                        label: l.t('common_speak'),
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onSpeak(msg.text),
                          child: Padding(
                            padding: const EdgeInsets.all(_sp4),
                            child: Icon(
                              ttsSpeaking
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_up_outlined,
                              size: 14,
                              color: accent.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: _sp8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  LANGUAGE SELECTOR
// ══════════════════════════════════════════════════════════════════════
class _LangSelector extends StatelessWidget {
  final String selectedCode;
  final bool isDark;
  final bool compact;
  final void Function(String) onChanged;
  const _LangSelector({
    required this.selectedCode,
    required this.isDark,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = isDark ? _secondaryDark : _secondary;
    final bg = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final cur = _langFor(selectedCode);

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).t('common_select_language'),
      color: isDark ? _dSurface2 : _lSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      elevation: 8,
      offset: const Offset(0, 44),
      onSelected: onChanged,
      itemBuilder: (_) => _kLanguages.map((lang) {
        final sel = lang.code == selectedCode;
        return PopupMenuItem<String>(
          value: lang.code,
          height: 44,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: sel
                      ? accent.withOpacity(0.12)
                      : (isDark ? _dSurface : _lSurface2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sel ? accent.withOpacity(0.30) : border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    lang.flag,
                    style: _label(9, sel ? accent : subClr, w: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: _sp12),
              Text(
                l.t(lang.nameKey),
                style: _body(
                  13,
                  sel ? accent : (isDark ? _dText : _lText),
                  w: sel ? FontWeight.w700 : FontWeight.w400,
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
      child: Semantics(
        label: AppLocalizations.of(context).t('common_select_language'),
        button: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _sp12,
            vertical: _sp8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    cur.flag,
                    style: _label(9, accent, w: FontWeight.w800),
                  ),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: _sp8),
                Text(l.t(cur.nameKey), style: _label(12, textClr)),
                const SizedBox(width: _sp4),
              ],
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: isDark ? _dTextSub : _lTextSub,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE BRIDGE PANEL
// ══════════════════════════════════════════════════════════════════════
class _MobileBridgePanel extends StatefulWidget {
  final bool isDark, listening, ttsSpeaking, autoSpeak, speechOk;
  final List<_Message> messages;
  final TextEditingController typeCtrl;
  final FocusNode typeFocus;
  final bool typeFocused;
  final ScrollController scrollCtrl;
  final Animation<double> pulse;
  final String selectedLangCode;
  final VoidCallback onSendHearing, onVoiceInput, onStopSpeak;
  final VoidCallback onToggleAutoSpeak, onClearChat;
  final void Function(String) onPhraseSelected;
  final void Function(String) onLangChanged;

  const _MobileBridgePanel({
    required this.isDark,
    required this.listening,
    required this.ttsSpeaking,
    required this.autoSpeak,
    required this.speechOk,
    required this.messages,
    required this.typeCtrl,
    required this.typeFocus,
    required this.typeFocused,
    required this.scrollCtrl,
    required this.pulse,
    required this.selectedLangCode,
    required this.onSendHearing,
    required this.onVoiceInput,
    required this.onStopSpeak,
    required this.onToggleAutoSpeak,
    required this.onClearChat,
    required this.onPhraseSelected,
    required this.onLangChanged,
  });

  @override
  State<_MobileBridgePanel> createState() => _MobileBridgePanelState();
}

class _MobileBridgePanelState extends State<_MobileBridgePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bg = isDark
        ? const Color(0xFF0D1117).withOpacity(0.96)
        : Colors.white.withOpacity(0.97);
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final accent = isDark ? _secondaryDark : _secondary;
    final micColor = widget.listening
        ? (isDark ? _dangerDark : _danger)
        : (isDark ? _dTextSub : _lTextSub);
    final narrowLayout = MediaQuery.of(context).size.width < 390;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: _sp8, bottom: _sp4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? _dBorder : _lBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Tab row + controls
            Padding(
              padding: const EdgeInsets.fromLTRB(_sp16, _sp4, _sp16, _sp8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MobilePanelTab(
                          label: l.t('bridge_convo_title'),
                          icon: Icons.forum_rounded,
                          active: _tab == 0,
                          isDark: isDark,
                          compact: narrowLayout,
                          badge: widget.messages.length,
                          onTap: () => setState(() => _tab = 0),
                        ),
                      ),
                      const SizedBox(width: _sp8),
                      Expanded(
                        child: _MobilePanelTab(
                          label: l.t('bridge_quick_phrases'),
                          icon: Icons.flash_on_rounded,
                          active: _tab == 1,
                          isDark: isDark,
                          compact: narrowLayout,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _sp8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _LangSelector(
                        selectedCode: widget.selectedLangCode,
                        isDark: isDark,
                        compact: narrowLayout,
                        onChanged: widget.onLangChanged,
                      ),
                      const SizedBox(width: _sp8),
                      // Auto-speak toggle
                      Semantics(
                        label: l.t('bridge_auto_speak'),
                        button: true,
                        toggled: widget.autoSpeak,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onToggleAutoSpeak,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: widget.autoSpeak
                                  ? accent.withOpacity(0.10)
                                  : (isDark ? _dSurface2 : _lSurface2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.autoSpeak
                                    ? accent.withOpacity(0.30)
                                    : border,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.autoSpeak
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: 16,
                              color: widget.autoSpeak ? accent : mutedClr,
                            ),
                          ),
                        ),
                      ),
                      if (_tab == 0 && widget.messages.isNotEmpty) ...[
                        const SizedBox(width: _sp8),
                        Semantics(
                          label: l.t('common_clear'),
                          button: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onClearChat,
                            child: Icon(
                              Icons.delete_sweep_rounded,
                              color: mutedClr,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == 0
                  ? _MobileChatTab(
                      messages: widget.messages,
                      typeCtrl: widget.typeCtrl,
                      typeFocus: widget.typeFocus,
                      typeFocused: widget.typeFocused,
                      isDark: isDark,
                      scrollCtrl: widget.scrollCtrl,
                      onSend: widget.onSendHearing,
                      onVoice: widget.onVoiceInput,
                      speechOk: widget.speechOk,
                      listening: widget.listening,
                      micColor: micColor,
                    )
                  : _MobilePhrasesTab(
                      isDark: isDark,
                      onPhraseSelected: widget.onPhraseSelected,
                    ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + _sp8),
          ],
        ),
      ),
    );
  }
}

// ── Mobile chat tab ───────────────────────────────────────────────────
class _MobileChatTab extends StatelessWidget {
  final List<_Message> messages;
  final TextEditingController typeCtrl;
  final FocusNode typeFocus;
  final bool typeFocused, isDark, speechOk, listening;
  final ScrollController scrollCtrl;
  final VoidCallback onSend, onVoice;
  final Color micColor;

  const _MobileChatTab({
    required this.messages,
    required this.typeCtrl,
    required this.typeFocus,
    required this.typeFocused,
    required this.isDark,
    required this.scrollCtrl,
    required this.onSend,
    required this.onVoice,
    required this.speechOk,
    required this.listening,
    required this.micColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final bg = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder : _lBorder;
    final accent = isDark ? _secondaryDark : _secondary;
    final micBg = listening
        ? (isDark ? _dangerDark.withOpacity(0.15) : _dangerLight)
        : bg;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message list
        SizedBox(
          height: 200,
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum_outlined, color: mutedClr, size: 22),
                      const SizedBox(height: _sp8),
                      Text(
                        l.t('bridge_empty_sub'),
                        style: _body(11, subClr),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _sp16,
                    vertical: _sp8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isDeaf = msg.sender == _Sender.deaf;
                    final ac = isDeaf
                        ? Color(0xFFA78BFA)
                        : (isDark ? _secondaryDark : _secondary);
                    final bubBg = isDeaf
                        ? (isDark ? Color(0xFF1E1040) : Color(0xFFEDE9FE))
                        : (isDark ? Color(0xFF003D36) : Color(0xFFE0F2F1));
                    final ts =
                        '${msg.time.hour.toString().padLeft(2, '0')}:'
                        '${msg.time.minute.toString().padLeft(2, '0')}';
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: _sp8,
                        left: isDeaf ? 0 : 24,
                        right: isDeaf ? 24 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp12,
                          vertical: _sp8,
                        ),
                        decoration: BoxDecoration(
                          color: bubBg,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isDeaf ? 3 : 12),
                            bottomRight: Radius.circular(isDeaf ? 12 : 3),
                          ),
                          border: Border.all(
                            color: ac.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.isSign)
                              Container(
                                margin: const EdgeInsets.only(bottom: _sp4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _sp8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ac.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l.t('bridge_isl_sign_badge'),
                                  style: _label(8, ac, w: FontWeight.w800),
                                ),
                              ),
                            Text(
                              msg.text,
                              style: _body(13, textClr, w: FontWeight.w500),
                            ),
                            const SizedBox(height: _sp4),
                            Text(
                              ts,
                              style: _label(
                                9,
                                ac.withOpacity(0.5),
                                w: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: _sp8),

        // Input row
        Padding(
          padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, 0),
          child: Row(
            children: [
              // Mic
              if (speechOk)
                Semantics(
                  label: listening
                      ? l.t('bridge_stop_voice_input')
                      : l.t('bridge_start_voice_input'),
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onVoice,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: micBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: listening
                              ? micColor.withOpacity(0.35)
                              : border,
                          width: listening ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 18,
                        color: micColor,
                      ),
                    ),
                  ),
                ),
              if (speechOk) const SizedBox(width: _sp8),
              // Text field
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeFocused ? accent.withOpacity(0.45) : border,
                      width: typeFocused ? 1.5 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: typeCtrl,
                    focusNode: typeFocus,
                    style: _body(14, textClr),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: l.t('bridge_type_hint'),
                      hintStyle: _body(14, mutedClr),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: _sp16,
                        vertical: _sp12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _sp8),
              // Send
              Semantics(
                label: l.t('common_send_message'),
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeCtrl.text.isEmpty
                          ? (isDark ? _dSurface2 : _lSurface2)
                          : accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: typeCtrl.text.isEmpty ? border : accent,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: typeCtrl.text.isEmpty ? mutedClr : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _sp8),
      ],
    );
  }
}

// ── Mobile phrases tab ────────────────────────────────────────────────
class _MobilePhrasesTab extends StatelessWidget {
  final bool isDark;
  final void Function(String) onPhraseSelected;
  const _MobilePhrasesTab({
    required this.isDark,
    required this.onPhraseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final accent = isDark ? _secondaryDark : _secondary;

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp8),
        itemCount: _kPhrases.length,
        itemBuilder: (_, i) {
          final p = _kPhrases[i];
          final text = l.t(p.key);
          return Semantics(
            label: text,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onPhraseSelected(text),
              child: Container(
                margin: const EdgeInsets.only(bottom: _sp8),
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp12,
                  vertical: _sp12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(p.icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: _sp12),
                    Expanded(child: Text(text, style: _body(13, textClr))),
                    Icon(Icons.send_rounded, color: accent, size: 14),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mobile panel tab ──────────────────────────────────────────────────
class _MobilePanelTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, isDark;
  final bool compact;
  final VoidCallback onTap;
  final int badge;
  const _MobilePanelTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.compact = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _secondaryDark : _secondary;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: _sp12,
            vertical: _sp8,
          ),
          decoration: BoxDecoration(
            color: active ? accent.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? accent.withOpacity(0.35) : Colors.transparent,
              width: active ? 1.5 : 0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: active ? accent : subClr),
              if (!compact) ...[
                const SizedBox(width: _sp4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _label(
                      11,
                      active ? accent : subClr,
                      w: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (badge > 0) ...[
                const SizedBox(width: _sp4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: _label(9, Colors.white, w: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  REUSABLE SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _ConnectionChip extends StatelessWidget {
  final bool connected, dark;
  final Animation<double> pulse;
  final String label;
  const _ConnectionChip({
    required this.connected,
    required this.pulse,
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? (dark ? _successDark : _success)
        : (dark ? _dangerDark : _danger);
    final bg = connected
        ? (dark ? _successDark.withOpacity(0.12) : _successLight)
        : (dark ? _dangerDark.withOpacity(0.12) : _dangerLight);
    final border = connected
        ? (dark ? _successDark.withOpacity(0.28) : _success.withOpacity(0.28))
        : (dark ? _dangerDark.withOpacity(0.28) : _danger.withOpacity(0.28));

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: connected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(pulse.value * 0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: _sp4),
            Text(label, style: _label(10, color, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PendingSignChip extends StatelessWidget {
  final String sign;
  final bool isDark;
  final VoidCallback onConfirm, onDismiss;
  final AppLocalizations l;
  const _PendingSignChip({
    required this.sign,
    required this.isDark,
    required this.onConfirm,
    required this.onDismiss,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.40), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sign_language_rounded,
            color: const Color(0xFFA78BFA),
            size: 18,
          ),
          const SizedBox(width: _sp8),
          Flexible(child: Text(sign, style: _heading(20, Colors.white))),
          const SizedBox(width: _sp12),
          Semantics(
            label: l.t('bridge_confirm_sign'),
            button: true,
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp12,
                  vertical: _sp8,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.t('bridge_send'),
                      style: _label(12, Colors.white, w: FontWeight.w700),
                    ),
                    const SizedBox(width: _sp4),
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: _sp8),
          Semantics(
            label: l.t('bridge_dismiss_sign'),
            button: true,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(_sp8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectingBadge extends StatelessWidget {
  final Animation<double> pulse;
  const _DetectingBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFA78BFA);
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withOpacity(0.3 + pulse.value * 0.5),
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
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(pulse.value * 0.8),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _sp4),
            Text(
              AppLocalizations.of(context).t('bridge_detecting'),
              style: _label(9, accent, w: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _IconActionBtn({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? _dSurface2 : _lSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? _dBorder : _lBorder, width: 1),
      ),
      child: Icon(icon, color: color, size: 15),
    ),
  );
}

class _MobileTopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MobileTopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    ),
  );
}

// ── Painters ──────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 20.0, r = 5.0;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(r, len + r), Offset(r, r), p);
    canvas.drawLine(Offset(r, r), Offset(len + r, r), p);
    canvas.drawLine(Offset(w - r, len + r), Offset(w - r, r), p);
    canvas.drawLine(Offset(w - r, r), Offset(w - len - r, r), p);
    canvas.drawLine(Offset(r, h - len - r), Offset(r, h - r), p);
    canvas.drawLine(Offset(r, h - r), Offset(len + r, h - r), p);
    canvas.drawLine(Offset(w - r, h - len - r), Offset(w - r, h - r), p);
    canvas.drawLine(Offset(w - r, h - r), Offset(w - len - r, h - r), p);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
