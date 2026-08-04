// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseDefinition _$ExerciseDefinitionFromJson(Map<String, dynamic> json) =>
    _ExerciseDefinition(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      nameVi: json['nameVi'] as String,
      level: $enumDecode(_$ExperienceLevelEnumMap, json['level']),
      equipment: (json['equipment'] as List<dynamic>)
          .map((e) => $enumDecode(_$EquipmentEnumMap, e))
          .toList(),
      movementPattern: $enumDecode(
        _$MovementPatternEnumMap,
        json['movementPattern'],
      ),
      primaryMuscleGroup: $enumDecode(
        _$MuscleGroupEnumMap,
        json['primaryMuscle'],
      ),
      secondaryMuscleGroups:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const [],
      instructionsVi: (json['instructionsVi'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      substituteIds:
          (json['substituteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      animationId: json['animationId'] as String?,
    );

Map<String, dynamic> _$ExerciseDefinitionToJson(
  _ExerciseDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'sourceId': instance.sourceId,
  'nameVi': instance.nameVi,
  'level': _$ExperienceLevelEnumMap[instance.level]!,
  'equipment': instance.equipment.map((e) => _$EquipmentEnumMap[e]!).toList(),
  'movementPattern': _$MovementPatternEnumMap[instance.movementPattern]!,
  'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscleGroup]!,
  'secondaryMuscles': instance.secondaryMuscleGroups
      .map((e) => _$MuscleGroupEnumMap[e]!)
      .toList(),
  'instructionsVi': instance.instructionsVi,
  'substituteIds': instance.substituteIds,
  'animationId': instance.animationId,
};

const _$ExperienceLevelEnumMap = {
  ExperienceLevel.beginner: 'BEGINNER',
  ExperienceLevel.intermediate: 'INTERMEDIATE',
};

const _$EquipmentEnumMap = {
  Equipment.bodyweight: 'BODYWEIGHT',
  Equipment.dumbbell: 'DUMBBELL',
  Equipment.band: 'BAND',
  Equipment.barbell: 'BARBELL',
  Equipment.bench: 'BENCH',
  Equipment.cable: 'CABLE',
  Equipment.machine: 'MACHINE',
  Equipment.cardioMachine: 'CARDIO_MACHINE',
};

const _$MovementPatternEnumMap = {
  MovementPattern.squat: 'SQUAT',
  MovementPattern.hinge: 'HINGE',
  MovementPattern.lunge: 'LUNGE',
  MovementPattern.horizontalPush: 'HORIZONTAL_PUSH',
  MovementPattern.verticalPush: 'VERTICAL_PUSH',
  MovementPattern.horizontalPull: 'HORIZONTAL_PULL',
  MovementPattern.verticalPull: 'VERTICAL_PULL',
  MovementPattern.carry: 'CARRY',
  MovementPattern.core: 'CORE',
  MovementPattern.locomotion: 'LOCOMOTION',
  MovementPattern.mobility: 'MOBILITY',
};

const _$MuscleGroupEnumMap = {
  MuscleGroup.chest: 'CHEST',
  MuscleGroup.back: 'BACK',
  MuscleGroup.shoulders: 'SHOULDERS',
  MuscleGroup.biceps: 'BICEPS',
  MuscleGroup.triceps: 'TRICEPS',
  MuscleGroup.core: 'CORE',
  MuscleGroup.quads: 'QUADS',
  MuscleGroup.hamstrings: 'HAMSTRINGS',
  MuscleGroup.glutes: 'GLUTES',
  MuscleGroup.calves: 'CALVES',
  MuscleGroup.fullBody: 'FULL_BODY',
  MuscleGroup.cardio: 'CARDIO',
  MuscleGroup.mobility: 'MOBILITY',
};

_ExercisePrescription _$ExercisePrescriptionFromJson(
  Map<String, dynamic> json,
) => _ExercisePrescription(
  exerciseId: json['exerciseId'] as String,
  sets: (json['sets'] as num).toInt(),
  minReps: (json['repsMin'] as num?)?.toInt(),
  maxReps: (json['repsMax'] as num?)?.toInt(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  restSeconds: (json['restSeconds'] as num).toInt(),
);

Map<String, dynamic> _$ExercisePrescriptionToJson(
  _ExercisePrescription instance,
) => <String, dynamic>{
  'exerciseId': instance.exerciseId,
  'sets': instance.sets,
  'repsMin': instance.minReps,
  'repsMax': instance.maxReps,
  'durationSeconds': instance.durationSeconds,
  'restSeconds': instance.restSeconds,
};

_WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) =>
    _WorkoutTemplate(
      sequence: (json['sequence'] as num).toInt(),
      week: (json['week'] as num).toInt(),
      titleVi: json['titleVi'] as String,
      focusVi: json['focusVi'] as String,
      estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      restDaysAfter: (json['restDaysAfter'] as num).toInt(),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExercisePrescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutTemplateToJson(_WorkoutTemplate instance) =>
    <String, dynamic>{
      'sequence': instance.sequence,
      'week': instance.week,
      'titleVi': instance.titleVi,
      'focusVi': instance.focusVi,
      'estimatedMinutes': instance.estimatedMinutes,
      'restDaysAfter': instance.restDaysAfter,
      'exercises': instance.exercises,
    };

_ProgramTemplate _$ProgramTemplateFromJson(Map<String, dynamic> json) =>
    _ProgramTemplate(
      id: json['id'] as String,
      goal: $enumDecode(_$FitnessGoalEnumMap, json['goal']),
      level: $enumDecode(_$ExperienceLevelEnumMap, json['level']),
      equipmentProfile: $enumDecode(
        _$EquipmentProfileEnumMap,
        json['equipmentProfile'],
      ),
      sessionsPerWeek: (json['sessionsPerWeek'] as num).toInt(),
      durationWeeks: (json['durationWeeks'] as num).toInt(),
      workouts: (json['workouts'] as List<dynamic>)
          .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgramTemplateToJson(_ProgramTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goal': _$FitnessGoalEnumMap[instance.goal]!,
      'level': _$ExperienceLevelEnumMap[instance.level]!,
      'equipmentProfile': _$EquipmentProfileEnumMap[instance.equipmentProfile]!,
      'sessionsPerWeek': instance.sessionsPerWeek,
      'durationWeeks': instance.durationWeeks,
      'workouts': instance.workouts,
    };

const _$FitnessGoalEnumMap = {
  FitnessGoal.muscleGain: 'MUSCLE_GAIN',
  FitnessGoal.fatLossConditioning: 'FAT_LOSS_CONDITIONING',
  FitnessGoal.endurance: 'ENDURANCE',
  FitnessGoal.generalFitness: 'GENERAL_FITNESS',
};

const _$EquipmentProfileEnumMap = {
  EquipmentProfile.bodyweightOnly: 'BODYWEIGHT_ONLY',
  EquipmentProfile.dumbbells: 'DUMBBELLS',
  EquipmentProfile.resistanceBands: 'RESISTANCE_BANDS',
  EquipmentProfile.fullGym: 'FULL_GYM',
};
