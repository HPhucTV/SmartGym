import 'package:dio/dio.dart';

import '../../core/model/food_photo_analysis_models.dart';
import 'backend_config.dart';

abstract class FoodAnalysisClient {
  Future<List<KnownFoodOption>> listKnownFoods();
  Future<FoodAnalysisReview> startPhotoAnalysis(PreparedUpload upload);
  Future<FoodAnalysisReview> addSecondaryPhoto(
    String analysisId,
    PreparedUpload upload,
  );
  Future<FoodAnalysisReady> confirmAnalysis(
    String analysisId,
    FoodAnalysisConfirmation confirmation,
  );
  void cancelPending();

}

class DioFoodAnalysisClient implements FoodAnalysisClient {
  static const Object _discardedDetail = Object();

  final Dio _dio;
  final String? Function() _endpointProvider;
  final Set<CancelToken> _photoCancelTokens = {};

  DioFoodAnalysisClient({
    Dio? dio,
    String? Function()? endpointProvider,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
              ),
            ),
        _endpointProvider = endpointProvider ?? (() => BackendConfig.baseUrl);

  @override
  Future<List<KnownFoodOption>> listKnownFoods() {
    return _photoRequest(
      (baseUrl, cancelToken) => _dio.get(
        '$baseUrl/api/food-analyses/foods',
        cancelToken: cancelToken,
      ),
      KnownFoodOption.listFromJson,
    );
  }

  @override
  Future<FoodAnalysisReview> startPhotoAnalysis(PreparedUpload upload) {
    return _photoRequest(
      (baseUrl, cancelToken) => _dio.post(
        '$baseUrl/api/food-analyses',
        data: FormData.fromMap({
          'primaryImage': _multipartFile(upload),
        }),
        cancelToken: cancelToken,
      ),
      FoodAnalysisReview.fromJson,
    );
  }

  @override
  Future<FoodAnalysisReview> addSecondaryPhoto(
    String analysisId,
    PreparedUpload upload,
  ) {
    final encodedId = _encodedAnalysisId(analysisId);
    return _photoRequest(
      (baseUrl, cancelToken) => _dio.post(
        '$baseUrl/api/food-analyses/$encodedId/images',
        data: FormData.fromMap({
          'secondaryImage': _multipartFile(upload),
        }),
        cancelToken: cancelToken,
      ),
      FoodAnalysisReview.fromJson,
    );
  }

  @override
  Future<FoodAnalysisReady> confirmAnalysis(
    String analysisId,
    FoodAnalysisConfirmation confirmation,
  ) {
    final encodedId = _encodedAnalysisId(analysisId);
    return _photoRequest(
      (baseUrl, cancelToken) => _dio.post(
        '$baseUrl/api/food-analyses/$encodedId/confirmations',
        data: confirmation.toJson(),
        options: Options(contentType: Headers.jsonContentType),
        cancelToken: cancelToken,
      ),
      FoodAnalysisReady.fromJson,
    );
  }

  @override
  void cancelPending() {
    final pending = List<CancelToken>.from(_photoCancelTokens);
    _photoCancelTokens.clear();
    for (final token in pending) {
      if (!token.isCancelled) {
        token.cancel('Food photo analysis cancelled.');
      }
    }
  }

  Future<T> _photoRequest<T>(
    Future<Response<dynamic>> Function(
      String baseUrl,
      CancelToken cancelToken,
    ) request,
    T Function(Object? json) parse,
  ) async {
    final baseUrl = _baseUrlOrNull();
    if (baseUrl == null) {
      throw FoodAnalysisApiException(
        code: 'ANALYSIS_UNAVAILABLE',
        message: 'Không thể phân tích ảnh lúc này.',
      );
    }

    final cancelToken = CancelToken();
    _photoCancelTokens.add(cancelToken);
    try {
      final response = await request(baseUrl, cancelToken);
      return parse(response.data);
    } on FoodAnalysisFormatException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        throw const FoodAnalysisCancelledException();
      }
      throw _photoApiException(error);
    } finally {
      _photoCancelTokens.remove(cancelToken);
    }
  }

  MultipartFile _multipartFile(PreparedUpload upload) {
    if (upload.bytes.isEmpty ||
        upload.filename.trim().isEmpty ||
        upload.mimeType.trim().isEmpty) {
      throw const FoodAnalysisFormatException(
        'Prepared upload is missing bytes, filename, or MIME type.',
      );
    }
    DioMediaType contentType;
    try {
      contentType = DioMediaType.parse(upload.mimeType);
    } on FormatException {
      throw const FoodAnalysisFormatException(
        'Prepared upload MIME type is invalid.',
      );
    }
    return MultipartFile.fromBytes(
      upload.bytes,
      filename: upload.filename,
      contentType: contentType,
    );
  }

  FoodAnalysisApiException _photoApiException(DioException exception) {
    final errorData = exception.response?.data;
    if (errorData is Map) {
      final nested = errorData['error'];
      if (nested is Map) {
        return FoodAnalysisApiException(
          code: _boundedErrorCode(nested['code']),
          message: _boundedErrorMessage(nested['message']),
          details: _safeDetails(nested['details']),
        );
      }
    }
    return FoodAnalysisApiException(
      code: 'ANALYSIS_UNAVAILABLE',
      message: 'Không thể phân tích ảnh lúc này.',
    );
  }

  String _boundedErrorCode(Object? value) {
    if (value is String &&
        value.isNotEmpty &&
        value.length <= 64 &&
        RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(value)) {
      return value;
    }
    return 'ANALYSIS_UNAVAILABLE';
  }

  String _boundedErrorMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty && value.length <= 500) {
      return value;
    }
    return 'Không thể phân tích ảnh lúc này.';
  }

  Map<String, Object?> _safeDetails(Object? value) {
    if (value is! Map) return const {};
    final details = <String, Object?>{};
    for (final entry in value.entries) {
      if (details.length == 4) break;
      if (entry.key is! String) continue;
      final key = (entry.key as String).trim();
      if (key.isEmpty || key.length > 64) continue;
      final sanitized = _sanitizeDetail(entry.value, depth: 0);
      if (identical(sanitized, _discardedDetail)) continue;
      details[key] = sanitized;
    }
    return Map.unmodifiable(details);
  }

  Object? _sanitizeDetail(Object? value, {required int depth}) {
    if (value == null || value is bool) return value;
    if (value is String) {
      return value.length <= 120 ? value : value.substring(0, 120);
    }
    if (value is num) {
      return value.isFinite ? value : _discardedDetail;
    }
    if (depth >= 2) return _discardedDetail;
    if (value is Map) {
      final sanitized = <String, Object?>{};
      for (final entry in value.entries) {
        if (sanitized.length == 4) break;
        if (entry.key is! String) continue;
        final key = (entry.key as String).trim();
        if (key.isEmpty || key.length > 64) continue;
        final nested = _sanitizeDetail(entry.value, depth: depth + 1);
        if (identical(nested, _discardedDetail)) continue;
        sanitized[key] = nested;
      }
      return Map.unmodifiable(sanitized);
    }
    if (value is List) {
      final sanitized = <Object?>[];
      for (final item in value) {
        if (sanitized.length == 4) break;
        final nested = _sanitizeDetail(item, depth: depth + 1);
        if (!identical(nested, _discardedDetail)) {
          sanitized.add(nested);
        }
      }
      return List.unmodifiable(sanitized);
    }
    return _discardedDetail;
  }

  String _encodedAnalysisId(String analysisId) {
    final trimmed = analysisId.trim();
    if (trimmed.isEmpty) {
      throw const FoodAnalysisFormatException(
        'analysisId must be a non-empty identifier.',
      );
    }
    return Uri.encodeComponent(trimmed);
  }

  String? _baseUrlOrNull() {
    final raw = _endpointProvider()?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}
