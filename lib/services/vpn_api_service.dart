import 'package:http/http.dart' as http;
import '../models/vpn_server.dart';

class VpnApiService {
  static const String apiUrl = 'https://www.vpngate.net/api/iphone/';
  
  /// Fetch VPN servers from VPN Gate API
  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'VPNGoat/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return _parseCsvResponse(response.body);
      } else {
        throw Exception('Failed to fetch servers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch servers: $e');
    }
  }

  /// Parse CSV response from API
  List<VpnServer> _parseCsvResponse(String csvData) {
    final List<VpnServer> servers = [];
    final lines = csvData.split('\n');
    
    // Skip header lines (first line is "*vpn_servers" and second is the header)
    bool foundHeader = false;
    
    for (final line in lines) {
      // Skip empty lines
      if (line.trim().isEmpty) continue;
      
      // Skip comment lines
      if (line.startsWith('*')) continue;
      
      // Skip the header row
      if (line.startsWith('#HostName')) {
        foundHeader = true;
        continue;
      }
      
      if (!foundHeader) continue;
      
      // Parse CSV row
      final row = _parseCsvRow(line);
      
      // Need at least basic fields
      if (row.length >= 15 && row[0].isNotEmpty && row[14].isNotEmpty) {
        try {
          final server = VpnServer.fromCsv(row);
          // Only add servers with valid OpenVPN config
          if (server.openVpnConfigDataBase64.isNotEmpty) {
            servers.add(server);
          }
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }
    }
    
    return servers;
  }

  /// Parse a CSV row handling potential commas in fields
  List<String> _parseCsvRow(String line) {
    final List<String> fields = [];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    
    // Add the last field
    fields.add(currentField.toString());
    
    return fields;
  }
}
