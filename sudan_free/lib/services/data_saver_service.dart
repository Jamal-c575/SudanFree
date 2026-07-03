import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSaverService extends ChangeNotifier {
  static final DataSaverService _instance = DataSaverService._internal();
  factory DataSaverService() => _instance;
  DataSaverService._internal();

  bool _isDataSaverEnabled = false;
  bool get isDataSaverEnabled => _isDataSaverEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDataSaverEnabled = prefs.getBool('data_saver_enabled') ?? false;
  }

  Future<void> toggleDataSaver(bool value) async {
    _isDataSaverEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_saver_enabled', value);
    notifyListeners();
  }

  // Returns optimized image parameters based on data saver mode
  String optimizeImageUrl(String originalUrl) {
    if (!_isDataSaverEnabled) return originalUrl;
    
    // Example: If using Firebase Extensions for resizing (e.g. _200x200)
    // Here we just return the original if we don't have a specific compression setup,
    // but we can append a query param or change the path if a resize extension is active.
    // For now, this is a placeholder where you'd inject '?alt=media&quality=low' 
    // or modify the path to point to a thumbnail.
    return originalUrl;
  }
}
