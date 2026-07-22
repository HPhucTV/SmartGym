import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/core/model/food_photo_analysis_models.dart';
import 'package:gym_app/feature/nutrition/photo/food_camera_gateway.dart';
import 'package:gym_app/feature/nutrition/photo/food_capture_screen.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_preprocessor.dart';

void main() {
  testWidgets('shows permission guidance when camera initialization is denied',
      (tester) async {
    final gateway = _FakeGateway(
      initializeError: const FoodCameraException.permissionDenied(),
    );

    await tester.pumpWidget(_app(gateway: gateway));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('quyền camera'), findsOneWidget);
    expect(find.byKey(const Key('food-camera-preview')), findsNothing);
  });

  testWidgets('shows retry guidance for a generic initialization failure',
      (tester) async {
    final gateway = _FakeGateway(initializeError: StateError('unavailable'));

    await tester.pumpWidget(_app(gateway: gateway));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('khởi động camera'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('returns only a PreparedUpload after a valid capture',
      (tester) async {
    final gateway = _FakeGateway();
    final upload = PreparedUpload(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
      mimeType: 'image/jpeg',
      filename: 'food-analysis.jpg',
    );
    Object? result;

    await tester.pumpWidget(
      _app(
        gateway: gateway,
        preprocessor: _FakePreprocessor(upload: upload, issues: const {}),
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();

    expect(result, same(upload));
    expect(gateway.captureCalls, 1);
  });

  testWidgets('rejects blur locally and lets the user recapture',
      (tester) async {
    final gateway = _FakeGateway();
    final preprocessor = _FakePreprocessor(
      issues: const {PhotoQualityIssue.tooBlurry},
    );

    await tester.pumpWidget(
      _app(gateway: gateway, preprocessor: preprocessor),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();

    expect(find.textContaining('mờ'), findsOneWidget);
    expect(find.text('Chụp lại'), findsOneWidget);

    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();
    expect(gateway.captureCalls, 2);
  });

  testWidgets('prevents two captures while one capture is pending',
      (tester) async {
    final pending = Completer<Uint8List>();
    final gateway = _FakeGateway(pendingCapture: pending);

    await tester.pumpWidget(_app(gateway: gateway));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pump();

    expect(gateway.captureCalls, 1);
    pending.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
  });

  testWidgets('requested second purpose has specific copy and closes cleanly',
      (tester) async {
    final gateway = _FakeGateway();
    Object? result = 'not closed';

    await tester.pumpWidget(
      _app(
        gateway: gateway,
        purpose: FoodCapturePurpose.requestedSideOrCloseUp,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('góc bên hoặc cận cảnh'), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-food-camera')));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(gateway.disposeCalls, 1);
  });

  testWidgets('close while initialization is pending cannot pop later',
      (tester) async {
    final pendingInitialize = Completer<void>();
    final gateway = _FakeGateway(pendingInitialize: pendingInitialize);

    await tester.pumpWidget(_app(gateway: gateway));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('close-food-camera')));
    await tester.pumpAndSettle();

    pendingInitialize.complete();
    await tester.pumpAndSettle();

    expect(gateway.disposeCalls, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('close while capture is pending cannot pop later',
      (tester) async {
    final pendingCapture = Completer<Uint8List>();
    final gateway = _FakeGateway(pendingCapture: pendingCapture);
    Object? result = 'not closed';

    await tester.pumpWidget(
      _app(gateway: gateway, onResult: (value) => result = value),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('close-food-camera')));
    await tester.pumpAndSettle();

    pendingCapture.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(gateway.disposeCalls, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
      'pause during take invalidates the stale capture and allows a new one',
      (tester) async {
    final pendingCapture = Completer<Uint8List>();
    final gateway = _FakeGateway(
      pendingCapture: pendingCapture,
      captureResponses: [
        Future.value(Uint8List.fromList([4, 5, 6])),
      ],
    );
    final upload = _upload();
    final preprocessor = _FakePreprocessor(
      preparationResponses: [
        PhotoPreparationResult(upload: upload, issues: const {}),
        PhotoPreparationResult(upload: upload, issues: const {}),
      ],
    );
    Object? result;

    await tester.pumpWidget(
      _app(
        gateway: gateway,
        preprocessor: preprocessor,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    pendingCapture.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(preprocessor.calls, 0);
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();

    expect(result, same(upload));
    expect(gateway.captureCalls, 2);
  });

  testWidgets(
      'pause during preprocessing invalidates the stale result and allows a new one',
      (tester) async {
    final gateway = _FakeGateway(
      captureResponses: [
        Future.value(Uint8List.fromList([1, 2, 3])),
        Future.value(Uint8List.fromList([4, 5, 6])),
      ],
    );
    final pendingPreparation = Completer<PhotoPreparationResult>();
    final upload = _upload();
    final preprocessor = _FakePreprocessor(
      pendingPreparation: pendingPreparation,
      preparationResponses: [
        PhotoPreparationResult(upload: upload, issues: const {}),
        PhotoPreparationResult(upload: upload, issues: const {}),
      ],
    );
    Object? result;

    await tester.pumpWidget(
      _app(
        gateway: gateway,
        preprocessor: preprocessor,
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pump();
    expect(preprocessor.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    pendingPreparation.complete(
      PhotoPreparationResult(upload: upload, issues: const {}),
    );
    await tester.pumpAndSettle();

    expect(result, isNull);
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();

    expect(result, same(upload));
    expect(gateway.captureCalls, 2);
  });

  testWidgets('pause and resume during initialize keeps the newest lifecycle',
      (tester) async {
    final pendingInitialize = Completer<void>();
    final gateway = _FakeGateway(pendingInitialize: pendingInitialize);

    await tester.pumpWidget(_app(gateway: gateway));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(gateway.disposeCalls, 1);
    expect(gateway.initializeCalls, 2);

    pendingInitialize.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-camera-preview')), findsOneWidget);
    expect(gateway.disposeCalls, 1);
  });
}

Widget _app({
  required _FakeGateway gateway,
  FoodPhotoPreprocessor? preprocessor,
  FoodCapturePurpose purpose = FoodCapturePurpose.primaryMealOrLabel,
  ValueChanged<Object?>? onResult,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<PreparedUpload>(
                MaterialPageRoute(
                  builder: (_) => FoodCaptureScreen(
                    gateway: gateway,
                    preprocessor: preprocessor ?? _FakePreprocessor(),
                    capturePurpose: purpose,
                  ),
                ),
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

final class _FakeGateway implements FoodCameraGateway {
  final Object? initializeError;
  final Completer<void>? pendingInitialize;
  final Completer<Uint8List>? pendingCapture;
  final List<Future<Uint8List>>? captureResponses;
  int captureCalls = 0;
  int disposeCalls = 0;
  int initializeCalls = 0;

  _FakeGateway({
    this.initializeError,
    this.pendingInitialize,
    this.pendingCapture,
    this.captureResponses,
  });

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeError != null) throw initializeError!;
    if (pendingInitialize != null) await pendingInitialize!.future;
  }

  @override
  Widget buildPreview() => Container(
        key: const Key('food-camera-preview'),
        color: Colors.black,
      );

  @override
  Future<Uint8List> takePicture() {
    captureCalls++;
    if (captureCalls == 1 && pendingCapture != null) {
      return pendingCapture!.future;
    }
    final responses = captureResponses;
    final responseIndex = captureCalls - 2;
    if (responses != null &&
        responseIndex >= 0 &&
        responseIndex < responses.length) {
      return responses[responseIndex];
    }
    return Future.value(Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

final class _FakePreprocessor implements FoodPhotoPreprocessor {
  final PreparedUpload? upload;
  final Set<PhotoQualityIssue> issues;
  final Completer<PhotoPreparationResult>? pendingPreparation;
  final List<PhotoPreparationResult>? preparationResponses;
  int calls = 0;

  _FakePreprocessor({
    this.upload,
    this.issues = const {PhotoQualityIssue.tooBlurry},
    this.pendingPreparation,
    this.preparationResponses,
  });

  @override
  Future<PhotoPreparationResult> prepare(Uint8List sourceBytes) async {
    calls++;
    if (calls == 1 && pendingPreparation != null) {
      return pendingPreparation!.future;
    }
    final responses = preparationResponses;
    final responseIndex = calls - 1;
    if (responses != null &&
        responseIndex >= 0 &&
        responseIndex < responses.length) {
      return responses[responseIndex];
    }
    return PhotoPreparationResult(upload: upload, issues: issues);
  }
}

PreparedUpload _upload() => PreparedUpload(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
      mimeType: 'image/jpeg',
      filename: 'food-analysis.jpg',
    );
