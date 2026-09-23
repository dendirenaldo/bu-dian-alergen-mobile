import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth untuk token tersimpan.
/// Mengembalikan null bila tidak ada ATAU string kosong (dipangkas),
/// agar semua lapis (splash, datasource, halaman) sepakat soal status tamu.
Future<String?> getValidToken() async {
  final prefs = await SharedPreferences.getInstance();
  final t = prefs.getString('auth_token')?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}
