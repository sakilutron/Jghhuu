import 'dart:async';
import 'dart:io';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/vpn_server.dart';

class OpenVpnService {
  static final OpenVPN _openVPN = OpenVPN(
    onVpnStatusChanged: _onVpnStatusChanged,
    onVpnStageChanged: _onVpnStageChanged,
  );

  static bool _isInitialized = false;

  // Stream controller for VPN status
  static final _statusController = StreamController<VPNStatus?>.broadcast();
  static Stream<VPNStatus?> get statusStream => _statusController.stream;

  // Current status
  static VPNStatus? _currentStatus;
  static VPNStatus? get currentStatus => _currentStatus;

  /// Initialize the OpenVPN engine
  static void initialize() {
    if (!_isInitialized) {
      _openVPN.initialize(
        groupIdentifier: "group.com.vpngoat.vpn",
        providerBundleIdentifier: "id.laskarmedia.openvpnFlutterExample.VPNExtension", // Using default for now as we don't have iOS setup
        localizedDescription: "VPN Goat",
      );
      _isInitialized = true;
    }
  }

  /// Request necessary permissions
  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  /// Connect to the VPN server
  static Future<void> connect(VpnServer server) async {
    if (!_isInitialized) initialize();
    await requestPermissions();

    final config = server.openVpnConfig;
    if (config.isEmpty) {
      return;
    }

    _openVPN.connect(
      config,
      server.hostName,
      username: '',
      password: '',
      certIsRequired: false,
    );
  }

  /// Disconnect from VPN
  static void disconnect() {
    if (_isInitialized) {
      _openVPN.disconnect();
    }
  }

  // Status callbacks
  static void _onVpnStatusChanged(VPNStatus? status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  static void _onVpnStageChanged(VPNStage? stage) {
    // Currently relying on status changes which includes connection state
  }

  /// Get Google Play Store link for OpenVPN Connect (legacy support if needed)
  static String get openVpnPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=net.openvpn.openvpn';

  /// Get Google Play Store link for OpenVPN for Android (legacy support if needed)
  static String get openVpnForAndroidPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=de.blinkt.openvpn';
}
