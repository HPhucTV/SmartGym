import '../../core/model/nutrition_models.dart';

abstract interface class BarcodeRepository {
  Future<ScanResult?> lookup(String barcode);

  Future<void> saveOverride(String barcode, ScanResult result);
}
