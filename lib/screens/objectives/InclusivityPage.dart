// lib/screens/objectives/InclusivityPage.dart
import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class InclusivityPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const InclusivityPage({super.key, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l      = AppLocalizations.of(context);
    const accent = Color(0xFF34C759); // Apple system green

    return ObjectivePageBase(
      toggleTheme: toggleTheme, setLocale: setLocale,
      accentColor: accent,
      heroIcon:    Icons.people_outline_rounded,
      tag:         l.t('obj_inclusivity'),
      category:    l.t('obj_inclusivity'),
      title:       l.t('obj_inclusivity'),
      subtitle:    l.t('obj_inclusivity_desc'),
      stats: [
        ObjStatData(value: l.t('incl_stat1_val'), label: l.t('incl_stat1_label'), description: l.t('incl_stat1_desc'), color: accent),
        ObjStatData(value: l.t('incl_stat2_val'), label: l.t('incl_stat2_label'), description: l.t('incl_stat2_desc'), color: kCrimson),
        ObjStatData(value: l.t('incl_stat3_val'), label: l.t('incl_stat3_label'), description: l.t('incl_stat3_desc'), color: kCrimson),
        ObjStatData(value: l.t('incl_stat4_val'), label: l.t('incl_stat4_label'), description: l.t('incl_stat4_desc'), color: kAmber),
      ],
      sections: [
        ObjSection(
          title: l.t('incl_s1_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('incl_s1_c1_title'), body: l.t('incl_s1_c1_body'), icon: Icons.groups_rounded,         accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('incl_s1_c2_title'), body: l.t('incl_s1_c2_body'), icon: Icons.handshake_outlined,     accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('incl_s1_c3_title'), body: l.t('incl_s1_c3_body'), icon: Icons.diversity_3_rounded,    accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('incl_s2_title'), isDark: isDark,
          child: ObjBarChart(isDark: isDark, data: [
            (l.t('incl_bar1'), 0.72, kCrimson),
            (l.t('incl_bar2'), 0.60, kAmber),
            (l.t('incl_bar3'), 0.85, kCrimson),
            (l.t('incl_bar4'), 0.40, kAmber),
            (l.t('incl_bar5'), 0.15, kCrimson),
          ]),
        ),
        ObjSection(
          title: l.t('incl_s3_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('incl_s3_c1_title'), body: l.t('incl_s3_c1_body'), icon: Icons.workspace_premium_rounded, accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('incl_s3_c2_title'), body: l.t('incl_s3_c2_body'), icon: Icons.open_in_new_rounded,       accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjQuoteBlock(quote: l.t('incl_quote'), source: l.t('incl_quote_src'), accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('incl_s4_title'), isDark: isDark,
          child: Column(children: [
            ObjTimelineItem(year: l.t('incl_t1_year'), event: l.t('incl_t1_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('incl_t2_year'), event: l.t('incl_t2_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('incl_t3_year'), event: l.t('incl_t3_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('incl_t4_year'), event: l.t('incl_t4_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('incl_t5_year'), event: l.t('incl_t5_event'), accent: accent, isDark: isDark, isLast: true),
          ]),
        ),
      ],
    );
  }
}