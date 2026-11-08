import 'package:flutter/material.dart';
import '../../../core/utils/display_names.dart';

class AllergenBadge extends StatelessWidget {
  final String name;
  final String severity;
  final double confidence;

  const AllergenBadge({
    super.key,
    required this.name,
    required this.severity,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color:
          _getSeverityColor(context).withValues(alpha: 0.05),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getSeverityColor(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber,
                color: _getSeverityColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    'Tingkat: ${formatSeverity(severity)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: _getSeverityColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatConfidence(confidence),
              style: textTheme.titleMedium?.copyWith(
                color: _getSeverityColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFF7F1D1D);
      case 'high':
        return Theme.of(context).colorScheme.error;
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}
