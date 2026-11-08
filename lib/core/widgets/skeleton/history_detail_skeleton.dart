import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton detail riwayat — meniru layout [HistoryDetailPage].
class HistoryDetailSkeleton extends StatelessWidget {
  const HistoryDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _FakeRow(),
          const _FakeRow(),
          const _FakeRow(),
          const _FakeRow(),
          const SizedBox(height: 12),
          Text(
            'Teks OCR',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore.',
          ),
          const SizedBox(height: 12),
          Text(
            'Alergen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _FakeAllergenBadge(),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeRow extends StatelessWidget {
  const _FakeRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Label'),
          Text('Nilai detail'),
        ],
      ),
    );
  }
}

class _FakeAllergenBadge extends StatelessWidget {
  const _FakeAllergenBadge();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kacang Tanah'),
                  SizedBox(height: 4),
                  Text('Tinggi • 92%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
