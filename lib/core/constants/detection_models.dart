/// Single source of truth untuk pilihan model deteksi.
/// Urutan = urutan tampil di UI (default pertama).
class DetectionModels {
  static const List<String> values = ['bert', 'bilstm', 'ensemble'];
  static const String def = 'bert';

  static String sanitize(String? m) {
    final v = (m ?? def).toLowerCase().trim();
    return values.contains(v) ? v : def;
  }
}
