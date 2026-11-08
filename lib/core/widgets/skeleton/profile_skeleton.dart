import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton profil — meniru [ProfileHeader] + daftar menu, 5 baris.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, child: Text('U')),
                  const SizedBox(height: 12),
                  Text(
                    'Nama Pengguna',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _FakeMenuRow(),
            ),
        ],
      ),
    );
  }
}

class _FakeMenuRow extends StatelessWidget {
  const _FakeMenuRow();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 12),
            Expanded(child: Text('Menu Pengaturan')),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
