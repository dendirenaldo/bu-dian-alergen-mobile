import 'package:flutter/material.dart';

class RecentDetectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String severity;
  final double confidence;

  const RecentDetectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.confidence,
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
              color: _getSeverityColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSeverityIcon(),
              color: _getSeverityColor(context),
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
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getSeverityColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    switch (severity) {
      case 'high':
        return Theme.of(context).colorScheme.error;
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return Theme.of(context).colorScheme.primary;
      case 'safe':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  IconData _getSeverityIcon() {
    switch (severity) {
      case 'high':
        return Icons.dangerous;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      case 'safe':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}
