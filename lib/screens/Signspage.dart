// lib/screens/SignsPage.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║  VANI — ISL Signs Library · Apple-Inspired Premium UI      ║
// ║  Font: Google Sans (SF Pro equivalent)                     ║
// ║                                                            ║
// ║  < 700px  → iOS Library style                             ║
// ║    - Large title navigation                                ║
// ║    - Pill filter chips (horizontal scroll)                 ║
// ║    - 2-column flip card grid                               ║
// ║                                                            ║
// ║  ≥ 700px  → macOS / web layout                            ║
// ║    - GlobalNavbar                                          ║
// ║    - Full header with stats                                ║
// ║    - 4–6 column grid                                       ║
// ╚══════════════════════════════════════════════════════════════╝

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _blue     = Color(0xFF007AFF);
const _blue_D   = Color(0xFF0A84FF);
const _indigo   = Color(0xFF5856D6);
const _indigo_D = Color(0xFF5E5CE6);
const _orange   = Color(0xFFFF9500);
const _orange_D = Color(0xFFFF9F0A);
const _teal     = Color(0xFF32ADE6);
const _teal_D   = Color(0xFF5AC8F5);

// ── Alphabet accent: system indigo
const _kAlpha  = Color(0xFF5856D6);
const _kAlphaD = Color(0xFF5E5CE6);
// ── Numbers accent: system orange
const _kNum    = Color(0xFFFF9500);
const _kNumD   = Color(0xFFFF9F0A);
// ── Words accent: system teal
const _kWord   = Color(0xFF32ADE6);
const _kWordD  = Color(0xFF5AC8F5);

// Light surfaces
const _lBg      = Color(0xFFF2F2F7);
const _lSurface = Color(0xFFFFFFFF);
const _lSep     = Color(0xFFC6C6C8);
const _lLabel   = Color(0xFF000000);
const _lLabel2  = Color(0x993C3C43);
const _lLabel3  = Color(0x4D3C3C43);
const _lFill    = Color(0x1F787880);

// Dark surfaces
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

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────
class _SignEntry {
  final String symbol, nameKey, meaningKey, descKey, categoryKey;
  final Color accentLight, accentDark;
  const _SignEntry({
    required this.symbol,
    required this.nameKey,
    required this.meaningKey,
    required this.descKey,
    required this.categoryKey,
    required this.accentLight,
    required this.accentDark,
  });
  Color accent(bool dark) => dark ? accentDark : accentLight;
}

// ─────────────────────────────────────────────────────────────
//  SIGN DATA  (64 entries)
// ─────────────────────────────────────────────────────────────
const List<_SignEntry> _kSigns = [
  // ALPHABET
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
  // NUMBERS
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
  // WORDS
  _SignEntry(symbol:'🙏', nameKey:'sign_namaste_name',   meaningKey:'sign_namaste_meaning',   descKey:'sign_namaste_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👋', nameKey:'sign_hello_name',     meaningKey:'sign_hello_meaning',     descKey:'sign_hello_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'✋', nameKey:'sign_hi_name',        meaningKey:'sign_hi_meaning',        descKey:'sign_hi_desc',        categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🤔', nameKey:'sign_howareyou_name', meaningKey:'sign_howareyou_meaning', descKey:'sign_howareyou_desc', categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🤫', nameKey:'sign_quiet_name',     meaningKey:'sign_quiet_meaning',     descKey:'sign_quiet_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🙏', nameKey:'sign_thanks_name',    meaningKey:'sign_thanks_meaning',    descKey:'sign_thanks_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🍽️', nameKey:'sign_food_name',     meaningKey:'sign_food_meaning',      descKey:'sign_food_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🤟', nameKey:'sign_iloveyou_name',  meaningKey:'sign_iloveyou_meaning',  descKey:'sign_iloveyou_desc',  categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👦', nameKey:'sign_brother_name',   meaningKey:'sign_brother_meaning',   descKey:'sign_brother_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👨', nameKey:'sign_father_name',    meaningKey:'sign_father_meaning',    descKey:'sign_father_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👩', nameKey:'sign_mother_name',    meaningKey:'sign_mother_meaning',    descKey:'sign_mother_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'💧', nameKey:'sign_water_name',     meaningKey:'sign_water_meaning',     descKey:'sign_water_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'❓', nameKey:'sign_what_name',      meaningKey:'sign_what_meaning',      descKey:'sign_what_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🙏', nameKey:'sign_please_name',    meaningKey:'sign_please_meaning',    descKey:'sign_please_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🆘', nameKey:'sign_help_name',      meaningKey:'sign_help_meaning',      descKey:'sign_help_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'📢', nameKey:'sign_loud_name',      meaningKey:'sign_loud_meaning',      descKey:'sign_loud_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👆', nameKey:'sign_yours_name',     meaningKey:'sign_yours_meaning',     descKey:'sign_yours_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'😴', nameKey:'sign_sleeping_name',  meaningKey:'sign_sleeping_meaning',  descKey:'sign_sleeping_desc',  categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🏷️', nameKey:'sign_name_name',     meaningKey:'sign_name_meaning',      descKey:'sign_name_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'😔', nameKey:'sign_sorry_name',     meaningKey:'sign_sorry_meaning',     descKey:'sign_sorry_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👍', nameKey:'sign_good_name',      meaningKey:'sign_good_meaning',      descKey:'sign_good_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'👎', nameKey:'sign_bad_name',       meaningKey:'sign_bad_meaning',       descKey:'sign_bad_desc',       categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'📅', nameKey:'sign_today_name',     meaningKey:'sign_today_meaning',     descKey:'sign_today_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'⏰', nameKey:'sign_time_name',      meaningKey:'sign_time_meaning',      descKey:'sign_time_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'💪', nameKey:'sign_strong_name',    meaningKey:'sign_strong_meaning',    descKey:'sign_strong_desc',    categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'❤️', nameKey:'sign_love_name',      meaningKey:'sign_love_meaning',      descKey:'sign_love_desc',      categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'🩹', nameKey:'sign_bandaid_name',   meaningKey:'sign_bandaid_meaning',   descKey:'sign_bandaid_desc',   categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
  _SignEntry(symbol:'😊', nameKey:'sign_happy_name',     meaningKey:'sign_happy_meaning',     descKey:'sign_happy_desc',     categoryKey:'cat_words', accentLight:_kWord, accentDark:_kWordD),
];

const _kCategoryOrder = ['cat_alphabet', 'cat_numbers', 'cat_words'];

// ══════════════════════════════════════════════════════════════
//  PAGE
// ══════════════════════════════════════════════════════════════
class SignsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const SignsPage({super.key, required this.toggleTheme, required this.setLocale});
  @override
  State<SignsPage> createState() => _SignsPageState();
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
        duration: const Duration(milliseconds: 600));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SignEntry> _filtered(AppLocalizations l) =>
      _kSigns.where((s) {
        final matchCat = _cat == 'all' || s.categoryKey == _cat;
        final q        = _query.toLowerCase();
        final matchQ   = q.isEmpty ||
            l.t(s.nameKey).toLowerCase().contains(q) ||
            l.t(s.meaningKey).toLowerCase().contains(q) ||
            l.t(s.categoryKey).toLowerCase().contains(q);
        return matchCat && matchQ;
      }).toList();

  void _switchCategory(String cat) {
    HapticFeedback.selectionClick();
    _entryCtrl.forward(from: 0.7);
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
  //  MOBILE  (<700px)  — iOS Library style
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, bool isDark, AppLocalizations l) {
    final bg     = isDark ? _dBg      : _lBg;
    final navBg  = isDark ? _dSurface : _lSurface;
    final sep    = isDark ? _dSep     : _lSep.withOpacity(0.5);
    final label  = isDark ? _dLabel   : _lLabel;
    final blueA  = isDark ? _blue_D   : _blue;
    final filtered = _filtered(l);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [

          // ── iOS navigation bar ────────────────
          Container(
            decoration: BoxDecoration(
                color: navBg,
                border: Border(bottom: BorderSide(color: sep, width: 0.5))),
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chevron_left_rounded, color: blueA, size: 28),
                    Text('Back', style: _t(15, FontWeight.w400, blueA)),
                  ]),
                ),
              ),
              const Spacer(),
              Text('ISL Signs', style: _t(16, FontWeight.w600, label, ls: -0.2)),
              const Spacer(),
              // count badge
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

          // ── Body ─────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _entryFade,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Search + Filter — sticky header
                  SliverToBoxAdapter(child: Column(children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchBar(
                          isDark: isDark, ctrl: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v)),
                    ),
                    const SizedBox(height: 12),
                    _FilterStrip(
                        isDark: isDark, selected: _cat, l: l,
                        onSelect: _switchCategory),
                    const SizedBox(height: 16),
                    if (filtered.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(children: [
                          Text(
                            '${filtered.length} of ${_kSigns.length} signs',
                            style: _t(12, FontWeight.w500,
                                isDark ? _dLabel3 : _lLabel3, ls: 0.2)),
                        ]),
                      ),
                  ])),

                  // Grid
                  if (filtered.isEmpty)
                    SliverFillRemaining(child: _EmptyState(isDark: isDark))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) => _FlipCard(
                              entry: filtered[i], isDark: isDark, l: l),
                          childCount: filtered.length,
                        ),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
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
  //  WEB / TABLET  (≥700px)
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
                        const SizedBox(height: 48),
                        // Page header
                        _WebHeader(isDark: isDark, l: l, isDesktop: isDesktop),
                        const SizedBox(height: 32),
                        // Search
                        _SearchBar(isDark: isDark, ctrl: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v)),
                        const SizedBox(height: 18),
                        // Filter chips
                        _FilterStrip(isDark: isDark, selected: _cat, l: l,
                            onSelect: _switchCategory),
                        const SizedBox(height: 24),
                        // Count
                        if (filtered.isNotEmpty)
                          Text(
                            '${filtered.length} of ${_kSigns.length} signs',
                            style: _t(12, FontWeight.w500,
                                isDark ? _dLabel3 : _lLabel3, ls: 0.2)),
                        const SizedBox(height: 16),
                        // Grid or empty
                        if (filtered.isEmpty)
                          _EmptyState(isDark: isDark)
                        else
                          GridView.builder(
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
                            itemBuilder: (_, i) => _FlipCard(
                                entry: filtered[i], isDark: isDark, l: l),
                          ),
                        const SizedBox(height: 80),
                      ]),
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
//  WEB HEADER
// ══════════════════════════════════════════════════════════════
class _WebHeader extends StatelessWidget {
  final bool isDark, isDesktop;
  final AppLocalizations l;
  const _WebHeader({required this.isDark, required this.l, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Label — iOS section header style
      Text('SIGNS LIBRARY',
          style: _t(10, FontWeight.w600,
              isDark ? _dLabel3 : _lLabel3, ls: 1.2)),
      const SizedBox(height: 10),
      Text(l.t('signs_title_1') + l.t('signs_title_highlight'),
          style: _t(isDesktop ? 40 : 30, FontWeight.w700, label, ls: -1.0, h: 1.1)),
      const SizedBox(height: 10),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(l.t('signs_subtitle'),
            style: _t(15, FontWeight.w400, label2, ls: -0.1, h: 1.65)),
      ),
      const SizedBox(height: 20),
      // Stat pills
      Wrap(spacing: 10, runSpacing: 10, children: [
        _StatPill(n: '${_kSigns.length}', label: 'total signs',   color: isDark ? _kAlphaD : _kAlpha, isDark: isDark),
        _StatPill(n: '26',               label: 'alphabet',       color: isDark ? _kAlphaD : _kAlpha, isDark: isDark),
        _StatPill(n: '10',               label: 'numbers',        color: isDark ? _kNumD   : _kNum,   isDark: isDark),
        _StatPill(n: '28',               label: 'common words',   color: isDark ? _kWordD  : _kWord,  isDark: isDark),
      ]),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final String n, label;
  final Color color;
  final bool isDark;
  const _StatPill({required this.n, required this.label,
    required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface : _lSurface;
    final label2 = isDark ? _dLabel  : _lLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.20), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(n, style: _t(14, FontWeight.w700, label2)),
        const SizedBox(width: 5),
        Text(label, style: _t(11, FontWeight.w400, isDark ? _dLabel2 : _lLabel2)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SEARCH BAR  — iOS-style rounded pill
// ══════════════════════════════════════════════════════════════
class _SearchBar extends StatefulWidget {
  final bool isDark;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.isDark, required this.ctrl,
    required this.onChanged});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? _dSurface2 : _lSurface;
    final fill   = widget.isDark ? _dFill     : _lFill;
    final label  = widget.isDark ? _dLabel    : _lLabel;
    final label2 = widget.isDark ? _dLabel2   : _lLabel2;
    final label3 = widget.isDark ? _dLabel3   : _lLabel3;
    final accent = widget.isDark ? _blue_D    : _blue;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _focused ? accent.withOpacity(0.50) : Colors.transparent,
                width: 1.5)),
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
                  color: _focused ? accent : label2, size: 20)),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: widget.ctrl.text.isNotEmpty
                ? GestureDetector(
                onTap: () { widget.ctrl.clear(); widget.onChanged(''); },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                          color: label2.withOpacity(0.20),
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 11,
                          color: label2)),
                ))
                : null,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 0),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FILTER STRIP  — iOS segment-control style chips
// ══════════════════════════════════════════════════════════════
class _FilterStrip extends StatelessWidget {
  final bool isDark;
  final String selected;
  final AppLocalizations l;
  final ValueChanged<String> onSelect;
  const _FilterStrip({required this.isDark, required this.selected,
    required this.l, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all',          'All',      Icons.square_foot_rounded, isDark ? _blue_D  : _blue),
      ('cat_alphabet', 'A–Z',      Icons.sort_by_alpha_rounded, isDark ? _kAlphaD : _kAlpha),
      ('cat_numbers',  '0–9',      Icons.tag_rounded,           isDark ? _kNumD   : _kNum),
      ('cat_words',    'Words',    Icons.sign_language_rounded,  isDark ? _kWordD  : _kWord),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: filters.map((f) {
          final active = f.$1 == selected;
          final color  = f.$4;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
                label: f.$2, icon: f.$3,
                color: color, active: active,
                isDark: isDark,
                count: f.$1 == 'all'
                    ? _kSigns.length
                    : _kSigns.where((s) => s.categoryKey == f.$1).length,
                onTap: () => onSelect(f.$1)),
          );
        }).toList(),
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
  const _FilterChip({required this.label, required this.icon,
    required this.color, required this.active, required this.isDark,
    required this.count, required this.onTap});
  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? widget.color
        : (_hovered
        ? widget.color.withOpacity(0.08)
        : (widget.isDark ? _dSurface : _lSurface));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.active
                      ? Colors.transparent
                      : widget.color.withOpacity(0.20),
                  width: 0.5),
              boxShadow: widget.active
                  ? [BoxShadow(
                  color: widget.color.withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 3))]
                  : []),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 13,
                color: widget.active
                    ? Colors.white
                    : (widget.isDark ? _dLabel2 : _lLabel2)),
            const SizedBox(width: 6),
            Text(widget.label,
                style: _t(12.5, FontWeight.w600,
                    widget.active ? Colors.white
                        : (widget.isDark ? _dLabel2 : _lLabel2))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: widget.active
                      ? Colors.white.withOpacity(0.22)
                      : widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.count}',
                  style: _t(9.5, FontWeight.w700,
                      widget.active ? Colors.white : widget.color)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FLIP CARD  — 3D card flip on tap / hover
// ══════════════════════════════════════════════════════════════
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
  late Animation<double>   _anim;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 440));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip(bool show) {
    if (show && !_flipped) { _ctrl.forward(); _flipped = true; }
    if (!show && _flipped) { _ctrl.reverse(); _flipped = false; }
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
              child: _CardBack(entry: widget.entry,
                  isDark: widget.isDark, l: widget.l),
            )
                : _CardFront(entry: widget.entry,
                isDark: widget.isDark, l: widget.l),
          );
        },
      ),
    ),
  );
}

// ── Card front — clean Apple card ────────────────────────────
class _CardFront extends StatelessWidget {
  final _SignEntry entry;
  final bool isDark;
  final AppLocalizations l;
  const _CardFront({required this.entry, required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface : _lSurface;
    final label  = isDark ? _dLabel   : _lLabel;
    final label3 = isDark ? _dLabel3  : _lLabel3;
    final accent = entry.accent(isDark);

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Stack(children: [
        // Subtle top accent line
        Positioned(top: 0, left: 0, right: 0,
            child: Container(
                height: 2,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      accent.withOpacity(0.40),
                      Colors.transparent,
                    ]),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20))))),

        // Content
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category chip
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accent.withOpacity(0.18), width: 0.5)),
                  child: Text(l.t(entry.categoryKey),
                      style: _t(8.5, FontWeight.w600, accent, ls: 0.5))),
              const SizedBox(height: 14),

              // Symbol in tinted circle
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withOpacity(0.16), width: 0.5)),
                child: Center(
                    child: Text(entry.symbol,
                        style: const TextStyle(fontSize: 28, height: 1.0))),
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
                Text('Tap to flip', style: _t(9, FontWeight.w400, label3)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Card back — accent-tinted ────────────────────────────────
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
          color: accent.withOpacity(isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.30), width: 1.0),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(isDark ? 0.18 : 0.10),
                blurRadius: 18, offset: const Offset(0, 6)),
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.28 : 0.06),
                blurRadius: 10, offset: const Offset(0, 3)),
          ]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.30))),
              child: Icon(Icons.sign_language_rounded, color: accent, size: 18)),
            const SizedBox(height: 10),

            // Sign name
            Text(l.t(entry.nameKey),
                textAlign: TextAlign.center,
                style: _t(12.5, FontWeight.w700, label, ls: -0.2)),
            const SizedBox(height: 6),

            // Hairline divider
            Container(height: 1,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [
                  Colors.transparent, accent.withOpacity(0.40), Colors.transparent
                ]))),
            const SizedBox(height: 8),

            // Meaning — highlighted pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.22), width: 0.5)),
              child: Text(l.t(entry.meaningKey),
                  textAlign: TextAlign.center, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12, FontWeight.w700, accent, ls: 0.1, h: 1.3)),
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
                color: accent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.16), width: 0.5)),
            child: Icon(Icons.search_off_rounded, color: label2, size: 28)),
        const SizedBox(height: 18),
        Text('No signs found',
            style: _t(17, FontWeight.w600, isDark ? _dLabel : _lLabel, ls: -0.2)),
        const SizedBox(height: 6),
        Text('Try a different search or category',
            style: _t(13, FontWeight.w400, label2)),
      ]),
    ));
  }
}