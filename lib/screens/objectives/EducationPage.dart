// lib/screens/objectives/EducationPage.dart
import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class EducationPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const EducationPage({super.key, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l      = AppLocalizations.of(context);
    const accent = Color(0xFFFF3B30); // Apple system red

    return ObjectivePageBase(
      toggleTheme: toggleTheme, setLocale: setLocale,
      accentColor: accent,
      heroIcon:    Icons.school_rounded,
      tag:         l.t('edu_tag'),
      category:    l.t('edu_category'),
      title:       l.t('edu_title'),
      subtitle:    l.t('edu_subtitle'),
      stats: [
        ObjStatData(value: l.t('edu_stat1_val'), label: l.t('edu_stat1_label'), description: l.t('edu_stat1_desc'), color: kCrimson),
        ObjStatData(value: l.t('edu_stat2_val'), label: l.t('edu_stat2_label'), description: l.t('edu_stat2_desc'), color: kCrimson),
        ObjStatData(value: l.t('edu_stat3_val'), label: l.t('edu_stat3_label'), description: l.t('edu_stat3_desc'), color: kAmber),
        ObjStatData(value: l.t('edu_stat4_val'), label: l.t('edu_stat4_label'), description: l.t('edu_stat4_desc'), color: accent),
      ],
      sections: [
        ObjSection(
          title: l.t('edu_s1_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('edu_s1_c1_title'), body: l.t('edu_s1_c1_body'), icon: Icons.child_care_rounded,    accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('edu_s1_c2_title'), body: l.t('edu_s1_c2_body'), icon: Icons.mic_off_rounded,       accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('edu_s1_c3_title'), body: l.t('edu_s1_c3_body'), icon: Icons.person_search_rounded, accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('edu_s2_title'), isDark: isDark,
          child: ObjBarChart(isDark: isDark, data: [
            (l.t('edu_bar1'), 0.67, kCrimson),
            (l.t('edu_bar2'), 0.67, kCrimson),
            (l.t('edu_bar3'), 0.70, kCrimson),
            (l.t('edu_bar4'), 0.22, kAmber),
            (l.t('edu_bar5'), 0.01, kCrimson),
          ]),
        ),
        ObjSection(
          title: l.t('edu_s3_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('edu_s3_c1_title'), body: l.t('edu_s3_c1_body'), icon: Icons.loop_rounded,          accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('edu_s3_c2_title'), body: l.t('edu_s3_c2_body'), icon: Icons.class_outlined,        accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('edu_s3_c3_title'), body: l.t('edu_s3_c3_body'), icon: Icons.auto_stories_rounded,  accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjQuoteBlock(quote: l.t('edu_quote'), source: l.t('edu_quote_src'), accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('edu_s4_title'), isDark: isDark,
          child: Column(children: [
            ObjTimelineItem(year: l.t('edu_t1_year'), event: l.t('edu_t1_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('edu_t2_year'), event: l.t('edu_t2_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('edu_t3_year'), event: l.t('edu_t3_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('edu_t4_year'), event: l.t('edu_t4_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('edu_t5_year'), event: l.t('edu_t5_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('edu_t6_year'), event: l.t('edu_t6_event'), accent: accent, isDark: isDark, isLast: true),
          ]),
        ),
      ],
    );
  }
}