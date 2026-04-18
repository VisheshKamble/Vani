
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/GlobalNavbar.dart';
import '../../l10n/AppLocalizations.dart';
//  APPLE DESIGN TOKENS
const _red      = Color(0xFFFF3B30);
const _red_D    = Color(0xFFFF453A);
const _orange   = Color(0xFFFF9500);
const _orange_D = Color(0xFFFF9F0A);
const _blue     = Color(0xFF007AFF);
const _blue_D   = Color(0xFF0A84FF);
const _green_D  = Color(0xFF30D158);
const _indigo_D = Color(0xFF5E5CE6);
const _teal_D   = Color(0xFF5AC8F5);
const _purple_D = Color(0xFFBF5AF2);

// Light surfaces
const _lBg      = Color(0xFFF2F2F7);
const _lSurface = Color(0xFFFFFFFF);
const _lSep     = Color(0xFFC6C6C8);
const _lLabel   = Color(0xFF000000);
const _lLabel2  = Color(0x993C3C43);

// Dark surfaces
const _dBg      = Color(0xFF000000);
const _dSurface = Color(0xFF1C1C1E);
const _dSep     = Color(0xFF38383A);
const _dLabel   = Color(0xFFFFFFFF);
const _dLabel2  = Color(0x99EBEBF5);

// Legacy aliases — keeps AccessibilityPage etc. compiling unchanged
const kCrimson = _red;
const kAmber   = _orange;

TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Plus Jakarta Sans',
        fontSize: size, fontWeight: w, color: c,
        letterSpacing: ls, height: h);
//  DARK-MODE ACCENT RESOLVER
Color _dk(Color c) {
  const m = <int, Color>{
    0xFF007AFF: _blue_D,
    0xFF32ADE6: _teal_D,
    0xFF34C759: _green_D,
    0xFFFF9500: _orange_D,
    0xFF5856D6: _indigo_D,
    0xFFFF3B30: _red_D,
    0xFFAF52DE: _purple_D,
    // Bridging page uses 0xFF0284C7 (old token) — map to teal_D
    0xFF0284C7: _teal_D,
    // Education uses 0xFFDC2626 (old kCrimson) — map to red_D
    0xFFDC2626: _red_D,
    // Old kAmber
    0xFFD97706: _orange_D,
  };
  return m[c.value] ?? c;
}

Color _resolve(Color c, bool dark) => dark ? _dk(c) : c;
//  DATA MODELS
class ObjStatData {
  final String value, label, description;
  final Color color;
  const ObjStatData({
    required this.value,
    required this.label,
    this.description = '',
    this.color = _blue,
  });
}

class ObjSection {
  final String title;
  final Widget child;
  final bool isDark;
  const ObjSection({
    required this.title,
    required this.child,
    required this.isDark,
  });
}
//  OBJECTIVE PAGE BASE  — router
class ObjectivePageBase extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  final Color accentColor;
  final IconData heroIcon;
  final String tag, category, title, subtitle;
  final List<ObjStatData> stats;
  final List<ObjSection> sections;

  const ObjectivePageBase({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
    required this.accentColor,
    required this.heroIcon,
    required this.tag,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.sections,
  });

  @override
  State<ObjectivePageBase> createState() => _ObjectivePageBaseState();
}

class _ObjectivePageBaseState extends State<ObjectivePageBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 560));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w      = MediaQuery.of(context).size.width;
    final accent = _resolve(widget.accentColor, isDark);

    return kIsWeb || w >= 700
      ? _buildWeb(context, isDark, accent, w)
      : _buildMobile(context, isDark, accent);
  }
  //  MOBILE  (<700px)
  Widget _buildMobile(BuildContext ctx, bool isDark, Color accent) {
    final bg    = isDark ? _dBg      : _lBg;
    final navBg = isDark ? _dSurface : _lSurface;
    final sep   = isDark ? _dSep     : _lSep.withOpacity(0.5);
    final blueA = isDark ? _blue_D   : _blue;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -140,
            child: _ObjOrb(
              color: accent.withOpacity(isDark ? 0.13 : 0.09),
              size: 360,
            ),
          ),
          Positioned(
            bottom: 120,
            right: -120,
            child: _ObjOrb(
              color: _blue.withOpacity(isDark ? 0.11 : 0.08),
              size: 300,
            ),
          ),
          Positioned(
            top: 70,
            right: -20,
            child: _ObjArcDecor(
              size: 160,
              color: accent,
              dark: isDark,
              flip: true,
            ),
          ),
          Positioned(
            bottom: 160,
            left: -20,
            child: _ObjArcDecor(
              size: 140,
              color: _blue,
              dark: isDark,
              flip: false,
            ),
          ),
          SafeArea(
            child: Column(children: [

              // iOS navigation bar
              Container(
                decoration: BoxDecoration(
                    color: navBg.withOpacity(isDark ? 0.96 : 0.94),
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
                        Text(AppLocalizations.of(context).t('common_back'), style: _t(15, FontWeight.w400, blueA)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.22), width: 0.5)),
                    child: Text(widget.category,
                        style: _t(11, FontWeight.w600, accent, ls: 0.2)),
                  ),
                ]),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero card
                          _MobileHero(
                              isDark: isDark, accent: accent,
                              icon: widget.heroIcon, tag: widget.tag,
                              title: widget.title, subtitle: widget.subtitle),

                          // Stats strip
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: _MobileStatsStrip(
                                stats: widget.stats, isDark: isDark),
                          ),

                          // Sections
                          ...widget.sections.map((s) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            child: _SectionBlock(
                                title: s.title, isDark: isDark,
                                accent: accent, child: s.child),
                          )),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
  //  WEB / TABLET  (≥700px)
  Widget _buildWeb(BuildContext ctx, bool isDark, Color accent, double w) {
    final isDesktop = w > 1100;
    final compactWeb = w < 700;
    final hPad      = isDesktop ? 72.0 : (compactWeb ? 16.0 : 56.0);
    final bg        = isDark ? _dBg : _lBg;
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned(
            top: -220,
            left: -180,
            child: _ObjOrb(
              color: accent.withOpacity(isDark ? 0.16 : 0.12),
              size: 760,
            ),
          ),
          Positioned(
            top: 260,
            right: -170,
            child: _ObjOrb(
              color: _blue.withOpacity(isDark ? 0.13 : 0.10),
              size: 620,
            ),
          ),
          Positioned(
            bottom: 120,
            left: w * 0.24,
            child: _ObjOrb(
              color: accent.withOpacity(isDark ? 0.11 : 0.08),
              size: 460,
            ),
          ),
          Positioned(
            top: 64,
            right: 150,
            child: _ObjArcDecor(
              size: 260,
              color: accent,
              dark: isDark,
              flip: true,
            ),
          ),
          Positioned(
            bottom: 240,
            left: -30,
            child: _ObjArcDecor(
              size: 220,
              color: _blue,
              dark: isDark,
              flip: false,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.018),
                            Colors.transparent,
                            accent.withOpacity(0.025),
                          ]
                        : [
                            accent.withOpacity(0.038),
                            Colors.transparent,
                            _blue.withOpacity(0.02),
                          ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(children: [
                GlobalNavbar(
                    toggleTheme: widget.toggleTheme,
                    setLocale:   widget.setLocale,
                    activeRoute: ''),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(children: [
                      // Full-bleed header
                      _WebHeroHeader(
                          isDark: isDark, accent: accent,
                          icon: widget.heroIcon, tag: widget.tag,
                          category: widget.category,
                          title: widget.title, subtitle: widget.subtitle,
                          hPad: hPad, onBack: () => Navigator.pop(ctx)),

                      // Body
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 34),
                              _WebStatsGrid(stats: widget.stats, isDark: isDark),
                              const SizedBox(height: 40),
                              ...widget.sections.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: _SectionBlock(
                                    title: s.title, isDark: isDark,
                                    accent: accent, child: s.child),
                              )),
                              const SizedBox(height: 62),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _ObjOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _ObjArcDecor extends StatelessWidget {
  final double size;
  final Color color;
  final bool dark;
  final bool flip;
  const _ObjArcDecor({
    required this.size,
    required this.color,
    required this.dark,
    required this.flip,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: flip ? (Matrix4.identity()..rotateZ(math.pi)) : Matrix4.identity(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ObjArcPainter(color: color, dark: dark)),
      ),
    );
  }
}

class _ObjArcPainter extends CustomPainter {
  final Color color;
  final bool dark;
  const _ObjArcPainter({required this.color, required this.dark});

  @override
  void paint(Canvas canvas, Size s) {
    void arc(double r, double op) {
      final glow = Paint()
        ..color = color.withOpacity(dark ? op * 0.045 : op * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), 0, math.pi / 2, false, glow);

      final p = Paint()
        ..color = color.withOpacity(dark ? op * 0.36 : op * 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), 0, math.pi / 2, false, p);
    }

    arc(s.width * 0.34, 0.30);
    arc(s.width * 0.66, 0.19);
    arc(s.width * 0.88, 0.11);
  }

  @override
  bool shouldRepaint(_ObjArcPainter old) => false;
}
//  MOBILE COMPONENTS

class _MobileHero extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final IconData icon;
  final String tag, title, subtitle;
  const _MobileHero({required this.isDark, required this.accent,
    required this.icon, required this.tag,
    required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel   : _lLabel;
    final sub   = isDark ? _dLabel2  : _lLabel2;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              isDark ? const Color(0xFF141417) : const Color(0xFFF8FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: accent.withOpacity(isDark ? 0.26 : 0.17), width: 0.8),
          boxShadow: [BoxShadow(
              color: accent.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 18, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 74,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.9), accent.withOpacity(0.30)],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.20), accent.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.25), width: 1)),
              child: Icon(icon, color: accent, size: 24)),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.18), width: 0.7)),
            child: Text(tag, style: _t(10, FontWeight.w600, accent, ls: 0.3)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(title, style: _t(24, FontWeight.w700, label, ls: -0.5, h: 1.1)),
        const SizedBox(height: 8),
        Text(subtitle, style: _t(14, FontWeight.w400, sub, ls: -0.1, h: 1.6)),
      ]),
    );
  }
}

class _MobileStatsStrip extends StatefulWidget {
  final List<ObjStatData> stats;
  final bool isDark;
  const _MobileStatsStrip({required this.stats, required this.isDark});
  @override
  State<_MobileStatsStrip> createState() => _MobileStatsStripState();
}

class _MobileStatsStripState extends State<_MobileStatsStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctrl.forward();
    });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bg  = widget.isDark ? _dSurface : _lSurface;
    final sep = widget.isDark ? _dSep : _lSep.withOpacity(0.4);
    final sub = widget.isDark ? _dLabel2 : _lLabel2;

    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              widget.isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.black.withOpacity(widget.isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: IntrinsicHeight(
        child: Row(children: [
          for (int i = 0; i < widget.stats.length; i++) ...[
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Column(children: [
                Text(widget.stats[i].value,
                    style: _t(17, FontWeight.w700,
                        _resolve(widget.stats[i].color, widget.isDark),
                        ls: -0.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(widget.stats[i].label,
                    style: _t(9.5, FontWeight.w500, sub, h: 1.3),
                    textAlign: TextAlign.center,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            )),
            if (i < widget.stats.length - 1)
              Container(width: 0.5, color: sep),
          ],
        ]),
      ),
    );
  }
}
//  WEB COMPONENTS

class _WebHeroHeader extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final IconData icon;
  final String tag, category, title, subtitle;
  final double hPad;
  final VoidCallback onBack;
  const _WebHeroHeader({required this.isDark, required this.accent,
    required this.icon, required this.tag, required this.category,
    required this.title, required this.subtitle,
    required this.hPad, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel   : _lLabel;
    final sub   = isDark ? _dLabel2  : _lLabel2;
    final blueA = isDark ? _blue_D   : _blue;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              isDark ? const Color(0xFF161A22) : const Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(isDark ? 0.22 : 0.14), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.10 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Breadcrumb
          GestureDetector(
            onTap: onBack,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: blueA, size: 20),
              Text(AppLocalizations.of(context).t('common_back'), style: _t(14, FontWeight.w400, blueA)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: 86,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.92), accent.withOpacity(0.30)],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Icon + badges row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.20), accent.withOpacity(0.08)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withOpacity(0.24), width: 1)),
                child: Icon(icon, color: accent, size: 28)),
            const SizedBox(width: 18),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.18), width: 0.7)),
                  child: Text(tag, style: _t(10, FontWeight.w600, accent, ls: 0.3)),
                ),
                const SizedBox(width: 8),
                Text(category, style: _t(11, FontWeight.w500, sub, ls: 0.2)),
              ]),
            ]),
          ]),
          const SizedBox(height: 20),
          // Display title
          Text(title, style: _t(36, FontWeight.w700, label, ls: -1.0, h: 1.08)),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(subtitle,
                style: _t(16, FontWeight.w400, sub, ls: -0.1, h: 1.65)),
          ),
        ]),
      ),
    );
  }
}

class _WebStatsGrid extends StatelessWidget {
  final List<ObjStatData> stats;
  final bool isDark;
  const _WebStatsGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) => GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: stats.map((s) =>
          _WebStatCard(stat: s, isDark: isDark)).toList());
}

class _WebStatCard extends StatelessWidget {
  final ObjStatData stat;
  final bool isDark;
  const _WebStatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel   : _lLabel;
    final sub   = isDark ? _dLabel2  : _lLabel2;
    final color = _resolve(stat.color, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(isDark ? 0.22 : 0.14), width: 0.8),
          boxShadow: [BoxShadow(
              color: color.withOpacity(isDark ? 0.12 : 0.07),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.92), color.withOpacity(0.30)],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(stat.value,
                style: _t(28, FontWeight.w700, color, ls: -0.8)),
            const SizedBox(height: 3),
            Text(stat.label, style: _t(12, FontWeight.w600, label)),
            if (stat.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(stat.description,
                  style: _t(10.5, FontWeight.w400, sub, h: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
    );
  }
}
//  SHARED SECTION BLOCK  (mobile + web)

class _SectionBlock extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color accent;
  final Widget child;
  const _SectionBlock({required this.title, required this.isDark,
    required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    final label = isDark ? _dLabel : _lLabel;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 22,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withOpacity(0.30)],
                ))),
        const SizedBox(width: 10),
        Expanded(child: Text(title,
            style: _t(18, FontWeight.w700, label, ls: -0.3))),
      ]),
      const SizedBox(height: 14),
      child,
    ]);
  }
}
//  PUBLIC COMPONENTS  (called by individual page files)

/// iOS grouped list cell — icon + title + body
class ObjInfoCard extends StatelessWidget {
  final String title, body;
  final IconData icon;
  final Color accent;
  final bool isDark;
  const ObjInfoCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final a     = _resolve(accent, isDark);
    final bg    = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel   : _lLabel;
    final sub   = isDark ? _dLabel2  : _lLabel2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: a.withOpacity(isDark ? 0.22 : 0.14), width: 0.7),
          boxShadow: [BoxShadow(
              color: a.withOpacity(isDark ? 0.10 : 0.07),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [a.withOpacity(0.20), a.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: a.withOpacity(0.24), width: 0.7)),
            child: Icon(icon, color: a, size: 17)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _t(14, FontWeight.w600, label, ls: -0.2)),
          const SizedBox(height: 4),
          Text(body,  style: _t(13, FontWeight.w400, sub, ls: -0.1, h: 1.55)),
        ])),
      ]),
    );
  }
}

/// Animated horizontal bar chart
class ObjBarChart extends StatefulWidget {
  final bool isDark;
  final List<(String, double, Color)> data;
  const ObjBarChart({super.key, required this.isDark, required this.data});
  @override
  State<ObjBarChart> createState() => _ObjBarChartState();
}

class _ObjBarChartState extends State<ObjBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bg    = widget.isDark ? _dSurface : _lSurface;
    final sub   = widget.isDark ? _dLabel2  : _lLabel2;
    final track = widget.isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bg,
                widget.isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.black.withOpacity(widget.isDark ? 0.0 : 0.04),
                width: 0.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05),
                blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: widget.data.map((row) {
          final pct   = (row.$2 * 100).round();
          final color = _resolve(row.$3, widget.isDark);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              SizedBox(width: 110,
                  child: Text(row.$1,
                      style: _t(11.5, FontWeight.w500, sub),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 7, color: track),
                  FractionallySizedBox(
                    widthFactor: (row.$2 * _anim.value).clamp(0.0, 1.0),
                    child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.9), color.withOpacity(0.65)],
                            ),
                            borderRadius: BorderRadius.circular(4))),
                  ),
                ]),
              )),
              const SizedBox(width: 10),
              SizedBox(width: 36,
                  child: Text('$pct%',
                      textAlign: TextAlign.right,
                      style: _t(11.5, FontWeight.w700, color))),
            ]),
          );
        }).toList()),
      ),
    );
  }
}

/// Editorial pull-quote with accent left bar
class ObjQuoteBlock extends StatelessWidget {
  final String quote, source;
  final Color accent;
  final bool isDark;
  const ObjQuoteBlock({
    super.key,
    required this.quote,
    required this.source,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final a     = _resolve(accent, isDark);
    final bg    = isDark ? _dSurface : _lSurface;
    final label = isDark ? _dLabel   : _lLabel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: a.withOpacity(isDark ? 0.20 : 0.12), width: 0.7),
          boxShadow: [BoxShadow(
              color: a.withOpacity(isDark ? 0.10 : 0.06),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 3,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [a, a.withOpacity(0.30)],
                ),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 16),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(quote, style: _t(14, FontWeight.w400, label, ls: -0.1, h: 1.65)),
          const SizedBox(height: 10),
          Text('— $source', style: _t(11.5, FontWeight.w600, a)),
        ])),
      ]),
    );
  }
}

class ObjTimelineItem extends StatelessWidget {
  final String year, event;
  final Color accent;
  final bool isDark;
  final bool isLast;
  const ObjTimelineItem({
    super.key,
    required this.year,
    required this.event,
    required this.accent,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final a   = _resolve(accent, isDark);
    final bg  = isDark ? _dSurface : _lSurface;
    final lbl = isDark ? _dLabel   : _lLabel;
    final sep = isDark ? _dSep     : _lSep.withOpacity(0.4);

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Year + dot + line
        SizedBox(width: 52, child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(year,
                  style: _t(10, FontWeight.w700, a),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: a, shape: BoxShape.circle)),
              if (!isLast)
                Expanded(child: Container(
                    width: 1.0, color: sep,
                    margin: const EdgeInsets.symmetric(vertical: 4))),
              if (isLast) const SizedBox(height: 16),
            ])),
        const SizedBox(width: 12),
        // Event card
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bg,
                    isDark ? const Color(0xFF16161A) : const Color(0xFFF7FAFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: a.withOpacity(isDark ? 0.18 : 0.12),
                    width: 0.7),
                boxShadow: [BoxShadow(
                    color: a.withOpacity(isDark ? 0.08 : 0.05),
                    blurRadius: 10, offset: const Offset(0, 3))]),
            child: Text(event,
                style: _t(13, FontWeight.w400, lbl, ls: -0.1, h: 1.5)),
          ),
        )),
      ]),
    );
  }
}
