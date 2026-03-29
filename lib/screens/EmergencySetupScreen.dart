// lib/screens/EmergencySetupScreen.dart
//
// ╔══════════════════════════════════════════════════════════╗
// ║  VANI — Emergency Setup  · Apple-Inspired Premium UI   ║
// ║  Font: Google Sans (SF Pro equivalent)                 ║
// ║  < 700px  → iOS Contacts Manager shell                 ║
// ║  ≥ 700px  → macOS Settings panel layout                ║
// ╚══════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import '../services/EmergencyService.dart';
import '../utils/PlatformHelper.dart';

// ─────────────────────────────────────────────────────────────
//  APPLE DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _red      = Color(0xFFFF3B30);
const _red_D    = Color(0xFFFF453A);
const _orange   = Color(0xFFFF9500);
const _orange_D = Color(0xFFFF9F0A);
const _blue     = Color(0xFF007AFF);
const _blue_D   = Color(0xFF0A84FF);
const _green    = Color(0xFF34C759);
const _green_D  = Color(0xFF30D158);
const _indigo   = Color(0xFF5856D6);
const _indigo_D = Color(0xFF5E5CE6);
const _teal     = Color(0xFF32ADE6);
const _teal_D   = Color(0xFF5AC8F5);
const _purple   = Color(0xFFAF52DE);
const _purple_D = Color(0xFFBF5AF2);
const _mint     = Color(0xFF00C7BE);
const _mint_D   = Color(0xFF63E6E2);

// Light surfaces
const _lBg       = Color(0xFFF2F2F7);
const _lSurface  = Color(0xFFFFFFFF);
const _lSep      = Color(0xFFC6C6C8);
const _lLabel    = Color(0xFF000000);
const _lLabel2   = Color(0x993C3C43);
const _lLabel3   = Color(0x4D3C3C43);
const _lFill     = Color(0x1F787880);

// Dark surfaces
const _dBg       = Color(0xFF000000);
const _dSurface  = Color(0xFF1C1C1E);
const _dSurface2 = Color(0xFF2C2C2E);
const _dSep      = Color(0xFF38383A);
const _dLabel    = Color(0xFFFFFFFF);
const _dLabel2   = Color(0x99EBEBF5);
const _dLabel3   = Color(0x4DEBEBF5);
const _dFill     = Color(0x3A787880);

// ── Text style shorthand ──────────────────────────────────────
TextStyle _t(double size, FontWeight w, Color c,
    {double ls = 0, double? h}) =>
    TextStyle(fontFamily: 'Google Sans',
        fontSize: size, fontWeight: w, color: c,
        letterSpacing: ls, height: h);

// ── Relation → system colour mapping ─────────────────────────
const _relationAccents = {
  'Family':    _blue,
  'Parent':    _teal,
  'Sibling':   _green,
  'Spouse':    _red,
  'Friend':    _orange,
  'Doctor':    _mint,
  'Caretaker': _purple,
  'Other':     Color(0xFF8E8E93),
};
Color _accentFor(String r, bool dark) {
  final base = _relationAccents[r] ?? const Color(0xFF8E8E93);
  if (!dark) return base;
  final map = {
    _blue: _blue_D, _teal: _teal_D, _green: _green_D,
    _red: _red_D, _orange: _orange_D, _mint: _mint_D,
    _purple: _purple_D,
  };
  return map[base] ?? base;
}

String _relationLabel(AppLocalizations l, String relationCode) {
  switch (relationCode) {
    case 'Family':
      return l.t('rel_family');
    case 'Parent':
      return l.t('rel_parent');
    case 'Sibling':
      return l.t('rel_sibling');
    case 'Spouse':
      return l.t('rel_spouse');
    case 'Friend':
      return l.t('rel_friend');
    case 'Doctor':
      return l.t('rel_doctor');
    case 'Caretaker':
      return l.t('rel_caretaker');
    case 'Other':
      return l.t('rel_other');
    default:
      return relationCode;
  }
}

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════
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
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
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

  // ════════════════════════════════════════════
  //  MOBILE  (<700px)  — iOS Contacts style
  // ════════════════════════════════════════════
  Widget _buildMobile(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) {
    final l = AppLocalizations.of(ctx);
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final bg     = isDark ? _dBg      : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [

            // ── iOS-style navigation bar ──────────
            _MobileNavBar(
              isDark: isDark, title: l.t('sos_setup_title'),
              subtitle: l.t('sos_setup_subtitle'),
              onBack: () => Navigator.pop(ctx),
              trailing: _ContactCountBadge(
                  count: contacts.length, hasPrimary: hasPrimary, isDark: isDark),
            ),

            // ── Body ─────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _entrySlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Capabilities strip — iOS "grouped list" card
                    _MobileCapabilitiesCard(isDark: isDark),
                    const SizedBox(height: 8),

                    // Shake card
                    if (PlatformHelper.supportsShake) ...[
                      _ShakeInfoCard(isDark: isDark),
                      const SizedBox(height: 8),
                    ],

                    // Section header — iOS grouped list header style
                    _GroupedSectionHeader(
                      title: contacts.isEmpty ? l.t('sos_no_contacts_yet') : l.t('sos_setup_title'),
                      trailing: (!hasPrimary && contacts.isNotEmpty)
                          ? _WarningChip(label: l.t('sos_no_primary'), isDark: isDark)
                          : null,
                      isDark: isDark,
                    ),

                    // Empty state
                    if (contacts.isEmpty)
                      _EmptyContactsCard(isDark: isDark),

                    // Contact list — iOS grouped list style
                    if (contacts.isNotEmpty)
                      _ContactList(
                        contacts: contacts, isDark: isDark,
                        onDelete:     (i) => _confirmDelete(i),
                        onSetPrimary: (i) => _setPrimary(i),
                        onEdit:       (c, i) => _openForm(existing: c, index: i),
                      ),

                    const SizedBox(height: 4),

                    // Add contact — iOS "+" list row
                    if (contacts.length < 5)
                      _AddContactRow(isDark: isDark, onTap: () => _openForm()),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  WEB / TABLET  (≥700px)  — macOS Settings
  // ════════════════════════════════════════════
  Widget _buildWeb(BuildContext ctx, List<EmergencyContact> contacts,
      bool isDark, bool isDesktop) {
    final hPad = isDesktop ? 96.0 : 52.0;
    final bg   = isDark ? _dBg : _lBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: Column(children: [
            GlobalNavbar(toggleTheme: widget.toggleTheme,
                setLocale: widget.setLocale, activeRoute: 'emergency'),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 64),
                physics: const BouncingScrollPhysics(),
                child: isDesktop
                    ? _webDesktopLayout(ctx, contacts, isDark)
                    : _webTabletLayout(ctx, contacts, isDark),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _webDesktopLayout(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Left — info panels
      SizedBox(
        width: 320,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _WebPageHeader(isDark: isDark, onBack: () => Navigator.pop(ctx)),
          const SizedBox(height: 28),
          _WebCapabilitiesCard(isDark: isDark),
          const SizedBox(height: 12),
          if (PlatformHelper.supportsShake) ...[
            _ShakeInfoCard(isDark: isDark),
            const SizedBox(height: 12),
          ],
        ]),
      ),
      const SizedBox(width: 48),
      // Right — contacts
      Expanded(child: _WebContactsPanel(
        contacts: contacts, isDark: isDark,
        onAdd:        () => _openForm(),
        onDelete:     (i) => _confirmDelete(i),
        onSetPrimary: (i) => _setPrimary(i),
        onEdit:       (c, i) => _openForm(existing: c, index: i),
      )),
    ]);
  }

  Widget _webTabletLayout(BuildContext ctx, List<EmergencyContact> contacts, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _WebPageHeader(isDark: isDark, onBack: () => Navigator.pop(ctx)),
      const SizedBox(height: 24),
      _WebCapabilitiesCard(isDark: isDark),
      const SizedBox(height: 20),
      _WebContactsPanel(
        contacts: contacts, isDark: isDark,
        onAdd:        () => _openForm(),
        onDelete:     (i) => _confirmDelete(i),
        onSetPrimary: (i) => _setPrimary(i),
        onEdit:       (c, i) => _openForm(existing: c, index: i),
      ),
      if (PlatformHelper.supportsShake) ...[
        const SizedBox(height: 12),
        _ShakeInfoCard(isDark: isDark),
      ],
    ]);
  }

  // ── Actions ──────────────────────────────────────────────
  void _confirmDelete(int index) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => _AppleAlertDialog(
        title: l.t('sos_remove_title'),
        message: l.t('sos_remove_body'),
        destructiveLabel: l.t('sos_remove_btn'),
        onDestructive: () async {
          await _service.deleteContact(index);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _setPrimary(int index) async {
    await _service.setPrimary(index);
    if (mounted) setState(() {});
  }

  void _openForm({EmergencyContact? existing, int? index}) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l.t('sos_generic_error'), style: _t(13, FontWeight.w500, Colors.white)),
                backgroundColor: _red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            }
          }
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MOBILE COMPONENTS
// ══════════════════════════════════════════════════════════════

// ── Mobile navigation bar ────────────────────────────────────
class _MobileNavBar extends StatelessWidget {
  final bool isDark;
  final String title, subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  const _MobileNavBar({required this.isDark, required this.title,
    required this.subtitle, required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface : _lSurface;
    final label  = isDark ? _dLabel   : _lLabel;
    final sep    = isDark ? _dSep     : _lSep.withOpacity(0.5);
    final accent = isDark ? _red_D    : _red;

    return Container(
      decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: sep, width: 0.5))),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        // iOS-style back chevron + label
        GestureDetector(
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chevron_left_rounded, color: accent, size: 28),
            Text(l.t('common_back'), style: _t(15, FontWeight.w400, accent)),
          ]),
        ),
        const Spacer(),
        // Centre title
        Column(children: [
          Text(title, style: _t(15, FontWeight.w600, label, ls: -0.2)),
          Text(subtitle, style: _t(11, FontWeight.w400, isDark ? _dLabel2 : _lLabel2)),
        ]),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _ContactCountBadge extends StatelessWidget {
  final int count;
  final bool hasPrimary, isDark;
  const _ContactCountBadge({required this.count, required this.hasPrimary,
    required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = hasPrimary ? (isDark ? _green_D : _green) : _orange;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.22), width: 0.5)),
      child: Text(AppLocalizations.of(context).t('sos_contacts_progress').replaceAll('{n}', '$count'),
            style: _t(11, FontWeight.w600, color)));
  }
}

// ── Grouped section header — iOS style ───────────────────────
class _GroupedSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isDark;
  const _GroupedSectionHeader({required this.title, this.trailing,
    required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(children: [
        Text(title.toUpperCase(),
            style: _t(11, FontWeight.w600,
                isDark ? _dLabel3 : _lLabel3, ls: 0.5)),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _WarningChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _WarningChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: _orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _orange.withOpacity(0.22), width: 0.5)),
      child: Text(label, style: _t(10, FontWeight.w600, _orange)));
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyContactsCard extends StatelessWidget {
  final bool isDark;
  const _EmptyContactsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = isDark ? _dSurface : _lSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: (isDark ? _red_D : _red).withOpacity(0.10),
                shape: BoxShape.circle),
            child: Icon(Icons.person_add_rounded,
                color: isDark ? _red_D : _red, size: 24)),
        const SizedBox(height: 14),
        Text(l.t('sos_add_first'),
            style: _t(16, FontWeight.w600, isDark ? _dLabel : _lLabel, ls: -0.2)),
        const SizedBox(height: 6),
        Text(l.t('sos_add_first_body'),
            textAlign: TextAlign.center,
            style: _t(13, FontWeight.w400, isDark ? _dLabel2 : _lLabel2, h: 1.55)),
      ]),
    );
  }
}

// ── Contact list (iOS grouped list cells) ────────────────────
class _ContactList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final bool isDark;
  final void Function(int) onDelete, onSetPrimary;
  final void Function(EmergencyContact, int) onEdit;
  const _ContactList({required this.contacts, required this.isDark,
    required this.onDelete, required this.onSetPrimary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? _dSurface  : _lSurface;
    final sep = isDark ? _dSep      : _lSep.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
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
            Divider(indent: 70, height: 0, thickness: 0.5,
                color: sep),
        ]);
      }).toList()),
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
  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final c      = widget.contact;
    final isDark = widget.isDark;
    final accent = _accentFor(c.relation, isDark);
    final label  = isDark ? _dLabel   : _lLabel;
    final label2 = isDark ? _dLabel2  : _lLabel2;
    final label3 = isDark ? _dLabel3  : _lLabel3;
    final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Avatar — iOS Contacts style
        Stack(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle),
            child: Center(child: Text(initial,
                style: _t(18, FontWeight.w700, accent))),
          ),
          if (c.isPrimary)
            Positioned(right: 0, bottom: 0, child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                  color: isDark ? _red_D : _red,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? _dSurface : _lSurface, width: 1.5)),
              child: const Center(child: Icon(Icons.star_rounded,
                  color: Colors.white, size: 8)),
            )),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(c.name, style: _t(15, FontWeight.w600, label, ls: -0.2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_relationLabel(l, c.relation), style: _t(10, FontWeight.w600, accent)),
            ),
          ]),
          const SizedBox(height: 2),
          Text(c.phone, style: _t(13, FontWeight.w400, label2)),
        ])),
        // iOS-style context menu trigger
        PopupMenuButton<String>(
          color: isDark ? _dSurface2 : _lSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 12,
          offset: const Offset(0, 8),
          icon: Icon(Icons.more_horiz_rounded, color: label3, size: 20),
          onSelected: (v) {
            if (v == 'edit')    widget.onEdit();
            if (v == 'primary') widget.onSetPrimary();
            if (v == 'delete')  widget.onDelete();
          },
          itemBuilder: (_) => [
            if (!c.isPrimary)
              _popupItem('primary', AppLocalizations.of(context).t('sos_set_primary'), Icons.star_rounded,
                  isDark ? _blue_D : _blue, isDark),
            _popupItem('edit', AppLocalizations.of(context).t('sos_edit_btn'), Icons.edit_rounded,
                isDark ? _dLabel : _lLabel, isDark),
            _popupItem('delete', AppLocalizations.of(context).t('sos_remove_menu'), Icons.delete_rounded,
                isDark ? _red_D : _red, isDark),
          ],
        ),
      ]),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label,
      IconData icon, Color color, bool isDark) =>
      PopupMenuItem(
          value: value, height: 44,
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Text(label, style: _t(14, FontWeight.w500, color)),
          ]));
}

// ── Add contact row ───────────────────────────────────────────
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
    final l = AppLocalizations.of(context);
    final bg     = widget.isDark ? _dSurface  : _lSurface;
    final accent = widget.isDark ? _blue_D    : _blue;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.black.withOpacity(widget.isDark ? 0.0 : 0.04), width: 0.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05),
                  blurRadius: 10, offset: const Offset(0, 3))]),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: accent, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 14),
            Text(l.t('sos_add_contact'),
                style: _t(15, FontWeight.w400, accent)),
          ]),
        ),
      ),
    );
  }
}

// ── Capabilities card (mobile) ───────────────────────────────
class _MobileCapabilitiesCard extends StatelessWidget {
  final bool isDark;
  const _MobileCapabilitiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isMobile = PlatformHelper.isMobile;
    final caps     = isMobile
        ? [
      (_red,    Icons.sms_rounded,           l.t('sos_cap_mobile_1_title'), l.t('sos_cap_mobile_1_desc')),
      (_indigo, Icons.vibration_rounded,     l.t('sos_cap_mobile_2_title'), l.t('sos_cap_mobile_2_desc')),
      (_teal,   Icons.location_on_rounded,   l.t('sos_cap_mobile_3_title'), l.t('sos_cap_mobile_3_desc')),
      (_green,  Icons.notifications_rounded, l.t('sos_cap_mobile_4_title'), l.t('sos_cap_mobile_4_desc')),
    ]
        : [
      (_blue,   Icons.chat_bubble_rounded,    l.t('sos_cap_web_1_title'), l.t('sos_cap_web_1_desc')),
      (_teal,   Icons.location_on_rounded,    l.t('sos_cap_web_2_title'), l.t('sos_cap_web_2_desc')),
      (_orange, Icons.content_copy_rounded,   l.t('sos_cap_web_3_title'), l.t('sos_cap_web_3_desc')),
      (_purple, Icons.link_rounded,           l.t('sos_cap_web_4_title'), l.t('sos_cap_web_4_desc')),
    ];

    final bg    = isDark ? _dSurface  : _lSurface;
    final label = isDark ? _dLabel    : _lLabel;
    final sub   = isDark ? _dLabel2   : _lLabel2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMobile
              ? Icons.smartphone_rounded : Icons.language_rounded,
              color: isDark ? _blue_D : _blue, size: 14),
          const SizedBox(width: 7),
            Text(isMobile
              ? l.t('sos_mobile_features') : l.t('sos_web_features'),
              style: _t(11, FontWeight.w600,
                  isDark ? _blue_D : _blue, ls: 0.3)),
        ]),
        const SizedBox(height: 14),
        Row(children: caps.asMap().entries.map((e) {
          final i    = e.key; final c = e.value;
          final last = i == caps.length - 1;
          final accent = isDark ? _darkOf(c.$1) : c.$1;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: last ? 0 : 8),
            child: Column(children: [
              Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(c.$2, color: accent, size: 18)),
              const SizedBox(height: 6),
              Text(c.$3, style: _t(10.5, FontWeight.w600, label)),
              Text(c.$4, style: _t(9, FontWeight.w400, sub), textAlign: TextAlign.center),
            ]),
          ));
        }).toList()),
      ]),
    );
  }

  Color _darkOf(Color c) {
    if (c == _red)    return _red_D;
    if (c == _indigo) return _indigo_D;
    if (c == _teal)   return _teal_D;
    if (c == _green)  return _green_D;
    if (c == _blue)   return _blue_D;
    if (c == _orange) return _orange_D;
    if (c == _purple) return _purple_D;
    return c;
  }
}

// ── Shake info card ───────────────────────────────────────────
class _ShakeInfoCard extends StatelessWidget {
  final bool isDark;
  const _ShakeInfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg     = isDark ? _dSurface  : _lSurface;
    final label  = isDark ? _dLabel    : _lLabel;
    final label2 = isDark ? _dLabel2   : _lLabel2;
    final accent = isDark ? _indigo_D  : _indigo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.vibration_rounded, color: accent, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('sos_shake_active'),
              style: _t(13.5, FontWeight.w600, label, ls: -0.2)),
          const SizedBox(height: 2),
            Text(l.t('sos_shake_body_setup'),
              style: _t(12, FontWeight.w400, label2, h: 1.45)),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB COMPONENTS
// ══════════════════════════════════════════════════════════════

class _WebPageHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  const _WebPageHeader({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = isDark ? _blue_D : _blue;
    final label  = isDark ? _dLabel  : _lLabel;
    final label2 = isDark ? _dLabel2 : _lLabel2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Back link — macOS style
      GestureDetector(
        onTap: onBack,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chevron_left_rounded, color: accent, size: 20),
          Text(l.t('sos_setup_back'), style: _t(14, FontWeight.w400, accent)),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: (isDark ? _red_D : _red).withOpacity(0.10),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.contacts_rounded,
              color: isDark ? _red_D : _red, size: 22)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('sos_setup_title'),
              style: _t(22, FontWeight.w700, label, ls: -0.5)),
            Text(l.t('sos_setup_subtitle'),
              style: _t(13, FontWeight.w400, label2)),
        ]),
      ]),
    ]);
  }
}

class _WebCapabilitiesCard extends StatelessWidget {
  final bool isDark;
  const _WebCapabilitiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isMobile = PlatformHelper.isMobile;
    final features = isMobile
        ? [
      (Icons.sms_rounded,            l.t('sos_web_cap_mobile_1')),
      (Icons.vibration_rounded,      l.t('sos_web_cap_mobile_2')),
      (Icons.location_on_rounded,    l.t('sos_web_cap_mobile_3')),
      (Icons.notifications_rounded,  l.t('sos_web_cap_mobile_4')),
    ]
        : [
      (Icons.chat_bubble_rounded,    l.t('sos_web_cap_web_1')),
      (Icons.location_on_rounded,    l.t('sos_web_cap_web_2')),
      (Icons.content_copy_rounded,   l.t('sos_web_cap_web_3')),
      (Icons.link_rounded,           l.t('sos_web_cap_web_4')),
    ];

    final bg     = isDark ? _dSurface  : _lSurface;
    final label2 = isDark ? _dLabel2   : _lLabel2;
    final accent = isDark ? _blue_D    : _blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.04), width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMobile ? Icons.smartphone_rounded : Icons.language_rounded,
              color: accent, size: 14),
          const SizedBox(width: 7),
          Text(isMobile ? l.t('sos_mobile_features') : l.t('sos_web_features'),
              style: _t(11, FontWeight.w600, accent, ls: 0.3)),
        ]),
        const SizedBox(height: 14),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(f.$1, color: accent, size: 14)),
            const SizedBox(width: 12),
            Expanded(child: Text(f.$2,
                style: _t(13, FontWeight.w400, label2, h: 1.4))),
          ]),
        )),
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
    final l = AppLocalizations.of(context);
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final label2     = isDark ? _dLabel2 : _lLabel2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Row(children: [
        Text(contacts.isEmpty
            ? l.t('sos_no_contacts_yet')
            : l.t('sos_contacts_count').replaceAll('{n}', '${contacts.length}'),
            style: _t(12, FontWeight.w600, label2, ls: 0.2)),
        const Spacer(),
        if (contacts.isNotEmpty)
          _ContactCountBadge(
              count: contacts.length, hasPrimary: hasPrimary, isDark: isDark),
      ]),
      const SizedBox(height: 12),

      if (contacts.isEmpty)
        _EmptyContactsCard(isDark: isDark)
      else
        _ContactList(
          contacts: contacts, isDark: isDark,
          onDelete:     onDelete,
          onSetPrimary: onSetPrimary,
          onEdit:       onEdit,
        ),

      const SizedBox(height: 8),
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
    final l = AppLocalizations.of(context);
    final accent = widget.isDark ? _blue_D : _blue;
    final sep    = widget.isDark ? _dSep : _lSep.withOpacity(0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: _hovered
                  ? accent.withOpacity(0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _hovered ? accent.withOpacity(0.30) : sep,
                  width: 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(l.t('sos_add_contact'),
                style: _t(14, FontWeight.w500, accent)),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CONTACT FORM SHEET  — iOS action sheet / modal card
// ══════════════════════════════════════════════════════════════
class _ContactFormSheet extends StatefulWidget {
  final EmergencyContact? existing;
  final bool isDark;
  final Function(EmergencyContact) onSave;
  const _ContactFormSheet({this.existing, required this.isDark, required this.onSave});
  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
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
    final l = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bg     = isDark ? _dSurface  : _lSurface;
    final label  = isDark ? _dLabel    : _lLabel;
    final label2 = isDark ? _dLabel2   : _lLabel2;
    final sep    = isDark ? _dSep      : _lSep.withOpacity(0.5);
    final accent = isDark ? _blue_D    : _blue;
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header — iOS modal header with close
            Row(children: [
                Expanded(child: Text(isEdit ? l.t('sos_edit_contact') : l.t('sos_new_contact'),
                  style: _t(17, FontWeight.w600, label, ls: -0.3))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: isDark ? _dFill : _lFill,
                        shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        color: label2, size: 14)),
              ),
            ]),

            const SizedBox(height: 4),
            Text(l.t('sos_will_notify'),
                style: _t(13, FontWeight.w400, label2)),

            const SizedBox(height: 20),
            Divider(height: 1, thickness: 0.5, color: sep),
            const SizedBox(height: 20),

            // Full name field
            _FieldLabel(text: l.t('sos_full_name'), isDark: isDark),
            const SizedBox(height: 6),
            _AppleTextField(
              controller: _nameCtrl, hint: l.t('sos_name_hint'),
                isDark: isDark,
                validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.t('sos_name_required') : null),

            const SizedBox(height: 16),

            // Phone field
            _FieldLabel(text: l.t('sos_phone'), isDark: isDark),
            const SizedBox(height: 6),
            _AppleTextField(
                controller: _phoneCtrl, hint: l.t('sos_phone_hint'),
                keyboardType: TextInputType.phone,
                isDark: isDark,
                prefixText: '+91  ',
                prefixColor: accent,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.t('sos_phone_required');
                  final c = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                  if (c.length < 10 || !RegExp(r'^\d+$').hasMatch(c)) {
                    return l.t('sos_phone_invalid10');
                  }
                  return null;
                }),

            const SizedBox(height: 16),

            // Relation chips
            _FieldLabel(text: l.t('sos_relation'), isDark: isDark),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8,
                children: _relations.map((r) {
                  final selected = r == _relation;
                  final chipAccent = _accentFor(r, isDark);
                  return GestureDetector(
                    onTap: () => setState(() => _relation = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: selected
                              ? chipAccent.withOpacity(0.12)
                              : (isDark ? _dFill : _lFill),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? chipAccent.withOpacity(0.40)
                                  : Colors.transparent,
                              width: selected ? 1.0 : 0.0)),
                            child: Text(_relationLabel(l, r), style: _t(12.5, FontWeight.w500,
                          selected ? chipAccent : label2)),
                    ),
                  );
                }).toList()),

            const SizedBox(height: 24),

            // Buttons — iOS modal action row
            Row(children: [
              // Cancel — text button
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: isDark ? _dFill : _lFill,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(l.t('sos_cancel'),
                        style: _t(15, FontWeight.w500, label2)))),
              )),
              const SizedBox(width: 12),
              // Confirm — filled
              Expanded(flex: 2, child: GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedOpacity(
                  opacity: _saving ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(child: _saving
                          ? SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? l.t('sos_save_changes') : l.t('sos_add_btn'),
                          style: _t(15, FontWeight.w600, Colors.white)))),
                ),
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
      isPrimary: widget.existing?.isPrimary ?? false,
    ));
    if (mounted) Navigator.pop(context);
  }
}

// ── Field label ───────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel({required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(text,
      style: _t(12, FontWeight.w600,
          isDark ? _dLabel2 : _lLabel2, ls: 0.3));
}

// ── Apple-style text field ────────────────────────────────────
class _AppleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool isDark;
  final String? prefixText;
  final Color? prefixColor;
  final String? Function(String?)? validator;
  const _AppleTextField({
    required this.controller, required this.hint,
    this.keyboardType = TextInputType.text,
    required this.isDark, this.prefixText,
    this.prefixColor, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fill   = isDark ? _dFill.withOpacity(0.3) : _lFill.withOpacity(0.5);
    final label  = isDark ? _dLabel   : _lLabel;
    final label2 = isDark ? _dLabel2  : _lLabel2;
    final accent = isDark ? _blue_D   : _blue;
    final border = BorderRadius.circular(11);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: _t(15, FontWeight.w400, label),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _t(15, FontWeight.w400, label2),
        prefixText: prefixText,
        prefixStyle: prefixText != null
            ? _t(15, FontWeight.w600, prefixColor ?? accent)
            : null,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: border,
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: border,
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: border,
            borderSide: BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: border,
            borderSide: BorderSide(color: isDark ? _red_D : _red, width: 1.0)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: border,
            borderSide: BorderSide(color: isDark ? _red_D : _red, width: 1.5)),
        errorStyle: _t(11, FontWeight.w500, isDark ? _red_D : _red),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  APPLE ALERT DIALOG  — replaces old _ConfirmDialog
// ══════════════════════════════════════════════════════════════
class _AppleAlertDialog extends StatelessWidget {
  final String title, message, destructiveLabel;
  final VoidCallback onDestructive;
  const _AppleAlertDialog({
    required this.title, required this.message,
    required this.destructiveLabel, required this.onDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _dSurface  : _lSurface;
    final label  = isDark ? _dLabel    : _lLabel;
    final label2 = isDark ? _dLabel2   : _lLabel2;
    final sep    = isDark ? _dSep      : _lSep.withOpacity(0.5);
    final dRed   = isDark ? _red_D     : _red;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(children: [
              Text(title, textAlign: TextAlign.center,
                  style: _t(17, FontWeight.w600, label, ls: -0.2)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center,
                  style: _t(13, FontWeight.w400, label2, h: 1.5)),
            ]),
          ),
          Divider(height: 1, thickness: 0.5, color: sep),
          // Buttons row — iOS alert style
          IntrinsicHeight(child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: sep, width: 0.5))),
                child: Center(child: Text(AppLocalizations.of(context).t('sos_cancel'),
                    style: _t(17, FontWeight.w400,
                        isDark ? _blue_D : _blue))),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(context); onDestructive(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text(destructiveLabel,
                    style: _t(17, FontWeight.w600, dRed))),
              ),
            )),
          ])),
        ]),
      ),
    );
  }
}