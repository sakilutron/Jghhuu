import 'package:flutter/material.dart';
import '../models/vpn_server.dart';

class ServerCard extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ServerCard({
    super.key,
    required this.server,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: server.isNew ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: server.isNew
            ? BorderSide(color: Colors.green.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: server.isNew
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hostname and badges
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Country flag emoji
                          Text(
                            _getCountryFlag(server.countryShort),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  server.hostName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  server.countryLong,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badges
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (server.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            server.isFavorite
                                ? Icons.star
                                : Icons.star_border,
                            color: server.isFavorite
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          onPressed: onFavoriteToggle,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      Icons.speed,
                      server.formattedSpeed,
                      'Speed',
                      _getSpeedColor(server.speed),
                    ),
                    _buildStatItem(
                      context,
                      Icons.timer,
                      '${server.ping} ms',
                      'Ping',
                      _getPingColor(server.ping),
                    ),
                    _buildStatItem(
                      context,
                      Icons.people,
                      '${server.numVpnSessions}',
                      'Sessions',
                      Colors.blue,
                    ),
                    _buildStatItem(
                      context,
                      Icons.access_time,
                      server.formattedUptime,
                      'Uptime',
                      Colors.purple,
                    ),
                  ],
                ),
                // IP Address
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'IP: ${server.ip}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getSpeedColor(int speed) {
    double mbps = speed / 1000000;
    if (mbps >= 100) return Colors.green;
    if (mbps >= 50) return Colors.lightGreen;
    if (mbps >= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getPingColor(int ping) {
    if (ping < 50) return Colors.green;
    if (ping < 100) return Colors.lightGreen;
    if (ping < 200) return Colors.orange;
    return Colors.red;
  }

  String _getCountryFlag(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) {
      return '\u{1F3F3}'; // White flag for unknown
    }
    
    // Convert country code to flag emoji
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
