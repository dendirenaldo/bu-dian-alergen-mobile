import '../entities/detection_entity.dart';
import '../entities/paginated_entity.dart';
import 'result.dart';

abstract class HistoryRepository {
  Future<Result<PaginatedEntity<DetectionEntity>>> getHistory({
    int page = 1,
    int limit = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
  });
}
