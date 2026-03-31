// lib/screens/EmergencySetupScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Setup  · UX4G Redesign                          ║
// ║  Font: Noto Sans (UX4G standard)                                  ║
// ║  < 700px  → Mobile contacts manager                               ║
// ║  ≥ 700px  → Web settings panel                                    ║
// ║                                                                    ║
// ║  UX4G Principles Applied:                                         ║
// ║  • Grouped list with visible separators (WCAG structure)          ║
// ║  • Avatar initials use semantic relation color                    ║
// ║  • Form validation with semantic danger color + icon              ║
// ║  • Relation chips use accessible bg/border/text color triplets    ║
// ║  • Empty state uses info color for helpful prompting              ║
// ║  • Confirmation dialog: destructive action in danger red          ║
// ║  • All touch targets min 44dp                                     ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import '../services/EmergencyService.dart';
import '../utils/PlatformHelper.dart';

// ─────────────────────────────────────────────────────────────────────
//  UX4G DESIGN TOKENS  (same palette as EmergencyScreen + HomeScreen)
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Noto Sans';

const _primary      = Color(0xFF1A56DB);
const _primaryDark  = Color(0xFF4A8EFF);
const _primaryLight = Color(0xFFE8F0FE);

const _danger       = Color(0xFFB71C1C);
const _dangerDark   = Color(0xFFEF5350);
const _dangerLight  = Color(0xFFFFEBEE);

const _warning      = Color(0xFF7A4800);
const _warningDark  = Color(0xFFFFB300);
const _warningLight = Color(0xFFFFF3E0);

const _success      = Color(0xFF1B7340);
const _successDark  = Color(0xFF27AE60);
const _successLight = Color(0xFFE6F4EC);

const _info         = Color(0xFF0D47A1);
const _infoDark     = Color(0xFF42A5F5);
const _infoLight    = Color(0xFFE3F2FD);

// Relation accent colors (all WCAG AA)
const _relFamily    = Color(0xFF0D47A1); // info/blue
const _relFamilyD   = Color(0xFF42A5F5);
const _relParent    = Color(0xFF006064); // teal
const _relParentD   = Color(0xFF4DD0E1);
const _relSibling   = Color(0xFF1B7340); // success/green
const _relSiblingD  = Color(0xFF27AE60);
const _relSpouse    = Color(0xFFB71C1C); // danger/red
const _relSpouseD   = Color(0xFFEF5350);
const _relFriend    = Color(0xFF7A4800); // warning/amber
const _relFriendD   = Color(0xFFFFB300);
const _relDoctor    = Color(0xFF004D40); // deep teal
const _relDoctorD   = Color(0xFF26A69A);
const _relCaretaker = Color(0xFF4A148C); // purple
const _relCaretakerD = Color(0xFFCE93D8);
const _relOther     = Color(0xFF374151); // neutral
const _relOtherD    = Color(0xFF9CA3AF);

// Neutral surfaces
const _lBg          = Color(0xFFF5F7FA);
const _lSurface     = Color(0xFFFFFFFF);
const _lSurface2    = Color(0xFFF0F4F8);
const _lBorder      = Color(0xFFCDD5DF);
const _lBorderSub   = Color(0xFFE4E9F0);
const _lText        = Color(0xFF111827);
const _lTextSub     = Color(0xFF374151);
const _lTextMuted   = Color(0xFF6B7280);

const _dBg          = Color(0xFF0D1117);
const _dSurface     = Color(0xFF161B22);
const _dSurface2    = Color(0xFF21262D);
const _dBorder      = Color(0xFF30363D);
const _dBorderSub   = Color(0xFF21262D);
const _dText        = Color(0xFFE6EDF3);
const _dTextSub     = Color(0xFFB0BEC5);
const _dTextMuted   = Color(0xFF8B949E);

// Spacing
const _sp4  = 4.0;
const _sp8  = 8.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;
const _sp48 = 48.0;

// ── Type helpers ──────────────────────────────────────────────────────
TextStyle _display(double size, Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: size, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: -0.5);

TextStyle _heading(double size, Color c, {FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.3, letterSpacing: -0.2);

TextStyle _body(double size, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.6);

TextStyle _label(double size, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.4, letterSpacing: 0.1);

// ── Relation → UX4G color mapping ────────────────────────────────────
const _relationAccents = {
  'Family':    [_relFamily,    _relFamilyD],
  'Parent':    [_relParent,    _relParentD],
  'Sibling':   [_relSibling,   _relSiblingD],
  'Spouse':    [_relSpouse,    _relSpouseD],
  'Friend':    [_relFriend,    _relFriendD],
  'Doctor':    [_relDoctor,    _relDoctorD],
  'Caretaker': [_relCaretaker, _relCaretakerD],
  'Other':     [_relOther,     _relOtherD],
};

Color _accentFor(String r, bool dark) {
  final pair = _relationAccents[r] ?? [_relOther, _relOtherD];
  return dark ? pair[1] : pair[0];
}

String _relationLabel(AppLocalizations l, String code) {
  switch (code) {
    case 'Family':    return l.t('rel_family');
    case 'Parent':    return l.t('rel_parent');
    case 'Sibling':   return l.t('rel_sibling');
    case 'Spouse':    return l.t('rel_spouse');
    case 'Friend':    return l.t('rel_friend');
    case 'Doctor':    return l.t('rel_doctor');
    case 'Caretaker': return l.t('rel_caretaker');
    case 'Other':     return l.t('rel_other');
    default:          return code;
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════
class EmergencySetupScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const EmergencySetupScreen({
    super.key, required this.toggleTheme, required this.setLocale,
  });
  @override
  State<EmergencySetupScreen> createState() => _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends State<EmergencySetupScreen>
    with SingleTickerProviderStateMixin {
  final _service = EmergencyService.instance;

  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final contacts = _service.getContacts();
    final w        = MediaQuery.of(context).size.width;
    return w < 700
        ? _buildMobile(context, contacts, isDark)
        : _buildWeb(context, contacts, isDark, w > 1100);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, List<EmergencyContact> contacts,
      bool isDark) {
    final l          = AppLocalizations.of(ctx);
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final bg         = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            // Nav bar
            _MobileNavBar(
              isDark: isDark,
              title: l.t('sos_setup_title'),
              subtitle: l.t('sos_setup_subtitle'),
              onBack: () => Navigator.pop(ctx),
              trailing: _ContactCountBadge(
                  count: contacts.length,
                  hasPrimary: hasPrimary,
                  isDark: isDark),
            ),

            Expanded(child: SlideTransition(
              position: _entrySlide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    _sp16, _sp12, _sp16, _sp48),
                physics: const BouncingScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CapabilitiesCard(isDark: isDark),
                      const SizedBox(height: _sp8),

                      if (PlatformHelper.supportsShake) ...[
                        _ShakeInfoCard(isDark: isDark),
                        const SizedBox(height: _sp8),
                      ],

                      // Section header
                      _GroupedSectionHeader(
                        title: contacts.isEmpty
                            ? l.t('sos_no_contacts_yet')
                            : l.t('sos_setup_title'),
                        trailing: (!hasPrimary && contacts.isNotEmpty)
                            ? _WarningBadge(
                            label: l.t('sos_no_primary'), isDark: isDark)
                            : null,
                        isDark: isDark,
                      ),

                      if (contacts.isEmpty)
                        _EmptyContactsCard(isDark: isDark),

                      if (contacts.isNotEmpty)
                        _ContactList(
                          contacts: contacts, isDark: isDark,
                          onDelete:     (i) => _confirmDelete(i),
                          onSetPrimary: (i) => _setPrimary(i),
                          onEdit:       (c, i) => _openForm(existing: c, index: i),
                        ),

                      const SizedBox(height: _sp8),

                      if (contacts.length < 5)
                        _AddContactRow(isDark: isDark, onTap: () => _openForm()),
                    ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  WEB / TABLET
  // ════════════════════════════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, List<EmergencyContact> contacts,
      bool isDark, bool isDesktop) {
    final hPad = isDesktop ? 80.0 : 40.0;
    final bg   = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            GlobalNavbar(toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale, activeRoute: 'emergency'),
            Expanded(child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, _sp24, hPad, 64),
              physics: const BouncingScrollPhysics(),
              child: isDesktop
                  ? _webDesktopLayout(ctx, contacts, isDark)
                  : _webTabletLayout(ctx, contacts, isDark),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, List<EmergencyContact> contacts,
      bool isDark) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 320,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _WebPageHeader(isDark: isDark, onBack: () => Navigator.pop(ctx)),
          const SizedBox(height: _sp24),
          _CapabilitiesCard(isDark: isDark),
          const SizedBox(height: _sp12),
          if (PlatformHelper.supportsShake) ...[
            _ShakeInfoCard(isDark: isDark),
            const SizedBox(height: _sp12),
          ],
        ])),
    const SizedBox(width: 48),
    Expanded(child: _WebContactsPanel(
      contacts: contacts, isDark: isDark,
      onAdd:        () => _openForm(),
      onDelete:     (i) => _confirmDelete(i),
      onSetPrimary: (i) => _setPrimary(i),
      onEdit:       (c, i) => _openForm(existing: c, index: i),
    )),
  ]);

  Widget _webTabletLayout(BuildContext ctx, List<EmergencyContact> contacts,
      bool isDark) => Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WebPageHeader(isDark: isDark, onBack: () => Navigator.pop(ctx)),
        const SizedBox(height: _sp24),
        _CapabilitiesCard(isDark: isDark),
        const SizedBox(height: _sp20),
        _WebContactsPanel(
          contacts: contacts, isDark: isDark,
          onAdd:        () => _openForm(),
          onDelete:     (i) => _confirmDelete(i),
          onSetPrimary: (i) => _setPrimary(i),
          onEdit:       (c, i) => _openForm(existing: c, index: i),
        ),
        if (PlatformHelper.supportsShake) ...[
          const SizedBox(height: _sp12),
          _ShakeInfoCard(isDark: isDark),
        ],
      ]);

  // ── Actions ───────────────────────────────────────────────────────
  void _confirmDelete(int index) {
    final l = AppLocalizations.of(context);
    showDialog(context: context,
        builder: (_) => _UX4GAlertDialog(
          title: l.t('sos_remove_title'),
          message: l.t('sos_remove_body'),
          destructiveLabel: l.t('sos_remove_btn'),
          onDestructive: () async {
            await _service.deleteContact(index);
            if (mounted) setState(() {});
          },
        ));
  }

  void _setPrimary(int index) async {
    await _service.setPrimary(index);
    if (mounted) setState(() {});
  }

  void _openForm({EmergencyContact? existing, int? index}) {
    final l = AppLocalizations.of(context);
    showDialog(context: context,
        builder: (_) => _ContactFormDialog(
          existing: existing,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onSave: (contact) async {
            try {
              index != null
                  ? await _service.updateContact(index, contact)
                  : await _service.addContact(contact);
              if (mounted) setState(() {});
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.t('sos_generic_error'),
                        style: _body(13, Colors.white, w: FontWeight.w500)),
                    backgroundColor: _danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))));
              }
            }
          },
        ));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  MOBILE NAV BAR
// ══════════════════════════════════════════════════════════════════════
class _MobileNavBar extends StatelessWidget {
  final bool isDark;
  final String title, subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  const _MobileNavBar({required this.isDark, required this.title,
    required this.subtitle, required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final bg      = isDark ? _dSurface : _lSurface;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final border  = isDark ? _dBorder  : _lBorder;
    final accent  = isDark ? _dangerDark : _danger;
    final navBlue = isDark ? _infoDark   : _info;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border, width: 1.0))),
      padding: const EdgeInsets.fromLTRB(_sp16, _sp12, _sp16, _sp12),
      child: Row(children: [
        Semantics(
          label: l.t('common_back'), button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _sp8, vertical: _sp8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chevron_left_rounded, color: navBlue, size: 22),
                Text(l.t('common_back'),
                    style: _body(15, navBlue, w: FontWeight.w500)),
              ]),
            ),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text(title, style: _heading(15, textClr)),
          Text(subtitle, style: _label(11, subClr, w: FontWeight.w400)),
        ]),
        const Spacer(),
        if (trailing != null) trailing!
        else const SizedBox(width: 48),
      ]),
    );
  }
}

// ── Contact count badge ───────────────────────────────────────────────
class _ContactCountBadge extends StatelessWidget {
  final int count;
  final bool hasPrimary, isDark;
  const _ContactCountBadge({required this.count, required this.hasPrimary,
    required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color   = hasPrimary
        ? (isDark ? _successDark : _success)
        : (isDark ? _warningDark : _warning);
    final bgColor = hasPrimary
        ? (isDark ? _successDark.withOpacity(0.12) : _successLight)
        : (isDark ? _warningDark.withOpacity(0.12) : _warningLight);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp12, vertical: _sp4),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.30), width: 1)),
        child: Text(
            AppLocalizations.of(context)
                .t('sos_contacts_progress')
                .replaceAll('{n}', '$count'),
            style: _label(11, color, w: FontWeight.w700)));
  }
}

// ── Grouped section header ────────────────────────────────────────────
class _GroupedSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isDark;
  const _GroupedSectionHeader({required this.title, this.trailing,
    required this.isDark});

  @override
  Widget build(BuildContext context) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, _sp20, 0, _sp8),
        child: Row(children: [
          Text(title.toUpperCase(),
              style: _label(10.5, isDark ? _dTextMuted : _lTextMuted,
                  w: FontWeight.w700)),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
      ));
}

// ── Warning badge ─────────────────────────────────────────────────────
class _WarningBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  const _WarningBadge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? _warningDark : _warning;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp4),
        decoration: BoxDecoration(
            color: isDark
                ? _warningDark.withOpacity(0.12)
                : _warningLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: color.withOpacity(0.30), width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 12),
          const SizedBox(width: _sp4),
          Text(label, style: _label(10.5, color, w: FontWeight.w700)),
        ]));
  }
}

// ── Empty state ───────────────────────────────────────────────────────
class _EmptyContactsCard extends StatelessWidget {
  final bool isDark;
  const _EmptyContactsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _dangerDark : _danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: _sp24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1)),
      child: Column(children: [
        Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                shape: BoxShape.circle),
            child: Icon(Icons.person_add_rounded, color: accent, size: 26)),
        const SizedBox(height: _sp16),
        Text(l.t('sos_add_first'),
            style: _heading(16, textClr)),
        const SizedBox(height: _sp8),
        Text(l.t('sos_add_first_body'), textAlign: TextAlign.center,
            style: _body(13, subClr)),
      ]),
    );
  }
}

// ── Contact list ──────────────────────────────────────────────────────
class _ContactList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final bool isDark;
  final void Function(int) onDelete, onSetPrimary;
  final void Function(EmergencyContact, int) onEdit;
  const _ContactList({required this.contacts, required this.isDark,
    required this.onDelete, required this.onSetPrimary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final sep    = isDark ? _dBorderSub : _lBorderSub;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1)),
      child: Column(children: contacts.asMap().entries.map((e) {
        final i    = e.key;
        final c    = e.value;
        final last = i == contacts.length - 1;
        return Column(children: [
          _ContactCell(
              contact: c, index: i, isDark: isDark,
              onDelete:     () => onDelete(i),
              onSetPrimary: () => onSetPrimary(i),
              onEdit:       () => onEdit(c, i)),
          if (!last)
            Divider(indent: 74, height: 1, thickness: 1, color: sep),
        ]);
      }).toList()),
    );
  }
}

class _ContactCell extends StatelessWidget {
  final EmergencyContact contact;
  final int index;
  final bool isDark;
  final VoidCallback onDelete, onSetPrimary, onEdit;
  const _ContactCell({required this.contact, required this.index,
    required this.isDark, required this.onDelete,
    required this.onSetPrimary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final c      = contact;
    final accent = _accentFor(c.relation, isDark);
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';

    return Semantics(
      label: '${c.name}, ${c.relation}, ${c.phone}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _sp16, vertical: _sp12),
        child: Row(children: [
          // Avatar with relation-color + primary star
          Stack(children: [
            Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Center(child: Text(initial,
                    style: _heading(20, accent)))),
            if (c.isPrimary)
              Positioned(right: 0, bottom: 0, child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                      color: isDark ? _dangerDark : _danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? _dSurface : _lSurface,
                          width: 1.5)),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 9))),
          ]),
          const SizedBox(width: _sp16),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(c.name,
                      style: _heading(15, textClr),
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: _sp8),
                  // Relation badge — semantic colors
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _sp8, vertical: _sp4),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: accent.withOpacity(0.25), width: 1)),
                      child: Text(_relationLabel(l, c.relation),
                          style: _label(10, accent, w: FontWeight.w700))),
                ]),
                const SizedBox(height: _sp4),
                Text(c.phone, style: _body(13, subClr)),
              ])),

          // Context menu — 3-dot
          PopupMenuButton<String>(
            tooltip: 'Options',
            color: isDark ? _dSurface2 : _lSurface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isDark ? _dBorder : _lBorder, width: 1)),
            elevation: 8,
            offset: const Offset(0, 8),
            icon: Icon(Icons.more_horiz_rounded, color: mutedClr, size: 20),
            onSelected: (v) {
              if (v == 'edit')    onEdit();
              if (v == 'primary') onSetPrimary();
              if (v == 'delete')  onDelete();
            },
            itemBuilder: (_) => [
              if (!c.isPrimary)
                _popupItem(context, 'primary',
                    l.t('sos_set_primary'), Icons.star_rounded,
                    isDark ? _infoDark : _info, isDark),
              _popupItem(context, 'edit',
                  l.t('sos_edit_btn'), Icons.edit_rounded,
                  isDark ? _dText : _lText, isDark),
              _popupItem(context, 'delete',
                  l.t('sos_remove_menu'), Icons.delete_rounded,
                  isDark ? _dangerDark : _danger, isDark),
            ],
          ),
        ]),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(BuildContext ctx, String value,
      String lbl, IconData icon, Color color, bool isDark) =>
      PopupMenuItem(value: value, height: 44,
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: _sp12),
            Text(lbl, style: _body(14, color, w: FontWeight.w500)),
          ]));
}

// ── Add contact row ───────────────────────────────────────────────────
class _AddContactRow extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddContactRow({required this.isDark, required this.onTap});
  @override
  State<_AddContactRow> createState() => _AddContactRowState();
}

class _AddContactRowState extends State<_AddContactRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = widget.isDark ? _dSurface : _lSurface;
    final border = widget.isDark ? _dBorder  : _lBorder;
    final accent = widget.isDark ? _infoDark : _info;

    return Semantics(
      button: true, label: l.t('sos_add_contact'),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1)),
            padding: const EdgeInsets.symmetric(
                horizontal: _sp16, vertical: _sp16),
            child: Row(children: [
              Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: accent, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18)),
              const SizedBox(width: _sp16),
              Text(l.t('sos_add_contact'),
                  style: _body(15, accent, w: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Capabilities card ─────────────────────────────────────────────────
class _CapabilitiesCard extends StatelessWidget {
  final bool isDark;
  const _CapabilitiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final isMobile = PlatformHelper.isMobile;
    final caps = isMobile
        ? [
      (_danger,  Icons.sms_rounded,           l.t('sos_cap_mobile_1_title'), l.t('sos_cap_mobile_1_desc')),
      (_info,    Icons.vibration_rounded,      l.t('sos_cap_mobile_2_title'), l.t('sos_cap_mobile_2_desc')),
      (_success, Icons.location_on_rounded,    l.t('sos_cap_mobile_3_title'), l.t('sos_cap_mobile_3_desc')),
      (_warning, Icons.notifications_rounded,  l.t('sos_cap_mobile_4_title'), l.t('sos_cap_mobile_4_desc')),
    ]
        : [
      (_info,    Icons.chat_bubble_rounded,    l.t('sos_cap_web_1_title'), l.t('sos_cap_web_1_desc')),
      (_success, Icons.location_on_rounded,    l.t('sos_cap_web_2_title'), l.t('sos_cap_web_2_desc')),
      (_warning, Icons.content_copy_rounded,   l.t('sos_cap_web_3_title'), l.t('sos_cap_web_3_desc')),
      (_danger,  Icons.link_rounded,           l.t('sos_cap_web_4_title'), l.t('sos_cap_web_4_desc')),
    ];

    final bg      = isDark ? _dSurface  : _lSurface;
    final border  = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText     : _lText;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final header  = isMobile
        ? (isDark ? _dangerDark : _danger)
        : (isDark ? _infoDark   : _info);

    Color dv(Color c) {
      if (c == _danger)  return isDark ? _dangerDark  : _danger;
      if (c == _info)    return isDark ? _infoDark    : _info;
      if (c == _success) return isDark ? _successDark : _success;
      if (c == _warning) return isDark ? _warningDark : _warning;
      return c;
    }

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMobile ? Icons.smartphone_rounded : Icons.language_rounded,
              color: header, size: 14),
          const SizedBox(width: _sp8),
          Text(isMobile
              ? l.t('sos_mobile_features')
              : l.t('sos_web_features'),
              style: _label(11.5, header, w: FontWeight.w700)),
        ]),
        const SizedBox(height: _sp16),
        Row(children: caps.asMap().entries.map((e) {
          final i    = e.key;
          final c    = e.value;
          final last = i == caps.length - 1;
          final ac   = dv(c.$1);
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: last ? 0 : _sp8),
            child: Column(children: [
              Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: ac.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(c.$2, color: ac, size: 20)),
              const SizedBox(height: _sp8),
              Text(c.$3, style: _label(10.5, textClr, w: FontWeight.w700),
                  textAlign: TextAlign.center),
              Text(c.$4, style: _body(9.5, subClr),
                  textAlign: TextAlign.center),
            ]),
          ));
        }).toList()),
      ]),
    );
  }
}

// ── Shake info card ───────────────────────────────────────────────────
class _ShakeInfoCard extends StatelessWidget {
  final bool isDark;
  const _ShakeInfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _infoDark : _info;

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1)),
      child: Row(children: [
        Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.vibration_rounded, color: accent, size: 22)),
        const SizedBox(width: _sp16),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.t('sos_shake_active'),
                  style: _label(14, textClr, w: FontWeight.w700)),
              const SizedBox(height: _sp4),
              Text(l.t('sos_shake_body_setup'),
                  style: _body(12, subClr)),
            ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  WEB COMPONENTS
// ══════════════════════════════════════════════════════════════════════
class _WebPageHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  const _WebPageHeader({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final navBlue = isDark ? _infoDark   : _info;
    final accent  = isDark ? _dangerDark : _danger;
    final textClr = isDark ? _dText      : _lText;
    final subClr  = isDark ? _dTextSub   : _lTextSub;

    return Semantics(
      header: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: _sp4, horizontal: _sp4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: navBlue, size: 20),
              Text(l.t('sos_setup_back'),
                  style: _body(14, navBlue, w: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(height: _sp20),
        Row(children: [
          Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.contacts_rounded, color: accent, size: 24)),
          const SizedBox(width: _sp16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('sos_setup_title'), style: _display(22, textClr)),
            Text(l.t('sos_setup_subtitle'), style: _body(13, subClr)),
          ]),
        ]),
      ]),
    );
  }
}

class _WebContactsPanel extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(int) onDelete, onSetPrimary;
  final void Function(EmergencyContact, int) onEdit;
  const _WebContactsPanel({required this.contacts, required this.isDark,
    required this.onAdd, required this.onDelete,
    required this.onSetPrimary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l          = AppLocalizations.of(context);
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final subClr     = isDark ? _dTextSub : _lTextSub;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(contacts.isEmpty
            ? l.t('sos_no_contacts_yet')
            : l.t('sos_contacts_count').replaceAll('{n}', '${contacts.length}'),
            style: _label(12, subClr, w: FontWeight.w700)),
        const Spacer(),
        if (contacts.isNotEmpty)
          _ContactCountBadge(count: contacts.length,
              hasPrimary: hasPrimary, isDark: isDark),
      ]),
      const SizedBox(height: _sp12),

      if (contacts.isEmpty)
        _EmptyContactsCard(isDark: isDark)
      else
        _ContactList(
            contacts: contacts, isDark: isDark,
            onDelete: onDelete, onSetPrimary: onSetPrimary, onEdit: onEdit),

      const SizedBox(height: _sp8),
      if (contacts.length < 5)
        _WebAddButton(isDark: isDark, onTap: onAdd),
    ]);
  }
}

class _WebAddButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _WebAddButton({required this.isDark, required this.onTap});
  @override
  State<_WebAddButton> createState() => _WebAddButtonState();
}

class _WebAddButtonState extends State<_WebAddButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final accent = widget.isDark ? _infoDark : _info;
    final border = widget.isDark ? _dBorder  : _lBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true, label: l.t('sos_add_contact'),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: _sp16),
            decoration: BoxDecoration(
                color: _hovered ? accent.withOpacity(0.06) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _hovered ? accent.withOpacity(0.35) : border,
                    width: _hovered ? 1.5 : 1.0)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_rounded, color: accent, size: 18),
              const SizedBox(width: _sp8),
              Text(l.t('sos_add_contact'),
                  style: _body(14, accent, w: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  CONTACT FORM DIALOG
//  UX4G: clear field labels, danger for errors, relation chips with
//        semantic colors, accessible cancel/confirm pair
// ══════════════════════════════════════════════════════════════════════
class _ContactFormDialog extends StatefulWidget {
  final EmergencyContact? existing;
  final bool isDark;
  final Function(EmergencyContact) onSave;
  const _ContactFormDialog({this.existing, required this.isDark,
    required this.onSave});
  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String _relation = 'Family';
  bool   _saving   = false;

  static const _relations = [
    'Family', 'Parent', 'Sibling', 'Spouse',
    'Friend', 'Doctor', 'Caretaker', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.existing?.name  ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _relation  = widget.existing?.relation ?? 'Family';
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final sep    = isDark ? _dBorderSub : _lBorderSub;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final accent  = isDark ? _infoDark : _info;
    final isEdit  = widget.existing != null;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1)),
      insetPadding: const EdgeInsets.symmetric(horizontal: _sp20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(_sp24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(children: [
                  Expanded(child: Text(
                      isEdit
                          ? l.t('sos_edit_contact')
                          : l.t('sos_new_contact'),
                      style: _heading(18, textClr))),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: isDark ? _dSurface2 : _lSurface2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border, width: 1)),
                        child: Icon(Icons.close_rounded,
                            color: mutedClr, size: 16)),
                  ),
                ]),
                const SizedBox(height: _sp4),
                Text(l.t('sos_will_notify'),
                    style: _body(13, subClr)),
                const SizedBox(height: _sp20),
                Divider(height: 1, thickness: 1, color: sep),
                const SizedBox(height: _sp20),

                // Name field
                _FieldLabel(text: l.t('sos_full_name'), isDark: isDark),
                const SizedBox(height: _sp8),
                _UX4GTextField(
                    controller: _nameCtrl,
                    hint: l.t('sos_name_hint'),
                    isDark: isDark,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.t('sos_name_required') : null),

                const SizedBox(height: _sp16),

                // Phone field
                _FieldLabel(text: l.t('sos_phone'), isDark: isDark),
                const SizedBox(height: _sp8),
                _UX4GTextField(
                    controller: _phoneCtrl,
                    hint: l.t('sos_phone_hint'),
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                    prefixText: '+91  ',
                    prefixColor: accent,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.t('sos_phone_required');
                      }
                      final c = v.replaceAll(
                          RegExp(r'[\s\-\(\)\+]'), '');
                      if (c.length < 10 ||
                          !RegExp(r'^\d+$').hasMatch(c)) {
                        return l.t('sos_phone_invalid10');
                      }
                      return null;
                    }),

                const SizedBox(height: _sp16),

                // Relation chips
                _FieldLabel(text: l.t('sos_relation'), isDark: isDark),
                const SizedBox(height: _sp12),
                Wrap(spacing: _sp8, runSpacing: _sp8,
                    children: _relations.map((r) {
                      final selected  = r == _relation;
                      final chipAccent = _accentFor(r, isDark);
                      return GestureDetector(
                        onTap: () => setState(() => _relation = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(
                              horizontal: _sp12, vertical: _sp8),
                          decoration: BoxDecoration(
                              color: selected
                                  ? chipAccent.withOpacity(0.12)
                                  : (isDark ? _dSurface2 : _lSurface2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selected
                                      ? chipAccent.withOpacity(0.40)
                                      : border,
                                  width: selected ? 1.5 : 1.0)),
                          child: Text(_relationLabel(l, r),
                              style: _label(12.5,
                                  selected ? chipAccent : subClr,
                                  w: selected
                                      ? FontWeight.w700 : FontWeight.w400)),
                        ),
                      );
                    }).toList()),

                const SizedBox(height: _sp24),

                // Action buttons — cancel left, confirm right
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: border, width: 1)),
                    child: Text(l.t('sos_cancel'),
                        style: _body(15, subClr, w: FontWeight.w600)),
                  )),
                  const SizedBox(width: _sp12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                        : Text(
                        isEdit
                            ? l.t('sos_save_changes')
                            : l.t('sos_add_btn'),
                        style: _label(15, Colors.white,
                            w: FontWeight.w700)),
                  )),
                ]),
              ]),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    widget.onSave(EmergencyContact(
        name:      _nameCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim(),
        relation:  _relation,
        isPrimary: widget.existing?.isPrimary ?? false));
    if (mounted) Navigator.pop(context);
  }
}

// ── Field label ───────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel({required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(text,
      style: _label(12, isDark ? _dTextSub : _lTextSub,
          w: FontWeight.w700));
}

// ── UX4G text field ───────────────────────────────────────────────────
class _UX4GTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool isDark;
  final String? prefixText;
  final Color? prefixColor;
  final String? Function(String?)? validator;
  const _UX4GTextField({
    required this.controller, required this.hint,
    this.keyboardType = TextInputType.text,
    required this.isDark, this.prefixText,
    this.prefixColor, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? _dSurface2 : _lSurface2;
    final border = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final hintClr = isDark ? _dTextMuted : _lTextMuted;
    final accent  = isDark ? _infoDark : _info;
    final radius  = BorderRadius.circular(8);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: _body(15, textClr),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _body(15, hintClr),
        prefixText: prefixText,
        prefixStyle: prefixText != null
            ? _label(15, prefixColor ?? accent, w: FontWeight.w600)
            : null,
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: _sp16, vertical: _sp16),
        border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: border, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
                color: isDark ? _dangerDark : _danger, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
                color: isDark ? _dangerDark : _danger, width: 2)),
        errorStyle: _label(11,
            isDark ? _dangerDark : _danger, w: FontWeight.w600),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  UX4G ALERT DIALOG
//  UX4G: destructive action uses danger color; cancel is neutral
// ══════════════════════════════════════════════════════════════════════
class _UX4GAlertDialog extends StatelessWidget {
  final String title, message, destructiveLabel;
  final VoidCallback onDestructive;
  const _UX4GAlertDialog({required this.title, required this.message,
    required this.destructiveLabel, required this.onDestructive});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? _dSurface  : _lSurface;
    final border  = isDark ? _dBorder   : _lBorder;
    final sep     = isDark ? _dBorderSub : _lBorderSub;
    final textClr = isDark ? _dText     : _lText;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final redClr  = isDark ? _dangerDark : _danger;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _sp24, _sp24, _sp24, _sp16),
            child: Column(children: [
              // Danger icon — prominent
              Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: isDark
                          ? _dangerDark.withOpacity(0.12)
                          : _dangerLight,
                      shape: BoxShape.circle),
                  child: Icon(Icons.delete_forever_rounded,
                      color: redClr, size: 24)),
              const SizedBox(height: _sp12),
              Text(title, textAlign: TextAlign.center,
                  style: _heading(17, textClr)),
              const SizedBox(height: _sp8),
              Text(message, textAlign: TextAlign.center,
                  style: _body(13, subClr)),
            ]),
          ),
          Divider(height: 1, thickness: 1, color: sep),
          IntrinsicHeight(child: Row(children: [
            // Cancel
            Expanded(child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: _sp16),
                decoration: BoxDecoration(border: Border(
                    right: BorderSide(color: sep, width: 1))),
                child: Center(child: Text(
                    AppLocalizations.of(context).t('sos_cancel'),
                    style: _body(16, isDark ? _infoDark : _info,
                        w: FontWeight.w500))),
              ),
            )),
            // Destructive
            Expanded(child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onDestructive();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _sp16),
                child: Center(child: Text(destructiveLabel,
                    style: _body(16, redClr, w: FontWeight.w700))),
              ),
            )),
          ])),
        ]),
      ),
    );
  }
}