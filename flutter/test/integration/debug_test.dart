import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/core/catalog/asset_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('debug initialization', () async {
    print('1. Setting mock shared preferences...');
    SharedPreferences.setMockInitialValues({});
    print('2. Getting shared preferences...');
    await SharedPreferences.getInstance();
    print('3. Initializing asset catalog...');
    final catalogRepo = AssetCatalogRepository(
      assetReader: (path) => rootBundle.loadString(path),
    );
    print('4. Awaiting catalogRepo.init()...');
    await catalogRepo.init();
    print('5. Finished catalogRepo.init().');
  });
}
