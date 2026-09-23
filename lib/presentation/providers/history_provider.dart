import 'package:flutter/material.dart';
import '../../core/utils/auth_token.dart';
import '../../domain/entities/detection_entity.dart';
import '../../data/repositories/history_repository_impl.dart';

class HistoryItem {
  final String id;
  final String result;
  final String detectionMethod;
  final double confidenceScore;
  final DateTime createdAt;
  final List<String>? allergens;
  final String? imageUrl;

  HistoryItem({
    required this.id,
    required this.result,
    required this.detectionMethod,
    required this.confidenceScore,
    required this.createdAt,
    this.allergens,
    this.imageUrl,
  });

  factory HistoryItem.fromEntity(DetectionEntity entity) {
    return HistoryItem(
      id: entity.id.toString(),
      result: entity.result,
      detectionMethod: entity.detectionMethod,
      confidenceScore: entity.confidenceScore,
      createdAt: entity.createdAt,
      allergens: entity.allergens?.map((a) => a.name).toList(),
      imageUrl: entity.imageUrl,
    );
  }
}

class HistoryProvider extends ChangeNotifier {
  final HistoryRepositoryImpl _repository = HistoryRepositoryImpl();

  bool _isLoading = false;
  String? _error;
  List<HistoryItem> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _searchQuery;
  String? _sortBy;
  String? _sortOrder;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HistoryItem> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get searchQuery => _searchQuery;

  Future<void> loadHistory() async {
    // Tamu tidak punya riwayat: jangan tembak API (401), halaman
    // menampilkan ajakan masuk sendiri.
    if (await getValidToken() == null) {
      _items = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final result = await _repository.getHistory(
        page: 1,
        limit: 10,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result.isSuccess && result.data != null) {
        _items = result.data!.data.map((e) => HistoryItem.fromEntity(e)).toList();
        _hasMore = result.data!.hasNextPage;
        _currentPage = 2;
      } else {
        _error = result.error ?? 'Gagal memuat riwayat';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getHistory(
        page: _currentPage,
        limit: 10,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result.isSuccess && result.data != null) {
        final newItems = result.data!.data.map((e) => HistoryItem.fromEntity(e)).toList();
        _items.addAll(newItems);
        _hasMore = result.data!.hasNextPage;
        _currentPage++;
      } else {
        _error = result.error;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadHistory();
  }

  void setSearch(String? query) {
    _searchQuery = (query == null || query.trim().isEmpty) ? null : query.trim();
    notifyListeners();
    // Backend tidak mendukung search server-side → filter client-side,
    // tanpa request ulang agar tidak memicu 400.
  }

  /// Hasil tampil dengan filter client-side (nama hasil/metode).
  List<HistoryItem> get filteredItems {
    if (_searchQuery == null || _searchQuery!.isEmpty) return _items;
    final q = _searchQuery!.toLowerCase();
    return _items.where((e) {
      return e.result.toLowerCase().contains(q) ||
          e.detectionMethod.toLowerCase().contains(q) ||
          (e.allergens?.any((a) => a.toLowerCase().contains(q)) ?? false);
    }).toList();
  }

  void setSort(String? sortBy, String? sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
    loadHistory();
  }

  void clearHistory() {
    _items = [];
    _currentPage = 1;
    _hasMore = true;
    _sortBy = null;
    _sortOrder = null;
    _searchQuery = null;
    notifyListeners();
  }
}
