import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class PlatformHelper {
  // True when running in a browser (Flutter Web)
  static bool get isWeb => kIsWeb;

  // True when running on Android or iOS device/emulator
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // True on Android specifically
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // True on iOS specifically
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  // True on desktop platforms
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // Can this platform use the device accelerometer for shake?
  static bool get supportsShake => isMobile;

  // Can this platform send an SMS directly via url_launcher?
  // Android/iOS yes. Web/Desktop no.
  static bool get canSendSMS => isMobile;

  // Can this platform vibrate?
  static bool get canVibrate => isMobile;

  // Can this platform get GPS coordinates?
  // Mobile = yes (geolocator). Web = yes (browser geolocation, needs permission).
  // Desktop = no reliable GPS.
  static bool get hasGPS => isMobile || isWeb;

  // Returns a human-readable platform name for logging/debugging
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isDesktop) return 'Desktop';
    return 'Unknown';
  }
}
