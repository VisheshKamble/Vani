// lib/services/EmergencyService.dart
//
// Changes from original:
//   • addContact    — also inserts into Supabase, stores returned supabaseId
//   • updateContact — also updates Supabase row if supabaseId is known
//   • deleteContact — also deletes Supabase row if supabaseId is known
//   • syncFromSupabase() — public method, called after login from AuthDialog
// Everything else (shake, SOS sending, dialogs) is 100% unchanged.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:shake/shake.dart';

import '../models/EmergencyContact.dart';
import '../utils/PlatformHelper.dart';
import '../services/SupabaseService.dart';
import 'LocationService.dart';

// ─────────────────────────────────────────────
//  SOS MESSAGE TYPES  (unchanged)
// ─────────────────────────────────────────────

enum SOSMessageType { generalHelp, medical, police, fire, custom }

extension SOSMessageTypeExt on SOSMessageType {
  String get label {
    switch (this) {
      case SOSMessageType.generalHelp:
        return 'General Emergency';
      case SOSMessageType.medical:
        return 'Medical Emergency';
      case SOSMessageType.police:
        return 'Safety Emergency';
      case SOSMessageType.fire:
        return 'Fire Emergency';
      case SOSMessageType.custom:
        return 'Emergency Alert';
    }
  }

  String get fullMessage => _buildBase(null);

  String _buildBase(String? locationBlock) {
    final loc =
        locationBlock ?? 'Location data was not available at time of alert.';
    switch (this) {
      case SOSMessageType.generalHelp:
        return 'URGENT — EMERGENCY ALERT\n\n'
            'This message was sent automatically by the VANI sign-language assistance app.\n\n'
            'The person who sent this alert is DEAF or MUTE and cannot speak or call for help. '
            'They require your immediate assistance.\n\n'
            'Please do one or more of the following right now:\n'
            '  1. Call them back at the number associated with this contact.\n'
            '  2. Go to their current location.\n'
            '  3. Contact emergency services (Dial 112) on their behalf.\n\n'
            'They will respond via text message or sign language.\n\n'
            'Current location:\n$loc\n\n'
            'Time of alert: {TIME}\n\n'
            '— Sent automatically via VANI Emergency SOS';

      case SOSMessageType.medical:
        return 'URGENT — MEDICAL EMERGENCY\n\n'
            'This message was sent automatically by the VANI sign-language assistance app.\n\n'
            'The person who sent this alert is DEAF or MUTE and is experiencing a medical emergency. '
            'They are unable to call for help verbally.\n\n'
            'Immediate actions required:\n'
            '  1. Call an ambulance — Dial 108.\n'
            '  2. Go to their location immediately.\n'
            '  3. Contact a doctor or nearby hospital.\n\n'
            'Current location:\n$loc\n\n'
            'Time of alert: {TIME}\n\n'
            '— Sent automatically via VANI Emergency SOS';

      case SOSMessageType.police:
        return 'URGENT — SAFETY EMERGENCY\n\n'
            'This message was sent automatically by the VANI sign-language assistance app.\n\n'
            'The person who sent this alert is DEAF or MUTE and is in a dangerous situation. '
            'They are unable to call the police verbally.\n\n'
            'Immediate actions required:\n'
            '  1. Call the police — Dial 100.\n'
            '  2. Go to their location immediately.\n'
            '  3. Alert someone nearby who can assist them.\n\n'
            'Current location:\n$loc\n\n'
            'Time of alert: {TIME}\n\n'
            '— Sent automatically via VANI Emergency SOS';

      case SOSMessageType.fire:
        return 'URGENT — FIRE OR SMOKE EMERGENCY\n\n'
            'This message was sent automatically by the VANI sign-language assistance app.\n\n'
            'The person who sent this alert is DEAF or MUTE and is reporting a fire or smoke emergency. '
            'They cannot call the fire brigade verbally.\n\n'
            'Immediate actions required:\n'
            '  1. Call the fire brigade — Dial 101.\n'
            '  2. Ensure evacuation of the building.\n'
            '  3. Alert people near this location.\n\n'
            'Current location:\n$loc\n\n'
            'Time of alert: {TIME}\n\n'
            '— Sent automatically via VANI Emergency SOS';

      case SOSMessageType.custom:
        return 'URGENT — EMERGENCY ALERT\n\n'
            'This message was sent automatically by the VANI sign-language assistance app.\n\n'
            'The person who sent this alert is DEAF or MUTE and requires immediate assistance. '
            'They cannot communicate verbally.\n\n'
            'Please contact them or go to their location immediately.\n\n'
            'Current location:\n$loc\n\n'
            'Time of alert: {TIME}\n\n'
            '— Sent automatically via VANI Emergency SOS';
    }
  }
}

// ─────────────────────────────────────────────
//  EMERGENCY SERVICE  (singleton)
// ─────────────────────────────────────────────

class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._();
  EmergencyService._();

  static const String _boxName = 'emergency_contacts';

  ShakeDetector? _shakeDetector;
  bool _shakeActive = false;
  bool _isTriggering = false;
  BuildContext? _context;

  // ── Initialisation ──────────────────────────

  Future<void> init(BuildContext context) async {
    _context = context;
    await _openBox();

    // If user is already logged in (e.g. app restarted with saved session),
    // pull their contacts from Supabase right away.
    if (SupabaseService.instance.isLoggedIn) {
      await syncFromSupabase();
    }

    _startShakeDetection();
  }

  void updateContext(BuildContext context) => _context = context;

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      Hive.registerAdapter(EmergencyContactAdapter());
      await Hive.openBox<EmergencyContact>(_boxName);
    }
  }

  // ── Supabase sync (public) ──────────────────

  /// Pull contacts from Supabase → overwrite local Hive box.
  /// Call after login / signup from AuthDialog.
  Future<void> syncFromSupabase() async {
    await SupabaseService.instance.syncContactsToHive();
  }

  /// Push local Hive contacts that have no supabaseId up to Supabase.
  /// Useful when a user adds contacts offline then later logs in.
  Future<void> pushLocalContactsToSupabase() async {
    // Push each local contact that has no supabaseId up to Supabase
    final box = Hive.box<EmergencyContact>('emergency_contacts');
    for (int i = 0; i < box.length; i++) {
      final contact = box.getAt(i);
      if (contact == null) continue;
      if (contact.supabaseId != null) continue; // already synced
      try {
        final row = await SupabaseService.instance.addContactToSupabase(
          contact,
        );
        contact.supabaseId = row['id'] as String?;
        await contact.save();
      } catch (e) {
        debugPrint('[EmergencyService] pushLocalContactsToSupabase error: $e');
      }
    }
  }

  // ── Shake detection (unchanged) ─────────────

  void _startShakeDetection() {
    if (!PlatformHelper.supportsShake) return;
    if (_shakeDetector != null) return;

    try {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: _onShakeDetected,
        minimumShakeCount: 2,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        shakeThresholdGravity: 2.5,
      );
    } catch (_) {}
  }

  void _onShakeDetected(ShakeEvent _) {
    if (_shakeActive) return;
    if (_isTriggering) return;
    if (getContacts().isEmpty) return;

    _shakeActive = true;
    triggerSOS(type: SOSMessageType.generalHelp, triggeredByShake: true).then((
      _,
    ) {
      Future.delayed(const Duration(seconds: 5), () => _shakeActive = false);
    });
  }

  void stopShakeDetection() {
    _shakeDetector?.stopListening();
    _shakeDetector = null;
    _shakeActive = false;
  }

  void restartShakeDetection() {
    stopShakeDetection();
    _startShakeDetection();
  }

  bool get shakeActive =>
      _shakeDetector != null && PlatformHelper.supportsShake;

  // ── Contact management ───────────────────────

  Box<EmergencyContact> get _box => Hive.box<EmergencyContact>(_boxName);

  List<EmergencyContact> getContacts() => _box.values.toList();

  /// Add contact to Hive AND Supabase (if logged in).
  Future<void> addContact(EmergencyContact contact) async {
    if (_box.length >= 5)
      throw Exception('Maximum 5 emergency contacts allowed.');
    if (!contact.isValid)
      throw Exception('Invalid phone number: ${contact.phone}');
    if (_box.isEmpty) contact.isPrimary = true;

    if (SupabaseService.instance.isLoggedIn) {
      // No try/catch here — let the error bubble up to the UI
      final row = await SupabaseService.instance.addContactToSupabase(contact);
      contact.supabaseId = row['id'] as String?;
    }

    await _box.add(contact);
  }

  /// Update contact in Hive AND Supabase (if logged in and supabaseId known).
  Future<void> updateContact(int index, EmergencyContact updated) async {
    if (!updated.isValid) throw Exception('Invalid phone number.');

    // Preserve the supabaseId from the old record
    final existing = _box.getAt(index);
    final sid = existing?.supabaseId ?? updated.supabaseId;
    updated.supabaseId = sid;

    if (SupabaseService.instance.isLoggedIn && sid != null) {
      try {
        await SupabaseService.instance.updateContactInSupabase(sid, updated);
      } catch (e) {
        debugPrint('[EmergencyService] Supabase updateContact error: $e');
      }
    }

    await _box.putAt(index, updated);
  }

  /// Delete contact from Hive AND Supabase (if logged in and supabaseId known).
  Future<void> deleteContact(int index) async {
    final contact = _box.getAt(index);

    if (SupabaseService.instance.isLoggedIn && contact?.supabaseId != null) {
      try {
        await SupabaseService.instance.deleteContactFromSupabase(
          contact!.supabaseId!,
        );
      } catch (e) {
        debugPrint('[EmergencyService] Supabase deleteContact error: $e');
      }
    }

    await _box.deleteAt(index);

    // Reassign primary if needed
    final remaining = getContacts();
    if (remaining.isNotEmpty && !remaining.any((c) => c.isPrimary)) {
      remaining.first.isPrimary = true;
      await remaining.first.save();
    }
  }

  Future<void> setPrimary(int index) async {
    final contacts = getContacts();
    for (int i = 0; i < contacts.length; i++) {
      contacts[i].isPrimary = (i == index);
      await contacts[i].save();
    }
  }

  bool get hasContacts => _box.isNotEmpty;
  int get contactCount => _box.length;

  // ── Core SOS trigger (unchanged) ─────────────

  Future<SOSResult> triggerSOS({
    required SOSMessageType type,
    String? customMessage,
    bool triggeredByShake = false,
  }) async {
    if (_isTriggering) {
      return SOSResult(
        success: false,
        reason: 'SOS already in progress.',
        platform: PlatformHelper.platformName,
      );
    }
    _isTriggering = true;

    try {
      final contacts = getContacts();
      _triggerHaptics();

      final location = await LocationService.instance.getLocationWithFallback(
        timeout: const Duration(seconds: 5),
      );

      final now = DateTime.now();
      final timeStr =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}  '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';

      final locationBlock = location.isAvailable
          ? '${location.mapsLink}\n(${location.displayString})'
          : 'Could not be determined automatically.';

      String fullMsg;
      if (customMessage != null &&
          (customMessage.contains('{LOCATION}') ||
              customMessage.contains('{TIME}'))) {
        fullMsg = customMessage
            .replaceAll('{LOCATION}', locationBlock)
            .replaceAll('{TIME}', timeStr);
      } else if (customMessage != null) {
        fullMsg = customMessage;
      } else {
        fullMsg = type._buildBase(locationBlock).replaceAll('{TIME}', timeStr);
      }

      if (contacts.isEmpty) {
        if (_context != null) _showNoContactsDialog(_context!);
        return SOSResult(
          success: false,
          reason: 'No emergency contacts configured.',
          platform: PlatformHelper.platformName,
        );
      }

      if (PlatformHelper.isMobile) {
        return await _sendMobileSOS(
          contacts: contacts,
          message: fullMsg,
          location: location,
          type: type,
        );
      } else if (PlatformHelper.isWeb) {
        return await _sendWebSOS(
          contacts: contacts,
          message: fullMsg,
          location: location,
          type: type,
        );
      } else {
        if (_context != null)
          _showDesktopSOSDialog(_context!, fullMsg, contacts);
        return SOSResult(
          success: true,
          reason: 'Desktop SOS dialog shown.',
          platform: PlatformHelper.platformName,
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 3));
      _isTriggering = false;
    }
  }

  // ── Mobile SOS (unchanged) ───────────────────

  Future<SOSResult> _sendMobileSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    int sent = 0;
    final List<String> errors = [];

    for (final contact in contacts) {
      if (!contact.isValid) {
        errors.add('Skipped ${contact.name}: invalid number.');
        continue;
      }

      final smsUri = Uri(
        scheme: 'sms',
        path: contact.internationalPhone,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          sent++;
        } else {
          final waUri = Uri.parse(
            _buildWhatsAppUrl(contact.internationalPhone, message),
          );
          if (await canLaunchUrl(waUri)) {
            await launchUrl(waUri, mode: LaunchMode.externalApplication);
            sent++;
          } else {
            errors.add('Could not reach ${contact.name}.');
          }
        }
      } catch (e) {
        errors.add('Error contacting ${contact.name}: $e');
      }

      if (contacts.indexOf(contact) < contacts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }

    return SOSResult(
      success: sent > 0,
      sentCount: sent,
      totalContacts: contacts.length,
      errors: errors,
      reason: sent > 0
          ? 'Alert sent to $sent contact(s).'
          : 'Failed to send alert.',
      platform: PlatformHelper.platformName,
    );
  }

  // ── Web SOS (unchanged) ──────────────────────

  Future<SOSResult> _sendWebSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    if (_context == null) {
      return SOSResult(
        success: false,
        reason: 'No context for web modal.',
        platform: PlatformHelper.platformName,
      );
    }

    _showWebSOSModal(
      context: _context!,
      contacts: contacts,
      message: message,
      location: location,
      type: type,
    );

    final primary = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.first,
    );
    try {
      final uri = Uri.parse(
        _buildWhatsAppUrl(primary.internationalPhone, message),
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return SOSResult(
      success: true,
      reason: 'Web SOS panel shown.',
      platform: PlatformHelper.platformName,
    );
  }

  // ── Helpers (unchanged) ──────────────────────

  String _buildWhatsAppUrl(String phone, String message) =>
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

  void _triggerHaptics() {
    if (!PlatformHelper.canVibrate) return;
    try {
      Vibration.vibrate(
        pattern: [0, 300, 150, 300, 150, 600],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  //  DIALOGS (all unchanged)
  // ─────────────────────────────────────────────

  void _showNoContactsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => _SosDialog(
        isDark: isDark,
        title: 'No Emergency Contacts',
        body:
            'You have not saved any emergency contacts yet. '
            'Go to the SOS setup screen and add at least one contact '
            'before using this feature.',
        accentColor: const Color(0xFFD97706),
        actions: [
          _SosDialogAction(
            label: 'OK',
            isPrimary: false,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showDesktopSOSDialog(
    BuildContext context,
    String message,
    List<EmergencyContact> contacts,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => _DesktopSOSDialog(
        isDark: isDark,
        message: message,
        contacts: contacts,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showWebSOSModal({
    required BuildContext context,
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WebSOSModal(
        contacts: contacts,
        message: message,
        location: location,
        type: type,
        onClose: () => Navigator.pop(ctx),
        buildWhatsApp: _buildWhatsAppUrl,
      ),
    );
  }

  void dispose() => stopShakeDetection();
}

// ─────────────────────────────────────────────
//  SOS RESULT
// ─────────────────────────────────────────────

class SOSResult {
  final bool success;
  final String reason;
  final String platform;
  final int sentCount;
  final int totalContacts;
  final List<String> errors;

  const SOSResult({
    required this.success,
    required this.reason,
    required this.platform,
    this.sentCount = 0,
    this.totalContacts = 0,
    this.errors = const [],
  });
}

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────

class _DT {
  final bool d;
  const _DT(this.d);
  Color get bg => d ? const Color(0xFF06060E) : const Color(0xFFF5F5FA);
  Color get surface => d ? const Color(0xFF0D0D1A) : Colors.white;
  Color get card => d ? const Color(0xFF13131F) : const Color(0xFFF8F8FC);
  Color get border => d ? const Color(0xFF1E1E30) : const Color(0xFFE2E2F0);
  Color get border2 => d ? const Color(0xFF2A2A40) : const Color(0xFFCCCCE0);
  Color get textPri => d ? const Color(0xFFF0EEFF) : const Color(0xFF0A0A1F);
  Color get textSec => d ? const Color(0xFF6A6A8A) : const Color(0xFF5A5A80);
  Color get textMut => d ? const Color(0xFF2E2E48) : const Color(0xFFAAAAAA);
  static const crimson = Color(0xFFDC2626);
  static const crimsonSoft = Color(0xFFEF4444);
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFA78BFA);
  static const green = Color(0xFF059669);
  static const greenLight = Color(0xFF34D399);
  static const amber = Color(0xFFD97706);
}

// ─────────────────────────────────────────────
//  GENERIC SOS DIALOG
// ─────────────────────────────────────────────

class _SosDialogAction {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _SosDialogAction({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });
}

class _SosDialog extends StatelessWidget {
  final bool isDark;
  final String title, body;
  final Color accentColor;
  final List<_SosDialogAction> actions;
  const _SosDialog({
    required this.isDark,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final t = _DT(isDark);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.55 : 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withOpacity(0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: t.textPri,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: t.border),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    style: TextStyle(
                      color: t.textSec,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: actions
                        .map(
                          (a) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: actions.indexOf(a) > 0 ? 8 : 0,
                              ),
                              child: GestureDetector(
                                onTap: a.onTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: a.isPrimary
                                        ? accentColor
                                        : accentColor.withOpacity(
                                            isDark ? 0.08 : 0.06,
                                          ),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: a.isPrimary
                                          ? accentColor
                                          : accentColor.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      a.label,
                                      style: TextStyle(
                                        color: a.isPrimary
                                            ? Colors.white
                                            : accentColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DESKTOP SOS DIALOG (unchanged)
// ─────────────────────────────────────────────

class _DesktopSOSDialog extends StatefulWidget {
  final bool isDark;
  final String message;
  final List<EmergencyContact> contacts;
  final VoidCallback onClose;
  const _DesktopSOSDialog({
    required this.isDark,
    required this.message,
    required this.contacts,
    required this.onClose,
  });
  @override
  State<_DesktopSOSDialog> createState() => _DesktopSOSDialogState();
}

class _DesktopSOSDialogState extends State<_DesktopSOSDialog> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _DT(widget.isDark);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.55 : 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _DT.crimson,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _DT.crimson.withOpacity(
                            widget.isDark ? 0.10 : 0.07,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _DT.crimson.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: _DT.crimsonSoft,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Alert Ready',
                              style: TextStyle(
                                color: t.textPri,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Copy and send to your contacts manually',
                              style: TextStyle(color: t.textSec, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: t.border),
                  const SizedBox(height: 14),
                  Text(
                    'Send to:',
                    style: TextStyle(
                      color: t.textSec,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.contacts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _DT.violetLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${c.name}',
                            style: TextStyle(
                              color: t.textPri,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.phone,
                            style: TextStyle(
                              color: t.textSec,
                              fontSize: 12,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: SelectableText(
                      widget.message,
                      style: TextStyle(
                        color: t.textSec,
                        fontSize: 11.5,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _copy,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _copied
                                  ? _DT.green.withOpacity(
                                      widget.isDark ? 0.12 : 0.08,
                                    )
                                  : _DT.violet.withOpacity(
                                      widget.isDark ? 0.10 : 0.07,
                                    ),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: _copied
                                    ? _DT.green.withOpacity(0.3)
                                    : _DT.violet.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _copied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  color: _copied
                                      ? _DT.greenLight
                                      : _DT.violetLight,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _copied ? 'Copied!' : 'Copy message',
                                  style: TextStyle(
                                    color: _copied
                                        ? _DT.greenLight
                                        : _DT.violetLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: t.card,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: t.border2),
                            ),
                            child: Center(
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: t.textSec,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WEB SOS MODAL (unchanged)
// ─────────────────────────────────────────────

class _WebSOSModal extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final String message;
  final LocationResult location;
  final SOSMessageType type;
  final VoidCallback onClose;
  final String Function(String, String) buildWhatsApp;
  const _WebSOSModal({
    required this.contacts,
    required this.message,
    required this.location,
    required this.type,
    required this.onClose,
    required this.buildWhatsApp,
  });
  @override
  State<_WebSOSModal> createState() => _WebSOSModalState();
}

class _WebSOSModalState extends State<_WebSOSModal> {
  bool _messageCopied = false;

  Future<void> _openWhatsApp(EmergencyContact c) async {
    final uri = Uri.parse(
      widget.buildWhatsApp(c.internationalPhone, widget.message),
    );
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTel(EmergencyContact c) async {
    final uri = Uri(scheme: 'tel', path: c.internationalPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _messageCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _messageCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _DT(isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.14),
              blurRadius: 48,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _DT.crimson,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _DT.crimson.withOpacity(
                              isDark ? 0.10 : 0.07,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _DT.crimson.withOpacity(0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: _DT.crimsonSoft,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency SOS Activated',
                                style: TextStyle(
                                  color: t.textPri,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.type.label,
                                style: const TextStyle(
                                  color: _DT.crimsonSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (widget.location.isAvailable
                                    ? _DT.green
                                    : _DT.amber)
                                .withOpacity(isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              (widget.location.isAvailable
                                      ? _DT.green
                                      : _DT.amber)
                                  .withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.location.isAvailable
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            color: widget.location.isAvailable
                                ? _DT.greenLight
                                : _DT.amber,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.location.isAvailable
                                  ? 'Location attached: ${widget.location.displayString}'
                                  : 'Location unavailable — message sent without coordinates.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: widget.location.isAvailable
                                    ? _DT.greenLight
                                    : _DT.amber,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Contact your emergency contacts:',
                      style: TextStyle(
                        color: t.textSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.contacts.map(
                      (contact) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: contact.isPrimary
                                ? _DT.crimson.withOpacity(0.28)
                                : t.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            contact.name,
                                            style: TextStyle(
                                              color: t.textPri,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _DT.violet.withOpacity(
                                                isDark ? 0.10 : 0.07,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              contact.relation,
                                              style: const TextStyle(
                                                color: _DT.violetLight,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (contact.isPrimary) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _DT.crimson.withOpacity(
                                                  isDark ? 0.10 : 0.07,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Primary',
                                                style: TextStyle(
                                                  color: _DT.crimsonSoft,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        contact.phone,
                                        style: TextStyle(
                                          color: t.textSec,
                                          fontSize: 11,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ContactActionBtn(
                                    label: 'WhatsApp',
                                    icon: Icons.chat_rounded,
                                    color: const Color(0xFF25D366),
                                    onTap: () => _openWhatsApp(contact),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ContactActionBtn(
                                    label: 'Call',
                                    icon: Icons.call_rounded,
                                    color: const Color(0xFF0284C7),
                                    onTap: () => _openTel(contact),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _copy,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _messageCopied
                              ? _DT.green.withOpacity(isDark ? 0.10 : 0.07)
                              : t.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _messageCopied
                                ? _DT.green.withOpacity(0.3)
                                : t.border2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _messageCopied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              color: _messageCopied
                                  ? _DT.greenLight
                                  : t.textSec,
                              size: 14,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _messageCopied
                                  ? 'Message copied to clipboard'
                                  : 'Copy emergency message',
                              style: TextStyle(
                                color: _messageCopied
                                    ? _DT.greenLight
                                    : t.textSec,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onClose,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'I am safe — Close this panel',
                          style: TextStyle(
                            color: t.textSec,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CONTACT ACTION BUTTON (unchanged)
// ─────────────────────────────────────────────

class _ContactActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ContactActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
