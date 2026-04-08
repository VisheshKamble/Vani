// lib/screens/EmergencySetupScreen.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Setup  · Apple-Minimal Redesign                  ║
// ║  Aesthetic: Refined minimal, SF-inspired depth, frosted surfaces   ║
// ║  Fixes: Keyboard avoidance, dialog overflow, form scroll           ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import '../services/EmergencyService.dart';
import '../utils/PlatformHelper.dart';

// ─────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Apple-inspired refined palette
// ─────────────────────────────────────────────────────────────────────
const _fontFamily = 'Plus Jakarta Sans';

// Semantic
const _danger      = Color(0xFFFF3B30);  // iOS red
const _dangerSoft  = Color(0xFFFFEEED);
const _warning     = Color(0xFFFF9500);  // iOS orange
const _warningSoft = Color(0xFFFFF4E6);
const _success     = Color(0xFF34C759);  // iOS green
const _successSoft = Color(0xFFEAF7EE);
const _info        = Color(0xFF007AFF);  // iOS blue
const _infoSoft    = Color(0xFFE5F1FF);

// Dark semantic
const _dangerD  = Color(0xFFFF453A);
const _warningD = Color(0xFFFF9F0A);
const _successD = Color(0xFF32D74B);
const _infoD    = Color(0xFF0A84FF);

// Relation colors — muted, Apple-style
const _relColors = {
  'Family':    [Color(0xFF007AFF), Color(0xFF0A84FF)],
  'Parent':    [Color(0xFF5856D6), Color(0xFF5E5CE6)],
  'Sibling':   [Color(0xFF34C759), Color(0xFF32D74B)],
  'Spouse':    [Color(0xFFFF3B30), Color(0xFFFF453A)],
  'Friend':    [Color(0xFFFF9500), Color(0xFFFF9F0A)],
  'Doctor':    [Color(0xFF00C7BE), Color(0xFF63E6E2)],
  'Caretaker': [Color(0xFFAF52DE), Color(0xFFBF5AF2)],
  'Other':     [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
};

// Light surfaces
const _lBg       = Color(0xFFF2F2F7);   // iOS grouped background
const _lSurface  = Color(0xFFFFFFFF);
const _lSurface2 = Color(0xFFF2F2F7);
const _lBorder   = Color(0xFFE5E5EA);
const _lSep      = Color(0xFFC6C6C8);
const _lText     = Color(0xFF000000);
const _lTextSub  = Color(0xFF3C3C43);
const _lTextMuted = Color(0xFF8E8E93);

// Dark surfaces
const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dBorder   = Color(0xFF38383A);
const _dSep      = Color(0xFF48484A);
const _dText     = Color(0xFFFFFFFF);
const _dTextSub  = Color(0xFFAEAEB2);
const _dTextMuted = Color(0xFF636366);

// Spacing (8pt grid)
const _sp2  = 2.0;
const _sp4  = 4.0;
const _sp6  = 6.0;
const _sp8  = 8.0;
const _sp12 = 12.0;
const _sp14 = 14.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;
const _sp32 = 32.0;
const _sp48 = 48.0;

// ── Type helpers ──────────────────────────────────────────────────────
TextStyle _largeTitle(Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: 34, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: 0.37);

TextStyle _title1(Color c) => TextStyle(
    fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700,
    color: c, height: 1.2, letterSpacing: 0.34);

TextStyle _title2(Color c) => TextStyle(
  fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w700,
    color: c, height: 1.3, letterSpacing: 0.35);

TextStyle _title3(Color c) => TextStyle(
  fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w700,
    color: c, height: 1.3, letterSpacing: 0.38);

TextStyle _headline(Color c) => TextStyle(
  fontFamily: _fontFamily, fontSize: 17, fontWeight: FontWeight.w700,
    color: c, height: 1.3, letterSpacing: -0.41);

TextStyle _body(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 17, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.41);

TextStyle _callout(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.32);

TextStyle _subhead(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 15, fontWeight: w,
    color: c, height: 1.5, letterSpacing: -0.23);

TextStyle _footnote(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 13, fontWeight: w,
    color: c, height: 1.4, letterSpacing: -0.08);

TextStyle _caption(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: w,
    color: c, height: 1.3, letterSpacing: 0.0);

// ── Relation helpers ──────────────────────────────────────────────────
Color _accentFor(String r, bool dark) {
  final pair = _relColors[r] ?? _relColors['Other']!;
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
        duration: const Duration(milliseconds: 360));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero)
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
    return kIsWeb || w >= 700
      ? _buildWeb(context, contacts, isDark, w > 1100)
      : _buildMobile(context, contacts, isDark);
  }

  // ════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ════════════════════════════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) {
    final l          = AppLocalizations.of(ctx);
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final bg         = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            _AppleNavBar(
              isDark: isDark,
              title: l.t('sos_setup_title'),
              onBack: () => Navigator.pop(ctx),
              trailing: contacts.isNotEmpty
                  ? _PillBadge(
                  label: l
                    .t('sos_contacts_progress')
                    .replaceAll('{n}', '${contacts.length}'),
                  color: hasPrimary
                      ? (isDark ? _successD : _success)
                      : (isDark ? _warningD : _warning),
                  isDark: isDark)
                  : null,
            ),

            Expanded(child: SlideTransition(
              position: _entrySlide,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_sp16, _sp8, _sp16, _sp48),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Header description
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_sp4, _sp8, _sp4, _sp20),
                    child: Text(l.t('sos_setup_subtitle'),
                        style: _subhead(isDark ? _dTextMuted : _lTextMuted)),
                  ),

                  _CapabilitiesCard(isDark: isDark),
                  const SizedBox(height: _sp12),

                  if (PlatformHelper.supportsShake) ...[
                    _ShakeInfoCard(isDark: isDark),
                    const SizedBox(height: _sp12),
                  ],

                  // Section header
                  _SectionHeader(
                    title: contacts.isEmpty
                        ? l.t('sos_no_contacts_yet')
                        : 'CONTACTS',
                    trailing: (!hasPrimary && contacts.isNotEmpty)
                        ? _InlineWarning(label: l.t('sos_no_primary'), isDark: isDark)
                        : null,
                    isDark: isDark,
                  ),

                  if (contacts.isEmpty)
                    _EmptyState(isDark: isDark)
                  else
                    _ContactList(
                      contacts: contacts, isDark: isDark,
                      onDelete:     (i) => _confirmDelete(i),
                      onSetPrimary: (i) => _setPrimary(i),
                      onEdit:       (c, i) => _openForm(existing: c, index: i),
                    ),

                  if (contacts.length < 5) ...[
                    const SizedBox(height: _sp8),
                    _AddButton(isDark: isDark, onTap: () => _openForm()),
                  ],
                ],
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
    final w = MediaQuery.of(ctx).size.width;
    final compactWeb = w < 700;
    final hPad = isDesktop ? 80.0 : (compactWeb ? 16.0 : 40.0);
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

  Widget _webDesktopLayout(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 300, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _WebPageHeader(isDark: isDark, onBack: () => Navigator.pop(ctx)),
          const SizedBox(height: _sp24),
          _CapabilitiesCard(isDark: isDark),
          const SizedBox(height: _sp12),
          if (PlatformHelper.supportsShake) ...[
            _ShakeInfoCard(isDark: isDark),
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

  Widget _webTabletLayout(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    showCupertinoStyleDialog(
      context: context,
      isDark: Theme.of(context).brightness == Brightness.dark,
      title: l.t('sos_remove_title'),
      message: l.t('sos_remove_body'),
      destructiveLabel: l.t('sos_remove_btn'),
      cancelLabel: l.t('sos_cancel'),
      onDestructive: () async {
        await _service.deleteContact(index);
        if (mounted) setState(() {});
      },
    );
  }

  void _setPrimary(int index) async {
    HapticFeedback.selectionClick();
    await _service.setPrimary(index);
    if (mounted) setState(() {});
  }

  void _openForm({EmergencyContact? existing, int? index}) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (_) => _ContactFormSheet(
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
              _showToast(l.t('sos_generic_error'), ok: false);
            }
          }
        },
      ),
    );
  }

  void _showToast(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: _sp8),
          Expanded(child: Text(msg,
              style: _subhead(Colors.white, w: FontWeight.w500))),
        ]),
        backgroundColor: ok
            ? (Theme.of(context).brightness == Brightness.dark ? _successD : _success)
            : (Theme.of(context).brightness == Brightness.dark ? _dangerD  : _danger),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_sp16),
        padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3)));
  }
}

// ── Cupertino-style dialog ────────────────────────────────────────────
void showCupertinoStyleDialog({
  required BuildContext context,
  required bool isDark,
  required String title,
  required String message,
  required String destructiveLabel,
  required String cancelLabel,
  required VoidCallback onDestructive,
}) {
  final bg     = isDark ? _dSurface : _lSurface;
  final border = isDark ? _dBorder  : _lBorder;
  final sep    = isDark ? _dSep     : _lSep;
  final textClr = isDark ? _dText   : _lText;
  final subClr  = isDark ? _dTextSub : _lTextSub;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 0.5)),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_sp20, _sp20, _sp20, _sp16),
            child: Column(children: [
              Text(title, textAlign: TextAlign.center,
                  style: _headline(textClr)),
              const SizedBox(height: _sp6),
              Text(message, textAlign: TextAlign.center,
                  style: _footnote(subClr)),
            ]),
          ),
          Divider(height: 0.5, thickness: 0.5, color: sep),
          IntrinsicHeight(child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                decoration: BoxDecoration(border: Border(
                    right: BorderSide(color: sep, width: 0.5))),
                alignment: Alignment.center,
                child: Text(cancelLabel,
                    style: _callout(isDark ? _infoD : _info)),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(context); onDestructive(); },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 44,
                child: Center(child: Text(destructiveLabel,
                    style: _callout(isDark ? _dangerD : _danger,
                        w: FontWeight.w600))),
              ),
            )),
          ])),
        ]),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  APPLE NAV BAR
// ══════════════════════════════════════════════════════════════════════
class _AppleNavBar extends StatelessWidget {
  final bool isDark;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  const _AppleNavBar({required this.isDark, required this.title,
    required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? _dSurface.withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94);
    final border  = isDark ? _dBorder  : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final accent  = isDark ? _infoD    : _info;
    final l       = AppLocalizations.of(context);

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _sp8, vertical: _sp8),
        child: Row(children: [
          // Back button
          _TapTarget(
            onTap: onBack,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: accent, size: 28),
              Text(l.t('common_back'),
                  style: _callout(accent, w: FontWeight.w400)),
            ]),
          ),
          Expanded(child: Center(
            child: Text(title, style: _headline(textClr)),
          )),
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: _sp8), child: trailing!)
          else
            const SizedBox(width: 64),
        ]),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────
class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _PillBadge({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: _sp10, vertical: _sp4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5)),
    child: Text(label, style: _caption(color, w: FontWeight.w700)),
  );
}

// Helper
const _sp10 = 10.0;

// ── Section header ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isDark;
  const _SectionHeader({required this.title, this.trailing, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(_sp4, _sp16, _sp4, _sp8),
    child: Row(children: [
      Text(title,
          style: _caption(isDark ? _dTextMuted : _lTextMuted, w: FontWeight.w600)),
      if (trailing != null) ...[const Spacer(), trailing!],
    ]),
  );
}

// ── Inline warning ────────────────────────────────────────────────────
class _InlineWarning extends StatelessWidget {
  final String label;
  final bool isDark;
  const _InlineWarning({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? _warningD : _warning;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.info_outline_rounded, color: color, size: 11),
      const SizedBox(width: 3),
      Text(label, style: _caption(color, w: FontWeight.w600)),
    ]);
  }
}

// ── Empty state ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final accent  = isDark ? _dangerD  : _danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: _sp24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 20, offset: const Offset(0, 4)),
          ]),
      child: Column(children: [
        Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle),
            child: Icon(Icons.person_add_rounded, color: accent, size: 26)),
        const SizedBox(height: _sp16),
        Text(l.t('sos_add_first'),
            style: _headline(textClr)),
        const SizedBox(height: _sp6),
        Text(l.t('sos_add_first_body'), textAlign: TextAlign.center,
            style: _footnote(subClr)),
      ]),
    );
  }
}

// ── Contact list (grouped, iOS-style) ────────────────────────────────
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
    final sep    = isDark ? _dSep      : _lBorder;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 20, offset: const Offset(0, 4)),
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: contacts.asMap().entries.map((e) {
          final i = e.key; final c = e.value;
          return Column(children: [
            _ContactCell(contact: c, index: i, isDark: isDark,
                onDelete:     () => onDelete(i),
                onSetPrimary: () => onSetPrimary(i),
                onEdit:       () => onEdit(c, i)),
            if (i < contacts.length - 1)
              Divider(indent: 72, endIndent: 0, height: 0.5,
                  thickness: 0.5, color: sep),
          ]);
        }).toList()),
      ),
    );
  }
}

class _ContactCell extends StatefulWidget {
  final EmergencyContact contact;
  final int index;
  final bool isDark;
  final VoidCallback onDelete, onSetPrimary, onEdit;
  const _ContactCell({required this.contact, required this.index,
    required this.isDark, required this.onDelete,
    required this.onSetPrimary, required this.onEdit});
  @override
  State<_ContactCell> createState() => _ContactCellState();
}

class _ContactCellState extends State<_ContactCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final c      = widget.contact;
    final isDark = widget.isDark;
    final accent = _accentFor(c.relation, isDark);
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;
    final pressedBg = isDark ? _dSurface2 : const Color(0xFFF5F5F7);
    final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed ? pressedBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp12),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Center(child: Text(initial,
                  style: TextStyle(fontFamily: _fontFamily, fontSize: 18,
                      fontWeight: FontWeight.w600, color: accent))),
            ),
            if (c.isPrimary)
              Positioned(right: 0, bottom: 0, child: Container(
                  width: 15, height: 15,
                  decoration: BoxDecoration(
                      color: isDark ? _dangerD : _danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? _dSurface : _lSurface, width: 1.5)),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 8))),
          ]),
          const SizedBox(width: _sp14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(c.name,
                  style: _subhead(textClr, w: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: _sp6),
              _MicroChip(label: _relationLabel(l, c.relation),
                  color: accent, isDark: isDark),
            ]),
            const SizedBox(height: _sp2),
            Text(c.phone, style: _footnote(subClr)),
          ])),

          // Action menu
          _TapTarget(
            onTap: () => _showActionSheet(context, l, isDark),
            child: Icon(Icons.more_horiz, color: mutedClr, size: 20),
          ),
        ]),
      ),
    );
  }

  void _showActionSheet(BuildContext ctx, AppLocalizations l, bool isDark) {
    final bg     = isDark ? _dSurface  : _lSurface;
    final border = isDark ? _dBorder   : _lBorder;
    final sep    = isDark ? _dSep      : _lSep;
    final textClr = isDark ? _dText    : _lText;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(_sp16, 0, _sp16,
            MediaQuery.of(ctx).padding.bottom + _sp8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Actions card
          Container(
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24, offset: const Offset(0, 8)),
                ]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (!widget.contact.isPrimary)
                _SheetAction(
                  label: l.t('sos_set_primary'),
                  icon: Icons.star_rounded,
                  color: isDark ? _infoD : _info,
                  isDark: isDark,
                  onTap: () { Navigator.pop(ctx); widget.onSetPrimary(); },
                  showDivider: true, sep: sep,
                ),
              _SheetAction(
                label: l.t('sos_edit_btn'),
                icon: Icons.edit_rounded,
                color: textClr,
                isDark: isDark,
                onTap: () { Navigator.pop(ctx); widget.onEdit(); },
                showDivider: true, sep: sep,
              ),
              _SheetAction(
                label: l.t('sos_remove_menu'),
                icon: Icons.delete_outline_rounded,
                color: isDark ? _dangerD : _danger,
                isDark: isDark,
                onTap: () { Navigator.pop(ctx); widget.onDelete(); },
                showDivider: false, sep: sep,
              ),
            ]),
          ),
          const SizedBox(height: _sp8),
          // Cancel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 0.5)),
            child: _SheetAction(
              label: l.t('sos_cancel'),
              icon: null,
              color: isDark ? _infoD : _info,
              isDark: isDark,
              onTap: () => Navigator.pop(ctx),
              showDivider: false, sep: sep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Sheet action row ──────────────────────────────────────────────────
class _SheetAction extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isDark, showDivider;
  final Color sep;
  final VoidCallback onTap;
  final FontWeight fontWeight;
  const _SheetAction({required this.label, required this.icon,
    required this.color, required this.isDark, required this.onTap,
    required this.showDivider, required this.sep,
    this.fontWeight = FontWeight.w400});
  @override State<_SheetAction> createState() => _SheetActionState();
}

class _SheetActionState extends State<_SheetAction> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final pressedBg = widget.isDark ? _dSurface2 : const Color(0xFFF5F5F7);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: _pressed ? pressedBg : Colors.transparent,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: _sp20),
          child: Row(children: [
            Expanded(child: Text(widget.label,
                style: _callout(widget.color, w: widget.fontWeight),
                textAlign: widget.icon == null ? TextAlign.center : TextAlign.start)),
            if (widget.icon != null)
              Icon(widget.icon, color: widget.color, size: 18),
          ]),
        ),
      ),
      if (widget.showDivider)
        Divider(height: 0.5, thickness: 0.5,
            indent: _sp20, color: widget.sep),
    ]);
  }
}

// ── Micro chip ────────────────────────────────────────────────────────
class _MicroChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _MicroChip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: _sp6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.5)),
    child: Text(label, style: _caption(color, w: FontWeight.w600)),
  );
}

// ── Add button ────────────────────────────────────────────────────────
class _AddButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddButton({required this.isDark, required this.onTap});
  @override State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final bg     = widget.isDark ? _dSurface : _lSurface;
    final border = widget.isDark ? _dBorder  : _lBorder;
    final accent = widget.isDark ? _infoD    : _info;
    final pressedBg = widget.isDark ? _dSurface2 : const Color(0xFFF5F5F7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
            color: _pressed ? pressedBg : bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: widget.isDark ? 0.18 : 0.04),
                  blurRadius: 16, offset: const Offset(0, 3)),
            ]),
        padding: const EdgeInsets.symmetric(horizontal: _sp16, vertical: _sp14),
        child: Row(children: [
          Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: accent, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 16)),
          const SizedBox(width: _sp14),
          Text(l.t('sos_add_contact'),
              style: _callout(accent, w: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Tap target helper ─────────────────────────────────────────────────
class _TapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapTarget({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(_sp8),
      child: child,
    ),
  );
}

// ── Capabilities card ─────────────────────────────────────────────────
class _CapabilitiesCard extends StatelessWidget {
  final bool isDark;
  const _CapabilitiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final isMobile = PlatformHelper.isMobile;
    final caps     = isMobile ? [
      (_danger,  Icons.message_rounded,        l.t('sos_cap_mobile_1_title'), l.t('sos_cap_mobile_1_desc')),
      (_info,    Icons.vibration_rounded,      l.t('sos_cap_mobile_2_title'), l.t('sos_cap_mobile_2_desc')),
      (_success, Icons.location_on_rounded,    l.t('sos_cap_mobile_3_title'), l.t('sos_cap_mobile_3_desc')),
      (_warning, Icons.notifications_rounded,  l.t('sos_cap_mobile_4_title'), l.t('sos_cap_mobile_4_desc')),
    ] : [
      (_info,    Icons.chat_bubble_rounded,    l.t('sos_cap_web_1_title'), l.t('sos_cap_web_1_desc')),
      (_success, Icons.location_on_rounded,    l.t('sos_cap_web_2_title'), l.t('sos_cap_web_2_desc')),
      (_warning, Icons.content_copy_rounded,   l.t('sos_cap_web_3_title'), l.t('sos_cap_web_3_desc')),
      (_danger,  Icons.link_rounded,           l.t('sos_cap_web_4_title'), l.t('sos_cap_web_4_desc')),
    ];

    final bg      = isDark ? _dSurface  : _lSurface;
    final border  = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText     : _lText;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final mutedClr = isDark ? _dTextMuted : _lTextMuted;

    Color resolve(Color c) {
      if (c == _danger)  return isDark ? _dangerD  : _danger;
      if (c == _info)    return isDark ? _infoD    : _info;
      if (c == _success) return isDark ? _successD : _success;
      if (c == _warning) return isDark ? _warningD : _warning;
      return c;
    }

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 16, offset: const Offset(0, 3)),
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMobile ? Icons.phone_iphone_rounded : Icons.language_rounded,
              color: mutedClr, size: 12),
          const SizedBox(width: _sp6),
          Text(isMobile ? l.t('sos_mobile_features') : l.t('sos_web_features'),
              style: _caption(mutedClr, w: FontWeight.w600)),
        ]),
        const SizedBox(height: _sp16),
        Row(children: caps.asMap().entries.map((e) {
          final i    = e.key;
          final cap  = e.value;
          final last = i == caps.length - 1;
          final ac   = resolve(cap.$1);
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: last ? 0 : _sp8),
            child: Column(children: [
              Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: ac.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(cap.$2, color: ac, size: 20)),
              const SizedBox(height: _sp8),
              Text(cap.$3,
                  style: _caption(textClr, w: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: _sp2),
              Text(cap.$4, style: _caption(subClr),
                  textAlign: TextAlign.center, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ));
        }).toList()),
      ]),
    );
  }
}

// ── Shake card ────────────────────────────────────────────────────────
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
    final accent  = isDark ? _infoD    : _info;

    return Container(
      padding: const EdgeInsets.all(_sp16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                blurRadius: 14, offset: const Offset(0, 3)),
          ]),
      child: Row(children: [
        Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.vibration_rounded, color: accent, size: 20)),
        const SizedBox(width: _sp14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.t('sos_shake_active'),
                  style: _subhead(textClr, w: FontWeight.w600)),
              const SizedBox(height: _sp2),
              Text(l.t('sos_shake_body_setup'), style: _footnote(subClr)),
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
    final accent  = isDark ? _infoD    : _info;
    final textClr = isDark ? _dText    : _lText;
    final subClr  = isDark ? _dTextSub : _lTextSub;
    final iconBg  = isDark ? _dangerD  : _danger;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _TapTarget(
        onTap: onBack,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chevron_left_rounded, color: accent, size: 20),
          Text(l.t('sos_setup_back'),
              style: _callout(accent, w: FontWeight.w400)),
        ]),
      ),
      const SizedBox(height: _sp20),
      Row(children: [
        Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.contacts_rounded, color: iconBg, size: 22)),
        const SizedBox(width: _sp14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('sos_setup_title'), style: _title2(textClr)),
          Text(l.t('sos_setup_subtitle'), style: _footnote(subClr)),
        ]),
      ]),
    ]);
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
            : l.t('sos_setup_title').toUpperCase(),
            style: _caption(subClr, w: FontWeight.w600)),
        const Spacer(),
        if (contacts.isNotEmpty)
          _PillBadge(
              label: l
                  .t('sos_contacts_progress')
                  .replaceAll('{n}', '${contacts.length}'),
              color: hasPrimary
                  ? (isDark ? _successD : _success)
                  : (isDark ? _warningD : _warning),
              isDark: isDark),
      ]),
      const SizedBox(height: _sp12),

      if (contacts.isEmpty)
        _EmptyState(isDark: isDark)
      else
        _ContactList(
            contacts: contacts, isDark: isDark,
            onDelete: onDelete, onSetPrimary: onSetPrimary, onEdit: onEdit),

      if (contacts.length < 5) ...[
        const SizedBox(height: _sp8),
        _WebAddButton(isDark: isDark, onTap: onAdd),
      ],
    ]);
  }
}

class _WebAddButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _WebAddButton({required this.isDark, required this.onTap});
  @override State<_WebAddButton> createState() => _WebAddButtonState();
}

class _WebAddButtonState extends State<_WebAddButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final accent = widget.isDark ? _infoD : _info;
    final border = widget.isDark ? _dBorder : _lBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: _sp14),
          decoration: BoxDecoration(
              color: _hovered ? accent.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _hovered ? accent.withValues(alpha: 0.30) : border,
                  width: _hovered ? 1.0 : 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, color: accent, size: 16),
            const SizedBox(width: _sp6),
            Text(l.t('sos_add_contact'),
                style: _subhead(accent, w: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  CONTACT FORM — Bottom Sheet (fixes keyboard overflow)
//  Key: uses Padding + MediaQuery.viewInsets for keyboard avoidance
//  All content scrollable so nothing overflows
// ══════════════════════════════════════════════════════════════════════
class _ContactFormSheet extends StatefulWidget {
  final EmergencyContact? existing;
  final bool isDark;
  final Function(EmergencyContact) onSave;
  const _ContactFormSheet({this.existing, required this.isDark, required this.onSave});
  @override State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
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
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _nameFocus.dispose(); _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final isDark = widget.isDark;

    // Core colors
    final bg      = isDark ? _dSurface  : _lSurface;
    final handle  = isDark ? _dBorder   : const Color(0xFFD1D1D6);
    final border  = isDark ? _dBorder   : _lBorder;
    final sep     = isDark ? _dSep      : _lBorder;
    final textClr = isDark ? _dText     : _lText;
    final subClr  = isDark ? _dTextSub  : _lTextSub;
    final accent  = isDark ? _infoD     : _info;
    final isEdit  = widget.existing != null;

    // ── KEY FIX: use viewInsets to push content above keyboard ──────
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom  = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 40, offset: const Offset(0, -4)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: _sp12, bottom: _sp8),
              decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(_sp20, _sp4, _sp20, _sp16),
              child: Row(children: [
                Text(isEdit ? l.t('sos_edit_contact') : l.t('sos_new_contact'),
                    style: _headline(textClr)),
                const Spacer(),
                _TapTarget(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                          color: isDark ? _dSurface2 : const Color(0xFFEEEEF0),
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          color: isDark ? _dTextMuted : _lTextMuted, size: 14)),
                ),
              ]),
            ),

            Divider(height: 0.5, thickness: 0.5, color: sep),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                    _sp20, _sp20, _sp20, safeBottom + _sp20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name field
                      _FormLabel(text: l.t('sos_full_name'), isDark: isDark),
                      const SizedBox(height: _sp8),
                      _AppleTextField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        hint: l.t('sos_name_hint'),
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(_phoneFocus),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.t('sos_name_required') : null,
                      ),

                      const SizedBox(height: _sp20),

                      // Phone field
                      _FormLabel(text: l.t('sos_phone'), isDark: isDark),
                      const SizedBox(height: _sp8),
                      _AppleTextField(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        hint: l.t('sos_phone_hint'),
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        prefixText: '+91  ',
                        prefixColor: accent,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => FocusScope.of(context).unfocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.t('sos_phone_required');
                          }
                          final c = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                          if (c.length < 10 || !RegExp(r'^\d+$').hasMatch(c)) {
                            return l.t('sos_phone_invalid10');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: _sp20),

                      // Relation chips
                      _FormLabel(text: l.t('sos_relation'), isDark: isDark),
                      const SizedBox(height: _sp12),
                      Wrap(
                        spacing: _sp8,
                        runSpacing: _sp8,
                        children: _relations.map((r) {
                          final selected     = r == _relation;
                          final chipAccent   = _accentFor(r, isDark);
                          final unselBg      = isDark ? _dSurface2 : const Color(0xFFF2F2F7);
                          final unselBorder  = isDark ? _dBorder   : _lBorder;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _relation = r);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: _sp12, vertical: _sp8),
                              decoration: BoxDecoration(
                                  color: selected
                                      ? chipAccent.withValues(alpha: 0.10)
                                      : unselBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: selected
                                          ? chipAccent.withValues(alpha: 0.35)
                                          : unselBorder,
                                      width: selected ? 1.0 : 0.5)),
                              child: Text(_relationLabel(l, r),
                                  style: _footnote(
                                      selected ? chipAccent : subClr,
                                      w: selected
                                          ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: _sp28),

                      // Buttons
                      Row(children: [
                        Expanded(child: _OutlineBtn(
                          label: l.t('sos_cancel'),
                          onTap: () => Navigator.pop(context),
                          isDark: isDark,
                        )),
                        const SizedBox(width: _sp12),
                        Expanded(flex: 2, child: _FilledBtn(
                          label: isEdit
                              ? l.t('sos_save_changes')
                              : l.t('sos_add_btn'),
                          color: accent,
                          loading: _saving,
                          onTap: _saving ? null : _save,
                        )),
                      ]),
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

  void _save() async {
    FocusScope.of(context).unfocus();
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

const _sp28 = 28.0;

// ── Form label ────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FormLabel({required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(text,
      style: _caption(isDark ? _dTextMuted : _lTextMuted, w: FontWeight.w600));
}

// ── Apple text field ──────────────────────────────────────────────────
class _AppleTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final TextInputType keyboardType;
  final bool isDark;
  final String? prefixText;
  final Color? prefixColor;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;

  const _AppleTextField({
    required this.controller,
    this.focusNode,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.isDark,
    this.prefixText,
    this.prefixColor,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? _dSurface2 : const Color(0xFFF2F2F7);
    final border  = isDark ? _dBorder   : _lBorder;
    final textClr = isDark ? _dText     : _lText;
    final hintClr = isDark ? _dTextMuted : _lTextMuted;
    final accent  = isDark ? _infoD     : _info;
    final errClr  = isDark ? _dangerD   : _danger;
    final radius  = BorderRadius.circular(10);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      validator: validator,
      style: _callout(textClr),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _callout(hintClr),
        prefixText: prefixText,
        prefixStyle: prefixText != null
            ? _callout(prefixColor ?? accent, w: FontWeight.w500)
            : null,
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: _sp16, vertical: _sp14),
        border: OutlineInputBorder(borderRadius: radius,
            borderSide: BorderSide(color: border, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: radius,
            borderSide: BorderSide(color: border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: radius,
            borderSide: BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: radius,
            borderSide: BorderSide(color: errClr, width: 1.0)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius,
            borderSide: BorderSide(color: errClr, width: 1.5)),
        errorStyle: _caption(errClr, w: FontWeight.w500),
      ),
    );
  }
}

// ── Outline button ────────────────────────────────────────────────────
class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _OutlineBtn({required this.label, required this.onTap, required this.isDark});
  @override State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final border  = widget.isDark ? _dBorder : _lBorder;
    final subClr  = widget.isDark ? _dTextSub : _lTextSub;
    final pressedBg = widget.isDark ? _dSurface2 : const Color(0xFFF2F2F7);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 50,
        decoration: BoxDecoration(
            color: _pressed ? pressedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 0.5)),
        alignment: Alignment.center,
        child: Text(widget.label, style: _callout(subClr, w: FontWeight.w500)),
      ),
    );
  }
}

// ── Filled button ─────────────────────────────────────────────────────
class _FilledBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;
  const _FilledBtn({required this.label, required this.color,
    required this.loading, this.onTap});
  @override State<_FilledBtn> createState() => _FilledBtnState();
}

class _FilledBtnState extends State<_FilledBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) { setState(() => _pressed = false); widget.onTap!(); } : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 50,
        decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.80 : 1.0),
            borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: widget.loading
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(widget.label,
            style: _callout(Colors.white, w: FontWeight.w600)),
      ),
    );
  }
}
