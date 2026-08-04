import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/catalog_models.dart';
import 'package:gym_app/feature/today/today_ui_state.dart';
import 'package:gym_app/feature/today/widgets/exercise_card.dart';
import 'package:gym_app/ui/theme/theme.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required String? animationId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: getGymLightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseCard(
              sessionId: 1,
              row: WorkoutRowUi(
                orderIndex: 0,
                nameVi: 'Chống đẩy',
                prescriptionText: '3 × 10',
                restSeconds: 60,
                instructionsVi: const [
                  'Giữ thân người thẳng.',
                  'Hạ ngực rồi đẩy lên.',
                ],
                isChecked: false,
                exerciseId: 'push_up',
                primaryMuscleGroup: MuscleGroup.chest,
                animationId: animationId,
              ),
              enabled: true,
              onCheckedChange: (_) {},
              onSubstitute: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Xem hướng dẫn ▼'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows 3D action only when the exercise declares animationId', (
    tester,
  ) async {
    await pumpCard(tester, animationId: 'push_up');

    expect(find.text('Xem chuyển động 3D'), findsOneWidget);
  });

  testWidgets('hides 3D action when no animation is supported', (tester) async {
    await pumpCard(tester, animationId: null);

    expect(find.text('Xem chuyển động 3D'), findsNothing);
  });
}
