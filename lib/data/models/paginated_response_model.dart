import '../../domain/entities/paginated_entity.dart';

class PaginatedResponseModel<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResponseModel({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  PaginatedEntity<T> toEntity() => PaginatedEntity(
    data: data,
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
  );
}
