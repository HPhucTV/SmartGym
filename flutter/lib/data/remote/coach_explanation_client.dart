import 'package:dio/dio.dart';
import '../../core/model/adaptation_models.dart';
import 'backend_config.dart';

abstract class CoachExplanationClient {
  Future<String?> explainDecision({
    required AdaptationKind kind,
    required String reasonVi,
    required String beforeValue,
    required String afterValue,
  });
}

class DioCoachExplanationClient implements CoachExplanationClient {
  final Dio _dio;
  final String? Function() _endpointProvider;

  DioCoachExplanationClient({
    Dio? dio,
    String? Function()? endpointProvider,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        _endpointProvider = endpointProvider ??
            (() => BackendConfig.baseUrl != null
                ? '${BackendConfig.baseUrl}/api/coach/decision-explanations'
                : null);

  @override
  Future<String?> explainDecision({
    required AdaptationKind kind,
    required String reasonVi,
    required String beforeValue,
    required String afterValue,
  }) async {
    final endpointUrl = _endpointProvider();
    if (endpointUrl == null) return null;

    try {
      final response = await _dio.post(
        endpointUrl,
        data: {
          'kind': kind.name.toUpperCase(), // Khớp với enum.name của Kotlin
          'reasonVi': reasonVi,
          'beforeValue': beforeValue,
          'afterValue': afterValue,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final explanation = data['explanation'] as String?;
        if (explanation != null && explanation.trim().isNotEmpty) {
          return explanation;
        }
      }
      return null;
    } catch (_) {
      return null; // Fallback locally on timeout or network error
    }
  }
}
