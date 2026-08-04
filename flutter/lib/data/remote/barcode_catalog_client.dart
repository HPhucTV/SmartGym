import 'package:dio/dio.dart';

import '../../core/model/nutrition_models.dart';
import 'backend_config.dart';

abstract interface class BarcodeCatalogClient {
  Future<ScanResult?> lookup(String barcode);
}

final class BarcodeLookupException implements Exception {
  const BarcodeLookupException();

  @override
  String toString() => 'Không thể tra cứu mã vạch lúc này.';
}

final class DioBarcodeCatalogClient implements BarcodeCatalogClient {
  DioBarcodeCatalogClient({Dio? dio, String? Function()? endpointProvider})
    : _dio = dio ?? Dio(),
      _endpointProvider = endpointProvider ?? (() => BackendConfig.baseUrl);

  final Dio _dio;
  final String? Function() _endpointProvider;

  @override
  Future<ScanResult?> lookup(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(normalizedBarcode)) {
      throw const FormatException('Mã vạch phải gồm từ 8 đến 14 chữ số.');
    }

    final rawBaseUrl = _endpointProvider()?.trim();
    if (rawBaseUrl == null || rawBaseUrl.isEmpty) return null;
    final baseUrl = rawBaseUrl.endsWith('/')
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1)
        : rawBaseUrl;

    try {
      final response = await _dio.get<Object?>(
        '$baseUrl/api/barcodes/${Uri.encodeComponent(normalizedBarcode)}',
      );
      final payload = response.data;
      if (payload is! Map) throw const BarcodeLookupException();
      return ScanResult.fromJson(Map<String, dynamic>.from(payload));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw const BarcodeLookupException();
    } on BarcodeLookupException {
      rethrow;
    } on Object {
      throw const BarcodeLookupException();
    }
  }
}
