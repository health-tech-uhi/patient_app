/// Mirrors backend paginated JSON: `{ items, metadata }`.
class PaginatedResult<T> {
  final List<T> items;
  final PaginatedMetadata? metadata;

  const PaginatedResult({required this.items, this.metadata});

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> map) itemParser,
  ) {
    final raw = json['items'];
    final list = <T>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(itemParser(e));
        }
      }
    }
    final meta = json['metadata'];
    return PaginatedResult(
      items: list,
      metadata: meta is Map<String, dynamic>
          ? PaginatedMetadata.fromJson(meta)
          : null,
    );
  }
}

class PaginatedMetadata {
  final int totalCount;
  final int page;
  final int perPage;
  final int totalPages;

  const PaginatedMetadata({
    required this.totalCount,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginatedMetadata.fromJson(Map<String, dynamic> json) {
    return PaginatedMetadata(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}
