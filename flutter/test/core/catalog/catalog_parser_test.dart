import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/catalog/catalog_parser.dart';

void main() {
  group('CatalogParserTest', () {
    const validExerciseJson = '''
[
  {
    "id": "push_up",
    "animationId": "push_up",
    "sourceId": "Pushups",
    "nameVi": "Chống đẩy",
    "level": "BEGINNER",
    "equipment": ["BODYWEIGHT"],
    "movementPattern": "HORIZONTAL_PUSH",
    "primaryMuscle": "CHEST",
    "secondaryMuscles": ["TRICEPS", "SHOULDERS"],
    "instructionsVi": [
      "Đặt hai tay dưới vai và giữ thân người thẳng.",
      "Hạ ngực có kiểm soát rồi đẩy người lên."
    ]
  }
]
''';

    test('valid minimal exercise JSON decodes', () {
      final exercises = CatalogParser.parseExercises(validExerciseJson);

      expect(exercises.length, equals(1));
      expect(exercises.first.id, equals("push_up"));
      expect(exercises.first.nameVi, equals("Chống đẩy"));
      expect(exercises.first.animationId, equals("push_up"));
    });

    test('unknown enum value throws FormatException or TypeError', () {
      expect(
        () => CatalogParser.parseExercises(
          validExerciseJson.replaceAll("BEGINNER", "ADVANCED_UNKNOWN"),
        ),
        throwsA(anyOf(
            isA<FormatException>(), isA<TypeError>(), isA<ArgumentError>())),
      );
    });

    test('missing required nameVi throws Exception', () {
      expect(
        () => CatalogParser.parseExercises(
          validExerciseJson.replaceAll('"nameVi": "Chống đẩy",', ""),
        ),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>(),
            isA<NoSuchMethodError>())),
      );
    });
  });
}
