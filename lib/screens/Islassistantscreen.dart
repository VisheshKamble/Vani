// lib/screens/ISLAssistantScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — ISL Assistant Screen  · UX4G Redesign                     ║
// ║  Font: Noto Sans (UX4G standard, full Devanagari coverage)        ║
// ║  Powered by: Gemini 2.0 Flash API                                 ║
// ║                                                                    ║
// ║  UX4G Principles Applied:                                         ║
// ║  • Chat bubbles: user = primary-blue, AI = neutral surface        ║
// ║  • Input bar: solid border (no frosted glass)                     ║
// ║  • Language strip: clearly labelled, accessible toggle            ║
// ║  • ISL sign chips: teal color (secondary) — distinct from AI      ║
// ║  • Quick prompts: info-blue tint, icon + label                    ║
// ║  • TTS toggle: on/off state uses success/muted colors             ║
// ║  • Error state: danger red with icon prefix                       ║
// ║  • Mic listening state: pulsing danger indicator (urgent action)  ║
// ║  • All touch targets ≥ 44dp                                       ║
// ║  • Semantics() on all interactive elements                        ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────────────
//  UX4G DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Noto Sans';

// Brand
const _primary       = Color(0xFF1A56DB);
const _primaryDark   = Color(0xFF4A8EFF);
const _primaryLight  = Color(0xFFE8F0FE);

// Secondary (teal — ISL sign chips)
const _secondary     = Color(0xFF00796B);
const _secondaryDark = Color(0xFF26A69A);
const _secondaryLight = Color(0xFFE0F2F1);

// Assistant accent (purple — consistent with HomeScreen)
const _purple        = Color(0xFF6200EA);
const _purpleDark    = Color(0xFF9C6BFF);
const _purpleSurface = Color(0xFFF3E5F5);
const _purpleSurfD   = Color(0xFF2A1047);

// Status
const _danger        = Color(0xFFB71C1C);
const _dangerDark    = Color(0xFFEF5350);
const _dangerLight   = Color(0xFFFFEBEE);
const _success       = Color(0xFF1B7340);
const _successDark   = Color(0xFF27AE60);
const _info          = Color(0xFF0D47A1);
const _infoDark      = Color(0xFF42A5F5);
const _infoLight     = Color(0xFFE3F2FD);

// Neutral surfaces
const _lBg           = Color(0xFFF5F7FA);
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

// Spacing
const _sp4  = 4.0;
const _sp8  = 8.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;

// ── Type helpers ──────────────────────────────────────────────────────
TextStyle _display(double size, Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: size, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: -0.5);

TextStyle _heading(double size, Color c, {FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.3, letterSpacing: -0.2);

TextStyle _body(double size, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.6);

TextStyle _label(double size, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.4, letterSpacing: 0.1);

// ─────────────────────────────────────────────────────────────────────
//  GEMINI CONFIG
// ─────────────────────────────────────────────────────────────────────
const String _geminiKey = String.fromEnvironment(
    'GEMINI_API_KEY', defaultValue: '');
const _kModel = 'gemini-2.5-flash';
const bool _geminiBackendEnabled = true;
String get _kUrl =>
    'https://generativelanguage.googleapis.com/v1beta/models/'
        '$_kModel:generateContent?key=$_geminiKey';

// ─────────────────────────────────────────────────────────────────────
//  ISL SYSTEM PROMPT
// ─────────────────────────────────────────────────────────────────────
const _kSystemPrompt = r'''
You are VANI, an AI assistant specialised in Indian Sign Language (ISL)
and accessibility for India's deaf and mute community.

YOUR CORE PURPOSE:
This app (VANI) uses on-device AI to translate ISL signs to text in real-time.
You are the conversational assistant inside that app. Help users:
1. LEARN ISL — explain any ISL sign clearly with step-by-step instructions
2. GUIDE HANDSHAPES — describe: handshape → palm orientation → location → movement → NMM
3. ANSWER ISL QUESTIONS — grammar, structure, regional variants, ISLRTC resources
4. EMERGENCY PHRASES — highlight life-saving signs clearly
5. RIGHTS & RESOURCES — Indian disability rights, RCI, ISLRTC, schemes

ISL SIGN GUIDE FORMAT (always use when explaining a sign):
When a user asks "how to sign X" or "what is the ISL sign for X", always respond with:
• Sign name in CAPS: e.g. HELP, WATER, DOCTOR
• Step 1 — Handshape: (describe fingers, fist, etc.)
• Step 2 — Location: (near face, chest, neutral space, etc.)
• Step 3 — Movement: (direction, path, repetition)
• Step 4 — Palm orientation: (facing you, away, down, etc.)
• Step 5 — Facial expression / NMM: (any required expression)
• Memory tip: a short memorable tip

ISL FACTS TO EMBED:
• ISL has Subject-Object-Verb (SOV) word order
• ISL is NOT derived from ASL or BSL — it is India's own language
• Over 63 million deaf/mute people in India; ~8.4 million ISL users
• Only ~250 certified ISL interpreters in India
• ISLRTC (Indian Sign Language Research & Training Centre) is the authority
• RCI certifies interpreters and educators

MULTILINGUAL BEHAVIOUR:
• Detect the language of the user's message automatically
• If the user writes in Hindi — respond fully in Hindi (हिंदी)
• If the user writes in Marathi — respond fully in Marathi (मराठी)
• Hinglish is fine and natural
• For sign descriptions, always include the English sign name in CAPS even in Hindi/Marathi responses

TONE:
• Warm, patient, encouraging — users face daily communication barriers
• Keep responses concise. Avoid walls of text.
• Use bullet points and numbered steps for clarity
• Celebrate learning — a simple "Great question!" or "बिल्कुल!" works well
''';

// ─────────────────────────────────────────────────────────────────────
//  QUICK PROMPTS
// ─────────────────────────────────────────────────────────────────────
const _kQuickPromptKeys = [
  ('isl_quick_1', Icons.waving_hand_rounded),
  ('isl_quick_2', Icons.front_hand_rounded),
  ('isl_quick_3', Icons.water_drop_rounded),
  ('isl_quick_4', Icons.medical_services_rounded),
  ('isl_quick_5', Icons.emergency_rounded),
  ('isl_quick_6', Icons.menu_book_rounded),
  ('isl_quick_7', Icons.volunteer_activism_rounded),
  ('isl_quick_8', Icons.gavel_rounded),
];

// ─────────────────────────────────────────────────────────────────────
//  LANGUAGES
// ─────────────────────────────────────────────────────────────────────
const _kLangs = [
  ('en', 'EN', '🇬🇧', 'en_IN', 'en-IN'),
  ('hi', 'हि', '🇮🇳', 'hi_IN', 'hi-IN'),
  ('mr', 'म',  '🇮🇳', 'mr_IN', 'mr-IN'),
];

// ─────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────
enum _Role { user, assistant }
enum _MsgStatus { sent, error }

class _Msg {
  final String id;
  final _Role  role;
  String       text;
  _MsgStatus   status;
  final DateTime time;
  List<String> islTags;
  _Msg({required this.id, required this.role, required this.text,
    this.status = _MsgStatus.sent, this.islTags = const [], DateTime? time})
      : time = time ?? DateTime.now();
}

// ══════════════════════════════════════════════════════════════════════
//  ISL ASSISTANT SCREEN
// ══════════════════════════════════════════════════════════════════════
class ISLAssistantScreen extends StatefulWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  const ISLAssistantScreen({super.key,
    required this.toggleTheme, required this.setLocale});
  @override
  State<ISLAssistantScreen> createState() => _ISLAssistantScreenState();
}

class _ISLAssistantScreenState extends State<ISLAssistantScreen>
    with TickerProviderStateMixin {

  final List<_Msg>           _msgs       = [];
  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();

  bool   _isLoading   = false;
  bool   _isListening = false;
  bool   _ttsEnabled  = true;
  String _lang        = 'en';

  final FlutterTts        _tts    = FlutterTts();
  final stt.SpeechToText  _speech = stt.SpeechToText();
  bool                    _speechOk = false;

  late AnimationController _typingCtrl;
  late Animation<double>   _typingAnim;
  bool _didSeedWelcome = false;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _typingAnim = CurvedAnimation(
        parent: _typingCtrl, curve: Curves.easeInOut);
    _initTts();
    _initSpeech();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedWelcome) return;
    _didSeedWelcome = true;
    _addAiMsg(AppLocalizations.of(context).t('isl_welcome_msg'));
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.44);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  Future<void> _initSpeech() async {
    _speechOk = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
      }
    });
  }

  List<String> _extractIslTags(String text) {
    final re = RegExp(r'\b[A-Z]{2,}(?:[_\s][A-Z]+)*\b');
    const skip = {'ISL','AI','VANI','IN','OF','TO','THE','AND','FOR',
      'OR','IS','ARE','BY','WITH','FROM','ON','AT','A','NMM','SOV'};
    return re.allMatches(text)
        .map((m) => m.group(0)!)
        .where((s) => !skip.contains(s))
        .toSet().toList();
  }

  void _addAiMsg(String text) {
    final tags = _extractIslTags(text);
    setState(() {
      _msgs.add(_Msg(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: _Role.assistant, text: text, islTags: tags));
    });
    _scrollToBottom();
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _isLoading) return;
    _inputCtrl.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _msgs.add(_Msg(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: _Role.user, text: t));
      _isLoading = true;
    });
    _scrollToBottom();
    try {
      final reply = await _callGemini(t);
      setState(() => _isLoading = false);
      _addAiMsg(reply);
      if (_ttsEnabled) {
        await _syncTtsLang();
        await _tts.speak(_cleanForTts(reply));
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _msgs.add(_Msg(
            id: '${DateTime.now().millisecondsSinceEpoch}',
            role: _Role.assistant,
            text: AppLocalizations.of(context).t('isl_connect_error'),
            status: _MsgStatus.error));
      });
      _scrollToBottom();
    }
  }

  Future<String> _callGemini(String userText) async {
    if (!_geminiBackendEnabled) {
      return 'ISL Assistant backend is temporarily disabled.';
    }
    if (_geminiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }
    final history = _msgs.take(20).map((m) => {
      'role': m.role == _Role.user ? 'user' : 'model',
      'parts': [{'text': m.text}],
    }).toList();

    final langSuffix = _lang == 'hi'
        ? ' (Please respond in Hindi — हिंदी में उत्तर दें)'
        : _lang == 'mr'
        ? ' (Please respond in Marathi — मराठीत उत्तर द्या)'
        : '';

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _kSystemPrompt}],
      },
      'contents': [
        ...history,
        {
          'role': 'user',
          'parts': [{'text': userText + langSuffix}],
        },
      ],
      'generationConfig': {
        'temperature': 0.70, 'maxOutputTokens': 700, 'topP': 0.90,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    });

    final resp = await http.post(Uri.parse(_kUrl),
        headers: {'Content-Type': 'application/json'},
        body: body).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) throw Exception('API ${resp.statusCode}');
    final json  = jsonDecode(resp.body) as Map<String, dynamic>;
    final parts = (json['candidates'] as List?)?.first['content']['parts']
    as List?;
    return parts?.first['text']?.toString()
        ?? AppLocalizations.of(context).t('isl_no_response');
  }

  Future<void> _toggleVoice() async {
    if (!_speechOk) return;
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      final locale = _kLangs.firstWhere((l) => l.$1 == _lang).$4;
      await _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            _inputCtrl.text = r.recognizedWords;
            setState(() => _isListening = false);
          }
        },
        localeId: locale,
        listenMode: stt.ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _syncTtsLang() async {
    final ttsLang = _kLangs.firstWhere((l) => l.$1 == _lang).$5;
    await _tts.setLanguage(ttsLang);
  }

  String _cleanForTts(String text) => text
      .replaceAll(RegExp(r'\*+'), '')
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAll(RegExp(r'`+'), '')
      .replaceAll(RegExp(r'\n+'), ' ')
      .trim();

  void _clearChat() {
    _tts.stop();
    setState(() {
      _msgs.clear();
      _addAiMsg(AppLocalizations.of(context).t('isl_chat_cleared'));
    });
  }

  String _askMoreSignPrompt(String sign) =>
      AppLocalizations.of(context)
          .t('isl_ask_more_sign')
          .replaceAll('{sign}', sign);

  // ════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w      = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l      = AppLocalizations.of(ctx);
    final bg     = isDark ? _dBg     : _lBg;
    final navBg  = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder  : _lBorder;
    final textClr = isDark ? _dText  : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _purpleDark : _purple;
    final navBlue = isDark ? _infoDark   : _info;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [

          // ── Top nav bar ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
                color: navBg,
                border: Border(bottom: BorderSide(color: border, width: 1.0))),
            padding: const EdgeInsets.fromLTRB(
                _sp8, _sp12, _sp12, _sp12),
            child: Row(children: [
              // Back
              Semantics(
                label: l.t('common_back'), button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pop(ctx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _sp8, vertical: _sp8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chevron_left_rounded, color: navBlue, size: 22),
                      Text(l.t('common_back'),
                          style: _body(15, navBlue, w: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
              const Spacer(),
              // Avatar + Title
              Column(children: [
                Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sign_language_rounded,
                        color: Colors.white, size: 18)),
                Text(l.t('assistant_title'),
                    style: _label(11, textClr, w: FontWeight.w600)),
              ]),
              const Spacer(),
              // TTS toggle
              Semantics(
                label: _ttsEnabled ? 'Mute voice output' : 'Unmute voice output',
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _ttsEnabled = !_ttsEnabled);
                    if (!_ttsEnabled) _tts.stop();
                  },
                  child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: _ttsEnabled
                              ? accent.withOpacity(0.10)
                              : (isDark ? _dSurface2 : _lSurface2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _ttsEnabled
                                  ? accent.withOpacity(0.25) : border,
                              width: 1)),
                      child: Icon(
                          _ttsEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          size: 18,
                          color: _ttsEnabled ? accent : subClr)),
                ),
              ),
              const SizedBox(width: _sp8),
              // Options
              _OptionsMenuButton(isDark: isDark, onClear: _clearChat),
            ]),
          ),

          // ── Language strip ───────────────────────────────────────────
          _LangStrip(selected: _lang, isDark: isDark,
              onSelect: (l) => setState(() => _lang = l)),

          // ── Messages ─────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: _msgs.isEmpty
                  ? _EmptyState(isDark: isDark,
                  onPrompt: _send)
                  : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      _sp12, _sp12, _sp12, _sp8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _msgs.length + (_isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _msgs.length) {
                      return _TypingIndicator(
                          isDark: isDark, anim: _typingAnim);
                    }
                    return _MsgBubble(
                      msg: _msgs[i], isDark: isDark,
                      onTapSign: (s) => _send(_askMoreSignPrompt(s)),
                      onSpeak: (text) async {
                        await _syncTtsLang();
                        await _tts.speak(_cleanForTts(text));
                      },
                    );
                  }),
            ),
          ),

          // ── Quick prompts (show when chat is empty) ──────────────────
          if (_msgs.length <= 1)
            _QuickPromptsRow(isDark: isDark, onTap: _send),

          // ── Input bar ────────────────────────────────────────────────
          _InputBar(
            controller:  _inputCtrl, isDark: isDark,
            isLoading:   _isLoading, isListening: _isListening,
            speechOk:    _speechOk,
            onSend:      _send, onVoice: _toggleVoice,
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  WEB / DESKTOP
  // ════════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final bg        = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          GlobalNavbar(toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale, activeRoute: 'assistant'),
          Expanded(child: isDesktop
              ? _webDesktopLayout(ctx, isDark)
              : _webTabletLayout(ctx, isDark)),
        ]),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) => Row(children: [
    _WebSidebar(
      isDark: isDark, selectedLang: _lang, ttsEnabled: _ttsEnabled,
      onLangSelect: (l) => setState(() => _lang = l),
      onTtsToggle:  () {
        setState(() => _ttsEnabled = !_ttsEnabled);
        if (!_ttsEnabled) _tts.stop();
      },
      onClearChat:   _clearChat,
      onQuickPrompt: _send,
    ),
    Expanded(child: _WebChatPane(
      msgs: _msgs, isDark: isDark,
      isLoading: _isLoading, typingAnim: _typingAnim,
      scrollCtrl: _scrollCtrl, inputCtrl: _inputCtrl,
      isListening: _isListening, speechOk: _speechOk,
      onSend: _send, onVoice: _toggleVoice,
      onTapSign: (s) => _send(_askMoreSignPrompt(s)),
      onSpeak: (text) async {
        await _syncTtsLang();
        await _tts.speak(_cleanForTts(text));
      },
    )),
  ]);

  Widget _webTabletLayout(BuildContext ctx, bool isDark) => Column(children: [
    _WebTopBar(
      isDark: isDark, selectedLang: _lang, ttsEnabled: _ttsEnabled,
      onLangSelect: (l) => setState(() => _lang = l),
      onTtsToggle: () {
        setState(() => _ttsEnabled = !_ttsEnabled);
        if (!_ttsEnabled) _tts.stop();
      },
      onClearChat: _clearChat,
    ),
    Expanded(child: _WebChatPane(
      msgs: _msgs, isDark: isDark,
      isLoading: _isLoading, typingAnim: _typingAnim,
      scrollCtrl: _scrollCtrl, inputCtrl: _inputCtrl,
      isListening: _isListening, speechOk: _speechOk,
      onSend: _send, onVoice: _toggleVoice,
      onTapSign: (s) => _send(_askMoreSignPrompt(s)),
      onSpeak: (text) async {
        await _syncTtsLang();
        await _tts.speak(_cleanForTts(text));
      },
    )),
  ]);
}

// ══════════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
//  UX4G: user = solid primary bg; AI = neutral surface bg
//  Error state = danger border + danger text
// ══════════════════════════════════════════════════════════════════════
class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final bool isDark;
  final void Function(String) onTapSign;
  final void Function(String) onSpeak;
  const _MsgBubble({required this.msg, required this.isDark,
    required this.onTapSign, required this.onSpeak});

  bool get _isUser => msg.role == _Role.user;

  @override
  Widget build(BuildContext context) {
    final accent    = isDark ? _purpleDark : _purple;
    final userBg    = isDark ? _primaryDark : _primary;
    final aiBg      = isDark ? _dSurface2   : _lSurface;
    final aiBorder  = isDark ? _dBorder     : _lBorder;
    final textClr   = isDark ? _dText       : _lText;
    final timeClr   = isDark ? _dTextMuted  : _lTextMuted;
    final isError   = msg.status == _MsgStatus.error;

    // ISL sign chip color — secondary teal (distinct from purple AI accent)
    final signAccent = isDark ? _secondaryDark : _secondary;

    return Semantics(
      label: '${_isUser ? 'You' : 'Assistant'}: ${msg.text}',
      child: Padding(
        padding: EdgeInsets.only(
            bottom: _sp4,
            left:  _isUser ? 56 : 0,
            right: _isUser ? 0 : 56),
        child: Column(
          crossAxisAlignment:
          _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // AI header row
            if (!_isUser)
              Padding(
                padding: const EdgeInsets.only(
                    bottom: _sp4, left: _sp4),
                child: Row(children: [
                  Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.sign_language_rounded,
                          color: Colors.white, size: 13)),
                  const SizedBox(width: _sp8),
                  Text(AppLocalizations.of(context).t('assistant_title'),
                      style: _label(11, isDark ? _dTextSub : _lTextSub,
                          w: FontWeight.w600)),
                ]),
              ),

            // Bubble — long-press to speak
            Semantics(
              label: 'Long press to speak aloud',
              child: GestureDetector(
                onLongPress: () => onSpeak(msg.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _sp16, vertical: _sp12),
                  decoration: BoxDecoration(
                      color: isError
                          ? (isDark
                          ? _dangerDark.withOpacity(0.12)
                          : _dangerLight)
                          : (_isUser ? userBg : aiBg),
                      borderRadius: BorderRadius.only(
                        topLeft:     const Radius.circular(16),
                        topRight:    const Radius.circular(16),
                        bottomLeft:  Radius.circular(_isUser ? 16 : 4),
                        bottomRight: Radius.circular(_isUser ? 4  : 16),
                      ),
                      border: isError
                          ? Border.all(
                          color: (isDark
                              ? _dangerDark
                              : _danger).withOpacity(0.35),
                          width: 1)
                          : (!_isUser
                          ? Border.all(color: aiBorder, width: 1)
                          : null)),
                  child: Text(msg.text,
                      style: _body(15,
                          isError
                              ? (isDark ? _dangerDark : _danger)
                              : (_isUser ? Colors.white : textClr))),
                ),
              ),
            ),

            // ISL sign chips (teal — secondary color = tactile/visual actions)
            if (!_isUser && msg.islTags.isNotEmpty) ...[
              const SizedBox(height: _sp8),
              Wrap(spacing: _sp8, runSpacing: _sp8,
                  children: msg.islTags.take(5).map((sign) =>
                      Semantics(
                        label: 'Learn sign: $sign', button: true,
                        child: GestureDetector(
                          onTap: () => onTapSign(sign),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _sp12, vertical: _sp4),
                            decoration: BoxDecoration(
                                color: signAccent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: signAccent.withOpacity(0.28),
                                    width: 1)),
                            child: Row(mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.front_hand_rounded,
                                      size: 12, color: signAccent),
                                  const SizedBox(width: _sp4),
                                  Text(sign, style: _label(11, signAccent,
                                      w: FontWeight.w700)),
                                ]),
                          ),
                        ),
                      )).toList()),
            ],

            // Timestamp
            const SizedBox(height: _sp4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sp4),
              child: Text(_fmtTime(msg.time),
                  style: _label(10, timeClr, w: FontWeight.w400)),
            ),
            const SizedBox(height: _sp8),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════════════
//  TYPING INDICATOR
// ══════════════════════════════════════════════════════════════════════
class _TypingIndicator extends StatelessWidget {
  final bool isDark;
  final Animation<double> anim;
  const _TypingIndicator({required this.isDark, required this.anim});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purpleDark : _purple;
    final bg     = isDark ? _dSurface2  : _lSurface;
    final border = isDark ? _dBorder    : _lBorder;

    return Semantics(
      label: 'Assistant is typing',
      child: Padding(
        padding: const EdgeInsets.only(bottom: _sp12),
        child: Row(children: [
          Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.sign_language_rounded,
                  color: Colors.white, size: 13)),
          const SizedBox(width: _sp8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: _sp16, vertical: _sp12),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(16),
                  topRight:    Radius.circular(16),
                  bottomLeft:  Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: border, width: 1)),
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) => Row(
                  children: List.generate(3, (i) {
                    final phase = ((anim.value + i * 0.28) % 1.0);
                    final scale = 0.6 + 0.4 * (phase < 0.5
                        ? phase * 2 : (1 - phase) * 2);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? _sp4 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(
                                    0.35 + 0.65 * scale))),
                      ),
                    );
                  })),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  INPUT BAR
//  UX4G: solid surface bar (no blur); mic in danger-red when active;
//  send button greyed when empty
// ══════════════════════════════════════════════════════════════════════
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark, isLoading, isListening, speechOk;
  final void Function(String) onSend;
  final VoidCallback onVoice;
  const _InputBar({
    required this.controller, required this.isDark,
    required this.isLoading, required this.isListening,
    required this.speechOk, required this.onSend, required this.onVoice,
  });
  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final ht = widget.controller.text.isNotEmpty;
      if (ht != _hasText) setState(() => _hasText = ht);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = widget.isDark ? _dSurface  : _lSurface;
    final border = widget.isDark ? _dBorder   : _lBorder;
    final fill   = widget.isDark ? _dSurface2 : _lSurface2;
    final subClr  = widget.isDark ? _dTextSub : _lTextSub;
    final textClr = widget.isDark ? _dText    : _lText;
    final hintClr = widget.isDark ? _dTextMuted : _lTextMuted;
    final accent  = widget.isDark ? _purpleDark : _purple;

    // Mic state: listening = danger (active/urgent), idle = neutral
    final micColor = widget.isListening
        ? (widget.isDark ? _dangerDark : _danger)
        : subClr;
    final micBg = widget.isListening
        ? (widget.isDark
        ? _dangerDark.withOpacity(0.15)
        : _dangerLight)
        : fill;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 1.0))),
      padding: const EdgeInsets.fromLTRB(
          _sp12, _sp8, _sp12, _sp8),
      child: Row(children: [
        // Mic button
        if (widget.speechOk)
          Semantics(
            label: widget.isListening ? 'Stop recording' : 'Start voice input',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onVoice,
              child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: micBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: widget.isListening
                              ? micColor.withOpacity(0.30)
                              : border,
                          width: widget.isListening ? 1.5 : 1.0)),
                  child: Icon(
                      widget.isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      size: 18, color: micColor)),
            ),
          ),

        const SizedBox(width: _sp8),

        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border, width: 1.0)),
            child: TextField(
              controller: widget.controller,
              maxLines:   null,
              enabled:    !widget.isLoading,
              textInputAction: TextInputAction.newline,
              style: _body(15, textClr),
              decoration: InputDecoration(
                hintText: widget.isListening
                    ? l.t('isl_input_listening')
                    : l.t('isl_input_hint'),
                hintStyle: _body(15, hintClr),
                border:          InputBorder.none,
                contentPadding:  const EdgeInsets.symmetric(
                    horizontal: _sp16, vertical: _sp12),
              ),
              onSubmitted: (v) {
                if (!widget.isLoading) widget.onSend(v);
              },
            ),
          ),
        ),

        const SizedBox(width: _sp8),

        // Send / loading
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: widget.isLoading
              ? SizedBox(
              key: const ValueKey('loading'),
              width: 40, height: 40,
              child: Padding(padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: accent)))
              : Semantics(
            key: const ValueKey('send'),
            label: 'Send message', button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => widget.onSend(widget.controller.text),
              child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _hasText ? accent : (widget.isDark
                          ? _dSurface2 : _lSurface2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _hasText
                              ? accent.withOpacity(0.0)
                              : border,
                          width: 1.0)),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 18,
                      color: _hasText
                          ? Colors.white
                          : (widget.isDark ? _dTextMuted : _lTextMuted))),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  QUICK PROMPTS ROW
// ══════════════════════════════════════════════════════════════════════
class _QuickPromptsRow extends StatelessWidget {
  final bool isDark;
  final void Function(String) onTap;
  const _QuickPromptsRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys
        .map((q) => (l.t(q.$1), q.$2)).toList();
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final accent  = isDark ? _infoDark : _info;

    return Container(
      height: 52,
      decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 1.0))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: _sp12, vertical: _sp8),
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        itemBuilder: (_, i) {
          final q = prompts[i];
          return Padding(
            padding: const EdgeInsets.only(right: _sp8),
            child: Semantics(
              label: q.$1, button: true,
              child: GestureDetector(
                onTap: () => onTap(q.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _sp12, vertical: _sp8),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: accent.withOpacity(0.22), width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(q.$2, size: 13, color: accent),
                    const SizedBox(width: _sp4),
                    Text(q.$1, style: _label(12, accent),
                        maxLines: 1),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  LANGUAGE STRIP (mobile)
// ══════════════════════════════════════════════════════════════════════
class _LangStrip extends StatelessWidget {
  final String selected;
  final bool isDark;
  final void Function(String) onSelect;
  const _LangStrip({required this.selected, required this.isDark,
    required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final accent = isDark ? _purpleDark : _purple;
    final bg     = isDark ? _dSurface   : _lSurface;
    final border = isDark ? _dBorder    : _lBorder;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;

    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border, width: 1.0))),
      padding: const EdgeInsets.symmetric(horizontal: _sp12),
      child: Row(children: [
        Text(l.t('isl_lang_label'),
            style: _label(11, mutedClr, w: FontWeight.w600)),
        const SizedBox(width: _sp8),
        ..._kLangs.map((lang) {
          final active = lang.$1 == selected;
          return Semantics(
            label: lang.$2, selected: active, button: true,
            child: GestureDetector(
              onTap: () => onSelect(lang.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: _sp8),
                padding: const EdgeInsets.symmetric(
                    horizontal: _sp12, vertical: _sp4),
                decoration: BoxDecoration(
                    color: active
                        ? accent.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: active
                            ? accent.withOpacity(0.30)
                            : Colors.transparent,
                        width: active ? 1.5 : 0)),
                child: Text('${lang.$3} ${lang.$2}',
                    style: _label(11.5,
                        active ? accent : subClr,
                        w: active ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          );
        }),
        const Spacer(),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB SIDEBAR
// ══════════════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final bool isDark, ttsEnabled;
  final String selectedLang;
  final void Function(String) onLangSelect;
  final VoidCallback onTtsToggle, onClearChat;
  final void Function(String) onQuickPrompt;
  const _WebSidebar({
    required this.isDark, required this.ttsEnabled,
    required this.selectedLang, required this.onLangSelect,
    required this.onTtsToggle, required this.onClearChat,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys
        .map((q) => (l.t(q.$1), q.$2)).toList();
    final bg      = isDark ? _dSurface  : _lSurface;
    final border  = isDark ? _dBorder   : _lBorder;
    final sep     = isDark ? _dBorderSub : _lBorderSub;
    final textClr = isDark ? _dText     : _lText;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final accent  = isDark ? _purpleDark : _purple;

    return Container(
      width: 280,
      decoration: BoxDecoration(
          color: bg,
          border: Border(right: BorderSide(color: border, width: 1.0))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(_sp20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.sign_language_rounded,
                            color: Colors.white, size: 24)),
                    const SizedBox(height: _sp12),
                    Text(l.t('assistant_title'),
                        style: _heading(18, textClr)),
                    Text(l.t('isl_sidebar_ai_tagline'),
                        style: _body(12, subClr)),
                  ]),
            ),

            Divider(height: 1, thickness: 1, color: sep),

            // Language section
            Padding(padding: const EdgeInsets.fromLTRB(
                _sp16, _sp16, _sp16, _sp8),
                child: Text(l.t('isl_sidebar_language'),
                    style: _label(10.5, mutedClr, w: FontWeight.w700))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sp12),
              child: Column(children: _kLangs.map((lang) {
                final active = lang.$1 == selectedLang;
                return Semantics(
                  selected: active, button: true,
                  label: lang.$2,
                  child: GestureDetector(
                    onTap: () => onLangSelect(lang.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      margin: const EdgeInsets.only(bottom: _sp4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: _sp12, vertical: _sp8),
                      decoration: BoxDecoration(
                          color: active
                              ? accent.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: active
                                  ? accent.withOpacity(0.25)
                                  : Colors.transparent,
                              width: active ? 1.5 : 0)),
                      child: Row(children: [
                        Text('${lang.$3}  ${lang.$2}',
                            style: _label(13.5,
                                active ? accent : subClr,
                                w: active
                                    ? FontWeight.w700 : FontWeight.w400)),
                        const Spacer(),
                        if (active)
                          Icon(Icons.check_rounded, color: accent, size: 14),
                      ]),
                    ),
                  ),
                );
              }).toList()),
            ),

            Divider(height: 1, thickness: 1, color: sep,
                indent: _sp16, endIndent: _sp16),

            // Settings
            Padding(padding: const EdgeInsets.fromLTRB(
                _sp16, _sp16, _sp16, _sp8),
                child: Text(l.t('isl_sidebar_settings'),
                    style: _label(10.5, mutedClr, w: FontWeight.w700))),
            _SidebarToggle(
                icon: ttsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: l.t('isl_sidebar_read_aloud'),
                value: ttsEnabled, isDark: isDark, accent: accent,
                onTap: onTtsToggle),

            Divider(height: 1, thickness: 1, color: sep,
                indent: _sp16, endIndent: _sp16),

            // Quick prompts
            Padding(padding: const EdgeInsets.fromLTRB(
                _sp16, _sp16, _sp16, _sp8),
                child: Text(l.t('isl_sidebar_quick_prompts'),
                    style: _label(10.5, mutedClr, w: FontWeight.w700))),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: _sp12),
              physics: const BouncingScrollPhysics(),
              itemCount: prompts.length,
              itemBuilder: (_, i) {
                final q = prompts[i];
                return _SidebarPromptBtn(
                    icon: q.$2, label: q.$1, isDark: isDark,
                    accent: isDark ? _infoDark : _info,
                    onTap: () => onQuickPrompt(q.$1));
              },
            )),

            Divider(height: 1, thickness: 1, color: sep),
            // Clear chat
            Semantics(
              label: 'Clear conversation', button: true,
              child: InkWell(
                onTap: onClearChat,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _sp24, vertical: _sp16),
                  child: Row(children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: isDark ? _dangerDark : _danger, size: 16),
                    const SizedBox(width: _sp12),
                    Text(l.t('isl_sidebar_clear_conversation'),
                        style: _body(13,
                            isDark ? _dangerDark : _danger,
                            w: FontWeight.w500)),
                  ]),
                ),
              ),
            ),
          ]),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value, isDark;
  final Color accent;
  final VoidCallback onTap;
  const _SidebarToggle({required this.icon, required this.label,
    required this.value, required this.isDark, required this.accent,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subClr = isDark ? _dTextSub : _lTextSub;
    return Semantics(
      toggled: value, button: true, label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              _sp24, _sp8, _sp24, _sp8),
          child: Row(children: [
            Icon(icon,
                color: value ? accent : subClr, size: 16),
            const SizedBox(width: _sp12),
            Expanded(child: Text(label, style: _body(13, subClr))),
            // UX4G toggle: solid track, white thumb
            Container(
              width: 40, height: 22,
              decoration: BoxDecoration(
                  color: value ? accent
                      : (isDark ? _dSurface2 : _lSurface2),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: value
                          ? accent.withOpacity(0.0)
                          : (isDark ? _dBorder : _lBorder),
                      width: 1)),
              child: AnimatedAlign(
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                duration: const Duration(milliseconds: 150),
                child: Container(
                    width: 18, height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarPromptBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  const _SidebarPromptBtn({required this.icon, required this.label,
    required this.isDark, required this.accent, required this.onTap});
  @override
  State<_SidebarPromptBtn> createState() => _SidebarPromptBtnState();
}

class _SidebarPromptBtnState extends State<_SidebarPromptBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true, label: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(bottom: _sp4),
            padding: const EdgeInsets.symmetric(
                horizontal: _sp12, vertical: _sp8),
            decoration: BoxDecoration(
                color: _hovered
                    ? widget.accent.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(widget.icon, size: 13, color: widget.accent),
              const SizedBox(width: _sp8),
              Expanded(child: Text(widget.label,
                  style: _body(12, subClr),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB CHAT PANE
// ══════════════════════════════════════════════════════════════════════
class _WebChatPane extends StatelessWidget {
  final List<_Msg> msgs;
  final bool isDark, isLoading, isListening, speechOk;
  final Animation<double> typingAnim;
  final ScrollController scrollCtrl;
  final TextEditingController inputCtrl;
  final void Function(String) onSend, onTapSign, onSpeak;
  final VoidCallback onVoice;
  const _WebChatPane({
    required this.msgs, required this.isDark,
    required this.isLoading, required this.isListening,
    required this.speechOk, required this.typingAnim,
    required this.scrollCtrl, required this.inputCtrl,
    required this.onSend, required this.onVoice,
    required this.onTapSign, required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(
      child: msgs.isEmpty
          ? _EmptyState(isDark: isDark, onPrompt: onSend)
          : ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(
              _sp24, _sp20, _sp24, _sp12),
          physics: const BouncingScrollPhysics(),
          itemCount: msgs.length + (isLoading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == msgs.length) {
              return _TypingIndicator(
                  isDark: isDark, anim: typingAnim);
            }
            return _MsgBubble(
                msg: msgs[i], isDark: isDark,
                onTapSign: onTapSign, onSpeak: onSpeak);
          }),
    ),
    _InputBar(
      controller: inputCtrl, isDark: isDark,
      isLoading: isLoading, isListening: isListening,
      speechOk: speechOk, onSend: onSend, onVoice: onVoice,
    ),
  ]);
}

// ══════════════════════════════════════════════════════════════════════
//  WEB TOP BAR (tablet)
// ══════════════════════════════════════════════════════════════════════
class _WebTopBar extends StatelessWidget {
  final bool isDark, ttsEnabled;
  final String selectedLang;
  final void Function(String) onLangSelect;
  final VoidCallback onTtsToggle, onClearChat;
  const _WebTopBar({required this.isDark, required this.ttsEnabled,
    required this.selectedLang, required this.onLangSelect,
    required this.onTtsToggle, required this.onClearChat});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final accent = isDark ? _purpleDark : _purple;
    final subClr  = isDark ? _dTextSub : _lTextSub;

    return Container(
      height: 48,
      decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border, width: 1.0))),
      padding: const EdgeInsets.symmetric(horizontal: _sp20),
      child: Row(children: [
        ..._kLangs.map((lang) {
          final active = lang.$1 == selectedLang;
          return Semantics(
            label: lang.$2, selected: active, button: true,
            child: GestureDetector(
              onTap: () => onLangSelect(lang.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                margin: const EdgeInsets.only(right: _sp8),
                padding: const EdgeInsets.symmetric(
                    horizontal: _sp12, vertical: _sp4),
                decoration: BoxDecoration(
                    color: active
                        ? accent.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: active
                            ? accent.withOpacity(0.28)
                            : Colors.transparent,
                        width: active ? 1.5 : 0)),
                child: Text('${lang.$3} ${lang.$2}',
                    style: _label(12,
                        active ? accent : subClr,
                        w: active ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          );
        }),
        const Spacer(),
        // TTS
        Semantics(
          label: ttsEnabled ? 'Mute' : 'Unmute', button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTtsToggle,
            child: Padding(
              padding: const EdgeInsets.all(_sp8),
              child: Icon(
                  ttsEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: ttsEnabled ? accent : subClr, size: 20),
            ),
          ),
        ),
        // Clear
        Semantics(
          label: 'Clear conversation', button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onClearChat,
            child: Padding(
              padding: const EdgeInsets.all(_sp8),
              child: Icon(Icons.delete_sweep_rounded,
                  color: isDark ? _dangerDark : _danger, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final void Function(String) onPrompt;
  const _EmptyState({required this.isDark, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys
        .map((q) => (l.t(q.$1), q.$2)).toList();
    final accent = isDark ? _purpleDark : _purple;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    // Quick prompt chips in info-blue (distinct from purple AI accent)
    final chipAccent = isDark ? _infoDark : _info;

    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sp32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.sign_language_rounded,
                color: Colors.white, size: 36)),
        const SizedBox(height: _sp20),
        Text(l.t('assistant_title'),
            style: _display(24, textClr)),
        const SizedBox(height: _sp8),
        Text(l.t('isl_empty_subtitle'),
            style: _body(14, subClr), textAlign: TextAlign.center),
        const SizedBox(height: _sp24),
        Wrap(spacing: _sp8, runSpacing: _sp8,
            children: prompts.take(4).map((q) =>
                Semantics(
                  label: q.$1, button: true,
                  child: GestureDetector(
                    onTap: () => onPrompt(q.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _sp16, vertical: _sp8),
                      decoration: BoxDecoration(
                          color: chipAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: chipAccent.withOpacity(0.22), width: 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(q.$2, size: 13, color: chipAccent),
                        const SizedBox(width: _sp8),
                        Text(q.$1, style: _label(12.5, chipAccent)),
                      ]),
                    ),
                  ),
                )).toList()),
      ]),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  OPTIONS MENU BUTTON (mobile 3-dot)
// ══════════════════════════════════════════════════════════════════════
class _OptionsMenuButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;
  const _OptionsMenuButton(
      {required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final redClr  = isDark ? _dangerDark : _danger;
    final bg      = isDark ? _dSurface2  : _lSurface;
    final border  = isDark ? _dBorder    : _lBorder;

    return PopupMenuButton<String>(
      tooltip: 'Options',
      color: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1)),
      elevation: 8,
      offset: const Offset(0, 44),
      icon: Icon(Icons.more_horiz_rounded, color: subClr, size: 20),
      onSelected: (v) {
        if (v == 'clear') onClear();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(value: 'clear', height: 44,
            child: Row(children: [
              Icon(Icons.delete_sweep_rounded, color: redClr, size: 16),
              const SizedBox(width: _sp12),
              Text(l.t('isl_options_clear_conversation'),
                  style: _body(14, redClr, w: FontWeight.w500)),
            ])),
        PopupMenuItem<String>(value: 'about', height: 44,
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: subClr, size: 16),
              const SizedBox(width: _sp12),
              Text(l.t('isl_options_about'),
                  style: _body(14, subClr, w: FontWeight.w500)),
            ])),
      ],
    );
  }
}