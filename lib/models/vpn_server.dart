import 'dart:convert';

class VpnServer {
  final String hostName;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int numVpnSessions;
  final int uptime;
  final int totalUsers;
  final int totalTraffic;
  final String logType;
  final String operator;
  final String message;
  final String openVpnConfigDataBase64;
  
  // Local state
  bool isFavorite;
  bool isNew;

  VpnServer({
    required this.hostName,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.uptime,
    required this.totalUsers,
    required this.totalTraffic,
    required this.logType,
    required this.operator,
    required this.message,
    required this.openVpnConfigDataBase64,
    this.isFavorite = false,
    this.isNew = false,
  });

  /// Unique identifier for the server
  String get uniqueId => '$hostName-$ip';

  /// Get decoded OpenVPN config
  String get openVpnConfig {
    try {
      return utf8.decode(base64Decode(openVpnConfigDataBase64));
    } catch (e) {
      return '';
    }
  }

  /// Get formatted speed in Mbps
  String get formattedSpeed {
    double mbps = speed / 1000000;
    if (mbps >= 1000) {
      return '${(mbps / 1000).toStringAsFixed(1)} Gbps';
    }
    return '${mbps.toStringAsFixed(1)} Mbps';
  }

  /// Get formatted uptime
  String get formattedUptime {
    int hours = uptime ~/ 3600000;
    int days = hours ~/ 24;
    if (days > 0) {
      return '$days days';
    }
    return '$hours hours';
  }

  /// Parse from CSV row
  factory VpnServer.fromCsv(List<String> row) {
    return VpnServer(
      hostName: row.isNotEmpty ? row[0] : '',
      ip: row.length > 1 ? row[1] : '',
      score: row.length > 2 ? int.tryParse(row[2]) ?? 0 : 0,
      ping: row.length > 3 ? int.tryParse(row[3]) ?? 9999 : 9999,
      speed: row.length > 4 ? int.tryParse(row[4]) ?? 0 : 0,
      countryLong: row.length > 5 ? row[5] : '',
      countryShort: row.length > 6 ? row[6] : '',
      numVpnSessions: row.length > 7 ? int.tryParse(row[7]) ?? 0 : 0,
      uptime: row.length > 8 ? int.tryParse(row[8]) ?? 0 : 0,
      totalUsers: row.length > 9 ? int.tryParse(row[9]) ?? 0 : 0,
      totalTraffic: row.length > 10 ? int.tryParse(row[10]) ?? 0 : 0,
      logType: row.length > 11 ? row[11] : '',
      operator: row.length > 12 ? row[12] : '',
      message: row.length > 13 ? row[13] : '',
      openVpnConfigDataBase64: row.length > 14 ? row[14] : '',
    );
  }

  /// Copy with modifications
  VpnServer copyWith({
    bool? isFavorite,
    bool? isNew,
  }) {
    return VpnServer(
      hostName: hostName,
      ip: ip,
      score: score,
      ping: ping,
      speed: speed,
      countryLong: countryLong,
      countryShort: countryShort,
      numVpnSessions: numVpnSessions,
      uptime: uptime,
      totalUsers: totalUsers,
      totalTraffic: totalTraffic,
      logType: logType,
      operator: operator,
      message: message,
      openVpnConfigDataBase64: openVpnConfigDataBase64,
      isFavorite: isFavorite ?? this.isFavorite,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VpnServer && other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => uniqueId.hashCode;
}
