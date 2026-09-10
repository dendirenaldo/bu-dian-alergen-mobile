import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/detection_entity.dart';
import '../../data/repositories/detection_repository_impl.dart';

class DetectionProvider extends ChangeNotifier {
  final DetectionRepositoryImpl _repository = DetectionRepositoryImpl();
  final ImagePicker _picker = ImagePicker();

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
    if (_selectedImage == null) return;

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

  void clearResult() {
    _selectedImage = null;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
