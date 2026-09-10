import '../../domain/entities/detection_entity.dart';
import '../../domain/entities/paginated_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/result.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _dataSource;

  HistoryRepositoryImpl({HistoryRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? HistoryRemoteDataSource();

  @override
  Future<Result<PaginatedEntity<DetectionEntity>>> getHistory({
    int page = 1,
    int limit = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _dataSource.getHistory(
        page: page,
        limit: limit,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return Result.success(
        PaginatedEntity(
          data: response.data.map((e) => e.toEntity()).toList(),
          page: response.page,
          limit: response.limit,
          total: response.total,
          totalPages: response.totalPages,
        ),
      );
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
