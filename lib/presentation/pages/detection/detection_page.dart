import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 8),
                  Text(
                    provider.quotaRemaining != null
                        ? 'Tanpa masuk, deteksi hanya bisa ${provider.quotaLimit}x per jam (sisa ${provider.quotaRemaining}x).'
                        : 'Tanpa masuk, deteksi hanya bisa 5x per jam.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Model: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: provider.selectedModel,
                      items: const [
                        DropdownMenuItem(value: 'bert', child: Text('BERT')),
                        DropdownMenuItem(value: 'bilstm', child: Text('BiLSTM')),
                        DropdownMenuItem(value: 'ensemble', child: Text('Ensemble')),
                      ],
                      onChanged: (v) {
                        if (v != null) provider.setModel(v);
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _isTextMode = !_isTextMode),
                      child: Text(_isTextMode ? 'Mode Gambar' : 'Mode Teks'),
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
                              if (context.mounted && provider.result != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DetectionResultPage(),
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
                            if (context.mounted && provider.result != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DetectionResultPage(),
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
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
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
    return Semantics(
      label: 'Area upload gambar',
      hint: 'Ketuk dua kali untuk memilih gambar dari kamera atau galeri',
      button: true,
      child: GestureDetector(
        onTap: () => _showImagePickerSheet(context, provider),
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ketuk untuk unggah gambar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kamera atau Galeri',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet(BuildContext context, DetectionProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Gambar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(LucideIcons.camera, color: Theme.of(context).colorScheme.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: Theme.of(context).colorScheme.secondary),
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
