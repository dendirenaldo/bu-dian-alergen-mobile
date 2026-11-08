import 'package:flutter/material.dart';
import '../../../config/routes.dart';
import '../../../core/utils/auth_token.dart';
import '../../../core/utils/display_names.dart';
import '../../../core/widgets/skeleton/history_detail_skeleton.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
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
    String? token;
    try {
      token = await getValidToken();
    } catch (_) {
      token = null;
    }
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isGuest = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _isAuthError = false;
    });
    final repo = DetectionRepositoryImpl();
    final result = await repo.getDetection(widget.detectionId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _item = result.data;
      } else {
        _error = result.error ?? 'Gagal memuat detail';
        _isAuthError = result.isUnauthenticated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: _loading
          ? const HistoryDetailSkeleton()
          : _isGuest || _isAuthError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masuk untuk melihat riwayat',
                          style: textTheme.titleLarge,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Coba Lagi'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Kembali'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _item == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _row('Hasil', formatResult(_item!.result)),
                        _row('Keyakinan',
                            formatConfidence(_item!.confidenceScore)),
                        _row('Metode', formatMethod(_item!.detectionMethod)),
                        _row('Tanggal', formatDateId(_item!.createdAt)),
                        if (_item!.ocrText != null &&
                            _item!.ocrText!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Teks OCR', style: textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(_item!.ocrText!,
                              style: textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 12),
                        Text('Alergen', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_item!.allergens == null ||
                            _item!.allergens!.isEmpty)
                          Text('Tidak ada alergen terdeteksi',
                              style: textTheme.bodyMedium)
                        else
                          ..._item!.allergens!.map((a) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: AllergenBadge(
                                    name: a.name,
                                    severity: a.severity,
                                    confidence: a.confidenceScore),
                              )),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.main),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(value, style: textTheme.titleMedium)
        ],
      ),
    );
  }
}
