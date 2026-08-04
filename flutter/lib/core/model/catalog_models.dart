import 'package:freezed_annotation/freezed_annotation.dart';
import 'goal_models.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

enum Equipment {
  @JsonValue('BODYWEIGHT')
  bodyweight,
  @JsonValue('DUMBBELL')
  dumbbell,
  @JsonValue('BAND')
  band,
  @JsonValue('BARBELL')
  barbell,
  @JsonValue('BENCH')
  bench,
  @JsonValue('CABLE')
  cable,
  @JsonValue('MACHINE')
  machine,
  @JsonValue('CARDIO_MACHINE')
  cardioMachine,
}

enum MuscleGroup {
  @JsonValue('CHEST')
  chest,
  @JsonValue('BACK')
  back,
  @JsonValue('SHOULDERS')
  shoulders,
  @JsonValue('BICEPS')
  biceps,
  @JsonValue('TRICEPS')
  triceps,
  @JsonValue('CORE')
  core,
  @JsonValue('QUADS')
  quads,
  @JsonValue('HAMSTRINGS')
  hamstrings,
  @JsonValue('GLUTES')
  glutes,
  @JsonValue('CALVES')
  calves,
  @JsonValue('FULL_BODY')
  fullBody,
  @JsonValue('CARDIO')
  cardio,
  @JsonValue('MOBILITY')
  mobility,
}

enum MovementPattern {
  @JsonValue('SQUAT')
  squat,
  @JsonValue('HINGE')
  hinge,
  @JsonValue('LUNGE')
  lunge,
  @JsonValue('HORIZONTAL_PUSH')
  horizontalPush,
  @JsonValue('VERTICAL_PUSH')
  verticalPush,
  @JsonValue('HORIZONTAL_PULL')
  horizontalPull,
  @JsonValue('VERTICAL_PULL')
  verticalPull,
  @JsonValue('CARRY')
  carry,
  @JsonValue('CORE')
  core,
  @JsonValue('LOCOMOTION')
  locomotion,
  @JsonValue('MOBILITY')
  mobility,
}

extension MuscleGroupExtension on MuscleGroup {
  String labelVi() {
    switch (this) {
      case MuscleGroup.chest:
        return 'Ngực';
      case MuscleGroup.back:
        return 'Lưng';
      case MuscleGroup.shoulders:
        return 'Vai';
      case MuscleGroup.biceps:
        return 'Tay trước';
      case MuscleGroup.triceps:
        return 'Tay sau';
      case MuscleGroup.core:
        return 'Bụng';
      case MuscleGroup.quads:
        return 'Đùi trước';
      case MuscleGroup.hamstrings:
        return 'Đùi sau';
      case MuscleGroup.glutes:
        return 'Mông';
      case MuscleGroup.calves:
        return 'Bắp chân';
      case MuscleGroup.fullBody:
        return 'Toàn thân';
      case MuscleGroup.cardio:
        return 'Tim mạch';
      case MuscleGroup.mobility:
        return 'Khớp/Giãn cơ';
    }
  }
}

@freezed
abstract class ExerciseDefinition with _$ExerciseDefinition {
  const factory ExerciseDefinition({
    required String id,
    required String sourceId,
    required String nameVi,
    required ExperienceLevel level,
    required List<Equipment> equipment,
    required MovementPattern movementPattern,
    @JsonKey(name: 'primaryMuscle') required MuscleGroup primaryMuscleGroup,
    @JsonKey(name: 'secondaryMuscles')
    @Default([])
    List<MuscleGroup> secondaryMuscleGroups,
    required List<String> instructionsVi,
    @Default([]) List<String> substituteIds,
    String? animationId,
  }) = _ExerciseDefinition;

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDefinitionFromJson(json);
}

@freezed
abstract class ExercisePrescription with _$ExercisePrescription {
  const factory ExercisePrescription({
    required String exerciseId,
    required int sets,
    @JsonKey(name: 'repsMin') int? minReps,
    @JsonKey(name: 'repsMax') int? maxReps,
    int? durationSeconds,
    required int restSeconds,
  }) = _ExercisePrescription;

  factory ExercisePrescription.fromJson(Map<String, dynamic> json) =>
      _$ExercisePrescriptionFromJson(json);
}

@freezed
abstract class WorkoutTemplate with _$WorkoutTemplate {
  const factory WorkoutTemplate({
    required int sequence,
    required int week,
    required String titleVi,
    required String focusVi,
    required int estimatedMinutes,
    required int restDaysAfter,
    required List<ExercisePrescription> exercises,
  }) = _WorkoutTemplate;

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);
}

@freezed
abstract class ProgramTemplate with _$ProgramTemplate {
  const factory ProgramTemplate({
    required String id,
    required FitnessGoal goal,
    required ExperienceLevel level,
    required EquipmentProfile equipmentProfile,
    required int sessionsPerWeek,
    required int durationWeeks,
    required List<WorkoutTemplate> workouts,
  }) = _ProgramTemplate;

  factory ProgramTemplate.fromJson(Map<String, dynamic> json) =>
      _$ProgramTemplateFromJson(json);
}
