import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/detection_entity.dart';
import '../../data/repositories/detection_repository_impl.dart';
import '../../services/connectivity_service.dart';

class DetectionProvider extends ChangeNotifier {
  final DetectionRepositoryImpl _repository = DetectionRepositoryImpl();
  final ImagePicker _picker = ImagePicker();
  final ConnectivityService _connectivityService = ConnectivityService();

  File? _selectedImage;
  DetectionEntity? _result;
  bool _isProcessing = false;
  String? _error;

  File? get selectedImage => _selectedImage;
  DetectionEntity? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

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

    final result = await _repository.detectAllergens(_selectedImage!);

    if (result.isSuccess) {
      _result = result.data;
    } else {
      _error = result.error;
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
    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      _error = 'Tidak ada koneksi internet. Silakan coba lagi.';
      notifyListeners();
      return;
    }
    _isProcessing = true;
    _error = null;
    notifyListeners();
    final result = await _repository.detectFromText(query);
    if (result.isSuccess) {
      _result = result.data;
    } else {
      _error = result.error;
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
