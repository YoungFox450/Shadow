import 'package:flutter/services.dart';

/// Pont vers le code natif Android pour vérifier et demander les
/// permissions nécessaires au verrouillage :
/// - Accès à l'utilisation (PACKAGE_USAGE_STATS)
/// - Affichage par-dessus les autres apps (SYSTEM_ALERT_WINDOW)
/// - Service d'accessibilité (AccessibilityService)
class PermissionsBridge {
  PermissionsBridge._();

  static const MethodChannel _channel = MethodChannel('shadow/permissions');

  static Future<bool> isUsageAccessGranted() =>
      _safeBoolCall('isUsageAccessGranted');

  static Future<void> requestUsageAccess() =>
      _safeVoidCall('openUsageAccessSettings');

  static Future<bool> isOverlayGranted() =>
      _safeBoolCall('isOverlayGranted');

  static Future<void> requestOverlay() =>
      _safeVoidCall('openOverlaySettings');

  static Future<bool> isAccessibilityServiceEnabled() =>
      _safeBoolCall('isAccessibilityServiceEnabled');

  static Future<void> requestAccessibilityService() =>
      _safeVoidCall('openAccessibilitySettings');

  static Future<bool> _safeBoolCall(String method) async {
    try {
      final result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> _safeVoidCall(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on PlatformException {
      // Ignoré si l'écran de réglages ne peut pas s'ouvrir
    } on MissingPluginException {
      // Plateforme non-Android
    }
  }
}
