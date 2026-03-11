import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ─────────────────────────────────────────────
//  WEBSOCKET CONFIG
// ─────────────────────────────────────────────
// NOTE: On desktop (Windows/macOS/Linux) and the iOS simulator, use localhost.
// On Android emulators, 10.0.2.2 maps to the host machine.
// On web, we use the browser origin (and match ws/wss to http/https).

const _kDefaultWsPort = 8000;
const _kWsPath = '/ws';

String _getWebSocketUrl() {
  if (kIsWeb) {
    final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
    //final port = Uri.base.port != 0 ? Uri.base.port : _kDefaultWsPort;
    final port = _kDefaultWsPort;
    return '$scheme://$host:$port$_kWsPath';
  }

  // Non-web platforms (mobile/desktop)
  // Android emulator uses 10.0.2.2 to reach the host machine.
  // Other platforms typically use localhost.
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'ws://10.0.2.2:$_kDefaultWsPort$_kWsPath';
  }

  // iOS simulator, desktop
  return 'ws://127.0.0.1:$_kDefaultWsPort$_kWsPath';
}

// Inference rate (ms between frames sent to backend)
const _kFrameIntervalMs = 100; // ~10 fps  — tune as needed

// ─────────────────────────────────────────────
//  SESSION STATE ENUM
// ─────────────────────────────────────────────
enum _SessionState { idle, connecting, running, stopping, error }

class TranslateScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const TranslateScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with WidgetsBindingObserver {
  // ── Camera ──────────────────────────────────
  CameraController? _camCtrl;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;
  bool _isCameraReady = false;

  // ── WebSocket ────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  bool _wsConnected = false;

  // ── Session ──────────────────────────────────
  _SessionState _state = _SessionState.idle;
  String? _sessionError;

  // ── Inference State ──────────────────────────
  String _predictionLabel = '—';
  double _confidence = 0.0;
  int _frameCount = 0;

  // ── Translation State ────────────────────────
  String selectedLanguage = 'Hindi';
  String englishPrediction = '';
  String regionalPrediction = '';

  final Map<String, String> languageCodes = {
    'Hindi': 'hi',
    'Marathi': 'mr',
    'Gujarati': 'gu',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Kannada': 'kn',
    'Bengali': 'bn',
  };

  // ── Streaming throttle ───────────────────────
  Timer? _frameTimer;
  bool _isCapturing = false; // single-flight lock

  // ── Transcription ────────────────────────────
  final TextEditingController _textCtrl = TextEditingController();

  // ── Reconnect ────────────────────────────────
  int _reconnectAttempts = 0;
  static const _kMaxReconnect = 5;
  Timer? _reconnectTimer;

  // ───────Translation Helper──────────────────────────────────────
  Future<String> translateText(String text, String langCode) async {
    final url =
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$langCode&dt=t&q=${Uri.encodeComponent(text)}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0][0][0];
    }

    return text;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause streaming when app goes to background
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_state == _SessionState.running) _stopSession();
    }
  }

  // ─────────────────────────────────────────────
  //  CAMERA SETUP
  // ─────────────────────────────────────────────
  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('[VANI] Camera discovery error: $e');
    }
  }

  Future<bool> _initCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return false;
    try {
      _camCtrl = CameraController(
        _cameras![_camIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.jpeg,
      );
      await _camCtrl!.initialize();
      if (!mounted) return false;
      setState(() => _isCameraReady = true);
      return true;
    } catch (e) {
      debugPrint('[VANI] Camera init error: $e');
      return false;
    }
  }

  Future<void> _disposeCamera() async {
    _isCameraReady = false;
    final ctrl = _camCtrl;
    _camCtrl = null;
    try {
      if (!kIsWeb &&
          ctrl != null &&
          ctrl.value.isInitialized &&
          ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
      await ctrl?.dispose();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  //  WEBSOCKET LIFECYCLE
  // ─────────────────────────────────────────────
  Future<bool> _connectWebSocket() async {
    try {
      final url = _getWebSocketUrl();
      debugPrint('[VANI] Connecting to WebSocket: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Handshake — give server 3 s to acknowledge connection
      await _channel!.ready.timeout(const Duration(seconds: 3));

      _wsConnected = true;
      _reconnectAttempts = 0;

      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onError: _onWsError,
        onDone: _onWsDone,
        cancelOnError: false,
      );

      debugPrint('[VANI] WebSocket connected ✅');
      return true;
    } catch (e) {
      debugPrint('[VANI] WebSocket connect failed: $e');
      _wsConnected = false;
      return false;
    }
  }

  void _onWsMessage(dynamic raw) {
    if (!mounted) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'prediction';

      if (type == 'ping') {
        // server keepalive — pong back
        _channel?.sink.add('__PING__');
        return;
      }

      if (type == 'stopped') {
        // server ack'd our STOP signal
        return;
      }

      if (type == 'error') {
        final msg = data['message'] as String? ?? 'Unknown error';
        debugPrint('[VANI] Server error: $msg');
        if (mounted) {
          setState(() {
            _state = _SessionState.error;
            _sessionError = msg;
          });
        }
        return;
      }

      if (type == 'prediction') {
        final label = (data['label'] ?? '—').toString();
        final conf = (data['confidence'] ?? 0.0).toDouble();

        setState(() {
          _predictionLabel = label;
          englishPrediction = label;
          _confidence = conf;
          _frameCount = (data['frame'] ?? _frameCount);
        });

        // Translate detected gesture
        translateText(label, languageCodes[selectedLanguage]!).then((
          translated,
        ) {
          if (!mounted) return;

          setState(() {
            regionalPrediction = translated;
          });
        });
      }
    } catch (e) {
      debugPrint('[VANI] WS parse error: $e');
    }
  }

  void _onWsError(Object error) {
    debugPrint('[VANI] WS error: $error');
    _wsConnected = false;
    if (_state == _SessionState.running) {
      _attemptReconnect();
    }
  }

  void _onWsDone() {
    debugPrint('[VANI] WS closed');
    _wsConnected = false;
    if (_state == _SessionState.running) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _kMaxReconnect) {
      if (mounted) {
        setState(() {
          _state = _SessionState.error;
          _sessionError = 'Connection lost. Please restart.';
        });
      }
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint(
      '[VANI] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!mounted || _state != _SessionState.running) return;
      final ok = await _connectWebSocket();
      if (!ok) _attemptReconnect();
    });
  }

  Future<void> _closeWebSocket() async {
    _reconnectTimer?.cancel();
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      _channel?.sink.add('__STOP__');
      await Future.delayed(const Duration(milliseconds: 150));
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _wsConnected = false;
  }

  // ─────────────────────────────────────────────
  //  FRAME STREAMING
  // ─────────────────────────────────────────────
  void _startFrameTimer() {
    _frameTimer?.cancel();
    _isCapturing = false;

    _frameTimer = Timer.periodic(
      Duration(milliseconds: _kFrameIntervalMs),
      (_) => _captureAndSend(),
    );
  }

  Future<void> _captureAndSend() async {
    if (_isCapturing) return;
    if (!_wsConnected) return;
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;

    _isCapturing = true;
    try {
      final XFile file = await _camCtrl!.takePicture();
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      _channel!.sink.add(b64);
    } catch (e) {
      debugPrint('[VANI] Capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  void _stopFrameTimer() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _isCapturing = false;
  }

  // ─────────────────────────────────────────────
  //  SESSION CONTROL  (START / STOP)
  // ─────────────────────────────────────────────
  Future<void> _startSession() async {
    if (_state != _SessionState.idle && _state != _SessionState.error) return;

    setState(() {
      _state = _SessionState.connecting;
      _sessionError = null;
      _predictionLabel = '—';
      _confidence = 0.0;
      _frameCount = 0;
    });

    // 1. Camera
    final camOk = await _initCamera();
    if (!camOk) {
      setState(() {
        _state = _SessionState.error;
        _sessionError = 'Camera unavailable';
      });
      return;
    }

    // 2. WebSocket
    final wsOk = await _connectWebSocket();
    if (!wsOk) {
      await _disposeCamera();
      setState(() {
        _state = _SessionState.error;
        _sessionError =
            'Cannot connect to inference server.\nEnsure backend is running.';
      });
      return;
    }

    // 3. Start streaming
    _startFrameTimer();
    setState(() => _state = _SessionState.running);
    debugPrint('[VANI] Session started 🚀');
  }

  Future<void> _stopSession() async {
    if (_state == _SessionState.idle || _state == _SessionState.stopping)
      return;

    setState(() => _state = _SessionState.stopping);

    _stopFrameTimer();
    await _closeWebSocket();
    await _disposeCamera();

    if (!mounted) return;
    setState(() {
      _state = _SessionState.idle;
      _predictionLabel = '—';
      _confidence = 0.0;
      _isCameraReady = false;
    });
    debugPrint('[VANI] Session stopped ⏹');
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final wasRunning = _state == _SessionState.running;
    if (wasRunning) await _stopSession();
    _camIndex = (_camIndex + 1) % _cameras!.length;
    if (wasRunning) await _startSession();
  }

  void _appendToTranscript() {
    if (_predictionLabel == '—' ||
        _predictionLabel == 'No Sign' ||
        _predictionLabel.isEmpty)
      return;
    _textCtrl.text += '$_predictionLabel ';
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _textCtrl.text.length),
    );
  }

  // ─────────────────────────────────────────────
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSession();
    _textCtrl.dispose();
    super.dispose();
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InstructionDialog(),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLarge = MediaQuery.of(context).size.width > 900;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06060F)
          : const Color(0xFFF4F6FD),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _BlurGlow(
              color: primary.withOpacity(isDark ? 0.14 : 0.08),
              size: 450,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlobalNavbar(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                  activeRoute: 'translate',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: isLarge
                        ? _buildWebLayout(isDark, primary)
                        : _buildMobileLayout(isDark, primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(bool isDark, Color primary) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 7, child: _videoCaptureSection(isDark, primary)),
      const SizedBox(width: 28),
      Expanded(
        flex: 4,
        child: Column(
          children: [
            _currentDetectionSection(isDark, primary),
            const SizedBox(height: 22),
            _translationPanel(isDark, primary),
          ],
        ),
      ),
    ],
  );

  Widget _buildMobileLayout(bool isDark, Color primary) => Column(
    children: [
      _videoCaptureSection(isDark, primary),
      const SizedBox(height: 20),
      _currentDetectionSection(isDark, primary),
      const SizedBox(height: 20),
      _translationPanel(isDark, primary),
    ],
  );

  // ─────────────────────────────────────────────
  //  VIDEO CAPTURE SECTION
  // ─────────────────────────────────────────────
  Widget _videoCaptureSection(bool isDark, Color primary) {
    final l = AppLocalizations.of(context);
    final isRunning = _state == _SessionState.running;

    return _GlassContainer(
      isDark: isDark,
      primary: primary,
      child: Column(
        children: [
          _buildSectionHeader(
            isDark: isDark,
            primary: primary,
            icon: Icons.sensors_rounded,
            title: l.t('translate_vision_title'),
            subtitle: l.t('translate_vision_sub'),
          ),
          const SizedBox(height: 18),

          // ── Camera viewport ───────────────────
          Container(
            height: 440,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child:
                        isRunning &&
                            _camCtrl != null &&
                            _camCtrl!.value.isInitialized
                        ? CameraPreview(_camCtrl!)
                        : _buildCameraPlaceholder(isDark, primary),
                  ),
                  if (isRunning)
                    Positioned(top: 18, right: 18, child: _buildLiveBadge()),
                  if (_state == _SessionState.connecting)
                    _buildConnectingOverlay(primary),
                  if (_state == _SessionState.error) _buildErrorOverlay(isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Controls ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOutlineButton(
                onPressed: _switchCamera,
                icon: Icons.flip_camera_android_rounded,
                label: l.t('translate_switch'),
                primary: primary,
              ),
              const SizedBox(width: 18),
              _buildStartStopButton(isDark, primary, l),
            ],
          ),

          // ── Error message ────────────────────
          if (_state == _SessionState.error && _sessionError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sessionError!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder(bool isDark, Color primary) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
        ),
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white.withOpacity(0.2),
          size: 56,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'Press Start to begin detection',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _buildConnectingOverlay(Color primary) => Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting...',
            style: TextStyle(color: primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorOverlay(bool isDark) => Container(
    color: Colors.black.withOpacity(0.65),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Connection Error',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFEF4444).withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: Colors.white, size: 7),
        SizedBox(width: 7),
        Text(
          'LIVE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────
  //  DETECTION SECTION
  // ─────────────────────────────────────────────
  Widget _currentDetectionSection(bool isDark, Color primary) {
    final l = AppLocalizations.of(context);
    final isActive = _state == _SessionState.running;

    return _GlassContainer(
      isDark: isDark,
      primary: primary,
      gradient: LinearGradient(
        colors: [primary.withOpacity(0.08), Colors.transparent],
      ),
      child: Column(
        children: [
          Text(
            l.t('translate_prediction'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.grey,
              letterSpacing: 1.8,
            ),
          ),
          // ── Language dropdown ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Regional Language',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primary.withOpacity(0.25)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    dropdownColor: isDark
                        ? const Color(0xFF0D0D1F)
                        : Colors.white,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primary,
                      size: 18,
                    ),
                    items: languageCodes.keys
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedLanguage = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── English box ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? primary.withOpacity(0.3)
                    : primary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'EN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive ? _predictionLabel : l.t('translate_waiting'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Regional box ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF10B981).withOpacity(0.35)
                    : const Color(0xFF10B981).withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedLanguage.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive
                        ? (regionalPrediction.isNotEmpty
                              ? regionalPrediction
                              : '...')
                        : l.t('translate_waiting'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Confidence bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confidence',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isActive
                        ? '${(_confidence * 100).toStringAsFixed(0)}%'
                        : '—',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isActive ? _confidence : 0,
                  minHeight: 4,
                  backgroundColor: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _confidence > 0.75
                        ? Colors.green
                        : _confidence > 0.45
                        ? Colors.orange
                        : primary,
                  ),
                ),
              ),
              // Frame counter (debug info)
              if (isActive) ...[
                const SizedBox(height: 6),
                Text(
                  'Frames: $_frameCount',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white24 : Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TRANSLATION PANEL
  // ─────────────────────────────────────────────
  Widget _translationPanel(bool isDark, Color primary) {
    final l = AppLocalizations.of(context);
    return _GlassContainer(
      isDark: isDark,
      primary: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('translate_transcription'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.grey,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF4F6FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: TextField(
              controller: _textCtrl,
              maxLines: 4,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: l.t('translate_hint'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey[400],
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(18),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Append prediction to transcript
              Expanded(
                child: _buildGradientButton(
                  label: 'Append Sign',
                  icon: Icons.add_rounded,
                  primary: primary,
                  onPressed: _appendToTranscript,
                ),
              ),
              const SizedBox(width: 12),
              _buildIconAction(
                Icons.copy_outlined,
                primary.withOpacity(0.8),
                () {
                  // Copy transcript to clipboard
                },
              ),
              const SizedBox(width: 10),
              _buildIconAction(
                Icons.delete_outline_rounded,
                const Color(0xFFEF4444),
                _textCtrl.clear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  UI COMPONENTS
  // ─────────────────────────────────────────────
  Widget _buildStartStopButton(bool isDark, Color primary, AppLocalizations l) {
    final isRunning = _state == _SessionState.running;
    final isLoading =
        _state == _SessionState.connecting || _state == _SessionState.stopping;
    final isError = _state == _SessionState.error;

    final Color btnColor = isRunning
        ? const Color(0xFFEF4444)
        : isError
        ? const Color(0xFFF59E0B)
        : primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: btnColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: btnColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(btnColor),
              ),
            )
          else
            Icon(
              isRunning
                  ? Icons.stop_rounded
                  : isError
                  ? Icons.refresh_rounded
                  : Icons.play_arrow_rounded,
              color: btnColor,
              size: 18,
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading
                ? null
                : isRunning
                ? _stopSession
                : _startSession,
            child: Text(
              isLoading
                  ? (isRunning ? 'Stopping…' : 'Connecting…')
                  : isRunning
                  ? 'Stop'
                  : isError
                  ? 'Retry'
                  : 'Start',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: btnColor,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isDark,
    required Color primary,
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      const SizedBox(width: 14),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0A0A1F),
              letterSpacing: 0.2,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    ],
  );

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required Color primary,
    required VoidCallback onPressed,
  }) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, const Color(0xFF4F46E5)]),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: primary.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Widget _buildOutlineButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color primary,
  }) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: BorderSide(color: primary.withOpacity(0.5), width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) =>
      Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 18),
          padding: const EdgeInsets.all(14),
        ),
      );
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────
class _BlurGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurGlow({required this.color, this.size = 400});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
      child: Container(color: Colors.transparent),
    ),
  );
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color primary;
  final Gradient? gradient;

  const _GlassContainer({
    required this.child,
    required this.isDark,
    required this.primary,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(28),
          gradient: gradient,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class _InstructionDialog extends StatelessWidget {
  const _InstructionDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final l = AppLocalizations.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF0D0D1F)
            : Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sign_language_rounded,
                color: primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('dialog_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0A0A1F),
              ),
            ),
          ],
        ),
        content: Text(
          l.t('dialog_body'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey[600],
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, const Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Text(
                    l.t('dialog_btn'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
