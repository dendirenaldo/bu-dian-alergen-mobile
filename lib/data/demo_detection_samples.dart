import '../../domain/entities/detection_entity.dart';

/// Contoh hasil siap pakai untuk Mode Latihan.
///
/// Tidak memanggil jaringan apa pun. Dipakai oleh
/// [DetectionProvider.detectDemo] agar pengguna bisa mencoba alur
/// tanpa memotret label asli.
final List<DetectionEntity> demoDetectionSamples = [
  DetectionEntity(
    id: -1,
    imageUrl: null,
    ocrText:
        'SUSU BUBUK FULL CREAM\nKomposisi: susu sapi segar, vitamin A, vitamin D3, kalsium.\nBerat bersih: 400 g.\nDiproduksi: PT Contoh Pangan Aman, Jakarta.',
    result: 'safe',
    confidenceScore: 0.98,
    processingTimeMs: 120,
    detectionMethod: 'image_ocr',
    modelName: 'bert',
    createdAt: DateTime(2026, 11, 8, 9, 30),
    allergens: const [],
  ),
  DetectionEntity(
    id: -2,
    imageUrl: null,
    ocrText:
        'MINYAK KEDELAI MURNI\nKomposisi: minyak kedelai (mengandung lesitin kedelai), antioksidan tokoferol.\nBerat bersih: 1 L.\nDiproduksi: PT Contoh Pangan, Surabaya.',
    result: 'unsafe',
    confidenceScore: 0.92,
    processingTimeMs: 210,
    detectionMethod: 'image_ocr',
    modelName: 'bert',
    createdAt: DateTime(2026, 11, 8, 9, 31),
    allergens: [
      AllergenResultEntity(
        allergenId: 1,
        name: 'Kedelai',
        severity: 'high',
        confidenceScore: 0.92,
      ),
    ],
  ),
  DetectionEntity(
    id: -3,
    imageUrl: null,
    ocrText:
        'BISKUIT GANDUM RENYAH\nKomposisi: tepung terigu (mengandung gluten), gula, margarin, susu bubuk, garam, pengembang.\nBerat bersih: 250 g.\nDiproduksi: PT Contoh Roti, Bandung.',
    result: 'unsafe',
    confidenceScore: 0.85,
    processingTimeMs: 180,
    detectionMethod: 'image_ocr',
    modelName: 'bert',
    createdAt: DateTime(2026, 11, 8, 9, 32),
    allergens: [
      AllergenResultEntity(
        allergenId: 2,
        name: 'Gluten',
        severity: 'medium',
        confidenceScore: 0.85,
      ),
    ],
  ),
];

/// Label pendek untuk ditampilkan di lembar pilih contoh.
const List<String> demoDetectionTitles = [
  'Susu Bubuk Aman',
  'Lecithin Kedelai Berbahaya',
  'Biskuit Gluten Sedang',
];
