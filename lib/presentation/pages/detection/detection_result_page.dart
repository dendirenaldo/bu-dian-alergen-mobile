import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/detection/result_card.dart';
import '../../widgets/detection/allergen_badge.dart';

class DetectionResultPage extends StatelessWidget {
  const DetectionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                ResultCard(
                  title: 'Ringkasan Deteksi',
                  child: Column(
                    children: [
                      _buildResultRow(context, 'Hasil', result.result),
                      _buildResultRow(
                        context,
                        'Confidence',
                        '${(result.confidenceScore * 100).toStringAsFixed(1)}%',
                      ),
                      _buildResultRow(context, 'Metode', result.detectionMethod),
                      if (result.modelName != null)
                        _buildResultRow(context, 'Model', result.modelName!.toUpperCase()),
                      if (result.processingTimeMs != null)
                        _buildResultRow(
                          context,
                          'Waktu Proses',
                          '${result.processingTimeMs}ms',
                        ),
                      _buildResultRow(
                        context,
                        'Discan Pada',
                        DateFormat('d MMM yyyy HH:mm').format(result.createdAt),
                      ),
                    ],
                  ),
                ),
                if (result.allergens != null && result.allergens!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Alergen Terdeteksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      result.ocrText!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
