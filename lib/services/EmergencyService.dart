import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:shake/shake.dart';

import '../l10n/AppLocalizations.dart';
import '../models/EmergencyContact.dart';
import '../Utils/PlatformHelper.dart';
import 'LocationService.dart';

// ─────────────────────────────────────────────
//  SOS MESSAGE TYPES
// ─────────────────────────────────────────────

enum SOSMessageType { generalHelp, medical, police, fire, custom }

String _localizedSosTypeLabel(AppLocalizations l, SOSMessageType type) {
  switch (type) {
    case SOSMessageType.generalHelp:
      return l.t('sos_general_title');
    case SOSMessageType.medical:
      return l.t('sos_medical_title');
    case SOSMessageType.police:
      return l.t('sos_police_title');
    case SOSMessageType.fire:
      return l.t('sos_fire_title');
    case SOSMessageType.custom:
      return l.t('sos_label_emergency');
  }
}

String _defaultSosTemplateKey(SOSMessageType type) {
  switch (type) {
    case SOSMessageType.generalHelp:
      return 'sos_sms_general_template';
    case SOSMessageType.medical:
      return 'sos_sms_medical_template';
    case SOSMessageType.police:
      return 'sos_sms_police_template';
    case SOSMessageType.fire:
      return 'sos_sms_fire_template';
    case SOSMessageType.custom:
      return 'sos_sms_accident_template';
  }
}

/// Hardcoded fallback templates — used if localization key is missing.
String _defaultSosTemplateFallback(SOSMessageType type) {
  switch (type) {
    case SOSMessageType.generalHelp:
      return '🆘 SOS! I need help urgently.\n\n📍 Location: {LOCATION}\n🕐 Time: {TIME}\n\n— Sent via VANI Emergency SOS';
    case SOSMessageType.medical:
      return '🚑 MEDICAL EMERGENCY! Please help immediately.\n\n📍 Location: {LOCATION}\n🕐 Time: {TIME}\n\n— Sent via VANI Emergency SOS';
    case SOSMessageType.police:
      return '🚨 POLICE EMERGENCY! I need police assistance.\n\n📍 Location: {LOCATION}\n🕐 Time: {TIME}\n\n— Sent via VANI Emergency SOS';
    case SOSMessageType.fire:
      return '🔥 FIRE EMERGENCY! Please call fire brigade immediately.\n\n📍 Location: {LOCATION}\n🕐 Time: {TIME}\n\n— Sent via VANI Emergency SOS';
    case SOSMessageType.custom:
      return '🚨 EMERGENCY! Please help immediately.\n\n📍 Location: {LOCATION}\n🕐 Time: {TIME}\n\n— Sent via VANI Emergency SOS';
  }
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

  // ── Lifecycle ──────────────────────────────

  Future<void> init(BuildContext context) async {
    _context = context;
    await _openBox();
    _startShakeDetection();
  }

  void updateContext(BuildContext context) => _context = context;

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      Hive.registerAdapter(EmergencyContactAdapter());
      await Hive.openBox<EmergencyContact>(_boxName);
    }
  }

  // ── Legacy no-op stubs ─────────────────────

  Future<void> syncFromSupabase() async {}
  Future<void> pushLocalContactsToSupabase() async {}

  // ── Shake Detection ────────────────────────

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

  // FIX: _shakeActive is set BEFORE the async call so concurrent shake events
  // are blocked immediately. Previously it was set inside .then() which meant
  // a second shake could slip through while the first was still awaiting GPS.
  void _onShakeDetected(ShakeEvent _) {
    if (_shakeActive || _isTriggering || getContacts().isEmpty) return;
    _shakeActive = true; // guard set synchronously before any await
    triggerSOS(
      type: SOSMessageType.generalHelp,
      triggeredByShake: true,
    ).then((_) {
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

  bool get shakeActive => _shakeDetector != null && PlatformHelper.supportsShake;

  // ── Hive Contact Storage ───────────────────

  Box<EmergencyContact> get _box => Hive.box<EmergencyContact>(_boxName);

  List<EmergencyContact> getContacts() => _box.values.toList();

  Future<void> addContact(EmergencyContact contact) async {
    if (_box.length >= 5) throw Exception('Maximum 5 emergency contacts allowed.');
    if (!contact.isValid) throw Exception('Invalid phone number: ${contact.phone}');
    if (_box.isEmpty) contact.isPrimary = true;
    await _box.add(contact);
  }

  Future<void> updateContact(int index, EmergencyContact updated) async {
    if (!updated.isValid) throw Exception('Invalid phone number.');
    await _box.putAt(index, updated);
  }

  Future<void> deleteContact(int index) async {
    await _box.deleteAt(index);
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

  // ─────────────────────────────────────────────
  //  CORE SOS TRIGGER
  // ─────────────────────────────────────────────

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

      // Guard: no contacts configured
      if (contacts.isEmpty) {
        if (_context != null) _showNoContactsDialog(_context!);
        return SOSResult(
          success: false,
          reason: 'No emergency contacts configured.',
          platform: PlatformHelper.platformName,
        );
      }

      // Immediate haptic feedback so the user knows SOS fired
      _triggerHaptics();

      // ── Location strategy: web keeps strict requirement, mobile is lenient ──
      // On mobile, GPS can time out or be temporarily unavailable. We must never
      // block the SOS entirely because of location — send the message with whatever
      // location we have (or none), rather than silently failing.
      final LocationResult location;
      if (kIsWeb) {
        // Web: keep original strict behaviour (unchanged)
        location = await _requireLiveLocationForSOS();
        if (!location.isAvailable) {
          final l = _context != null ? AppLocalizations.of(_context!) : null;
          return SOSResult(
            success: false,
            reason: l?.t('sos_location_required_reason') ??
                'Live location is required for SOS. Please enable location and try again.',
            platform: PlatformHelper.platformName,
          );
        }
      } else {
        // Mobile: best-effort location — SOS is NEVER blocked by location failure
        location = await _getMobileLocationBestEffort();
      }

      // ── Build full pre-filled message ──
      final fullMsg = _buildSOSMessage(
        type: type,
        customMessage: customMessage,
        location: location,
      );

      // ── Send via WhatsApp ──
      return kIsWeb
          ? await _sendWebSOS(
              contacts: contacts,
              message: fullMsg,
              location: location,
              type: type,
            )
          : await _sendMobileSOS(
              contacts: contacts,
              message: fullMsg,
              location: location,
              type: type,
            );
    } finally {
      // 3-second cooldown before another SOS can be triggered
      await Future.delayed(const Duration(seconds: 3));
      _isTriggering = false;
    }
  }

  // ─────────────────────────────────────────────
  //  MOBILE LOCATION — best-effort, never blocks SOS
  // ─────────────────────────────────────────────

  /// Gets location for mobile SOS. Tries fast (6s) then falls back to last
  /// known position. If neither is available the SOS still sends — the message
  /// will contain "Location unavailable" instead of coordinates.
  Future<LocationResult> _getMobileLocationBestEffort() async {
    // Try a quick fix first
    final quick = await LocationService.instance
        .getLocationWithFallback(timeout: const Duration(seconds: 6));
    if (quick.isAvailable) return quick;

    // Fall back to the last cached position if we have one
    final cached = LocationService.instance.lastKnownLocation;
    if (cached != null && cached.isAvailable) return cached;

    // Return unavailable — SOS will still send, just without coordinates
    return const LocationResult(
      isAvailable: false,
      error: 'Location unavailable.',
    );
  }

  // ─────────────────────────────────────────────
  //  MESSAGE BUILDER
  // ─────────────────────────────────────────────

  String _buildSOSMessage({
    required SOSMessageType type,
    required LocationResult location,
    String? customMessage,
  }) {
    final now = DateTime.now();
    final timeStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    // Google Maps link on its own line, coordinates below
    final locationBlock = location.isAvailable
        ? '${location.mapsLink}\n(${location.displayString})'
        : 'Location unavailable';

    // Template priority: customMessage → l10n key → hardcoded fallback
    String template;
    if (customMessage != null && customMessage.trim().isNotEmpty) {
      template = customMessage;
    } else if (_context != null) {
      final l = AppLocalizations.of(_context!);
      final localized = l.t(_defaultSosTemplateKey(type));
      // If the key was returned verbatim, the translation is missing
      template = (localized == _defaultSosTemplateKey(type))
          ? _defaultSosTemplateFallback(type)
          : localized;
    } else {
      template = _defaultSosTemplateFallback(type);
    }

    return template
        .replaceAll('{LOCATION}', locationBlock)
        .replaceAll('{TIME}', timeStr);
  }

  // ─────────────────────────────────────────────
  //  MOBILE WHATSAPP SENDER
  // ─────────────────────────────────────────────

  /// Opens WhatsApp natively on Android/iOS with the pre-filled message.
  ///
  /// Launch strategy:
  ///   1. intent:// URI on Android — bypasses Android 11+ package-visibility
  ///      restrictions entirely. Does not require <queries> in AndroidManifest.
  ///      Opens WhatsApp directly to the pre-filled chat.
  ///   2. whatsapp:// scheme — works on iOS and older Android.
  ///   3. wa.me HTTPS fallback — last resort, opens browser or WhatsApp Web.
  ///
  /// All three attempts pass the full encoded message so the user only needs
  /// to tap Send — they are NOT redirected to an invite/info page.
  Future<SOSResult> _sendMobileSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    final errors = <String>[];
    int sentCount = 0;
    final total = contacts.length;

    for (int i = 0; i < total; i++) {
      final contact = contacts[i];
      final phone = contact.whatsappDigits;
      final encodedMsg = Uri.encodeComponent(message);
      bool launched = false;

      // ── Attempt 1: Android intent URI ──────────────────────────────────────
      // Uses Android ACTION_VIEW intent directed at WhatsApp's package.
      // This bypasses the Android 11+ package-visibility restriction (no need
      // for <queries> block) and opens directly to a chat with the pre-filled
      // message. The `launchMode` must be externalNonBrowsingApplication so
      // Flutter does not try to open it inside a Chrome Custom Tab.
      if (!kIsWeb) {
        try {
          final intentUri = Uri.parse(
            'intent://send/$phone'
            '#Intent;'
            'scheme=whatsapp;'
            'package=com.whatsapp;'
            'action=android.intent.action.SENDTO;'
            'S.android.intent.extra.TEXT=${Uri.encodeComponent(message)};'
            'end',
          );
          launched = await launchUrl(
            intentUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (_) {
          // Not Android or WhatsApp not installed — fall through
        }
      }

      // ── Attempt 2: whatsapp:// deep-link scheme ─────────────────────────────
      // Works on iOS and Android when WhatsApp is installed. Opens a chat with
      // the contact and pre-fills the message body. This is NOT an invite link.
      if (!launched) {
        try {
          final waUri = Uri.parse(
            'whatsapp://send?phone=$phone&text=$encodedMsg',
          );
          launched = await launchUrl(
            waUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          // Scheme not handled (WhatsApp not installed) — fall through
        }
      }

      // ── Attempt 3: wa.me HTTPS fallback ────────────────────────────────────
      // wa.me?phone=&text= opens a chat with the pre-filled message when
      // WhatsApp is installed, or WhatsApp Web in a browser if not.
      // This is the correct URL format — NOT wa.me/<phone> alone (which shows
      // the contact profile/invite page without a pre-filled message).
      if (!launched) {
        try {
          final webUri = Uri.parse(
            'https://wa.me/$phone?text=$encodedMsg',
          );
          launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          errors.add('${contact.name}: $e');
        }
      }

      if (launched) sentCount++;

      // Delay between contacts only — never after the last one
      if (i < total - 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    if (sentCount == 0) {
      return SOSResult(
        success: false,
        reason: 'Could not open WhatsApp. Make sure it is installed.',
        platform: PlatformHelper.platformName,
        sentCount: 0,
        totalContacts: total,
        errors: errors,
      );
    }

    return SOSResult(
      success: true,
      reason: 'WhatsApp opened for $sentCount of $total contact(s).',
      platform: PlatformHelper.platformName,
      sentCount: sentCount,
      totalContacts: total,
      errors: errors,
    );
  }

  // ─────────────────────────────────────────────
  //  WEB WHATSAPP SENDER  (UNCHANGED)
  // ─────────────────────────────────────────────

  /// Opens wa.me links from the Flutter web app.
  ///
  /// WHY LaunchMode.platformDefault instead of externalApplication:
  ///   On web, `LaunchMode.externalApplication` navigates the CURRENT tab to
  ///   the URL on some browsers, destroying the app state. `platformDefault`
  ///   lets the browser decide — it opens WhatsApp Web / the WhatsApp app
  ///   without unloading the page in all major browsers.
  Future<SOSResult> _sendWebSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    final errors = <String>[];
    int sentCount = 0;
    final total = contacts.length;

    for (int i = 0; i < total; i++) {
      final contact = contacts[i];
      final phone = contact.whatsappDigits;
      final encodedMsg = Uri.encodeComponent(message);

      try {
        await launchUrl(
          Uri.parse('https://wa.me/$phone?text=$encodedMsg'),
          mode: LaunchMode.platformDefault,
        );
        sentCount++;
      } catch (e) {
        errors.add('${contact.name}: $e');
      }

      if (i < total - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    // Always show the web modal as a backup (popup may have been blocked).
    // Schedule via addPostFrameCallback so we never call showDialog
    // mid-async inside a build cycle.
    final ctx = _context;
    if (ctx != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctx.mounted) {
          _showWebSOSModal(
            context: ctx,
            contacts: contacts,
            message: message,
            location: location,
            type: type,
          );
        }
      });
    }

    return SOSResult(
      success: sentCount > 0,
      reason: sentCount > 0
          ? 'WhatsApp opened for $sentCount of $total contact(s).'
          : 'Could not open WhatsApp. Use the modal to copy and send manually.',
      platform: PlatformHelper.platformName,
      sentCount: sentCount,
      totalContacts: total,
      errors: errors,
    );
  }

  // ─────────────────────────────────────────────
  //  HAPTICS
  // ─────────────────────────────────────────────

  void _triggerHaptics() {
    if (!PlatformHelper.canVibrate) return;
    try {
      Vibration.vibrate(
        pattern: [0, 300, 150, 300, 150, 600],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  // ─────────────────────────────────────────────
  //  LOCATION FLOW — web only (strict, with full UI)
  // ─────────────────────────────────────────────

  /// Used by web only. Obtains a FRESH GPS fix every time SOS fires.
  /// Shows appropriate UI dialogs for each failure mode.
  /// Mobile uses _getMobileLocationBestEffort() instead.
  Future<LocationResult> _requireLiveLocationForSOS() async {
    // Attempt 1: fresh GPS fix
    final first = await LocationService.instance.getCurrentLocation();
    if (first.isAvailable) return first;

    // Non-interactive environments — no dialogs possible
    if (_context == null || (!PlatformHelper.isMobile && !kIsWeb)) {
      return first;
    }

    // Check the real permission state to show the right dialog
    final permStatus = await Geolocator.checkPermission();

    if (permStatus == LocationPermission.deniedForever) {
      // Permission permanently blocked — must send user to OS Settings
      final openSettings = await _showOpenSettingsDialog();
      if (openSettings) {
        await Geolocator.openAppSettings();
        // Brief wait for user to toggle the permission and return
        await Future.delayed(const Duration(seconds: 2));
        final afterSettings = await LocationService.instance.getCurrentLocation();
        if (afterSettings.isAvailable) return afterSettings;
      }
      return const LocationResult(
        isAvailable: false,
        error: 'Location permission permanently denied.',
      );
    }

    // Permission denied but recoverable — ask user to allow it
    final allow = await _showAllowLocationDialog();
    if (!allow) {
      return const LocationResult(
        isAvailable: false,
        error: 'Location permission not granted.',
      );
    }

    // Retry loop after user taps "Allow"
    while (true) {
      final retry = await LocationService.instance.getCurrentLocation();
      if (retry.isAvailable) return retry;

      final tryAgain = await _showLocationRetryDialog(retry.error);
      if (!tryAgain) return retry;
    }
  }

  // ── Location permission dialogs ─────────────

  /// Shown when location is transiently denied — asks user to grant it.
  Future<bool> _showAllowLocationDialog() async {
    if (_context == null) return true;
    final result = await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final t = _DT(isDark);
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.border2),
          ),
          title: Text(
            l.t('sos_location_required_title'),
            style: TextStyle(
                color: t.textPri, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Text(
            l.t('sos_location_required_body'),
            style: TextStyle(color: t.textSec, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('common_close'),
                  style: TextStyle(
                      color: t.textSec, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l.t('sos_allow_location'),
                style: const TextStyle(
                    color: Color(0xFF059669), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Shown when permission is PERMANENTLY denied — directs user to Settings.
  Future<bool> _showOpenSettingsDialog() async {
    if (_context == null) return false;
    final result = await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final t = _DT(isDark);
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.border2),
          ),
          title: Text(
            l.t('sos_location_required_title'),
            style: TextStyle(
                color: t.textPri, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Text(
            l.t('sos_location_denied_forever_body'),
            style: TextStyle(color: t.textSec, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('common_cancel'),
                  style: TextStyle(
                      color: t.textSec, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l.t('sos_open_settings'),
                style: const TextStyle(
                    color: Color(0xFF059669), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Shown after a retry attempt fails — offers another retry or cancel.
  Future<bool> _showLocationRetryDialog(String? error) async {
    if (_context == null) return false;
    final result = await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final t = _DT(isDark);
        final l = AppLocalizations.of(ctx);
        final body = l
            .t('sos_location_retry_body')
            .replaceAll(
                '{error}', (error ?? l.t('sos_location_unavailable')).trim());
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.border2),
          ),
          title: Text(
            l.t('sos_location_required_title'),
            style: TextStyle(
                color: t.textPri, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Text(
            body,
            style: TextStyle(color: t.textSec, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('common_close'),
                  style: TextStyle(
                      color: t.textSec, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l.t('common_retry'),
                style: const TextStyle(
                    color: Color(0xFF059669), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ── Other dialogs ───────────────────────────

  void _showNoContactsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => _SosDialog(
        isDark: isDark,
        title: l.t('sos_no_contacts_title'),
        body: l.t('sos_no_contacts_body'),
        accentColor: const Color(0xFFD97706),
        actions: [
          _SosDialogAction(
            label: l.t('common_ok'),
            isPrimary: false,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
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
      ),
    );
  }

  void dispose() => stopShakeDetection();
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                          color:
                              accentColor.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: accentColor.withOpacity(0.22)),
                        ),
                        child: Icon(Icons.warning_rounded,
                            color: accentColor, size: 18),
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
                        color: t.textSec, fontSize: 13, height: 1.65),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: actions.asMap().entries.map((e) {
                      final a = e.value;
                      return Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(left: e.key > 0 ? 8 : 0),
                          child: GestureDetector(
                            onTap: a.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: a.isPrimary
                                    ? accentColor
                                    : accentColor.withOpacity(
                                        isDark ? 0.08 : 0.06),
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
                      );
                    }).toList(),
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
//  WEB SOS MODAL  (UNCHANGED)
// ─────────────────────────────────────────────

class _WebSOSModal extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final String message;
  final LocationResult location;
  final SOSMessageType type;
  final VoidCallback onClose;
  const _WebSOSModal({
    required this.contacts,
    required this.message,
    required this.location,
    required this.type,
    required this.onClose,
  });
  @override
  State<_WebSOSModal> createState() => _WebSOSModalState();
}

class _WebSOSModalState extends State<_WebSOSModal> {
  bool _messageCopied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _messageCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _messageCopied = false);
    });
  }

  Future<void> _openWhatsApp(EmergencyContact contact) async {
    final phone = contact.whatsappDigits;
    final encodedMsg = Uri.encodeComponent(widget.message);
    try {
      await launchUrl(
        Uri.parse('https://wa.me/$phone?text=$encodedMsg'),
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _DT(isDark);
    final l = AppLocalizations.of(context);

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
            // Red accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _DT.crimson,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _DT.crimson
                                .withOpacity(isDark ? 0.10 : 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _DT.crimson.withOpacity(0.22)),
                          ),
                          child: const Icon(Icons.emergency_rounded,
                              color: _DT.crimsonSoft, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.t('sos_activated_title'),
                                style: TextStyle(
                                  color: t.textPri,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _localizedSosTypeLabel(l, widget.type),
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

                    // ── Location banner ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (widget.location.isAvailable
                                ? _DT.green
                                : _DT.amber)
                            .withOpacity(isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (widget.location.isAvailable
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
                                  ? l
                                      .t('sos_location_attached')
                                      .replaceAll('{location}',
                                          widget.location.displayString)
                                  : l.t('sos_location_unavailable'),
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

                    // ── Contacts — each has its own Open button ──
                    Text(
                      l.t('sos_send_to_contacts'),
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
                        child: Row(
                          children: [
                            // Contact info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _DT.violet.withOpacity(
                                              isDark ? 0.10 : 0.07),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _DT.crimson.withOpacity(
                                                isDark ? 0.10 : 0.07),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            l.t('sos_primary_badge'),
                                            style: const TextStyle(
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
                                        color: t.textSec, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Per-contact "Open" button — manual fallback
                            GestureDetector(
                              onTap: () => _openWhatsApp(contact),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366)
                                      .withOpacity(isDark ? 0.15 : 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF25D366)
                                        .withOpacity(0.30),
                                  ),
                                ),
                                child: const Text(
                                  'Open',
                                  style: TextStyle(
                                    color: Color(0xFF25D366),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Copy message ─────────────────────────────
                    GestureDetector(
                      onTap: _copy,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _messageCopied
                              ? _DT.green
                                  .withOpacity(isDark ? 0.10 : 0.07)
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
                                  ? l.t('sos_copied')
                                  : l.t('sos_copy_message'),
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

                    // ── Close ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onClose,
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l.t('sos_close_safe'),
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