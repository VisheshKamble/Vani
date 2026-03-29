// lib/screens/objectives/AccessibilityPage.dart
import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class AccessibilityPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const AccessibilityPage({super.key, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l      = AppLocalizations.of(context);
    const accent = Color(0xFF5856D6); // Apple system indigo

    return ObjectivePageBase(
      toggleTheme: toggleTheme, setLocale: setLocale,
      accentColor: accent,
      heroIcon:    Icons.accessibility_new_rounded,
      tag:         l.t('acc_tag'),
      category:    l.t('acc_category'),
      title:       l.t('acc_title'),
      subtitle:    l.t('acc_subtitle'),
      stats: [
        ObjStatData(value: l.t('acc_stat1_val'), label: l.t('acc_stat1_label'), description: l.t('acc_stat1_desc'), color: accent),
        ObjStatData(value: l.t('acc_stat2_val'), label: l.t('acc_stat2_label'), description: l.t('acc_stat2_desc'), color: kCrimson),
        ObjStatData(value: l.t('acc_stat3_val'), label: l.t('acc_stat3_label'), description: l.t('acc_stat3_desc'), color: kCrimson),
        ObjStatData(value: l.t('acc_stat4_val'), label: l.t('acc_stat4_label'), description: l.t('acc_stat4_desc'), color: kAmber),
      ],
      sections: [
        ObjSection(
          title: l.t('acc_s1_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('acc_s1_c1_title'), body: l.t('acc_s1_c1_body'), icon: Icons.record_voice_over_rounded, accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('acc_s1_c2_title'), body: l.t('acc_s1_c2_body'), icon: Icons.map_outlined,               accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('acc_s1_c3_title'), body: l.t('acc_s1_c3_body'), icon: Icons.local_hospital_outlined,    accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('acc_s2_title'), isDark: isDark,
          child: ObjBarChart(isDark: isDark, data: [
            (l.t('acc_bar1'), 0.88, kCrimson),
            (l.t('acc_bar2'), 0.82, kCrimson),
            (l.t('acc_bar3'), 0.74, kAmber),
            (l.t('acc_bar4'), 0.79, kCrimson),
            (l.t('acc_bar5'), 0.91, kCrimson),
            (l.t('acc_bar6'), 0.85, kCrimson),
          ]),
        ),
        ObjSection(
          title: l.t('acc_s3_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('acc_s3_c1_title'), body: l.t('acc_s3_c1_body'), icon: Icons.speed_rounded,          accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('acc_s3_c2_title'), body: l.t('acc_s3_c2_body'), icon: Icons.currency_rupee_rounded, accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjQuoteBlock(quote: l.t('acc_quote'), source: l.t('acc_quote_src'), accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('acc_s4_title'), isDark: isDark,
          child: Column(children: [
            ObjTimelineItem(year: l.t('acc_t1_year'), event: l.t('acc_t1_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('acc_t2_year'), event: l.t('acc_t2_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('acc_t3_year'), event: l.t('acc_t3_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('acc_t4_year'), event: l.t('acc_t4_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('acc_t5_year'), event: l.t('acc_t5_event'), accent: accent, isDark: isDark, isLast: true),
          ]),
        ),
      ],
    );
  }
}