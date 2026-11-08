import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton daftar riwayat — meniru [HistoryItemCard], 5 baris.
class HistoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const HistoryListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _FakeHistoryItemCard(),
          );
        },
      ),
    );
  }
}

class _FakeHistoryItemCard extends StatelessWidget {
  const _FakeHistoryItemCard();

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
                  Text('Berbahaya Terdeteksi'),
                  SizedBox(height: 4),
                  Text('Gambar (OCR) • 3 alergen'),
                  SizedBox(height: 2),
                  Text('12 Jan 2026 14:30'),
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
