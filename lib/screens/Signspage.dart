// lib/screens/SignsPage.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Signs Page · Complete Redesign                            ║
// ║  "Learning Vault" — premium ISL reference & practice experience   ║
// ║                                                                    ║
// ║  Design language:                                                  ║
// ║  • Atmospheric background matching home / onboarding               ║
// ║  • Category collection headers (editorial-magazine layout)         ║
// ║  • Sign cards: bold symbol, gradient glow on hover/tap            ║
// ║  • Detail modal sheet: immersive full-screen sign view             ║
// ║  • Progress pill: tracks how many signs viewed this session        ║
// ║  • Web: 5-col masonry-feel grid, sticky sidebar filter            ║
// ║  • Mobile: horizontal scroll category rows + vertical sign list   ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────
const _ff = 'Plus Jakarta Sans';

// Brand palette
const _blue = Color(0xFF1A56DB);
const _blueDark = Color(0xFF4A8EFF);
const _teal = Color(0xFF00796B);
const _tealDark = Color(0xFF26A69A);
const _amber = Color(0xFF7A4800);
const _amberDark = Color(0xFFFFB300);
const _purple = Color(0xFF6200EA);
const _purpleDk = Color(0xFF9C6BFF);
const _green = Color(0xFF1B7340);
const _greenDk = Color(0xFF27AE60);

// Surfaces — light
const _lBg = Color(0xFFF0F4FB);
const _lSurf = Color(0xFFFFFFFF);
const _lSurf2 = Color(0xFFEEF2FA);
const _lBord = Color(0xFFCDD5DF);
const _lTxt = Color(0xFF0F172A);
const _lTxtSub = Color(0xFF334155);
const _lMuted = Color(0xFF64748B);

// Surfaces — dark
const _dBg = Color(0xFF0D1117);
const _dSurf = Color(0xFF161B22);
const _dSurf2 = Color(0xFF21262D);
const _dBord = Color(0xFF30363D);
const _dTxt = Color(0xFFE6EDF3);
const _dTxtSub = Color(0xFFB0BEC5);
const _dMuted = Color(0xFF8B949E);

// Spacing
const _s4 = 4.0;
const _s8 = 8.0;
const _s12 = 12.0;
const _s16 = 16.0;
const _s18 = 18.0;
const _s20 = 20.0;
const _s24 = 24.0;
const _s32 = 32.0;
const _s28 = 28.0;

final Uri _kIslrtcUri = Uri.parse('https://islrtc.nic.in/');

// Text styles
TextStyle _disp(double sz, Color c) => TextStyle(
  fontFamily: _ff,
  fontSize: sz,
  fontWeight: FontWeight.w800,
  color: c,
  height: 1.15,
  letterSpacing: -0.8,
);
TextStyle _head(double sz, Color c, {FontWeight w = FontWeight.w700}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.25,
      letterSpacing: -0.3,
    );
TextStyle _body(double sz, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.6,
    );
TextStyle _lbl(double sz, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(
      fontFamily: _ff,
      fontSize: sz,
      fontWeight: w,
      color: c,
      height: 1.4,
      letterSpacing: 0.1,
    );

// ─────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────
enum SignCategory { alphabet, numbers, words }

class _Sign {
  final String symbol;
  final IconData? icon;
  final String nameKey, meaningKey, descKey;
  final SignCategory cat;
  final Color lightAccent, darkAccent;

  const _Sign({
    this.symbol = '',
    this.icon,
    required this.nameKey,
    required this.meaningKey,
    required this.descKey,
    required this.cat,
    required this.lightAccent,
    required this.darkAccent,
  });

  Color accent(bool d) => d ? darkAccent : lightAccent;
  String get catKey {
    switch (cat) {
      case SignCategory.alphabet:
        return 'cat_alphabet';
      case SignCategory.numbers:
        return 'cat_numbers';
      case SignCategory.words:
        return 'cat_words';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
//  64 SIGN ENTRIES
// ─────────────────────────────────────────────────────────────────────
const List<_Sign> _kSigns = [
  // ALPHABET
  _Sign(
    symbol: 'A',
    nameKey: 'sign_a_name',
    meaningKey: 'sign_a_meaning',
    descKey: 'sign_a_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'B',
    nameKey: 'sign_b_name',
    meaningKey: 'sign_b_meaning',
    descKey: 'sign_b_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'C',
    nameKey: 'sign_c_name',
    meaningKey: 'sign_c_meaning',
    descKey: 'sign_c_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'D',
    nameKey: 'sign_d_name',
    meaningKey: 'sign_d_meaning',
    descKey: 'sign_d_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'E',
    nameKey: 'sign_e_name',
    meaningKey: 'sign_e_meaning',
    descKey: 'sign_e_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'F',
    nameKey: 'sign_f_name',
    meaningKey: 'sign_f_meaning',
    descKey: 'sign_f_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'G',
    nameKey: 'sign_g_name',
    meaningKey: 'sign_g_meaning',
    descKey: 'sign_g_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'H',
    nameKey: 'sign_h_name',
    meaningKey: 'sign_h_meaning',
    descKey: 'sign_h_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'I',
    nameKey: 'sign_i_name',
    meaningKey: 'sign_i_meaning',
    descKey: 'sign_i_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'J',
    nameKey: 'sign_j_name',
    meaningKey: 'sign_j_meaning',
    descKey: 'sign_j_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'K',
    nameKey: 'sign_k_name',
    meaningKey: 'sign_k_meaning',
    descKey: 'sign_k_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'L',
    nameKey: 'sign_l_name',
    meaningKey: 'sign_l_meaning',
    descKey: 'sign_l_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'M',
    nameKey: 'sign_m_name',
    meaningKey: 'sign_m_meaning',
    descKey: 'sign_m_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'N',
    nameKey: 'sign_n_name',
    meaningKey: 'sign_n_meaning',
    descKey: 'sign_n_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'O',
    nameKey: 'sign_o_name',
    meaningKey: 'sign_o_meaning',
    descKey: 'sign_o_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'P',
    nameKey: 'sign_p_name',
    meaningKey: 'sign_p_meaning',
    descKey: 'sign_p_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'Q',
    nameKey: 'sign_q_name',
    meaningKey: 'sign_q_meaning',
    descKey: 'sign_q_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'R',
    nameKey: 'sign_r_name',
    meaningKey: 'sign_r_meaning',
    descKey: 'sign_r_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'S',
    nameKey: 'sign_s_name',
    meaningKey: 'sign_s_meaning',
    descKey: 'sign_s_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'T',
    nameKey: 'sign_t_name',
    meaningKey: 'sign_t_meaning',
    descKey: 'sign_t_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'U',
    nameKey: 'sign_u_name',
    meaningKey: 'sign_u_meaning',
    descKey: 'sign_u_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'V',
    nameKey: 'sign_v_name',
    meaningKey: 'sign_v_meaning',
    descKey: 'sign_v_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'W',
    nameKey: 'sign_w_name',
    meaningKey: 'sign_w_meaning',
    descKey: 'sign_w_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'X',
    nameKey: 'sign_x_name',
    meaningKey: 'sign_x_meaning',
    descKey: 'sign_x_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'Y',
    nameKey: 'sign_y_name',
    meaningKey: 'sign_y_meaning',
    descKey: 'sign_y_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  _Sign(
    symbol: 'Z',
    nameKey: 'sign_z_name',
    meaningKey: 'sign_z_meaning',
    descKey: 'sign_z_desc',
    cat: SignCategory.alphabet,
    lightAccent: _blue,
    darkAccent: _blueDark,
  ),
  // NUMBERS
  _Sign(
    symbol: '0',
    nameKey: 'sign_0_name',
    meaningKey: 'sign_0_meaning',
    descKey: 'sign_0_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '1',
    nameKey: 'sign_1_name',
    meaningKey: 'sign_1_meaning',
    descKey: 'sign_1_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '2',
    nameKey: 'sign_2_name',
    meaningKey: 'sign_2_meaning',
    descKey: 'sign_2_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '3',
    nameKey: 'sign_3_name',
    meaningKey: 'sign_3_meaning',
    descKey: 'sign_3_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '4',
    nameKey: 'sign_4_name',
    meaningKey: 'sign_4_meaning',
    descKey: 'sign_4_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '5',
    nameKey: 'sign_5_name',
    meaningKey: 'sign_5_meaning',
    descKey: 'sign_5_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '6',
    nameKey: 'sign_6_name',
    meaningKey: 'sign_6_meaning',
    descKey: 'sign_6_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '7',
    nameKey: 'sign_7_name',
    meaningKey: 'sign_7_meaning',
    descKey: 'sign_7_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '8',
    nameKey: 'sign_8_name',
    meaningKey: 'sign_8_meaning',
    descKey: 'sign_8_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  _Sign(
    symbol: '9',
    nameKey: 'sign_9_name',
    meaningKey: 'sign_9_meaning',
    descKey: 'sign_9_desc',
    cat: SignCategory.numbers,
    lightAccent: _amber,
    darkAccent: _amberDark,
  ),
  // WORDS
  _Sign(
    icon: Icons.waving_hand_rounded,
    nameKey: 'sign_namaste_name',
    meaningKey: 'sign_namaste_meaning',
    descKey: 'sign_namaste_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.waving_hand_outlined,
    nameKey: 'sign_hello_name',
    meaningKey: 'sign_hello_meaning',
    descKey: 'sign_hello_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.back_hand_rounded,
    nameKey: 'sign_hi_name',
    meaningKey: 'sign_hi_meaning',
    descKey: 'sign_hi_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.help_outline_rounded,
    nameKey: 'sign_howareyou_name',
    meaningKey: 'sign_howareyou_meaning',
    descKey: 'sign_howareyou_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.do_not_disturb_on_rounded,
    nameKey: 'sign_quiet_name',
    meaningKey: 'sign_quiet_meaning',
    descKey: 'sign_quiet_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.volunteer_activism_rounded,
    nameKey: 'sign_thanks_name',
    meaningKey: 'sign_thanks_meaning',
    descKey: 'sign_thanks_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.restaurant_rounded,
    nameKey: 'sign_food_name',
    meaningKey: 'sign_food_meaning',
    descKey: 'sign_food_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.sign_language_rounded,
    nameKey: 'sign_iloveyou_name',
    meaningKey: 'sign_iloveyou_meaning',
    descKey: 'sign_iloveyou_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.people_rounded,
    nameKey: 'sign_brother_name',
    meaningKey: 'sign_brother_meaning',
    descKey: 'sign_brother_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.person_rounded,
    nameKey: 'sign_father_name',
    meaningKey: 'sign_father_meaning',
    descKey: 'sign_father_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.person_2_rounded,
    nameKey: 'sign_mother_name',
    meaningKey: 'sign_mother_meaning',
    descKey: 'sign_mother_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.water_drop_rounded,
    nameKey: 'sign_water_name',
    meaningKey: 'sign_water_meaning',
    descKey: 'sign_water_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.question_mark_rounded,
    nameKey: 'sign_what_name',
    meaningKey: 'sign_what_meaning',
    descKey: 'sign_what_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.front_hand_rounded,
    nameKey: 'sign_please_name',
    meaningKey: 'sign_please_meaning',
    descKey: 'sign_please_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.sos_rounded,
    nameKey: 'sign_help_name',
    meaningKey: 'sign_help_meaning',
    descKey: 'sign_help_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.volume_up_rounded,
    nameKey: 'sign_loud_name',
    meaningKey: 'sign_loud_meaning',
    descKey: 'sign_loud_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.person_pin_rounded,
    nameKey: 'sign_yours_name',
    meaningKey: 'sign_yours_meaning',
    descKey: 'sign_yours_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.bedtime_rounded,
    nameKey: 'sign_sleeping_name',
    meaningKey: 'sign_sleeping_meaning',
    descKey: 'sign_sleeping_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.badge_rounded,
    nameKey: 'sign_name_name',
    meaningKey: 'sign_name_meaning',
    descKey: 'sign_name_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.sentiment_dissatisfied_rounded,
    nameKey: 'sign_sorry_name',
    meaningKey: 'sign_sorry_meaning',
    descKey: 'sign_sorry_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.thumb_up_rounded,
    nameKey: 'sign_good_name',
    meaningKey: 'sign_good_meaning',
    descKey: 'sign_good_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.thumb_down_rounded,
    nameKey: 'sign_bad_name',
    meaningKey: 'sign_bad_meaning',
    descKey: 'sign_bad_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.calendar_today_rounded,
    nameKey: 'sign_today_name',
    meaningKey: 'sign_today_meaning',
    descKey: 'sign_today_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.access_time_rounded,
    nameKey: 'sign_time_name',
    meaningKey: 'sign_time_meaning',
    descKey: 'sign_time_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.fitness_center_rounded,
    nameKey: 'sign_strong_name',
    meaningKey: 'sign_strong_meaning',
    descKey: 'sign_strong_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.favorite_rounded,
    nameKey: 'sign_love_name',
    meaningKey: 'sign_love_meaning',
    descKey: 'sign_love_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.healing_rounded,
    nameKey: 'sign_bandaid_name',
    meaningKey: 'sign_bandaid_meaning',
    descKey: 'sign_bandaid_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
  _Sign(
    icon: Icons.sentiment_satisfied_rounded,
    nameKey: 'sign_happy_name',
    meaningKey: 'sign_happy_meaning',
    descKey: 'sign_happy_desc',
    cat: SignCategory.words,
    lightAccent: _teal,
    darkAccent: _tealDark,
  ),
];

// ─────────────────────────────────────────────────────────────────────
//  ATMOSPHERIC BG PAINTER  (same language as home + onboarding)
// ─────────────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final bool d;
  const _BgPainter(this.d);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final cB = d ? _blueDark : _blue;
    final cP = d ? _purpleDk : _purple;
    final cT = d ? _tealDark : _teal;

    void orb(Offset c, double r, Color col, double a) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [col.withValues(alpha: a), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    void ring(Offset c, double r, Color col, double a, double sw) =>
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = col.withValues(alpha: a)
            ..strokeWidth = sw
            ..style = PaintingStyle.stroke,
        );

    void dot(Offset c, double r, Color col, double a) =>
        canvas.drawCircle(c, r, Paint()..color = col.withValues(alpha: a));

    // Orbs
    orb(Offset(w * 1.08, -h * 0.05), w * 0.65, cB, d ? 0.13 : 0.09);
    orb(Offset(-w * 0.08, h * 1.08), w * 0.58, cP, d ? 0.10 : 0.07);
    orb(Offset(w * 0.10, h * 0.45), w * 0.25, cT, d ? 0.07 : 0.05);

    // Rings
    ring(Offset(w * 1.08, -h * 0.05), w * 0.75, cB, d ? 0.09 : 0.07, 1.0);
    ring(Offset(w * 1.08, -h * 0.05), w * 0.95, cB, d ? 0.05 : 0.04, 0.6);
    ring(Offset(-w * 0.08, h * 1.08), w * 0.65, cP, d ? 0.07 : 0.05, 0.8);

    // Float circles
    void fc(Offset c, double r, Color col, double a) {
      canvas.drawCircle(c, r, Paint()..color = col.withValues(alpha: a));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = col.withValues(alpha: a * 0.12)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    fc(Offset(w * 0.74, h * 0.08), w * 0.09, cB, d ? 0.15 : 0.10);
    fc(Offset(w * 0.92, h * 0.20), w * 0.05, cB, d ? 0.10 : 0.07);
    fc(Offset(w * 0.06, h * 0.28), w * 0.08, cP, d ? 0.12 : 0.08);
    fc(Offset(w * 0.16, h * 0.70), w * 0.12, cB, d ? 0.10 : 0.07);
    fc(Offset(w * 0.85, h * 0.65), w * 0.09, cP, d ? 0.10 : 0.07);
    fc(Offset(w * 0.40, h * 0.90), w * 0.07, cT, d ? 0.12 : 0.08);

    // Dots
    dot(Offset(w * 0.08, h * 0.15), 3.5, cB, d ? 0.32 : 0.22);
    dot(Offset(w * 0.88, h * 0.60), 2.5, cP, d ? 0.28 : 0.18);
    dot(Offset(w * 0.22, h * 0.85), 4.0, cT, d ? 0.25 : 0.16);
    dot(Offset(w * 0.76, h * 0.26), 2.8, cB, d ? 0.22 : 0.15);
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.d != d;
}

// ═════════════════════════════════════════════════════════════════════
//  PAGE
// ═════════════════════════════════════════════════════════════════════
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

class _SignsPageState extends State<SignsPage> with TickerProviderStateMixin {
  SignCategory? _cat; // null = all
  String _query = '';
  final Set<String> _viewed = {}; // session progress
  final _searchCtrl = TextEditingController();

  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  Future<void> _openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<_Sign> get _filtered {
    final q = _query.toLowerCase();
    return _kSigns.where((s) {
      final catOk = _cat == null || s.cat == _cat;
      return catOk &&
          (q.isEmpty ||
              s.nameKey.contains(q) ||
              s.symbol.toLowerCase().contains(q));
    }).toList();
  }

  void _markViewed(String key) {
    if (!_viewed.contains(key)) setState(() => _viewed.add(key));
  }

  void _openDetail(BuildContext ctx, _Sign sign, bool d, AppLocalizations l) {
    _markViewed(sign.nameKey);
    if (kIsWeb) {
      showDialog(
        context: ctx,
        barrierColor: Colors.black.withValues(alpha: d ? 0.68 : 0.48),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 26,
            vertical: 30,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: _SignDetailDialog(sign: sign, d: d, l: l),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SignDetailSheet(sign: sign, d: d, l: l),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final l = AppLocalizations.of(context);
    return kIsWeb || w >= 700
        ? _buildWeb(context, d, l, w)
        : _buildMobile(context, d, l);
  }

  // ════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool d, AppLocalizations l) {
    final bg = d ? _dBg : _lBg;
    final surf = d ? _dSurf : _lSurf;
    final bord = d ? _dBord : _lBord;
    final txt = d ? _dTxt : _lTxt;
    final muted = d ? _dMuted : _lMuted;
    final accent = d ? _blueDark : _blue;
    final filtered = _filtered;
    final progress = _kSigns.isEmpty ? 0.0 : _viewed.length / _kSigns.length;
    final mobileWidth = MediaQuery.of(ctx).size.width;
    final mobileCols = mobileWidth < 360 ? 1 : 2;
    final mobileTileExtent = mobileCols == 1
        ? 148.0
        : (mobileWidth < 420 ? 194.0 : 186.0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Atmospheric BG
          Positioned.fill(child: CustomPaint(painter: _BgPainter(d))),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar + hero + controls ───────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(_s16, _s10, _s16, _s12),
                  decoration: BoxDecoration(
                    color: surf.withValues(alpha: 0.90),
                    border: Border(bottom: BorderSide(color: bord, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: d ? _dSurf2 : _lSurf2,
                                border: Border.all(color: bord, width: 1),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: accent,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: _s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.t('nav_signs'), style: _head(17, txt)),
                                Text(
                                  '${_kSigns.length} ${l.t('signs_stat_total')}',
                                  style: _lbl(11, muted, w: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          _ProgressBadge(
                            progress: progress,
                            viewed: _viewed.length,
                            total: _kSigns.length,
                            d: d,
                          ),
                        ],
                      ),
                      const SizedBox(height: _s12),
                      _MobileSignsHero(
                        d: d,
                        l: l,
                        progress: progress,
                        viewed: _viewed.length,
                        total: _kSigns.length,
                        onOpenResource: () => _openExternal(_kIslrtcUri),
                      ),
                      const SizedBox(height: _s12),
                      _SearchField(
                        d: d,
                        ctrl: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: _s12),
                      _CategoryPills(
                        d: d,
                        selected: _cat,
                        l: l,
                        onSelect: (c) => setState(() {
                          _cat = c;
                          _entryCtrl.forward(from: 0.5);
                        }),
                      ),
                    ],
                  ),
                ),

                // ── Grid ────────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: filtered.isEmpty
                        ? _EmptyState(d: d)
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              _s16,
                              _s12,
                              _s16,
                              72,
                            ),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: mobileCols,
                                  mainAxisSpacing: _s12,
                                  crossAxisSpacing: _s12,
                                  mainAxisExtent: mobileTileExtent,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _SignTile(
                              sign: filtered[i],
                              d: d,
                              l: l,
                              webMode: false,
                              viewed: _viewed.contains(filtered[i].nameKey),
                              onTap: () => _openDetail(ctx, filtered[i], d, l),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  WEB LAYOUT
  // ════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool d, AppLocalizations l, double w) {
    final isWide = w > 1200;
    final compactWeb = w < 700;
    final bg = d ? _dBg : _lBg;
    final muted = d ? _dMuted : _lMuted;
    final filtered = _filtered;
    final hPad = isWide ? 64.0 : (compactWeb ? 16.0 : 30.0);
    final cols = isWide ? 4 : (w > 980 ? 3 : 2);
    final progress = _kSigns.isEmpty ? 0.0 : _viewed.length / _kSigns.length;
    final contentMax = isWide ? 1400.0 : 1160.0;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter(d))),
          SafeArea(
            child: Column(
              children: [
                // Navbar
                GlobalNavbar(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                  activeRoute: 'signs',
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMax),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Sticky sidebar ─────────────────────────────────────
                            if (isWide)
                              _WebSidebar(
                                d: d,
                                cat: _cat,
                                l: l,
                                viewed: _viewed.length,
                                total: _kSigns.length,
                                progress: progress,
                                onSelect: (c) => setState(() {
                                  _cat = c;
                                  _entryCtrl.forward(from: 0.5);
                                }),
                              ),

                            // ── Main content ──────────────────────────────────────
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  isWide ? _s32 : hPad,
                                  _s32,
                                  hPad,
                                  80,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hero header
                                    _WebHero(
                                      d: d,
                                      l: l,
                                      isWide: isWide,
                                      progress: progress,
                                      viewed: _viewed.length,
                                    ),
                                    const SizedBox(height: _s24),

                                    _WebControlDeck(
                                      d: d,
                                      selected: _cat,
                                      l: l,
                                      ctrl: _searchCtrl,
                                      filteredCount: filtered.length,
                                      totalCount: _kSigns.length,
                                      onChanged: (v) =>
                                          setState(() => _query = v),
                                      onSelect: (c) => setState(() {
                                        _cat = c;
                                      }),
                                      onOpenResource: () =>
                                          _openExternal(_kIslrtcUri),
                                    ),
                                    const SizedBox(height: _s20),

                                    // Results count
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(width: _s8),
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
                                          style: _lbl(
                                            12,
                                            muted,
                                            w: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: _s16),

                                    // Grid
                                    filtered.isEmpty
                                        ? _EmptyState(d: d)
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: cols,
                                                  mainAxisSpacing: _s16,
                                                  crossAxisSpacing: _s16,
                                                  childAspectRatio: 0.96,
                                                ),
                                            itemCount: filtered.length,
                                            itemBuilder: (_, i) => _SignTile(
                                              sign: filtered[i],
                                              d: d,
                                              l: l,
                                              webMode: true,
                                              viewed: _viewed.contains(
                                                filtered[i].nameKey,
                                              ),
                                              onTap: () => _openDetail(
                                                ctx,
                                                filtered[i],
                                                d,
                                                l,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  WEB HERO HEADER
// ─────────────────────────────────────────────────────────────────────
class _WebHero extends StatelessWidget {
  final bool d, isWide;
  final AppLocalizations l;
  final double progress;
  final int viewed;
  const _WebHero({
    required this.d,
    required this.l,
    required this.isWide,
    required this.progress,
    required this.viewed,
  });

  @override
  Widget build(BuildContext context) {
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    final muted = d ? _dMuted : _lMuted;
    final accent = d ? _blueDark : _blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, d ? _purpleDk : _purple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: _s8),
            Text(
              l.t('signs_library_label'),
              style: _lbl(10, muted, w: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: _s16),

        // Title
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Indian Sign\n',
                style: _disp(isWide ? 44 : 32, txt),
              ),
              TextSpan(
                text: 'Language',
                style: _disp(isWide ? 44 : 32, accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: _s12),

        Text(l.t('signs_subtitle'), style: _body(14, sub)),
        const SizedBox(height: _s24),

        // Stat row
        Wrap(
          spacing: _s12,
          runSpacing: _s12,
          children: [
            _StatCard(
              icon: Icons.sort_by_alpha_rounded,
              n: '26',
              label: l.t('signs_stat_alphabet'),
              color: d ? _blueDark : _blue,
              d: d,
            ),
            _StatCard(
              icon: Icons.tag_rounded,
              n: '10',
              label: l.t('signs_stat_numbers'),
              color: d ? _amberDark : _amber,
              d: d,
            ),
            _StatCard(
              icon: Icons.sign_language_rounded,
              n: '28',
              label: l.t('signs_stat_words'),
              color: d ? _tealDark : _teal,
              d: d,
            ),
            _StatCard(
              icon: Icons.auto_awesome_rounded,
              n: '$viewed',
              label: l.t('signs_stat_explored'),
              color: d ? _purpleDk : _purple,
              d: d,
              highlight: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String n, label;
  final Color color;
  final bool d, highlight;
  const _StatCard({
    required this.icon,
    required this.n,
    required this.label,
    required this.color,
    required this.d,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final surf = d ? _dSurf : _lSurf;
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _s16, vertical: _s12),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : surf,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.30) : color.withValues(alpha: 0.22),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: _s8),
          Text(
            n,
            style: _head(16, highlight ? color : txt, w: FontWeight.w800),
          ),
          const SizedBox(width: _s4),
          Text(label, style: _body(12, highlight ? color : sub)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  WEB SIDEBAR
// ─────────────────────────────────────────────────────────────────────
class _WebSidebar extends StatelessWidget {
  final bool d;
  final SignCategory? cat;
  final AppLocalizations l;
  final int viewed, total;
  final double progress;
  final void Function(SignCategory?) onSelect;
  const _WebSidebar({
    required this.d,
    required this.cat,
    required this.l,
    required this.viewed,
    required this.total,
    required this.progress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final surf = d ? _dSurf : _lSurf;
    final bord = d ? _dBord : _lBord;
    final muted = d ? _dMuted : _lMuted;

    final cats = [
      (null, l.t('cat_all'), Icons.apps_rounded, 64, d ? _blueDark : _blue),
      (
        SignCategory.alphabet,
        l.t('cat_alphabet'),
        Icons.sort_by_alpha_rounded,
        26,
        d ? _blueDark : _blue,
      ),
      (
        SignCategory.numbers,
        l.t('cat_numbers'),
        Icons.tag_rounded,
        10,
        d ? _amberDark : _amber,
      ),
      (
        SignCategory.words,
        l.t('cat_words'),
        Icons.sign_language_rounded,
        28,
        d ? _tealDark : _teal,
      ),
    ];

    return Container(
      width: 244,
      margin: const EdgeInsets.fromLTRB(_s24, _s24, 0, _s24),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bord, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: d ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('signs_categories_label'),
              style: _lbl(10, muted, w: FontWeight.w700),
            ),
            const SizedBox(height: _s16),

            ...cats.map(
              (c) => _SidebarItem(
                label: c.$2,
                icon: c.$3,
                count: c.$4,
                color: c.$5,
                active: cat == c.$1,
                d: d,
                onTap: () => onSelect(c.$1),
              ),
            ),

            const Spacer(),
            // Session progress
            Container(
              padding: const EdgeInsets.all(_s16),
              decoration: BoxDecoration(
                color: (d ? _purpleDk : _purple).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (d ? _purpleDk : _purple).withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: d ? _purpleDk : _purple,
                        size: 14,
                      ),
                      const SizedBox(width: _s8),
                      Text(
                        l.t('signs_progress_label'),
                        style: _lbl(
                          12,
                          d ? _purpleDk : _purple,
                          w: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _s8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: (d ? _purpleDk : _purple).withValues(alpha: 
                        0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation(
                        d ? _purpleDk : _purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: _s8),
                  Text(
                    l.t('signs_progress_count').replaceAll('{viewed}', '$viewed').replaceAll('{total}', '$total'),
                    style: _lbl(
                      11,
                      d ? _dTxtSub : _lTxtSub,
                      w: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final Color color;
  final bool active, d;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.active,
    required this.d,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    return Padding(
      padding: const EdgeInsets.only(bottom: _s4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: _s12, vertical: _s10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.28) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: active ? color : sub),
              const SizedBox(width: _s12),
              Expanded(
                child: Text(
                  label,
                  style: _lbl(
                    13,
                    active ? color : txt,
                    w: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: 0.15)
                      : (d ? _dSurf2 : _lSurf2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: _lbl(10, active ? color : sub, w: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  PROGRESS BADGE (mobile top bar)
// ─────────────────────────────────────────────────────────────────────
class _ProgressBadge extends StatelessWidget {
  final double progress;
  final int viewed, total;
  final bool d;
  const _ProgressBadge({
    required this.progress,
    required this.viewed,
    required this.total,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    final accent = d ? _purpleDk : _purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _s12, vertical: _s8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
                Text(
                  '${(progress * 100).toInt()}',
                  style: _lbl(8, accent, w: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: _s6),
          Text('$viewed/$total', style: _lbl(11, accent, w: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  CATEGORY PILLS
// ─────────────────────────────────────────────────────────────────────
class _CategoryPills extends StatelessWidget {
  final bool d;
  final SignCategory? selected;
  final AppLocalizations l;
  final void Function(SignCategory?) onSelect;
  const _CategoryPills({
    required this.d,
    required this.selected,
    required this.l,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (null, l.t('cat_all'), Icons.apps_rounded, d ? _blueDark : _blue, 64),
      (
        SignCategory.alphabet,
        l.t('cat_alphabet'),
        Icons.sort_by_alpha_rounded,
        d ? _blueDark : _blue,
        26,
      ),
      (
        SignCategory.numbers,
        l.t('cat_numbers'),
        Icons.tag_rounded,
        d ? _amberDark : _amber,
        10,
      ),
      (
        SignCategory.words,
        l.t('cat_words'),
        Icons.sign_language_rounded,
        d ? _tealDark : _teal,
        28,
      ),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _s16),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: _s8),
        itemBuilder: (_, i) {
          final it = items[i];
          final active = selected == it.$1;
          final color = it.$4;
          final bg = active ? color : Colors.transparent;
          final fgTxt = active ? Colors.white : (d ? _dTxtSub : _lMuted);
          final brdClr = active ? Colors.transparent : color.withValues(alpha: 0.30);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(it.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: _s16,
                vertical: _s6,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: brdClr, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(it.$3, size: 12, color: fgTxt),
                  const SizedBox(width: _s6),
                  Text(
                    it.$2,
                    style: _lbl(
                      12,
                      fgTxt,
                      w: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: _s6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.25)
                          : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${it.$5}',
                      style: _lbl(
                        9,
                        active ? Colors.white : color,
                        w: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  SEARCH FIELD
// ─────────────────────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  final bool d;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.d,
    required this.ctrl,
    required this.onChanged,
  });
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _MobileSignsHero extends StatelessWidget {
  final bool d;
  final AppLocalizations l;
  final double progress;
  final int viewed;
  final int total;
  final VoidCallback onOpenResource;
  const _MobileSignsHero({
    required this.d,
    required this.l,
    required this.progress,
    required this.viewed,
    required this.total,
    required this.onOpenResource,
  });

  @override
  Widget build(BuildContext context) {
    final accent = d ? _blueDark : _blue;
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: d
              ? [const Color(0xFF111E35), const Color(0xFF172746)]
              : [const Color(0xFFF8FBFF), const Color(0xFFEFF4FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('signs_learning_vault_title'),
                  style: _head(16, txt, w: FontWeight.w800),
                ),
                const SizedBox(height: _s4),
                Text(
                  l.t('signs_learning_vault_subtitle'),
                  style: _body(12, sub),
                ),
                const SizedBox(height: _s8),
                _ResourceActionButton(
                  d: d,
                  label: l.t('signs_islrtc_resources'),
                  icon: Icons.open_in_new_rounded,
                  onTap: onOpenResource,
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: _s12),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
                Text('$viewed', style: _lbl(11, accent, w: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: _s4),
          Text('/$total', style: _lbl(10, sub, w: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WebControlDeck extends StatelessWidget {
  final bool d;
  final SignCategory? selected;
  final AppLocalizations l;
  final TextEditingController ctrl;
  final int filteredCount;
  final int totalCount;
  final ValueChanged<String> onChanged;
  final void Function(SignCategory?) onSelect;
  final VoidCallback onOpenResource;
  const _WebControlDeck({
    required this.d,
    required this.selected,
    required this.l,
    required this.ctrl,
    required this.filteredCount,
    required this.totalCount,
    required this.onChanged,
    required this.onSelect,
    required this.onOpenResource,
  });

  @override
  Widget build(BuildContext context) {
    final surf = d ? _dSurf : _lSurf;
    final bord = d ? _dBord : _lBord;
    final sub = d ? _dTxtSub : _lTxtSub;
    return Container(
      padding: const EdgeInsets.all(_s16),
      decoration: BoxDecoration(
        color: surf.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bord, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: d ? 0.18 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$filteredCount/$totalCount',
                style: _lbl(12, sub, w: FontWeight.w700),
              ),
              const SizedBox(width: _s8),
              Text(
                l.t('signs_visible_label'),
                style: _lbl(11, sub, w: FontWeight.w500),
              ),
              const Spacer(),
              _ResourceActionButton(
                d: d,
                label: l.t('signs_islrtc_resources'),
                icon: Icons.open_in_new_rounded,
                onTap: onOpenResource,
              ),
            ],
          ),
          const SizedBox(height: _s12),
          _SearchField(d: d, ctrl: ctrl, onChanged: onChanged),
          const SizedBox(height: _s12),
          _CategoryPills(d: d, selected: selected, l: l, onSelect: onSelect),
        ],
      ),
    );
  }
}

class _ResourceActionButton extends StatefulWidget {
  final bool d;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  const _ResourceActionButton({
    required this.d,
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_ResourceActionButton> createState() => _ResourceActionButtonState();
}

class _ResourceActionButtonState extends State<_ResourceActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.d ? _blueDark : _blue;
    final surf = widget.d ? _dSurf2 : _lSurf;
    final bord = widget.d ? _dBord : _lBord;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? _s12 : _s16,
            vertical: widget.compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: _hover ? accent.withValues(alpha: 0.10) : surf,
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
            border: Border.all(
              color: _hover ? accent.withValues(alpha: 0.30) : bord,
              width: 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: widget.d ? 0.16 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(widget.label, style: _lbl(12, accent, w: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFieldState extends State<_SearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final surf = widget.d ? _dSurf2 : _lSurf;
    final bord = widget.d ? _dBord : _lBord;
    final txt = widget.d ? _dTxt : _lTxt;
    final hint = widget.d ? _dMuted : _lMuted;
    final focus = widget.d ? _blueDark : _blue;
    final sub = widget.d ? _dTxtSub : _lTxtSub;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? focus : bord,
            width: _focused ? 2 : 1,
          ),
          boxShadow: _focused
              ? [BoxShadow(color: focus.withValues(alpha: 0.12), blurRadius: 12)]
              : [],
        ),
        child: TextField(
          controller: widget.ctrl,
          onChanged: widget.onChanged,
          style: _body(15, txt),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).t('signs_search_hint'),
            hintStyle: _body(15, hint),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: _s16, right: _s8),
              child: Icon(
                Icons.search_rounded,
                color: _focused ? focus : sub,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: widget.ctrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      widget.ctrl.clear();
                      widget.onChanged('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: _s12),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: sub.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 12, color: sub),
                      ),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: _s14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  SIGN TILE  (replaces old flip card)
//  Premium card: bold symbol, category pill, glow on hover
// ─────────────────────────────────────────────────────────────────────
class _SignTile extends StatefulWidget {
  final _Sign sign;
  final bool d, viewed;
  final bool webMode;
  final AppLocalizations l;
  final VoidCallback onTap;
  const _SignTile({
    required this.sign,
    required this.d,
    required this.l,
    required this.viewed,
    required this.onTap,
    this.webMode = false,
  });
  @override
  State<_SignTile> createState() => _SignTileState();
}

class _SignTileState extends State<_SignTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final d = widget.d;
    final accent = sign.accent(d);
    final surf = d ? _dSurf : _lSurf;
    final bord = d ? _dBord : _lBord;
    final txt = d ? _dTxt : _lTxt;
    final muted = d ? _dMuted : _lMuted;

    final radius = widget.webMode ? 22.0 : 16.0;
    final badgeSize = widget.webMode ? 74.0 : 54.0;
    final symbolSize = widget.webMode ? 28.0 : 22.0;
    final titleSize = widget.webMode ? 14.0 : 12.5;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _scaleCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scaleCtrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(widget.webMode ? _s16 : _s12),
            transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [surf, surf],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: bord, width: 1.0),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: d ? 0.28 : 0.14),
                        blurRadius: widget.webMode ? 24 : 16,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: d ? 0.20 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Container(
                    width: widget.webMode ? 92 : 74,
                    height: widget.webMode ? 92 : 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [accent.withValues(alpha: 0.12), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: _hovered ? 0.95 : 0.78),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.webMode ? _s18 : _s16,
                    widget.webMode ? _s16 : _s14,
                    widget.webMode
                        ? (widget.viewed ? 86 : _s16)
                        : (widget.viewed ? 44 : _s12),
                    widget.webMode ? _s16 : _s12,
                  ),
                  child: widget.webMode
                      ? _buildWebBody(
                          sign,
                          accent,
                          surf,
                          bord,
                          txt,
                          muted,
                          badgeSize,
                          symbolSize,
                          titleSize,
                        )
                      : _buildMobileBody(
                          sign,
                          accent,
                          surf,
                          bord,
                          txt,
                          muted,
                          badgeSize,
                          symbolSize,
                          titleSize,
                        ),
                ),
                if (widget.viewed)
                  Positioned(
                    top: widget.webMode ? 14 : 10,
                    right: widget.webMode ? 14 : 10,
                    child: Container(
                      width: widget.webMode ? null : 22,
                      height: widget.webMode ? null : 22,
                      alignment: Alignment.center,
                      padding: widget.webMode
                          ? const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            )
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: widget.webMode
                          ? Text(
                              widget.l.t('signs_viewed_badge'),
                              style: _lbl(9, accent, w: FontWeight.w700),
                            )
                          : Icon(Icons.check_rounded, size: 13, color: accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebBody(
    _Sign sign,
    Color accent,
    Color surf,
    Color bord,
    Color txt,
    Color muted,
    double badgeSize,
    double symbolSize,
    double titleSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: _hovered ? 0.22 : 0.16),
                    accent.withValues(alpha: _hovered ? 0.10 : 0.06),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: _hovered ? 0.34 : 0.20),
                  width: 1,
                ),
              ),
              child: Center(
                child: sign.icon != null
                    ? Icon(sign.icon!, color: accent, size: symbolSize)
                    : Text(
                        sign.symbol,
                        style: TextStyle(
                          fontFamily: _ff,
                          fontSize: symbolSize,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          height: 1.0,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: _s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: _s6),
                      Text(
                        _catShort(sign.cat),
                        style: _lbl(10, accent, w: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: _s10),
                  Text(
                    widget.l.t(sign.nameKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _head(titleSize, txt, w: FontWeight.w800),
                  ),
                  const SizedBox(height: _s6),
                  Text(
                    widget.l.t(sign.meaningKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(11.5, muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: _s14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _s10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: surf == _lSurf ? _lSurf2 : _dSurf2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: bord, width: 1),
              ),
              child: Text(
                widget.l.t('signs_open_detail'),
                style: _lbl(10, muted, w: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_rounded, size: 15, color: accent),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileBody(
    _Sign sign,
    Color accent,
    Color surf,
    Color bord,
    Color txt,
    Color muted,
    double badgeSize,
    double symbolSize,
    double titleSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: _hovered ? 0.22 : 0.16),
                accent.withValues(alpha: _hovered ? 0.10 : 0.06),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: _hovered ? 0.34 : 0.20),
              width: 1,
            ),
          ),
          child: Center(
            child: sign.icon != null
                ? Icon(sign.icon!, color: accent, size: symbolSize)
                : Text(
                    sign.symbol,
                    style: TextStyle(
                      fontFamily: _ff,
                      fontSize: symbolSize,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: _s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: _s6),
                  Expanded(
                    child: Text(
                      _catShort(sign.cat),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _lbl(9, accent, w: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _s6),
              Text(
                widget.l.t(sign.nameKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _head(titleSize, txt, w: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                widget.l.t(sign.meaningKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _body(11, muted),
              ),
              const SizedBox(height: _s6),
              Row(
                children: [
                  Icon(Icons.open_in_new_rounded, size: 10, color: accent),
                  const SizedBox(width: _s4),
                  Expanded(
                    child: Text(
                      widget.l.t('signs_tap_to_open'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _lbl(8.5, accent, w: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _catShort(SignCategory c) {
    switch (c) {
      case SignCategory.alphabet:
        return widget.l.t('cat_alphabet');
      case SignCategory.numbers:
        return widget.l.t('cat_numbers');
      case SignCategory.words:
        return widget.l.t('cat_words');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
//  SIGN DETAIL BOTTOM SHEET  — immersive full detail view
// ─────────────────────────────────────────────────────────────────────
class _SignDetailSheet extends StatelessWidget {
  final _Sign sign;
  final bool d;
  final AppLocalizations l;
  const _SignDetailSheet({
    required this.sign,
    required this.d,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final accent = sign.accent(d);
    final surf = d ? _dSurf : _lSurf;
    final bord = d ? _dBord : _lBord;
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;

    return Container(
      decoration: BoxDecoration(
        color: surf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: bord, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: _s12, bottom: _s8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: bord,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Color accent header band
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: _s20),
            padding: const EdgeInsets.symmetric(vertical: _s24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: d ? 0.18 : 0.10),
                  accent.withValues(alpha: d ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
            ),
            child: Column(
              children: [
                // Large symbol / icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: sign.icon != null
                        ? Icon(sign.icon!, color: accent, size: 38)
                        : Text(
                            sign.symbol,
                            style: TextStyle(
                              fontFamily: _ff,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              height: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: _s16),
                Text(l.t(sign.nameKey), style: _head(22, txt)),
                const SizedBox(height: _s6),
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _s12,
                    vertical: _s4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Row(
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
                      const SizedBox(width: _s6),
                      Text(
                        _catLabel(sign.cat),
                        style: _lbl(11, accent, w: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(_s20),
            child: Column(
              children: [
                // Meaning
                _DetailRow(
                  icon: Icons.translate_rounded,
                  label: l.t('signs_detail_meaning'),
                  value: l.t(sign.meaningKey),
                  accent: accent,
                  d: d,
                ),
                const SizedBox(height: _s12),

                // Description
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: l.t('signs_detail_how_to_sign'),
                  value: l.t(sign.descKey),
                  accent: accent,
                  d: d,
                ),
                const SizedBox(height: _s20),

                // Practice prompt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(_s16),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam_rounded, color: accent, size: 18),
                      const SizedBox(width: _s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.t('signs_practice_title'),
                              style: _lbl(13, txt, w: FontWeight.w700),
                            ),
                            Text(
                              l.t('signs_practice_subtitle'),
                              style: _body(12, sub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + _s8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _catLabel(SignCategory c) {
    switch (c) {
      case SignCategory.alphabet:
        return l.t('cat_alphabet');
      case SignCategory.numbers:
        return l.t('cat_numbers');
      case SignCategory.words:
        return l.t('cat_words');
    }
  }
}

class _SignDetailDialog extends StatelessWidget {
  final _Sign sign;
  final bool d;
  final AppLocalizations l;
  const _SignDetailDialog({
    required this.sign,
    required this.d,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final accent = sign.accent(d);
    final surf = d ? _dSurf : _lSurf;
    final surf2 = d ? _dSurf2 : _lSurf2;
    final bord = d ? _dBord : _lBord;
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    final maxH = MediaQuery.of(context).size.height * 0.86;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [surf, surf2],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: bord, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: d ? 0.40 : 0.18),
                blurRadius: 44,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(_s20, _s16, _s20, _s12),
                decoration: BoxDecoration(
                  color: surf.withValues(alpha: 0.78),
                  border: Border(bottom: BorderSide(color: bord, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.24),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.sign_language_rounded,
                        size: 20,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: _s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('signs_detail_title'),
                            style: _head(16, txt, w: FontWeight.w800),
                          ),
                          Text(
                            l.t('signs_detail_subtitle'),
                            style: _lbl(11, sub, w: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: d ? _dSurf2 : _lSurf2,
                          shape: BoxShape.circle,
                          border: Border.all(color: bord, width: 1),
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: sub),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _SignDetailSheetContent(
                  sign: sign,
                  d: d,
                  l: l,
                  accent: accent,
                  txt: txt,
                  sub: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignDetailSheetContent extends StatelessWidget {
  final _Sign sign;
  final bool d;
  final AppLocalizations l;
  final Color accent;
  final Color txt;
  final Color sub;
  const _SignDetailSheetContent({
    required this.sign,
    required this.d,
    required this.l,
    required this.accent,
    required this.txt,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(_s20, _s20, _s20, _s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: _s28,
              horizontal: _s20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: d ? 0.20 : 0.12),
                  accent.withValues(alpha: d ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.36),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: d ? 0.22 : 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: sign.icon != null
                        ? Icon(sign.icon!, color: accent, size: 42)
                        : Text(
                            sign.symbol,
                            style: TextStyle(
                              fontFamily: _ff,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              height: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: _s16),
                Text(
                  l.t(sign.nameKey),
                  style: _head(24, txt, w: FontWeight.w800),
                ),
                const SizedBox(height: _s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _s12,
                    vertical: _s4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _catLabel(sign.cat),
                    style: _lbl(11, accent, w: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _s16),
          _DetailRow(
            icon: Icons.translate_rounded,
            label: l.t('signs_detail_meaning'),
            value: l.t(sign.meaningKey),
            accent: accent,
            d: d,
          ),
          const SizedBox(height: _s12),
          _DetailRow(
            icon: Icons.info_outline_rounded,
            label: l.t('signs_detail_how_to_sign'),
            value: l.t(sign.descKey),
            accent: accent,
            d: d,
          ),
          const SizedBox(height: _s16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_s16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(Icons.videocam_rounded, color: accent, size: 18),
                ),
                const SizedBox(width: _s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('signs_practice_title'),
                        style: _lbl(14, txt, w: FontWeight.w700),
                      ),
                      Text(
                        l.t('signs_practice_subtitle'),
                        style: _body(12, sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _catLabel(SignCategory c) {
    switch (c) {
      case SignCategory.alphabet:
        return l.t('cat_alphabet');
      case SignCategory.numbers:
        return l.t('cat_numbers');
      case SignCategory.words:
        return l.t('cat_words');
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  final bool d;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    final surf2 = d ? _dSurf2 : _lSurf2;
    final bord = d ? _dBord : _lBord;
    final txt = d ? _dTxt : _lTxt;
    final muted = d ? _dMuted : _lMuted;
    return Container(
      padding: const EdgeInsets.all(_s14),
      decoration: BoxDecoration(
        color: surf2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bord, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 13),
          ),
          const SizedBox(width: _s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: _lbl(9, muted, w: FontWeight.w700),
                ),
                const SizedBox(height: _s4),
                Text(value, style: _body(14, txt)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool d;
  const _EmptyState({required this.d});
  @override
  Widget build(BuildContext context) {
    final txt = d ? _dTxt : _lTxt;
    final sub = d ? _dTxtSub : _lTxtSub;
    final accent = d ? _blueDark : _blue;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.20), width: 1),
            ),
            child: Icon(Icons.search_off_rounded, color: sub, size: 28),
          ),
          const SizedBox(height: _s20),
          Text(
            AppLocalizations.of(context).t('signs_no_results'),
            style: _head(18, txt),
          ),
          const SizedBox(height: _s8),
          Text(
            AppLocalizations.of(context).t('signs_no_results_sub'),
            style: _body(13, sub),
          ),
        ],
      ),
    );
  }
}

// Extra spacing constants
const _s6 = 6.0;
const _s10 = 10.0;
const _s14 = 14.0;

