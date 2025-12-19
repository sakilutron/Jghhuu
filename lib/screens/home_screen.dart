import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/vpn_provider.dart';
import '../models/vpn_server.dart';
import '../widgets/server_card.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../services/openvpn_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, child) {
        // Create or update tab controller when countries change
        if (_tabController == null || 
            _tabController!.length != provider.countries.length) {
          _tabController?.dispose();
          if (provider.countries.isNotEmpty) {
            _tabController = TabController(
              length: provider.countries.length,
              vsync: this,
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.vpn_key, size: 32);
                  },
                ),
                const SizedBox(width: 8),
                const Text('VPN Goat'),
              ],
            ),
            actions: [
              // Stats badge
              if (!provider.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.newServerCount > 0) ...[
                        _buildBadge(
                          '${provider.newServerCount} new',
                          Colors.green,
                        ),
                        const SizedBox(width: 4),
                      ],
                      _buildBadge(
                        '${provider.totalServerCount}',
                        Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              // Refresh button
              IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.fetchServers(),
                tooltip: 'Refresh',
              ),
            ],
            bottom: provider.countries.isNotEmpty && _tabController != null
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: provider.countries.map((country) {
                      final count = provider.getServersForCountry(country).length;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getCountryFlag(country)),
                            const SizedBox(width: 4),
                            Text('$country ($count)'),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : null,
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBody(VpnProvider provider) {
    // Show banner if we are not disconnected
    final showBanner = provider.vpnStage != null && provider.vpnStage != VPNStage.disconnected;

    return Column(
      children: [
        if (showBanner)
          _buildVpnStatusBanner(provider),
        Expanded(
          child: _buildServerListContent(provider),
        ),
      ],
    );
  }

  Widget _buildVpnStatusBanner(VpnProvider provider) {
    final stage = provider.vpnStage;
    final status = provider.vpnStatus;
    final isConnected = stage == VPNStage.connected;

    String statusText = 'Connecting...';
    if (stage == VPNStage.connected) statusText = 'Connected';
    if (stage == VPNStage.disconnected) statusText = 'Disconnected';
    if (stage == VPNStage.wait_connection) statusText = 'Waiting for connection...';
    if (stage == VPNStage.authenticating) statusText = 'Authenticating...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: isConnected ? Colors.green : Colors.orange,
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.vpn_lock : Icons.sync,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status?.duration != null)
                  Text(
                    status!.duration!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: () => OpenVpnService.disconnect(),
          ),
        ],
      ),
    );
  }

  Widget _buildServerListContent(VpnProvider provider) {
    if (provider.isLoading && provider.servers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching VPN servers...'),
          ],
        ),
      );
    }

    if (provider.error != null && provider.servers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load servers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.fetchServers(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.countries.isEmpty) {
      return const Center(
        child: Text('No servers available'),
      );
    }

    return Column(
      children: [
        // Last refresh indicator
        if (provider.lastRefresh != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${_formatTime(provider.lastRefresh!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Auto-refresh: 30s)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        // Server list
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: provider.countries.map((country) {
              final servers = provider.getServersForCountry(country);
              return _buildServerList(servers, provider);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServerList(List<VpnServer> servers, VpnProvider provider) {
    if (servers.isEmpty) {
      return const Center(
        child: Text('No servers in this country'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchServers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          return ServerCard(
            server: server,
            onTap: () => _showServerDetails(server),
            onFavoriteToggle: () => provider.toggleFavorite(server),
          );
        },
      ),
    );
  }

  void _showServerDetails(VpnServer server) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Server header
                  Row(
                    children: [
                      Text(
                        _getCountryFlag(server.countryShort),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.hostName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              server.countryLong,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (server.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _connectToServer(server),
                      icon: const Icon(Icons.vpn_key),
                      label: const Text(
                        'Connect with OpenVPN',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Server details
                  _buildDetailSection('Connection Details', [
                    _buildDetailRow('IP Address', server.ip),
                    _buildDetailRow('Speed', server.formattedSpeed),
                    _buildDetailRow('Ping', '${server.ping} ms'),
                    _buildDetailRow('Score', '${server.score}'),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection('Server Info', [
                    _buildDetailRow('Uptime', server.formattedUptime),
                    _buildDetailRow('Sessions', '${server.numVpnSessions}'),
                    _buildDetailRow('Total Users', '${server.totalUsers}'),
                    _buildDetailRow('Operator', server.operator.isNotEmpty ? server.operator : 'N/A'),
                  ]),
                  if (server.message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailSection('Message', [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          server.message,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToServer(VpnServer server) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    // Show connecting message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to VPN server...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await OpenVpnService.connect(server);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getCountryFlag(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) {
      return '\u{1F3F3}';
    }
    
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
