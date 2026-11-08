import 'package:flutter/material.dart';
import '../../../core/utils/display_names.dart';

class HistoryItemCard extends StatelessWidget {
  final String title;
  final String method;
  final double confidence;
  final DateTime createdAt;
  final int allergenCount;

  const HistoryItemCard({
    super.key,
    required this.title,
    required this.method,
    required this.confidence,
    required this.createdAt,
    required this.allergenCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final resultLabel = formatResult(
      allergenCount > 0 ? 'unsafe' : 'safe',
    );
    return Semantics(
      label: 'Deteksi $title, status: $resultLabel',
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getResultColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getResultIcon(),
                  color: _getResultColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatResult(title),
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatMethod(method),
                          style: textTheme.bodySmall,
                        ),
                        if (allergenCount > 0) ...[
                          Text(
                            ' • ',
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            formatAllergenCount(allergenCount),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateId(createdAt),
                      style: textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getResultColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatConfidence(confidence),
                  style: textTheme.labelMedium?.copyWith(
                    color: _getResultColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(BuildContext context) {
    if (allergenCount > 0) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.secondary;
  }

  IconData _getResultIcon() {
    if (allergenCount > 0) return Icons.warning_amber;
    return Icons.check_circle;
  }
}
