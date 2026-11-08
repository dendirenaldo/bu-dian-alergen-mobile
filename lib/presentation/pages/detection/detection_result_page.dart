import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/tour/tour_keys.dart';
import '../../../core/utils/display_names.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/detection/result_card.dart';
import '../../widgets/detection/allergen_badge.dart';

class DetectionResultPage extends StatelessWidget {
  const DetectionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Consumer<DetectionProvider>(
      builder: (context, provider, _) {
        final result = provider.result;
        if (result == null) {
          return const Scaffold(
            body: Center(child: Text('Tidak ada hasil')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hasil Deteksi'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.isDemo)
                  Semantics(
                    label:
                        'Mode Latihan, tidak disimpan ke Riwayat',
                    liveRegion: true,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 20,
                            color: Color(0xFF92400E),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode Latihan — tidak disimpan ke Riwayat',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  key: TourKeys.resultCardKey,
                  child: ResultCard(
                    title: 'Ringkasan Deteksi',
                    child: Column(
                      children: [
                        _buildResultRow(
                            context, 'Hasil', formatResult(result.result)),
                        _buildResultRow(
                          context,
                          'Confidence',
                          formatConfidence(result.confidenceScore),
                        ),
                        _buildResultRow(
                            context, 'Metode', formatMethod(result.detectionMethod)),
                        if (result.modelName != null)
                          _buildResultRow(context, 'Model',
                              formatModelName(result.modelName)),
                        if (result.processingTimeMs != null)
                          _buildResultRow(
                            context,
                            'Waktu Proses',
                            formatDuration(result.processingTimeMs),
                          ),
                        _buildResultRow(
                          context,
                          'Discan Pada',
                          formatDateId(result.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                if (result.allergens != null && result.allergens!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Alergen Terdeteksi',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...result.allergens!.map(
                    (allergen) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AllergenBadge(
                        name: allergen.name,
                        severity: allergen.severity,
                        confidence: allergen.confidenceScore,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (result.ocrText != null) ...[
                  Text(
                    'Teks Terekstrak',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        result.ocrText!,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      provider.clearResult();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Scan Lagi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
