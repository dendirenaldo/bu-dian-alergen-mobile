import 'package:intl/intl.dart';

/// Helper tampilan berbahasa Indonesia untuk nilai mentah dari API/model.
///
/// Semua fungsi bersifat murni, null-safe, dan case-insensitive untuk input
/// String agar aman dipakai di seluruh presentation layer.

String formatModelName(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'bert':
      return 'BERT';
    case 'bilstm':
      return 'BiLSTM';
    case 'ensemble':
      return 'Ensemble';
    default:
      if (raw == null || raw.trim().isEmpty) return '-';
      return raw.trim();
  }
}

String formatMethod(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'image_ocr':
    case 'image':
    case 'ocr':
      return 'Gambar (OCR)';
    case 'text_input':
    case 'text':
      return 'Teks';
    default:
      if (raw == null || raw.trim().isEmpty) return '-';
      return raw.trim();
  }
}

String formatResult(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'safe':
      return 'Aman';
    case 'unsafe':
      return 'Berbahaya';
    case 'unknown':
      return 'Tidak diketahui';
    default:
      if (raw == null || raw.trim().isEmpty) return '-';
      return raw.trim();
  }
}

String formatSeverity(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'low':
      return 'Rendah';
    case 'medium':
      return 'Sedang';
    case 'high':
      return 'Tinggi';
    case 'critical':
      return 'Kritis';
    case 'safe':
      return 'Aman';
    default:
      if (raw == null || raw.trim().isEmpty) return '-';
      return raw.trim();
  }
}

/// 0.875 -> "87,5%". Satu desimal koma Indonesia.
/// Membuang ",0" agar 0.92 -> "92%" bukan "92,0%".
String formatConfidence(double? value) {
  if (value == null || value.isNaN) return '-';
  final pct = value * 100;
  final fixed = pct.toStringAsFixed(1).replaceAll('.', ',');
  if (fixed.endsWith(',0')) {
    return '${fixed.substring(0, fixed.length - 2)}%';
  }
  return '$fixed%';
}

/// ms -> detik Indonesia + " dtk".
/// 123 -> "0,1 dtk", 1230 -> "1,2 dtk".
String formatDuration(int? ms) {
  if (ms == null) return '-';
  final sec = ms / 1000;
  final fixed = sec.toStringAsFixed(1).replaceAll('.', ',');
  return '$fixed dtk';
}

/// DateTime -> "12 Jan 2026 14:30" via intl id_ID.
String formatDateId(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM yyyy HH:mm', 'id_ID').format(date);
}

String formatAllergenCount(int count) {
  if (count <= 0) return 'Tidak ada alergen';
  return '$count alergen';
}
