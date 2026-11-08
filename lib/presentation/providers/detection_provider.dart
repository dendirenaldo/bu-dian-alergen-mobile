import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/detection_entity.dart';
import '../../data/demo_detection_samples.dart';
import '../../data/models/detection_model.dart';
import '../../data/datasources/detection_remote_datasource.dart';
import '../../data/repositories/detection_repository_impl.dart';
import '../../core/constants/detection_models.dart';
import '../../services/connectivity_service.dart';

String _providerUuid() {
  final r = Random.secure();
  String h(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${h(8)}-${h(4)}-4${h(3)}-${['8', '9', 'a', 'b'][r.nextInt(4)]}${h(3)}-${h(12)}';
}

enum _LastAction { image, text }

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
  bool _isDemo = false;

  // --- SSE live progress state ---
  double? _progress;
  String? _currentStage;
  String? _stageMessage;
  int? _etaMs;
  String? _jobId;
  String? _idempotencyKey;
  String? _modelFallbackNotice;
  bool _ocrLowQuality = false;
  int? _retryAfterSec;

  _LastAction? _lastAction;
  String? _lastText;

  StreamSubscription<SseProgressEvent>? _sseSub;
  bool _resultSetFromPost = false;
  bool _cancelRequested = false;
  bool _disposed = false;

  File? get selectedImage => _selectedImage;
  DetectionEntity? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String get selectedModel => _selectedModel;
  int? get quotaRemaining => _quotaRemaining;
  int get quotaLimit => _quotaLimit;
  bool get isDemo => _isDemo;

  /// 0..1, null = indeterminate (fallback POST lama tanpa SSE).
  double? get progress => _progress;
  String? get currentStage => _currentStage;
  String? get stageMessage => _stageMessage;
  int? get etaMs => _etaMs;
  String? get jobId => _jobId;
  String? get idempotencyKey => _idempotencyKey;
  String? get modelFallbackNotice => _modelFallbackNotice;
  bool get ocrLowQuality => _ocrLowQuality;
  int? get retryAfterSec => _retryAfterSec;
  bool get hasActiveJob => _jobId != null && _isProcessing;

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
        if (_quotaRemaining != null) {
          _quotaRemaining = null;
          notifyListeners();
        }
      }
    } catch (_) {
    }
  }

  void _resetProgressState({double? progress = 0}) {
    _progress = progress;
    _currentStage = 'received';
    _stageMessage = 'Memulai deteksi…';
    _etaMs = null;
    _jobId = null;
    _modelFallbackNotice = null;
    _ocrLowQuality = false;
    _retryAfterSec = null;
    _resultSetFromPost = false;
    _cancelRequested = false;
  }

  Future<void> _cancelStream() async {
    try {
      await _sseSub?.cancel();
    } catch (_) {}
    _sseSub = null;
  }

  void _applySseEvent(SseProgressEvent ev) {
    if (_cancelRequested || _disposed) return;
    _currentStage = ev.stage;
    _stageMessage = ev.message.isEmpty ? _stageMessage : ev.message;
    _progress = (ev.progress.clamp(0, 100)) / 100.0;
    _etaMs = ev.etaMs;
    final data = ev.data;
    if (data != null) {
      final quality = data['ocrQuality'];
      if (quality is Map) {
        final low = quality['lowQuality'];
        if (low == true) _ocrLowQuality = true;
      }
      final fallback = data['fallbackNotice'];
      if (fallback is String && fallback.trim().isNotEmpty) {
        _modelFallbackNotice = fallback.trim();
      }
      final backend = data['backend'];
      if (backend is String &&
          backend.trim().isNotEmpty &&
          backend.trim().toLowerCase() != _selectedModel.toLowerCase() &&
          _modelFallbackNotice == null) {
        _modelFallbackNotice = 'Model ${_selectedModel.toUpperCase()} sibuk, dipakai ${backend.trim().toUpperCase()}';
      }
    }
    if (ev.isDone) {
      _progress = 1.0;
      final dataResult = ev.data?['result'];
      if (dataResult is Map && !_resultSetFromPost && _result == null) {
        try {
          final model = DetectionModel.fromJson(dataResult.cast<String, dynamic>());
          _result = model.toEntity();
          _checkFallbackFromResult();
        } catch (_) {
          // Hasil SSE tak valid: pertahankan hasil POST bila ada.
        }
      }
    }
    notifyListeners();
  }

  void _checkFallbackFromResult() {
    final r = _result;
    if (r == null) return;
    final actual = (r.modelName ?? '').toLowerCase().trim();
    if (actual.isNotEmpty && actual != _selectedModel.toLowerCase()) {
      _modelFallbackNotice ??= 'Model ${_selectedModel.toUpperCase()} sibuk, dipakai ${actual.toUpperCase()}';
    }
  }

  Future<void> _followStream(String uploadId) async {
    await _cancelStream();
    if (_cancelRequested || _disposed) return;
    try {
      final stream = _repository.watchJob(uploadId);
      final completer = Completer<void>();
      _sseSub = stream.listen(
        _applySseEvent,
        onError: (_) {
          // SSE gagal di tengah jalan: jangan rusak hasil POST (fallback lama).
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );
      // Batasi tunggu replay agar UI tidak menggantung (backend maks ~120 dtk).
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {},
      );
    } catch (_) {
      // Abaikan: hasil POST tetap berlaku (fallback lama).
    }
  }

  Future<void> detectAllergens({String? reuseIdempotencyKey}) async {
    if (_selectedImage == null || _isProcessing) return;

    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      _error = 'Tidak ada koneksi internet. Silakan coba lagi.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _error = null;
    _isDemo = false;
    _idempotencyKey = reuseIdempotencyKey?.trim().isNotEmpty == true
        ? reuseIdempotencyKey!.trim()
        : _providerUuid();
    _lastAction = _LastAction.image;
    _lastText = null;
    _result = null;
    _resetProgressState();
    _jobId = null;
    notifyListeners();

    try {
      final detailed = await _repository.detectAllergensDetailed(
        _selectedImage!,
        model: _selectedModel,
        idempotencyKey: _idempotencyKey,
      );

      if (detailed.jobId != null && detailed.jobId!.trim().isNotEmpty) {
        _jobId = detailed.jobId!.trim();
      }
      if (detailed.modelFallback != null && detailed.modelFallback!.trim().isNotEmpty) {
        _modelFallbackNotice = 'Model ${_selectedModel.toUpperCase()} sibuk, dipakai ${detailed.modelFallback!.trim().toUpperCase()}';
      }
      if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;

      if (detailed.result.isSuccess && detailed.result.data != null) {
        _result = detailed.result.data;
        _resultSetFromPost = true;
        _checkFallbackFromResult();
        _progress = 1.0;
        _currentStage = 'done';
        _stageMessage = 'Deteksi selesai';
        notifyListeners();
        // Replay SSE untuk melengkapi pesan tahap + ocrQuality bila ada jobId.
        if (_jobId != null) await _followStream(_jobId!);
        await refreshQuota();
      } else if (detailed.isPending && _jobId != null) {
        // POST 202: hasil menyusul via SSE.
        await _followStream(_jobId!);
        if (_result != null) {
          _checkFallbackFromResult();
          await refreshQuota();
        } else if (!_cancelRequested) {
          _error = detailed.result.error ?? 'Deteksi masih diproses. Coba lagi.';
          if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;
        }
      } else {
        _error = detailed.result.error;
        if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;
        if (detailed.result.statusCode == 429 && _retryAfterSec == null) {
          _retryAfterSec = _parseRetryAfterFromMessage(_error);
        }
        _progress = null;
        await refreshQuota();
      }
    } catch (e) {
      if (!_cancelRequested) {
        _error = e.toString().replaceFirst('Exception: ', '');
        _progress = null;
        await refreshQuota();
      }
    }

    if (!_cancelRequested) {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> detectFromText(String text, {String? reuseIdempotencyKey}) async {
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
    _isDemo = false;
    _idempotencyKey = reuseIdempotencyKey?.trim().isNotEmpty == true
        ? reuseIdempotencyKey!.trim()
        : _providerUuid();
    _lastAction = _LastAction.text;
    _lastText = query;
    _result = null;
    _resetProgressState();
    _jobId = null;
    notifyListeners();

    try {
      final detailed = await _repository.detectFromTextDetailed(
        query,
        model: _selectedModel,
        idempotencyKey: _idempotencyKey,
      );

      if (detailed.jobId != null && detailed.jobId!.trim().isNotEmpty) {
        _jobId = detailed.jobId!.trim();
      }
      if (detailed.modelFallback != null && detailed.modelFallback!.trim().isNotEmpty) {
        _modelFallbackNotice = 'Model ${_selectedModel.toUpperCase()} sibuk, dipakai ${detailed.modelFallback!.trim().toUpperCase()}';
      }
      if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;

      if (detailed.result.isSuccess && detailed.result.data != null) {
        _result = detailed.result.data;
        _resultSetFromPost = true;
        _checkFallbackFromResult();
        _progress = 1.0;
        _currentStage = 'done';
        _stageMessage = 'Deteksi selesai';
        notifyListeners();
        if (_jobId != null) await _followStream(_jobId!);
        await refreshQuota();
      } else if (detailed.isPending && _jobId != null) {
        await _followStream(_jobId!);
        if (_result != null) {
          _checkFallbackFromResult();
          await refreshQuota();
        } else if (!_cancelRequested) {
          _error = detailed.result.error ?? 'Deteksi masih diproses. Coba lagi.';
          if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;
        }
      } else {
        _error = detailed.result.error;
        if (detailed.retryAfterSec != null) _retryAfterSec = detailed.retryAfterSec;
        if (detailed.result.statusCode == 429 && _retryAfterSec == null) {
          _retryAfterSec = _parseRetryAfterFromMessage(_error);
        }
        _progress = null;
        await refreshQuota();
      }
    } catch (e) {
      if (!_cancelRequested) {
        _error = e.toString().replaceFirst('Exception: ', '');
        _progress = null;
        await refreshQuota();
      }
    }

    if (!_cancelRequested) {
      _isProcessing = false;
      notifyListeners();
    }
  }

  int? _parseRetryAfterFromMessage(String? message) {
    if (message == null) return null;
    final m = RegExp(r'(\d+)\s*(detik|s|second)', caseSensitive: false).firstMatch(message);
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  /// Batalkan job aktif: DELETE job + hentikan stream + reset + refresh kuota.
  Future<void> cancel() async {
    if (!_isProcessing && _jobId == null) return;
    _cancelRequested = true;
    final id = _jobId;
    await _cancelStream();
    if (id != null && id.isNotEmpty) {
      try {
        await _repository.cancelJob(id);
      } catch (_) {
        // Best-effort: refund diurus server; UI tetap reset.
      }
    }
    _isProcessing = false;
    _progress = null;
    _currentStage = 'cancelled';
    _stageMessage = 'Deteksi dibatalkan';
    _error = null;
    if (!_disposed) notifyListeners();
    await refreshQuota();
    _jobId = null;
    _cancelRequested = false;
    if (!_disposed) notifyListeners();
  }

  /// Ulangi aksi terakhir dengan Idempotency-Key yang SAMA (tidak dobel kuota).
  Future<void> retryLast() async {
    if (_isProcessing) return;
    final key = _idempotencyKey;
    if (_lastAction == null || key == null || key.isEmpty) return;
    if (_lastAction == _LastAction.text) {
      await detectFromText(_lastText ?? '', reuseIdempotencyKey: key);
    } else {
      await detectAllergens(reuseIdempotencyKey: key);
    }
  }

  void clearResult() {
    _selectedImage = null;
    _result = null;
    _error = null;
    _isDemo = false;
    _progress = null;
    _currentStage = null;
    _stageMessage = null;
    _etaMs = null;
    _jobId = null;
    _modelFallbackNotice = null;
    _ocrLowQuality = false;
    _retryAfterSec = null;
    notifyListeners();
  }

  /// Mengisi [_result] dari contoh lokal tanpa jaringan.
  ///
  /// Sengaja tidak memanggil repository, HTTP, maupun refreshQuota
  /// agar kuota tidak berkurang dan riwayat tidak tertulis.
  void detectDemo(int index) {
    if (_isProcessing) return;
    if (index < 0 || index >= demoDetectionSamples.length) return;
    _selectedImage = null;
    _result = demoDetectionSamples[index];
    _error = null;
    _isProcessing = false;
    _isDemo = true;
    _progress = null;
    _currentStage = null;
    _stageMessage = null;
    _etaMs = null;
    _jobId = null;
    _modelFallbackNotice = null;
    _ocrLowQuality = false;
    _retryAfterSec = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancelStream());
    _connectivityService.dispose();
    super.dispose();
  }
}

void unawaited(Future<void> future) {}
