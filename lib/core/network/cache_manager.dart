import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String prefix = 'b4e_cache_';

  static Future<void> saveCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    await prefs.setString('$prefix$key', jsonString);
  }

  static Future<dynamic> getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$prefix$key');
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$prefix$key');
  }

  static Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}
