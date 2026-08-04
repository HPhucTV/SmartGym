import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/catalog/catalog_parser.dart';
import 'package:gym_app/core/catalog/catalog_validator.dart';

void main() {
  group('CatalogValidatorTest', () {
    const validExerciseJson = '''
[{
  "id":"push_up",
  "animationId":"push_up",
  "sourceId":"Pushups",
  "nameVi":"Chống đẩy",
  "level":"BEGINNER",
  "equipment":["BODYWEIGHT"],
  "movementPattern":"HORIZONTAL_PUSH",
  "primaryMuscle":"CHEST",
  "secondaryMuscles":["TRICEPS"],
  "instructionsVi":["Giữ thân thẳng.","Hạ ngực rồi đẩy lên."]
}]
''';

    test('validator reports every required catalog issue', () {
      final valid = CatalogParser.parseExercises(validExerciseJson).single;
      final invalid = valid.copyWith(
        id: "Bad-ID",
        animationId: "Bad-Animation",
        sourceId: " ",
        nameVi: "",
        equipment: [],
        instructionsVi: ["", "Hai", "Ba", "Bốn", "Năm", "Sáu"],
      );

      final issues = CatalogValidator.validateExercises([invalid, invalid]);

      expect(issues.any((issue) => issue.contains("Duplicate exercise id")),
          isTrue);
      expect(issues.any((issue) => issue.contains("[a-z0-9_]+")), isTrue);
      expect(issues.any((issue) => issue.contains("animationId")), isTrue);
      expect(issues.any((issue) => issue.contains("sourceId")), isTrue);
      expect(issues.any((issue) => issue.contains("nameVi")), isTrue);
      expect(
          issues.any(
              (issue) => issue.contains("instructionsVi must contain 2..5")),
          isTrue);
      expect(
          issues.any((issue) => issue.contains("blank instruction")), isTrue);
      expect(issues.any((issue) => issue.contains("equipment")), isTrue);
    });

    test('bundled exercise asset contains 64 valid unique records', () {
      final file = File('assets/catalog/exercises_vi.json');
      expect(file.existsSync(), isTrue,
          reason: "Không tìm thấy file assets/catalog/exercises_vi.json");
      final raw = file.readAsStringSync();
      final exercises = CatalogParser.parseExercises(raw);

      expect(exercises.length, equals(64));
      expect(exercises.map((e) => e.id).toSet().length, equals(64));
      expect(exercises.every((e) => e.animationId != null), isTrue);
      expect(exercises.map((e) => e.animationId).toSet().length, equals(64));
      expect(CatalogValidator.validateExercises(exercises).isEmpty, isTrue);
      expect(
          exercises.every((e) =>
              e.instructionsVi.length >= 2 && e.instructionsVi.length <= 5),
          isTrue);
    });
  });
}
