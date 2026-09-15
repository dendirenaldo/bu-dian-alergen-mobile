import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/datasources/settings_remote_datasource.dart';

/// Nama aplikasi mengikuti backend (`GET /settings/public` → `app_name`),
/// dengan fallback [AppConfig.appName] ("Allergen Detector") bila
/// offline/error. Dimuat sekali saat splash.
class AppSettingsProvider extends ChangeNotifier {
  final SettingsRemoteDataSource _dataSource;

  AppSettingsProvider({SettingsRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? SettingsRemoteDataSource();

  String _appName = AppConfig.appName;
  bool _loaded = false;

  String get appName => _appName;
  bool get loaded => _loaded;

  String get initials {
    final words = _appName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'AD';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final pub = await _dataSource.getPublic();
      final name = (pub['app_name'] ?? '').trim();
      if (name.isNotEmpty) {
        _appName = name;
      }
    } catch (_) {
      // offline/error → tetap fallback
    }
    _loaded = true;
    notifyListeners();
  }
}
