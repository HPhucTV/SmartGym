import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
// import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/local/database.dart';
import 'package:gym_app/main.dart' as app;

void main() {
  // IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late GymDatabase database;

  setUp(() async {
    print('ONBOARDING_TEST: setUp starting...');
    SharedPreferences.setMockInitialValues({});
    database = GymDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    debugMockEpochDay = DateTime.utc(2026, 7, 20).millisecondsSinceEpoch ~/
        (24 * 60 * 60 * 1000);
    print('ONBOARDING_TEST: setUp finished.');
  });

  tearDown(() async {
    print('ONBOARDING_TEST: tearDown starting, closing database...');
    await database.close();
    print('ONBOARDING_TEST: database closed in tearDown.');
    debugMockEpochDay = null;
    print('ONBOARDING_TEST: tearDown finished.');
  });

  Future<String> testAssetReader(String path) async {
    print('TEST_READER: Reading path: $path');
    var file = File(path);
    if (file.existsSync()) {
      print('TEST_READER: Found at path: $path');
      return file.readAsStringSync();
    }
    file = File('flutter/$path');
    if (file.existsSync()) {
      print('TEST_READER: Found at flutter/$path');
      return file.readAsStringSync();
    }
    print('TEST_READER: Not found anywhere!');
    throw Exception(
        'Test asset not found: $path (current directory: ${Directory.current.path})');
  }

  testWidgets('Onboarding and Goal Creation Integration Test',
      (WidgetTester tester) async {
    // Set viewport size so all list options are visible without scrolling
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Launch the app with in-memory database override
    print('ONBOARDING_TEST: Calling app.main...');
    await app.main(
      overrides: [
        gymDatabaseProvider.overrideWithValue(database),
      ],
      assetReader: testAssetReader,
    );
    print('ONBOARDING_TEST: Finished app.main.');

    // Wait for the async initialization in app.main (SharedPreferences, Asset Catalog etc.)
    print('ONBOARDING_TEST: Initial pump...');
    await tester.pump();
    print(
        'ONBOARDING_TEST: Initial pump finished. Waiting for CircularProgressIndicator...');
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    print('ONBOARDING_TEST: CircularProgressIndicator cleared.');

    // Verify Onboarding Screen is shown (we should see "Bước 1/8")
    expect(find.textContaining('Bước 1/8'), findsOneWidget);
    expect(find.text('Giới tính'), findsOneWidget);

    // Select Gender: Nam
    print('ONBOARDING_TEST: Tapping Nam...');
    await tester.tap(find.text('Nam'));
    print('ONBOARDING_TEST: Pump after Nam...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Nam selected.');

    // Select Body Type: Ectomorph
    print('ONBOARDING_TEST: Tapping Ectomorph...');
    await tester.tap(find.text('Ectomorph'));
    print('ONBOARDING_TEST: Pump after Ectomorph...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Ectomorph selected.');

    // Tap "Tiếp tục"
    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 1)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 1)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 1 finished.');

    // Step 2/8: Goal
    expect(find.textContaining('Bước 2/8'), findsOneWidget);
    // Tap "Tăng cơ"
    print('ONBOARDING_TEST: Tapping Tăng cơ...');
    await tester.tap(find.text('Tăng cơ'));
    print('ONBOARDING_TEST: Pump after Tăng cơ...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Tăng cơ selected.');

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 2)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 2)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 2 finished.');

    // Step 3/8: Level
    expect(find.textContaining('Bước 3/8'), findsOneWidget);
    // Tap "Trung cấp"
    print('ONBOARDING_TEST: Tapping Trung cấp...');
    await tester.tap(find.text('Trung cấp'));
    print('ONBOARDING_TEST: Pump after Trung cấp...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Trung cấp selected.');

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 3)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 3)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 3 finished.');

    // Step 4/8: Equipment
    expect(find.textContaining('Bước 4/8'), findsOneWidget);
    // Tap "Phòng gym đầy đủ"
    print('ONBOARDING_TEST: Tapping Phòng gym đầy đủ...');
    await tester.tap(find.text('Phòng gym đầy đủ'));
    print('ONBOARDING_TEST: Pump after Phòng gym đầy đủ...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Phòng gym đầy đủ selected.');

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 4)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 4)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 4 finished.');

    // Step 5/8: Training Days
    expect(find.textContaining('Bước 5/8'), findsOneWidget);
    // Select Thứ Hai, Thứ Tư, Thứ Sáu
    print('ONBOARDING_TEST: Tapping Thứ Hai...');
    await tester.tap(find.text('Thứ Hai'));
    print('ONBOARDING_TEST: Pump after Thứ Hai...');
    await tester.pumpAndSettle();

    print('ONBOARDING_TEST: Tapping Thứ Tư...');
    await tester.tap(find.text('Thứ Tư'));
    print('ONBOARDING_TEST: Pump after Thứ Tư...');
    await tester.pumpAndSettle();

    print('ONBOARDING_TEST: Tapping Thứ Sáu...');
    await tester.tap(find.text('Thứ Sáu'));
    print('ONBOARDING_TEST: Pump after Thứ Sáu...');
    await tester.pumpAndSettle();

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 5)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 5)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 5 finished.');

    // Step 6/8: Duration
    expect(find.textContaining('Bước 6/8'), findsOneWidget);
    // Tap "Tối đa 60 phút"
    print('ONBOARDING_TEST: Tapping Tối đa 60 phút...');
    await tester.tap(find.text('Tối đa 60 phút'));
    print('ONBOARDING_TEST: Pump after Tối đa 60 phút...');
    await tester.pumpAndSettle();

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 6)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 6)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 6 finished.');

    // Step 7/8: Rest behavior
    expect(find.textContaining('Bước 7/8'), findsOneWidget);
    // Tap "Nghỉ hoàn toàn"
    print('ONBOARDING_TEST: Tapping Nghỉ hoàn toàn...');
    await tester.tap(find.text('Nghỉ hoàn toàn'));
    print('ONBOARDING_TEST: Pump after Nghỉ hoàn toàn...');
    await tester.pumpAndSettle();

    print('ONBOARDING_TEST: Tapping Tiếp tục (Step 7)...');
    await tester.tap(find.text('Tiếp tục'));
    print('ONBOARDING_TEST: Pump after Tiếp tục (Step 7)...');
    await tester.pumpAndSettle();
    print('ONBOARDING_TEST: Step 7 finished.');

    // Step 8/8: Review
    expect(find.textContaining('Bước 8/8'), findsOneWidget);
    print('ONBOARDING_TEST: Tapping Tạo mục tiêu...');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tạo mục tiêu'));
    // Wait for generator to run and TodayScreen to finish loading (CircularProgressIndicator disappears)
    print(
        'ONBOARDING_TEST: Waiting for CircularProgressIndicator to clear after Goal Creation...');
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final isEmpty = find.byType(CircularProgressIndicator).evaluate().isEmpty;
      print(
          'ONBOARDING_TEST: Loop iteration $i, CircularProgressIndicator is empty: $isEmpty');
      if (isEmpty) {
        break;
      }
    }
    print('ONBOARDING_TEST: Indicator check loop finished.');

    // After goal creation, we should land on TodayScreen/MainNavigationShell!
    print('ONBOARDING_TEST: Verifying Hôm nay screen presence...');
    expect(find.text('Hôm nay'), findsOneWidget);
    print('ONBOARDING_TEST: Hôm nay screen verified.');

    // Dispose the app widget tree to trigger database/provider disposal inside the test body
    print(
        'ONBOARDING_TEST: Disposing app widget tree via SizedBox.shrink()...');
    await tester.pumpWidget(const SizedBox.shrink());
    print('ONBOARDING_TEST: Widget tree disposed. Pumping 1s...');
    // Pump a duration to allow any pending timers/streams to finish
    await tester.pump(const Duration(seconds: 1));
    print('ONBOARDING_TEST: Onboarding integration test body completed.');
  });
}
