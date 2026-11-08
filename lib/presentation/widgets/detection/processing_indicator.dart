import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Indikator pemrosesan — skeleton stepper 3 langkah.
class ProcessingIndicator extends StatelessWidget {
  const ProcessingIndicator({super.key});

  static const _steps = [
    (title: 'Mengunggah gambar...', subtitle: 'Mengirim ke server'),
    (title: 'Menganalisis gambar...', subtitle: 'Menjalankan model deteksi'),
    (title: 'Menyusun hasil...', subtitle: 'Menyiapkan ringkasan alergen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Sedang memproses',
              liveRegion: true,
              child: Text(
                'Memproses deteksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _steps.length; i++) ...[
              _StepRow(
                index: i + 1,
                title: _steps[i].title,
                subtitle: _steps[i].subtitle,
                isLast: i == _steps.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool isLast;

  const _StepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('$index')),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: Colors.grey,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
