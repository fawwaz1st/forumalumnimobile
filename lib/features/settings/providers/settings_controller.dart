import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Map<String, bool> notifPrefs; // comments, mentions, votes, follows
  final bool loadImagesOnCellular;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notifPrefs = const {
      'comments': true,
      'mentions': true,
      'votes': true,
      'follows': true,
    },
    this.loadImagesOnCellular = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Map<String, bool>? notifPrefs,
    bool? loadImagesOnCellular,
  }) => SettingsState(
        themeMode: themeMode ?? this.themeMode,
        notifPrefs: notifPrefs ?? this.notifPrefs,
        loadImagesOnCellular: loadImagesOnCellular ?? this.loadImagesOnCellular,
      );

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode.name,
        'notifPrefs': notifPrefs,
        'loadImagesOnCellular': loadImagesOnCellular,
      };

  factory SettingsState.fromMap(Map<String, dynamic> map) {
    final m = map['notifPrefs'] as Map? ?? const {};
    return SettingsState(
      themeMode: _modeFromName(map['themeMode'] as String? ?? 'system'),
      notifPrefs: m.map((key, value) => MapEntry(key.toString(), value == true)),
      loadImagesOnCellular: map['loadImagesOnCellular'] == true,
    );
  }

  static ThemeMode _modeFromName(String name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._box) : super(const SettingsState()) {
    final raw = _box.get('settings_v1');
    if (raw != null) {
      try {
        state = SettingsState.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  final Box<String> _box;

  Future<void> _persist() async {
    await _box.put('settings_v1', jsonEncode(state.toMap()));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setNotifPref(String key, bool value) {
    final newMap = {...state.notifPrefs, key: value};
    state = state.copyWith(notifPrefs: newMap);
    _persist();
  }

  void setLoadImagesOnCellular(bool value) {
    state = state.copyWith(loadImagesOnCellular: value);
    _persist();
  }

  Future<void> clearCache() async {
    // Hanya contoh: bersihkan beberapa box yang kita gunakan.
    for (final name in ['posts_cache', 'posts_queue', 'post_drafts', 'notifications_v1', 'search_history_v1']) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      } else if (await Hive.boxExists(name)) {
        final b = await Hive.openBox(name);
        await b.clear();
        await b.close();
      }
    }
  }
}

final _settingsBoxProvider = FutureProvider<Box<String>>((ref) async {
  return Hive.isBoxOpen('app_settings') ? Hive.box<String>('app_settings') : await Hive.openBox<String>('app_settings');
});

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final boxAsync = ref.watch(_settingsBoxProvider);
  return boxAsync.maybeWhen(
    data: (box) => SettingsController(box),
    orElse: () => SettingsController(Hive.box<String>('app_settings')),
  );
});
