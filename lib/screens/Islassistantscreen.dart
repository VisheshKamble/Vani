// lib/screens/ISLAssistantScreen.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║  VANI — ISL Assistant Screen                               ║
// ║  Font: Google Sans (SF Pro equivalent)                     ║
// ║  Powered by: Gemini 2.0 Flash API                         ║
// ║                                                            ║
// ║  FEATURES                                                  ║
// ║  • Gemini AI — ISL-context system prompt                  ║
// ║  • Multilingual: EN / HI / MR (auto-detect + user select) ║
// ║  • Voice INPUT  — speech_to_text (mic button)             ║
// ║  • Voice OUTPUT — flutter_tts (speaks every AI reply)     ║
// ║  • Step-by-step ISL sign guides in every response         ║
// ║  • Inline ISL sign-name chips (tap to drill down)         ║
// ║  • Quick-prompt chips                                      ║
// ║  • Full conversation history sent to Gemini               ║
// ║  • Mobile: iOS Messages-style bubbles                     ║
// ║  • Web/tablet: macOS split layout via GlobalNavbar        ║
// ╚══════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS  — identical to the rest of the app
// ─────────────────────────────────────────────────────────────
const _blue      = Color(0xFF007AFF);
const _blue_D    = Color(0xFF0A84FF);
const _indigo    = Color(0xFF5856D6);
const _indigo_D  = Color(0xFF5E5CE6);
const _green     = Color(0xFF34C759);
const _red       = Color(0xFFFF3B30);
const _red_D     = Color(0xFFFF453A);
const _purple    = Color(0xFFAF52DE);
const _purple_D  = Color(0xFFBF5AF2);

const _lBg       = Color(0xFFF2F2F7);
const _lSurface  = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFEFEFF4);
const _lSep      = Color(0xFFC6C6C8);
const _lLabel    = Color(0xFF000000);
const _lLabel2   = Color(0x993C3C43);
const _lLabel3   = Color(0x4D3C3C43);
const _lFill     = Color(0x1F787880);

const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dSep      = Color(0xFF38383A);
const _dLabel    = Color(0xFFFFFFFF);
const _dLabel2   = Color(0x99EBEBF5);
const _dLabel3   = Color(0x4DEBEBF5);
const _dFill     = Color(0x3A787880);

TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

// ─────────────────────────────────────────────────────────────
//  GEMINI CONFIG  — loaded from .env.local at runtime
// ─────────────────────────────────────────────────────────────
String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
const  _kModel = 'gemini-2.5-flash';
String get _kUrl =>
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$_kModel:generateContent?key=$_geminiKey';

// ─────────────────────────────────────────────────────────────
//  ISL SYSTEM PROMPT  — scoped to this project's purpose
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
//  QUICK PROMPTS
// ─────────────────────────────────────────────────────────────
const _kQuickPrompts = [
  ('How do I sign "Hello" in ISL?',          Icons.waving_hand_rounded),
  ('Show me the sign for HELP',              Icons.front_hand_rounded),
  ('What is the ISL sign for WATER?',        Icons.water_drop_rounded),
  ('How to sign DOCTOR and HOSPITAL',        Icons.medical_services_rounded),
  ('Emergency signs I must know',            Icons.emergency_rounded),
  ('Explain ISL grammar rules',              Icons.menu_book_rounded),
  ('Sign for THANK YOU in ISL',              Icons.volunteer_activism_rounded),
  ('Rights of deaf people in India',         Icons.gavel_rounded),
];

// ─────────────────────────────────────────────────────────────
//  SUPPORTED LANGUAGES
// ─────────────────────────────────────────────────────────────
const _kLangs = [
  ('en', 'EN', '🇬🇧', 'en_IN', 'en-IN'),
  ('hi', 'हि', '🇮🇳', 'hi_IN', 'hi-IN'),
  ('mr', 'म',  '🇮🇳', 'mr_IN', 'mr-IN'),
];

// ─────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────
enum _Role { user, assistant }

enum _MsgStatus { sending, sent, error }

class _Msg {
  final String id;
  final _Role  role;
  String       text;
  _MsgStatus   status;
  final DateTime time;
  List<String> islTags;

  _Msg({
    required this.id, required this.role, required this.text,
    this.status = _MsgStatus.sent, this.islTags = const [],
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ══════════════════════════════════════════════════════════════
//  ISL ASSISTANT SCREEN
// ══════════════════════════════════════════════════════════════
class ISLAssistantScreen extends StatefulWidget {
  final VoidCallback     toggleTheme;
  final Function(Locale) setLocale;
  const ISLAssistantScreen(
      {super.key, required this.toggleTheme, required this.setLocale});
  @override
  State<ISLAssistantScreen> createState() => _ISLAssistantScreenState();
}

class _ISLAssistantScreenState extends State<ISLAssistantScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────
  final List<_Msg>           _msgs      = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();

  bool   _isLoading   = false;
  bool   _isListening = false;
  bool   _ttsEnabled  = true;
  String _lang        = 'en';   // en / hi / mr

  // ── Services ───────────────────────────────────────────────
  final FlutterTts        _tts    = FlutterTts();
  final stt.SpeechToText  _speech = stt.SpeechToText();
  bool                    _speechOk = false;

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _typingCtrl;
  late Animation<double>   _typingAnim;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _typingAnim = CurvedAnimation(parent: _typingCtrl, curve: Curves.easeInOut);

    _initTts();
    _initSpeech();

    // Welcome
    _addAiMsg(
      'नमस्ते! I\'m your ISL Assistant. 🤟\n\n'
      'I can help you learn Indian Sign Language step by step, explain any sign\'s '
      'handshape and movement, translate phrases, and connect you with resources for '
      'India\'s deaf and mute community.\n\n'
      'What would you like to learn today?',
    );
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
        if (s == 'done' || s == 'notListening') setState(() => _isListening = false);
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

  // ── Helpers ────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
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
          role: _Role.assistant,
          text: text,
          islTags: tags));
    });
    _scrollToBottom();
  }

  // ── Send ───────────────────────────────────────────────────
  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _isLoading) return;
    _inputCtrl.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _msgs.add(_Msg(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: _Role.user,
          text: t));
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
            text: 'Sorry, I couldn\'t connect right now. Please check your internet and try again.',
            status: _MsgStatus.error));
      });
      _scrollToBottom();
    }
  }

  // ── Gemini API ─────────────────────────────────────────────
  Future<String> _callGemini(String userText) async {
    // Build last 20 turns of context
    final history = _msgs.take(20).map((m) => {
      'role': m.role == _Role.user ? 'user' : 'model',
      'parts': [{'text': m.text}],
    }).toList();

    // Language instruction suffix
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
        'temperature': 0.70,
        'maxOutputTokens': 700,
        'topP': 0.90,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    });

    final resp = await http.post(
      Uri.parse(_kUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) throw Exception('API ${resp.statusCode}');

    final json  = jsonDecode(resp.body) as Map<String, dynamic>;
    final parts = (json['candidates'] as List?)?.first['content']['parts'] as List?;
    return parts?.first['text']?.toString() ?? 'No response received.';
  }

  // ── Voice input ────────────────────────────────────────────
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
      _addAiMsg('Chat cleared. नमस्ते! How can I help you with ISL today? 🤟');
    });
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w      = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ══════════════════════════════════════════════════════════
  //  MOBILE  (<700px)
  // ══════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final bg    = isDark ? _dBg     : _lBg;
    final navBg = isDark ? _dSurface : _lSurface;
    final sep   = isDark ? _dSep   : _lSep.withOpacity(0.5);
    final label = isDark ? _dLabel : _lLabel;
    final accent = isDark ? _purple_D : _purple;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [

          // ── iOS-style nav bar ──────────────────────────────
          Container(
            decoration: BoxDecoration(
                color: navBg,
                border: Border(bottom: BorderSide(color: sep, width: 0.5))),
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            child: Row(children: [
              // Back chevron
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chevron_left_rounded, color: accent, size: 28),
                    Text('Back', style: _t(15, FontWeight.w400, accent)),
                  ]),
                ),
              ),
              const Spacer(),
              // Title + avatar
              Column(children: [
                Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [accent, _blue],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.sign_language_rounded,
                        color: Colors.white, size: 16)),
                Text('ISL Assistant', style: _t(11, FontWeight.w600, label)),
              ]),
              const Spacer(),
              // TTS toggle + options
              Row(children: [
                _NavIconBtn(
                    icon: _ttsEnabled
                        ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: _ttsEnabled ? accent
                        : (isDark ? _dLabel3 : _lLabel3),
                    onTap: () {
                      setState(() => _ttsEnabled = !_ttsEnabled);
                      if (!_ttsEnabled) _tts.stop();
                    }),
                _NavIconBtn(
                    icon: Icons.more_horiz_rounded,
                    color: isDark ? _dLabel2 : _lLabel2,
                    onTap: () => _showOptions(ctx, isDark)),
              ]),
            ]),
          ),

          // ── Language selector strip ────────────────────────
          _LangStrip(selected: _lang, isDark: isDark,
              onSelect: (l) => setState(() => _lang = l)),

          // ── Messages ──────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: _msgs.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _msgs.length + (_isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _msgs.length) {
                          return _TypingIndicator(isDark: isDark, anim: _typingAnim);
                        }
                        return _MsgBubble(
                          msg: _msgs[i], isDark: isDark,
                          onTapSign: (sign) => _send('Tell me more about the ISL sign for $sign'),
                          onSpeak:   (text) async {
                            await _syncTtsLang();
                            await _tts.speak(_cleanForTts(text));
                          },
                        );
                      }),
            ),
          ),

          // ── Quick prompts ─────────────────────────────────
          if (_msgs.length <= 1)
            _QuickPromptsRow(isDark: isDark, onTap: _send),

          // ── Input bar ─────────────────────────────────────
          _InputBar(
            controller:  _inputCtrl,
            isDark:      isDark,
            isLoading:   _isLoading,
            isListening: _isListening,
            speechOk:    _speechOk,
            onSend:      _send,
            onVoice:     _toggleVoice,
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  WEB / DESKTOP  (≥700px)
  // ══════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final bg        = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Shared GlobalNavbar — activeRoute = 'assistant'
          GlobalNavbar(toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale, activeRoute: 'assistant'),

          Expanded(
            child: isDesktop
                ? _webDesktopLayout(ctx, isDark)
                : _webTabletLayout(ctx, isDark),
          ),
        ]),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) {
    return Row(children: [
      // Sidebar
      _WebSidebar(
        isDark:       isDark,
        selectedLang: _lang,
        ttsEnabled:   _ttsEnabled,
        onLangSelect: (l) => setState(() => _lang = l),
        onTtsToggle:  () {
          setState(() => _ttsEnabled = !_ttsEnabled);
          if (!_ttsEnabled) _tts.stop();
        },
        onClearChat:   _clearChat,
        onQuickPrompt: _send,
      ),
      // Chat pane
      Expanded(child: _WebChatPane(
        msgs: _msgs, isDark: isDark,
        isLoading: _isLoading, typingAnim: _typingAnim,
        scrollCtrl: _scrollCtrl, inputCtrl: _inputCtrl,
        isListening: _isListening, speechOk: _speechOk,
        onSend: _send, onVoice: _toggleVoice,
        onTapSign: (sign) => _send('Tell me more about the ISL sign for $sign'),
        onSpeak: (text) async {
          await _syncTtsLang();
          await _tts.speak(_cleanForTts(text));
        },
      )),
    ]);
  }

  Widget _webTabletLayout(BuildContext ctx, bool isDark) {
    return Column(children: [
      // Compact top bar for tablet
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
        onTapSign: (sign) => _send('Tell me more about the ISL sign for $sign'),
        onSpeak: (text) async {
          await _syncTtsLang();
          await _tts.speak(_cleanForTts(text));
        },
      )),
    ]);
  }

  // ── Options sheet ─────────────────────────────────────────
  void _showOptions(BuildContext ctx, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? _dSurface : _lSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OptionsSheet(isDark: isDark, onClear: _clearChat),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ══════════════════════════════════════════════════════════════
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
    final accent     = isDark ? _purple_D : _purple;
    final bubbleBg   = _isUser ? accent : (isDark ? _dSurface2 : _lSurface);
    final textColor  = _isUser ? Colors.white : (isDark ? _dLabel : _lLabel);
    final timeColor  = isDark ? _dLabel3 : _lLabel3;
    final isError    = msg.status == _MsgStatus.error;

    return Padding(
      padding: EdgeInsets.only(
          bottom: 4,
          left:  _isUser ? 60 : 0,
          right: _isUser ? 0 : 60),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Assistant avatar row
          if (!_isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(children: [
                Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [accent, _blue],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.sign_language_rounded,
                        color: Colors.white, size: 11)),
                const SizedBox(width: 6),
                Text('ISL Assistant',
                    style: _t(11, FontWeight.w600, isDark ? _dLabel2 : _lLabel2)),
              ]),
            ),

          // Bubble — long-press to speak
          GestureDetector(
            onLongPress: () => onSpeak(msg.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: isError
                      ? (isDark ? _red_D : _red).withOpacity(0.10)
                      : bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(_isUser ? 18 : 4),
                    bottomRight: Radius.circular(_isUser ? 4  : 18),
                  ),
                  border: !_isUser
                      ? Border.all(
                          color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                          width: 0.5)
                      : null,
                  boxShadow: _isUser ? [] : [BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 10, offset: const Offset(0, 2))]),
              child: Text(
                msg.text,
                style: _t(15, FontWeight.w400,
                    isError ? (isDark ? _red_D : _red) : textColor,
                    ls: -0.2, h: 1.5),
              ),
            ),
          ),

          // ISL sign chips
          if (!_isUser && msg.islTags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: msg.islTags.take(5).map((sign) =>
                  GestureDetector(
                    onTap: () => onTapSign(sign),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.22), width: 0.5)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.front_hand_rounded, size: 10, color: accent),
                        const SizedBox(width: 4),
                        Text(sign,
                            style: _t(10.5, FontWeight.w600, accent)),
                      ]),
                    ),
                  )).toList(),
            ),
          ],

          // Timestamp
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(_fmtTime(msg.time), style: _t(10, FontWeight.w400, timeColor)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════
//  TYPING INDICATOR
// ══════════════════════════════════════════════════════════════
class _TypingIndicator extends StatelessWidget {
  final bool isDark;
  final Animation<double> anim;
  const _TypingIndicator({required this.isDark, required this.anim});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purple_D : _purple;
    final bg     = isDark ? _dSurface2 : _lSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, _blue],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle),
            child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 11)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              border: Border.all(
                  color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 8, offset: const Offset(0, 2))]),
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => Row(children: List.generate(3, (i) {
              final phase = ((anim.value + i * 0.28) % 1.0);
              final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? _dLabel2 : _lLabel2)
                              .withOpacity(0.3 + 0.7 * scale))),
                ),
              );
            })),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  INPUT BAR
// ══════════════════════════════════════════════════════════════
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark, isLoading, isListening, speechOk;
  final void Function(String) onSend;
  final VoidCallback onVoice;
  const _InputBar({
    required this.controller, required this.isDark,
    required this.isLoading,  required this.isListening,
    required this.speechOk,   required this.onSend, required this.onVoice,
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
    final bg     = widget.isDark ? _dSurface  : _lSurface;
    final sep    = widget.isDark ? _dSep      : _lSep.withOpacity(0.5);
    final fill   = widget.isDark ? _dFill.withOpacity(0.5) : _lFill;
    final label2 = widget.isDark ? _dLabel2   : _lLabel2;
    final accent = widget.isDark ? _purple_D  : _purple;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
              color: bg.withOpacity(0.92),
              border: Border(top: BorderSide(color: sep, width: 0.5))),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(children: [
            // Mic button
            if (widget.speechOk)
              _CircleBtn(
                icon: widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: widget.isListening ? (widget.isDark ? _red_D : _red) : label2,
                bg:    widget.isListening
                    ? (widget.isDark ? _red_D : _red).withOpacity(0.12)
                    : fill,
                size: 36,
                onTap: widget.onVoice,
              ),

            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 36, maxHeight: 120),
                decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.07),
                        width: 0.5)),
                child: TextField(
                  controller: widget.controller,
                  maxLines:   null,
                  enabled:    !widget.isLoading,
                  textInputAction: TextInputAction.newline,
                  style: _t(15, FontWeight.w400,
                      widget.isDark ? _dLabel : _lLabel),
                  decoration: InputDecoration(
                    hintText: widget.isListening ? 'Listening…' : 'Ask about ISL…',
                    hintStyle: _t(15, FontWeight.w400, label2),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  ),
                  onSubmitted: (v) { if (!widget.isLoading) widget.onSend(v); },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send / loading
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 36, height: 36,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: accent)))
                  : _CircleBtn(
                      key: const ValueKey('send'),
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.white,
                      bg: _hasText ? accent : label2.withOpacity(0.40),
                      size: 36,
                      onTap: () => widget.onSend(widget.controller.text)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  QUICK PROMPTS ROW
// ══════════════════════════════════════════════════════════════
class _QuickPromptsRow extends StatelessWidget {
  final bool isDark;
  final void Function(String) onTap;
  const _QuickPromptsRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface : _lSurface;
    final sep   = isDark ? _dSep : _lSep.withOpacity(0.5);
    final accent = isDark ? _purple_D : _purple;

    return Container(
      height: 52,
      decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: sep, width: 0.5))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _kQuickPrompts.length,
        itemBuilder: (_, i) {
          final q = _kQuickPrompts[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(q.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.20), width: 0.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(q.$2, size: 13, color: accent),
                  const SizedBox(width: 5),
                  Text(q.$1, style: _t(12, FontWeight.w500, accent), maxLines: 1),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LANGUAGE STRIP  (mobile)
// ══════════════════════════════════════════════════════════════
class _LangStrip extends StatelessWidget {
  final String selected;
  final bool isDark;
  final void Function(String) onSelect;
  const _LangStrip({required this.selected, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purple_D : _purple;
    final bg     = isDark ? _dSurface : _lSurface;
    final sep    = isDark ? _dSep : _lSep.withOpacity(0.5);

    return Container(
      height: 36,
      decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: sep, width: 0.5))),
      child: Row(children: [
        const SizedBox(width: 12),
        Text('Lang:', style: _t(11, FontWeight.w500,
            isDark ? _dLabel3 : _lLabel3)),
        const SizedBox(width: 8),
        ..._kLangs.map((l) {
          final active = l.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(l.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: active ? accent.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? accent.withOpacity(0.35) : Colors.transparent,
                      width: 0.5)),
              child: Text('${l.$3} ${l.$2}',
                  style: _t(11.5,
                      active ? FontWeight.w700 : FontWeight.w400,
                      active ? accent : (isDark ? _dLabel2 : _lLabel2))),
            ),
          );
        }),
        const Spacer(),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB SIDEBAR
// ══════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final bool isDark, ttsEnabled;
  final String selectedLang;
  final void Function(String) onLangSelect;
  final VoidCallback onTtsToggle, onClearChat;
  final void Function(String) onQuickPrompt;
  const _WebSidebar({
    required this.isDark,       required this.ttsEnabled,
    required this.selectedLang, required this.onLangSelect,
    required this.onTtsToggle,  required this.onClearChat,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface  : _lSurface;
    final sep    = isDark ? _dSep      : _lSep.withOpacity(0.5);
    final label  = isDark ? _dLabel    : _lLabel;
    final label2 = isDark ? _dLabel2   : _lLabel2;
    final label3 = isDark ? _dLabel3   : _lLabel3;
    final accent = isDark ? _purple_D  : _purple;

    return Container(
      width: 280,
      decoration: BoxDecoration(
          color: bg,
          border: Border(right: BorderSide(color: sep, width: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, _blue],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 22)),
            const SizedBox(height: 12),
            Text('ISL Assistant',
                style: _t(18, FontWeight.w700, label, ls: -0.3)),
            Text('Powered by Gemini · ISL Expert',
                style: _t(11.5, FontWeight.w400, label2)),
          ]),
        ),

        Divider(height: 1, thickness: 0.5, color: sep),

        // Language
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text('LANGUAGE',
              style: _t(10, FontWeight.w600, label3, ls: 0.8)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: _kLangs.map((l) {
            final active = l.$1 == selectedLang;
            return GestureDetector(
              onTap: () => onLangSelect(l.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                    color: active ? accent.withOpacity(0.10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: active ? accent.withOpacity(0.25) : Colors.transparent,
                        width: 0.5)),
                child: Row(children: [
                  Text('${l.$3}  ${l.$2}',
                      style: _t(13.5,
                          active ? FontWeight.w600 : FontWeight.w400,
                          active ? accent : label2)),
                  const Spacer(),
                  if (active) Icon(Icons.check_rounded, color: accent, size: 14),
                ]),
              ),
            );
          }).toList()),
        ),

        // Settings
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text('SETTINGS',
              style: _t(10, FontWeight.w600, label3, ls: 0.8)),
        ),
        _SidebarToggle(
            icon: ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: 'Read responses aloud',
            value: ttsEnabled, isDark: isDark, accent: accent,
            onTap: onTtsToggle),

        Divider(height: 1, thickness: 0.5, color: sep,
            indent: 20, endIndent: 20),

        // Quick prompts
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text('QUICK PROMPTS',
              style: _t(10, FontWeight.w600, label3, ls: 0.8)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: _kQuickPrompts.length,
            itemBuilder: (_, i) {
              final q = _kQuickPrompts[i];
              return _SidebarPromptBtn(
                  icon: q.$2, label: q.$1, isDark: isDark,
                  accent: accent, onTap: () => onQuickPrompt(q.$1));
            },
          ),
        ),

        Divider(height: 1, thickness: 0.5, color: sep),
        // Clear
        GestureDetector(
          onTap: onClearChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(children: [
              Icon(Icons.delete_sweep_rounded,
                  color: isDark ? _red_D : _red, size: 15),
              const SizedBox(width: 10),
              Text('Clear conversation',
                  style: _t(13, FontWeight.w500, isDark ? _red_D : _red)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────
//  SIDEBAR HELPERS
// ──────────────────────────────────────────────
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
    final label2 = isDark ? _dLabel2 : _lLabel2;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Row(children: [
          Icon(icon, color: value ? accent : label2, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: _t(13, FontWeight.w400, label2))),
          Container(
            width: 36, height: 20,
            decoration: BoxDecoration(
                color: value ? accent : label2.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10)),
            child: AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 150),
              child: Container(
                  width: 16, height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
        ]),
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
    final label2 = widget.isDark ? _dLabel2 : _lLabel2;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: _hovered ? widget.accent.withOpacity(0.07) : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(widget.icon, size: 13, color: widget.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.label,
                style: _t(12, FontWeight.w400, label2),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB CHAT PANE
// ══════════════════════════════════════════════════════════════
class _WebChatPane extends StatelessWidget {
  final List<_Msg> msgs;
  final bool isDark, isLoading, isListening, speechOk;
  final Animation<double> typingAnim;
  final ScrollController scrollCtrl;
  final TextEditingController inputCtrl;
  final void Function(String) onSend, onTapSign, onSpeak;
  final VoidCallback onVoice;
  const _WebChatPane({
    required this.msgs,       required this.isDark,
    required this.isLoading,  required this.isListening,
    required this.speechOk,   required this.typingAnim,
    required this.scrollCtrl, required this.inputCtrl,
    required this.onSend,     required this.onVoice,
    required this.onTapSign,  required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: msgs.isEmpty
            ? _WebEmptyState(isDark: isDark)
            : ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                physics: const BouncingScrollPhysics(),
                itemCount: msgs.length + (isLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == msgs.length) {
                    return _TypingIndicator(isDark: isDark, anim: typingAnim);
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
}

// ══════════════════════════════════════════════════════════════
//  WEB TOP BAR  (tablet)
// ══════════════════════════════════════════════════════════════
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
    final bg     = isDark ? _dSurface : _lSurface;
    final sep    = isDark ? _dSep : _lSep.withOpacity(0.5);
    final accent = isDark ? _purple_D : _purple;
    final label2 = isDark ? _dLabel2  : _lLabel2;

    return Container(
      height: 46,
      decoration: BoxDecoration(
          color: bg, border: Border(bottom: BorderSide(color: sep, width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        ..._kLangs.map((l) {
          final active = l.$1 == selectedLang;
          return GestureDetector(
            onTap: () => onLangSelect(l.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: active ? accent.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? accent.withOpacity(0.28) : Colors.transparent,
                      width: 0.5)),
              child: Text('${l.$3} ${l.$2}',
                  style: _t(12, active ? FontWeight.w600 : FontWeight.w400,
                      active ? accent : label2)),
            ),
          );
        }),
        const Spacer(),
        _NavIconBtn(
            icon: ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: ttsEnabled ? accent : label2,
            onTap: onTtsToggle),
        _NavIconBtn(
            icon: Icons.delete_sweep_rounded,
            color: isDark ? _red_D : _red,
            onTap: onClearChat),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATES
// ══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purple_D : _purple;
    final label  = isDark ? _dLabel   : _lLabel;
    final label2 = isDark ? _dLabel2  : _lLabel2;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, _blue],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 30)),
      const SizedBox(height: 16),
      Text('ISL Assistant', style: _t(20, FontWeight.w700, label, ls: -0.3)),
      const SizedBox(height: 6),
      Text('Ask anything about Indian Sign Language',
          style: _t(14, FontWeight.w400, label2)),
    ]));
  }
}

class _WebEmptyState extends StatelessWidget {
  final bool isDark;
  const _WebEmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purple_D : _purple;
    final label  = isDark ? _dLabel   : _lLabel;
    final label2 = isDark ? _dLabel2  : _lLabel2;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, _blue],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 34)),
      const SizedBox(height: 20),
      Text('VANI ISL Assistant', style: _t(26, FontWeight.w700, label, ls: -0.5)),
      const SizedBox(height: 8),
      Text('Multilingual · Voice Input & Output · ISL Expert',
          style: _t(14, FontWeight.w400, label2, ls: 0.2)),
      const SizedBox(height: 24),
      Wrap(spacing: 10, runSpacing: 10,
          children: _kQuickPrompts.take(4).map((q) =>
              GestureDetector(
                onTap: () {},   // handled at screen level via sendPrompt
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accent.withOpacity(0.20), width: 0.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(q.$2, size: 13, color: accent),
                    const SizedBox(width: 6),
                    Text(q.$1, style: _t(12.5, FontWeight.w500, accent)),
                  ]),
                ),
              )).toList()),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════
//  OPTIONS BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _OptionsSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;
  const _OptionsSheet({required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final sep    = isDark ? _dSep : _lSep.withOpacity(0.5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: isDark ? _dFill : _lFill,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Options', style: _t(17, FontWeight.w600, label, ls: -0.2)),
        const SizedBox(height: 16),
        Divider(height: 1, color: sep),
        ListTile(
          leading: Icon(Icons.delete_sweep_rounded, color: isDark ? _red_D : _red),
          title: Text('Clear Conversation',
              style: _t(15, FontWeight.w500, isDark ? _red_D : _red)),
          onTap: () { Navigator.pop(context); onClear(); },
        ),
        ListTile(
          leading: Icon(Icons.info_outline_rounded, color: label2),
          title: Text('About ISL Assistant',
              style: _t(15, FontWeight.w500, label2)),
          subtitle: Text('Powered by Gemini 2.0 Flash · ISLRTC aligned',
              style: _t(12, FontWeight.w400, label2)),
          onTap: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED TINY WIDGETS
// ══════════════════════════════════════════════════════════════
class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavIconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20)));
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final double size;
  final VoidCallback onTap;
  const _CircleBtn({super.key, required this.icon, required this.color,
    required this.bg, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size, height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: size * 0.50)));
}