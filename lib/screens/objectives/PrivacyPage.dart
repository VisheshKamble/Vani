import 'package:flutter/material.dart';
import '../../l10n/AppLocalizations.dart';
import 'objective_shared.dart';

class PrivacyPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const PrivacyPage({super.key, required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l      = AppLocalizations.of(context);
    const accent = Color(0xFFFF9500); // Apple system orange

    return ObjectivePageBase(
      toggleTheme: toggleTheme, setLocale: setLocale,
      accentColor: accent,
      heroIcon:    Icons.shield_outlined,
      tag:         l.t('obj_privacy'),
      category:    l.t('obj_privacy'),
      title:       l.t('obj_privacy'),
      subtitle:    l.t('obj_privacy_desc'),
      stats: [
        ObjStatData(value: l.t('priv_stat1_val'), label: l.t('priv_stat1_label'), description: l.t('priv_stat1_desc'), color: accent),
        ObjStatData(value: l.t('priv_stat2_val'), label: l.t('priv_stat2_label'), description: l.t('priv_stat2_desc'), color: kCrimson),
        ObjStatData(value: l.t('priv_stat3_val'), label: l.t('priv_stat3_label'), description: l.t('priv_stat3_desc'), color: kCrimson),
        ObjStatData(value: l.t('priv_stat4_val'), label: l.t('priv_stat4_label'), description: l.t('priv_stat4_desc'), color: kAmber),
      ],
      sections: [
        ObjSection(
          title: l.t('priv_s1_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('priv_s1_c1_title'), body: l.t('priv_s1_c1_body'), icon: Icons.phone_android_rounded,   accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('priv_s1_c2_title'), body: l.t('priv_s1_c2_body'), icon: Icons.cloud_off_rounded,       accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('priv_s1_c3_title'), body: l.t('priv_s1_c3_body'), icon: Icons.lock_outline_rounded,    accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('priv_s3_title'), isDark: isDark,
          child: ObjBarChart(isDark: isDark, data: [
            (l.t('priv_bar1'), 0.78, kCrimson),
            (l.t('priv_bar2'), 0.65, kCrimson),
            (l.t('priv_bar3'), 0.90, kCrimson),
            (l.t('priv_bar4'), 0.45, kAmber),
            (l.t('priv_bar5'), 0.20, kAmber),
          ]),
        ),
        ObjSection(
          title: l.t('priv_s2_title'), isDark: isDark,
          child: Column(children: [
            ObjInfoCard(title: l.t('priv_s2_c1_title'), body: l.t('priv_s2_c1_body'), icon: Icons.memory_rounded,          accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjInfoCard(title: l.t('priv_s2_c2_title'), body: l.t('priv_s2_c2_body'), icon: Icons.verified_user_rounded,   accent: accent, isDark: isDark),
            const SizedBox(height: 12),
            ObjQuoteBlock(quote: l.t('priv_quote'), source: l.t('priv_quote_src'), accent: accent, isDark: isDark),
          ]),
        ),
        ObjSection(
          title: l.t('priv_s4_title'), isDark: isDark,
          child: Column(children: [
            ObjTimelineItem(year: l.t('priv_t1_year'), event: l.t('priv_t1_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('priv_t2_year'), event: l.t('priv_t2_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('priv_t3_year'), event: l.t('priv_t3_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('priv_t4_year'), event: l.t('priv_t4_event'), accent: accent, isDark: isDark),
            ObjTimelineItem(year: l.t('priv_t5_year'), event: l.t('priv_t5_event'), accent: accent, isDark: isDark, isLast: true),
          ]),
        ),
      ],
    );
  }
}
