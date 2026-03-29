// lib/screens/objectives/BridgingGapsPage.dart
import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class BridgingGapsPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const BridgingGapsPage({super.key, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l      = AppLocalizations.of(context);
    const accent = Color(0xFF32ADE6); // Apple system teal

    return ObjectivePageBase(
      toggleTheme: toggleTheme, setLocale: setLocale,
      accentColor: accent,
      heroIcon:    Icons.connecting_airports_rounded,
      tag:         l.t('bridge_tag'),
      category:    l.t('bridge_category'),
      title:       l.t('bridge_title'),
      subtitle:    l.t('bridge_subtitle'),
      stats: [
        ObjStatData(value: l.t('bridge_stat1_val'), label: l.t('bridge_stat1_label'), description: l.t('bridge_stat1_desc'), color: accent),
        ObjStatData(value: l.t('bridge_stat2_val'), label: l.t('bridge_stat2_label'), description: l.t('bridge_stat2_desc'), color: kCrimson),
        ObjStatData(value: l.t('bridge_stat3_val'), label: l.t('bridge_stat3_label'), description: l.t('bridge_stat3_desc'), color: kCrimson),
        ObjStatData(value: l.t('bridge_stat4_val'), label: l.t('bridge_stat4_label'), description: l.t('bridge_stat4_desc'), color: kAmber),
      ],
      sections: [
        ObjSection(
          title: l.t('bridge_s1_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('bridge_s1_c1_title'), body: l.t('bridge_s1_c1_body'), icon: Icons.language_rounded,   accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('bridge_s1_c2_title'), body: l.t('bridge_s1_c2_body'), icon: Icons.school_outlined,    accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('bridge_s1_c3_title'), body: l.t('bridge_s1_c3_body'), icon: Icons.psychology_outlined, accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('bridge_s2_title'), isDark: isDark,
          child: ObjBarChart(isDark: isDark, data: [
            (l.t('bridge_bar1'), 0.08, kCrimson),
            (l.t('bridge_bar2'), 0.54, accent),
            (l.t('bridge_bar3'), 0.02, kCrimson),
            (l.t('bridge_bar4'), 0.26, kAmber),
            (l.t('bridge_bar5'), 0.33, kAmber),
          ]),
        ),
        ObjSection(
          title: l.t('bridge_s3_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('bridge_s3_c1_title'), body: l.t('bridge_s3_c1_body'), icon: Icons.swap_horiz_rounded,    accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('bridge_s3_c2_title'), body: l.t('bridge_s3_c2_body'), icon: Icons.work_outline_rounded,   accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjQuoteBlock(quote: l.t('bridge_quote'), source: l.t('bridge_quote_src'), accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('bridge_s4_title'), isDark: isDark,
          child: Column(children: [
            ObjTimelineItem(year: l.t('bridge_t1_year'), event: l.t('bridge_t1_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('bridge_t2_year'), event: l.t('bridge_t2_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('bridge_t3_year'), event: l.t('bridge_t3_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('bridge_t4_year'), event: l.t('bridge_t4_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('bridge_t5_year'), event: l.t('bridge_t5_event'), accent: accent, isDark: isDark, isLast: true),
          ]),
        ),
      ],
    );
  }
}