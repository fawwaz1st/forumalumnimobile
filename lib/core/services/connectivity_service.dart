import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/core/services/local_storage_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.read(connectivityServiceProvider);
  return service.isConnectedStream;
});

class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get isConnectedStream => _connectionController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Timer? _connectivityTimer;

  void _init() {
    // Check connectivity every 30 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });

    // Check initial connectivity status
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final wasConnected = _isConnected;
    
    try {
      // Simple connectivity check by attempting DNS lookup
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isConnected = false;
    }
    
    // Update offline mode in storage
    LocalStorageService.setOfflineMode(!_isConnected);
    
    // Notify listeners only if state changed
    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);

      // Handle connectivity state changes
      if (!wasConnected && _isConnected) {
        _onConnectedFromOffline();
      } else if (wasConnected && !_isConnected) {
        _onDisconnectedFromOnline();
      }
    }
  }

  void _onConnectedFromOffline() {
    // Trigger sync of pending actions
    _syncPendingActions();
  }

  void _onDisconnectedFromOnline() {
    // Optional: Show offline mode notification
    print('App went offline - using cached data');
  }

  Future<void> _syncPendingActions() async {
    try {
      final pendingActions = await LocalStorageService.getPendingActions();
      
      for (final action in pendingActions) {
        try {
          await _processPendingAction(action);
          await LocalStorageService.removePendingAction(action);
        } catch (e) {
          print('Failed to sync action: ${action['type']} - $e');
          // Keep action in queue for next sync attempt
        }
      }
    } catch (e) {
      print('Error syncing pending actions: $e');
    }
  }

  Future<void> _processPendingAction(Map<String, dynamic> action) async {
    switch (action['type']) {
      case 'create_post':
        // TODO: Implement post creation sync
        break;
      case 'like_post':
        // TODO: Implement like sync
        break;
      case 'comment_post':
        // TODO: Implement comment sync
        break;
      case 'update_profile':
        // TODO: Implement profile update sync
        break;
      default:
        print('Unknown action type: ${action['type']}');
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectionController.close();
  }
}
