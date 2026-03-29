// lib/screens/TwoWayScreen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────
//  WEBSOCKET CONFIG  (mirrors TranslateScreen exactly)
// ─────────────────────────────────────────────
// const _kDefaultWsPort  = 8000;
// const _kWsPath         = '/ws';
// const _kFrameIntervalMs = 100;

// String _getWebSocketUrl() {
//   if (kIsWeb) {
//     final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
//     final host   = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
//     return '$scheme://$host:$_kDefaultWsPort$_kWsPath';
//   }
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     return 'ws://10.0.2.2:$_kDefaultWsPort$_kWsPath';
//   }
//   return 'ws://127.0.0.1:$_kDefaultWsPort$_kWsPath';
// }

// Change this to your Railway domain
const String _kRailwayHost = 'isl-production-57d4.up.railway.app';
const String _kWsPath = '/ws';
const int _kFrameIntervalMs = 100;

String _getWebSocketUrl() {
  // Use wss (Secure) for all platforms in production.
  // Railway handles port mapping automatically, so we don't include :8000
  return 'wss://$_kRailwayHost$_kWsPath';
}

const double _kMinPredictionConfidence = 0.30;
const int _kStableDetectionMs = 450;
const int _kDetectionCooldownMs = 800;
const int _kSameLabelCooldownMs = 1800;

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _kObsidian    = Color(0xFF020205);
const _kSurface     = Color(0xFF0A0A12);
const _kSurfaceUp   = Color(0xFF0F0F1A);
const _kSurfaceHi   = Color(0xFF141428);
const _kBorder      = Color(0xFF1C1C2E);
const _kBorderBrt   = Color(0xFF252540);
const _kTextPri     = Color(0xFFF2F0FF);
const _kTextSec     = Color(0xFF6B6B8A);
const _kTextMuted   = Color(0xFF2E2E4A);
const _kViolet      = Color(0xFF7C3AED);
const _kVioletLight = Color(0xFFA78BFA);
const _kTeal        = Color(0xFF0891B2);
const _kTealLight   = Color(0xFF22D3EE);
const _kGreen       = Color(0xFF059669);
const _kGreenLight  = Color(0xFF34D399);
const _kCrimson     = Color(0xFFDC2626);

class _T {
  final bool d;
  const _T(this.d);
  Color get scaffold  => d ? _kObsidian            : const Color(0xFFF4F6FD);
  Color get surface   => d ? _kSurface             : Colors.white;
  Color get surfaceUp => d ? _kSurfaceUp           : const Color(0xFFF8F8FC);
  Color get surfaceHi => d ? _kSurfaceHi           : const Color(0xFFEEEEF8);
  Color get border    => d ? _kBorder              : const Color(0xFFE0E0EE);
  Color get borderBrt => d ? _kBorderBrt           : const Color(0xFFCCCCDD);
  Color get textPri   => d ? _kTextPri             : const Color(0xFF0A0A1F);
  Color get textSec   => d ? _kTextSec             : const Color(0xFF6A6A8A);
  Color get textMuted => d ? _kTextMuted           : const Color(0xFFAAAAAA);
  Color get gridLine  => d
      ? const Color(0xFF12122A).withOpacity(0.5)
      : const Color(0xFFE0E0F0).withOpacity(0.8);
}

// ─────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────
enum _Sender { deaf, hearing }

class _Message {
  final String  text;
  final _Sender sender;
  final DateTime time;
  final bool    isSign;
  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.isSign = false,
  });
}

// ─────────────────────────────────────────────
//  QUICK PHRASES
// ─────────────────────────────────────────────
const List<Map<String, String>> _kPhrases = [
  {'key': 'phrase_1',  'icon': '👋'},
  {'key': 'phrase_2',  'icon': '🪪'},
  {'key': 'phrase_3',  'icon': '⏳'},
  {'key': 'phrase_4',  'icon': '✅'},
  {'key': 'phrase_5',  'icon': '✏️'},
  {'key': 'phrase_6',  'icon': '🚶'},
  {'key': 'phrase_7',  'icon': '🆘'},
  {'key': 'phrase_8',  'icon': '🏥'},
  {'key': 'phrase_9',  'icon': '📅'},
  {'key': 'phrase_10', 'icon': '🪑'},
  {'key': 'phrase_11', 'icon': '🤝'},
  {'key': 'phrase_12', 'icon': '📞'},
];

// ══════════════════════════════════════════════
//  TWO WAY SCREEN
// ══════════════════════════════════════════════

class TwoWayScreen extends StatefulWidget {
  final VoidCallback       toggleTheme;
  final Function(Locale)   setLocale;
  const TwoWayScreen({super.key, required this.toggleTheme, required this.setLocale});

  @override
  State<TwoWayScreen> createState() => _TwoWayScreenState();
}

class _TwoWayScreenState extends State<TwoWayScreen> with TickerProviderStateMixin {

  // ── Camera ────────────────────────────────
  CameraController?       _cam;
  List<CameraDescription> _cameras = [];
  bool  _camReady  = false;
  bool  _camActive = true;
  int   _camIndex  = 0;

  // ── WebSocket ─────────────────────────────
  WebSocketChannel? _ws;
  bool              _wsConnected = false;
  Timer?            _frameTimer;
  // Reconnect state
  int               _reconnectAttempts = 0;
  Timer?            _reconnectTimer;
  static const int  _maxReconnectAttempts = 5;

  // ── Messages ──────────────────────────────
  final List<_Message>     _messages   = [];
  final ScrollController   _scroll     = ScrollController();

  // ── Hearing input ─────────────────────────
  final TextEditingController _typeCtrl  = TextEditingController();
  final FocusNode             _typeFocus = FocusNode();
  bool _typeFocused = false;

  // ── ISL detection ─────────────────────────
  String _detected  = '';   // current detected sign word
  String _pending   = '';   // latest detected sign waiting for manual send
  bool   _detecting = false;
  String _candidate = '';
  DateTime _candidateSince = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastAccepted = '';
  DateTime _lastAcceptedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Animations ────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
    // Defer WS connect to after first frame so URI.base is available on web
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWs());
    _typeFocus.addListener(() => setState(() => _typeFocused = _typeFocus.hasFocus));
    _typeCtrl.addListener(() => setState(() {})); // for send button colour
  }

  void _initAnimations() {
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  // ─────────────────────────────────────────
  //  CAMERA
  // ─────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _camIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_camIndex < 0) _camIndex = 0;
      await _startCamera(_camIndex);
    } catch (_) {}
  }

  Future<void> _startCamera(int idx) async {
    await _cam?.dispose();
    _cam = CameraController(_cameras[idx], ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    try {
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
      _startFrameStream();
    } catch (_) {}
  }

  void _startFrameStream() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(Duration(milliseconds: _kFrameIntervalMs), (_) async {
      if (!_camReady || !_camActive || !_wsConnected) return;
      if (_cam == null || !_cam!.value.isInitialized) return;
      try {
        final img   = await _cam!.takePicture();
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

  // ─────────────────────────────────────────
  //  WEBSOCKET — robust connect with retry
  // ─────────────────────────────────────────

  void _connectWs() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    try {
      final url = _getWebSocketUrl();
      _ws = WebSocketChannel.connect(Uri.parse(url));
      if (mounted) setState(() => _wsConnected = true);
      _reconnectAttempts = 0;

      _ws!.stream.listen(
        _onSignReceived,
        onError: (_) => _onWsDisconnected(),
        onDone:  ()  => _onWsDisconnected(),
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
      // Exponential back-off: 1s, 2s, 4s, 8s, 16s
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

      // Backend may send JSON payloads like {"type":"prediction","label":"HELLO","confidence":0.91}
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          final obj = jsonDecode(raw);
          if (obj is Map<String, dynamic>) {
            final type = (obj['type'] ?? 'prediction').toString();
            if (type != 'prediction') return null;
            final label = (obj['label'] ?? '').toString().trim();
            if (label.isEmpty) return null;
            final conf = (obj['confidence'] as num?)?.toDouble() ?? 1.0;
            return (sign: label.toUpperCase(), confidence: conf);
          }
        } catch (_) {}
      }

      // Fallback: plain label string payload.
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
      if (_detecting && mounted) {
        setState(() => _detecting = false);
      }
      return;
    }

    final now = DateTime.now();

    // Step 1: candidate must stay same for a minimum stability window.
    if (sign != _candidate) {
      _candidate = sign;
      _candidateSince = now;
      if (!_detecting && mounted) {
        setState(() => _detecting = true);
      }
      return;
    }

    if (now.difference(_candidateSince).inMilliseconds < _kStableDetectionMs) {
      return;
    }

    // Step 2: cooldown to avoid repeated frame-level spam.
    if (now.difference(_lastAcceptedAt).inMilliseconds < _kDetectionCooldownMs) {
      return;
    }

    if (sign == _lastAccepted &&
        now.difference(_lastAcceptedAt).inMilliseconds < _kSameLabelCooldownMs) {
      return;
    }

    if (sign == _pending) {
      return;
    }

    _lastAccepted = sign;
    _lastAcceptedAt = now;

    setState(() {
      _detected = sign;
      _pending = sign;
      _detecting = false;
    });
  }

  void _confirmSign() {
    if (_pending.trim().isEmpty) return;
    _addMessage(_pending.trim(), _Sender.deaf, isSign: true);
    setState(() { _pending = ''; _detected = ''; _detecting = false; });
    _candidate = '';
  }

  void _clearPending() {
    setState(() { _pending = ''; _detected = ''; _detecting = false; });
    _candidate = '';
  }

  // ─────────────────────────────────────────
  //  MESSAGES
  // ─────────────────────────────────────────

  void _sendHearing() {
    final text = _typeCtrl.text.trim();
    if (text.isEmpty) return;
    _typeCtrl.clear();
    _addMessage(text, _Sender.hearing);
    HapticFeedback.lightImpact();
  }

  void _addMessage(String text, _Sender sender, {bool isSign = false}) {
    setState(() {
      _messages.add(_Message(text: text, sender: sender, time: DateTime.now(), isSign: isSign));
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  void _clearChat() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final t = _T(Theme.of(context).brightness == Brightness.dark);
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l.t('bridge_clear_confirm_title'),
              style: TextStyle(color: t.textPri, fontWeight: FontWeight.w700)),
          content: Text(l.t('bridge_clear_confirm_body'),
              style: TextStyle(color: t.textSec, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(l.t('sos_cancel'), style: TextStyle(color: t.textSec))),
            TextButton(
              onPressed: () { Navigator.pop(ctx); setState(() => _messages.clear()); },
              child: Text(l.t('bridge_clear'), style: const TextStyle(color: _kCrimson)),
            ),
          ],
        );
      },
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
    super.dispose();
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final t         = _T(isDark);
    final size      = MediaQuery.of(context).size;
    final w         = size.width;
    final isDesktop = w > 1100;
    final isTablet  = w >= 700 && w <= 1100;
    final isMobile  = w < 700;

    return Scaffold(
      backgroundColor: isMobile ? Colors.black : t.scaffold,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        if (!isMobile) ...[
          Positioned.fill(child: CustomPaint(painter: _GridPainter(t: t))),
          Positioned(top: -140, left: w * 0.15,
              child: _Glow(color: _kViolet.withOpacity(isDark ? 0.07 : 0.025), size: 380)),
          Positioned(bottom: -100, right: -40,
              child: _Glow(color: _kTeal.withOpacity(isDark ? 0.07 : 0.025), size: 320)),
        ],
        SafeArea(
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: Column(children: [
                if (!isMobile)
                  GlobalNavbar(toggleTheme: widget.toggleTheme,
                      setLocale: widget.setLocale, activeRoute: 'bridge'),
                Expanded(
                  child: isDesktop
                      ? _desktopLayout(t, size)
                      : isTablet
                      ? _tabletLayout(t, size)
                      : _buildMobileShell(context, t, size, isDark),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────
  //  DESKTOP (side-by-side, 3 columns)
  // ─────────────────────────────────────────

  Widget _desktopLayout(_T t, Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Left — deaf panel
        Expanded(
          flex: 4,
          child: Column(children: [
            _deafHeader(t),
            const SizedBox(height: 10),
            Expanded(child: _cameraPanel(t)),
            const SizedBox(height: 10),
            _signStatus(t),
          ]),
        ),

        const SizedBox(width: 16),

        // Centre — thread
        Expanded(
          flex: 5,
          child: Column(children: [
            _threadHeader(t),
            const SizedBox(height: 10),
            Expanded(child: _messageThread(t)),
            const SizedBox(height: 10),
            _hearingInput(t),
          ]),
        ),

        const SizedBox(width: 16),

        // Right — phrases (scrollable so it never overflows)
        SizedBox(
          width: 192,
          child: _phrasesColumn(t),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────
  //  TABLET (2 columns: camera left, thread right)
  // ─────────────────────────────────────────

  Widget _tabletLayout(_T t, Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Left — deaf panel
        Expanded(
          flex: 5,
          child: Column(children: [
            _deafHeader(t),
            const SizedBox(height: 10),
            Expanded(child: _cameraPanel(t)),
            const SizedBox(height: 10),
            _signStatus(t),
          ]),
        ),
        const SizedBox(width: 14),
        // Right — thread + input
        Expanded(
          flex: 6,
          child: Column(children: [
            _threadHeader(t),
            const SizedBox(height: 10),
            Expanded(child: _messageThread(t)),
            const SizedBox(height: 10),
            _hearingInput(t),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────
  //  MOBILE SHELL — fullscreen camera + bottom panel
  // ─────────────────────────────────────────

  Widget _buildMobileShell(BuildContext ctx, _T t, Size size, bool isDark) {
    final l = AppLocalizations.of(ctx);
    return Stack(fit: StackFit.expand, children: [

      // Camera fills screen
      if (_camReady && _camActive && _cam != null)
        CameraPreview(_cam!)
      else
        _mobileCamBg(t),

      // Corner brackets
      Positioned.fill(child: CustomPaint(
          painter: _CornerPainter(color: _kViolet.withOpacity(
              _camActive && _camReady ? 0.6 : 0.22)))),

      // Top bar
      Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(bottom: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(children: [
                    _FloatBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(ctx)),
                    const SizedBox(width: 10),
                    AnimatedBuilder(animation: _pulse, builder: (_, __) =>
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.48),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: (_wsConnected ? _kGreenLight : _kCrimson)
                                    .withOpacity(0.42))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 5, height: 5, decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _wsConnected ? _kGreenLight : _kCrimson,
                                  boxShadow: [BoxShadow(
                                      color: (_wsConnected ? _kGreenLight : _kCrimson)
                                          .withOpacity(_pulse.value * 0.7),
                                      blurRadius: 5)])),
                              const SizedBox(width: 6),
                                Text(_wsConnected ? l.t('bridge_isl_live') : l.t('common_connecting'),
                                  style: TextStyle(
                                      color: _wsConnected ? _kGreenLight : _kCrimson,
                                      fontSize: 10, fontWeight: FontWeight.w700)),
                            ]))),
                    const Spacer(),
                    _FloatBtn(
                        icon: _camActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        onTap: _toggleCamera),
                    if (_cameras.length > 1) ...[
                      const SizedBox(width: 8),
                      _FloatBtn(icon: Icons.flip_camera_ios_rounded, onTap: _flipCamera),
                    ],
                  ])))),

      // Pending sign overlay
      if (_pending.isNotEmpty && _camActive)
        Positioned(top: 72, left: 0, right: 0,
            child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text(_pending, style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10),
                  GestureDetector(onTap: _confirmSign,
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(color: _kViolet, borderRadius: BorderRadius.circular(8)),
                            child: Text(l.t('bridge_send'), style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 6),
                  GestureDetector(onTap: _clearPending,
                      child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 13))),
                ])))),

      // Detecting badge
      if (_detecting && _camActive)
        Positioned(top: 72, left: 14,
            child: AnimatedBuilder(animation: _pulse, builder: (_, __) =>
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kVioletLight.withOpacity(0.3 + _pulse.value * 0.5))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(
                          shape: BoxShape.circle, color: _kVioletLight,
                          boxShadow: [BoxShadow(
                              color: _kVioletLight.withOpacity(_pulse.value * 0.8), blurRadius: 7)])),
                      const SizedBox(width: 5),
                        Text(l.t('bridge_detecting'), style: const TextStyle(
                          color: _kVioletLight, fontSize: 9, fontWeight: FontWeight.w700)),
                    ])))),

      // Bottom frosted panel
      Positioned(bottom: 0, left: 0, right: 0,
          child: _MobileBridgePanel(
            t: t, isDark: isDark,
            messages: _messages,
            pending: _pending,
            typeCtrl: _typeCtrl,
            typeFocus: _typeFocus,
            typeFocused: _typeFocused,
            onSendHearing: _sendHearing,
            onConfirmSign: _confirmSign,
            onClearPending: _clearPending,
            onClearChat: _clearChat,
            onPhraseSelected: (p) => _addMessage(p, _Sender.hearing),
            scrollCtrl: _scroll,
            pulse: _pulse,
          )),
    ]);
  }

    Widget _mobileCamBg(_T t) {
    final l = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF06060F),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kViolet.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: _kViolet.withOpacity(0.18))),
          child: const Icon(Icons.sign_language_rounded, color: _kVioletLight, size: 34)),
        const SizedBox(height: 14),
        Text(l.t('bridge_camera_init'),
          style: TextStyle(color: Colors.white38, fontSize: 13)),
      ])));
    }

  // ─────────────────────────────────────────
  //  DEAF PANEL HEADER
  // ─────────────────────────────────────────

  Widget _deafHeader(_T t) {
    final l = AppLocalizations.of(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _kViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kViolet.withOpacity(0.2)),
        ),
        child: const Icon(Icons.sign_language_rounded, color: _kVioletLight, size: 15),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('bridge_deaf_label'),
              style: TextStyle(color: t.textPri, fontSize: 12, fontWeight: FontWeight.w700)),
          Text(l.t('bridge_deaf_sublabel'), style: TextStyle(color: t.textSec, fontSize: 10)),
        ]),
      ),

      // Connection dot
      AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: (_wsConnected ? _kGreen : _kCrimson).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (_wsConnected ? _kGreen : _kCrimson).withOpacity(0.22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _wsConnected ? _kGreenLight : _kCrimson,
                boxShadow: [BoxShadow(
                  color: (_wsConnected ? _kGreenLight : _kCrimson)
                      .withOpacity(_pulse.value * 0.7),
                  blurRadius: 5,
                )],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _wsConnected
                  ? l.t('bridge_isl_live')
                  : (_reconnectAttempts < _maxReconnectAttempts ? l.t('common_connecting') : l.t('bridge_offline')),
              style: TextStyle(
                color: _wsConnected ? _kGreenLight : _kCrimson,
                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4,
              ),
            ),
          ]),
        ),
      ),

      const SizedBox(width: 6),
      _Btn(
        icon: _camActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
        color: _camActive ? _kVioletLight : t.textMuted,
        onTap: _toggleCamera,
        tooltip: _camActive ? l.t('bridge_pause_camera') : l.t('bridge_resume_camera'),
        t: t,
      ),
      if (_cameras.length > 1) ...[
        const SizedBox(width: 4),
        _Btn(
          icon: Icons.flip_camera_ios_rounded,
          color: t.textSec,
          onTap: _flipCamera,
          tooltip: l.t('bridge_flip_camera'),
          t: t,
        ),
      ],
    ]);
  }

  // ─────────────────────────────────────────
  //  CAMERA PANEL
  // ─────────────────────────────────────────

  Widget _cameraPanel(_T t) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceUp,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kViolet.withOpacity(0.2)),
        ),
        child: Stack(fit: StackFit.expand, children: [

          if (_camReady && _camActive && _cam != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: CameraPreview(_cam!),
            )
          else
            _cameraPlaceholder(t),

          // Corner brackets
          Positioned.fill(child: CustomPaint(
              painter: _CornerPainter(color: _kViolet.withOpacity(0.55)))),

          // Detecting badge
          if (_detecting && _camActive)
            Positioned(
              top: 10, left: 10,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kVioletLight.withOpacity(0.4 + _pulse.value * 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kVioletLight,
                        boxShadow: [BoxShadow(
                          color: _kVioletLight.withOpacity(_pulse.value * 0.8),
                          blurRadius: 7,
                        )],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(l.t('bridge_detecting'),
                        style: TextStyle(color: _kVioletLight, fontSize: 9,
                            fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  ]),
                ),
              ),
            ),

          // Pending sign overlay
          if (_pending.isNotEmpty && _camActive)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.82), Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _pending,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w800, letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _confirmSign,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kViolet,
                        borderRadius: BorderRadius.circular(8),
                      ),
                        child: Text(l.t('bridge_send'),
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _clearPending,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ]),
              ),
            ),

          // Camera off overlay
          if (!_camActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.videocam_off_rounded, color: t.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text(l.t('bridge_camera_paused'),
                      style: TextStyle(color: t.textSec, fontSize: 12)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _cameraPlaceholder(_T t) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceHi,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kViolet.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: _kViolet.withOpacity(0.18)),
          ),
          child: const Icon(Icons.sign_language_rounded, color: _kVioletLight, size: 30),
        ),
        const SizedBox(height: 12),
        Text(l.t('bridge_camera_init'), style: TextStyle(color: t.textSec, fontSize: 12)),
        const SizedBox(height: 4),
        Text(l.t('bridge_camera_hint'),
            style: TextStyle(color: t.textMuted, fontSize: 10)),
      ]),
    );
  }

  // ─────────────────────────────────────────
  //  SIGN STATUS BAR
  // ─────────────────────────────────────────

  Widget _signStatus(_T t) {
    final l = AppLocalizations.of(context);
    final hasPending = _pending.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: hasPending
            ? _kViolet.withOpacity(t.d ? 0.1 : 0.06)
            : t.surfaceUp,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: hasPending ? _kViolet.withOpacity(0.3) : t.border),
      ),
      child: Row(children: [
        Icon(
          hasPending ? Icons.record_voice_over_rounded : Icons.front_hand_rounded,
          color: hasPending ? _kVioletLight : t.textMuted,
          size: 16,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            hasPending
                ? _pending
                : (_wsConnected
                ? l.t('bridge_waiting_sign')
                : l.t('bridge_connect_backend')),
            style: TextStyle(
              color: hasPending ? _kVioletLight : t.textSec,
              fontSize: hasPending ? 13 : 11,
              fontWeight: hasPending ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        if (hasPending) ...[
          GestureDetector(
            onTap: _confirmSign,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _kViolet,
                borderRadius: BorderRadius.circular(7),
              ),
                child: Text('${l.t('bridge_send')} ->',
                  style: TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _clearPending,
            child: Icon(Icons.clear_rounded, color: t.textMuted, size: 14),
          ),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────
  //  THREAD HEADER
  // ─────────────────────────────────────────

  Widget _threadHeader(_T t) {
    final l = AppLocalizations.of(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _kTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kTeal.withOpacity(0.2)),
        ),
        child: const Icon(Icons.forum_rounded, color: _kTealLight, size: 15),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('bridge_convo_title'),
              style: TextStyle(color: t.textPri, fontSize: 12, fontWeight: FontWeight.w700)),
            Text((_messages.length == 1 ? l.t('bridge_messages') : l.t('bridge_messages_plural'))
              .replaceAll('{n}', '${_messages.length}'),
              style: TextStyle(color: t.textSec, fontSize: 10)),
        ]),
      ),
      if (_messages.isNotEmpty)
        _Btn(
          icon: Icons.delete_sweep_rounded,
          color: t.textSec,
          onTap: _clearChat,
          tooltip: l.t('bridge_clear_convo'),
          t: t,
        ),
    ]);
  }

  // ─────────────────────────────────────────
  //  MESSAGE THREAD
  // ─────────────────────────────────────────

  Widget _messageThread(_T t) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceUp,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: _messages.isEmpty
          ? _emptyThread(t)
          : ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          itemCount: _messages.length,
          itemBuilder: (_, i) => _bubble(_messages[i], t, i),
        ),
      ),
    );
  }

  Widget _emptyThread(_T t) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surfaceHi,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, color: t.textMuted, size: 26),
          ),
          const SizedBox(height: 12),
          Text(l.t('bridge_empty_title'),
              style: TextStyle(color: t.textSec, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            l.t('bridge_empty_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.55),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(_Message msg, _T t, int i) {
    final l = AppLocalizations.of(context);
    final isDeaf     = msg.sender == _Sender.deaf;
    final bubbleCol  = isDeaf
        ? _kViolet.withOpacity(t.d ? 0.16 : 0.09)
        : _kTeal.withOpacity(t.d ? 0.13 : 0.07);
    final borderCol  = isDeaf
        ? _kViolet.withOpacity(0.25)
        : _kTeal.withOpacity(0.22);
    final accentCol  = isDeaf ? _kVioletLight : _kTealLight;
    final timeStr    = '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';
    final showLabel  = i == 0 || _messages[i - 1].sender != msg.sender;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 5,
        left:  isDeaf ? 0 : 28,
        right: isDeaf ? 28 : 0,
      ),
      child: Column(
        crossAxisAlignment: isDeaf ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 2, right: 2),
              child: Text(
                isDeaf ? l.t('bridge_deaf_label') : l.t('bridge_hearing_label'),
                style: TextStyle(
                  color: accentCol.withOpacity(0.6),
                  fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bubbleCol,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(14),
                topRight:    const Radius.circular(14),
                bottomLeft:  Radius.circular(isDeaf ? 3 : 14),
                bottomRight: Radius.circular(isDeaf ? 14 : 3),
              ),
              border: Border.all(color: borderCol),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (msg.isSign)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kViolet.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(l.t('bridge_isl_sign_badge'),
                        style: TextStyle(color: _kVioletLight,
                            fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              Text(msg.text,
                  style: TextStyle(color: t.textPri, fontSize: 13,
                      fontWeight: FontWeight.w500, height: 1.4)),
              const SizedBox(height: 3),
              Text(timeStr,
                  style: TextStyle(color: accentCol.withOpacity(0.45), fontSize: 8)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  HEARING PERSON INPUT  (redesigned)
  // ─────────────────────────────────────────

  Widget _hearingInput(_T t) {
    final l = AppLocalizations.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [

      // Role label
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kTeal.withOpacity(0.2)),
          ),
          child: const Icon(Icons.keyboard_rounded, color: _kTealLight, size: 13),
        ),
        const SizedBox(width: 8),
        Text(l.t('bridge_hearing_sublabel'),
            style: TextStyle(color: t.textSec, fontSize: 10, fontWeight: FontWeight.w600)),
        const Spacer(),
        // Quick phrase sheet trigger
        GestureDetector(
          onTap: () => _showPhraseSheet(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kTeal.withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome_rounded, color: _kTealLight, size: 11),
              const SizedBox(width: 4),
                Text(l.t('bridge_quick_phrases'),
                  style: TextStyle(color: _kTealLight, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),

      const SizedBox(height: 8),

      // Input row
      Row(children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: t.surfaceHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _typeFocused ? _kTeal.withOpacity(0.45) : t.borderBrt,
                width: _typeFocused ? 1.5 : 1.0,
              ),
              boxShadow: _typeFocused
                  ? [BoxShadow(color: _kTeal.withOpacity(0.08), blurRadius: 12)]
                  : [],
            ),
            child: TextField(
              controller:     _typeCtrl,
              focusNode:      _typeFocus,
              style:          TextStyle(color: t.textPri, fontSize: 13),
              maxLines:       3,
              minLines:       1,
              textInputAction: TextInputAction.send,
              onSubmitted:    (_) => _sendHearing(),
              decoration: InputDecoration(
                hintText:  l.t('bridge_type_hint'),
                hintStyle: TextStyle(color: t.textMuted, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send button
        GestureDetector(
          onTap: _sendHearing,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _typeCtrl.text.isEmpty ? t.surfaceHi : _kTeal,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: _typeCtrl.text.isEmpty ? t.borderBrt : _kTeal),
              boxShadow: _typeCtrl.text.isEmpty
                  ? []
                  : [BoxShadow(
                  color: _kTeal.withOpacity(0.3),
                  blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Icon(
                Icons.send_rounded,
                color: _typeCtrl.text.isEmpty ? t.textMuted : Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ─────────────────────────────────────────
  //  PHRASES — desktop right column
  // ─────────────────────────────────────────

  Widget _phrasesColumn(_T t) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: _kTealLight, size: 13),
          const SizedBox(width: 5),
            Text(l.t('bridge_quick_phrases'),
              style: TextStyle(color: t.textSec, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        // Use ListView inside Expanded so it scrolls and never overflows
        Expanded(
          child: ListView.builder(
            itemCount: _kPhrases.length,
            itemBuilder: (_, i) {
              final p = _kPhrases[i];
              return GestureDetector(
                onTap: () => _addMessage(l.t(p['key']!), _Sender.hearing),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.surfaceUp,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(children: [
                    Text(p['icon']!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(l.t(p['key']!),
                          style: TextStyle(color: t.textSec, fontSize: 10, height: 1.4)),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  PHRASES — mobile bottom sheet
  // ─────────────────────────────────────────

  void _showPhraseSheet(_T t) {
    final l = AppLocalizations.of(context);
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
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 34, height: 4,
                decoration: BoxDecoration(
                  color: t.borderBrt,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: _kTealLight, size: 15),
                const SizedBox(width: 8),
                Text(l.t('bridge_quick_phrases'),
                    style: TextStyle(color: t.textPri, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(l.t('bridge_tap_to_send'),
                  style: TextStyle(color: t.textSec, fontSize: 11)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _kPhrases.length,
                itemBuilder: (_, i) {
                  final p = _kPhrases[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addMessage(l.t(p['key']!), _Sender.hearing);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: t.surfaceUp,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(children: [
                        Text(p['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(l.t(p['key']!),
                              style: TextStyle(color: t.textPri,
                                  fontSize: 13, height: 1.4)),
                        ),
                        Icon(Icons.send_rounded, color: _kTealLight, size: 14),
                      ]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 16),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE: FLOATING ICON BUTTON (top-bar overlay)
// ─────────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FloatBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.14))),
          child: Icon(icon, color: Colors.white, size: 19)));
}

// ─────────────────────────────────────────────
//  MOBILE: BRIDGE BOTTOM PANEL
//  Frosted glass panel with 2 tabs:
//    Tab 0 — Chat thread + hearing input
//    Tab 1 — Quick phrases
// ─────────────────────────────────────────────
class _MobileBridgePanel extends StatefulWidget {
  final _T t;
  final bool isDark;
  final List<_Message> messages;
  final String pending;
  final TextEditingController typeCtrl;
  final FocusNode typeFocus;
  final bool typeFocused;
  final VoidCallback onSendHearing, onConfirmSign, onClearPending, onClearChat;
  final void Function(String) onPhraseSelected;
  final ScrollController scrollCtrl;
  final Animation<double> pulse;

  const _MobileBridgePanel({
    required this.t, required this.isDark,
    required this.messages, required this.pending,
    required this.typeCtrl, required this.typeFocus,
    required this.typeFocused,
    required this.onSendHearing, required this.onConfirmSign,
    required this.onClearPending, required this.onClearChat,
    required this.onPhraseSelected, required this.scrollCtrl,
    required this.pulse,
  });

  @override
  State<_MobileBridgePanel> createState() => _MobileBridgePanelState();
}

class _MobileBridgePanelState extends State<_MobileBridgePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.t;
    final d = widget.isDark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
              color: d
                  ? const Color(0xFF07080F).withOpacity(0.93)
                  : Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: t.border, width: 0.8))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Drag handle
            Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: d ? Colors.white.withOpacity(0.17) : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2)))),

            // Tab row
            Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Row(children: [
                  _BridgePanelTab(
                      label: l.t('bridge_convo_title'), icon: Icons.forum_rounded,
                      active: _tab == 0, isDark: d,
                      badge: widget.messages.length,
                      onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: 8),
                  _BridgePanelTab(
                      label: l.t('bridge_quick_phrases'), icon: Icons.auto_awesome_rounded,
                      active: _tab == 1, isDark: d,
                      onTap: () => setState(() => _tab = 1)),
                  if (_tab == 0 && widget.messages.isNotEmpty) ...[
                    const Spacer(),
                    GestureDetector(
                        onTap: widget.onClearChat,
                        child: Icon(Icons.delete_sweep_rounded, color: t.textMuted, size: 17)),
                  ],
                ])),

            // Tab content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == 0
                  ? _ChatTab(widget: widget, d: d, t: t)
                  : _PhrasesTab(widget: widget, d: d, t: t),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 6),
          ]),
        ),
      ),
    );
  }
}

class _BridgePanelTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, isDark;
  final VoidCallback onTap;
  final int badge;
  const _BridgePanelTab({required this.label, required this.icon,
    required this.active, required this.isDark, required this.onTap,
    this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: active ? _kTeal.withOpacity(isDark ? 0.15 : 0.09) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active
                  ? _kTeal.withOpacity(0.38)
                  : Colors.transparent)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: active ? _kTealLight : (isDark ? _kTextSec : const Color(0xFF6A6A8A))),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
                color: active ? _kTealLight : (isDark ? _kTextSec : const Color(0xFF6A6A8A)),
                fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: _kTeal, shape: BoxShape.circle),
                  child: Center(child: Text('$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
            ],
          ])));
}

class _ChatTab extends StatelessWidget {
  final _MobileBridgePanel widget;
  final bool d;
  final _T t;
  const _ChatTab({required this.widget, required this.d, required this.t});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Message thread (fixed height)
      SizedBox(
        height: 200,
        child: widget.messages.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forum_outlined, color: t.textMuted, size: 22),
          const SizedBox(height: 6),
            Text(l.t('bridge_empty_sub'),
              style: TextStyle(color: t.textSec, fontSize: 11)),
        ]))
            : ListView.builder(
            controller: widget.scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: widget.messages.length,
            itemBuilder: (_, i) {
              final msg = widget.messages[i];
              final isDeaf = msg.sender == _Sender.deaf;
              final bubbleCol = isDeaf
                  ? _kViolet.withOpacity(d ? 0.16 : 0.09)
                  : _kTeal.withOpacity(d ? 0.13 : 0.07);
              final borderCol = isDeaf
                  ? _kViolet.withOpacity(0.25) : _kTeal.withOpacity(0.22);
              final accentCol = isDeaf ? _kVioletLight : _kTealLight;
              final timeStr = '${msg.time.hour.toString().padLeft(2,'0')}:${msg.time.minute.toString().padLeft(2,'0')}';

              return Padding(
                  padding: EdgeInsets.only(
                      bottom: 6,
                      left: isDeaf ? 0 : 24,
                      right: isDeaf ? 24 : 0),
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                          color: bubbleCol,
                          borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isDeaf ? 3 : 12),
                              bottomRight: Radius.circular(isDeaf ? 12 : 3)),
                          border: Border.all(color: borderCol)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (msg.isSign)
                          Container(
                              margin: const EdgeInsets.only(bottom: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _kViolet.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(3)),
                                child: Text(l.t('bridge_isl_sign_badge'), style: const TextStyle(
                                  color: _kVioletLight, fontSize: 7, fontWeight: FontWeight.w800))),
                        Text(msg.text, style: TextStyle(
                            color: t.textPri, fontSize: 13,
                            fontWeight: FontWeight.w500, height: 1.4)),
                        const SizedBox(height: 2),
                        Text(timeStr, style: TextStyle(
                            color: accentCol.withOpacity(0.45), fontSize: 8)),
                      ])));
            }),
      ),

      const SizedBox(height: 8),

      // Hearing input
      Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Row(children: [
            Expanded(
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                        color: t.surfaceHi,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: widget.typeFocused ? _kTeal.withOpacity(0.45) : t.borderBrt,
                            width: widget.typeFocused ? 1.5 : 1.0)),
                    child: TextField(
                        controller: widget.typeCtrl,
                        focusNode: widget.typeFocus,
                        style: TextStyle(color: t.textPri, fontSize: 13),
                        maxLines: 2, minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.onSendHearing(),
                        decoration: InputDecoration(
                            hintText: l.t('bridge_type_hint'),
                            hintStyle: TextStyle(color: t.textMuted, fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: InputBorder.none)))),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: widget.onSendHearing,
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: widget.typeCtrl.text.isEmpty ? t.surfaceHi : _kTeal,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: widget.typeCtrl.text.isEmpty ? [] : [BoxShadow(
                            color: _kTeal.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Icon(Icons.send_rounded,
                        color: widget.typeCtrl.text.isEmpty ? t.textMuted : Colors.white,
                        size: 17))),
          ])),
      const SizedBox(height: 8),
    ]);
  }
}

class _PhrasesTab extends StatelessWidget {
  final _MobileBridgePanel widget;
  final bool d;
  final _T t;
  const _PhrasesTab({required this.widget, required this.d, required this.t});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
        height: 280,
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            itemCount: _kPhrases.length,
            itemBuilder: (_, i) {
              final p = _kPhrases[i];
              return GestureDetector(
                  onTap: () => widget.onPhraseSelected(l.t(p['key']!)),
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                          color: t.surfaceUp,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border)),
                      child: Row(children: [
                        Text(p['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.t(p['key']!),
                            style: TextStyle(color: t.textPri, fontSize: 12.5,
                                fontWeight: FontWeight.w600, height: 1.35))),
                        Icon(Icons.arrow_forward_ios_rounded, color: t.textMuted, size: 10),
                      ])));
            }));
  }
}

// ─────────────────────────────────────────────
//  SMALL REUSABLE BUTTON
// ─────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final IconData   icon;
  final Color      color;
  final VoidCallback onTap;
  final String     tooltip;
  final _T         t;
  const _Btn({required this.icon, required this.color,
    required this.onTap, required this.tooltip, required this.t});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: t.surfaceHi,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: t.border),
        ),
        child: Center(child: Icon(icon, color: color, size: 15)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: const SizedBox.expand(),
    ),
  );
}

class _GridPainter extends CustomPainter {
  final _T t;
  const _GridPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = t.gridLine..strokeWidth = 0.5;
    const step = 52.0;
    for (double x = 0; x < size.width;  x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override
  bool shouldRepaint(_GridPainter old) => old.t.d != t.d;
}

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
    const len = 20.0;
    const r   = 5.0;
    final w = size.width, h = size.height;
    // TL
    canvas.drawLine(Offset(r, len + r), Offset(r, r), p);
    canvas.drawLine(Offset(r, r), Offset(len + r, r), p);
    // TR
    canvas.drawLine(Offset(w - r, len + r), Offset(w - r, r), p);
    canvas.drawLine(Offset(w - r, r), Offset(w - len - r, r), p);
    // BL
    canvas.drawLine(Offset(r, h - len - r), Offset(r, h - r), p);
    canvas.drawLine(Offset(r, h - r), Offset(len + r, h - r), p);
    // BR
    canvas.drawLine(Offset(w - r, h - len - r), Offset(w - r, h - r), p);
    canvas.drawLine(Offset(w - r, h - r), Offset(w - len - r, h - r), p);
  }
  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}