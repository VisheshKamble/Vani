// lib/screens/ISLAssistantScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — ISL Assistant Screen  · Premium Redesign v2               ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║  Powered by: Gemini 2.0 Flash API                                 ║
// ║  Languages: 10 Indian Languages                                   ║
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
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

// Brand
const _primary = Color(0xFF1A56DB);
const _primaryDark = Color(0xFF4A8EFF);

// Secondary (teal)
const _secondary = Color(0xFF00796B);
const _secondaryDark = Color(0xFF26A69A);

// Assistant accent (violet)
const _purple = Color(0xFF6200EA);
const _purpleDark = Color(0xFF9C6BFF);
const _purpleGlow = Color(0xFF7C3AED);

// Status
const _danger = Color(0xFFB71C1C);
const _dangerDark = Color(0xFFEF5350);
const _dangerLight = Color(0xFFFFEBEE);
const _info = Color(0xFF0D47A1);
const _infoDark = Color(0xFF42A5F5);
const _success = Color(0xFF1B7340);
const _successDark = Color(0xFF27AE60);

// Light theme
const _lBg = Color(0xFFF8F9FC);
const _lSurface = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF0F4F8);
const _lSurface3 = Color(0xFFEAEEF4);
const _lBorder = Color(0xFFDDE3ED);
const _lBorderSub = Color(0xFFEDF0F5);
const _lText = Color(0xFF0D1117);
const _lTextSub = Color(0xFF374151);
const _lTextMuted = Color(0xFF6B7280);

// Dark theme
const _dBg = Color(0xFF080C12);
const _dSurface = Color(0xFF0F1520);
const _dSurface2 = Color(0xFF161D2A);
const _dSurface3 = Color(0xFF1C2535);
const _dBorder = Color(0xFF252F40);
const _dBorderSub = Color(0xFF1C2535);
const _dText = Color(0xFFECF0F7);
const _dTextSub = Color(0xFFB0BEC5);
const _dTextMuted = Color(0xFF6B7A90);

// Spacing
const _sp4 = 4.0;
const _sp6 = 6.0;
const _sp8 = 8.0;
const _sp10 = 10.0;
const _sp12 = 12.0;
const _sp14 = 14.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;
const _sp48 = 48.0;

// ── Type helpers ─────────────────────────────────────────────────────
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

TextStyle _mono(double size, Color c) => TextStyle(
  fontFamily: 'monospace',
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: c,
  height: 1.5,
  letterSpacing: 0.5,
);

// ─────────────────────────────────────────────────────────────────────
//  GEMINI CONFIG
// ─────────────────────────────────────────────────────────────────────
const String _geminiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);
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
• If the user writes in Bengali — respond fully in Bengali (বাংলা)
• If the user writes in Tamil — respond fully in Tamil (தமிழ்)
• If the user writes in Telugu — respond fully in Telugu (తెలుగు)
• If the user writes in Kannada — respond fully in Kannada (ಕನ್ನಡ)
• If the user writes in Malayalam — respond fully in Malayalam (മലയാളം)
• If the user writes in Gujarati — respond fully in Gujarati (ગુજરાતી)
• If the user writes in Punjabi — respond fully in Punjabi (ਪੰਜਾਬੀ)
• If the user writes in Odia — respond fully in Odia (ଓଡ଼ିଆ)
• Hinglish is fine and natural
• For sign descriptions, always include the English sign name in CAPS even in other language responses

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
//  10 INDIAN LANGUAGES
// ─────────────────────────────────────────────────────────────────────
const _kLangs = [
  ('en', 'EN', 'English', '🇬🇧', 'en_IN', 'en-IN'),
  ('hi', 'हि', 'हिंदी', '🇮🇳', 'hi_IN', 'hi-IN'),
  ('mr', 'म', 'मराठी', '🇮🇳', 'mr_IN', 'mr-IN'),
  ('bn', 'বাং', 'বাংলা', '🇮🇳', 'bn_IN', 'bn-IN'),
  ('ta', 'தமி', 'தமிழ்', '🇮🇳', 'ta_IN', 'ta-IN'),
  ('te', 'తె', 'తెలుగు', '🇮🇳', 'te_IN', 'te-IN'),
  ('kn', 'ಕನ್', 'ಕನ್ನಡ', '🇮🇳', 'kn_IN', 'kn-IN'),
  ('ml', 'മ', 'മലയാളം', '🇮🇳', 'ml_IN', 'ml-IN'),
  ('gu', 'ગુ', 'ગુજરાતી', '🇮🇳', 'gu_IN', 'gu-IN'),
  ('pa', 'ਪੰ', 'ਪੰਜਾਬੀ', '🇮🇳', 'pa_IN', 'pa-IN'),
];

// ─────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────
enum _Role { user, assistant }

enum _MsgStatus { sent, error }

class _Msg {
  final String id;
  final _Role role;
  String text;
  _MsgStatus status;
  final DateTime time;
  List<String> islTags;
  _Msg({
    required this.id,
    required this.role,
    required this.text,
    this.status = _MsgStatus.sent,
    this.islTags = const [],
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ══════════════════════════════════════════════════════════════════════
//  ISL ASSISTANT SCREEN
// ══════════════════════════════════════════════════════════════════════
class ISLAssistantScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const ISLAssistantScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<ISLAssistantScreen> createState() => _ISLAssistantScreenState();
}

class _ISLAssistantScreenState extends State<ISLAssistantScreen>
    with TickerProviderStateMixin {
  final List<_Msg> _msgs = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isLoading = false;
  bool _isListening = false;
  bool _ttsEnabled = true;
  String _lang = 'en';

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechOk = false;

  late AnimationController _typingCtrl;
  late Animation<double> _typingAnim;
  bool _didSeedWelcome = false;

  // For animated gradient header on web
  late AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _typingAnim = CurvedAnimation(parent: _typingCtrl, curve: Curves.easeInOut);
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
    await _tts.setSpeechRate(0.90);
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
    _gradientCtrl.dispose();
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
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<String> _extractIslTags(String text) {
    final re = RegExp(r'\b[A-Z]{2,}(?:[_\s][A-Z]+)*\b');
    const skip = {
      'ISL',
      'AI',
      'VANI',
      'IN',
      'OF',
      'TO',
      'THE',
      'AND',
      'FOR',
      'OR',
      'IS',
      'ARE',
      'BY',
      'WITH',
      'FROM',
      'ON',
      'AT',
      'A',
      'NMM',
      'SOV',
    };
    return re
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((s) => !skip.contains(s))
        .toSet()
        .toList();
  }

  void _addAiMsg(String text) {
    final tags = _extractIslTags(text);
    setState(() {
      _msgs.add(
        _Msg(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: _Role.assistant,
          text: text,
          islTags: tags,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _isLoading) return;
    _inputCtrl.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _msgs.add(
        _Msg(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: _Role.user,
          text: t,
        ),
      );
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
        _msgs.add(
          _Msg(
            id: '${DateTime.now().millisecondsSinceEpoch}',
            role: _Role.assistant,
            text: AppLocalizations.of(context).t('isl_connect_error'),
            status: _MsgStatus.error,
          ),
        );
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
    final history = _msgs
        .take(20)
        .map(
          (m) => {
            'role': m.role == _Role.user ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
        )
        .toList();

    final langEntry = _kLangs.firstWhere((l) => l.$1 == _lang);
    final langSuffix = _lang == 'en'
        ? ''
        : ' (Please respond in ${langEntry.$3} — ${langEntry.$4} में उत्तर दें)';

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _kSystemPrompt},
        ],
      },
      'contents': [
        ...history,
        {
          'role': 'user',
          'parts': [
            {'text': userText + langSuffix},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.70,
        'maxOutputTokens': 700,
        'topP': 0.90,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });

    final resp = await http
        .post(
          Uri.parse(_kUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) throw Exception('API ${resp.statusCode}');
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final parts =
        (json['candidates'] as List?)?.first['content']['parts'] as List?;
    return parts?.first['text']?.toString() ??
        AppLocalizations.of(context).t('isl_no_response');
  }

  Future<void> _toggleVoice() async {
    if (!_speechOk) return;
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      final locale = _kLangs.firstWhere((l) => l.$1 == _lang).$5;
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
    final ttsLang = _kLangs.firstWhere((l) => l.$1 == _lang).$6;
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

  String _askMoreSignPrompt(String sign) => AppLocalizations.of(
    context,
  ).t('isl_ask_more_sign').replaceAll('{sign}', sign);

  // ════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark)
        : _buildWeb(context, isDark, w);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final bg = isDark ? _dBg : _lBg;
    final navBg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _purpleDark : _purple;
    final navBlue = isDark ? Color(0xFF4A8EFF) : _info;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Refined mobile nav bar ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: navBg,
                border: Border(bottom: BorderSide(color: border, width: 1.0)),
              ),
              padding: const EdgeInsets.fromLTRB(_sp8, _sp10, _sp12, _sp10),
              child: Row(
                children: [
                  Semantics(
                    label: l.t('common_back'),
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp8,
                          vertical: _sp8,
                        ),
                        decoration: BoxDecoration(
                          color: navBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: navBlue.withOpacity(0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              color: navBlue,
                              size: 20,
                            ),
                            Text(
                              l.t('common_back'),
                              style: _label(13, navBlue, w: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Avatar + Title centered
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sign_language_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.t('assistant_title'),
                        style: _label(10, textClr, w: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // TTS toggle — pill style
                  Semantics(
                    label: _ttsEnabled
                        ? 'Mute voice output'
                        : 'Unmute voice output',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _ttsEnabled = !_ttsEnabled);
                        if (!_ttsEnabled) _tts.stop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _ttsEnabled
                              ? accent.withOpacity(0.12)
                              : (isDark ? _dSurface2 : _lSurface2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _ttsEnabled
                                ? accent.withOpacity(0.30)
                                : border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _ttsEnabled
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_off_rounded,
                          size: 17,
                          color: _ttsEnabled ? accent : subClr,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _sp8),
                  _OptionsMenuButton(isDark: isDark, onClear: _clearChat),
                ],
              ),
            ),

            // ── Language selector (scrollable pill row) ──────────────────
            _LangPillRow(
              selected: _lang,
              isDark: isDark,
              onSelect: (l) => setState(() => _lang = l),
            ),

            // ── Messages ─────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(ctx).unfocus(),
                child: _msgs.isEmpty
                    ? _EmptyState(isDark: isDark, onPrompt: _send)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(
                          _sp12,
                          _sp16,
                          _sp12,
                          _sp8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _msgs.length + (_isLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _msgs.length) {
                            return _TypingIndicator(
                              isDark: isDark,
                              anim: _typingAnim,
                            );
                          }
                          return _MsgBubble(
                            msg: _msgs[i],
                            isDark: isDark,
                            onTapSign: (s) => _send(_askMoreSignPrompt(s)),
                            onSpeak: (text) async {
                              await _syncTtsLang();
                              await _tts.speak(_cleanForTts(text));
                            },
                          );
                        },
                      ),
              ),
            ),

            if (_msgs.length <= 1)
              _QuickPromptsRow(isDark: isDark, onTap: _send),

            _InputBar(
              controller: _inputCtrl,
              isDark: isDark,
              isLoading: _isLoading,
              isListening: _isListening,
              speechOk: _speechOk,
              onSend: _send,
              onVoice: _toggleVoice,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  WEB / DESKTOP — Premium layout
  // ════════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, double w) {
    final isDesktop = w > 1100;
    final bg = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            GlobalNavbar(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
              activeRoute: 'assistant',
            ),
            Expanded(
              child: isDesktop
                  ? _webDesktopLayout(ctx, isDark)
                  : _webTabletLayout(ctx, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, bool isDark) => Row(
    children: [
      _WebSidebar(
        isDark: isDark,
        selectedLang: _lang,
        ttsEnabled: _ttsEnabled,
        onLangSelect: (l) => setState(() => _lang = l),
        onTtsToggle: () {
          setState(() => _ttsEnabled = !_ttsEnabled);
          if (!_ttsEnabled) _tts.stop();
        },
        onClearChat: _clearChat,
        onQuickPrompt: _send,
      ),
      Expanded(
        child: _WebChatPane(
          msgs: _msgs,
          isDark: isDark,
          isLoading: _isLoading,
          typingAnim: _typingAnim,
          scrollCtrl: _scrollCtrl,
          inputCtrl: _inputCtrl,
          isListening: _isListening,
          speechOk: _speechOk,
          onSend: _send,
          onVoice: _toggleVoice,
          onTapSign: (s) => _send(_askMoreSignPrompt(s)),
          onSpeak: (text) async {
            await _syncTtsLang();
            await _tts.speak(_cleanForTts(text));
          },
        ),
      ),
    ],
  );

  Widget _webTabletLayout(BuildContext ctx, bool isDark) => Column(
    children: [
      _WebTopBar(
        isDark: isDark,
        selectedLang: _lang,
        ttsEnabled: _ttsEnabled,
        onLangSelect: (l) => setState(() => _lang = l),
        onTtsToggle: () {
          setState(() => _ttsEnabled = !_ttsEnabled);
          if (!_ttsEnabled) _tts.stop();
        },
        onClearChat: _clearChat,
      ),
      Expanded(
        child: _WebChatPane(
          msgs: _msgs,
          isDark: isDark,
          isLoading: _isLoading,
          typingAnim: _typingAnim,
          scrollCtrl: _scrollCtrl,
          inputCtrl: _inputCtrl,
          isListening: _isListening,
          speechOk: _speechOk,
          onSend: _send,
          onVoice: _toggleVoice,
          onTapSign: (s) => _send(_askMoreSignPrompt(s)),
          onSpeak: (text) async {
            await _syncTtsLang();
            await _tts.speak(_cleanForTts(text));
          },
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════
//  LANGUAGE PILL ROW (mobile) — scrollable, 10 languages
// ══════════════════════════════════════════════════════════════════════
class _LangPillRow extends StatelessWidget {
  final String selected;
  final bool isDark;
  final void Function(String) onSelect;
  const _LangPillRow({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purpleDark : _purple;
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final l = AppLocalizations.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: _sp12),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 12, color: mutedClr),
                const SizedBox(width: _sp4),
                Text('Lang', style: _label(10, mutedClr, w: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: _sp8),
          // vertical divider
          Container(width: 1, height: 20, color: border),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: _sp8,
                vertical: _sp8,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: _kLangs.length,
              itemBuilder: (_, i) {
                final lang = _kLangs[i];
                final active = lang.$1 == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: _sp6),
                  child: Semantics(
                    label: lang.$3,
                    selected: active,
                    button: true,
                    child: GestureDetector(
                      onTap: () => onSelect(lang.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp10,
                          vertical: _sp4,
                        ),
                        decoration: BoxDecoration(
                          color: active ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? accent : border,
                            width: active ? 0 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(lang.$4, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: _sp4),
                            Text(
                              lang.$2,
                              style: _label(
                                11,
                                active ? Colors.white : subClr,
                                w: active ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE — Premium redesign
// ══════════════════════════════════════════════════════════════════════
class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final bool isDark;
  final void Function(String) onTapSign;
  final void Function(String) onSpeak;
  const _MsgBubble({
    required this.msg,
    required this.isDark,
    required this.onTapSign,
    required this.onSpeak,
  });

  bool get _isUser => msg.role == _Role.user;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purpleDark : _purple;
    final userBg1 = isDark ? _primaryDark : _primary;
    final userBg2 = isDark ? Color(0xFF5B4AE8) : Color(0xFF4338CA);
    final aiBg = isDark ? _dSurface2 : _lSurface;
    final aiBorder = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final timeClr = isDark ? _dTextMuted : _lTextMuted;
    final isError = msg.status == _MsgStatus.error;
    final signAccent = isDark ? _secondaryDark : _secondary;
    final l = AppLocalizations.of(context);

    return Semantics(
      label:
          '${_isUser ? l.t('assistant_you') : l.t('assistant_title')}: ${msg.text}',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: _sp6,
          left: _isUser ? 48 : 0,
          right: _isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: _isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // AI avatar row
            if (!_isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: _sp6, left: _sp4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sign_language_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: _sp8),
                    Text(
                      l.t('app_title_short'),
                      style: _label(
                        11,
                        isDark ? _dTextSub : _lTextSub,
                        w: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: _sp6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),

            // Bubble
            Semantics(
              label: l.t('isl_long_press_speak'),
              child: GestureDetector(
                onLongPress: () => onSpeak(msg.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _sp16,
                    vertical: _sp12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isError
                        ? null
                        : (_isUser
                              ? LinearGradient(
                                  colors: [userBg1, userBg2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null),
                    color: isError
                        ? (isDark
                              ? _dangerDark.withOpacity(0.12)
                              : _dangerLight)
                        : (_isUser ? null : aiBg),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(_isUser ? 18 : 4),
                      bottomRight: Radius.circular(_isUser ? 4 : 18),
                    ),
                    border: isError
                        ? Border.all(
                            color: (isDark ? _dangerDark : _danger).withOpacity(
                              0.35,
                            ),
                            width: 1,
                          )
                        : (!_isUser
                              ? Border.all(color: aiBorder, width: 1)
                              : null),
                    boxShadow: _isUser
                        ? [
                            BoxShadow(
                              color: _primary.withOpacity(0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.15 : 0.04,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    msg.text,
                    style: _body(
                      14.5,
                      isError
                          ? (isDark ? _dangerDark : _danger)
                          : (_isUser ? Colors.white : textClr),
                    ),
                  ),
                ),
              ),
            ),

            // ISL sign chips
            if (!_isUser && msg.islTags.isNotEmpty) ...[
              const SizedBox(height: _sp8),
              Wrap(
                spacing: _sp6,
                runSpacing: _sp6,
                children: msg.islTags
                    .take(5)
                    .map(
                      (sign) => Semantics(
                        label: l.t('isl_learn_sign').replaceAll('{sign}', sign),
                        button: true,
                        child: GestureDetector(
                          onTap: () => onTapSign(sign),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _sp10,
                              vertical: _sp4,
                            ),
                            decoration: BoxDecoration(
                              color: signAccent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: signAccent.withOpacity(0.30),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.front_hand_rounded,
                                  size: 11,
                                  color: signAccent,
                                ),
                                const SizedBox(width: _sp4),
                                Text(
                                  sign,
                                  style: _label(
                                    10.5,
                                    signAccent,
                                    w: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Time
            const SizedBox(height: _sp4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sp4),
              child: Text(
                _fmtTime(msg.time),
                style: _label(9.5, timeClr, w: FontWeight.w400),
              ),
            ),
            const SizedBox(height: _sp10),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════════════
//  TYPING INDICATOR — refined
// ══════════════════════════════════════════════════════════════════════
class _TypingIndicator extends StatelessWidget {
  final bool isDark;
  final Animation<double> anim;
  const _TypingIndicator({required this.isDark, required this.anim});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _purpleDark : _purple;
    final bg = isDark ? _dSurface2 : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final l = AppLocalizations.of(context);

    return Semantics(
      label: l.t('isl_typing'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _sp12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: _sp8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _sp16,
                vertical: _sp12,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: border, width: 1),
              ),
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Row(
                  children: List.generate(3, (i) {
                    final phase = ((anim.value + i * 0.28) % 1.0);
                    final scale =
                        0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? _sp5 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.3 + 0.7 * scale),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _sp5 = 5.0;

// ══════════════════════════════════════════════════════════════════════
//  INPUT BAR — Premium glass-style
// ══════════════════════════════════════════════════════════════════════
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark, isLoading, isListening, speechOk;
  final void Function(String) onSend;
  final VoidCallback onVoice;
  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.isListening,
    required this.speechOk,
    required this.onSend,
    required this.onVoice,
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
    final l = AppLocalizations.of(context);
    final bg = widget.isDark ? _dSurface : _lSurface;
    final border = widget.isDark ? _dBorder : _lBorder;
    final fill = widget.isDark ? _dSurface2 : _lSurface2;
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    final textClr = widget.isDark ? _dText : _lText;
    final hintClr = widget.isDark ? _dTextMuted : _lTextMuted;
    final accent = widget.isDark ? _purpleDark : _purple;

    final micColor = widget.isListening
        ? (widget.isDark ? _dangerDark : _danger)
        : subClr;
    final micBg = widget.isListening
        ? (widget.isDark ? _dangerDark.withOpacity(0.15) : _dangerLight)
        : fill;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.0)),
      ),
      padding: const EdgeInsets.fromLTRB(_sp12, _sp10, _sp12, _sp10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic
          if (widget.speechOk)
            Padding(
              padding: const EdgeInsets.only(bottom: _sp4),
              child: Semantics(
                label: widget.isListening
                    ? 'Stop listening'
                    : 'Start voice input',
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: widget.onVoice,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: micBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isListening
                            ? micColor.withOpacity(0.40)
                            : border,
                        width: widget.isListening ? 1.5 : 1.0,
                      ),
                      boxShadow: widget.isListening
                          ? [
                              BoxShadow(
                                color: micColor.withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      size: 18,
                      color: micColor,
                    ),
                  ),
                ),
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
                border: Border.all(color: border, width: 1.0),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                enabled: !widget.isLoading,
                textInputAction: TextInputAction.newline,
                style: _body(14.5, textClr),
                decoration: InputDecoration(
                  hintText: widget.isListening
                      ? l.t('isl_input_listening')
                      : l.t('isl_input_hint'),
                  hintStyle: _body(14.5, hintClr),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: _sp16,
                    vertical: _sp12,
                  ),
                ),
                onSubmitted: (v) {
                  if (!widget.isLoading) widget.onSend(v);
                },
              ),
            ),
          ),

          const SizedBox(width: _sp8),

          // Send / loading
          Padding(
            padding: const EdgeInsets.only(bottom: _sp4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accent,
                        ),
                      ),
                    )
                  : Semantics(
                      key: const ValueKey('send'),
                      label: l.t('common_send_message'),
                      button: true,
                      child: GestureDetector(
                        onTap: () => widget.onSend(widget.controller.text),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: _hasText
                                ? LinearGradient(
                                    colors: [accent, accent.withOpacity(0.75)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _hasText
                                ? null
                                : (widget.isDark ? _dSurface2 : _lSurface2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _hasText ? Colors.transparent : border,
                              width: 1.0,
                            ),
                            boxShadow: _hasText
                                ? [
                                    BoxShadow(
                                      color: accent.withOpacity(0.30),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: _hasText
                                ? Colors.white
                                : (widget.isDark ? _dTextMuted : _lTextMuted),
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

// ══════════════════════════════════════════════════════════════════════
//  QUICK PROMPTS ROW
// ══════════════════════════════════════════════════════════════════════
class _QuickPromptsRow extends StatelessWidget {
  final bool isDark;
  final void Function(String) onTap;
  const _QuickPromptsRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys.map((q) => (l.t(q.$1), q.$2)).toList();
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final accent = isDark ? _infoDark : _info;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.0)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp8),
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        itemBuilder: (_, i) {
          final q = prompts[i];
          return Padding(
            padding: const EdgeInsets.only(right: _sp8),
            child: Semantics(
              label: q.$1,
              button: true,
              child: GestureDetector(
                onTap: () => onTap(q.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _sp12,
                    vertical: _sp6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withOpacity(0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(q.$2, size: 12, color: accent),
                      const SizedBox(width: _sp6),
                      Text(q.$1, style: _label(11.5, accent), maxLines: 1),
                    ],
                  ),
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
//  EMPTY STATE — Premium centered design
// ══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final void Function(String) onPrompt;
  const _EmptyState({required this.isDark, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys.map((q) => (l.t(q.$1), q.$2)).toList();
    final accent = isDark ? _purpleDark : _purple;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final chipAccent = isDark ? _infoDark : _info;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 48,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: _sp24),
            Text(l.t('assistant_title'), style: _display(26, textClr)),
            const SizedBox(height: _sp8),
            Text(
              l.t('isl_empty_subtitle'),
              style: _body(13.5, subClr),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _sp8),
            // ISL stats line
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: _sp6),
                Text(
                  '10 Indian Languages • Gemini AI',
                  style: _label(11, mutedClr, w: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: _sp24),
            Wrap(
              spacing: _sp8,
              runSpacing: _sp8,
              children: prompts
                  .take(4)
                  .map(
                    (q) => Semantics(
                      label: q.$1,
                      button: true,
                      child: GestureDetector(
                        onTap: () => onPrompt(q.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _sp14,
                            vertical: _sp8,
                          ),
                          decoration: BoxDecoration(
                            color: chipAccent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: chipAccent.withOpacity(0.20),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(q.$2, size: 13, color: chipAccent),
                              const SizedBox(width: _sp6),
                              Text(q.$1, style: _label(12, chipAccent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB SIDEBAR — Premium redesign
// ══════════════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final bool isDark, ttsEnabled;
  final String selectedLang;
  final void Function(String) onLangSelect;
  final VoidCallback onTtsToggle, onClearChat;
  final void Function(String) onQuickPrompt;
  const _WebSidebar({
    required this.isDark,
    required this.ttsEnabled,
    required this.selectedLang,
    required this.onLangSelect,
    required this.onTtsToggle,
    required this.onClearChat,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prompts = _kQuickPromptKeys.map((q) => (l.t(q.$1), q.$2)).toList();
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final sep = isDark ? _dBorderSub : _lBorderSub;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final accent = isDark ? _purpleDark : _purple;

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with gradient accent bar ────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sep, width: 1)),
            ),
            padding: const EdgeInsets.all(_sp20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sign_language_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: _sp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('assistant_title'),
                            style: _heading(16, textClr),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: _sp4),
                              Text(
                                'Online',
                                style: _label(
                                  10.5,
                                  Color(0xFF22C55E),
                                  w: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Language section ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(_sp16, _sp14, _sp16, _sp8),
            child: Text(
              'LANGUAGE',
              style: _label(
                9.5,
                mutedClr,
                w: FontWeight.w700,
              ).copyWith(letterSpacing: 1.2),
            ),
          ),

          // Language grid — 2 columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sp12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: _sp6,
              crossAxisSpacing: _sp6,
              childAspectRatio: 2.8,
              children: _kLangs.map((lang) {
                final active = lang.$1 == selectedLang;
                return Semantics(
                  selected: active,
                  button: true,
                  label: lang.$3,
                  child: GestureDetector(
                    onTap: () => onLangSelect(lang.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sp8,
                        vertical: _sp6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? accent.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? accent.withOpacity(0.30) : border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.$4, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: _sp4),
                          Expanded(
                            child: Text(
                              lang.$2,
                              style: _label(
                                11,
                                active ? accent : subClr,
                                w: active ? FontWeight.w700 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (active)
                            Icon(
                              Icons.check_circle_rounded,
                              color: accent,
                              size: 12,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Container(
            height: 1,
            color: sep,
            margin: const EdgeInsets.symmetric(
              vertical: _sp12,
              horizontal: _sp16,
            ),
          ),

          // ── Settings ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp8),
            child: Text(
              'SETTINGS',
              style: _label(
                9.5,
                mutedClr,
                w: FontWeight.w700,
              ).copyWith(letterSpacing: 1.2),
            ),
          ),
          _SidebarToggle(
            icon: ttsEnabled
                ? Icons.graphic_eq_rounded
                : Icons.volume_off_rounded,
            label: l.t('isl_sidebar_read_aloud'),
            value: ttsEnabled,
            isDark: isDark,
            accent: accent,
            onTap: onTtsToggle,
          ),

          Container(
            height: 1,
            color: sep,
            margin: const EdgeInsets.symmetric(
              vertical: _sp12,
              horizontal: _sp16,
            ),
          ),

          // ── Quick prompts ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(_sp16, 0, _sp16, _sp8),
            child: Text(
              'QUICK PROMPTS',
              style: _label(
                9.5,
                mutedClr,
                w: FontWeight.w700,
              ).copyWith(letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: _sp12),
              physics: const BouncingScrollPhysics(),
              itemCount: prompts.length,
              itemBuilder: (_, i) {
                final q = prompts[i];
                return _SidebarPromptBtn(
                  icon: q.$2,
                  label: q.$1,
                  isDark: isDark,
                  accent: isDark ? _infoDark : _info,
                  onTap: () => onQuickPrompt(q.$1),
                );
              },
            ),
          ),

          Container(height: 1, color: sep),
          // Clear chat
          Semantics(
            label: l.t('isl_options_clear_conversation'),
            button: true,
            child: InkWell(
              onTap: onClearChat,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp20,
                  vertical: _sp14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isDark ? _dangerDark : _danger).withOpacity(
                          0.10,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: isDark ? _dangerDark : _danger,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: _sp12),
                    Text(
                      l.t('isl_sidebar_clear_conversation'),
                      style: _body(
                        12.5,
                        isDark ? _dangerDark : _danger,
                        w: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value, isDark;
  final Color accent;
  final VoidCallback onTap;
  const _SidebarToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subClr = isDark ? _dTextSub : _lTextSub;
    return Semantics(
      toggled: value,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_sp16, _sp8, _sp16, _sp8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value
                      ? accent.withOpacity(0.12)
                      : (isDark ? _dSurface2 : _lSurface2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: value ? accent : subClr, size: 14),
              ),
              const SizedBox(width: _sp12),
              Expanded(child: Text(label, style: _body(12.5, subClr))),
              Container(
                width: 38,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? accent : (isDark ? _dSurface2 : _lSurface2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: value
                        ? Colors.transparent
                        : (isDark ? _dBorder : _lBorder),
                    width: 1,
                  ),
                ),
                child: AnimatedAlign(
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  const _SidebarPromptBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });
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
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(bottom: _sp4),
            padding: const EdgeInsets.symmetric(
              horizontal: _sp10,
              vertical: _sp8,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.accent.withOpacity(0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(_hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(widget.icon, size: 12, color: widget.accent),
                ),
                const SizedBox(width: _sp8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: _body(12, subClr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_hovered)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: widget.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB CHAT PANE — Premium
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
    required this.msgs,
    required this.isDark,
    required this.isLoading,
    required this.isListening,
    required this.speechOk,
    required this.typingAnim,
    required this.scrollCtrl,
    required this.inputCtrl,
    required this.onSend,
    required this.onVoice,
    required this.onTapSign,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dBg : _lBg;
    return Column(
      children: [
        Expanded(
          child: Container(
            color: bg,
            child: msgs.isEmpty
                ? _EmptyState(isDark: isDark, onPrompt: onSend)
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      _sp32,
                      _sp24,
                      _sp32,
                      _sp12,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: msgs.length + (isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == msgs.length) {
                        return _TypingIndicator(
                          isDark: isDark,
                          anim: typingAnim,
                        );
                      }
                      return _MsgBubble(
                        msg: msgs[i],
                        isDark: isDark,
                        onTapSign: onTapSign,
                        onSpeak: onSpeak,
                      );
                    },
                  ),
          ),
        ),
        _InputBar(
          controller: inputCtrl,
          isDark: isDark,
          isLoading: isLoading,
          isListening: isListening,
          speechOk: speechOk,
          onSend: onSend,
          onVoice: onVoice,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB TOP BAR (tablet) — refined
// ══════════════════════════════════════════════════════════════════════
class _WebTopBar extends StatelessWidget {
  final bool isDark, ttsEnabled;
  final String selectedLang;
  final void Function(String) onLangSelect;
  final VoidCallback onTtsToggle, onClearChat;
  const _WebTopBar({
    required this.isDark,
    required this.ttsEnabled,
    required this.selectedLang,
    required this.onLangSelect,
    required this.onTtsToggle,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final accent = isDark ? _purpleDark : _purple;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _sp20),
      child: Row(
        children: [
          // Horizontal scrollable lang pills
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _kLangs.length,
              itemBuilder: (_, i) {
                final lang = _kLangs[i];
                final active = lang.$1 == selectedLang;
                return Padding(
                  padding: const EdgeInsets.only(
                    right: _sp6,
                    top: _sp10,
                    bottom: _sp10,
                  ),
                  child: Semantics(
                    label: lang.$3,
                    selected: active,
                    button: true,
                    child: GestureDetector(
                      onTap: () => onLangSelect(lang.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp10,
                          vertical: _sp4,
                        ),
                        decoration: BoxDecoration(
                          color: active ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? accent : border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(lang.$4, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: _sp4),
                            Text(
                              lang.$2,
                              style: _label(
                                11,
                                active ? Colors.white : subClr,
                                w: active ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: _sp8),
          // TTS
          Semantics(
            label: ttsEnabled ? 'Mute' : 'Unmute',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTtsToggle,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ttsEnabled
                      ? accent.withOpacity(0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ttsEnabled ? accent.withOpacity(0.25) : border,
                    width: 1,
                  ),
                ),
                child: Icon(
                  ttsEnabled
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_off_rounded,
                  color: ttsEnabled ? accent : subClr,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: _sp8),
          // Clear
          Semantics(
            label: l.t('isl_options_clear_conversation'),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onClearChat,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 1),
                ),
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: isDark ? _dangerDark : _danger,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  OPTIONS MENU BUTTON (mobile 3-dot) — refined
// ══════════════════════════════════════════════════════════════════════
class _OptionsMenuButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;
  const _OptionsMenuButton({required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subClr = isDark ? _dTextSub : _lTextSub;
    final redClr = isDark ? _dangerDark : _danger;
    final bg = isDark ? _dSurface2 : _lSurface;
    final border = isDark ? _dBorder : _lBorder;

    return PopupMenuButton<String>(
      tooltip: l.t('isl_options_title'),
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: 1),
      ),
      elevation: 12,
      offset: const Offset(0, 44),
      icon: Icon(Icons.more_horiz_rounded, color: subClr, size: 20),
      onSelected: (v) {
        if (v == 'clear') onClear();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'clear',
          height: 44,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: redClr.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: redClr,
                  size: 14,
                ),
              ),
              const SizedBox(width: _sp12),
              Text(
                l.t('isl_options_clear_conversation'),
                style: _body(13.5, redClr, w: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'about',
          height: 44,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: subClr.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: subClr,
                  size: 14,
                ),
              ),
              const SizedBox(width: _sp12),
              Text(
                l.t('isl_options_about'),
                style: _body(13.5, subClr, w: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
