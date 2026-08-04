import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../remote/backend_config.dart';
import '../remote/coach_explanation_client.dart';
import '../remote/coach_review_client.dart';
import '../remote/food_analysis_client.dart';
import '../remote/barcode_catalog_client.dart';
import '../repositories/barcode_repository.dart';
import '../repositories/drift_barcode_repository.dart';
import 'data_providers.dart';
import '../../core/model/food_photo_analysis_models.dart';

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

final barcodeCatalogClientProvider = Provider<BarcodeCatalogClient>((ref) {
  return DioBarcodeCatalogClient(
    dio: ref.watch(dioProvider),
    endpointProvider: () => BackendConfig.baseUrl,
  );
});

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  return DriftBarcodeRepository(
    database: ref.watch(gymDatabaseProvider),
    remote: ref.watch(barcodeCatalogClientProvider),
  );
});

final knownFoodCatalogProvider = FutureProvider<List<KnownFoodOption>>((ref) {
  return ref.watch(foodAnalysisClientProvider).listKnownFoods();
});
