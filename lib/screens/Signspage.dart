// lib/screens/SignsPage.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Signs Page  · UX4G Redesign                               ║
// ║  Font: Google Sans (UX4G standard)                                ║
// ║                                                                    ║
// ║  UX4G Principles Applied:                                         ║
// ║  • Category filter: accessible segmented tabs with count badges   ║
// ║  • Search bar: clear focus state (2dp border, info color)         ║
// ║  • Card front: semantic category color, icon or letter            ║
// ║  • Card back: accessible on accent bg (WCAG AA)                   ║
// ║  • Web header: editorial with stat row                            ║
// ║  • Semantics() on flip cards and interactive elements             ║
// ║  • Flip accessible via keyboard tap / GestureDetector             ║
// ║  • Section count label (UX4G: orientation landmark)               ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────────────
//  UX4G DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Google Sans';

const _primary = Color(0xFF1A56DB);
const _primaryDark = Color(0xFF4A8EFF);
const _info = Color(0xFF0D47A1);
const _infoDark = Color(0xFF42A5F5);

// Category accent colors
const _catAlpha = Color(0xFF0D47A1); // Alphabet — info/blue
const _catAlphaD = Color(0xFF42A5F5);
const _catNum = Color(0xFF7A4800); // Numbers — warning/amber
const _catNumD = Color(0xFFFFB300);
const _catWord = Color(0xFF00796B); // Words — secondary/teal
const _catWordD = Color(0xFF26A69A);

// Surfaces
const _lBg = Color(0xFFF5F7FA);
const _lSurface = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF0F4F8);
const _lBorder = Color(0xFFCDD5DF);
const _lText = Color(0xFF111827);
const _lTextSub = Color(0xFF374151);
const _lTextMuted = Color(0xFF6B7280);

const _dBg = Color(0xFF0D1117);
const _dSurface = Color(0xFF161B22);
const _dSurface2 = Color(0xFF21262D);
const _dBorder = Color(0xFF30363D);
const _dText = Color(0xFFE6EDF3);
const _dTextSub = Color(0xFFB0BEC5);
const _dTextMuted = Color(0xFF8B949E);

const _sp4 = 4.0;
const _sp8 = 8.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;

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

// ═════════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═════════════════════════════════════════════════════════════════════
class _SignEntry {
  final String symbol;
  final IconData? wordIcon;
  final String nameKey, meaningKey, descKey, categoryKey;
  final Color accentLight, accentDark;

  const _SignEntry({
    this.symbol = '',
    this.wordIcon,
    required this.nameKey,
    required this.meaningKey,
    required this.descKey,
    required this.categoryKey,
    required this.accentLight,
    required this.accentDark,
  });

  Color accent(bool dark) => dark ? accentDark : accentLight;
  bool get isWord => categoryKey == 'cat_words';
}

// ═════════════════════════════════════════════════════════════════════
//  SIGN DATA — 64 entries
// ═════════════════════════════════════════════════════════════════════
const List<_SignEntry> _kSigns = [
  // ── ALPHABET ─────────────────────────────────────────────────────
  _SignEntry(
    symbol: 'A',
    nameKey: 'sign_a_name',
    meaningKey: 'sign_a_meaning',
    descKey: 'sign_a_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'B',
    nameKey: 'sign_b_name',
    meaningKey: 'sign_b_meaning',
    descKey: 'sign_b_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'C',
    nameKey: 'sign_c_name',
    meaningKey: 'sign_c_meaning',
    descKey: 'sign_c_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'D',
    nameKey: 'sign_d_name',
    meaningKey: 'sign_d_meaning',
    descKey: 'sign_d_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'E',
    nameKey: 'sign_e_name',
    meaningKey: 'sign_e_meaning',
    descKey: 'sign_e_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'F',
    nameKey: 'sign_f_name',
    meaningKey: 'sign_f_meaning',
    descKey: 'sign_f_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'G',
    nameKey: 'sign_g_name',
    meaningKey: 'sign_g_meaning',
    descKey: 'sign_g_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'H',
    nameKey: 'sign_h_name',
    meaningKey: 'sign_h_meaning',
    descKey: 'sign_h_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'I',
    nameKey: 'sign_i_name',
    meaningKey: 'sign_i_meaning',
    descKey: 'sign_i_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'J',
    nameKey: 'sign_j_name',
    meaningKey: 'sign_j_meaning',
    descKey: 'sign_j_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'K',
    nameKey: 'sign_k_name',
    meaningKey: 'sign_k_meaning',
    descKey: 'sign_k_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'L',
    nameKey: 'sign_l_name',
    meaningKey: 'sign_l_meaning',
    descKey: 'sign_l_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'M',
    nameKey: 'sign_m_name',
    meaningKey: 'sign_m_meaning',
    descKey: 'sign_m_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'N',
    nameKey: 'sign_n_name',
    meaningKey: 'sign_n_meaning',
    descKey: 'sign_n_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'O',
    nameKey: 'sign_o_name',
    meaningKey: 'sign_o_meaning',
    descKey: 'sign_o_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'P',
    nameKey: 'sign_p_name',
    meaningKey: 'sign_p_meaning',
    descKey: 'sign_p_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'Q',
    nameKey: 'sign_q_name',
    meaningKey: 'sign_q_meaning',
    descKey: 'sign_q_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'R',
    nameKey: 'sign_r_name',
    meaningKey: 'sign_r_meaning',
    descKey: 'sign_r_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'S',
    nameKey: 'sign_s_name',
    meaningKey: 'sign_s_meaning',
    descKey: 'sign_s_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'T',
    nameKey: 'sign_t_name',
    meaningKey: 'sign_t_meaning',
    descKey: 'sign_t_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'U',
    nameKey: 'sign_u_name',
    meaningKey: 'sign_u_meaning',
    descKey: 'sign_u_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'V',
    nameKey: 'sign_v_name',
    meaningKey: 'sign_v_meaning',
    descKey: 'sign_v_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'W',
    nameKey: 'sign_w_name',
    meaningKey: 'sign_w_meaning',
    descKey: 'sign_w_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'X',
    nameKey: 'sign_x_name',
    meaningKey: 'sign_x_meaning',
    descKey: 'sign_x_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'Y',
    nameKey: 'sign_y_name',
    meaningKey: 'sign_y_meaning',
    descKey: 'sign_y_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),
  _SignEntry(
    symbol: 'Z',
    nameKey: 'sign_z_name',
    meaningKey: 'sign_z_meaning',
    descKey: 'sign_z_desc',
    categoryKey: 'cat_alphabet',
    accentLight: _catAlpha,
    accentDark: _catAlphaD,
  ),

  // ── NUMBERS ──────────────────────────────────────────────────────
  _SignEntry(
    symbol: '0',
    nameKey: 'sign_0_name',
    meaningKey: 'sign_0_meaning',
    descKey: 'sign_0_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '1',
    nameKey: 'sign_1_name',
    meaningKey: 'sign_1_meaning',
    descKey: 'sign_1_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '2',
    nameKey: 'sign_2_name',
    meaningKey: 'sign_2_meaning',
    descKey: 'sign_2_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '3',
    nameKey: 'sign_3_name',
    meaningKey: 'sign_3_meaning',
    descKey: 'sign_3_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '4',
    nameKey: 'sign_4_name',
    meaningKey: 'sign_4_meaning',
    descKey: 'sign_4_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '5',
    nameKey: 'sign_5_name',
    meaningKey: 'sign_5_meaning',
    descKey: 'sign_5_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '6',
    nameKey: 'sign_6_name',
    meaningKey: 'sign_6_meaning',
    descKey: 'sign_6_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '7',
    nameKey: 'sign_7_name',
    meaningKey: 'sign_7_meaning',
    descKey: 'sign_7_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '8',
    nameKey: 'sign_8_name',
    meaningKey: 'sign_8_meaning',
    descKey: 'sign_8_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),
  _SignEntry(
    symbol: '9',
    nameKey: 'sign_9_name',
    meaningKey: 'sign_9_meaning',
    descKey: 'sign_9_desc',
    categoryKey: 'cat_numbers',
    accentLight: _catNum,
    accentDark: _catNumD,
  ),

  // ── WORDS ────────────────────────────────────────────────────────
  _SignEntry(
    wordIcon: Icons.waving_hand_rounded,
    nameKey: 'sign_namaste_name',
    meaningKey: 'sign_namaste_meaning',
    descKey: 'sign_namaste_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.waving_hand_outlined,
    nameKey: 'sign_hello_name',
    meaningKey: 'sign_hello_meaning',
    descKey: 'sign_hello_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.back_hand_rounded,
    nameKey: 'sign_hi_name',
    meaningKey: 'sign_hi_meaning',
    descKey: 'sign_hi_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.help_outline_rounded,
    nameKey: 'sign_howareyou_name',
    meaningKey: 'sign_howareyou_meaning',
    descKey: 'sign_howareyou_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.do_not_disturb_on_rounded,
    nameKey: 'sign_quiet_name',
    meaningKey: 'sign_quiet_meaning',
    descKey: 'sign_quiet_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.volunteer_activism_rounded,
    nameKey: 'sign_thanks_name',
    meaningKey: 'sign_thanks_meaning',
    descKey: 'sign_thanks_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.restaurant_rounded,
    nameKey: 'sign_food_name',
    meaningKey: 'sign_food_meaning',
    descKey: 'sign_food_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.sign_language_rounded,
    nameKey: 'sign_iloveyou_name',
    meaningKey: 'sign_iloveyou_meaning',
    descKey: 'sign_iloveyou_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.people_rounded,
    nameKey: 'sign_brother_name',
    meaningKey: 'sign_brother_meaning',
    descKey: 'sign_brother_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.person_rounded,
    nameKey: 'sign_father_name',
    meaningKey: 'sign_father_meaning',
    descKey: 'sign_father_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.person_2_rounded,
    nameKey: 'sign_mother_name',
    meaningKey: 'sign_mother_meaning',
    descKey: 'sign_mother_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.water_drop_rounded,
    nameKey: 'sign_water_name',
    meaningKey: 'sign_water_meaning',
    descKey: 'sign_water_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.question_mark_rounded,
    nameKey: 'sign_what_name',
    meaningKey: 'sign_what_meaning',
    descKey: 'sign_what_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.front_hand_rounded,
    nameKey: 'sign_please_name',
    meaningKey: 'sign_please_meaning',
    descKey: 'sign_please_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.sos_rounded,
    nameKey: 'sign_help_name',
    meaningKey: 'sign_help_meaning',
    descKey: 'sign_help_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.volume_up_rounded,
    nameKey: 'sign_loud_name',
    meaningKey: 'sign_loud_meaning',
    descKey: 'sign_loud_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.person_pin_rounded,
    nameKey: 'sign_yours_name',
    meaningKey: 'sign_yours_meaning',
    descKey: 'sign_yours_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.bedtime_rounded,
    nameKey: 'sign_sleeping_name',
    meaningKey: 'sign_sleeping_meaning',
    descKey: 'sign_sleeping_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.badge_rounded,
    nameKey: 'sign_name_name',
    meaningKey: 'sign_name_meaning',
    descKey: 'sign_name_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.sentiment_dissatisfied_rounded,
    nameKey: 'sign_sorry_name',
    meaningKey: 'sign_sorry_meaning',
    descKey: 'sign_sorry_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.thumb_up_rounded,
    nameKey: 'sign_good_name',
    meaningKey: 'sign_good_meaning',
    descKey: 'sign_good_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.thumb_down_rounded,
    nameKey: 'sign_bad_name',
    meaningKey: 'sign_bad_meaning',
    descKey: 'sign_bad_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.calendar_today_rounded,
    nameKey: 'sign_today_name',
    meaningKey: 'sign_today_meaning',
    descKey: 'sign_today_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.access_time_rounded,
    nameKey: 'sign_time_name',
    meaningKey: 'sign_time_meaning',
    descKey: 'sign_time_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.fitness_center_rounded,
    nameKey: 'sign_strong_name',
    meaningKey: 'sign_strong_meaning',
    descKey: 'sign_strong_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.favorite_rounded,
    nameKey: 'sign_love_name',
    meaningKey: 'sign_love_meaning',
    descKey: 'sign_love_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.healing_rounded,
    nameKey: 'sign_bandaid_name',
    meaningKey: 'sign_bandaid_meaning',
    descKey: 'sign_bandaid_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
  _SignEntry(
    wordIcon: Icons.sentiment_satisfied_rounded,
    nameKey: 'sign_happy_name',
    meaningKey: 'sign_happy_meaning',
    descKey: 'sign_happy_desc',
    categoryKey: 'cat_words',
    accentLight: _catWord,
    accentDark: _catWordD,
  ),
];

// ══════════════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════════════
class SignsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const SignsPage({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });
  @override
  State<SignsPage> createState() => _SignsPageState();
}

class _SignsPageState extends State<SignsPage>
    with SingleTickerProviderStateMixin {
  String _cat = 'all';
  String _query = '';
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SignEntry> _filtered(AppLocalizations l) => _kSigns.where((s) {
    final matchCat = _cat == 'all' || s.categoryKey == _cat;
    final q = _query.toLowerCase();
    final matchQ =
        q.isEmpty ||
        l.t(s.nameKey).toLowerCase().contains(q) ||
        l.t(s.meaningKey).toLowerCase().contains(q);
    return matchCat && matchQ;
  }).toList();

  void _switchCategory(String cat) {
    HapticFeedback.selectionClick();
    _entryCtrl.forward(from: 0.6);
    setState(() => _cat = cat);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final w = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark, l)
        : _buildWeb(context, isDark, l, w);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark, AppLocalizations l) {
    final bg = isDark ? _dBg : _lBg;
    final navBg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final navBlue = isDark ? _infoDark : _info;
    final filtered = _filtered(l);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Nav bar ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(_sp16, _sp12, _sp16, _sp12),
              decoration: BoxDecoration(
                color: navBg,
                border: Border(bottom: BorderSide(color: border, width: 1)),
              ),
              child: Row(
                children: [
                  Semantics(
                    label: l.t('common_back'),
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.pop(ctx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sp8,
                          vertical: _sp8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              color: navBlue,
                              size: 22,
                            ),
                            Text(
                              l.t('common_back'),
                              style: _body(15, navBlue, w: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    header: true,
                    child: Text(l.t('nav_signs'), style: _heading(16, textClr)),
                  ),
                  const Spacer(),
                  // Count badge — UX4G orientation landmark
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _sp12,
                      vertical: _sp4,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? _catAlphaD : _catAlpha).withOpacity(
                        0.10,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isDark ? _catAlphaD : _catAlpha).withOpacity(
                          0.25,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_kSigns.length}',
                      style: _label(
                        11,
                        isDark ? _catAlphaD : _catAlpha,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: _sp16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _sp16,
                            ),
                            child: _SearchBar(
                              isDark: isDark,
                              ctrl: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          const SizedBox(height: _sp12),
                          _FilterStrip(
                            isDark: isDark,
                            selected: _cat,
                            l: l,
                            onSelect: _switchCategory,
                          ),
                          const SizedBox(height: _sp16),
                          if (filtered.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                _sp20,
                                0,
                                _sp20,
                                _sp8,
                              ),
                              child: Semantics(
                                label: l
                                    .t('signs_showing_filtered')
                                    .replaceAll('{n}', '${filtered.length}')
                                    .replaceAll('{total}', '${_kSigns.length}'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: mutedClr,
                                      ),
                                    ),
                                    const SizedBox(width: _sp8),
                                    Text(
                                      l
                                          .t('signs_showing_filtered')
                                          .replaceAll(
                                            '{n}',
                                            '${filtered.length}',
                                          )
                                          .replaceAll(
                                            '{total}',
                                            '${_kSigns.length}',
                                          ),
                                      style: _label(
                                        11.5,
                                        mutedClr,
                                        w: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    filtered.isEmpty
                        ? SliverFillRemaining(
                            child: _EmptyState(isDark: isDark),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              _sp16,
                              _sp8,
                              _sp16,
                              _sp48,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _FlipCard(
                                  entry: filtered[i],
                                  isDark: isDark,
                                  l: l,
                                ),
                                childCount: filtered.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: _sp12,
                                    crossAxisSpacing: _sp12,
                                    childAspectRatio: 0.84,
                                  ),
                            ),
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

  // ════════════════════════════════════════════════════════════════════
  //  WEB / TABLET
  // ════════════════════════════════════════════════════════════════════
  Widget _buildWeb(
    BuildContext ctx,
    bool isDark,
    AppLocalizations l,
    double w,
  ) {
    final isDesktop = w > 1100;
    final hPad = isDesktop ? 80.0 : 40.0;
    final cols = isDesktop ? 6 : 4;
    final bg = isDark ? _dBg : _lBg;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final filtered = _filtered(l);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(
            children: [
              GlobalNavbar(
                toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale,
                activeRoute: 'signs',
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: _sp48),
                        _WebPageHeader(
                          isDark: isDark,
                          l: l,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: _sp32),
                        _SearchBar(
                          isDark: isDark,
                          ctrl: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: _sp20),
                        _FilterStrip(
                          isDark: isDark,
                          selected: _cat,
                          l: l,
                          onSelect: _switchCategory,
                        ),
                        const SizedBox(height: _sp24),
                        if (filtered.isNotEmpty)
                          Semantics(
                            label: l
                                .t('signs_showing_filtered')
                                .replaceAll('{n}', '${filtered.length}')
                                .replaceAll('{total}', '${_kSigns.length}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mutedClr,
                                  ),
                                ),
                                const SizedBox(width: _sp8),
                                Text(
                                  l
                                      .t('signs_showing_filtered')
                                      .replaceAll('{n}', '${filtered.length}')
                                      .replaceAll(
                                        '{total}',
                                        '${_kSigns.length}',
                                      ),
                                  style: _label(
                                    12,
                                    mutedClr,
                                    w: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: _sp16),
                        filtered.isEmpty
                            ? _EmptyState(isDark: isDark)
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: _sp16,
                                      crossAxisSpacing: _sp16,
                                      childAspectRatio: 0.82,
                                    ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _FlipCard(
                                  entry: filtered[i],
                                  isDark: isDark,
                                  l: l,
                                ),
                              ),
                        const SizedBox(height: 80),
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

// ══════════════════════════════════════════════════════════════════════
//  WEB PAGE HEADER — editorial + stat row
// ══════════════════════════════════════════════════════════════════════
class _WebPageHeader extends StatelessWidget {
  final bool isDark, isDesktop;
  final AppLocalizations l;
  const _WebPageHeader({
    required this.isDark,
    required this.l,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label (UX4G pattern)
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? _catAlphaD : _catAlpha,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: _sp8),
              Text(
                l.t('signs_title_highlight').toUpperCase(),
                style: _label(10, mutedClr, w: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: _sp16),

          // Title
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${l.t('signs_title_line1')}\n',
                  style: _display(isDesktop ? 40 : 30, textClr),
                ),
                TextSpan(
                  text: l.t('signs_title_line2'),
                  style: _display(
                    isDesktop ? 40 : 30,
                    isDark ? _catAlphaD : _catAlpha,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _sp12),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(l.t('signs_subtitle'), style: _body(14.5, subClr)),
          ),
          const SizedBox(height: _sp24),

          // Stat pills
          Wrap(
            spacing: _sp12,
            runSpacing: _sp12,
            children: [
              _StatPill(
                icon: Icons.sort_by_alpha_rounded,
                n: '26',
                label: l.t('signs_stat_alphabet'),
                color: isDark ? _catAlphaD : _catAlpha,
                isDark: isDark,
              ),
              _StatPill(
                icon: Icons.tag_rounded,
                n: '10',
                label: l.t('signs_stat_numbers'),
                color: isDark ? _catNumD : _catNum,
                isDark: isDark,
              ),
              _StatPill(
                icon: Icons.sign_language_rounded,
                n: '28',
                label: l.t('signs_stat_words'),
                color: isDark ? _catWordD : _catWord,
                isDark: isDark,
              ),
              _StatPill(
                icon: Icons.library_books_rounded,
                n: '${_kSigns.length}',
                label: l.t('signs_stat_total'),
                color: isDark ? _primaryDark : _primary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String n, label;
  final Color color;
  final bool isDark;
  const _StatPill({
    required this.icon,
    required this.n,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: _sp8),
          Text(n, style: _heading(14, textClr, w: FontWeight.w700)),
          const SizedBox(width: _sp4),
          Text(label, style: _body(12, subClr)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SEARCH BAR — UX4G: clear focus indicator (info color border)
// ══════════════════════════════════════════════════════════════════════
class _SearchBar extends StatefulWidget {
  final bool isDark;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({
    required this.isDark,
    required this.ctrl,
    required this.onChanged,
  });
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = widget.isDark ? _dSurface2 : _lSurface2;
    final border = widget.isDark ? _dBorder : _lBorder;
    final textClr = widget.isDark ? _dText : _lText;
    final hintClr = widget.isDark ? _dTextMuted : _lTextMuted;
    final subClr = widget.isDark ? _dTextSub : _lTextSub;
    final focusClr = widget.isDark ? _infoDark : _info;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? focusClr : border,
            width: _focused ? 2.0 : 1.0,
          ),
        ),
        child: TextField(
          controller: widget.ctrl,
          onChanged: widget.onChanged,
          style: _body(15, textClr),
          decoration: InputDecoration(
            hintText: l.t('signs_search_hint'),
            hintStyle: _body(15, hintClr),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: _sp16, right: _sp8),
              child: Icon(
                Icons.search_rounded,
                color: _focused ? focusClr : subClr,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: widget.ctrl.text.isNotEmpty
                ? Semantics(
                    label: l.t('common_clear'),
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        widget.ctrl.clear();
                        widget.onChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: _sp12),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: subClr.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: subClr,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: _sp16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  FILTER STRIP — segmented tabs with category counts
// ══════════════════════════════════════════════════════════════════════
class _FilterStrip extends StatelessWidget {
  final bool isDark;
  final String selected;
  final AppLocalizations l;
  final ValueChanged<String> onSelect;
  const _FilterStrip({
    required this.isDark,
    required this.selected,
    required this.l,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (
        'all',
        l.t('cat_all'),
        Icons.apps_rounded,
        isDark ? _primaryDark : _primary,
      ),
      (
        'cat_alphabet',
        l.t('cat_alphabet'),
        Icons.sort_by_alpha_rounded,
        isDark ? _catAlphaD : _catAlpha,
      ),
      (
        'cat_numbers',
        l.t('cat_numbers'),
        Icons.tag_rounded,
        isDark ? _catNumD : _catNum,
      ),
      (
        'cat_words',
        l.t('cat_words'),
        Icons.sign_language_rounded,
        isDark ? _catWordD : _catWord,
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _sp16),
        physics: const BouncingScrollPhysics(),
        children: filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: _sp8),
                child: _FilterChip(
                  key: ValueKey(f.$1),
                  label: f.$2,
                  icon: f.$3,
                  color: f.$4,
                  active: f.$1 == selected,
                  isDark: isDark,
                  count: f.$1 == 'all'
                      ? _kSigns.length
                      : _kSigns.where((s) => s.categoryKey == f.$1).length,
                  onTap: () => onSelect(f.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active, isDark;
  final int count;
  final VoidCallback onTap;
  const _FilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.isDark,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = active ? color : (isDark ? _dSurface : _lSurface);
    final textClr = active ? Colors.white : (isDark ? _dTextSub : _lTextSub);
    final borderClr = active ? Colors.transparent : color.withOpacity(0.25);

    return Semantics(
      selected: active,
      button: true,
      label: l.t('signs_showing_all').replaceAll('{n}', '$count'),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: _sp16,
            vertical: _sp4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: active ? Colors.white : (isDark ? _dTextSub : _lTextSub),
              ),
              const SizedBox(width: _sp8),
              Text(
                label,
                style: _label(
                  12.5,
                  textClr,
                  w: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: _sp8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sp8,
                  vertical: _sp4 * 0.5,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: _label(
                    9,
                    active ? Colors.white : color,
                    w: FontWeight.w700,
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

// ══════════════════════════════════════════════════════════════════════
//  FLIP CARD
// ══════════════════════════════════════════════════════════════════════
class _FlipCard extends StatefulWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _FlipCard({required this.entry, required this.isDark, required this.l});
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip(bool show) {
    if (show && !_flipped) {
      _ctrl.forward();
      _flipped = true;
    }
    if (!show && _flipped) {
      _ctrl.reverse();
      _flipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return MouseRegion(
      onEnter: (_) => _flip(true),
      onExit: (_) => _flip(false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        label: '${l.t(widget.entry.nameKey)} — ${l.t('signs_tap_flip')}',
        button: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _flip(!_flipped);
          },
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final angle = _anim.value * math.pi;
              final showBack = _anim.value > 0.5;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: showBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _CardBack(
                          entry: widget.entry,
                          isDark: widget.isDark,
                          l: l,
                        ),
                      )
                    : _CardFront(
                        entry: widget.entry,
                        isDark: widget.isDark,
                        l: l,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Card Front ────────────────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _CardFront({
    required this.entry,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent(isDark);
    final bg = isDark ? _dSurface : _lSurface;
    final border = isDark ? _dBorder : _lBorder;
    final textClr = isDark ? _dText : _lText;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Stack(
        children: [
          // Accent top bar (UX4G: category color indicator)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(_sp16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category dot + label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: _sp4),
                    Text(
                      l.t(entry.categoryKey),
                      style: _label(9, accent, w: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: _sp16),

                // Symbol / icon in bordered circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: entry.isWord
                        ? Icon(entry.wordIcon!, color: accent, size: 28)
                        : Text(
                            entry.symbol,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: _sp12),

                // Name
                Text(
                  l.t(entry.nameKey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _heading(13, textClr),
                ),
                const SizedBox(height: _sp12),

                // Flip hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 10, color: mutedClr),
                    const SizedBox(width: _sp4),
                    Text(
                      l.t('signs_tap_flip'),
                      style: _label(9, mutedClr, w: FontWeight.w400),
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
}

// ── Card Back ─────────────────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _CardBack({required this.entry, required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent(isDark);
    // Back text always uses dark text on light accent bg, or light text on dark
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;

    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_sp16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.30), width: 1),
              ),
              child: Icon(
                entry.isWord ? entry.wordIcon! : Icons.sign_language_rounded,
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(height: _sp8),

            // Name
            Text(
              l.t(entry.nameKey),
              textAlign: TextAlign.center,
              style: _heading(13, textClr),
            ),
            const SizedBox(height: _sp8),

            // Divider line
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withOpacity(0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: _sp8),

            // Meaning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: _sp8,
                vertical: _sp8,
              ),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.22), width: 1),
              ),
              child: Text(
                l.t(entry.meaningKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _label(12, accent, w: FontWeight.w700),
              ),
            ),
            const SizedBox(height: _sp8),

            // Description
            Expanded(
              child: Text(
                l.t(entry.descKey),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
                style: _body(10, subClr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textClr = isDark ? _dText : _lText;
    final subClr = isDark ? _dTextSub : _lTextSub;
    final accent = isDark ? _primaryDark : _primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.20), width: 1),
              ),
              child: Icon(Icons.search_off_rounded, color: subClr, size: 28),
            ),
            const SizedBox(height: _sp20),
            Text(l.t('signs_no_results'), style: _heading(17, textClr)),
            const SizedBox(height: _sp8),
            Text(l.t('signs_no_results_sub'), style: _body(13, subClr)),
          ],
        ),
      ),
    );
  }
}

const _sp48 = 48.0;
