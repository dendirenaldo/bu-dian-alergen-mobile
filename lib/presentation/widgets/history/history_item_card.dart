import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      method,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (allergenCount > 0) ...[
                      Text(' • ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      Text(
                        '$allergenCount alergen${allergenCount > 1 ? '' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy HH:mm').format(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getResultColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getResultColor(context),
              ),
            ),
          ),
        ],
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
