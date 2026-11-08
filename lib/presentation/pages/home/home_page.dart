import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/tour/guided_tour_service.dart';
import '../../../core/tour/tour_keys.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/quick_action_card.dart';
import '../../widgets/home/recent_detection_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GuidedTourService.maybeShowAfterOnboarding(context);
    });
  }

  Future<void> _openTour() async {
    HapticFeedback.lightImpact();
    await GuidedTourService.showTour(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          Semantics(
            button: true,
            label: 'Buka panduan penggunaan',
            hint: 'Ketuk dua kali untuk melihat tur panduan',
            child: IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Panduan',
              onPressed: _openTour,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(key: TourKeys.homeHeaderKey),
              const SizedBox(height: 24),
              Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      key: TourKeys.scanActionKey,
                      icon: LucideIcons.scanLine,
                      title: 'Scan Label',
                      subtitle: 'Deteksi alergen',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        context.read<BottomNavProvider>().setIndex(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      key: TourKeys.historyActionKey,
                      icon: LucideIcons.clock,
                      title: 'Riwayat',
                      subtitle: 'Lihat scan sebelumnya',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {
                        context.read<BottomNavProvider>().setIndex(2);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deteksi Terakhir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<BottomNavProvider>().setIndex(2);
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const RecentDetectionCard(
                title: 'Susu Bubuk Terdeteksi',
                subtitle: 'Scan 2 jam yang lalu',
                severity: 'high',
                confidence: 0.92,
              ),
              const SizedBox(height: 8),
              const RecentDetectionCard(
                title: 'Tidak Ditemukan Alergen',
                subtitle: 'Scan kemarin',
                severity: 'safe',
                confidence: 0.98,
              ),
              const SizedBox(height: 8),
              const RecentDetectionCard(
                title: 'Lecithin Kedelai Terdeteksi',
                subtitle: 'Scan 2 hari yang lalu',
                severity: 'medium',
                confidence: 0.85,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
