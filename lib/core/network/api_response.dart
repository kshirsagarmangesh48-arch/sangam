class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? filterStats;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
    this.filterStats,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      pagination: json['pagination'] != null ? json['pagination'] as Map<String, dynamic> : null,
      filterStats: json['filterStats'] != null ? json['filterStats'] as Map<String, dynamic> : null,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}
