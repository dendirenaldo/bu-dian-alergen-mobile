import 'package:flutter/material.dart';
import '../../../config/routes.dart';
import '../../../core/utils/auth_token.dart';
import '../../../data/repositories/detection_repository_impl.dart';
import '../../../domain/entities/detection_entity.dart';
import '../../widgets/detection/allergen_badge.dart';

class HistoryDetailPage extends StatefulWidget {
  final int detectionId;
  const HistoryDetailPage({super.key, required this.detectionId});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  DetectionEntity? _item;
  String? _error;
  bool _loading = true;
  bool _isGuest = false;
  bool _isAuthError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.detectionId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Data tidak ditemukan';
      });
      return;
    }
    // Riwayat hanya untuk akun.
    if (await getValidToken() == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isGuest = true;
      });
      return;
    }
    final repo = DetectionRepositoryImpl();
    final result = await repo.getDetection(widget.detectionId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _item = result.data;
      } else {
        _error = result.error ?? 'Gagal memuat detail';
        _isAuthError = (_error ?? '').contains('401');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isGuest || _isAuthError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Masuk untuk melihat riwayat',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
                          },
                          child: const Text('Masuk / Daftar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                )
              : _item == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _row('Hasil', _item!.result == 'safe' ? 'Aman' : 'Berbahaya'),
                        _row('Keyakinan', '${(_item!.confidenceScore * 100).toInt()}%'),
                        _row('Metode', _item!.detectionMethod == 'image_ocr' ? 'Gambar (OCR)' : 'Teks'),
                        _row('Tanggal', _item!.createdAt.toString()),
                        if (_item!.ocrText != null && _item!.ocrText!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Teks OCR', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(_item!.ocrText!),
                        ],
                        const SizedBox(height: 12),
                        const Text('Alergen', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (_item!.allergens == null || _item!.allergens!.isEmpty)
                          const Text('Tidak ada alergen terdeteksi')
                        else
                          ..._item!.allergens!.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AllergenBadge(name: a.name, severity: a.severity, confidence: a.confidenceScore),
                              )),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.main),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}
