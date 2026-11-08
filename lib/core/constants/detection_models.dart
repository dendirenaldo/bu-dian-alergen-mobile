class DetectionModels {
  static const List<String> values = ['bert', 'bilstm', 'ensemble'];
  static const String def = 'bert';

  static String sanitize(String? m) {
    final v = (m ?? def).toLowerCase().trim();
    return values.contains(v) ? v : def;
  }
}
