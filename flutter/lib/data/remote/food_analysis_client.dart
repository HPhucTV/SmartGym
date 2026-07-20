import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/model/food_photo_analysis_models.dart';
import '../../core/model/nutrition_models.dart';
import 'backend_config.dart';

abstract class FoodAnalysisClient {
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

  // Compatibility until the separate barcode cleanup.
  Future<ScanResult?> analyze(Uint8List imageBytes);
  Future<ScanResult?> scanBarcode(String barcode);
  Future<bool> registerBarcode(String barcode, ScanResult result);
}

class DioFoodAnalysisClient implements FoodAnalysisClient {
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

  @override
  Future<ScanResult?> scanBarcode(String barcode) async {
    final baseUrl = BackendConfig.baseUrl;
    if (baseUrl == null) return null;
    final url = '$baseUrl/api/scan-barcode?barcode=$barcode';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ScanResult.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(
          'Lỗi HTTP ${e.response?.statusCode}: ${e.response?.data}');
    } catch (e) {
      throw Exception('Phản hồi trống hoặc lỗi từ máy chủ: $e');
    }
  }

  @override
  Future<bool> registerBarcode(String barcode, ScanResult result) async {
    final baseUrl = BackendConfig.baseUrl;
    if (baseUrl == null) return false;
    final url = '$baseUrl/api/register-barcode';

    try {
      final response = await _dio.post(
        url,
        data: {
          'barcode': barcode,
          'dishName': result.dishName,
          'totalCalories': result.totalCalories,
          'proteinGrams': result.proteinGrams,
          'carbsGrams': result.carbsGrams,
          'fatGrams': result.fatGrams,
          'advice': result.advice,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ScanResult?> analyze(Uint8List imageBytes) async {
    final baseUrl = _baseUrlOrNull();
    if (baseUrl == null) return null;
    final endpointUrl = '$baseUrl/api/analyze-food';

    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'food.jpg',
          contentType: DioMediaType.parse('image/jpeg'),
        ),
      });

      final response = await _dio.post(endpointUrl, data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ScanResult.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String? message;
      if (errorData is Map<String, dynamic>) {
        message = errorData['error'] as String?;
      }
      throw Exception(message ?? 'Lỗi HTTP ${e.response?.statusCode}');
    } catch (e) {
      throw Exception('Phản hồi trống hoặc lỗi từ máy chủ: $e');
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
    for (final entry in value.entries.take(4)) {
      if (entry.key is String) {
        details[entry.key as String] = entry.value;
      }
    }
    return details;
  }

  String _encodedAnalysisId(String analysisId) {
    final trimmed = analysisId.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const FoodAnalysisFormatException(
        'analysisId must be a non-empty bounded identifier.',
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
