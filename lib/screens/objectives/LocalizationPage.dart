import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class LocalizationPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const LocalizationPage({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    const accent = Color(0xFF007AFF);

    return ObjectivePageBase(
      toggleTheme: toggleTheme,
      setLocale: setLocale,
      accentColor: accent,
      heroIcon: Icons.language_rounded,
      tag: l.t('loc_tag'),
      category: l.t('loc_category'),
      title: l.t('loc_title'),
      subtitle: l.t('loc_subtitle'),
      stats: [
        ObjStatData(
          value: l.t('loc_stat1_val'),
          label: l.t('loc_stat1_label'),
          description: l.t('loc_stat1_desc'),
          color: accent,
        ),
        ObjStatData(
          value: l.t('loc_stat2_val'),
          label: l.t('loc_stat2_label'),
          description: l.t('loc_stat2_desc'),
          color: kCrimson,
        ),
        ObjStatData(
          value: l.t('loc_stat3_val'),
          label: l.t('loc_stat3_label'),
          description: l.t('loc_stat3_desc'),
          color: kAmber,
        ),
        ObjStatData(
          value: l.t('loc_stat4_val'),
          label: l.t('loc_stat4_label'),
          description: l.t('loc_stat4_desc'),
          color: accent,
        ),
      ],
      sections: [
        ObjSection(
          title: l.t('loc_s1_title'),
          isDark: isDark,
          child: Column(
            children: [
              ObjInfoCard(
                title: l.t('loc_s1_c1_title'),
                body: l.t('loc_s1_c1_body'),
                icon: Icons.text_fields_rounded,
                accent: accent,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ObjInfoCard(
                title: l.t('loc_s1_c2_title'),
                body: l.t('loc_s1_c2_body'),
                icon: Icons.touch_app_rounded,
                accent: accent,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ObjInfoCard(
                title: l.t('loc_s1_c3_title'),
                body: l.t('loc_s1_c3_body'),
                icon: Icons.support_agent_rounded,
                accent: accent,
                isDark: isDark,
              ),
            ],
          ),
        ),
        ObjSection(
          title: l.t('loc_s2_title'),
          isDark: isDark,
          child: ObjBarChart(
            isDark: isDark,
            data: [
              (l.t('loc_bar1'), 0.99, accent),
              (l.t('loc_bar2'), 0.98, kCrimson),
              (l.t('loc_bar3'), 0.97, kAmber),
              (l.t('loc_bar4'), 0.96, accent),
              (l.t('loc_bar5'), 0.95, kCrimson),
            ],
          ),
        ),
        ObjSection(
          title: l.t('loc_s3_title'),
          isDark: isDark,
          child: Column(
            children: [
              ObjInfoCard(
                title: l.t('loc_s3_c1_title'),
                body: l.t('loc_s3_c1_body'),
                icon: Icons.dataset_rounded,
                accent: accent,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ObjInfoCard(
                title: l.t('loc_s3_c2_title'),
                body: l.t('loc_s3_c2_body'),
                icon: Icons.rule_folder_rounded,
                accent: accent,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ObjQuoteBlock(
                quote: l.t('loc_quote'),
                source: l.t('loc_quote_src'),
                accent: accent,
                isDark: isDark,
              ),
            ],
          ),
        ),
        ObjSection(
          title: l.t('loc_s4_title'),
          isDark: isDark,
          child: Column(
            children: [
              ObjTimelineItem(
                year: l.t('loc_t1_year'),
                event: l.t('loc_t1_event'),
                accent: accent,
                isDark: isDark,
              ),
              ObjTimelineItem(
                year: l.t('loc_t2_year'),
                event: l.t('loc_t2_event'),
                accent: accent,
                isDark: isDark,
              ),
              ObjTimelineItem(
                year: l.t('loc_t3_year'),
                event: l.t('loc_t3_event'),
                accent: accent,
                isDark: isDark,
              ),
              ObjTimelineItem(
                year: l.t('loc_t4_year'),
                event: l.t('loc_t4_event'),
                accent: accent,
                isDark: isDark,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
