import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/display_names.dart';
import '../../providers/detection_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/detection/image_preview_widget.dart';
import '../../widgets/detection/processing_indicator.dart';
import '../detection/detection_result_page.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  bool _isTextMode = false;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionProvider>().refreshQuota();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _retryLastAction() async {
    final provider = context.read<DetectionProvider>();
    if (_isTextMode) {
      await provider.detectFromText(_textCtrl.text);
    } else {
      await provider.detectAllergens();
    }
    if (!mounted) return;
    if (provider.result != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DetectionResultPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isLoggedIn = context.watch<AuthProvider>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Alergen'),
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unggah gambar label makanan untuk mendeteksi alergen',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 8),
                  Text(
                    provider.quotaRemaining != null
                        ? 'Tanpa masuk, deteksi hanya bisa ${provider.quotaLimit}x per jam (sisa ${provider.quotaRemaining}x).'
                        : 'Tanpa masuk, deteksi hanya bisa 5x per jam.',
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Model: ', style: textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: provider.selectedModel,
                      items: [
                        DropdownMenuItem(
                            value: 'bert',
                            child: Text(formatModelName('bert'))),
                        DropdownMenuItem(
                            value: 'bilstm',
                            child: Text(formatModelName('bilstm'))),
                        DropdownMenuItem(
                            value: 'ensemble',
                            child: Text(formatModelName('ensemble'))),
                      ],
                      onChanged: (v) {
                        if (v != null) provider.setModel(v);
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => _isTextMode = !_isTextMode),
                      child:
                          Text(_isTextMode ? 'Mode Gambar' : 'Mode Teks'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isTextMode) ...[
                  TextField(
                    controller: _textCtrl,
                    maxLines: 5,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan teks komposisi bahan...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: provider.isProcessing
                          ? null
                          : () async {
                              await provider.detectFromText(_textCtrl.text);
                              if (context.mounted &&
                                  provider.result != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DetectionResultPage(),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(LucideIcons.search),
                      label: const Text('Deteksi Teks'),
                    ),
                  ),
                ] else if (provider.selectedImage != null) ...[
                  ImagePreviewWidget(
                    image: provider.selectedImage!,
                    onRemove: () => provider.clearResult(),
                  ),
                  const SizedBox(height: 24),
                  if (provider.isProcessing)
                    const ProcessingIndicator()
                  else
                    Semantics(
                      button: true,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await provider.detectAllergens();
                            if (context.mounted &&
                                provider.result != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DetectionResultPage(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.search),
                          label: const Text('Deteksi Alergen'),
                        ),
                      ),
                    ),
                ] else
                  _buildUploadArea(context, provider),
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: provider.isProcessing
                                ? null
                                : _retryLastAction,
                            icon: const Icon(LucideIcons.refreshCw,
                                size: 16),
                            label: const Text('Coba Lagi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context, DetectionProvider provider) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Area upload gambar',
      hint: 'Ketuk dua kali untuk memilih gambar dari kamera atau galeri',
      button: true,
      child: GestureDetector(
        onTap: () => _showImagePickerSheet(context, provider),
        child: Card(
          margin: EdgeInsets.zero,
          color: colorScheme.primary.withValues(alpha: 0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ketuk untuk unggah gambar',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamera atau Galeri',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet(
      BuildContext context, DetectionProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Gambar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(LucideIcons.camera,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.image,
                    color: Theme.of(context).colorScheme.secondary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
