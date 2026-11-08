import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getValidToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('auth_token')?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  } catch (_) {
    return null;
  }
}
