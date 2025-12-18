import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _previousServersKey = 'previous_servers';
  
  late SharedPreferences _prefs;
  
  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get list of favorite server IDs
  Set<String> getFavorites() {
    final List<String> favorites = _prefs.getStringList(_favoritesKey) ?? [];
    return favorites.toSet();
  }
  
  /// Add a server to favorites
  Future<void> addFavorite(String serverId) async {
    final favorites = getFavorites();
    favorites.add(serverId);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }
  
  /// Remove a server from favorites
  Future<void> removeFavorite(String serverId) async {
    final favorites = getFavorites();
    favorites.remove(serverId);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }
  
  /// Toggle favorite status
  Future<bool> toggleFavorite(String serverId) async {
    final favorites = getFavorites();
    if (favorites.contains(serverId)) {
      await removeFavorite(serverId);
      return false;
    } else {
      await addFavorite(serverId);
      return true;
    }
  }
  
  /// Check if a server is favorite
  bool isFavorite(String serverId) {
    return getFavorites().contains(serverId);
  }
  
  /// Get previous server IDs (for new server detection)
  Set<String> getPreviousServerIds() {
    final List<String> serverIds = _prefs.getStringList(_previousServersKey) ?? [];
    return serverIds.toSet();
  }
  
  /// Save current server IDs for next comparison
  Future<void> saveCurrentServerIds(List<String> serverIds) async {
    await _prefs.setStringList(_previousServersKey, serverIds);
  }
  
  /// Check if this is the first fetch (no previous servers stored)
  bool isFirstFetch() {
    return !_prefs.containsKey(_previousServersKey);
  }
}
