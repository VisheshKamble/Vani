// Imported on Web only via conditional import in LocationService.dart.
// Do NOT import this file directly.
// FIX: dart:html is deprecated in Flutter Web (Dart 3.x).
// We use geolocator's built-in web support instead — it works on web
// via its own JS interop under the hood, no dart:html needed.
// geolocator ^13.0.0 supports web natively out of the box.

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'LocationService.dart';

Future<LocationResult> getCurrentLocation() async {
  // geolocator works on web — it uses the browser Geolocation API
  // internally via its own JS interop. We just call the same API.

  // 1. Check if location services available (on web this checks
  //    whether the browser supports geolocation at all)
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return const LocationResult(
      isAvailable: false,
      error: 'Geolocation is not supported or enabled in this browser.',
    );
  }

  // 2. Check / request permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        isAvailable: false,
        error:
            'Location permission denied. Allow location access in your browser and try again.',
      );
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return const LocationResult(
      isAvailable: false,
      error:
          'Location permanently blocked in browser. Open browser settings → Site settings → Location to allow.',
    );
  }

  // 3. Get position with timeout
  try {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    return LocationResult(
      isAvailable: true,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } on TimeoutException {
    // Browser GPS timed out — try last known
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          isAvailable: true,
          latitude: last.latitude,
          longitude: last.longitude,
        );
      }
    } catch (_) {}
    return const LocationResult(
      isAvailable: false,
      error: 'Browser location timed out. Message will send without coordinates.',
    );
  } catch (e) {
    return LocationResult(
      isAvailable: false,
      error: 'Browser location error: ${e.toString()}',
    );
  }
}
