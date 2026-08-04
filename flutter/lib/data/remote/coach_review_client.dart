import 'package:dio/dio.dart';
import 'backend_config.dart';

class CoachReviewRequest {
  final String goalVi;
  final String levelVi;
  final String sessionTitle;
  final bool completedToday;
  final int caloriesEaten;
  final int calorieLimit;
  final int proteinEaten;
  final int carbsEaten;
  final int fatEaten;
  final bool sweatActive;
  final String sweatExerciseName;
  final int sweatExtraSets;

  const CoachReviewRequest({
    required this.goalVi,
    required this.levelVi,
    required this.sessionTitle,
    required this.completedToday,
    required this.caloriesEaten,
    required this.calorieLimit,
    required this.proteinEaten,
    required this.carbsEaten,
    required this.fatEaten,
    required this.sweatActive,
    required this.sweatExerciseName,
    required this.sweatExtraSets,
  });
}

abstract class CoachReviewClient {
  Future<String?> reviewToday(CoachReviewRequest request);
}

class DioCoachReviewClient implements CoachReviewClient {
  final Dio _dio;
  final String? Function() _endpointProvider;

  DioCoachReviewClient({
    Dio? dio,
    String? Function()? endpointProvider,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _endpointProvider = endpointProvider ??
            (() => BackendConfig.baseUrl != null
                ? '${BackendConfig.baseUrl}/api/coach/review'
                : null);

  @override
  Future<String?> reviewToday(CoachReviewRequest request) async {
    final endpoint = _endpointProvider();
    if (endpoint == null) return null;

    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'goal': request.goalVi,
          'level': request.levelVi,
          'sessionTitle': request.sessionTitle,
          'completedToday': request.completedToday,
          'caloriesEaten': request.caloriesEaten,
          'calorieLimit': request.calorieLimit,
          'proteinEaten': request.proteinEaten,
          'carbsEaten': request.carbsEaten,
          'fatEaten': request.fatEaten,
          'sweatActive': request.sweatActive,
          'sweatExerciseName': request.sweatExerciseName,
          'sweatExtraSets': request.sweatExtraSets,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final review = data['review'] as String?;
        if (review != null && review.trim().isNotEmpty) {
          return review;
        }
      }
      return null;
    } catch (_) {
      return null; // Fallback locally on timeout or network error
    }
  }
}
