import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/profile/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tampilan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return SettingsTile(
                  icon: LucideIcons.moon,
                  title: 'Mode Gelap',
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) {
                      HapticFeedback.mediumImpact();
                      themeProvider.toggleTheme();
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SettingsTile(
              icon: LucideIcons.trash2,
              title: 'Hapus Cache',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Cache'),
                    content: const Text(
                        'Apakah Anda yakin ingin menghapus cache?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Cache berhasil dihapus'),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        },
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tentang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SettingsTile(
              icon: LucideIcons.info,
              title: 'Versi Aplikasi',
              subtitle: '1.0.0',
            ),
            const SettingsTile(
              icon: LucideIcons.fileText,
              title: 'Ketentuan Layanan',
            ),
            const SettingsTile(
              icon: LucideIcons.shield,
              title: 'Kebijakan Privasi',
            ),
          ],
        ),
      ),
    );
  }
}
