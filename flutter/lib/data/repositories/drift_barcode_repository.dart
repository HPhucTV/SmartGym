import 'package:drift/drift.dart';

import '../../core/model/nutrition_models.dart';
import '../local/database.dart';
import '../remote/barcode_catalog_client.dart';
import 'barcode_repository.dart';

final class DriftBarcodeRepository implements BarcodeRepository {
  DriftBarcodeRepository({
    required GymDatabase database,
    required BarcodeCatalogClient remote,
    int Function()? nowEpochMillis,
  }) : _database = database,
       _remote = remote,
       _nowEpochMillis =
           nowEpochMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final GymDatabase _database;
  final BarcodeCatalogClient _remote;
  final int Function() _nowEpochMillis;

  @override
  Future<ScanResult?> lookup(String barcode) async {
    final normalizedBarcode = _validatedBarcode(barcode);
    final local = await _database.personalizationDao.barcodeOverrideNow(
      normalizedBarcode,
    );
    if (local != null) return _toDomain(local);
    return _remote.lookup(normalizedBarcode);
  }

  @override
  Future<void> saveOverride(String barcode, ScanResult result) {
    final normalizedBarcode = _validatedBarcode(barcode);
    return _database.personalizationDao.upsertBarcodeOverride(
      BarcodeOverridesCompanion.insert(
        barcode: normalizedBarcode,
        dishName: result.dishName.trim(),
        totalCalories: result.totalCalories,
        proteinGrams: result.proteinGrams,
        carbsGrams: result.carbsGrams,
        fatGrams: result.fatGrams,
        advice: Value(result.advice),
        updatedAtEpochMillis: _nowEpochMillis(),
      ),
    );
  }

  String _validatedBarcode(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(normalized)) {
      throw const FormatException('Mã vạch phải gồm từ 8 đến 14 chữ số.');
    }
    return normalized;
  }

  ScanResult _toDomain(BarcodeOverrideData value) {
    return ScanResult(
      dishName: value.dishName,
      totalCalories: value.totalCalories,
      proteinGrams: value.proteinGrams,
      carbsGrams: value.carbsGrams,
      fatGrams: value.fatGrams,
      fitnessScore: 5,
      advice: value.advice,
      constituents: const [],
      calculationProcess: 'Dữ liệu mã vạch đã xác nhận trên thiết bị.',
      confidence: 1,
      needsUserConfirmation: false,
    );
  }
}
