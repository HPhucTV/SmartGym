import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../remote/backend_config.dart';
import '../remote/coach_explanation_client.dart';
import '../remote/coach_review_client.dart';
import '../remote/food_analysis_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));
});

final coachExplanationClientProvider = Provider<CoachExplanationClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioCoachExplanationClient(dio: dio);
});

final coachReviewClientProvider = Provider<CoachReviewClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioCoachReviewClient(dio: dio);
});

final foodAnalysisClientProvider = Provider<FoodAnalysisClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioFoodAnalysisClient(
    dio: dio,
    endpointProvider: () => BackendConfig.baseUrl,
  );
});
