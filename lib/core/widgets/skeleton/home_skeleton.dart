import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton beranda — meniru header + [RecentDetectionCard], 5 baris.
class HomeSkeleton extends StatelessWidget {
  final int itemCount;

  const HomeSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat Pagi, User!'),
                    SizedBox(height: 4),
                    Text('Siap mendeteksi alergen?'),
                  ],
                ),
              ),
              CircleAvatar(radius: 24, child: Text('U')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Deteksi Terakhir'),
          const SizedBox(height: 8),
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _FakeRecentCard(),
            ),
        ],
      ),
    );
  }
}

class _FakeRecentCard extends StatelessWidget {
  const _FakeRecentCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Susu Bubuk Terdeteksi'),
                  SizedBox(height: 2),
                  Text('Scan 2 jam yang lalu • Tinggi'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('92%'),
            ),
          ],
        ),
      ),
    );
  }
}
