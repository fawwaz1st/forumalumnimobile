import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:forum_alumni/features/forum/data/models/post_model.dart';
import 'package:forum_alumni/features/profile/data/models/alumni_model.dart';
import 'package:forum_alumni/features/notifications/data/models/notification_model.dart';

class LocalStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;

  // Keys for different data types
  static const String _postsKey = 'cached_posts';
  static const String _userProfileKey = 'user_profile';
  static const String _alumniKey = 'cached_alumni';
  static const String _notificationsKey = 'cached_notifications';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _offlineModeKey = 'offline_mode';
  static const String _pendingActionsKey = 'pending_actions';

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Posts caching
  static Future<void> cachePosts(List<PostModel> posts) async {
    await init();
    final postsJson = posts.map((post) => post.toJson()).toList();
    await _prefs!.setString(_postsKey, jsonEncode(postsJson));
    await _updateLastSyncTime();
  }

  static Future<List<PostModel>?> getCachedPosts() async {
    await init();
    final postsString = _prefs!.getString(_postsKey);
    if (postsString == null) return null;

    try {
      final List<dynamic> postsJson = jsonDecode(postsString);
      return postsJson.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> cachePost(PostModel post) async {
    final cachedPosts = await getCachedPosts() ?? [];
    
    // Update existing post or add new one
    final existingIndex = cachedPosts.indexWhere((p) => p.id == post.id);
    if (existingIndex != -1) {
      cachedPosts[existingIndex] = post;
    } else {
      cachedPosts.insert(0, post);
    }

    await cachePosts(cachedPosts);
  }

  static Future<void> removeCachedPost(int postId) async {
    final cachedPosts = await getCachedPosts() ?? [];
    cachedPosts.removeWhere((post) => post.id == postId);
    await cachePosts(cachedPosts);
  }

  // User profile caching
  static Future<void> cacheUserProfile(AlumniModel profile) async {
    await _secureStorage.write(
      key: _userProfileKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  static Future<AlumniModel?> getCachedUserProfile() async {
    final profileString = await _secureStorage.read(key: _userProfileKey);
    if (profileString == null) return null;

    try {
      final profileJson = jsonDecode(profileString);
      return AlumniModel.fromJson(profileJson);
    } catch (e) {
      return null;
    }
  }

  // Alumni caching
  static Future<void> cacheAlumni(List<AlumniModel> alumni) async {
    await init();
    final alumniJson = alumni.map((alumni) => alumni.toJson()).toList();
    await _prefs!.setString(_alumniKey, jsonEncode(alumniJson));
  }

  static Future<List<AlumniModel>?> getCachedAlumni() async {
    await init();
    final alumniString = _prefs!.getString(_alumniKey);
    if (alumniString == null) return null;

    try {
      final List<dynamic> alumniJson = jsonDecode(alumniString);
      return alumniJson.map((json) => AlumniModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Notifications caching
  static Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    await init();
    final notificationsJson = notifications.map((notification) => notification.toJson()).toList();
    await _prefs!.setString(_notificationsKey, jsonEncode(notificationsJson));
  }

  static Future<List<NotificationModel>?> getCachedNotifications() async {
    await init();
    final notificationsString = _prefs!.getString(_notificationsKey);
    if (notificationsString == null) return null;

    try {
      final List<dynamic> notificationsJson = jsonDecode(notificationsString);
      return notificationsJson.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Offline mode management
  static Future<void> setOfflineMode(bool isOffline) async {
    await init();
    await _prefs!.setBool(_offlineModeKey, isOffline);
  }

  static Future<bool> isOfflineMode() async {
    await init();
    return _prefs!.getBool(_offlineModeKey) ?? false;
  }

  // Sync time management
  static Future<void> _updateLastSyncTime() async {
    await init();
    await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastSyncTime() async {
    await init();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<bool> isCacheExpired({Duration maxAge = const Duration(hours: 24)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }

  // Pending actions for sync when back online
  static Future<void> addPendingAction(Map<String, dynamic> action) async {
    await init();
    final existingActions = await getPendingActions();
    existingActions.add(action);
    await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    await init();
    final actionsString = _prefs!.getString(_pendingActionsKey);
    if (actionsString == null) return [];

    try {
      final List<dynamic> actionsJson = jsonDecode(actionsString);
      return actionsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> removePendingAction(Map<String, dynamic> action) async {
    await init();
    final existingActions = await getPendingActions();
    existingActions.removeWhere((a) => 
      a['id'] == action['id'] && a['type'] == action['type']);
    await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
  }

  static Future<void> clearPendingActions() async {
    await init();
    await _prefs!.remove(_pendingActionsKey);
  }

  // Search cache for quick access
  static Future<void> cacheSearchResults(String query, List<PostModel> results) async {
    await init();
    final searchKey = 'search_${query.hashCode}';
    final resultsJson = results.map((post) => post.toJson()).toList();
    await _prefs!.setString(searchKey, jsonEncode(resultsJson));
  }

  static Future<List<PostModel>?> getCachedSearchResults(String query) async {
    await init();
    final searchKey = 'search_${query.hashCode}';
    final resultsString = _prefs!.getString(searchKey);
    if (resultsString == null) return null;

    try {
      final List<dynamic> resultsJson = jsonDecode(resultsString);
      return resultsJson.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
    await init();
    await _prefs!.remove(_postsKey);
    await _prefs!.remove(_alumniKey);
    await _prefs!.remove(_notificationsKey);
    await _prefs!.remove(_lastSyncKey);
    
    // Clear search cache (find and remove all search keys)
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith('search_')) {
        await _prefs!.remove(key);
      }
    }
  }

  // Get cache size information
  static Future<Map<String, int>> getCacheInfo() async {
    await init();
    final info = <String, int>{};
    
    final postsSize = _prefs!.getString(_postsKey)?.length ?? 0;
    final alumniSize = _prefs!.getString(_alumniKey)?.length ?? 0;
    final notificationsSize = _prefs!.getString(_notificationsKey)?.length ?? 0;
    
    info['posts'] = postsSize;
    info['alumni'] = alumniSize;
    info['notifications'] = notificationsSize;
    info['total'] = postsSize + alumniSize + notificationsSize;
    
    return info;
  }
}
