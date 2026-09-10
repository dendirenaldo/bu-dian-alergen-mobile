import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSeverityColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSeverityColor(context).withValues(alpha: 0.2),
        ),
      ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Tingkat: ${severity.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSeverityColor(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getSeverityColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    switch (severity.toLowerCase()) {
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
