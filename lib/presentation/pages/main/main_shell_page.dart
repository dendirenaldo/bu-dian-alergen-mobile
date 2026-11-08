import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/bottom_nav_provider.dart';
import '../home/home_page.dart';
import '../detection/detection_page.dart';
import '../history/history_page.dart';
import '../profile/profile_page.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<BottomNavProvider, int>(
      selector: (_, nav) => nav.currentIndex,
      builder: (context, currentIndex, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar Aplikasi'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      SystemNavigator.pop();
                    },
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
          child: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: IndexedStack(
                key: ValueKey<int>(currentIndex),
                index: currentIndex,
                children: const [
                  HomePage(key: PageStorageKey('home')),
                  DetectionPage(key: PageStorageKey('detection')),
                  HistoryPage(key: PageStorageKey('history')),
                  ProfilePage(key: PageStorageKey('profile')),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                context.read<BottomNavProvider>().setIndex(index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(LucideIcons.home),
                  selectedIcon: Icon(LucideIcons.home, color: Color(0xFF2563EB)),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.scanLine),
                  selectedIcon:
                      Icon(LucideIcons.scanLine, color: Color(0xFF2563EB)),
                  label: 'Deteksi',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.clock),
                  selectedIcon: Icon(LucideIcons.clock, color: Color(0xFF2563EB)),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.user),
                  selectedIcon: Icon(LucideIcons.user, color: Color(0xFF2563EB)),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
