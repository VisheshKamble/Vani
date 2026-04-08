import 'package:flutter/foundation.dart';

enum WebHomeSection {
  home,
  features,
  howItWorks,
  objectives,
  vision,
  contact,
}

class WebHomeNav {
  static final ValueNotifier<WebHomeSection?> _sectionNotifier =
      ValueNotifier<WebHomeSection?>(null);

  static ValueListenable<WebHomeSection?> get listenable => _sectionNotifier;

  static WebHomeSection? get requestedSection => _sectionNotifier.value;

  static void request(WebHomeSection section) {
    _sectionNotifier.value = section;
  }

  static void clear() {
    _sectionNotifier.value = null;
  }
}
