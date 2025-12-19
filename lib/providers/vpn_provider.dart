import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../models/vpn_server.dart';
import '../services/vpn_api_service.dart';
import '../services/storage_service.dart';
import '../services/openvpn_service.dart';

class VpnProvider extends ChangeNotifier {
  final VpnApiService _apiService = VpnApiService();
  final StorageService _storageService = StorageService();
  
  List<VpnServer> _servers = [];
  Map<String, List<VpnServer>> _serversByCountry = {};
  List<String> _countries = [];
  bool _isLoading = false;
  String? _error;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;
  
  // VPN Status
  VPNStatus? _vpnStatus;
  StreamSubscription<VPNStatus?>? _vpnStatusSubscription;

  // Getters
  List<VpnServer> get servers => _servers;
  Map<String, List<VpnServer>> get serversByCountry => _serversByCountry;
  List<String> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;
  VPNStatus? get vpnStatus => _vpnStatus;
  
  /// Initialize the provider
  Future<void> init() async {
    await _storageService.init();
    await fetchServers();
    _startAutoRefresh();
    _listenToVpnStatus();
  }

  void _listenToVpnStatus() {
    _vpnStatusSubscription = OpenVpnService.statusStream.listen((status) {
      _vpnStatus = status;
      notifyListeners();
    });
  }
  
  /// Fetch servers from API
  Future<void> fetchServers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newServers = await _apiService.fetchServers();
      final favorites = _storageService.getFavorites();
      final previousServerIds = _storageService.getPreviousServerIds();
      final isFirstFetch = _storageService.isFirstFetch();
      
      // Apply favorites and new status
      for (var server in newServers) {
        server.isFavorite = favorites.contains(server.uniqueId);
        // Mark as new only if not first fetch and server wasn't in previous list
        server.isNew = !isFirstFetch && !previousServerIds.contains(server.uniqueId);
      }
      
      // Save current server IDs for next comparison
      await _storageService.saveCurrentServerIds(
        newServers.map((s) => s.uniqueId).toList()
      );
      
      _servers = newServers;
      _organizeByCountry();
      _lastRefresh = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Organize servers by country with US prioritized
  void _organizeByCountry() {
    _serversByCountry = {};
    
    for (final server in _servers) {
      final country = server.countryShort.isNotEmpty 
          ? server.countryShort 
          : 'Unknown';
      
      if (!_serversByCountry.containsKey(country)) {
        _serversByCountry[country] = [];
      }
      _serversByCountry[country]!.add(server);
    }
    
    // Sort servers within each country
    for (final country in _serversByCountry.keys) {
      _sortServers(_serversByCountry[country]!);
    }
    
    // Create country list with US first
    _countries = _serversByCountry.keys.toList();
    _countries.sort((a, b) {
      // US comes first
      if (a == 'US') return -1;
      if (b == 'US') return 1;
      // Then sort alphabetically
      return a.compareTo(b);
    });
  }
  
  /// Sort servers: New first, then Favorites, then by Ping
  void _sortServers(List<VpnServer> servers) {
    servers.sort((a, b) {
      // New servers first
      if (a.isNew && !b.isNew) return -1;
      if (!a.isNew && b.isNew) return 1;
      
      // Favorites second
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      
      // Then by ping (lower is better)
      return a.ping.compareTo(b.ping);
    });
  }
  
  /// Toggle favorite status for a server
  Future<void> toggleFavorite(VpnServer server) async {
    final isFavorite = await _storageService.toggleFavorite(server.uniqueId);
    
    // Update server in the list
    final index = _servers.indexWhere((s) => s.uniqueId == server.uniqueId);
    if (index != -1) {
      _servers[index] = _servers[index].copyWith(isFavorite: isFavorite);
    }
    
    // Re-organize to apply new sorting
    _organizeByCountry();
    notifyListeners();
  }
  
  /// Get servers for a specific country
  List<VpnServer> getServersForCountry(String countryCode) {
    return _serversByCountry[countryCode] ?? [];
  }
  
  /// Get total server count
  int get totalServerCount => _servers.length;
  
  /// Get favorite count
  int get favoriteCount => _servers.where((s) => s.isFavorite).length;
  
  /// Get new server count
  int get newServerCount => _servers.where((s) => s.isNew).length;
  
  /// Start auto-refresh timer (every 30 seconds)
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchServers(),
    );
  }
  
  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  /// Resume auto-refresh timer
  void resumeAutoRefresh() {
    _startAutoRefresh();
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _vpnStatusSubscription?.cancel();
    super.dispose();
  }
}
