import 'package:flutter/material.dart';

/// Nama tahap SSE yang ramah pengguna (tanpa jargon teknis).
String formatStage(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'received':
      return 'Menerima permintaan';
    case 'quota_reserved':
      return 'Mengecek kuota';
    case 'upload_ok':
      return 'Gambar diterima';
    case 'ml_start':
      return 'Mulai memeriksa';
    case 'ml_ocr':
      return 'Membaca tulisan label';
    case 'ml_infer':
      return 'Mengenali bahan';
    case 'ml_mapping':
      return 'Mencocokkan alergen';
    case 'db_saved':
      return 'Menyimpan hasil';
    case 'done':
      return 'Selesai';
    case 'error':
      return 'Gagal';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      if (raw == null || raw.trim().isEmpty) return 'Memproses';
      return raw.trim();
  }
}

/// Indikator progres nyata SSE (bukan skeleton statis).
///
/// [progress] 0..1; null = indeterminate (fallback POST lama tanpa SSE).
class ProcessingIndicator extends StatelessWidget {
  final double? progress;
  final String? stage;
  final String? message;
  final int? etaMs;
  final VoidCallback? onCancel;

  const ProcessingIndicator({
    super.key,
    this.progress,
    this.stage,
    this.message,
    this.etaMs,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = progress == null ? null : (progress!.clamp(0.0, 1.0) * 100).round();
    final etaSec = etaMs == null ? null : (etaMs! / 1000).ceil();
    final liveLabel = progress == null
        ? 'Sedang memproses${stage != null ? ': ${formatStage(stage)}' : ''}'
        : 'Progres ${pct ?? 0} persen, tahap ${formatStage(stage)}'
            '${etaSec != null ? ', sisa sekitar $etaSec detik' : ''}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: liveLabel,
            liveRegion: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatStage(stage),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (pct != null)
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          if (message != null && message!.trim().isNotEmpty)
            Text(
              message!.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (etaSec != null && etaSec > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Perkiraan sisa waktu: $etaSec dtk',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: 'Batalkan deteksi',
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Batal'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
