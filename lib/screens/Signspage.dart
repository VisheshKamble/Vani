// ══════════════════════════════════════════════════════════════
//  FIX 2 — PREMIUM SIGNS PAGE  (full drop-in replacement)
//  lib/screens/SignsPage.dart
//
//  KEY CHANGES vs original:
//  • Words category: emoji symbols replaced with refined
//    icon-in-pill system using Material symbols — no emojis
//  • Card front: icon rendered inside a glassy tinted ring,
//    category shown as an accent dot row (no pill border spam)
//  • Card back: frosted glass tint, clear typographic hierarchy
//  • Filter strip: pill-segment with animated active indicator
//  • Search bar: iOS-style floating with focus glow ring
//  • Web header: large editorial title + accent stat row
//  • Google Sans throughout
//  • Fully dark-mode aware
// ══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─── Tokens ────────────────────────────────────────────────
const _blue     = Color(0xFF007AFF);
const _blue_D   = Color(0xFF0A84FF);
const _indigo   = Color(0xFF5856D6);
const _indigo_D = Color(0xFF5E5CE6);
const _orange   = Color(0xFFFF9500);
const _orange_D = Color(0xFFFF9F0A);
const _teal     = Color(0xFF32ADE6);
const _teal_D   = Color(0xFF5AC8F5);
const _purple   = Color(0xFFAF52DE);
const _purple_D = Color(0xFFBF5AF2);

const _kAlpha  = Color(0xFF5856D6);
const _kAlphaD = Color(0xFF5E5CE6);
const _kNum    = Color(0xFFFF9500);
const _kNumD   = Color(0xFFFF9F0A);
const _kWord   = Color(0xFF32ADE6);
const _kWordD  = Color(0xFF5AC8F5);

const _lBg      = Color(0xFFF2F2F7);
const _lSurface = Color(0xFFFFFFFF);
const _lSep     = Color(0xFFC6C6C8);
const _lLabel   = Color(0xFF000000);
const _lLabel2  = Color(0x993C3C43);
const _lLabel3  = Color(0x4D3C3C43);
const _lFill    = Color(0x1F787880);
const _dBg      = Color(0xFF000000);
const _dSurface = Color(0xFF1C1C1E);
const _dSurface2= Color(0xFF2C2C2E);
const _dSep     = Color(0xFF38383A);
const _dLabel   = Color(0xFFFFFFFF);
const _dLabel2  = Color(0x99EBEBF5);
const _dLabel3  = Color(0x4DEBEBF5);
const _dFill    = Color(0x3A787880);

TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c,
        letterSpacing: ls, height: h);

// ══════════════════════════════════════════════════════════════
//  DATA MODEL — icon replaces symbol for Words
// ══════════════════════════════════════════════════════════════
class _SignEntry {
  final String symbol;      // letter / digit string for A-Z / 0-9
  final IconData? wordIcon; // used for Words category instead of emoji
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

// ══════════════════════════════════════════════════════════════
//  SIGN DATA — 64 entries.
//  Words: replaced all emojis with curated Material icons.
// ══════════════════════════════════════════════════════════════
const List<_SignEntry> _kSigns = [
  // ── ALPHABET ───────────────────────────────────────────────
  _SignEntry(symbol:'A', nameKey:'sign_a_name', meaningKey:'sign_a_meaning', descKey:'sign_a_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'B', nameKey:'sign_b_name', meaningKey:'sign_b_meaning', descKey:'sign_b_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'C', nameKey:'sign_c_name', meaningKey:'sign_c_meaning', descKey:'sign_c_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'D', nameKey:'sign_d_name', meaningKey:'sign_d_meaning', descKey:'sign_d_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'E', nameKey:'sign_e_name', meaningKey:'sign_e_meaning', descKey:'sign_e_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'F', nameKey:'sign_f_name', meaningKey:'sign_f_meaning', descKey:'sign_f_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'G', nameKey:'sign_g_name', meaningKey:'sign_g_meaning', descKey:'sign_g_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'H', nameKey:'sign_h_name', meaningKey:'sign_h_meaning', descKey:'sign_h_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'I', nameKey:'sign_i_name', meaningKey:'sign_i_meaning', descKey:'sign_i_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'J', nameKey:'sign_j_name', meaningKey:'sign_j_meaning', descKey:'sign_j_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'K', nameKey:'sign_k_name', meaningKey:'sign_k_meaning', descKey:'sign_k_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'L', nameKey:'sign_l_name', meaningKey:'sign_l_meaning', descKey:'sign_l_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'M', nameKey:'sign_m_name', meaningKey:'sign_m_meaning', descKey:'sign_m_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'N', nameKey:'sign_n_name', meaningKey:'sign_n_meaning', descKey:'sign_n_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'O', nameKey:'sign_o_name', meaningKey:'sign_o_meaning', descKey:'sign_o_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'P', nameKey:'sign_p_name', meaningKey:'sign_p_meaning', descKey:'sign_p_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'Q', nameKey:'sign_q_name', meaningKey:'sign_q_meaning', descKey:'sign_q_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'R', nameKey:'sign_r_name', meaningKey:'sign_r_meaning', descKey:'sign_r_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'S', nameKey:'sign_s_name', meaningKey:'sign_s_meaning', descKey:'sign_s_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'T', nameKey:'sign_t_name', meaningKey:'sign_t_meaning', descKey:'sign_t_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'U', nameKey:'sign_u_name', meaningKey:'sign_u_meaning', descKey:'sign_u_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'V', nameKey:'sign_v_name', meaningKey:'sign_v_meaning', descKey:'sign_v_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'W', nameKey:'sign_w_name', meaningKey:'sign_w_meaning', descKey:'sign_w_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'X', nameKey:'sign_x_name', meaningKey:'sign_x_meaning', descKey:'sign_x_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'Y', nameKey:'sign_y_name', meaningKey:'sign_y_meaning', descKey:'sign_y_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),
  _SignEntry(symbol:'Z', nameKey:'sign_z_name', meaningKey:'sign_z_meaning', descKey:'sign_z_desc', categoryKey:'cat_alphabet', accentLight:_kAlpha, accentDark:_kAlphaD),

  // ── NUMBERS ────────────────────────────────────────────────
  _SignEntry(symbol:'0', nameKey:'sign_0_name', meaningKey:'sign_0_meaning', descKey:'sign_0_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'1', nameKey:'sign_1_name', meaningKey:'sign_1_meaning', descKey:'sign_1_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'2', nameKey:'sign_2_name', meaningKey:'sign_2_meaning', descKey:'sign_2_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'3', nameKey:'sign_3_name', meaningKey:'sign_3_meaning', descKey:'sign_3_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'4', nameKey:'sign_4_name', meaningKey:'sign_4_meaning', descKey:'sign_4_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'5', nameKey:'sign_5_name', meaningKey:'sign_5_meaning', descKey:'sign_5_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'6', nameKey:'sign_6_name', meaningKey:'sign_6_meaning', descKey:'sign_6_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'7', nameKey:'sign_7_name', meaningKey:'sign_7_meaning', descKey:'sign_7_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'8', nameKey:'sign_8_name', meaningKey:'sign_8_meaning', descKey:'sign_8_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),
  _SignEntry(symbol:'9', nameKey:'sign_9_name', meaningKey:'sign_9_meaning', descKey:'sign_9_desc', categoryKey:'cat_numbers', accentLight:_kNum, accentDark:_kNumD),

  // ── WORDS — all using refined Material icons ────────────────
  _SignEntry(wordIcon: Icons.waving_hand_rounded,          nameKey:'sign_namaste_name',   meaningKey:'sign_namaste_meaning',   descKey:'sign_namaste_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.waving_hand_outlined,         nameKey:'sign_hello_name',     meaningKey:'sign_hello_meaning',     descKey:'sign_hello_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.back_hand_rounded,            nameKey:'sign_hi_name',        meaningKey:'sign_hi_meaning',        descKey:'sign_hi_desc',        categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.help_outline_rounded,         nameKey:'sign_howareyou_name', meaningKey:'sign_howareyou_meaning', descKey:'sign_howareyou_desc', categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.do_not_disturb_on_rounded,   nameKey:'sign_quiet_name',     meaningKey:'sign_quiet_meaning',     descKey:'sign_quiet_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.volunteer_activism_rounded,  nameKey:'sign_thanks_name',    meaningKey:'sign_thanks_meaning',    descKey:'sign_thanks_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.restaurant_rounded,          nameKey:'sign_food_name',      meaningKey:'sign_food_meaning',      descKey:'sign_food_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.sign_language_rounded,       nameKey:'sign_iloveyou_name',  meaningKey:'sign_iloveyou_meaning',  descKey:'sign_iloveyou_desc',  categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.people_rounded,              nameKey:'sign_brother_name',   meaningKey:'sign_brother_meaning',   descKey:'sign_brother_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.person_rounded,              nameKey:'sign_father_name',    meaningKey:'sign_father_meaning',    descKey:'sign_father_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.person_2_rounded,            nameKey:'sign_mother_name',    meaningKey:'sign_mother_meaning',    descKey:'sign_mother_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.water_drop_rounded,          nameKey:'sign_water_name',     meaningKey:'sign_water_meaning',     descKey:'sign_water_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.question_mark_rounded,       nameKey:'sign_what_name',      meaningKey:'sign_what_meaning',      descKey:'sign_what_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.front_hand_rounded,          nameKey:'sign_please_name',    meaningKey:'sign_please_meaning',    descKey:'sign_please_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.sos_rounded,                 nameKey:'sign_help_name',      meaningKey:'sign_help_meaning',      descKey:'sign_help_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.volume_up_rounded,           nameKey:'sign_loud_name',      meaningKey:'sign_loud_meaning',      descKey:'sign_loud_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.person_pin_rounded,          nameKey:'sign_yours_name',     meaningKey:'sign_yours_meaning',     descKey:'sign_yours_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.bedtime_rounded,             nameKey:'sign_sleeping_name',  meaningKey:'sign_sleeping_meaning',  descKey:'sign_sleeping_desc',  categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.badge_rounded,               nameKey:'sign_name_name',      meaningKey:'sign_name_meaning',      descKey:'sign_name_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.sentiment_dissatisfied_rounded, nameKey:'sign_sorry_name',  meaningKey:'sign_sorry_meaning',     descKey:'sign_sorry_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.thumb_up_rounded,            nameKey:'sign_good_name',      meaningKey:'sign_good_meaning',      descKey:'sign_good_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.thumb_down_rounded,          nameKey:'sign_bad_name',       meaningKey:'sign_bad_meaning',       descKey:'sign_bad_desc',       categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.calendar_today_rounded,      nameKey:'sign_today_name',     meaningKey:'sign_today_meaning',     descKey:'sign_today_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.access_time_rounded,         nameKey:'sign_time_name',      meaningKey:'sign_time_meaning',      descKey:'sign_time_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.fitness_center_rounded,      nameKey:'sign_strong_name',    meaningKey:'sign_strong_meaning',    descKey:'sign_strong_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.favorite_rounded,            nameKey:'sign_love_name',      meaningKey:'sign_love_meaning',      descKey:'sign_love_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.healing_rounded,             nameKey:'sign_bandaid_name',   meaningKey:'sign_bandaid_meaning',   descKey:'sign_bandaid_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(wordIcon: Icons.sentiment_satisfied_rounded, nameKey:'sign_happy_name',     meaningKey:'sign_happy_meaning',     descKey:'sign_happy_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
];

// ══════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════
class SignsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const SignsPage({super.key, required this.toggleTheme, required this.setLocale});
  @override State<SignsPage> createState() => _SignsPageState();
}

class _SignsPageState extends State<SignsPage>
    with SingleTickerProviderStateMixin {
  String _cat   = 'all';
  String _query = '';
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  List<_SignEntry> _filtered(AppLocalizations l) =>
      _kSigns.where((s) {
        final matchCat = _cat == 'all' || s.categoryKey == _cat;
        final q = _query.toLowerCase();
        final matchQ = q.isEmpty ||
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
    final l      = AppLocalizations.of(context);
    final w      = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, isDark, l)
        : _buildWeb(context, isDark, l, w);
  }

  // ════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark, AppLocalizations l) {
    final bg    = isDark ? _dBg      : _lBg;
    final navBg = isDark ? _dSurface : _lSurface;
    final sep   = isDark ? _dSep     : _lSep.withOpacity(0.5);
    final label = isDark ? _dLabel   : _lLabel;
    final blueA = isDark ? _blue_D   : _blue;
    final filtered = _filtered(l);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [

          // ── iOS navigation bar ──────────────────────────
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                    color: navBg.withOpacity(0.88),
                    border: Border(bottom: BorderSide(color: sep, width: 0.5))),
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
                child: Row(children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chevron_left_rounded, color: blueA, size: 26),
                        Text('Back', style: _t(15, FontWeight.w400, blueA)),
                      ]),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text('ISL Signs',
                      style: _t(16, FontWeight.w600, label, ls: -0.2)),

                  const Spacer(),

                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: (isDark ? _kAlphaD : _kAlpha).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: (isDark ? _kAlphaD : _kAlpha).withOpacity(0.22),
                            width: 0.5)),
                    child: Text('${_kSigns.length}',
                        style: _t(11, FontWeight.w600,
                            isDark ? _kAlphaD : _kAlpha)),
                  ),
                ]),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _entryFade,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: Column(children: [
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PremiumSearchBar(
                          isDark: isDark, ctrl: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v)),
                    ),
                    const SizedBox(height: 12),
                    _PremiumFilterStrip(
                        isDark: isDark, selected: _cat, l: l,
                        onSelect: _switchCategory),
                    const SizedBox(height: 14),
                    if (filtered.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                        child: Row(children: [
                          Container(width: 4, height: 4,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? _dLabel3 : _lLabel3)),
                          const SizedBox(width: 6),
                          Text('${filtered.length} of ${_kSigns.length} signs',
                              style: _t(11.5, FontWeight.w500,
                                  isDark ? _dLabel3 : _lLabel3, ls: 0.1)),
                        ]),
                      ),
                  ])),

                  filtered.isEmpty
                      ? SliverFillRemaining(child: _EmptyState(isDark: isDark))
                      : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _PremiumFlipCard(
                            entry: filtered[i], isDark: isDark, l: l),
                        childCount: filtered.length,
                      ),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.84,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  WEB / TABLET
  // ════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, bool isDark, AppLocalizations l, double w) {
    final isDesktop = w > 1100;
    final hPad      = isDesktop ? 88.0 : 44.0;
    final cols      = isDesktop ? 6 : 4;
    final bg        = isDark ? _dBg : _lBg;
    final filtered  = _filtered(l);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            GlobalNavbar(toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale, activeRoute: 'signs'),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 52),
                      _WebHeader(isDark: isDark, l: l, isDesktop: isDesktop),
                      const SizedBox(height: 32),
                      _PremiumSearchBar(
                          isDark: isDark, ctrl: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v)),
                      const SizedBox(height: 18),
                      _PremiumFilterStrip(
                          isDark: isDark, selected: _cat, l: l,
                          onSelect: _switchCategory),
                      const SizedBox(height: 22),
                      if (filtered.isNotEmpty)
                        Row(children: [
                          Container(width: 4, height: 4,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? _dLabel3 : _lLabel3)),
                          const SizedBox(width: 6),
                          Text('${filtered.length} of ${_kSigns.length} signs',
                              style: _t(12, FontWeight.w500,
                                  isDark ? _dLabel3 : _lLabel3, ls: 0.2)),
                        ]),
                      const SizedBox(height: 16),
                      filtered.isEmpty
                          ? _EmptyState(isDark: isDark)
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _PremiumFlipCard(
                            entry: filtered[i], isDark: isDark, l: l),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB HEADER  — editorial, large title
// ══════════════════════════════════════════════════════════════
class _WebHeader extends StatelessWidget {
  final bool isDark, isDesktop;
  final AppLocalizations l;
  const _WebHeader({required this.isDark, required this.l, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final label3 = isDark ? _dLabel3 : _lLabel3;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Eyebrow
      Row(children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(
                color: isDark ? _kAlphaD : _kAlpha,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text('SIGNS LIBRARY',
            style: _t(10, FontWeight.w600, label3, ls: 1.4)),
      ]),

      const SizedBox(height: 14),

      // Title
      RichText(text: TextSpan(children: [
        TextSpan(
            text: 'Indian Sign\n',
            style: _t(isDesktop ? 42 : 32, FontWeight.w700, label, ls: -1.2, h: 1.05)),
        TextSpan(
            text: 'Language',
            style: _t(isDesktop ? 42 : 32, FontWeight.w700,
                isDark ? _kAlphaD : _kAlpha, ls: -1.2, h: 1.05)),
      ])),

      const SizedBox(height: 12),

      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Text(l.t('signs_subtitle'),
            style: _t(14.5, FontWeight.w400, label2, ls: -0.1, h: 1.65)),
      ),

      const SizedBox(height: 22),

      // Stat pills — no emojis, clean icon+text
      Wrap(spacing: 10, runSpacing: 10, children: [
        _StatPill(icon: Icons.sort_by_alpha_rounded, n: '26',
            label: 'Alphabet', color: isDark ? _kAlphaD : _kAlpha, isDark: isDark),
        _StatPill(icon: Icons.tag_rounded, n: '10',
            label: 'Numbers', color: isDark ? _kNumD : _kNum, isDark: isDark),
        _StatPill(icon: Icons.sign_language_rounded, n: '28',
            label: 'Common Words', color: isDark ? _kWordD : _kWord, isDark: isDark),
        _StatPill(icon: Icons.library_books_rounded, n: '${_kSigns.length}',
            label: 'Total', color: isDark ? _blue_D : _blue, isDark: isDark),
      ]),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String n, label;
  final Color color;
  final bool isDark;
  const _StatPill({required this.icon, required this.n,
    required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface : _lSurface;
    final label2 = isDark ? _dLabel2  : _lLabel2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 12)),
        const SizedBox(width: 8),
        Text(n, style: _t(14, FontWeight.w700, isDark ? _dLabel : _lLabel)),
        const SizedBox(width: 5),
        Text(label, style: _t(11.5, FontWeight.w400, label2)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SEARCH BAR  — refined frosted glass
// ══════════════════════════════════════════════════════════════
class _PremiumSearchBar extends StatefulWidget {
  final bool isDark;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _PremiumSearchBar({required this.isDark, required this.ctrl,
    required this.onChanged});
  @override State<_PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<_PremiumSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final fill   = widget.isDark ? _dFill    : _lFill;
    final label  = widget.isDark ? _dLabel   : _lLabel;
    final label3 = widget.isDark ? _dLabel3  : _lLabel3;
    final accent = widget.isDark ? _blue_D   : _blue;
    final label2 = widget.isDark ? _dLabel2  : _lLabel2;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _focused ? accent.withOpacity(0.55) : Colors.transparent,
                width: 1.5),
            boxShadow: _focused ? [
              BoxShadow(color: accent.withOpacity(0.12),
                  blurRadius: 16, offset: const Offset(0, 4)),
            ] : []),
        child: TextField(
          controller: widget.ctrl,
          onChanged: widget.onChanged,
          style: _t(15, FontWeight.w400, label),
          decoration: InputDecoration(
            hintText: 'Search signs…',
            hintStyle: _t(15, FontWeight.w400, label3),
            prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(Icons.search_rounded,
                    color: _focused ? accent : label2, size: 18)),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: widget.ctrl.text.isNotEmpty
                ? GestureDetector(
                onTap: () { widget.ctrl.clear(); widget.onChanged(''); },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                          color: label2.withOpacity(0.22),
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 11, color: label2)),
                )) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FILTER STRIP  — segmented control style
// ══════════════════════════════════════════════════════════════
class _PremiumFilterStrip extends StatelessWidget {
  final bool isDark;
  final String selected;
  final AppLocalizations l;
  final ValueChanged<String> onSelect;
  const _PremiumFilterStrip({required this.isDark, required this.selected,
    required this.l, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all',          'All',    Icons.apps_rounded,          isDark ? _blue_D  : _blue),
      ('cat_alphabet', 'A–Z',   Icons.sort_by_alpha_rounded, isDark ? _kAlphaD : _kAlpha),
      ('cat_numbers',  '0–9',   Icons.tag_rounded,           isDark ? _kNumD   : _kNum),
      ('cat_words',    'Words', Icons.sign_language_rounded,  isDark ? _kWordD  : _kWord),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
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
              onTap: () => onSelect(f.$1)),
        )).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active, isDark;
  final int count;
  final VoidCallback onTap;
  const _FilterChip({super.key, required this.label, required this.icon,
    required this.color, required this.active, required this.isDark,
    required this.count, required this.onTap});
  @override State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ac;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scaleAnim = CurvedAnimation(parent: _ac, curve: Curves.easeOutBack);
    if (widget.active) _ac.value = 1.0;
  }

  @override
  void didUpdateWidget(_FilterChip old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _ac.forward() : _ac.reverse();
    }
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? widget.color
        : (_hovered
        ? widget.color.withOpacity(0.09)
        : (widget.isDark ? _dSurface : _lSurface));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.active
                      ? Colors.transparent
                      : widget.color.withOpacity(0.22),
                  width: 0.75),
              boxShadow: widget.active ? [
                BoxShadow(
                    color: widget.color.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ] : []),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 12,
                color: widget.active ? Colors.white
                    : (widget.isDark ? _dLabel2 : _lLabel2)),
            const SizedBox(width: 6),
            Text(widget.label,
                style: _t(12.5, FontWeight.w600,
                    widget.active ? Colors.white
                        : (widget.isDark ? _dLabel2 : _lLabel2))),
            const SizedBox(width: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: widget.active
                      ? Colors.white.withOpacity(0.25)
                      : widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.count}',
                  style: _t(9, FontWeight.w700,
                      widget.active ? Colors.white : widget.color)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PREMIUM FLIP CARD
// ══════════════════════════════════════════════════════════════
class _PremiumFlipCard extends StatefulWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _PremiumFlipCard({required this.entry, required this.isDark, required this.l});
  @override State<_PremiumFlipCard> createState() => _PremiumFlipCardState();
}

class _PremiumFlipCardState extends State<_PremiumFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 420));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip(bool show) {
    if (show && !_flipped)  { _ctrl.forward(); _flipped = true; }
    if (!show && _flipped)  { _ctrl.reverse(); _flipped = false; }
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _flip(true),
    onExit:  (_) => _flip(false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _flip(!_flipped); },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle    = _anim.value * math.pi;
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
              child: _CardBack(entry: widget.entry, isDark: widget.isDark, l: widget.l),
            )
                : _CardFront(entry: widget.entry, isDark: widget.isDark, l: widget.l),
          );
        },
      ),
    ),
  );
}

// ── Card Front ───────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _CardFront({required this.entry, required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent(isDark);
    final bg     = isDark ? _dSurface : _lSurface;
    final label  = isDark ? _dLabel   : _lLabel;
    final label3 = isDark ? _dLabel3  : _lLabel3;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: accent.withOpacity(isDark ? 0.12 : 0.07), width: 0.75),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
                blurRadius: 14, offset: const Offset(0, 5)),
            BoxShadow(
                color: accent.withOpacity(isDark ? 0.08 : 0.04),
                blurRadius: 18, offset: const Offset(0, 4)),
          ]),
      child: Stack(children: [
        // Top gradient accent line
        Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 1.5,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      accent.withOpacity(0.50),
                      Colors.transparent,
                    ]),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20))))),

        // Subtle radial glow top-right
        Positioned(top: -10, right: -10,
            child: Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      accent.withOpacity(isDark ? 0.10 : 0.06),
                      Colors.transparent,
                    ])))),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category indicator (no pill border)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent)),
                const SizedBox(width: 5),
                Text(l.t(entry.categoryKey),
                    style: _t(9, FontWeight.w600, accent, ls: 0.4)),
              ]),

              const SizedBox(height: 14),

              // Symbol / icon
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(isDark ? 0.20 : 0.10),
                          accent.withOpacity(isDark ? 0.10 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withOpacity(isDark ? 0.28 : 0.16),
                        width: 0.75)),
                child: Center(
                  child: entry.isWord
                      ? Icon(entry.wordIcon!, color: accent, size: 28)
                      : Text(entry.symbol,
                      style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          height: 1.0)),
                ),
              ),

              const SizedBox(height: 12),

              // Name
              Text(l.t(entry.nameKey),
                  textAlign: TextAlign.center, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w600, label, ls: -0.2, h: 1.2)),

              const SizedBox(height: 10),

              // Flip hint
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.touch_app_rounded, size: 9, color: label3),
                const SizedBox(width: 4),
                Text('Tap to flip',
                    style: _t(9, FontWeight.w400, label3)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Card Back ────────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _CardBack({required this.entry, required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent(isDark);
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;

    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                accent.withOpacity(isDark ? 0.22 : 0.10),
                accent.withOpacity(isDark ? 0.10 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: accent.withOpacity(isDark ? 0.32 : 0.22), width: 0.75),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(isDark ? 0.16 : 0.10),
                blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.07),
                blurRadius: 12, offset: const Offset(0, 4)),
          ]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: accent.withOpacity(0.30), width: 0.75)),
              child: Icon(
                  entry.isWord ? entry.wordIcon! : Icons.sign_language_rounded,
                  color: accent, size: 18),
            ),

            const SizedBox(height: 10),

            // Name
            Text(l.t(entry.nameKey),
                textAlign: TextAlign.center,
                style: _t(13, FontWeight.w700, label, ls: -0.2)),

            const SizedBox(height: 7),

            // Hairline separator
            Container(height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      accent.withOpacity(0.40),
                      Colors.transparent,
                    ]))),

            const SizedBox(height: 9),

            // Meaning pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: accent.withOpacity(0.25), width: 0.5)),
              child: Text(l.t(entry.meaningKey),
                  textAlign: TextAlign.center, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _t(11.5, FontWeight.w700, accent, ls: 0.1, h: 1.3)),
            ),

            const SizedBox(height: 8),

            // Hand description
            Expanded(child: Text(l.t(entry.descKey),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
                style: _t(10, FontWeight.w400, label2, h: 1.55))),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label2 = isDark ? _dLabel2 : _lLabel2;
    final accent = isDark ? _blue_D  : _blue;
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accent.withOpacity(isDark ? 0.15 : 0.08),
                  accent.withOpacity(0.04),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                border: Border.all(
                    color: accent.withOpacity(0.20), width: 0.75)),
            child: Icon(Icons.search_off_rounded, color: label2, size: 26)),
        const SizedBox(height: 18),
        Text('No signs found',
            style: _t(17, FontWeight.w600,
                isDark ? _dLabel : _lLabel, ls: -0.2)),
        const SizedBox(height: 6),
        Text('Try a different search or category',
            style: _t(13, FontWeight.w400, label2)),
      ]),
    ));
  }
}