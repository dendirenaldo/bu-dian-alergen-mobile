import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/detection_entity.dart';
import '../../data/repositories/detection_repository_impl.dart';
import '../../core/constants/detection_models.dart';
import '../../services/connectivity_service.dart';

class DetectionProvider extends ChangeNotifier {
  final DetectionRepositoryImpl _repository = DetectionRepositoryImpl();
  final ImagePicker _picker = ImagePicker();
  final ConnectivityService _connectivityService = ConnectivityService();

  File? _selectedImage;
  DetectionEntity? _result;
  bool _isProcessing = false;
  String? _error;
  String _selectedModel = DetectionModels.def;
  int? _quotaRemaining;
  int _quotaLimit = 5;

  File? get selectedImage => _selectedImage;
  DetectionEntity? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String get selectedModel => _selectedModel;
  int? get quotaRemaining => _quotaRemaining;
  int get quotaLimit => _quotaLimit;

  void setModel(String m) {
    final v = DetectionModels.sanitize(m);
    if (v == _selectedModel) return;
    _selectedModel = v;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Gagal mengambil gambar';
      notifyListeners();
    }
  }

  Future<void> refreshQuota() async {
    try {
      final q = await _repository.fetchPublicQuota();
      if (q != null) {
        if (q['remaining'] is num) _quotaRemaining = (q['remaining'] as num).toInt();
        if (q['limit'] is num) _quotaLimit = (q['limit'] as num).toInt();
        notifyListeners();
      } else {
        // Login (unlimited) atau kuota tak tersedia.
        if (_quotaRemaining != null) {
          _quotaRemaining = null;
          notifyListeners();
        }
      }
    } catch (_) {
      // Jaringan gagal: pertahankan nilai lama, jangan null-kan.
    }
  }

  Future<void> detectAllergens() async {
    // Idempotency: abaikan ketukan ganda saat masih memproses.
    if (_selectedImage == null || _isProcessing) return;

    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      _error = 'Tidak ada koneksi internet. Silakan coba lagi.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    final result = await _repository.detectAllergens(_selectedImage!, model: _selectedModel);

    if (result.isSuccess) {
      _result = result.data;
      await refreshQuota();
    } else {
      _error = result.error;
      // Kuota habis juga mengubah sisa — sinkronkan tampilan.
      await refreshQuota();
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> detectFromText(String text) async {
    if (_isProcessing) return;
    final query = text.trim();
    if (query.isEmpty) {
      _error = 'Teks komposisi tidak boleh kosong';
      notifyListeners();
      return;
    }
    if (query.length > 5000) {
      _error = 'Teks maksimal 5000 karakter';
      notifyListeners();
      return;
    }
    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      _error = 'Tidak ada koneksi internet. Silakan coba lagi.';
      notifyListeners();
      return;
    }
    _isProcessing = true;
    _error = null;
    notifyListeners();
    final result = await _repository.detectFromText(query, model: _selectedModel);
    if (result.isSuccess) {
      _result = result.data;
      await refreshQuota();
    } else {
      _error = result.error;
      await refreshQuota();
    }
    _isProcessing = false;
    notifyListeners();
  }

  void clearResult() {
    _selectedImage = null;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
