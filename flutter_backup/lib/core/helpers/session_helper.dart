import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/*
class SessionManager {
  static const _key = 'session_id';
  static Future<void> save(String id) async =>
      (await SharedPreferences.getInstance()).setString(_key, id);

  static Future<String?> load() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}*/

class SessionManager {
  static const _kAuth = 'auth_json';

  static Future<void> save(String sid, int uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuth, jsonEncode({'session_id': sid, 'uid': uid}));
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAuth);
    return raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
  }

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_kAuth);
}
