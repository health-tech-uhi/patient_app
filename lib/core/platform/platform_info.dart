import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Apple ecosystem only — avoids changing feel on Android/Web.
void hapticSelectionOnApple() {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      HapticFeedback.selectionClick();
    default:
      break;
  }
}
