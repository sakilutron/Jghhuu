import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vpn_server.dart';

class OpenVpnService {
  /// Launch OpenVPN with the server configuration
  static Future<bool> connect(VpnServer server) async {
    final config = server.openVpnConfig;
    if (config.isEmpty) {
      return false;
    }

    if (Platform.isAndroid) {
      return await _launchAndroidOpenVpn(config, server);
    } else {
      // For other platforms, try to open a data URI
      return await _launchGenericOpenVpn(config, server);
    }
  }

  /// Launch OpenVPN on Android using Intent
  static Future<bool> _launchAndroidOpenVpn(String config, VpnServer server) async {
    // 1. Try Generic View with Data URI (Works for OpenVPN Connect and others)
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        type: 'application/x-openvpn-profile',
        data: 'data:application/x-openvpn-profile;base64,${server.openVpnConfigDataBase64}',
        flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK
      );
      await intent.launch();
      return true;
    } catch (e) {
      // Continue
    }

    // 2. Try OpenVPN for Android (de.blinkt.openvpn) with SEND intent (Import profile)
    // Needs text/plain type for inline config
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SEND',
        type: 'text/plain',
        arguments: <String, dynamic>{
          'android.intent.extra.TEXT': config,
        },
        package: 'de.blinkt.openvpn',
        flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK
      );
      
      await intent.launch();
      return true;
    } catch (e) {
      // Continue
    }

    // 3. Try OpenVPN Connect (net.openvpn.openvpn) explicitly with Data URI
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        type: 'application/x-openvpn-profile',
        data: 'data:application/x-openvpn-profile;base64,${server.openVpnConfigDataBase64}',
        package: 'net.openvpn.openvpn',
        flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK
      );

      await intent.launch();
      return true;
    } catch (e) {
      // Continue
    }

    return false;
  }

  /// Generic OpenVPN launch for non-Android platforms
  static Future<bool> _launchGenericOpenVpn(String config, VpnServer server) async {
    // Create a data URI for the config
    final dataUri = Uri.parse(
      'data:application/x-openvpn-profile;base64,${server.openVpnConfigDataBase64}'
    );
    
    if (await canLaunchUrl(dataUri)) {
      return await launchUrl(dataUri);
    }
    return false;
  }

  /// Check if OpenVPN app is installed
  static Future<bool> isOpenVpnInstalled() async {
    if (Platform.isAndroid) {
      try {
        // Check for common OpenVPN apps
        final packages = [
          'net.openvpn.openvpn',
          'de.blinkt.openvpn',
        ];
        
        for (final package in packages) {
          try {
            final intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              package: package,
            );
            // If this doesn't throw, the package exists
            await intent.launch();
            return true;
          } catch (e) {
            continue;
          }
        }
        return false;
      } catch (e) {
        return false;
      }
    }
    return true; // Assume true for other platforms
  }

  /// Get Google Play Store link for OpenVPN Connect
  static String get openVpnPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=net.openvpn.openvpn';

  /// Get Google Play Store link for OpenVPN for Android
  static String get openVpnForAndroidPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=de.blinkt.openvpn';
}
