import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/nutrition_models.dart';
import 'package:gym_app/data/local/database.dart';
import 'package:gym_app/data/remote/barcode_catalog_client.dart';
import 'package:gym_app/data/repositories/drift_barcode_repository.dart';

void main() {
  late GymDatabase database;
  late _FakeBarcodeClient remote;
  late DriftBarcodeRepository repository;

  setUp(() {
    database = GymDatabase(NativeDatabase.memory());
    remote = _FakeBarcodeClient();
    repository = DriftBarcodeRepository(
      database: database,
      remote: remote,
      nowEpochMillis: () => 123456789,
    );
  });

  tearDown(() => database.close());

  test('returns a local override without calling the network', () async {
    await repository.saveOverride('8930000000001', _result('Đã sửa'));

    final result = await repository.lookup('8930000000001');

    expect(result?.dishName, 'Đã sửa');
    expect(result?.needsUserConfirmation, isFalse);
    expect(remote.lookupCount, 0);
  });

  test('falls back to the read-only catalog when no override exists', () async {
    remote.result = _result('Từ máy chủ');

    final result = await repository.lookup('8930000000001');

    expect(result?.dishName, 'Từ máy chủ');
    expect(remote.lookupCount, 1);
    expect(
      await database.personalizationDao.barcodeOverrideNow('8930000000001'),
      isNull,
    );
  });
}

ScanResult _result(String name) => ScanResult(
  dishName: name,
  totalCalories: 120,
  proteinGrams: 4,
  carbsGrams: 20,
  fatGrams: 2,
  fitnessScore: 5,
  advice: 'Dữ liệu thử nghiệm.',
  constituents: const [],
);

final class _FakeBarcodeClient implements BarcodeCatalogClient {
  ScanResult? result;
  int lookupCount = 0;

  @override
  Future<ScanResult?> lookup(String barcode) async {
    lookupCount += 1;
    return result;
  }
}
