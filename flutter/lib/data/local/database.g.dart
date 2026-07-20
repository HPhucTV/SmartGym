// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _programIdMeta =
      const VerificationMeta('programId');
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
      'program_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<FitnessGoal, String> goal =
      GeneratedColumn<String>('goal', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<FitnessGoal>($GoalsTable.$convertergoal);
  static const VerificationMeta _goalsCsvMeta =
      const VerificationMeta('goalsCsv');
  @override
  late final GeneratedColumn<String> goalsCsv = GeneratedColumn<String>(
      'goals_csv', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<Gender, String> gender =
      GeneratedColumn<String>('gender', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('MALE'))
          .withConverter<Gender>($GoalsTable.$convertergender);
  @override
  late final GeneratedColumnWithTypeConverter<BodyType, String> bodyType =
      GeneratedColumn<String>('body_type', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('MESOMORPH'))
          .withConverter<BodyType>($GoalsTable.$converterbodyType);
  @override
  late final GeneratedColumnWithTypeConverter<ExperienceLevel, String> level =
      GeneratedColumn<String>('level', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ExperienceLevel>($GoalsTable.$converterlevel);
  @override
  late final GeneratedColumnWithTypeConverter<EquipmentProfile, String>
      equipmentProfile = GeneratedColumn<String>(
              'equipment_profile', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<EquipmentProfile>(
              $GoalsTable.$converterequipmentProfile);
  static const VerificationMeta _sessionsPerWeekMeta =
      const VerificationMeta('sessionsPerWeek');
  @override
  late final GeneratedColumn<int> sessionsPerWeek = GeneratedColumn<int>(
      'sessions_per_week', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationWeeksMeta =
      const VerificationMeta('durationWeeks');
  @override
  late final GeneratedColumn<int> durationWeeks = GeneratedColumn<int>(
      'duration_weeks', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<RestDayMode, String> restDayMode =
      GeneratedColumn<String>('rest_day_mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RestDayMode>($GoalsTable.$converterrestDayMode);
  static const VerificationMeta _trainingDaysMaskMeta =
      const VerificationMeta('trainingDaysMask');
  @override
  late final GeneratedColumn<int> trainingDaysMask = GeneratedColumn<int>(
      'training_days_mask', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _sessionDurationMinutesMeta =
      const VerificationMeta('sessionDurationMinutes');
  @override
  late final GeneratedColumn<int> sessionDurationMinutes = GeneratedColumn<int>(
      'session_duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  static const VerificationMeta _createdEpochDayMeta =
      const VerificationMeta('createdEpochDay');
  @override
  late final GeneratedColumn<int> createdEpochDay = GeneratedColumn<int>(
      'created_epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        programId,
        goal,
        goalsCsv,
        gender,
        bodyType,
        level,
        equipmentProfile,
        sessionsPerWeek,
        durationWeeks,
        restDayMode,
        trainingDaysMask,
        sessionDurationMinutes,
        createdEpochDay,
        archived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(_programIdMeta,
          programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta));
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('goals_csv')) {
      context.handle(_goalsCsvMeta,
          goalsCsv.isAcceptableOrUnknown(data['goals_csv']!, _goalsCsvMeta));
    }
    if (data.containsKey('sessions_per_week')) {
      context.handle(
          _sessionsPerWeekMeta,
          sessionsPerWeek.isAcceptableOrUnknown(
              data['sessions_per_week']!, _sessionsPerWeekMeta));
    } else if (isInserting) {
      context.missing(_sessionsPerWeekMeta);
    }
    if (data.containsKey('duration_weeks')) {
      context.handle(
          _durationWeeksMeta,
          durationWeeks.isAcceptableOrUnknown(
              data['duration_weeks']!, _durationWeeksMeta));
    } else if (isInserting) {
      context.missing(_durationWeeksMeta);
    }
    if (data.containsKey('training_days_mask')) {
      context.handle(
          _trainingDaysMaskMeta,
          trainingDaysMask.isAcceptableOrUnknown(
              data['training_days_mask']!, _trainingDaysMaskMeta));
    }
    if (data.containsKey('session_duration_minutes')) {
      context.handle(
          _sessionDurationMinutesMeta,
          sessionDurationMinutes.isAcceptableOrUnknown(
              data['session_duration_minutes']!, _sessionDurationMinutesMeta));
    }
    if (data.containsKey('created_epoch_day')) {
      context.handle(
          _createdEpochDayMeta,
          createdEpochDay.isAcceptableOrUnknown(
              data['created_epoch_day']!, _createdEpochDayMeta));
    } else if (isInserting) {
      context.missing(_createdEpochDayMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      programId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program_id'])!,
      goal: $GoalsTable.$convertergoal.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal'])!),
      goalsCsv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goals_csv'])!,
      gender: $GoalsTable.$convertergender.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!),
      bodyType: $GoalsTable.$converterbodyType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_type'])!),
      level: $GoalsTable.$converterlevel.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level'])!),
      equipmentProfile: $GoalsTable.$converterequipmentProfile.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}equipment_profile'])!),
      sessionsPerWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sessions_per_week'])!,
      durationWeeks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_weeks'])!,
      restDayMode: $GoalsTable.$converterrestDayMode.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rest_day_mode'])!),
      trainingDaysMask: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}training_days_mask'])!,
      sessionDurationMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}session_duration_minutes'])!,
      createdEpochDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_epoch_day'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<FitnessGoal, String> $convertergoal =
      const FitnessGoalConverter();
  static TypeConverter<Gender, String> $convertergender =
      const GenderConverter();
  static TypeConverter<BodyType, String> $converterbodyType =
      const BodyTypeConverter();
  static TypeConverter<ExperienceLevel, String> $converterlevel =
      const ExperienceLevelConverter();
  static TypeConverter<EquipmentProfile, String> $converterequipmentProfile =
      const EquipmentProfileConverter();
  static TypeConverter<RestDayMode, String> $converterrestDayMode =
      const RestDayModeConverter();
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String programId;
  final FitnessGoal goal;
  final String goalsCsv;
  final Gender gender;
  final BodyType bodyType;
  final ExperienceLevel level;
  final EquipmentProfile equipmentProfile;
  final int sessionsPerWeek;
  final int durationWeeks;
  final RestDayMode restDayMode;
  final int trainingDaysMask;
  final int sessionDurationMinutes;
  final int createdEpochDay;
  final bool archived;
  const Goal(
      {required this.id,
      required this.programId,
      required this.goal,
      required this.goalsCsv,
      required this.gender,
      required this.bodyType,
      required this.level,
      required this.equipmentProfile,
      required this.sessionsPerWeek,
      required this.durationWeeks,
      required this.restDayMode,
      required this.trainingDaysMask,
      required this.sessionDurationMinutes,
      required this.createdEpochDay,
      required this.archived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<String>(programId);
    {
      map['goal'] = Variable<String>($GoalsTable.$convertergoal.toSql(goal));
    }
    map['goals_csv'] = Variable<String>(goalsCsv);
    {
      map['gender'] =
          Variable<String>($GoalsTable.$convertergender.toSql(gender));
    }
    {
      map['body_type'] =
          Variable<String>($GoalsTable.$converterbodyType.toSql(bodyType));
    }
    {
      map['level'] = Variable<String>($GoalsTable.$converterlevel.toSql(level));
    }
    {
      map['equipment_profile'] = Variable<String>(
          $GoalsTable.$converterequipmentProfile.toSql(equipmentProfile));
    }
    map['sessions_per_week'] = Variable<int>(sessionsPerWeek);
    map['duration_weeks'] = Variable<int>(durationWeeks);
    {
      map['rest_day_mode'] = Variable<String>(
          $GoalsTable.$converterrestDayMode.toSql(restDayMode));
    }
    map['training_days_mask'] = Variable<int>(trainingDaysMask);
    map['session_duration_minutes'] = Variable<int>(sessionDurationMinutes);
    map['created_epoch_day'] = Variable<int>(createdEpochDay);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      programId: Value(programId),
      goal: Value(goal),
      goalsCsv: Value(goalsCsv),
      gender: Value(gender),
      bodyType: Value(bodyType),
      level: Value(level),
      equipmentProfile: Value(equipmentProfile),
      sessionsPerWeek: Value(sessionsPerWeek),
      durationWeeks: Value(durationWeeks),
      restDayMode: Value(restDayMode),
      trainingDaysMask: Value(trainingDaysMask),
      sessionDurationMinutes: Value(sessionDurationMinutes),
      createdEpochDay: Value(createdEpochDay),
      archived: Value(archived),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      goal: serializer.fromJson<FitnessGoal>(json['goal']),
      goalsCsv: serializer.fromJson<String>(json['goalsCsv']),
      gender: serializer.fromJson<Gender>(json['gender']),
      bodyType: serializer.fromJson<BodyType>(json['bodyType']),
      level: serializer.fromJson<ExperienceLevel>(json['level']),
      equipmentProfile:
          serializer.fromJson<EquipmentProfile>(json['equipmentProfile']),
      sessionsPerWeek: serializer.fromJson<int>(json['sessionsPerWeek']),
      durationWeeks: serializer.fromJson<int>(json['durationWeeks']),
      restDayMode: serializer.fromJson<RestDayMode>(json['restDayMode']),
      trainingDaysMask: serializer.fromJson<int>(json['trainingDaysMask']),
      sessionDurationMinutes:
          serializer.fromJson<int>(json['sessionDurationMinutes']),
      createdEpochDay: serializer.fromJson<int>(json['createdEpochDay']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<String>(programId),
      'goal': serializer.toJson<FitnessGoal>(goal),
      'goalsCsv': serializer.toJson<String>(goalsCsv),
      'gender': serializer.toJson<Gender>(gender),
      'bodyType': serializer.toJson<BodyType>(bodyType),
      'level': serializer.toJson<ExperienceLevel>(level),
      'equipmentProfile': serializer.toJson<EquipmentProfile>(equipmentProfile),
      'sessionsPerWeek': serializer.toJson<int>(sessionsPerWeek),
      'durationWeeks': serializer.toJson<int>(durationWeeks),
      'restDayMode': serializer.toJson<RestDayMode>(restDayMode),
      'trainingDaysMask': serializer.toJson<int>(trainingDaysMask),
      'sessionDurationMinutes': serializer.toJson<int>(sessionDurationMinutes),
      'createdEpochDay': serializer.toJson<int>(createdEpochDay),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Goal copyWith(
          {int? id,
          String? programId,
          FitnessGoal? goal,
          String? goalsCsv,
          Gender? gender,
          BodyType? bodyType,
          ExperienceLevel? level,
          EquipmentProfile? equipmentProfile,
          int? sessionsPerWeek,
          int? durationWeeks,
          RestDayMode? restDayMode,
          int? trainingDaysMask,
          int? sessionDurationMinutes,
          int? createdEpochDay,
          bool? archived}) =>
      Goal(
        id: id ?? this.id,
        programId: programId ?? this.programId,
        goal: goal ?? this.goal,
        goalsCsv: goalsCsv ?? this.goalsCsv,
        gender: gender ?? this.gender,
        bodyType: bodyType ?? this.bodyType,
        level: level ?? this.level,
        equipmentProfile: equipmentProfile ?? this.equipmentProfile,
        sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
        durationWeeks: durationWeeks ?? this.durationWeeks,
        restDayMode: restDayMode ?? this.restDayMode,
        trainingDaysMask: trainingDaysMask ?? this.trainingDaysMask,
        sessionDurationMinutes:
            sessionDurationMinutes ?? this.sessionDurationMinutes,
        createdEpochDay: createdEpochDay ?? this.createdEpochDay,
        archived: archived ?? this.archived,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      goal: data.goal.present ? data.goal.value : this.goal,
      goalsCsv: data.goalsCsv.present ? data.goalsCsv.value : this.goalsCsv,
      gender: data.gender.present ? data.gender.value : this.gender,
      bodyType: data.bodyType.present ? data.bodyType.value : this.bodyType,
      level: data.level.present ? data.level.value : this.level,
      equipmentProfile: data.equipmentProfile.present
          ? data.equipmentProfile.value
          : this.equipmentProfile,
      sessionsPerWeek: data.sessionsPerWeek.present
          ? data.sessionsPerWeek.value
          : this.sessionsPerWeek,
      durationWeeks: data.durationWeeks.present
          ? data.durationWeeks.value
          : this.durationWeeks,
      restDayMode:
          data.restDayMode.present ? data.restDayMode.value : this.restDayMode,
      trainingDaysMask: data.trainingDaysMask.present
          ? data.trainingDaysMask.value
          : this.trainingDaysMask,
      sessionDurationMinutes: data.sessionDurationMinutes.present
          ? data.sessionDurationMinutes.value
          : this.sessionDurationMinutes,
      createdEpochDay: data.createdEpochDay.present
          ? data.createdEpochDay.value
          : this.createdEpochDay,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('goal: $goal, ')
          ..write('goalsCsv: $goalsCsv, ')
          ..write('gender: $gender, ')
          ..write('bodyType: $bodyType, ')
          ..write('level: $level, ')
          ..write('equipmentProfile: $equipmentProfile, ')
          ..write('sessionsPerWeek: $sessionsPerWeek, ')
          ..write('durationWeeks: $durationWeeks, ')
          ..write('restDayMode: $restDayMode, ')
          ..write('trainingDaysMask: $trainingDaysMask, ')
          ..write('sessionDurationMinutes: $sessionDurationMinutes, ')
          ..write('createdEpochDay: $createdEpochDay, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      programId,
      goal,
      goalsCsv,
      gender,
      bodyType,
      level,
      equipmentProfile,
      sessionsPerWeek,
      durationWeeks,
      restDayMode,
      trainingDaysMask,
      sessionDurationMinutes,
      createdEpochDay,
      archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.goal == this.goal &&
          other.goalsCsv == this.goalsCsv &&
          other.gender == this.gender &&
          other.bodyType == this.bodyType &&
          other.level == this.level &&
          other.equipmentProfile == this.equipmentProfile &&
          other.sessionsPerWeek == this.sessionsPerWeek &&
          other.durationWeeks == this.durationWeeks &&
          other.restDayMode == this.restDayMode &&
          other.trainingDaysMask == this.trainingDaysMask &&
          other.sessionDurationMinutes == this.sessionDurationMinutes &&
          other.createdEpochDay == this.createdEpochDay &&
          other.archived == this.archived);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> programId;
  final Value<FitnessGoal> goal;
  final Value<String> goalsCsv;
  final Value<Gender> gender;
  final Value<BodyType> bodyType;
  final Value<ExperienceLevel> level;
  final Value<EquipmentProfile> equipmentProfile;
  final Value<int> sessionsPerWeek;
  final Value<int> durationWeeks;
  final Value<RestDayMode> restDayMode;
  final Value<int> trainingDaysMask;
  final Value<int> sessionDurationMinutes;
  final Value<int> createdEpochDay;
  final Value<bool> archived;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.goal = const Value.absent(),
    this.goalsCsv = const Value.absent(),
    this.gender = const Value.absent(),
    this.bodyType = const Value.absent(),
    this.level = const Value.absent(),
    this.equipmentProfile = const Value.absent(),
    this.sessionsPerWeek = const Value.absent(),
    this.durationWeeks = const Value.absent(),
    this.restDayMode = const Value.absent(),
    this.trainingDaysMask = const Value.absent(),
    this.sessionDurationMinutes = const Value.absent(),
    this.createdEpochDay = const Value.absent(),
    this.archived = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String programId,
    required FitnessGoal goal,
    this.goalsCsv = const Value.absent(),
    this.gender = const Value.absent(),
    this.bodyType = const Value.absent(),
    required ExperienceLevel level,
    required EquipmentProfile equipmentProfile,
    required int sessionsPerWeek,
    required int durationWeeks,
    required RestDayMode restDayMode,
    this.trainingDaysMask = const Value.absent(),
    this.sessionDurationMinutes = const Value.absent(),
    required int createdEpochDay,
    this.archived = const Value.absent(),
  })  : programId = Value(programId),
        goal = Value(goal),
        level = Value(level),
        equipmentProfile = Value(equipmentProfile),
        sessionsPerWeek = Value(sessionsPerWeek),
        durationWeeks = Value(durationWeeks),
        restDayMode = Value(restDayMode),
        createdEpochDay = Value(createdEpochDay);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? programId,
    Expression<String>? goal,
    Expression<String>? goalsCsv,
    Expression<String>? gender,
    Expression<String>? bodyType,
    Expression<String>? level,
    Expression<String>? equipmentProfile,
    Expression<int>? sessionsPerWeek,
    Expression<int>? durationWeeks,
    Expression<String>? restDayMode,
    Expression<int>? trainingDaysMask,
    Expression<int>? sessionDurationMinutes,
    Expression<int>? createdEpochDay,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (goal != null) 'goal': goal,
      if (goalsCsv != null) 'goals_csv': goalsCsv,
      if (gender != null) 'gender': gender,
      if (bodyType != null) 'body_type': bodyType,
      if (level != null) 'level': level,
      if (equipmentProfile != null) 'equipment_profile': equipmentProfile,
      if (sessionsPerWeek != null) 'sessions_per_week': sessionsPerWeek,
      if (durationWeeks != null) 'duration_weeks': durationWeeks,
      if (restDayMode != null) 'rest_day_mode': restDayMode,
      if (trainingDaysMask != null) 'training_days_mask': trainingDaysMask,
      if (sessionDurationMinutes != null)
        'session_duration_minutes': sessionDurationMinutes,
      if (createdEpochDay != null) 'created_epoch_day': createdEpochDay,
      if (archived != null) 'archived': archived,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? programId,
      Value<FitnessGoal>? goal,
      Value<String>? goalsCsv,
      Value<Gender>? gender,
      Value<BodyType>? bodyType,
      Value<ExperienceLevel>? level,
      Value<EquipmentProfile>? equipmentProfile,
      Value<int>? sessionsPerWeek,
      Value<int>? durationWeeks,
      Value<RestDayMode>? restDayMode,
      Value<int>? trainingDaysMask,
      Value<int>? sessionDurationMinutes,
      Value<int>? createdEpochDay,
      Value<bool>? archived}) {
    return GoalsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      goal: goal ?? this.goal,
      goalsCsv: goalsCsv ?? this.goalsCsv,
      gender: gender ?? this.gender,
      bodyType: bodyType ?? this.bodyType,
      level: level ?? this.level,
      equipmentProfile: equipmentProfile ?? this.equipmentProfile,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      restDayMode: restDayMode ?? this.restDayMode,
      trainingDaysMask: trainingDaysMask ?? this.trainingDaysMask,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      createdEpochDay: createdEpochDay ?? this.createdEpochDay,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (goal.present) {
      map['goal'] =
          Variable<String>($GoalsTable.$convertergoal.toSql(goal.value));
    }
    if (goalsCsv.present) {
      map['goals_csv'] = Variable<String>(goalsCsv.value);
    }
    if (gender.present) {
      map['gender'] =
          Variable<String>($GoalsTable.$convertergender.toSql(gender.value));
    }
    if (bodyType.present) {
      map['body_type'] = Variable<String>(
          $GoalsTable.$converterbodyType.toSql(bodyType.value));
    }
    if (level.present) {
      map['level'] =
          Variable<String>($GoalsTable.$converterlevel.toSql(level.value));
    }
    if (equipmentProfile.present) {
      map['equipment_profile'] = Variable<String>(
          $GoalsTable.$converterequipmentProfile.toSql(equipmentProfile.value));
    }
    if (sessionsPerWeek.present) {
      map['sessions_per_week'] = Variable<int>(sessionsPerWeek.value);
    }
    if (durationWeeks.present) {
      map['duration_weeks'] = Variable<int>(durationWeeks.value);
    }
    if (restDayMode.present) {
      map['rest_day_mode'] = Variable<String>(
          $GoalsTable.$converterrestDayMode.toSql(restDayMode.value));
    }
    if (trainingDaysMask.present) {
      map['training_days_mask'] = Variable<int>(trainingDaysMask.value);
    }
    if (sessionDurationMinutes.present) {
      map['session_duration_minutes'] =
          Variable<int>(sessionDurationMinutes.value);
    }
    if (createdEpochDay.present) {
      map['created_epoch_day'] = Variable<int>(createdEpochDay.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('goal: $goal, ')
          ..write('goalsCsv: $goalsCsv, ')
          ..write('gender: $gender, ')
          ..write('bodyType: $bodyType, ')
          ..write('level: $level, ')
          ..write('equipmentProfile: $equipmentProfile, ')
          ..write('sessionsPerWeek: $sessionsPerWeek, ')
          ..write('durationWeeks: $durationWeeks, ')
          ..write('restDayMode: $restDayMode, ')
          ..write('trainingDaysMask: $trainingDaysMask, ')
          ..write('sessionDurationMinutes: $sessionDurationMinutes, ')
          ..write('createdEpochDay: $createdEpochDay, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES goals (id) ON DELETE CASCADE'));
  static const VerificationMeta _sequenceIndexMeta =
      const VerificationMeta('sequenceIndex');
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
      'sequence_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleViMeta =
      const VerificationMeta('titleVi');
  @override
  late final GeneratedColumn<String> titleVi = GeneratedColumn<String>(
      'title_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _focusViMeta =
      const VerificationMeta('focusVi');
  @override
  late final GeneratedColumn<String> focusVi = GeneratedColumn<String>(
      'focus_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _estimatedMinutesMeta =
      const VerificationMeta('estimatedMinutes');
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
      'estimated_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dueEpochDayMeta =
      const VerificationMeta('dueEpochDay');
  @override
  late final GeneratedColumn<int> dueEpochDay = GeneratedColumn<int>(
      'due_epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedEpochDayMeta =
      const VerificationMeta('completedEpochDay');
  @override
  late final GeneratedColumn<int> completedEpochDay = GeneratedColumn<int>(
      'completed_epoch_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _volumeScalePercentMeta =
      const VerificationMeta('volumeScalePercent');
  @override
  late final GeneratedColumn<int> volumeScalePercent = GeneratedColumn<int>(
      'volume_scale_percent', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _selectedTimeBudgetMinutesMeta =
      const VerificationMeta('selectedTimeBudgetMinutes');
  @override
  late final GeneratedColumn<int> selectedTimeBudgetMinutes =
      GeneratedColumn<int>('selected_time_budget_minutes', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        goalId,
        sequenceIndex,
        titleVi,
        focusVi,
        estimatedMinutes,
        dueEpochDay,
        completedEpochDay,
        volumeScalePercent,
        selectedTimeBudgetMinutes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
          _sequenceIndexMeta,
          sequenceIndex.isAcceptableOrUnknown(
              data['sequence_index']!, _sequenceIndexMeta));
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    if (data.containsKey('title_vi')) {
      context.handle(_titleViMeta,
          titleVi.isAcceptableOrUnknown(data['title_vi']!, _titleViMeta));
    } else if (isInserting) {
      context.missing(_titleViMeta);
    }
    if (data.containsKey('focus_vi')) {
      context.handle(_focusViMeta,
          focusVi.isAcceptableOrUnknown(data['focus_vi']!, _focusViMeta));
    } else if (isInserting) {
      context.missing(_focusViMeta);
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
          _estimatedMinutesMeta,
          estimatedMinutes.isAcceptableOrUnknown(
              data['estimated_minutes']!, _estimatedMinutesMeta));
    } else if (isInserting) {
      context.missing(_estimatedMinutesMeta);
    }
    if (data.containsKey('due_epoch_day')) {
      context.handle(
          _dueEpochDayMeta,
          dueEpochDay.isAcceptableOrUnknown(
              data['due_epoch_day']!, _dueEpochDayMeta));
    } else if (isInserting) {
      context.missing(_dueEpochDayMeta);
    }
    if (data.containsKey('completed_epoch_day')) {
      context.handle(
          _completedEpochDayMeta,
          completedEpochDay.isAcceptableOrUnknown(
              data['completed_epoch_day']!, _completedEpochDayMeta));
    }
    if (data.containsKey('volume_scale_percent')) {
      context.handle(
          _volumeScalePercentMeta,
          volumeScalePercent.isAcceptableOrUnknown(
              data['volume_scale_percent']!, _volumeScalePercentMeta));
    }
    if (data.containsKey('selected_time_budget_minutes')) {
      context.handle(
          _selectedTimeBudgetMinutesMeta,
          selectedTimeBudgetMinutes.isAcceptableOrUnknown(
              data['selected_time_budget_minutes']!,
              _selectedTimeBudgetMinutesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {goalId, sequenceIndex},
      ];
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}goal_id'])!,
      sequenceIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence_index'])!,
      titleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_vi'])!,
      focusVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}focus_vi'])!,
      estimatedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estimated_minutes'])!,
      dueEpochDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_epoch_day'])!,
      completedEpochDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_epoch_day']),
      volumeScalePercent: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}volume_scale_percent'])!,
      selectedTimeBudgetMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}selected_time_budget_minutes']),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final int goalId;
  final int sequenceIndex;
  final String titleVi;
  final String focusVi;
  final int estimatedMinutes;
  final int dueEpochDay;
  final int? completedEpochDay;
  final int volumeScalePercent;
  final int? selectedTimeBudgetMinutes;
  const WorkoutSession(
      {required this.id,
      required this.goalId,
      required this.sequenceIndex,
      required this.titleVi,
      required this.focusVi,
      required this.estimatedMinutes,
      required this.dueEpochDay,
      this.completedEpochDay,
      required this.volumeScalePercent,
      this.selectedTimeBudgetMinutes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    map['title_vi'] = Variable<String>(titleVi);
    map['focus_vi'] = Variable<String>(focusVi);
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    map['due_epoch_day'] = Variable<int>(dueEpochDay);
    if (!nullToAbsent || completedEpochDay != null) {
      map['completed_epoch_day'] = Variable<int>(completedEpochDay);
    }
    map['volume_scale_percent'] = Variable<int>(volumeScalePercent);
    if (!nullToAbsent || selectedTimeBudgetMinutes != null) {
      map['selected_time_budget_minutes'] =
          Variable<int>(selectedTimeBudgetMinutes);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      sequenceIndex: Value(sequenceIndex),
      titleVi: Value(titleVi),
      focusVi: Value(focusVi),
      estimatedMinutes: Value(estimatedMinutes),
      dueEpochDay: Value(dueEpochDay),
      completedEpochDay: completedEpochDay == null && nullToAbsent
          ? const Value.absent()
          : Value(completedEpochDay),
      volumeScalePercent: Value(volumeScalePercent),
      selectedTimeBudgetMinutes:
          selectedTimeBudgetMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(selectedTimeBudgetMinutes),
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
      titleVi: serializer.fromJson<String>(json['titleVi']),
      focusVi: serializer.fromJson<String>(json['focusVi']),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
      dueEpochDay: serializer.fromJson<int>(json['dueEpochDay']),
      completedEpochDay: serializer.fromJson<int?>(json['completedEpochDay']),
      volumeScalePercent: serializer.fromJson<int>(json['volumeScalePercent']),
      selectedTimeBudgetMinutes:
          serializer.fromJson<int?>(json['selectedTimeBudgetMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
      'titleVi': serializer.toJson<String>(titleVi),
      'focusVi': serializer.toJson<String>(focusVi),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
      'dueEpochDay': serializer.toJson<int>(dueEpochDay),
      'completedEpochDay': serializer.toJson<int?>(completedEpochDay),
      'volumeScalePercent': serializer.toJson<int>(volumeScalePercent),
      'selectedTimeBudgetMinutes':
          serializer.toJson<int?>(selectedTimeBudgetMinutes),
    };
  }

  WorkoutSession copyWith(
          {int? id,
          int? goalId,
          int? sequenceIndex,
          String? titleVi,
          String? focusVi,
          int? estimatedMinutes,
          int? dueEpochDay,
          Value<int?> completedEpochDay = const Value.absent(),
          int? volumeScalePercent,
          Value<int?> selectedTimeBudgetMinutes = const Value.absent()}) =>
      WorkoutSession(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        sequenceIndex: sequenceIndex ?? this.sequenceIndex,
        titleVi: titleVi ?? this.titleVi,
        focusVi: focusVi ?? this.focusVi,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        dueEpochDay: dueEpochDay ?? this.dueEpochDay,
        completedEpochDay: completedEpochDay.present
            ? completedEpochDay.value
            : this.completedEpochDay,
        volumeScalePercent: volumeScalePercent ?? this.volumeScalePercent,
        selectedTimeBudgetMinutes: selectedTimeBudgetMinutes.present
            ? selectedTimeBudgetMinutes.value
            : this.selectedTimeBudgetMinutes,
      );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
      titleVi: data.titleVi.present ? data.titleVi.value : this.titleVi,
      focusVi: data.focusVi.present ? data.focusVi.value : this.focusVi,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      dueEpochDay:
          data.dueEpochDay.present ? data.dueEpochDay.value : this.dueEpochDay,
      completedEpochDay: data.completedEpochDay.present
          ? data.completedEpochDay.value
          : this.completedEpochDay,
      volumeScalePercent: data.volumeScalePercent.present
          ? data.volumeScalePercent.value
          : this.volumeScalePercent,
      selectedTimeBudgetMinutes: data.selectedTimeBudgetMinutes.present
          ? data.selectedTimeBudgetMinutes.value
          : this.selectedTimeBudgetMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('titleVi: $titleVi, ')
          ..write('focusVi: $focusVi, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('dueEpochDay: $dueEpochDay, ')
          ..write('completedEpochDay: $completedEpochDay, ')
          ..write('volumeScalePercent: $volumeScalePercent, ')
          ..write('selectedTimeBudgetMinutes: $selectedTimeBudgetMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      goalId,
      sequenceIndex,
      titleVi,
      focusVi,
      estimatedMinutes,
      dueEpochDay,
      completedEpochDay,
      volumeScalePercent,
      selectedTimeBudgetMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.sequenceIndex == this.sequenceIndex &&
          other.titleVi == this.titleVi &&
          other.focusVi == this.focusVi &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.dueEpochDay == this.dueEpochDay &&
          other.completedEpochDay == this.completedEpochDay &&
          other.volumeScalePercent == this.volumeScalePercent &&
          other.selectedTimeBudgetMinutes == this.selectedTimeBudgetMinutes);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<int> sequenceIndex;
  final Value<String> titleVi;
  final Value<String> focusVi;
  final Value<int> estimatedMinutes;
  final Value<int> dueEpochDay;
  final Value<int?> completedEpochDay;
  final Value<int> volumeScalePercent;
  final Value<int?> selectedTimeBudgetMinutes;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
    this.titleVi = const Value.absent(),
    this.focusVi = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.dueEpochDay = const Value.absent(),
    this.completedEpochDay = const Value.absent(),
    this.volumeScalePercent = const Value.absent(),
    this.selectedTimeBudgetMinutes = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required int sequenceIndex,
    required String titleVi,
    required String focusVi,
    required int estimatedMinutes,
    required int dueEpochDay,
    this.completedEpochDay = const Value.absent(),
    this.volumeScalePercent = const Value.absent(),
    this.selectedTimeBudgetMinutes = const Value.absent(),
  })  : goalId = Value(goalId),
        sequenceIndex = Value(sequenceIndex),
        titleVi = Value(titleVi),
        focusVi = Value(focusVi),
        estimatedMinutes = Value(estimatedMinutes),
        dueEpochDay = Value(dueEpochDay);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<int>? sequenceIndex,
    Expression<String>? titleVi,
    Expression<String>? focusVi,
    Expression<int>? estimatedMinutes,
    Expression<int>? dueEpochDay,
    Expression<int>? completedEpochDay,
    Expression<int>? volumeScalePercent,
    Expression<int>? selectedTimeBudgetMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
      if (titleVi != null) 'title_vi': titleVi,
      if (focusVi != null) 'focus_vi': focusVi,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (dueEpochDay != null) 'due_epoch_day': dueEpochDay,
      if (completedEpochDay != null) 'completed_epoch_day': completedEpochDay,
      if (volumeScalePercent != null)
        'volume_scale_percent': volumeScalePercent,
      if (selectedTimeBudgetMinutes != null)
        'selected_time_budget_minutes': selectedTimeBudgetMinutes,
    });
  }

  WorkoutSessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? goalId,
      Value<int>? sequenceIndex,
      Value<String>? titleVi,
      Value<String>? focusVi,
      Value<int>? estimatedMinutes,
      Value<int>? dueEpochDay,
      Value<int?>? completedEpochDay,
      Value<int>? volumeScalePercent,
      Value<int?>? selectedTimeBudgetMinutes}) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      titleVi: titleVi ?? this.titleVi,
      focusVi: focusVi ?? this.focusVi,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueEpochDay: dueEpochDay ?? this.dueEpochDay,
      completedEpochDay: completedEpochDay ?? this.completedEpochDay,
      volumeScalePercent: volumeScalePercent ?? this.volumeScalePercent,
      selectedTimeBudgetMinutes:
          selectedTimeBudgetMinutes ?? this.selectedTimeBudgetMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    if (titleVi.present) {
      map['title_vi'] = Variable<String>(titleVi.value);
    }
    if (focusVi.present) {
      map['focus_vi'] = Variable<String>(focusVi.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (dueEpochDay.present) {
      map['due_epoch_day'] = Variable<int>(dueEpochDay.value);
    }
    if (completedEpochDay.present) {
      map['completed_epoch_day'] = Variable<int>(completedEpochDay.value);
    }
    if (volumeScalePercent.present) {
      map['volume_scale_percent'] = Variable<int>(volumeScalePercent.value);
    }
    if (selectedTimeBudgetMinutes.present) {
      map['selected_time_budget_minutes'] =
          Variable<int>(selectedTimeBudgetMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('titleVi: $titleVi, ')
          ..write('focusVi: $focusVi, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('dueEpochDay: $dueEpochDay, ')
          ..write('completedEpochDay: $completedEpochDay, ')
          ..write('volumeScalePercent: $volumeScalePercent, ')
          ..write('selectedTimeBudgetMinutes: $selectedTimeBudgetMinutes')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_sessions (id) ON DELETE CASCADE'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalExerciseIdMeta =
      const VerificationMeta('originalExerciseId');
  @override
  late final GeneratedColumn<String> originalExerciseId =
      GeneratedColumn<String>('original_exercise_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
      'sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minRepsMeta =
      const VerificationMeta('minReps');
  @override
  late final GeneratedColumn<int> minReps = GeneratedColumn<int>(
      'min_reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxRepsMeta =
      const VerificationMeta('maxReps');
  @override
  late final GeneratedColumn<int> maxReps = GeneratedColumn<int>(
      'max_reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _restSecondsMeta =
      const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
      'rest_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isCheckedMeta =
      const VerificationMeta('isChecked');
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
      'is_checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _omittedByTimeBudgetMeta =
      const VerificationMeta('omittedByTimeBudget');
  @override
  late final GeneratedColumn<bool> omittedByTimeBudget = GeneratedColumn<bool>(
      'omitted_by_time_budget', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("omitted_by_time_budget" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        orderIndex,
        exerciseId,
        originalExerciseId,
        sets,
        minReps,
        maxReps,
        durationSeconds,
        restSeconds,
        isChecked,
        omittedByTimeBudget
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<SessionExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('original_exercise_id')) {
      context.handle(
          _originalExerciseIdMeta,
          originalExerciseId.isAcceptableOrUnknown(
              data['original_exercise_id']!, _originalExerciseIdMeta));
    }
    if (data.containsKey('sets')) {
      context.handle(
          _setsMeta, sets.isAcceptableOrUnknown(data['sets']!, _setsMeta));
    } else if (isInserting) {
      context.missing(_setsMeta);
    }
    if (data.containsKey('min_reps')) {
      context.handle(_minRepsMeta,
          minReps.isAcceptableOrUnknown(data['min_reps']!, _minRepsMeta));
    }
    if (data.containsKey('max_reps')) {
      context.handle(_maxRepsMeta,
          maxReps.isAcceptableOrUnknown(data['max_reps']!, _maxRepsMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
          _restSecondsMeta,
          restSeconds.isAcceptableOrUnknown(
              data['rest_seconds']!, _restSecondsMeta));
    } else if (isInserting) {
      context.missing(_restSecondsMeta);
    }
    if (data.containsKey('is_checked')) {
      context.handle(_isCheckedMeta,
          isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta));
    }
    if (data.containsKey('omitted_by_time_budget')) {
      context.handle(
          _omittedByTimeBudgetMeta,
          omittedByTimeBudget.isAcceptableOrUnknown(
              data['omitted_by_time_budget']!, _omittedByTimeBudgetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, orderIndex};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      originalExerciseId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_exercise_id']),
      sets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sets'])!,
      minReps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_reps']),
      maxReps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_reps']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      restSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_seconds'])!,
      isChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_checked'])!,
      omittedByTimeBudget: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}omitted_by_time_budget'])!,
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final int sessionId;
  final int orderIndex;
  final String exerciseId;
  final String? originalExerciseId;
  final int sets;
  final int? minReps;
  final int? maxReps;
  final int? durationSeconds;
  final int restSeconds;
  final bool isChecked;
  final bool omittedByTimeBudget;
  const SessionExercise(
      {required this.sessionId,
      required this.orderIndex,
      required this.exerciseId,
      this.originalExerciseId,
      required this.sets,
      this.minReps,
      this.maxReps,
      this.durationSeconds,
      required this.restSeconds,
      required this.isChecked,
      required this.omittedByTimeBudget});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['order_index'] = Variable<int>(orderIndex);
    map['exercise_id'] = Variable<String>(exerciseId);
    if (!nullToAbsent || originalExerciseId != null) {
      map['original_exercise_id'] = Variable<String>(originalExerciseId);
    }
    map['sets'] = Variable<int>(sets);
    if (!nullToAbsent || minReps != null) {
      map['min_reps'] = Variable<int>(minReps);
    }
    if (!nullToAbsent || maxReps != null) {
      map['max_reps'] = Variable<int>(maxReps);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['rest_seconds'] = Variable<int>(restSeconds);
    map['is_checked'] = Variable<bool>(isChecked);
    map['omitted_by_time_budget'] = Variable<bool>(omittedByTimeBudget);
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      sessionId: Value(sessionId),
      orderIndex: Value(orderIndex),
      exerciseId: Value(exerciseId),
      originalExerciseId: originalExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalExerciseId),
      sets: Value(sets),
      minReps: minReps == null && nullToAbsent
          ? const Value.absent()
          : Value(minReps),
      maxReps: maxReps == null && nullToAbsent
          ? const Value.absent()
          : Value(maxReps),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      restSeconds: Value(restSeconds),
      isChecked: Value(isChecked),
      omittedByTimeBudget: Value(omittedByTimeBudget),
    );
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      originalExerciseId:
          serializer.fromJson<String?>(json['originalExerciseId']),
      sets: serializer.fromJson<int>(json['sets']),
      minReps: serializer.fromJson<int?>(json['minReps']),
      maxReps: serializer.fromJson<int?>(json['maxReps']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      omittedByTimeBudget:
          serializer.fromJson<bool>(json['omittedByTimeBudget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'originalExerciseId': serializer.toJson<String?>(originalExerciseId),
      'sets': serializer.toJson<int>(sets),
      'minReps': serializer.toJson<int?>(minReps),
      'maxReps': serializer.toJson<int?>(maxReps),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'isChecked': serializer.toJson<bool>(isChecked),
      'omittedByTimeBudget': serializer.toJson<bool>(omittedByTimeBudget),
    };
  }

  SessionExercise copyWith(
          {int? sessionId,
          int? orderIndex,
          String? exerciseId,
          Value<String?> originalExerciseId = const Value.absent(),
          int? sets,
          Value<int?> minReps = const Value.absent(),
          Value<int?> maxReps = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          int? restSeconds,
          bool? isChecked,
          bool? omittedByTimeBudget}) =>
      SessionExercise(
        sessionId: sessionId ?? this.sessionId,
        orderIndex: orderIndex ?? this.orderIndex,
        exerciseId: exerciseId ?? this.exerciseId,
        originalExerciseId: originalExerciseId.present
            ? originalExerciseId.value
            : this.originalExerciseId,
        sets: sets ?? this.sets,
        minReps: minReps.present ? minReps.value : this.minReps,
        maxReps: maxReps.present ? maxReps.value : this.maxReps,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        isChecked: isChecked ?? this.isChecked,
        omittedByTimeBudget: omittedByTimeBudget ?? this.omittedByTimeBudget,
      );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      originalExerciseId: data.originalExerciseId.present
          ? data.originalExerciseId.value
          : this.originalExerciseId,
      sets: data.sets.present ? data.sets.value : this.sets,
      minReps: data.minReps.present ? data.minReps.value : this.minReps,
      maxReps: data.maxReps.present ? data.maxReps.value : this.maxReps,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      restSeconds:
          data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      omittedByTimeBudget: data.omittedByTimeBudget.present
          ? data.omittedByTimeBudget.value
          : this.omittedByTimeBudget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('sessionId: $sessionId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('originalExerciseId: $originalExerciseId, ')
          ..write('sets: $sets, ')
          ..write('minReps: $minReps, ')
          ..write('maxReps: $maxReps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isChecked: $isChecked, ')
          ..write('omittedByTimeBudget: $omittedByTimeBudget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId,
      orderIndex,
      exerciseId,
      originalExerciseId,
      sets,
      minReps,
      maxReps,
      durationSeconds,
      restSeconds,
      isChecked,
      omittedByTimeBudget);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.sessionId == this.sessionId &&
          other.orderIndex == this.orderIndex &&
          other.exerciseId == this.exerciseId &&
          other.originalExerciseId == this.originalExerciseId &&
          other.sets == this.sets &&
          other.minReps == this.minReps &&
          other.maxReps == this.maxReps &&
          other.durationSeconds == this.durationSeconds &&
          other.restSeconds == this.restSeconds &&
          other.isChecked == this.isChecked &&
          other.omittedByTimeBudget == this.omittedByTimeBudget);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<int> sessionId;
  final Value<int> orderIndex;
  final Value<String> exerciseId;
  final Value<String?> originalExerciseId;
  final Value<int> sets;
  final Value<int?> minReps;
  final Value<int?> maxReps;
  final Value<int?> durationSeconds;
  final Value<int> restSeconds;
  final Value<bool> isChecked;
  final Value<bool> omittedByTimeBudget;
  final Value<int> rowid;
  const SessionExercisesCompanion({
    this.sessionId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.originalExerciseId = const Value.absent(),
    this.sets = const Value.absent(),
    this.minReps = const Value.absent(),
    this.maxReps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.omittedByTimeBudget = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    required int sessionId,
    required int orderIndex,
    required String exerciseId,
    this.originalExerciseId = const Value.absent(),
    required int sets,
    this.minReps = const Value.absent(),
    this.maxReps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required int restSeconds,
    this.isChecked = const Value.absent(),
    this.omittedByTimeBudget = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        orderIndex = Value(orderIndex),
        exerciseId = Value(exerciseId),
        sets = Value(sets),
        restSeconds = Value(restSeconds);
  static Insertable<SessionExercise> custom({
    Expression<int>? sessionId,
    Expression<int>? orderIndex,
    Expression<String>? exerciseId,
    Expression<String>? originalExerciseId,
    Expression<int>? sets,
    Expression<int>? minReps,
    Expression<int>? maxReps,
    Expression<int>? durationSeconds,
    Expression<int>? restSeconds,
    Expression<bool>? isChecked,
    Expression<bool>? omittedByTimeBudget,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (originalExerciseId != null)
        'original_exercise_id': originalExerciseId,
      if (sets != null) 'sets': sets,
      if (minReps != null) 'min_reps': minReps,
      if (maxReps != null) 'max_reps': maxReps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (isChecked != null) 'is_checked': isChecked,
      if (omittedByTimeBudget != null)
        'omitted_by_time_budget': omittedByTimeBudget,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionExercisesCompanion copyWith(
      {Value<int>? sessionId,
      Value<int>? orderIndex,
      Value<String>? exerciseId,
      Value<String?>? originalExerciseId,
      Value<int>? sets,
      Value<int?>? minReps,
      Value<int?>? maxReps,
      Value<int?>? durationSeconds,
      Value<int>? restSeconds,
      Value<bool>? isChecked,
      Value<bool>? omittedByTimeBudget,
      Value<int>? rowid}) {
    return SessionExercisesCompanion(
      sessionId: sessionId ?? this.sessionId,
      orderIndex: orderIndex ?? this.orderIndex,
      exerciseId: exerciseId ?? this.exerciseId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      sets: sets ?? this.sets,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      isChecked: isChecked ?? this.isChecked,
      omittedByTimeBudget: omittedByTimeBudget ?? this.omittedByTimeBudget,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (originalExerciseId.present) {
      map['original_exercise_id'] = Variable<String>(originalExerciseId.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (minReps.present) {
      map['min_reps'] = Variable<int>(minReps.value);
    }
    if (maxReps.present) {
      map['max_reps'] = Variable<int>(maxReps.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (omittedByTimeBudget.present) {
      map['omitted_by_time_budget'] = Variable<bool>(omittedByTimeBudget.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('originalExerciseId: $originalExerciseId, ')
          ..write('sets: $sets, ')
          ..write('minReps: $minReps, ')
          ..write('maxReps: $maxReps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isChecked: $isChecked, ')
          ..write('omittedByTimeBudget: $omittedByTimeBudget, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalProfilesTable extends PersonalProfiles
    with TableInfo<$PersonalProfilesTable, PersonalProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _birthDateEpochDayMeta =
      const VerificationMeta('birthDateEpochDay');
  @override
  late final GeneratedColumn<int> birthDateEpochDay = GeneratedColumn<int>(
      'birth_date_epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<MetabolicSex, String>
      metabolicSex = GeneratedColumn<String>(
              'metabolic_sex', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MetabolicSex>(
              $PersonalProfilesTable.$convertermetabolicSex);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentWeightKgMeta =
      const VerificationMeta('currentWeightKg');
  @override
  late final GeneratedColumn<double> currentWeightKg = GeneratedColumn<double>(
      'current_weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _targetWeightKgMeta =
      const VerificationMeta('targetWeightKg');
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
      'target_weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, String>
      activityLevel = GeneratedColumn<String>(
              'activity_level', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ActivityLevel>(
              $PersonalProfilesTable.$converteractivityLevel);
  @override
  late final GeneratedColumnWithTypeConverter<GoalPace, String> goalPace =
      GeneratedColumn<String>('goal_pace', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<GoalPace>($PersonalProfilesTable.$convertergoalPace);
  static const VerificationMeta _personalizationConsentMeta =
      const VerificationMeta('personalizationConsent');
  @override
  late final GeneratedColumn<bool> personalizationConsent =
      GeneratedColumn<bool>('personalization_consent', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("personalization_consent" IN (0, 1))'));
  static const VerificationMeta _cloudAiConsentMeta =
      const VerificationMeta('cloudAiConsent');
  @override
  late final GeneratedColumn<bool> cloudAiConsent = GeneratedColumn<bool>(
      'cloud_ai_consent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("cloud_ai_consent" IN (0, 1))'));
  static const VerificationMeta _updatedAtEpochMillisMeta =
      const VerificationMeta('updatedAtEpochMillis');
  @override
  late final GeneratedColumn<int> updatedAtEpochMillis = GeneratedColumn<int>(
      'updated_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        birthDateEpochDay,
        metabolicSex,
        heightCm,
        currentWeightKg,
        targetWeightKg,
        activityLevel,
        goalPace,
        personalizationConsent,
        cloudAiConsent,
        updatedAtEpochMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<PersonalProfileData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('birth_date_epoch_day')) {
      context.handle(
          _birthDateEpochDayMeta,
          birthDateEpochDay.isAcceptableOrUnknown(
              data['birth_date_epoch_day']!, _birthDateEpochDayMeta));
    } else if (isInserting) {
      context.missing(_birthDateEpochDayMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('current_weight_kg')) {
      context.handle(
          _currentWeightKgMeta,
          currentWeightKg.isAcceptableOrUnknown(
              data['current_weight_kg']!, _currentWeightKgMeta));
    } else if (isInserting) {
      context.missing(_currentWeightKgMeta);
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
          _targetWeightKgMeta,
          targetWeightKg.isAcceptableOrUnknown(
              data['target_weight_kg']!, _targetWeightKgMeta));
    } else if (isInserting) {
      context.missing(_targetWeightKgMeta);
    }
    if (data.containsKey('personalization_consent')) {
      context.handle(
          _personalizationConsentMeta,
          personalizationConsent.isAcceptableOrUnknown(
              data['personalization_consent']!, _personalizationConsentMeta));
    } else if (isInserting) {
      context.missing(_personalizationConsentMeta);
    }
    if (data.containsKey('cloud_ai_consent')) {
      context.handle(
          _cloudAiConsentMeta,
          cloudAiConsent.isAcceptableOrUnknown(
              data['cloud_ai_consent']!, _cloudAiConsentMeta));
    } else if (isInserting) {
      context.missing(_cloudAiConsentMeta);
    }
    if (data.containsKey('updated_at_epoch_millis')) {
      context.handle(
          _updatedAtEpochMillisMeta,
          updatedAtEpochMillis.isAcceptableOrUnknown(
              data['updated_at_epoch_millis']!, _updatedAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_updatedAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalProfileData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      birthDateEpochDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}birth_date_epoch_day'])!,
      metabolicSex: $PersonalProfilesTable.$convertermetabolicSex.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}metabolic_sex'])!),
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm'])!,
      currentWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_weight_kg'])!,
      targetWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_weight_kg'])!,
      activityLevel: $PersonalProfilesTable.$converteractivityLevel.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}activity_level'])!),
      goalPace: $PersonalProfilesTable.$convertergoalPace.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}goal_pace'])!),
      personalizationConsent: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}personalization_consent'])!,
      cloudAiConsent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}cloud_ai_consent'])!,
      updatedAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}updated_at_epoch_millis'])!,
    );
  }

  @override
  $PersonalProfilesTable createAlias(String alias) {
    return $PersonalProfilesTable(attachedDatabase, alias);
  }

  static TypeConverter<MetabolicSex, String> $convertermetabolicSex =
      const MetabolicSexConverter();
  static TypeConverter<ActivityLevel, String> $converteractivityLevel =
      const ActivityLevelConverter();
  static TypeConverter<GoalPace, String> $convertergoalPace =
      const GoalPaceConverter();
}

class PersonalProfileData extends DataClass
    implements Insertable<PersonalProfileData> {
  final int id;
  final int birthDateEpochDay;
  final MetabolicSex metabolicSex;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
  final GoalPace goalPace;
  final bool personalizationConsent;
  final bool cloudAiConsent;
  final int updatedAtEpochMillis;
  const PersonalProfileData(
      {required this.id,
      required this.birthDateEpochDay,
      required this.metabolicSex,
      required this.heightCm,
      required this.currentWeightKg,
      required this.targetWeightKg,
      required this.activityLevel,
      required this.goalPace,
      required this.personalizationConsent,
      required this.cloudAiConsent,
      required this.updatedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['birth_date_epoch_day'] = Variable<int>(birthDateEpochDay);
    {
      map['metabolic_sex'] = Variable<String>(
          $PersonalProfilesTable.$convertermetabolicSex.toSql(metabolicSex));
    }
    map['height_cm'] = Variable<double>(heightCm);
    map['current_weight_kg'] = Variable<double>(currentWeightKg);
    map['target_weight_kg'] = Variable<double>(targetWeightKg);
    {
      map['activity_level'] = Variable<String>(
          $PersonalProfilesTable.$converteractivityLevel.toSql(activityLevel));
    }
    {
      map['goal_pace'] = Variable<String>(
          $PersonalProfilesTable.$convertergoalPace.toSql(goalPace));
    }
    map['personalization_consent'] = Variable<bool>(personalizationConsent);
    map['cloud_ai_consent'] = Variable<bool>(cloudAiConsent);
    map['updated_at_epoch_millis'] = Variable<int>(updatedAtEpochMillis);
    return map;
  }

  PersonalProfilesCompanion toCompanion(bool nullToAbsent) {
    return PersonalProfilesCompanion(
      id: Value(id),
      birthDateEpochDay: Value(birthDateEpochDay),
      metabolicSex: Value(metabolicSex),
      heightCm: Value(heightCm),
      currentWeightKg: Value(currentWeightKg),
      targetWeightKg: Value(targetWeightKg),
      activityLevel: Value(activityLevel),
      goalPace: Value(goalPace),
      personalizationConsent: Value(personalizationConsent),
      cloudAiConsent: Value(cloudAiConsent),
      updatedAtEpochMillis: Value(updatedAtEpochMillis),
    );
  }

  factory PersonalProfileData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalProfileData(
      id: serializer.fromJson<int>(json['id']),
      birthDateEpochDay: serializer.fromJson<int>(json['birthDateEpochDay']),
      metabolicSex: serializer.fromJson<MetabolicSex>(json['metabolicSex']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      currentWeightKg: serializer.fromJson<double>(json['currentWeightKg']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      activityLevel: serializer.fromJson<ActivityLevel>(json['activityLevel']),
      goalPace: serializer.fromJson<GoalPace>(json['goalPace']),
      personalizationConsent:
          serializer.fromJson<bool>(json['personalizationConsent']),
      cloudAiConsent: serializer.fromJson<bool>(json['cloudAiConsent']),
      updatedAtEpochMillis:
          serializer.fromJson<int>(json['updatedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'birthDateEpochDay': serializer.toJson<int>(birthDateEpochDay),
      'metabolicSex': serializer.toJson<MetabolicSex>(metabolicSex),
      'heightCm': serializer.toJson<double>(heightCm),
      'currentWeightKg': serializer.toJson<double>(currentWeightKg),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'activityLevel': serializer.toJson<ActivityLevel>(activityLevel),
      'goalPace': serializer.toJson<GoalPace>(goalPace),
      'personalizationConsent': serializer.toJson<bool>(personalizationConsent),
      'cloudAiConsent': serializer.toJson<bool>(cloudAiConsent),
      'updatedAtEpochMillis': serializer.toJson<int>(updatedAtEpochMillis),
    };
  }

  PersonalProfileData copyWith(
          {int? id,
          int? birthDateEpochDay,
          MetabolicSex? metabolicSex,
          double? heightCm,
          double? currentWeightKg,
          double? targetWeightKg,
          ActivityLevel? activityLevel,
          GoalPace? goalPace,
          bool? personalizationConsent,
          bool? cloudAiConsent,
          int? updatedAtEpochMillis}) =>
      PersonalProfileData(
        id: id ?? this.id,
        birthDateEpochDay: birthDateEpochDay ?? this.birthDateEpochDay,
        metabolicSex: metabolicSex ?? this.metabolicSex,
        heightCm: heightCm ?? this.heightCm,
        currentWeightKg: currentWeightKg ?? this.currentWeightKg,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goalPace: goalPace ?? this.goalPace,
        personalizationConsent:
            personalizationConsent ?? this.personalizationConsent,
        cloudAiConsent: cloudAiConsent ?? this.cloudAiConsent,
        updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
      );
  PersonalProfileData copyWithCompanion(PersonalProfilesCompanion data) {
    return PersonalProfileData(
      id: data.id.present ? data.id.value : this.id,
      birthDateEpochDay: data.birthDateEpochDay.present
          ? data.birthDateEpochDay.value
          : this.birthDateEpochDay,
      metabolicSex: data.metabolicSex.present
          ? data.metabolicSex.value
          : this.metabolicSex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      currentWeightKg: data.currentWeightKg.present
          ? data.currentWeightKg.value
          : this.currentWeightKg,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      goalPace: data.goalPace.present ? data.goalPace.value : this.goalPace,
      personalizationConsent: data.personalizationConsent.present
          ? data.personalizationConsent.value
          : this.personalizationConsent,
      cloudAiConsent: data.cloudAiConsent.present
          ? data.cloudAiConsent.value
          : this.cloudAiConsent,
      updatedAtEpochMillis: data.updatedAtEpochMillis.present
          ? data.updatedAtEpochMillis.value
          : this.updatedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProfileData(')
          ..write('id: $id, ')
          ..write('birthDateEpochDay: $birthDateEpochDay, ')
          ..write('metabolicSex: $metabolicSex, ')
          ..write('heightCm: $heightCm, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('goalPace: $goalPace, ')
          ..write('personalizationConsent: $personalizationConsent, ')
          ..write('cloudAiConsent: $cloudAiConsent, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      birthDateEpochDay,
      metabolicSex,
      heightCm,
      currentWeightKg,
      targetWeightKg,
      activityLevel,
      goalPace,
      personalizationConsent,
      cloudAiConsent,
      updatedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalProfileData &&
          other.id == this.id &&
          other.birthDateEpochDay == this.birthDateEpochDay &&
          other.metabolicSex == this.metabolicSex &&
          other.heightCm == this.heightCm &&
          other.currentWeightKg == this.currentWeightKg &&
          other.targetWeightKg == this.targetWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.goalPace == this.goalPace &&
          other.personalizationConsent == this.personalizationConsent &&
          other.cloudAiConsent == this.cloudAiConsent &&
          other.updatedAtEpochMillis == this.updatedAtEpochMillis);
}

class PersonalProfilesCompanion extends UpdateCompanion<PersonalProfileData> {
  final Value<int> id;
  final Value<int> birthDateEpochDay;
  final Value<MetabolicSex> metabolicSex;
  final Value<double> heightCm;
  final Value<double> currentWeightKg;
  final Value<double> targetWeightKg;
  final Value<ActivityLevel> activityLevel;
  final Value<GoalPace> goalPace;
  final Value<bool> personalizationConsent;
  final Value<bool> cloudAiConsent;
  final Value<int> updatedAtEpochMillis;
  const PersonalProfilesCompanion({
    this.id = const Value.absent(),
    this.birthDateEpochDay = const Value.absent(),
    this.metabolicSex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.currentWeightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.goalPace = const Value.absent(),
    this.personalizationConsent = const Value.absent(),
    this.cloudAiConsent = const Value.absent(),
    this.updatedAtEpochMillis = const Value.absent(),
  });
  PersonalProfilesCompanion.insert({
    this.id = const Value.absent(),
    required int birthDateEpochDay,
    required MetabolicSex metabolicSex,
    required double heightCm,
    required double currentWeightKg,
    required double targetWeightKg,
    required ActivityLevel activityLevel,
    required GoalPace goalPace,
    required bool personalizationConsent,
    required bool cloudAiConsent,
    required int updatedAtEpochMillis,
  })  : birthDateEpochDay = Value(birthDateEpochDay),
        metabolicSex = Value(metabolicSex),
        heightCm = Value(heightCm),
        currentWeightKg = Value(currentWeightKg),
        targetWeightKg = Value(targetWeightKg),
        activityLevel = Value(activityLevel),
        goalPace = Value(goalPace),
        personalizationConsent = Value(personalizationConsent),
        cloudAiConsent = Value(cloudAiConsent),
        updatedAtEpochMillis = Value(updatedAtEpochMillis);
  static Insertable<PersonalProfileData> custom({
    Expression<int>? id,
    Expression<int>? birthDateEpochDay,
    Expression<String>? metabolicSex,
    Expression<double>? heightCm,
    Expression<double>? currentWeightKg,
    Expression<double>? targetWeightKg,
    Expression<String>? activityLevel,
    Expression<String>? goalPace,
    Expression<bool>? personalizationConsent,
    Expression<bool>? cloudAiConsent,
    Expression<int>? updatedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birthDateEpochDay != null) 'birth_date_epoch_day': birthDateEpochDay,
      if (metabolicSex != null) 'metabolic_sex': metabolicSex,
      if (heightCm != null) 'height_cm': heightCm,
      if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goalPace != null) 'goal_pace': goalPace,
      if (personalizationConsent != null)
        'personalization_consent': personalizationConsent,
      if (cloudAiConsent != null) 'cloud_ai_consent': cloudAiConsent,
      if (updatedAtEpochMillis != null)
        'updated_at_epoch_millis': updatedAtEpochMillis,
    });
  }

  PersonalProfilesCompanion copyWith(
      {Value<int>? id,
      Value<int>? birthDateEpochDay,
      Value<MetabolicSex>? metabolicSex,
      Value<double>? heightCm,
      Value<double>? currentWeightKg,
      Value<double>? targetWeightKg,
      Value<ActivityLevel>? activityLevel,
      Value<GoalPace>? goalPace,
      Value<bool>? personalizationConsent,
      Value<bool>? cloudAiConsent,
      Value<int>? updatedAtEpochMillis}) {
    return PersonalProfilesCompanion(
      id: id ?? this.id,
      birthDateEpochDay: birthDateEpochDay ?? this.birthDateEpochDay,
      metabolicSex: metabolicSex ?? this.metabolicSex,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalPace: goalPace ?? this.goalPace,
      personalizationConsent:
          personalizationConsent ?? this.personalizationConsent,
      cloudAiConsent: cloudAiConsent ?? this.cloudAiConsent,
      updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (birthDateEpochDay.present) {
      map['birth_date_epoch_day'] = Variable<int>(birthDateEpochDay.value);
    }
    if (metabolicSex.present) {
      map['metabolic_sex'] = Variable<String>($PersonalProfilesTable
          .$convertermetabolicSex
          .toSql(metabolicSex.value));
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (currentWeightKg.present) {
      map['current_weight_kg'] = Variable<double>(currentWeightKg.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>($PersonalProfilesTable
          .$converteractivityLevel
          .toSql(activityLevel.value));
    }
    if (goalPace.present) {
      map['goal_pace'] = Variable<String>(
          $PersonalProfilesTable.$convertergoalPace.toSql(goalPace.value));
    }
    if (personalizationConsent.present) {
      map['personalization_consent'] =
          Variable<bool>(personalizationConsent.value);
    }
    if (cloudAiConsent.present) {
      map['cloud_ai_consent'] = Variable<bool>(cloudAiConsent.value);
    }
    if (updatedAtEpochMillis.present) {
      map['updated_at_epoch_millis'] =
          Variable<int>(updatedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalProfilesCompanion(')
          ..write('id: $id, ')
          ..write('birthDateEpochDay: $birthDateEpochDay, ')
          ..write('metabolicSex: $metabolicSex, ')
          ..write('heightCm: $heightCm, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('goalPace: $goalPace, ')
          ..write('personalizationConsent: $personalizationConsent, ')
          ..write('cloudAiConsent: $cloudAiConsent, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $WeightMeasurementsTable extends WeightMeasurements
    with TableInfo<$WeightMeasurementsTable, WeightMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _epochDayMeta =
      const VerificationMeta('epochDay');
  @override
  late final GeneratedColumn<int> epochDay = GeneratedColumn<int>(
      'epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtEpochMillisMeta =
      const VerificationMeta('recordedAtEpochMillis');
  @override
  late final GeneratedColumn<int> recordedAtEpochMillis = GeneratedColumn<int>(
      'recorded_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [epochDay, weightKg, recordedAtEpochMillis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_measurements';
  @override
  VerificationContext validateIntegrity(Insertable<WeightMeasurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('epoch_day')) {
      context.handle(_epochDayMeta,
          epochDay.isAcceptableOrUnknown(data['epoch_day']!, _epochDayMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('recorded_at_epoch_millis')) {
      context.handle(
          _recordedAtEpochMillisMeta,
          recordedAtEpochMillis.isAcceptableOrUnknown(
              data['recorded_at_epoch_millis']!, _recordedAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_recordedAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {epochDay};
  @override
  WeightMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightMeasurement(
      epochDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}epoch_day'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      recordedAtEpochMillis: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}recorded_at_epoch_millis'])!,
    );
  }

  @override
  $WeightMeasurementsTable createAlias(String alias) {
    return $WeightMeasurementsTable(attachedDatabase, alias);
  }
}

class WeightMeasurement extends DataClass
    implements Insertable<WeightMeasurement> {
  final int epochDay;
  final double weightKg;
  final int recordedAtEpochMillis;
  const WeightMeasurement(
      {required this.epochDay,
      required this.weightKg,
      required this.recordedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['epoch_day'] = Variable<int>(epochDay);
    map['weight_kg'] = Variable<double>(weightKg);
    map['recorded_at_epoch_millis'] = Variable<int>(recordedAtEpochMillis);
    return map;
  }

  WeightMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return WeightMeasurementsCompanion(
      epochDay: Value(epochDay),
      weightKg: Value(weightKg),
      recordedAtEpochMillis: Value(recordedAtEpochMillis),
    );
  }

  factory WeightMeasurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightMeasurement(
      epochDay: serializer.fromJson<int>(json['epochDay']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      recordedAtEpochMillis:
          serializer.fromJson<int>(json['recordedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'epochDay': serializer.toJson<int>(epochDay),
      'weightKg': serializer.toJson<double>(weightKg),
      'recordedAtEpochMillis': serializer.toJson<int>(recordedAtEpochMillis),
    };
  }

  WeightMeasurement copyWith(
          {int? epochDay, double? weightKg, int? recordedAtEpochMillis}) =>
      WeightMeasurement(
        epochDay: epochDay ?? this.epochDay,
        weightKg: weightKg ?? this.weightKg,
        recordedAtEpochMillis:
            recordedAtEpochMillis ?? this.recordedAtEpochMillis,
      );
  WeightMeasurement copyWithCompanion(WeightMeasurementsCompanion data) {
    return WeightMeasurement(
      epochDay: data.epochDay.present ? data.epochDay.value : this.epochDay,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      recordedAtEpochMillis: data.recordedAtEpochMillis.present
          ? data.recordedAtEpochMillis.value
          : this.recordedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightMeasurement(')
          ..write('epochDay: $epochDay, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAtEpochMillis: $recordedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(epochDay, weightKg, recordedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightMeasurement &&
          other.epochDay == this.epochDay &&
          other.weightKg == this.weightKg &&
          other.recordedAtEpochMillis == this.recordedAtEpochMillis);
}

class WeightMeasurementsCompanion extends UpdateCompanion<WeightMeasurement> {
  final Value<int> epochDay;
  final Value<double> weightKg;
  final Value<int> recordedAtEpochMillis;
  const WeightMeasurementsCompanion({
    this.epochDay = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.recordedAtEpochMillis = const Value.absent(),
  });
  WeightMeasurementsCompanion.insert({
    this.epochDay = const Value.absent(),
    required double weightKg,
    required int recordedAtEpochMillis,
  })  : weightKg = Value(weightKg),
        recordedAtEpochMillis = Value(recordedAtEpochMillis);
  static Insertable<WeightMeasurement> custom({
    Expression<int>? epochDay,
    Expression<double>? weightKg,
    Expression<int>? recordedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (epochDay != null) 'epoch_day': epochDay,
      if (weightKg != null) 'weight_kg': weightKg,
      if (recordedAtEpochMillis != null)
        'recorded_at_epoch_millis': recordedAtEpochMillis,
    });
  }

  WeightMeasurementsCompanion copyWith(
      {Value<int>? epochDay,
      Value<double>? weightKg,
      Value<int>? recordedAtEpochMillis}) {
    return WeightMeasurementsCompanion(
      epochDay: epochDay ?? this.epochDay,
      weightKg: weightKg ?? this.weightKg,
      recordedAtEpochMillis:
          recordedAtEpochMillis ?? this.recordedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (epochDay.present) {
      map['epoch_day'] = Variable<int>(epochDay.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (recordedAtEpochMillis.present) {
      map['recorded_at_epoch_millis'] =
          Variable<int>(recordedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightMeasurementsCompanion(')
          ..write('epochDay: $epochDay, ')
          ..write('weightKg: $weightKg, ')
          ..write('recordedAtEpochMillis: $recordedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $DailyNutritionsTable extends DailyNutritions
    with TableInfo<$DailyNutritionsTable, DailyNutritionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNutritionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _epochDayMeta =
      const VerificationMeta('epochDay');
  @override
  late final GeneratedColumn<int> epochDay = GeneratedColumn<int>(
      'epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _consumedCaloriesMeta =
      const VerificationMeta('consumedCalories');
  @override
  late final GeneratedColumn<int> consumedCalories = GeneratedColumn<int>(
      'consumed_calories', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consumedProteinGramsMeta =
      const VerificationMeta('consumedProteinGrams');
  @override
  late final GeneratedColumn<int> consumedProteinGrams = GeneratedColumn<int>(
      'consumed_protein_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consumedCarbsGramsMeta =
      const VerificationMeta('consumedCarbsGrams');
  @override
  late final GeneratedColumn<int> consumedCarbsGrams = GeneratedColumn<int>(
      'consumed_carbs_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consumedFatGramsMeta =
      const VerificationMeta('consumedFatGrams');
  @override
  late final GeneratedColumn<int> consumedFatGrams = GeneratedColumn<int>(
      'consumed_fat_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consumedFiberGramsMeta =
      const VerificationMeta('consumedFiberGrams');
  @override
  late final GeneratedColumn<int> consumedFiberGrams = GeneratedColumn<int>(
      'consumed_fiber_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _targetBasalCaloriesMeta =
      const VerificationMeta('targetBasalCalories');
  @override
  late final GeneratedColumn<int> targetBasalCalories = GeneratedColumn<int>(
      'target_basal_calories', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetMaintenanceCaloriesMeta =
      const VerificationMeta('targetMaintenanceCalories');
  @override
  late final GeneratedColumn<int> targetMaintenanceCalories =
      GeneratedColumn<int>('target_maintenance_calories', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetCaloriesMeta =
      const VerificationMeta('targetCalories');
  @override
  late final GeneratedColumn<int> targetCalories = GeneratedColumn<int>(
      'target_calories', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetProteinGramsMeta =
      const VerificationMeta('targetProteinGrams');
  @override
  late final GeneratedColumn<int> targetProteinGrams = GeneratedColumn<int>(
      'target_protein_grams', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetCarbsGramsMeta =
      const VerificationMeta('targetCarbsGrams');
  @override
  late final GeneratedColumn<int> targetCarbsGrams = GeneratedColumn<int>(
      'target_carbs_grams', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetFatGramsMeta =
      const VerificationMeta('targetFatGrams');
  @override
  late final GeneratedColumn<int> targetFatGrams = GeneratedColumn<int>(
      'target_fat_grams', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastEntrySourceMeta =
      const VerificationMeta('lastEntrySource');
  @override
  late final GeneratedColumn<String> lastEntrySource = GeneratedColumn<String>(
      'last_entry_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _waterIntakeMlMeta =
      const VerificationMeta('waterIntakeMl');
  @override
  late final GeneratedColumn<int> waterIntakeMl = GeneratedColumn<int>(
      'water_intake_ml', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtEpochMillisMeta =
      const VerificationMeta('updatedAtEpochMillis');
  @override
  late final GeneratedColumn<int> updatedAtEpochMillis = GeneratedColumn<int>(
      'updated_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        epochDay,
        consumedCalories,
        consumedProteinGrams,
        consumedCarbsGrams,
        consumedFatGrams,
        consumedFiberGrams,
        targetBasalCalories,
        targetMaintenanceCalories,
        targetCalories,
        targetProteinGrams,
        targetCarbsGrams,
        targetFatGrams,
        lastEntrySource,
        waterIntakeMl,
        updatedAtEpochMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_nutritions';
  @override
  VerificationContext validateIntegrity(Insertable<DailyNutritionData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('epoch_day')) {
      context.handle(_epochDayMeta,
          epochDay.isAcceptableOrUnknown(data['epoch_day']!, _epochDayMeta));
    }
    if (data.containsKey('consumed_calories')) {
      context.handle(
          _consumedCaloriesMeta,
          consumedCalories.isAcceptableOrUnknown(
              data['consumed_calories']!, _consumedCaloriesMeta));
    }
    if (data.containsKey('consumed_protein_grams')) {
      context.handle(
          _consumedProteinGramsMeta,
          consumedProteinGrams.isAcceptableOrUnknown(
              data['consumed_protein_grams']!, _consumedProteinGramsMeta));
    }
    if (data.containsKey('consumed_carbs_grams')) {
      context.handle(
          _consumedCarbsGramsMeta,
          consumedCarbsGrams.isAcceptableOrUnknown(
              data['consumed_carbs_grams']!, _consumedCarbsGramsMeta));
    }
    if (data.containsKey('consumed_fat_grams')) {
      context.handle(
          _consumedFatGramsMeta,
          consumedFatGrams.isAcceptableOrUnknown(
              data['consumed_fat_grams']!, _consumedFatGramsMeta));
    }
    if (data.containsKey('consumed_fiber_grams')) {
      context.handle(
          _consumedFiberGramsMeta,
          consumedFiberGrams.isAcceptableOrUnknown(
              data['consumed_fiber_grams']!, _consumedFiberGramsMeta));
    }
    if (data.containsKey('target_basal_calories')) {
      context.handle(
          _targetBasalCaloriesMeta,
          targetBasalCalories.isAcceptableOrUnknown(
              data['target_basal_calories']!, _targetBasalCaloriesMeta));
    }
    if (data.containsKey('target_maintenance_calories')) {
      context.handle(
          _targetMaintenanceCaloriesMeta,
          targetMaintenanceCalories.isAcceptableOrUnknown(
              data['target_maintenance_calories']!,
              _targetMaintenanceCaloriesMeta));
    }
    if (data.containsKey('target_calories')) {
      context.handle(
          _targetCaloriesMeta,
          targetCalories.isAcceptableOrUnknown(
              data['target_calories']!, _targetCaloriesMeta));
    }
    if (data.containsKey('target_protein_grams')) {
      context.handle(
          _targetProteinGramsMeta,
          targetProteinGrams.isAcceptableOrUnknown(
              data['target_protein_grams']!, _targetProteinGramsMeta));
    }
    if (data.containsKey('target_carbs_grams')) {
      context.handle(
          _targetCarbsGramsMeta,
          targetCarbsGrams.isAcceptableOrUnknown(
              data['target_carbs_grams']!, _targetCarbsGramsMeta));
    }
    if (data.containsKey('target_fat_grams')) {
      context.handle(
          _targetFatGramsMeta,
          targetFatGrams.isAcceptableOrUnknown(
              data['target_fat_grams']!, _targetFatGramsMeta));
    }
    if (data.containsKey('last_entry_source')) {
      context.handle(
          _lastEntrySourceMeta,
          lastEntrySource.isAcceptableOrUnknown(
              data['last_entry_source']!, _lastEntrySourceMeta));
    }
    if (data.containsKey('water_intake_ml')) {
      context.handle(
          _waterIntakeMlMeta,
          waterIntakeMl.isAcceptableOrUnknown(
              data['water_intake_ml']!, _waterIntakeMlMeta));
    }
    if (data.containsKey('updated_at_epoch_millis')) {
      context.handle(
          _updatedAtEpochMillisMeta,
          updatedAtEpochMillis.isAcceptableOrUnknown(
              data['updated_at_epoch_millis']!, _updatedAtEpochMillisMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {epochDay};
  @override
  DailyNutritionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNutritionData(
      epochDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}epoch_day'])!,
      consumedCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}consumed_calories'])!,
      consumedProteinGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consumed_protein_grams'])!,
      consumedCarbsGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consumed_carbs_grams'])!,
      consumedFatGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consumed_fat_grams'])!,
      consumedFiberGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consumed_fiber_grams'])!,
      targetBasalCalories: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}target_basal_calories']),
      targetMaintenanceCalories: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}target_maintenance_calories']),
      targetCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_calories']),
      targetProteinGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}target_protein_grams']),
      targetCarbsGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_carbs_grams']),
      targetFatGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_fat_grams']),
      lastEntrySource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_entry_source']),
      waterIntakeMl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}water_intake_ml'])!,
      updatedAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}updated_at_epoch_millis'])!,
    );
  }

  @override
  $DailyNutritionsTable createAlias(String alias) {
    return $DailyNutritionsTable(attachedDatabase, alias);
  }
}

class DailyNutritionData extends DataClass
    implements Insertable<DailyNutritionData> {
  final int epochDay;
  final int consumedCalories;
  final int consumedProteinGrams;
  final int consumedCarbsGrams;
  final int consumedFatGrams;
  final int consumedFiberGrams;
  final int? targetBasalCalories;
  final int? targetMaintenanceCalories;
  final int? targetCalories;
  final int? targetProteinGrams;
  final int? targetCarbsGrams;
  final int? targetFatGrams;
  final String? lastEntrySource;
  final int waterIntakeMl;
  final int updatedAtEpochMillis;
  const DailyNutritionData(
      {required this.epochDay,
      required this.consumedCalories,
      required this.consumedProteinGrams,
      required this.consumedCarbsGrams,
      required this.consumedFatGrams,
      required this.consumedFiberGrams,
      this.targetBasalCalories,
      this.targetMaintenanceCalories,
      this.targetCalories,
      this.targetProteinGrams,
      this.targetCarbsGrams,
      this.targetFatGrams,
      this.lastEntrySource,
      required this.waterIntakeMl,
      required this.updatedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['epoch_day'] = Variable<int>(epochDay);
    map['consumed_calories'] = Variable<int>(consumedCalories);
    map['consumed_protein_grams'] = Variable<int>(consumedProteinGrams);
    map['consumed_carbs_grams'] = Variable<int>(consumedCarbsGrams);
    map['consumed_fat_grams'] = Variable<int>(consumedFatGrams);
    map['consumed_fiber_grams'] = Variable<int>(consumedFiberGrams);
    if (!nullToAbsent || targetBasalCalories != null) {
      map['target_basal_calories'] = Variable<int>(targetBasalCalories);
    }
    if (!nullToAbsent || targetMaintenanceCalories != null) {
      map['target_maintenance_calories'] =
          Variable<int>(targetMaintenanceCalories);
    }
    if (!nullToAbsent || targetCalories != null) {
      map['target_calories'] = Variable<int>(targetCalories);
    }
    if (!nullToAbsent || targetProteinGrams != null) {
      map['target_protein_grams'] = Variable<int>(targetProteinGrams);
    }
    if (!nullToAbsent || targetCarbsGrams != null) {
      map['target_carbs_grams'] = Variable<int>(targetCarbsGrams);
    }
    if (!nullToAbsent || targetFatGrams != null) {
      map['target_fat_grams'] = Variable<int>(targetFatGrams);
    }
    if (!nullToAbsent || lastEntrySource != null) {
      map['last_entry_source'] = Variable<String>(lastEntrySource);
    }
    map['water_intake_ml'] = Variable<int>(waterIntakeMl);
    map['updated_at_epoch_millis'] = Variable<int>(updatedAtEpochMillis);
    return map;
  }

  DailyNutritionsCompanion toCompanion(bool nullToAbsent) {
    return DailyNutritionsCompanion(
      epochDay: Value(epochDay),
      consumedCalories: Value(consumedCalories),
      consumedProteinGrams: Value(consumedProteinGrams),
      consumedCarbsGrams: Value(consumedCarbsGrams),
      consumedFatGrams: Value(consumedFatGrams),
      consumedFiberGrams: Value(consumedFiberGrams),
      targetBasalCalories: targetBasalCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBasalCalories),
      targetMaintenanceCalories:
          targetMaintenanceCalories == null && nullToAbsent
              ? const Value.absent()
              : Value(targetMaintenanceCalories),
      targetCalories: targetCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCalories),
      targetProteinGrams: targetProteinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(targetProteinGrams),
      targetCarbsGrams: targetCarbsGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCarbsGrams),
      targetFatGrams: targetFatGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(targetFatGrams),
      lastEntrySource: lastEntrySource == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEntrySource),
      waterIntakeMl: Value(waterIntakeMl),
      updatedAtEpochMillis: Value(updatedAtEpochMillis),
    );
  }

  factory DailyNutritionData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNutritionData(
      epochDay: serializer.fromJson<int>(json['epochDay']),
      consumedCalories: serializer.fromJson<int>(json['consumedCalories']),
      consumedProteinGrams:
          serializer.fromJson<int>(json['consumedProteinGrams']),
      consumedCarbsGrams: serializer.fromJson<int>(json['consumedCarbsGrams']),
      consumedFatGrams: serializer.fromJson<int>(json['consumedFatGrams']),
      consumedFiberGrams: serializer.fromJson<int>(json['consumedFiberGrams']),
      targetBasalCalories:
          serializer.fromJson<int?>(json['targetBasalCalories']),
      targetMaintenanceCalories:
          serializer.fromJson<int?>(json['targetMaintenanceCalories']),
      targetCalories: serializer.fromJson<int?>(json['targetCalories']),
      targetProteinGrams: serializer.fromJson<int?>(json['targetProteinGrams']),
      targetCarbsGrams: serializer.fromJson<int?>(json['targetCarbsGrams']),
      targetFatGrams: serializer.fromJson<int?>(json['targetFatGrams']),
      lastEntrySource: serializer.fromJson<String?>(json['lastEntrySource']),
      waterIntakeMl: serializer.fromJson<int>(json['waterIntakeMl']),
      updatedAtEpochMillis:
          serializer.fromJson<int>(json['updatedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'epochDay': serializer.toJson<int>(epochDay),
      'consumedCalories': serializer.toJson<int>(consumedCalories),
      'consumedProteinGrams': serializer.toJson<int>(consumedProteinGrams),
      'consumedCarbsGrams': serializer.toJson<int>(consumedCarbsGrams),
      'consumedFatGrams': serializer.toJson<int>(consumedFatGrams),
      'consumedFiberGrams': serializer.toJson<int>(consumedFiberGrams),
      'targetBasalCalories': serializer.toJson<int?>(targetBasalCalories),
      'targetMaintenanceCalories':
          serializer.toJson<int?>(targetMaintenanceCalories),
      'targetCalories': serializer.toJson<int?>(targetCalories),
      'targetProteinGrams': serializer.toJson<int?>(targetProteinGrams),
      'targetCarbsGrams': serializer.toJson<int?>(targetCarbsGrams),
      'targetFatGrams': serializer.toJson<int?>(targetFatGrams),
      'lastEntrySource': serializer.toJson<String?>(lastEntrySource),
      'waterIntakeMl': serializer.toJson<int>(waterIntakeMl),
      'updatedAtEpochMillis': serializer.toJson<int>(updatedAtEpochMillis),
    };
  }

  DailyNutritionData copyWith(
          {int? epochDay,
          int? consumedCalories,
          int? consumedProteinGrams,
          int? consumedCarbsGrams,
          int? consumedFatGrams,
          int? consumedFiberGrams,
          Value<int?> targetBasalCalories = const Value.absent(),
          Value<int?> targetMaintenanceCalories = const Value.absent(),
          Value<int?> targetCalories = const Value.absent(),
          Value<int?> targetProteinGrams = const Value.absent(),
          Value<int?> targetCarbsGrams = const Value.absent(),
          Value<int?> targetFatGrams = const Value.absent(),
          Value<String?> lastEntrySource = const Value.absent(),
          int? waterIntakeMl,
          int? updatedAtEpochMillis}) =>
      DailyNutritionData(
        epochDay: epochDay ?? this.epochDay,
        consumedCalories: consumedCalories ?? this.consumedCalories,
        consumedProteinGrams: consumedProteinGrams ?? this.consumedProteinGrams,
        consumedCarbsGrams: consumedCarbsGrams ?? this.consumedCarbsGrams,
        consumedFatGrams: consumedFatGrams ?? this.consumedFatGrams,
        consumedFiberGrams: consumedFiberGrams ?? this.consumedFiberGrams,
        targetBasalCalories: targetBasalCalories.present
            ? targetBasalCalories.value
            : this.targetBasalCalories,
        targetMaintenanceCalories: targetMaintenanceCalories.present
            ? targetMaintenanceCalories.value
            : this.targetMaintenanceCalories,
        targetCalories:
            targetCalories.present ? targetCalories.value : this.targetCalories,
        targetProteinGrams: targetProteinGrams.present
            ? targetProteinGrams.value
            : this.targetProteinGrams,
        targetCarbsGrams: targetCarbsGrams.present
            ? targetCarbsGrams.value
            : this.targetCarbsGrams,
        targetFatGrams:
            targetFatGrams.present ? targetFatGrams.value : this.targetFatGrams,
        lastEntrySource: lastEntrySource.present
            ? lastEntrySource.value
            : this.lastEntrySource,
        waterIntakeMl: waterIntakeMl ?? this.waterIntakeMl,
        updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
      );
  DailyNutritionData copyWithCompanion(DailyNutritionsCompanion data) {
    return DailyNutritionData(
      epochDay: data.epochDay.present ? data.epochDay.value : this.epochDay,
      consumedCalories: data.consumedCalories.present
          ? data.consumedCalories.value
          : this.consumedCalories,
      consumedProteinGrams: data.consumedProteinGrams.present
          ? data.consumedProteinGrams.value
          : this.consumedProteinGrams,
      consumedCarbsGrams: data.consumedCarbsGrams.present
          ? data.consumedCarbsGrams.value
          : this.consumedCarbsGrams,
      consumedFatGrams: data.consumedFatGrams.present
          ? data.consumedFatGrams.value
          : this.consumedFatGrams,
      consumedFiberGrams: data.consumedFiberGrams.present
          ? data.consumedFiberGrams.value
          : this.consumedFiberGrams,
      targetBasalCalories: data.targetBasalCalories.present
          ? data.targetBasalCalories.value
          : this.targetBasalCalories,
      targetMaintenanceCalories: data.targetMaintenanceCalories.present
          ? data.targetMaintenanceCalories.value
          : this.targetMaintenanceCalories,
      targetCalories: data.targetCalories.present
          ? data.targetCalories.value
          : this.targetCalories,
      targetProteinGrams: data.targetProteinGrams.present
          ? data.targetProteinGrams.value
          : this.targetProteinGrams,
      targetCarbsGrams: data.targetCarbsGrams.present
          ? data.targetCarbsGrams.value
          : this.targetCarbsGrams,
      targetFatGrams: data.targetFatGrams.present
          ? data.targetFatGrams.value
          : this.targetFatGrams,
      lastEntrySource: data.lastEntrySource.present
          ? data.lastEntrySource.value
          : this.lastEntrySource,
      waterIntakeMl: data.waterIntakeMl.present
          ? data.waterIntakeMl.value
          : this.waterIntakeMl,
      updatedAtEpochMillis: data.updatedAtEpochMillis.present
          ? data.updatedAtEpochMillis.value
          : this.updatedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionData(')
          ..write('epochDay: $epochDay, ')
          ..write('consumedCalories: $consumedCalories, ')
          ..write('consumedProteinGrams: $consumedProteinGrams, ')
          ..write('consumedCarbsGrams: $consumedCarbsGrams, ')
          ..write('consumedFatGrams: $consumedFatGrams, ')
          ..write('consumedFiberGrams: $consumedFiberGrams, ')
          ..write('targetBasalCalories: $targetBasalCalories, ')
          ..write('targetMaintenanceCalories: $targetMaintenanceCalories, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProteinGrams: $targetProteinGrams, ')
          ..write('targetCarbsGrams: $targetCarbsGrams, ')
          ..write('targetFatGrams: $targetFatGrams, ')
          ..write('lastEntrySource: $lastEntrySource, ')
          ..write('waterIntakeMl: $waterIntakeMl, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      epochDay,
      consumedCalories,
      consumedProteinGrams,
      consumedCarbsGrams,
      consumedFatGrams,
      consumedFiberGrams,
      targetBasalCalories,
      targetMaintenanceCalories,
      targetCalories,
      targetProteinGrams,
      targetCarbsGrams,
      targetFatGrams,
      lastEntrySource,
      waterIntakeMl,
      updatedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNutritionData &&
          other.epochDay == this.epochDay &&
          other.consumedCalories == this.consumedCalories &&
          other.consumedProteinGrams == this.consumedProteinGrams &&
          other.consumedCarbsGrams == this.consumedCarbsGrams &&
          other.consumedFatGrams == this.consumedFatGrams &&
          other.consumedFiberGrams == this.consumedFiberGrams &&
          other.targetBasalCalories == this.targetBasalCalories &&
          other.targetMaintenanceCalories == this.targetMaintenanceCalories &&
          other.targetCalories == this.targetCalories &&
          other.targetProteinGrams == this.targetProteinGrams &&
          other.targetCarbsGrams == this.targetCarbsGrams &&
          other.targetFatGrams == this.targetFatGrams &&
          other.lastEntrySource == this.lastEntrySource &&
          other.waterIntakeMl == this.waterIntakeMl &&
          other.updatedAtEpochMillis == this.updatedAtEpochMillis);
}

class DailyNutritionsCompanion extends UpdateCompanion<DailyNutritionData> {
  final Value<int> epochDay;
  final Value<int> consumedCalories;
  final Value<int> consumedProteinGrams;
  final Value<int> consumedCarbsGrams;
  final Value<int> consumedFatGrams;
  final Value<int> consumedFiberGrams;
  final Value<int?> targetBasalCalories;
  final Value<int?> targetMaintenanceCalories;
  final Value<int?> targetCalories;
  final Value<int?> targetProteinGrams;
  final Value<int?> targetCarbsGrams;
  final Value<int?> targetFatGrams;
  final Value<String?> lastEntrySource;
  final Value<int> waterIntakeMl;
  final Value<int> updatedAtEpochMillis;
  const DailyNutritionsCompanion({
    this.epochDay = const Value.absent(),
    this.consumedCalories = const Value.absent(),
    this.consumedProteinGrams = const Value.absent(),
    this.consumedCarbsGrams = const Value.absent(),
    this.consumedFatGrams = const Value.absent(),
    this.consumedFiberGrams = const Value.absent(),
    this.targetBasalCalories = const Value.absent(),
    this.targetMaintenanceCalories = const Value.absent(),
    this.targetCalories = const Value.absent(),
    this.targetProteinGrams = const Value.absent(),
    this.targetCarbsGrams = const Value.absent(),
    this.targetFatGrams = const Value.absent(),
    this.lastEntrySource = const Value.absent(),
    this.waterIntakeMl = const Value.absent(),
    this.updatedAtEpochMillis = const Value.absent(),
  });
  DailyNutritionsCompanion.insert({
    this.epochDay = const Value.absent(),
    this.consumedCalories = const Value.absent(),
    this.consumedProteinGrams = const Value.absent(),
    this.consumedCarbsGrams = const Value.absent(),
    this.consumedFatGrams = const Value.absent(),
    this.consumedFiberGrams = const Value.absent(),
    this.targetBasalCalories = const Value.absent(),
    this.targetMaintenanceCalories = const Value.absent(),
    this.targetCalories = const Value.absent(),
    this.targetProteinGrams = const Value.absent(),
    this.targetCarbsGrams = const Value.absent(),
    this.targetFatGrams = const Value.absent(),
    this.lastEntrySource = const Value.absent(),
    this.waterIntakeMl = const Value.absent(),
    this.updatedAtEpochMillis = const Value.absent(),
  });
  static Insertable<DailyNutritionData> custom({
    Expression<int>? epochDay,
    Expression<int>? consumedCalories,
    Expression<int>? consumedProteinGrams,
    Expression<int>? consumedCarbsGrams,
    Expression<int>? consumedFatGrams,
    Expression<int>? consumedFiberGrams,
    Expression<int>? targetBasalCalories,
    Expression<int>? targetMaintenanceCalories,
    Expression<int>? targetCalories,
    Expression<int>? targetProteinGrams,
    Expression<int>? targetCarbsGrams,
    Expression<int>? targetFatGrams,
    Expression<String>? lastEntrySource,
    Expression<int>? waterIntakeMl,
    Expression<int>? updatedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (epochDay != null) 'epoch_day': epochDay,
      if (consumedCalories != null) 'consumed_calories': consumedCalories,
      if (consumedProteinGrams != null)
        'consumed_protein_grams': consumedProteinGrams,
      if (consumedCarbsGrams != null)
        'consumed_carbs_grams': consumedCarbsGrams,
      if (consumedFatGrams != null) 'consumed_fat_grams': consumedFatGrams,
      if (consumedFiberGrams != null)
        'consumed_fiber_grams': consumedFiberGrams,
      if (targetBasalCalories != null)
        'target_basal_calories': targetBasalCalories,
      if (targetMaintenanceCalories != null)
        'target_maintenance_calories': targetMaintenanceCalories,
      if (targetCalories != null) 'target_calories': targetCalories,
      if (targetProteinGrams != null)
        'target_protein_grams': targetProteinGrams,
      if (targetCarbsGrams != null) 'target_carbs_grams': targetCarbsGrams,
      if (targetFatGrams != null) 'target_fat_grams': targetFatGrams,
      if (lastEntrySource != null) 'last_entry_source': lastEntrySource,
      if (waterIntakeMl != null) 'water_intake_ml': waterIntakeMl,
      if (updatedAtEpochMillis != null)
        'updated_at_epoch_millis': updatedAtEpochMillis,
    });
  }

  DailyNutritionsCompanion copyWith(
      {Value<int>? epochDay,
      Value<int>? consumedCalories,
      Value<int>? consumedProteinGrams,
      Value<int>? consumedCarbsGrams,
      Value<int>? consumedFatGrams,
      Value<int>? consumedFiberGrams,
      Value<int?>? targetBasalCalories,
      Value<int?>? targetMaintenanceCalories,
      Value<int?>? targetCalories,
      Value<int?>? targetProteinGrams,
      Value<int?>? targetCarbsGrams,
      Value<int?>? targetFatGrams,
      Value<String?>? lastEntrySource,
      Value<int>? waterIntakeMl,
      Value<int>? updatedAtEpochMillis}) {
    return DailyNutritionsCompanion(
      epochDay: epochDay ?? this.epochDay,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      consumedProteinGrams: consumedProteinGrams ?? this.consumedProteinGrams,
      consumedCarbsGrams: consumedCarbsGrams ?? this.consumedCarbsGrams,
      consumedFatGrams: consumedFatGrams ?? this.consumedFatGrams,
      consumedFiberGrams: consumedFiberGrams ?? this.consumedFiberGrams,
      targetBasalCalories: targetBasalCalories ?? this.targetBasalCalories,
      targetMaintenanceCalories:
          targetMaintenanceCalories ?? this.targetMaintenanceCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams ?? this.targetCarbsGrams,
      targetFatGrams: targetFatGrams ?? this.targetFatGrams,
      lastEntrySource: lastEntrySource ?? this.lastEntrySource,
      waterIntakeMl: waterIntakeMl ?? this.waterIntakeMl,
      updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (epochDay.present) {
      map['epoch_day'] = Variable<int>(epochDay.value);
    }
    if (consumedCalories.present) {
      map['consumed_calories'] = Variable<int>(consumedCalories.value);
    }
    if (consumedProteinGrams.present) {
      map['consumed_protein_grams'] = Variable<int>(consumedProteinGrams.value);
    }
    if (consumedCarbsGrams.present) {
      map['consumed_carbs_grams'] = Variable<int>(consumedCarbsGrams.value);
    }
    if (consumedFatGrams.present) {
      map['consumed_fat_grams'] = Variable<int>(consumedFatGrams.value);
    }
    if (consumedFiberGrams.present) {
      map['consumed_fiber_grams'] = Variable<int>(consumedFiberGrams.value);
    }
    if (targetBasalCalories.present) {
      map['target_basal_calories'] = Variable<int>(targetBasalCalories.value);
    }
    if (targetMaintenanceCalories.present) {
      map['target_maintenance_calories'] =
          Variable<int>(targetMaintenanceCalories.value);
    }
    if (targetCalories.present) {
      map['target_calories'] = Variable<int>(targetCalories.value);
    }
    if (targetProteinGrams.present) {
      map['target_protein_grams'] = Variable<int>(targetProteinGrams.value);
    }
    if (targetCarbsGrams.present) {
      map['target_carbs_grams'] = Variable<int>(targetCarbsGrams.value);
    }
    if (targetFatGrams.present) {
      map['target_fat_grams'] = Variable<int>(targetFatGrams.value);
    }
    if (lastEntrySource.present) {
      map['last_entry_source'] = Variable<String>(lastEntrySource.value);
    }
    if (waterIntakeMl.present) {
      map['water_intake_ml'] = Variable<int>(waterIntakeMl.value);
    }
    if (updatedAtEpochMillis.present) {
      map['updated_at_epoch_millis'] =
          Variable<int>(updatedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionsCompanion(')
          ..write('epochDay: $epochDay, ')
          ..write('consumedCalories: $consumedCalories, ')
          ..write('consumedProteinGrams: $consumedProteinGrams, ')
          ..write('consumedCarbsGrams: $consumedCarbsGrams, ')
          ..write('consumedFatGrams: $consumedFatGrams, ')
          ..write('consumedFiberGrams: $consumedFiberGrams, ')
          ..write('targetBasalCalories: $targetBasalCalories, ')
          ..write('targetMaintenanceCalories: $targetMaintenanceCalories, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProteinGrams: $targetProteinGrams, ')
          ..write('targetCarbsGrams: $targetCarbsGrams, ')
          ..write('targetFatGrams: $targetFatGrams, ')
          ..write('lastEntrySource: $lastEntrySource, ')
          ..write('waterIntakeMl: $waterIntakeMl, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $WeeklyCheckInsTable extends WeeklyCheckIns
    with TableInfo<$WeeklyCheckInsTable, WeeklyCheckInData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekStartEpochDayMeta =
      const VerificationMeta('weekStartEpochDay');
  @override
  late final GeneratedColumn<int> weekStartEpochDay = GeneratedColumn<int>(
      'week_start_epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
      'energy', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hungerMeta = const VerificationMeta('hunger');
  @override
  late final GeneratedColumn<int> hunger = GeneratedColumn<int>(
      'hunger', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recoveryMeta =
      const VerificationMeta('recovery');
  @override
  late final GeneratedColumn<int> recovery = GeneratedColumn<int>(
      'recovery', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sleepQualityMeta =
      const VerificationMeta('sleepQuality');
  @override
  late final GeneratedColumn<int> sleepQuality = GeneratedColumn<int>(
      'sleep_quality', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtEpochMillisMeta =
      const VerificationMeta('createdAtEpochMillis');
  @override
  late final GeneratedColumn<int> createdAtEpochMillis = GeneratedColumn<int>(
      'created_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        weekStartEpochDay,
        weightKg,
        energy,
        hunger,
        recovery,
        sleepQuality,
        note,
        createdAtEpochMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_check_ins';
  @override
  VerificationContext validateIntegrity(Insertable<WeeklyCheckInData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week_start_epoch_day')) {
      context.handle(
          _weekStartEpochDayMeta,
          weekStartEpochDay.isAcceptableOrUnknown(
              data['week_start_epoch_day']!, _weekStartEpochDayMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('energy')) {
      context.handle(_energyMeta,
          energy.isAcceptableOrUnknown(data['energy']!, _energyMeta));
    } else if (isInserting) {
      context.missing(_energyMeta);
    }
    if (data.containsKey('hunger')) {
      context.handle(_hungerMeta,
          hunger.isAcceptableOrUnknown(data['hunger']!, _hungerMeta));
    } else if (isInserting) {
      context.missing(_hungerMeta);
    }
    if (data.containsKey('recovery')) {
      context.handle(_recoveryMeta,
          recovery.isAcceptableOrUnknown(data['recovery']!, _recoveryMeta));
    } else if (isInserting) {
      context.missing(_recoveryMeta);
    }
    if (data.containsKey('sleep_quality')) {
      context.handle(
          _sleepQualityMeta,
          sleepQuality.isAcceptableOrUnknown(
              data['sleep_quality']!, _sleepQualityMeta));
    } else if (isInserting) {
      context.missing(_sleepQualityMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at_epoch_millis')) {
      context.handle(
          _createdAtEpochMillisMeta,
          createdAtEpochMillis.isAcceptableOrUnknown(
              data['created_at_epoch_millis']!, _createdAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_createdAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekStartEpochDay};
  @override
  WeeklyCheckInData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyCheckInData(
      weekStartEpochDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}week_start_epoch_day'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      energy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy'])!,
      hunger: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hunger'])!,
      recovery: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recovery'])!,
      sleepQuality: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sleep_quality'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}created_at_epoch_millis'])!,
    );
  }

  @override
  $WeeklyCheckInsTable createAlias(String alias) {
    return $WeeklyCheckInsTable(attachedDatabase, alias);
  }
}

class WeeklyCheckInData extends DataClass
    implements Insertable<WeeklyCheckInData> {
  final int weekStartEpochDay;
  final double weightKg;
  final int energy;
  final int hunger;
  final int recovery;
  final int sleepQuality;
  final String? note;
  final int createdAtEpochMillis;
  const WeeklyCheckInData(
      {required this.weekStartEpochDay,
      required this.weightKg,
      required this.energy,
      required this.hunger,
      required this.recovery,
      required this.sleepQuality,
      this.note,
      required this.createdAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week_start_epoch_day'] = Variable<int>(weekStartEpochDay);
    map['weight_kg'] = Variable<double>(weightKg);
    map['energy'] = Variable<int>(energy);
    map['hunger'] = Variable<int>(hunger);
    map['recovery'] = Variable<int>(recovery);
    map['sleep_quality'] = Variable<int>(sleepQuality);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at_epoch_millis'] = Variable<int>(createdAtEpochMillis);
    return map;
  }

  WeeklyCheckInsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyCheckInsCompanion(
      weekStartEpochDay: Value(weekStartEpochDay),
      weightKg: Value(weightKg),
      energy: Value(energy),
      hunger: Value(hunger),
      recovery: Value(recovery),
      sleepQuality: Value(sleepQuality),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtEpochMillis: Value(createdAtEpochMillis),
    );
  }

  factory WeeklyCheckInData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyCheckInData(
      weekStartEpochDay: serializer.fromJson<int>(json['weekStartEpochDay']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      energy: serializer.fromJson<int>(json['energy']),
      hunger: serializer.fromJson<int>(json['hunger']),
      recovery: serializer.fromJson<int>(json['recovery']),
      sleepQuality: serializer.fromJson<int>(json['sleepQuality']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtEpochMillis:
          serializer.fromJson<int>(json['createdAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekStartEpochDay': serializer.toJson<int>(weekStartEpochDay),
      'weightKg': serializer.toJson<double>(weightKg),
      'energy': serializer.toJson<int>(energy),
      'hunger': serializer.toJson<int>(hunger),
      'recovery': serializer.toJson<int>(recovery),
      'sleepQuality': serializer.toJson<int>(sleepQuality),
      'note': serializer.toJson<String?>(note),
      'createdAtEpochMillis': serializer.toJson<int>(createdAtEpochMillis),
    };
  }

  WeeklyCheckInData copyWith(
          {int? weekStartEpochDay,
          double? weightKg,
          int? energy,
          int? hunger,
          int? recovery,
          int? sleepQuality,
          Value<String?> note = const Value.absent(),
          int? createdAtEpochMillis}) =>
      WeeklyCheckInData(
        weekStartEpochDay: weekStartEpochDay ?? this.weekStartEpochDay,
        weightKg: weightKg ?? this.weightKg,
        energy: energy ?? this.energy,
        hunger: hunger ?? this.hunger,
        recovery: recovery ?? this.recovery,
        sleepQuality: sleepQuality ?? this.sleepQuality,
        note: note.present ? note.value : this.note,
        createdAtEpochMillis: createdAtEpochMillis ?? this.createdAtEpochMillis,
      );
  WeeklyCheckInData copyWithCompanion(WeeklyCheckInsCompanion data) {
    return WeeklyCheckInData(
      weekStartEpochDay: data.weekStartEpochDay.present
          ? data.weekStartEpochDay.value
          : this.weekStartEpochDay,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      energy: data.energy.present ? data.energy.value : this.energy,
      hunger: data.hunger.present ? data.hunger.value : this.hunger,
      recovery: data.recovery.present ? data.recovery.value : this.recovery,
      sleepQuality: data.sleepQuality.present
          ? data.sleepQuality.value
          : this.sleepQuality,
      note: data.note.present ? data.note.value : this.note,
      createdAtEpochMillis: data.createdAtEpochMillis.present
          ? data.createdAtEpochMillis.value
          : this.createdAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyCheckInData(')
          ..write('weekStartEpochDay: $weekStartEpochDay, ')
          ..write('weightKg: $weightKg, ')
          ..write('energy: $energy, ')
          ..write('hunger: $hunger, ')
          ..write('recovery: $recovery, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('note: $note, ')
          ..write('createdAtEpochMillis: $createdAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(weekStartEpochDay, weightKg, energy, hunger,
      recovery, sleepQuality, note, createdAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyCheckInData &&
          other.weekStartEpochDay == this.weekStartEpochDay &&
          other.weightKg == this.weightKg &&
          other.energy == this.energy &&
          other.hunger == this.hunger &&
          other.recovery == this.recovery &&
          other.sleepQuality == this.sleepQuality &&
          other.note == this.note &&
          other.createdAtEpochMillis == this.createdAtEpochMillis);
}

class WeeklyCheckInsCompanion extends UpdateCompanion<WeeklyCheckInData> {
  final Value<int> weekStartEpochDay;
  final Value<double> weightKg;
  final Value<int> energy;
  final Value<int> hunger;
  final Value<int> recovery;
  final Value<int> sleepQuality;
  final Value<String?> note;
  final Value<int> createdAtEpochMillis;
  const WeeklyCheckInsCompanion({
    this.weekStartEpochDay = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.energy = const Value.absent(),
    this.hunger = const Value.absent(),
    this.recovery = const Value.absent(),
    this.sleepQuality = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtEpochMillis = const Value.absent(),
  });
  WeeklyCheckInsCompanion.insert({
    this.weekStartEpochDay = const Value.absent(),
    required double weightKg,
    required int energy,
    required int hunger,
    required int recovery,
    required int sleepQuality,
    this.note = const Value.absent(),
    required int createdAtEpochMillis,
  })  : weightKg = Value(weightKg),
        energy = Value(energy),
        hunger = Value(hunger),
        recovery = Value(recovery),
        sleepQuality = Value(sleepQuality),
        createdAtEpochMillis = Value(createdAtEpochMillis);
  static Insertable<WeeklyCheckInData> custom({
    Expression<int>? weekStartEpochDay,
    Expression<double>? weightKg,
    Expression<int>? energy,
    Expression<int>? hunger,
    Expression<int>? recovery,
    Expression<int>? sleepQuality,
    Expression<String>? note,
    Expression<int>? createdAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (weekStartEpochDay != null) 'week_start_epoch_day': weekStartEpochDay,
      if (weightKg != null) 'weight_kg': weightKg,
      if (energy != null) 'energy': energy,
      if (hunger != null) 'hunger': hunger,
      if (recovery != null) 'recovery': recovery,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (note != null) 'note': note,
      if (createdAtEpochMillis != null)
        'created_at_epoch_millis': createdAtEpochMillis,
    });
  }

  WeeklyCheckInsCompanion copyWith(
      {Value<int>? weekStartEpochDay,
      Value<double>? weightKg,
      Value<int>? energy,
      Value<int>? hunger,
      Value<int>? recovery,
      Value<int>? sleepQuality,
      Value<String?>? note,
      Value<int>? createdAtEpochMillis}) {
    return WeeklyCheckInsCompanion(
      weekStartEpochDay: weekStartEpochDay ?? this.weekStartEpochDay,
      weightKg: weightKg ?? this.weightKg,
      energy: energy ?? this.energy,
      hunger: hunger ?? this.hunger,
      recovery: recovery ?? this.recovery,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      note: note ?? this.note,
      createdAtEpochMillis: createdAtEpochMillis ?? this.createdAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekStartEpochDay.present) {
      map['week_start_epoch_day'] = Variable<int>(weekStartEpochDay.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (hunger.present) {
      map['hunger'] = Variable<int>(hunger.value);
    }
    if (recovery.present) {
      map['recovery'] = Variable<int>(recovery.value);
    }
    if (sleepQuality.present) {
      map['sleep_quality'] = Variable<int>(sleepQuality.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtEpochMillis.present) {
      map['created_at_epoch_millis'] =
          Variable<int>(createdAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyCheckInsCompanion(')
          ..write('weekStartEpochDay: $weekStartEpochDay, ')
          ..write('weightKg: $weightKg, ')
          ..write('energy: $energy, ')
          ..write('hunger: $hunger, ')
          ..write('recovery: $recovery, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('note: $note, ')
          ..write('createdAtEpochMillis: $createdAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $AdaptationDecisionsTable extends AdaptationDecisions
    with TableInfo<$AdaptationDecisionsTable, AdaptationDecisionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdaptationDecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<AdaptationKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AdaptationKind>(
              $AdaptationDecisionsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<AdaptationMode, String> mode =
      GeneratedColumn<String>('mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AdaptationMode>(
              $AdaptationDecisionsTable.$convertermode);
  @override
  late final GeneratedColumnWithTypeConverter<AdaptationStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AdaptationStatus>(
              $AdaptationDecisionsTable.$converterstatus);
  static const VerificationMeta _reasonViMeta =
      const VerificationMeta('reasonVi');
  @override
  late final GeneratedColumn<String> reasonVi = GeneratedColumn<String>(
      'reason_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadVersionMeta =
      const VerificationMeta('payloadVersion');
  @override
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
      'payload_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _inputsJsonMeta =
      const VerificationMeta('inputsJson');
  @override
  late final GeneratedColumn<String> inputsJson = GeneratedColumn<String>(
      'inputs_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _beforeJsonMeta =
      const VerificationMeta('beforeJson');
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
      'before_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _afterJsonMeta =
      const VerificationMeta('afterJson');
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
      'after_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _undoJsonMeta =
      const VerificationMeta('undoJson');
  @override
  late final GeneratedColumn<String> undoJson = GeneratedColumn<String>(
      'undo_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtEpochMillisMeta =
      const VerificationMeta('createdAtEpochMillis');
  @override
  late final GeneratedColumn<int> createdAtEpochMillis = GeneratedColumn<int>(
      'created_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resolvedAtEpochMillisMeta =
      const VerificationMeta('resolvedAtEpochMillis');
  @override
  late final GeneratedColumn<int> resolvedAtEpochMillis = GeneratedColumn<int>(
      'resolved_at_epoch_millis', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        mode,
        status,
        reasonVi,
        payloadVersion,
        inputsJson,
        beforeJson,
        afterJson,
        undoJson,
        createdAtEpochMillis,
        resolvedAtEpochMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adaptation_decisions';
  @override
  VerificationContext validateIntegrity(
      Insertable<AdaptationDecisionData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reason_vi')) {
      context.handle(_reasonViMeta,
          reasonVi.isAcceptableOrUnknown(data['reason_vi']!, _reasonViMeta));
    } else if (isInserting) {
      context.missing(_reasonViMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
          _payloadVersionMeta,
          payloadVersion.isAcceptableOrUnknown(
              data['payload_version']!, _payloadVersionMeta));
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('inputs_json')) {
      context.handle(
          _inputsJsonMeta,
          inputsJson.isAcceptableOrUnknown(
              data['inputs_json']!, _inputsJsonMeta));
    } else if (isInserting) {
      context.missing(_inputsJsonMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
          _beforeJsonMeta,
          beforeJson.isAcceptableOrUnknown(
              data['before_json']!, _beforeJsonMeta));
    } else if (isInserting) {
      context.missing(_beforeJsonMeta);
    }
    if (data.containsKey('after_json')) {
      context.handle(_afterJsonMeta,
          afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta));
    } else if (isInserting) {
      context.missing(_afterJsonMeta);
    }
    if (data.containsKey('undo_json')) {
      context.handle(_undoJsonMeta,
          undoJson.isAcceptableOrUnknown(data['undo_json']!, _undoJsonMeta));
    } else if (isInserting) {
      context.missing(_undoJsonMeta);
    }
    if (data.containsKey('created_at_epoch_millis')) {
      context.handle(
          _createdAtEpochMillisMeta,
          createdAtEpochMillis.isAcceptableOrUnknown(
              data['created_at_epoch_millis']!, _createdAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_createdAtEpochMillisMeta);
    }
    if (data.containsKey('resolved_at_epoch_millis')) {
      context.handle(
          _resolvedAtEpochMillisMeta,
          resolvedAtEpochMillis.isAcceptableOrUnknown(
              data['resolved_at_epoch_millis']!, _resolvedAtEpochMillisMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdaptationDecisionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdaptationDecisionData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $AdaptationDecisionsTable.$converterkind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      mode: $AdaptationDecisionsTable.$convertermode.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!),
      status: $AdaptationDecisionsTable.$converterstatus.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      reasonVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_vi'])!,
      payloadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_version'])!,
      inputsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inputs_json'])!,
      beforeJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}before_json'])!,
      afterJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}after_json'])!,
      undoJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}undo_json'])!,
      createdAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}created_at_epoch_millis'])!,
      resolvedAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}resolved_at_epoch_millis']),
    );
  }

  @override
  $AdaptationDecisionsTable createAlias(String alias) {
    return $AdaptationDecisionsTable(attachedDatabase, alias);
  }

  static TypeConverter<AdaptationKind, String> $converterkind =
      const AdaptationKindConverter();
  static TypeConverter<AdaptationMode, String> $convertermode =
      const AdaptationModeConverter();
  static TypeConverter<AdaptationStatus, String> $converterstatus =
      const AdaptationStatusConverter();
}

class AdaptationDecisionData extends DataClass
    implements Insertable<AdaptationDecisionData> {
  final int id;
  final AdaptationKind kind;
  final AdaptationMode mode;
  final AdaptationStatus status;
  final String reasonVi;
  final int payloadVersion;
  final String inputsJson;
  final String beforeJson;
  final String afterJson;
  final String undoJson;
  final int createdAtEpochMillis;
  final int? resolvedAtEpochMillis;
  const AdaptationDecisionData(
      {required this.id,
      required this.kind,
      required this.mode,
      required this.status,
      required this.reasonVi,
      required this.payloadVersion,
      required this.inputsJson,
      required this.beforeJson,
      required this.afterJson,
      required this.undoJson,
      required this.createdAtEpochMillis,
      this.resolvedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
          $AdaptationDecisionsTable.$converterkind.toSql(kind));
    }
    {
      map['mode'] = Variable<String>(
          $AdaptationDecisionsTable.$convertermode.toSql(mode));
    }
    {
      map['status'] = Variable<String>(
          $AdaptationDecisionsTable.$converterstatus.toSql(status));
    }
    map['reason_vi'] = Variable<String>(reasonVi);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['inputs_json'] = Variable<String>(inputsJson);
    map['before_json'] = Variable<String>(beforeJson);
    map['after_json'] = Variable<String>(afterJson);
    map['undo_json'] = Variable<String>(undoJson);
    map['created_at_epoch_millis'] = Variable<int>(createdAtEpochMillis);
    if (!nullToAbsent || resolvedAtEpochMillis != null) {
      map['resolved_at_epoch_millis'] = Variable<int>(resolvedAtEpochMillis);
    }
    return map;
  }

  AdaptationDecisionsCompanion toCompanion(bool nullToAbsent) {
    return AdaptationDecisionsCompanion(
      id: Value(id),
      kind: Value(kind),
      mode: Value(mode),
      status: Value(status),
      reasonVi: Value(reasonVi),
      payloadVersion: Value(payloadVersion),
      inputsJson: Value(inputsJson),
      beforeJson: Value(beforeJson),
      afterJson: Value(afterJson),
      undoJson: Value(undoJson),
      createdAtEpochMillis: Value(createdAtEpochMillis),
      resolvedAtEpochMillis: resolvedAtEpochMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAtEpochMillis),
    );
  }

  factory AdaptationDecisionData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdaptationDecisionData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<AdaptationKind>(json['kind']),
      mode: serializer.fromJson<AdaptationMode>(json['mode']),
      status: serializer.fromJson<AdaptationStatus>(json['status']),
      reasonVi: serializer.fromJson<String>(json['reasonVi']),
      payloadVersion: serializer.fromJson<int>(json['payloadVersion']),
      inputsJson: serializer.fromJson<String>(json['inputsJson']),
      beforeJson: serializer.fromJson<String>(json['beforeJson']),
      afterJson: serializer.fromJson<String>(json['afterJson']),
      undoJson: serializer.fromJson<String>(json['undoJson']),
      createdAtEpochMillis:
          serializer.fromJson<int>(json['createdAtEpochMillis']),
      resolvedAtEpochMillis:
          serializer.fromJson<int?>(json['resolvedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<AdaptationKind>(kind),
      'mode': serializer.toJson<AdaptationMode>(mode),
      'status': serializer.toJson<AdaptationStatus>(status),
      'reasonVi': serializer.toJson<String>(reasonVi),
      'payloadVersion': serializer.toJson<int>(payloadVersion),
      'inputsJson': serializer.toJson<String>(inputsJson),
      'beforeJson': serializer.toJson<String>(beforeJson),
      'afterJson': serializer.toJson<String>(afterJson),
      'undoJson': serializer.toJson<String>(undoJson),
      'createdAtEpochMillis': serializer.toJson<int>(createdAtEpochMillis),
      'resolvedAtEpochMillis': serializer.toJson<int?>(resolvedAtEpochMillis),
    };
  }

  AdaptationDecisionData copyWith(
          {int? id,
          AdaptationKind? kind,
          AdaptationMode? mode,
          AdaptationStatus? status,
          String? reasonVi,
          int? payloadVersion,
          String? inputsJson,
          String? beforeJson,
          String? afterJson,
          String? undoJson,
          int? createdAtEpochMillis,
          Value<int?> resolvedAtEpochMillis = const Value.absent()}) =>
      AdaptationDecisionData(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        mode: mode ?? this.mode,
        status: status ?? this.status,
        reasonVi: reasonVi ?? this.reasonVi,
        payloadVersion: payloadVersion ?? this.payloadVersion,
        inputsJson: inputsJson ?? this.inputsJson,
        beforeJson: beforeJson ?? this.beforeJson,
        afterJson: afterJson ?? this.afterJson,
        undoJson: undoJson ?? this.undoJson,
        createdAtEpochMillis: createdAtEpochMillis ?? this.createdAtEpochMillis,
        resolvedAtEpochMillis: resolvedAtEpochMillis.present
            ? resolvedAtEpochMillis.value
            : this.resolvedAtEpochMillis,
      );
  AdaptationDecisionData copyWithCompanion(AdaptationDecisionsCompanion data) {
    return AdaptationDecisionData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      reasonVi: data.reasonVi.present ? data.reasonVi.value : this.reasonVi,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      inputsJson:
          data.inputsJson.present ? data.inputsJson.value : this.inputsJson,
      beforeJson:
          data.beforeJson.present ? data.beforeJson.value : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
      undoJson: data.undoJson.present ? data.undoJson.value : this.undoJson,
      createdAtEpochMillis: data.createdAtEpochMillis.present
          ? data.createdAtEpochMillis.value
          : this.createdAtEpochMillis,
      resolvedAtEpochMillis: data.resolvedAtEpochMillis.present
          ? data.resolvedAtEpochMillis.value
          : this.resolvedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdaptationDecisionData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('reasonVi: $reasonVi, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('undoJson: $undoJson, ')
          ..write('createdAtEpochMillis: $createdAtEpochMillis, ')
          ..write('resolvedAtEpochMillis: $resolvedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      mode,
      status,
      reasonVi,
      payloadVersion,
      inputsJson,
      beforeJson,
      afterJson,
      undoJson,
      createdAtEpochMillis,
      resolvedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdaptationDecisionData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.reasonVi == this.reasonVi &&
          other.payloadVersion == this.payloadVersion &&
          other.inputsJson == this.inputsJson &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson &&
          other.undoJson == this.undoJson &&
          other.createdAtEpochMillis == this.createdAtEpochMillis &&
          other.resolvedAtEpochMillis == this.resolvedAtEpochMillis);
}

class AdaptationDecisionsCompanion
    extends UpdateCompanion<AdaptationDecisionData> {
  final Value<int> id;
  final Value<AdaptationKind> kind;
  final Value<AdaptationMode> mode;
  final Value<AdaptationStatus> status;
  final Value<String> reasonVi;
  final Value<int> payloadVersion;
  final Value<String> inputsJson;
  final Value<String> beforeJson;
  final Value<String> afterJson;
  final Value<String> undoJson;
  final Value<int> createdAtEpochMillis;
  final Value<int?> resolvedAtEpochMillis;
  const AdaptationDecisionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.reasonVi = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.inputsJson = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.undoJson = const Value.absent(),
    this.createdAtEpochMillis = const Value.absent(),
    this.resolvedAtEpochMillis = const Value.absent(),
  });
  AdaptationDecisionsCompanion.insert({
    this.id = const Value.absent(),
    required AdaptationKind kind,
    required AdaptationMode mode,
    required AdaptationStatus status,
    required String reasonVi,
    required int payloadVersion,
    required String inputsJson,
    required String beforeJson,
    required String afterJson,
    required String undoJson,
    required int createdAtEpochMillis,
    this.resolvedAtEpochMillis = const Value.absent(),
  })  : kind = Value(kind),
        mode = Value(mode),
        status = Value(status),
        reasonVi = Value(reasonVi),
        payloadVersion = Value(payloadVersion),
        inputsJson = Value(inputsJson),
        beforeJson = Value(beforeJson),
        afterJson = Value(afterJson),
        undoJson = Value(undoJson),
        createdAtEpochMillis = Value(createdAtEpochMillis);
  static Insertable<AdaptationDecisionData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? reasonVi,
    Expression<int>? payloadVersion,
    Expression<String>? inputsJson,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<String>? undoJson,
    Expression<int>? createdAtEpochMillis,
    Expression<int>? resolvedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (reasonVi != null) 'reason_vi': reasonVi,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (inputsJson != null) 'inputs_json': inputsJson,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (undoJson != null) 'undo_json': undoJson,
      if (createdAtEpochMillis != null)
        'created_at_epoch_millis': createdAtEpochMillis,
      if (resolvedAtEpochMillis != null)
        'resolved_at_epoch_millis': resolvedAtEpochMillis,
    });
  }

  AdaptationDecisionsCompanion copyWith(
      {Value<int>? id,
      Value<AdaptationKind>? kind,
      Value<AdaptationMode>? mode,
      Value<AdaptationStatus>? status,
      Value<String>? reasonVi,
      Value<int>? payloadVersion,
      Value<String>? inputsJson,
      Value<String>? beforeJson,
      Value<String>? afterJson,
      Value<String>? undoJson,
      Value<int>? createdAtEpochMillis,
      Value<int?>? resolvedAtEpochMillis}) {
    return AdaptationDecisionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      reasonVi: reasonVi ?? this.reasonVi,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      inputsJson: inputsJson ?? this.inputsJson,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      undoJson: undoJson ?? this.undoJson,
      createdAtEpochMillis: createdAtEpochMillis ?? this.createdAtEpochMillis,
      resolvedAtEpochMillis:
          resolvedAtEpochMillis ?? this.resolvedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
          $AdaptationDecisionsTable.$converterkind.toSql(kind.value));
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
          $AdaptationDecisionsTable.$convertermode.toSql(mode.value));
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $AdaptationDecisionsTable.$converterstatus.toSql(status.value));
    }
    if (reasonVi.present) {
      map['reason_vi'] = Variable<String>(reasonVi.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (inputsJson.present) {
      map['inputs_json'] = Variable<String>(inputsJson.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (undoJson.present) {
      map['undo_json'] = Variable<String>(undoJson.value);
    }
    if (createdAtEpochMillis.present) {
      map['created_at_epoch_millis'] =
          Variable<int>(createdAtEpochMillis.value);
    }
    if (resolvedAtEpochMillis.present) {
      map['resolved_at_epoch_millis'] =
          Variable<int>(resolvedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdaptationDecisionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('reasonVi: $reasonVi, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('undoJson: $undoJson, ')
          ..write('createdAtEpochMillis: $createdAtEpochMillis, ')
          ..write('resolvedAtEpochMillis: $resolvedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockedAtEpochMillisMeta =
      const VerificationMeta('unlockedAtEpochMillis');
  @override
  late final GeneratedColumn<int> unlockedAtEpochMillis = GeneratedColumn<int>(
      'unlocked_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [type, unlockedAtEpochMillis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(Insertable<Achievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('unlocked_at_epoch_millis')) {
      context.handle(
          _unlockedAtEpochMillisMeta,
          unlockedAtEpochMillis.isAcceptableOrUnknown(
              data['unlocked_at_epoch_millis']!, _unlockedAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      unlockedAtEpochMillis: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}unlocked_at_epoch_millis'])!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String type;
  final int unlockedAtEpochMillis;
  const Achievement({required this.type, required this.unlockedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['unlocked_at_epoch_millis'] = Variable<int>(unlockedAtEpochMillis);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      type: Value(type),
      unlockedAtEpochMillis: Value(unlockedAtEpochMillis),
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      type: serializer.fromJson<String>(json['type']),
      unlockedAtEpochMillis:
          serializer.fromJson<int>(json['unlockedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'unlockedAtEpochMillis': serializer.toJson<int>(unlockedAtEpochMillis),
    };
  }

  Achievement copyWith({String? type, int? unlockedAtEpochMillis}) =>
      Achievement(
        type: type ?? this.type,
        unlockedAtEpochMillis:
            unlockedAtEpochMillis ?? this.unlockedAtEpochMillis,
      );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      type: data.type.present ? data.type.value : this.type,
      unlockedAtEpochMillis: data.unlockedAtEpochMillis.present
          ? data.unlockedAtEpochMillis.value
          : this.unlockedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('type: $type, ')
          ..write('unlockedAtEpochMillis: $unlockedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(type, unlockedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.type == this.type &&
          other.unlockedAtEpochMillis == this.unlockedAtEpochMillis);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> type;
  final Value<int> unlockedAtEpochMillis;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.type = const Value.absent(),
    this.unlockedAtEpochMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String type,
    required int unlockedAtEpochMillis,
    this.rowid = const Value.absent(),
  })  : type = Value(type),
        unlockedAtEpochMillis = Value(unlockedAtEpochMillis);
  static Insertable<Achievement> custom({
    Expression<String>? type,
    Expression<int>? unlockedAtEpochMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (unlockedAtEpochMillis != null)
        'unlocked_at_epoch_millis': unlockedAtEpochMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith(
      {Value<String>? type,
      Value<int>? unlockedAtEpochMillis,
      Value<int>? rowid}) {
    return AchievementsCompanion(
      type: type ?? this.type,
      unlockedAtEpochMillis:
          unlockedAtEpochMillis ?? this.unlockedAtEpochMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unlockedAtEpochMillis.present) {
      map['unlocked_at_epoch_millis'] =
          Variable<int>(unlockedAtEpochMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('type: $type, ')
          ..write('unlockedAtEpochMillis: $unlockedAtEpochMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutFeedbacksTable extends WorkoutFeedbacks
    with TableInfo<$WorkoutFeedbacksTable, WorkoutFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutFeedbacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_sessions (id) ON DELETE CASCADE'));
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedEpochDayMeta =
      const VerificationMeta('completedEpochDay');
  @override
  late final GeneratedColumn<int> completedEpochDay = GeneratedColumn<int>(
      'completed_epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutDifficulty, String>
      difficulty = GeneratedColumn<String>('difficulty', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<WorkoutDifficulty>(
              $WorkoutFeedbacksTable.$converterdifficulty);
  static const VerificationMeta _recordedAtEpochMillisMeta =
      const VerificationMeta('recordedAtEpochMillis');
  @override
  late final GeneratedColumn<int> recordedAtEpochMillis = GeneratedColumn<int>(
      'recorded_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [sessionId, goalId, completedEpochDay, difficulty, recordedAtEpochMillis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_feedbacks';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutFeedbackData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('completed_epoch_day')) {
      context.handle(
          _completedEpochDayMeta,
          completedEpochDay.isAcceptableOrUnknown(
              data['completed_epoch_day']!, _completedEpochDayMeta));
    } else if (isInserting) {
      context.missing(_completedEpochDayMeta);
    }
    if (data.containsKey('recorded_at_epoch_millis')) {
      context.handle(
          _recordedAtEpochMillisMeta,
          recordedAtEpochMillis.isAcceptableOrUnknown(
              data['recorded_at_epoch_millis']!, _recordedAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_recordedAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  WorkoutFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutFeedbackData(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}goal_id'])!,
      completedEpochDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_epoch_day'])!,
      difficulty: $WorkoutFeedbacksTable.$converterdifficulty.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}difficulty'])!),
      recordedAtEpochMillis: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}recorded_at_epoch_millis'])!,
    );
  }

  @override
  $WorkoutFeedbacksTable createAlias(String alias) {
    return $WorkoutFeedbacksTable(attachedDatabase, alias);
  }

  static TypeConverter<WorkoutDifficulty, String> $converterdifficulty =
      const WorkoutDifficultyConverter();
}

class WorkoutFeedbackData extends DataClass
    implements Insertable<WorkoutFeedbackData> {
  final int sessionId;
  final int goalId;
  final int completedEpochDay;
  final WorkoutDifficulty difficulty;
  final int recordedAtEpochMillis;
  const WorkoutFeedbackData(
      {required this.sessionId,
      required this.goalId,
      required this.completedEpochDay,
      required this.difficulty,
      required this.recordedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['goal_id'] = Variable<int>(goalId);
    map['completed_epoch_day'] = Variable<int>(completedEpochDay);
    {
      map['difficulty'] = Variable<String>(
          $WorkoutFeedbacksTable.$converterdifficulty.toSql(difficulty));
    }
    map['recorded_at_epoch_millis'] = Variable<int>(recordedAtEpochMillis);
    return map;
  }

  WorkoutFeedbacksCompanion toCompanion(bool nullToAbsent) {
    return WorkoutFeedbacksCompanion(
      sessionId: Value(sessionId),
      goalId: Value(goalId),
      completedEpochDay: Value(completedEpochDay),
      difficulty: Value(difficulty),
      recordedAtEpochMillis: Value(recordedAtEpochMillis),
    );
  }

  factory WorkoutFeedbackData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutFeedbackData(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      goalId: serializer.fromJson<int>(json['goalId']),
      completedEpochDay: serializer.fromJson<int>(json['completedEpochDay']),
      difficulty: serializer.fromJson<WorkoutDifficulty>(json['difficulty']),
      recordedAtEpochMillis:
          serializer.fromJson<int>(json['recordedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'goalId': serializer.toJson<int>(goalId),
      'completedEpochDay': serializer.toJson<int>(completedEpochDay),
      'difficulty': serializer.toJson<WorkoutDifficulty>(difficulty),
      'recordedAtEpochMillis': serializer.toJson<int>(recordedAtEpochMillis),
    };
  }

  WorkoutFeedbackData copyWith(
          {int? sessionId,
          int? goalId,
          int? completedEpochDay,
          WorkoutDifficulty? difficulty,
          int? recordedAtEpochMillis}) =>
      WorkoutFeedbackData(
        sessionId: sessionId ?? this.sessionId,
        goalId: goalId ?? this.goalId,
        completedEpochDay: completedEpochDay ?? this.completedEpochDay,
        difficulty: difficulty ?? this.difficulty,
        recordedAtEpochMillis:
            recordedAtEpochMillis ?? this.recordedAtEpochMillis,
      );
  WorkoutFeedbackData copyWithCompanion(WorkoutFeedbacksCompanion data) {
    return WorkoutFeedbackData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      completedEpochDay: data.completedEpochDay.present
          ? data.completedEpochDay.value
          : this.completedEpochDay,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      recordedAtEpochMillis: data.recordedAtEpochMillis.present
          ? data.recordedAtEpochMillis.value
          : this.recordedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutFeedbackData(')
          ..write('sessionId: $sessionId, ')
          ..write('goalId: $goalId, ')
          ..write('completedEpochDay: $completedEpochDay, ')
          ..write('difficulty: $difficulty, ')
          ..write('recordedAtEpochMillis: $recordedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId, goalId, completedEpochDay, difficulty, recordedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutFeedbackData &&
          other.sessionId == this.sessionId &&
          other.goalId == this.goalId &&
          other.completedEpochDay == this.completedEpochDay &&
          other.difficulty == this.difficulty &&
          other.recordedAtEpochMillis == this.recordedAtEpochMillis);
}

class WorkoutFeedbacksCompanion extends UpdateCompanion<WorkoutFeedbackData> {
  final Value<int> sessionId;
  final Value<int> goalId;
  final Value<int> completedEpochDay;
  final Value<WorkoutDifficulty> difficulty;
  final Value<int> recordedAtEpochMillis;
  const WorkoutFeedbacksCompanion({
    this.sessionId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.completedEpochDay = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.recordedAtEpochMillis = const Value.absent(),
  });
  WorkoutFeedbacksCompanion.insert({
    this.sessionId = const Value.absent(),
    required int goalId,
    required int completedEpochDay,
    required WorkoutDifficulty difficulty,
    required int recordedAtEpochMillis,
  })  : goalId = Value(goalId),
        completedEpochDay = Value(completedEpochDay),
        difficulty = Value(difficulty),
        recordedAtEpochMillis = Value(recordedAtEpochMillis);
  static Insertable<WorkoutFeedbackData> custom({
    Expression<int>? sessionId,
    Expression<int>? goalId,
    Expression<int>? completedEpochDay,
    Expression<String>? difficulty,
    Expression<int>? recordedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (goalId != null) 'goal_id': goalId,
      if (completedEpochDay != null) 'completed_epoch_day': completedEpochDay,
      if (difficulty != null) 'difficulty': difficulty,
      if (recordedAtEpochMillis != null)
        'recorded_at_epoch_millis': recordedAtEpochMillis,
    });
  }

  WorkoutFeedbacksCompanion copyWith(
      {Value<int>? sessionId,
      Value<int>? goalId,
      Value<int>? completedEpochDay,
      Value<WorkoutDifficulty>? difficulty,
      Value<int>? recordedAtEpochMillis}) {
    return WorkoutFeedbacksCompanion(
      sessionId: sessionId ?? this.sessionId,
      goalId: goalId ?? this.goalId,
      completedEpochDay: completedEpochDay ?? this.completedEpochDay,
      difficulty: difficulty ?? this.difficulty,
      recordedAtEpochMillis:
          recordedAtEpochMillis ?? this.recordedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (completedEpochDay.present) {
      map['completed_epoch_day'] = Variable<int>(completedEpochDay.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(
          $WorkoutFeedbacksTable.$converterdifficulty.toSql(difficulty.value));
    }
    if (recordedAtEpochMillis.present) {
      map['recorded_at_epoch_millis'] =
          Variable<int>(recordedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutFeedbacksCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('goalId: $goalId, ')
          ..write('completedEpochDay: $completedEpochDay, ')
          ..write('difficulty: $difficulty, ')
          ..write('recordedAtEpochMillis: $recordedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $MealTemplatesTable extends MealTemplates
    with TableInfo<$MealTemplatesTable, MealTemplateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameViMeta = const VerificationMeta('nameVi');
  @override
  late final GeneratedColumn<String> nameVi = GeneratedColumn<String>(
      'name_vi', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE');
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _proteinGramsMeta =
      const VerificationMeta('proteinGrams');
  @override
  late final GeneratedColumn<int> proteinGrams = GeneratedColumn<int>(
      'protein_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _carbsGramsMeta =
      const VerificationMeta('carbsGrams');
  @override
  late final GeneratedColumn<int> carbsGrams = GeneratedColumn<int>(
      'carbs_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fatGramsMeta =
      const VerificationMeta('fatGrams');
  @override
  late final GeneratedColumn<int> fatGrams = GeneratedColumn<int>(
      'fat_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fiberGramsMeta =
      const VerificationMeta('fiberGrams');
  @override
  late final GeneratedColumn<int> fiberGrams = GeneratedColumn<int>(
      'fiber_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtEpochMillisMeta =
      const VerificationMeta('updatedAtEpochMillis');
  @override
  late final GeneratedColumn<int> updatedAtEpochMillis = GeneratedColumn<int>(
      'updated_at_epoch_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nameVi,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        fiberGrams,
        updatedAtEpochMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_templates';
  @override
  VerificationContext validateIntegrity(Insertable<MealTemplateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_vi')) {
      context.handle(_nameViMeta,
          nameVi.isAcceptableOrUnknown(data['name_vi']!, _nameViMeta));
    } else if (isInserting) {
      context.missing(_nameViMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
          _proteinGramsMeta,
          proteinGrams.isAcceptableOrUnknown(
              data['protein_grams']!, _proteinGramsMeta));
    } else if (isInserting) {
      context.missing(_proteinGramsMeta);
    }
    if (data.containsKey('carbs_grams')) {
      context.handle(
          _carbsGramsMeta,
          carbsGrams.isAcceptableOrUnknown(
              data['carbs_grams']!, _carbsGramsMeta));
    } else if (isInserting) {
      context.missing(_carbsGramsMeta);
    }
    if (data.containsKey('fat_grams')) {
      context.handle(_fatGramsMeta,
          fatGrams.isAcceptableOrUnknown(data['fat_grams']!, _fatGramsMeta));
    } else if (isInserting) {
      context.missing(_fatGramsMeta);
    }
    if (data.containsKey('fiber_grams')) {
      context.handle(
          _fiberGramsMeta,
          fiberGrams.isAcceptableOrUnknown(
              data['fiber_grams']!, _fiberGramsMeta));
    }
    if (data.containsKey('updated_at_epoch_millis')) {
      context.handle(
          _updatedAtEpochMillisMeta,
          updatedAtEpochMillis.isAcceptableOrUnknown(
              data['updated_at_epoch_millis']!, _updatedAtEpochMillisMeta));
    } else if (isInserting) {
      context.missing(_updatedAtEpochMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nameVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_vi'])!,
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories'])!,
      proteinGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protein_grams'])!,
      carbsGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}carbs_grams'])!,
      fatGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fat_grams'])!,
      fiberGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiber_grams'])!,
      updatedAtEpochMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}updated_at_epoch_millis'])!,
    );
  }

  @override
  $MealTemplatesTable createAlias(String alias) {
    return $MealTemplatesTable(attachedDatabase, alias);
  }
}

class MealTemplateData extends DataClass
    implements Insertable<MealTemplateData> {
  final int id;
  final String nameVi;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int fiberGrams;
  final int updatedAtEpochMillis;
  const MealTemplateData(
      {required this.id,
      required this.nameVi,
      required this.calories,
      required this.proteinGrams,
      required this.carbsGrams,
      required this.fatGrams,
      required this.fiberGrams,
      required this.updatedAtEpochMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_vi'] = Variable<String>(nameVi);
    map['calories'] = Variable<int>(calories);
    map['protein_grams'] = Variable<int>(proteinGrams);
    map['carbs_grams'] = Variable<int>(carbsGrams);
    map['fat_grams'] = Variable<int>(fatGrams);
    map['fiber_grams'] = Variable<int>(fiberGrams);
    map['updated_at_epoch_millis'] = Variable<int>(updatedAtEpochMillis);
    return map;
  }

  MealTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MealTemplatesCompanion(
      id: Value(id),
      nameVi: Value(nameVi),
      calories: Value(calories),
      proteinGrams: Value(proteinGrams),
      carbsGrams: Value(carbsGrams),
      fatGrams: Value(fatGrams),
      fiberGrams: Value(fiberGrams),
      updatedAtEpochMillis: Value(updatedAtEpochMillis),
    );
  }

  factory MealTemplateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplateData(
      id: serializer.fromJson<int>(json['id']),
      nameVi: serializer.fromJson<String>(json['nameVi']),
      calories: serializer.fromJson<int>(json['calories']),
      proteinGrams: serializer.fromJson<int>(json['proteinGrams']),
      carbsGrams: serializer.fromJson<int>(json['carbsGrams']),
      fatGrams: serializer.fromJson<int>(json['fatGrams']),
      fiberGrams: serializer.fromJson<int>(json['fiberGrams']),
      updatedAtEpochMillis:
          serializer.fromJson<int>(json['updatedAtEpochMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameVi': serializer.toJson<String>(nameVi),
      'calories': serializer.toJson<int>(calories),
      'proteinGrams': serializer.toJson<int>(proteinGrams),
      'carbsGrams': serializer.toJson<int>(carbsGrams),
      'fatGrams': serializer.toJson<int>(fatGrams),
      'fiberGrams': serializer.toJson<int>(fiberGrams),
      'updatedAtEpochMillis': serializer.toJson<int>(updatedAtEpochMillis),
    };
  }

  MealTemplateData copyWith(
          {int? id,
          String? nameVi,
          int? calories,
          int? proteinGrams,
          int? carbsGrams,
          int? fatGrams,
          int? fiberGrams,
          int? updatedAtEpochMillis}) =>
      MealTemplateData(
        id: id ?? this.id,
        nameVi: nameVi ?? this.nameVi,
        calories: calories ?? this.calories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        carbsGrams: carbsGrams ?? this.carbsGrams,
        fatGrams: fatGrams ?? this.fatGrams,
        fiberGrams: fiberGrams ?? this.fiberGrams,
        updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
      );
  MealTemplateData copyWithCompanion(MealTemplatesCompanion data) {
    return MealTemplateData(
      id: data.id.present ? data.id.value : this.id,
      nameVi: data.nameVi.present ? data.nameVi.value : this.nameVi,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      carbsGrams:
          data.carbsGrams.present ? data.carbsGrams.value : this.carbsGrams,
      fatGrams: data.fatGrams.present ? data.fatGrams.value : this.fatGrams,
      fiberGrams:
          data.fiberGrams.present ? data.fiberGrams.value : this.fiberGrams,
      updatedAtEpochMillis: data.updatedAtEpochMillis.present
          ? data.updatedAtEpochMillis.value
          : this.updatedAtEpochMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplateData(')
          ..write('id: $id, ')
          ..write('nameVi: $nameVi, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nameVi, calories, proteinGrams,
      carbsGrams, fatGrams, fiberGrams, updatedAtEpochMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplateData &&
          other.id == this.id &&
          other.nameVi == this.nameVi &&
          other.calories == this.calories &&
          other.proteinGrams == this.proteinGrams &&
          other.carbsGrams == this.carbsGrams &&
          other.fatGrams == this.fatGrams &&
          other.fiberGrams == this.fiberGrams &&
          other.updatedAtEpochMillis == this.updatedAtEpochMillis);
}

class MealTemplatesCompanion extends UpdateCompanion<MealTemplateData> {
  final Value<int> id;
  final Value<String> nameVi;
  final Value<int> calories;
  final Value<int> proteinGrams;
  final Value<int> carbsGrams;
  final Value<int> fatGrams;
  final Value<int> fiberGrams;
  final Value<int> updatedAtEpochMillis;
  const MealTemplatesCompanion({
    this.id = const Value.absent(),
    this.nameVi = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbsGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.fiberGrams = const Value.absent(),
    this.updatedAtEpochMillis = const Value.absent(),
  });
  MealTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String nameVi,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    this.fiberGrams = const Value.absent(),
    required int updatedAtEpochMillis,
  })  : nameVi = Value(nameVi),
        calories = Value(calories),
        proteinGrams = Value(proteinGrams),
        carbsGrams = Value(carbsGrams),
        fatGrams = Value(fatGrams),
        updatedAtEpochMillis = Value(updatedAtEpochMillis);
  static Insertable<MealTemplateData> custom({
    Expression<int>? id,
    Expression<String>? nameVi,
    Expression<int>? calories,
    Expression<int>? proteinGrams,
    Expression<int>? carbsGrams,
    Expression<int>? fatGrams,
    Expression<int>? fiberGrams,
    Expression<int>? updatedAtEpochMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameVi != null) 'name_vi': nameVi,
      if (calories != null) 'calories': calories,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (carbsGrams != null) 'carbs_grams': carbsGrams,
      if (fatGrams != null) 'fat_grams': fatGrams,
      if (fiberGrams != null) 'fiber_grams': fiberGrams,
      if (updatedAtEpochMillis != null)
        'updated_at_epoch_millis': updatedAtEpochMillis,
    });
  }

  MealTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? nameVi,
      Value<int>? calories,
      Value<int>? proteinGrams,
      Value<int>? carbsGrams,
      Value<int>? fatGrams,
      Value<int>? fiberGrams,
      Value<int>? updatedAtEpochMillis}) {
    return MealTemplatesCompanion(
      id: id ?? this.id,
      nameVi: nameVi ?? this.nameVi,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameVi.present) {
      map['name_vi'] = Variable<String>(nameVi.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<int>(proteinGrams.value);
    }
    if (carbsGrams.present) {
      map['carbs_grams'] = Variable<int>(carbsGrams.value);
    }
    if (fatGrams.present) {
      map['fat_grams'] = Variable<int>(fatGrams.value);
    }
    if (fiberGrams.present) {
      map['fiber_grams'] = Variable<int>(fiberGrams.value);
    }
    if (updatedAtEpochMillis.present) {
      map['updated_at_epoch_millis'] =
          Variable<int>(updatedAtEpochMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('nameVi: $nameVi, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('updatedAtEpochMillis: $updatedAtEpochMillis')
          ..write(')'))
        .toString();
  }
}

class $UserFoodOverridesTable extends UserFoodOverrides
    with TableInfo<$UserFoodOverridesTable, UserFoodOverrideData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFoodOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dishNameMeta =
      const VerificationMeta('dishName');
  @override
  late final GeneratedColumn<String> dishName = GeneratedColumn<String>(
      'dish_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalCaloriesMeta =
      const VerificationMeta('totalCalories');
  @override
  late final GeneratedColumn<int> totalCalories = GeneratedColumn<int>(
      'total_calories', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _proteinGramsMeta =
      const VerificationMeta('proteinGrams');
  @override
  late final GeneratedColumn<int> proteinGrams = GeneratedColumn<int>(
      'protein_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _carbsGramsMeta =
      const VerificationMeta('carbsGrams');
  @override
  late final GeneratedColumn<int> carbsGrams = GeneratedColumn<int>(
      'carbs_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fatGramsMeta =
      const VerificationMeta('fatGrams');
  @override
  late final GeneratedColumn<int> fatGrams = GeneratedColumn<int>(
      'fat_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [dishName, totalCalories, proteinGrams, carbsGrams, fatGrams];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_food_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserFoodOverrideData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dish_name')) {
      context.handle(_dishNameMeta,
          dishName.isAcceptableOrUnknown(data['dish_name']!, _dishNameMeta));
    } else if (isInserting) {
      context.missing(_dishNameMeta);
    }
    if (data.containsKey('total_calories')) {
      context.handle(
          _totalCaloriesMeta,
          totalCalories.isAcceptableOrUnknown(
              data['total_calories']!, _totalCaloriesMeta));
    } else if (isInserting) {
      context.missing(_totalCaloriesMeta);
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
          _proteinGramsMeta,
          proteinGrams.isAcceptableOrUnknown(
              data['protein_grams']!, _proteinGramsMeta));
    } else if (isInserting) {
      context.missing(_proteinGramsMeta);
    }
    if (data.containsKey('carbs_grams')) {
      context.handle(
          _carbsGramsMeta,
          carbsGrams.isAcceptableOrUnknown(
              data['carbs_grams']!, _carbsGramsMeta));
    } else if (isInserting) {
      context.missing(_carbsGramsMeta);
    }
    if (data.containsKey('fat_grams')) {
      context.handle(_fatGramsMeta,
          fatGrams.isAcceptableOrUnknown(data['fat_grams']!, _fatGramsMeta));
    } else if (isInserting) {
      context.missing(_fatGramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dishName};
  @override
  UserFoodOverrideData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFoodOverrideData(
      dishName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dish_name'])!,
      totalCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_calories'])!,
      proteinGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protein_grams'])!,
      carbsGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}carbs_grams'])!,
      fatGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fat_grams'])!,
    );
  }

  @override
  $UserFoodOverridesTable createAlias(String alias) {
    return $UserFoodOverridesTable(attachedDatabase, alias);
  }
}

class UserFoodOverrideData extends DataClass
    implements Insertable<UserFoodOverrideData> {
  final String dishName;
  final int totalCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  const UserFoodOverrideData(
      {required this.dishName,
      required this.totalCalories,
      required this.proteinGrams,
      required this.carbsGrams,
      required this.fatGrams});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dish_name'] = Variable<String>(dishName);
    map['total_calories'] = Variable<int>(totalCalories);
    map['protein_grams'] = Variable<int>(proteinGrams);
    map['carbs_grams'] = Variable<int>(carbsGrams);
    map['fat_grams'] = Variable<int>(fatGrams);
    return map;
  }

  UserFoodOverridesCompanion toCompanion(bool nullToAbsent) {
    return UserFoodOverridesCompanion(
      dishName: Value(dishName),
      totalCalories: Value(totalCalories),
      proteinGrams: Value(proteinGrams),
      carbsGrams: Value(carbsGrams),
      fatGrams: Value(fatGrams),
    );
  }

  factory UserFoodOverrideData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFoodOverrideData(
      dishName: serializer.fromJson<String>(json['dishName']),
      totalCalories: serializer.fromJson<int>(json['totalCalories']),
      proteinGrams: serializer.fromJson<int>(json['proteinGrams']),
      carbsGrams: serializer.fromJson<int>(json['carbsGrams']),
      fatGrams: serializer.fromJson<int>(json['fatGrams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dishName': serializer.toJson<String>(dishName),
      'totalCalories': serializer.toJson<int>(totalCalories),
      'proteinGrams': serializer.toJson<int>(proteinGrams),
      'carbsGrams': serializer.toJson<int>(carbsGrams),
      'fatGrams': serializer.toJson<int>(fatGrams),
    };
  }

  UserFoodOverrideData copyWith(
          {String? dishName,
          int? totalCalories,
          int? proteinGrams,
          int? carbsGrams,
          int? fatGrams}) =>
      UserFoodOverrideData(
        dishName: dishName ?? this.dishName,
        totalCalories: totalCalories ?? this.totalCalories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        carbsGrams: carbsGrams ?? this.carbsGrams,
        fatGrams: fatGrams ?? this.fatGrams,
      );
  UserFoodOverrideData copyWithCompanion(UserFoodOverridesCompanion data) {
    return UserFoodOverrideData(
      dishName: data.dishName.present ? data.dishName.value : this.dishName,
      totalCalories: data.totalCalories.present
          ? data.totalCalories.value
          : this.totalCalories,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      carbsGrams:
          data.carbsGrams.present ? data.carbsGrams.value : this.carbsGrams,
      fatGrams: data.fatGrams.present ? data.fatGrams.value : this.fatGrams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFoodOverrideData(')
          ..write('dishName: $dishName, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dishName, totalCalories, proteinGrams, carbsGrams, fatGrams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFoodOverrideData &&
          other.dishName == this.dishName &&
          other.totalCalories == this.totalCalories &&
          other.proteinGrams == this.proteinGrams &&
          other.carbsGrams == this.carbsGrams &&
          other.fatGrams == this.fatGrams);
}

class UserFoodOverridesCompanion extends UpdateCompanion<UserFoodOverrideData> {
  final Value<String> dishName;
  final Value<int> totalCalories;
  final Value<int> proteinGrams;
  final Value<int> carbsGrams;
  final Value<int> fatGrams;
  final Value<int> rowid;
  const UserFoodOverridesCompanion({
    this.dishName = const Value.absent(),
    this.totalCalories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbsGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserFoodOverridesCompanion.insert({
    required String dishName,
    required int totalCalories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    this.rowid = const Value.absent(),
  })  : dishName = Value(dishName),
        totalCalories = Value(totalCalories),
        proteinGrams = Value(proteinGrams),
        carbsGrams = Value(carbsGrams),
        fatGrams = Value(fatGrams);
  static Insertable<UserFoodOverrideData> custom({
    Expression<String>? dishName,
    Expression<int>? totalCalories,
    Expression<int>? proteinGrams,
    Expression<int>? carbsGrams,
    Expression<int>? fatGrams,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dishName != null) 'dish_name': dishName,
      if (totalCalories != null) 'total_calories': totalCalories,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (carbsGrams != null) 'carbs_grams': carbsGrams,
      if (fatGrams != null) 'fat_grams': fatGrams,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserFoodOverridesCompanion copyWith(
      {Value<String>? dishName,
      Value<int>? totalCalories,
      Value<int>? proteinGrams,
      Value<int>? carbsGrams,
      Value<int>? fatGrams,
      Value<int>? rowid}) {
    return UserFoodOverridesCompanion(
      dishName: dishName ?? this.dishName,
      totalCalories: totalCalories ?? this.totalCalories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dishName.present) {
      map['dish_name'] = Variable<String>(dishName.value);
    }
    if (totalCalories.present) {
      map['total_calories'] = Variable<int>(totalCalories.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<int>(proteinGrams.value);
    }
    if (carbsGrams.present) {
      map['carbs_grams'] = Variable<int>(carbsGrams.value);
    }
    if (fatGrams.present) {
      map['fat_grams'] = Variable<int>(fatGrams.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFoodOverridesCompanion(')
          ..write('dishName: $dishName, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodCatalogTable extends FoodCatalog
    with TableInfo<$FoodCatalogTable, FoodCatalogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodCatalogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gramsPerServingMeta =
      const VerificationMeta('gramsPerServing');
  @override
  late final GeneratedColumn<double> gramsPerServing = GeneratedColumn<double>(
      'grams_per_serving', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100.0));
  static const VerificationMeta _caloriesPerServingMeta =
      const VerificationMeta('caloriesPerServing');
  @override
  late final GeneratedColumn<double> caloriesPerServing =
      GeneratedColumn<double>('calories_per_serving', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _fatPerServingMeta =
      const VerificationMeta('fatPerServing');
  @override
  late final GeneratedColumn<double> fatPerServing = GeneratedColumn<double>(
      'fat_per_serving', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _carbsPerServingMeta =
      const VerificationMeta('carbsPerServing');
  @override
  late final GeneratedColumn<double> carbsPerServing = GeneratedColumn<double>(
      'carbs_per_serving', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _proteinPerServingMeta =
      const VerificationMeta('proteinPerServing');
  @override
  late final GeneratedColumn<double> proteinPerServing =
      GeneratedColumn<double>('protein_per_serving', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _potassiumMgMeta =
      const VerificationMeta('potassiumMg');
  @override
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
      'potassium_mg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sodiumMgMeta =
      const VerificationMeta('sodiumMg');
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
      'sodium_mg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _cholesterolMgMeta =
      const VerificationMeta('cholesterolMg');
  @override
  late final GeneratedColumn<double> cholesterolMg = GeneratedColumn<double>(
      'cholesterol_mg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _fiberPerServingMeta =
      const VerificationMeta('fiberPerServing');
  @override
  late final GeneratedColumn<double> fiberPerServing = GeneratedColumn<double>(
      'fiber_per_serving', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _importBatchIdMeta =
      const VerificationMeta('importBatchId');
  @override
  late final GeneratedColumn<String> importBatchId = GeneratedColumn<String>(
      'import_batch_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        gramsPerServing,
        caloriesPerServing,
        fatPerServing,
        carbsPerServing,
        proteinPerServing,
        potassiumMg,
        sodiumMg,
        cholesterolMg,
        fiberPerServing,
        importBatchId,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_catalog';
  @override
  VerificationContext validateIntegrity(Insertable<FoodCatalogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams_per_serving')) {
      context.handle(
          _gramsPerServingMeta,
          gramsPerServing.isAcceptableOrUnknown(
              data['grams_per_serving']!, _gramsPerServingMeta));
    }
    if (data.containsKey('calories_per_serving')) {
      context.handle(
          _caloriesPerServingMeta,
          caloriesPerServing.isAcceptableOrUnknown(
              data['calories_per_serving']!, _caloriesPerServingMeta));
    }
    if (data.containsKey('fat_per_serving')) {
      context.handle(
          _fatPerServingMeta,
          fatPerServing.isAcceptableOrUnknown(
              data['fat_per_serving']!, _fatPerServingMeta));
    }
    if (data.containsKey('carbs_per_serving')) {
      context.handle(
          _carbsPerServingMeta,
          carbsPerServing.isAcceptableOrUnknown(
              data['carbs_per_serving']!, _carbsPerServingMeta));
    }
    if (data.containsKey('protein_per_serving')) {
      context.handle(
          _proteinPerServingMeta,
          proteinPerServing.isAcceptableOrUnknown(
              data['protein_per_serving']!, _proteinPerServingMeta));
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
          _potassiumMgMeta,
          potassiumMg.isAcceptableOrUnknown(
              data['potassium_mg']!, _potassiumMgMeta));
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(_sodiumMgMeta,
          sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta));
    }
    if (data.containsKey('cholesterol_mg')) {
      context.handle(
          _cholesterolMgMeta,
          cholesterolMg.isAcceptableOrUnknown(
              data['cholesterol_mg']!, _cholesterolMgMeta));
    }
    if (data.containsKey('fiber_per_serving')) {
      context.handle(
          _fiberPerServingMeta,
          fiberPerServing.isAcceptableOrUnknown(
              data['fiber_per_serving']!, _fiberPerServingMeta));
    }
    if (data.containsKey('import_batch_id')) {
      context.handle(
          _importBatchIdMeta,
          importBatchId.isAcceptableOrUnknown(
              data['import_batch_id']!, _importBatchIdMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodCatalogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodCatalogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      gramsPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}grams_per_serving'])!,
      caloriesPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}calories_per_serving'])!,
      fatPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fat_per_serving'])!,
      carbsPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}carbs_per_serving'])!,
      proteinPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}protein_per_serving'])!,
      potassiumMg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}potassium_mg'])!,
      sodiumMg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sodium_mg'])!,
      cholesterolMg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cholesterol_mg'])!,
      fiberPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fiber_per_serving'])!,
      importBatchId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}import_batch_id'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $FoodCatalogTable createAlias(String alias) {
    return $FoodCatalogTable(attachedDatabase, alias);
  }
}

class FoodCatalogData extends DataClass implements Insertable<FoodCatalogData> {
  final int id;
  final String name;
  final double gramsPerServing;
  final double caloriesPerServing;
  final double fatPerServing;
  final double carbsPerServing;
  final double proteinPerServing;
  final double potassiumMg;
  final double sodiumMg;
  final double cholesterolMg;
  final double fiberPerServing;
  final String importBatchId;
  final bool isFavorite;
  const FoodCatalogData(
      {required this.id,
      required this.name,
      required this.gramsPerServing,
      required this.caloriesPerServing,
      required this.fatPerServing,
      required this.carbsPerServing,
      required this.proteinPerServing,
      required this.potassiumMg,
      required this.sodiumMg,
      required this.cholesterolMg,
      required this.fiberPerServing,
      required this.importBatchId,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grams_per_serving'] = Variable<double>(gramsPerServing);
    map['calories_per_serving'] = Variable<double>(caloriesPerServing);
    map['fat_per_serving'] = Variable<double>(fatPerServing);
    map['carbs_per_serving'] = Variable<double>(carbsPerServing);
    map['protein_per_serving'] = Variable<double>(proteinPerServing);
    map['potassium_mg'] = Variable<double>(potassiumMg);
    map['sodium_mg'] = Variable<double>(sodiumMg);
    map['cholesterol_mg'] = Variable<double>(cholesterolMg);
    map['fiber_per_serving'] = Variable<double>(fiberPerServing);
    map['import_batch_id'] = Variable<String>(importBatchId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  FoodCatalogCompanion toCompanion(bool nullToAbsent) {
    return FoodCatalogCompanion(
      id: Value(id),
      name: Value(name),
      gramsPerServing: Value(gramsPerServing),
      caloriesPerServing: Value(caloriesPerServing),
      fatPerServing: Value(fatPerServing),
      carbsPerServing: Value(carbsPerServing),
      proteinPerServing: Value(proteinPerServing),
      potassiumMg: Value(potassiumMg),
      sodiumMg: Value(sodiumMg),
      cholesterolMg: Value(cholesterolMg),
      fiberPerServing: Value(fiberPerServing),
      importBatchId: Value(importBatchId),
      isFavorite: Value(isFavorite),
    );
  }

  factory FoodCatalogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodCatalogData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gramsPerServing: serializer.fromJson<double>(json['gramsPerServing']),
      caloriesPerServing:
          serializer.fromJson<double>(json['caloriesPerServing']),
      fatPerServing: serializer.fromJson<double>(json['fatPerServing']),
      carbsPerServing: serializer.fromJson<double>(json['carbsPerServing']),
      proteinPerServing: serializer.fromJson<double>(json['proteinPerServing']),
      potassiumMg: serializer.fromJson<double>(json['potassiumMg']),
      sodiumMg: serializer.fromJson<double>(json['sodiumMg']),
      cholesterolMg: serializer.fromJson<double>(json['cholesterolMg']),
      fiberPerServing: serializer.fromJson<double>(json['fiberPerServing']),
      importBatchId: serializer.fromJson<String>(json['importBatchId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gramsPerServing': serializer.toJson<double>(gramsPerServing),
      'caloriesPerServing': serializer.toJson<double>(caloriesPerServing),
      'fatPerServing': serializer.toJson<double>(fatPerServing),
      'carbsPerServing': serializer.toJson<double>(carbsPerServing),
      'proteinPerServing': serializer.toJson<double>(proteinPerServing),
      'potassiumMg': serializer.toJson<double>(potassiumMg),
      'sodiumMg': serializer.toJson<double>(sodiumMg),
      'cholesterolMg': serializer.toJson<double>(cholesterolMg),
      'fiberPerServing': serializer.toJson<double>(fiberPerServing),
      'importBatchId': serializer.toJson<String>(importBatchId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  FoodCatalogData copyWith(
          {int? id,
          String? name,
          double? gramsPerServing,
          double? caloriesPerServing,
          double? fatPerServing,
          double? carbsPerServing,
          double? proteinPerServing,
          double? potassiumMg,
          double? sodiumMg,
          double? cholesterolMg,
          double? fiberPerServing,
          String? importBatchId,
          bool? isFavorite}) =>
      FoodCatalogData(
        id: id ?? this.id,
        name: name ?? this.name,
        gramsPerServing: gramsPerServing ?? this.gramsPerServing,
        caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
        fatPerServing: fatPerServing ?? this.fatPerServing,
        carbsPerServing: carbsPerServing ?? this.carbsPerServing,
        proteinPerServing: proteinPerServing ?? this.proteinPerServing,
        potassiumMg: potassiumMg ?? this.potassiumMg,
        sodiumMg: sodiumMg ?? this.sodiumMg,
        cholesterolMg: cholesterolMg ?? this.cholesterolMg,
        fiberPerServing: fiberPerServing ?? this.fiberPerServing,
        importBatchId: importBatchId ?? this.importBatchId,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  FoodCatalogData copyWithCompanion(FoodCatalogCompanion data) {
    return FoodCatalogData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gramsPerServing: data.gramsPerServing.present
          ? data.gramsPerServing.value
          : this.gramsPerServing,
      caloriesPerServing: data.caloriesPerServing.present
          ? data.caloriesPerServing.value
          : this.caloriesPerServing,
      fatPerServing: data.fatPerServing.present
          ? data.fatPerServing.value
          : this.fatPerServing,
      carbsPerServing: data.carbsPerServing.present
          ? data.carbsPerServing.value
          : this.carbsPerServing,
      proteinPerServing: data.proteinPerServing.present
          ? data.proteinPerServing.value
          : this.proteinPerServing,
      potassiumMg:
          data.potassiumMg.present ? data.potassiumMg.value : this.potassiumMg,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      cholesterolMg: data.cholesterolMg.present
          ? data.cholesterolMg.value
          : this.cholesterolMg,
      fiberPerServing: data.fiberPerServing.present
          ? data.fiberPerServing.value
          : this.fiberPerServing,
      importBatchId: data.importBatchId.present
          ? data.importBatchId.value
          : this.importBatchId,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodCatalogData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gramsPerServing: $gramsPerServing, ')
          ..write('caloriesPerServing: $caloriesPerServing, ')
          ..write('fatPerServing: $fatPerServing, ')
          ..write('carbsPerServing: $carbsPerServing, ')
          ..write('proteinPerServing: $proteinPerServing, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('fiberPerServing: $fiberPerServing, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      gramsPerServing,
      caloriesPerServing,
      fatPerServing,
      carbsPerServing,
      proteinPerServing,
      potassiumMg,
      sodiumMg,
      cholesterolMg,
      fiberPerServing,
      importBatchId,
      isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodCatalogData &&
          other.id == this.id &&
          other.name == this.name &&
          other.gramsPerServing == this.gramsPerServing &&
          other.caloriesPerServing == this.caloriesPerServing &&
          other.fatPerServing == this.fatPerServing &&
          other.carbsPerServing == this.carbsPerServing &&
          other.proteinPerServing == this.proteinPerServing &&
          other.potassiumMg == this.potassiumMg &&
          other.sodiumMg == this.sodiumMg &&
          other.cholesterolMg == this.cholesterolMg &&
          other.fiberPerServing == this.fiberPerServing &&
          other.importBatchId == this.importBatchId &&
          other.isFavorite == this.isFavorite);
}

class FoodCatalogCompanion extends UpdateCompanion<FoodCatalogData> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> gramsPerServing;
  final Value<double> caloriesPerServing;
  final Value<double> fatPerServing;
  final Value<double> carbsPerServing;
  final Value<double> proteinPerServing;
  final Value<double> potassiumMg;
  final Value<double> sodiumMg;
  final Value<double> cholesterolMg;
  final Value<double> fiberPerServing;
  final Value<String> importBatchId;
  final Value<bool> isFavorite;
  const FoodCatalogCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gramsPerServing = const Value.absent(),
    this.caloriesPerServing = const Value.absent(),
    this.fatPerServing = const Value.absent(),
    this.carbsPerServing = const Value.absent(),
    this.proteinPerServing = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.fiberPerServing = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  FoodCatalogCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.gramsPerServing = const Value.absent(),
    this.caloriesPerServing = const Value.absent(),
    this.fatPerServing = const Value.absent(),
    this.carbsPerServing = const Value.absent(),
    this.proteinPerServing = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.fiberPerServing = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.isFavorite = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FoodCatalogData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? gramsPerServing,
    Expression<double>? caloriesPerServing,
    Expression<double>? fatPerServing,
    Expression<double>? carbsPerServing,
    Expression<double>? proteinPerServing,
    Expression<double>? potassiumMg,
    Expression<double>? sodiumMg,
    Expression<double>? cholesterolMg,
    Expression<double>? fiberPerServing,
    Expression<String>? importBatchId,
    Expression<bool>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gramsPerServing != null) 'grams_per_serving': gramsPerServing,
      if (caloriesPerServing != null)
        'calories_per_serving': caloriesPerServing,
      if (fatPerServing != null) 'fat_per_serving': fatPerServing,
      if (carbsPerServing != null) 'carbs_per_serving': carbsPerServing,
      if (proteinPerServing != null) 'protein_per_serving': proteinPerServing,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (cholesterolMg != null) 'cholesterol_mg': cholesterolMg,
      if (fiberPerServing != null) 'fiber_per_serving': fiberPerServing,
      if (importBatchId != null) 'import_batch_id': importBatchId,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  FoodCatalogCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? gramsPerServing,
      Value<double>? caloriesPerServing,
      Value<double>? fatPerServing,
      Value<double>? carbsPerServing,
      Value<double>? proteinPerServing,
      Value<double>? potassiumMg,
      Value<double>? sodiumMg,
      Value<double>? cholesterolMg,
      Value<double>? fiberPerServing,
      Value<String>? importBatchId,
      Value<bool>? isFavorite}) {
    return FoodCatalogCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gramsPerServing: gramsPerServing ?? this.gramsPerServing,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      fatPerServing: fatPerServing ?? this.fatPerServing,
      carbsPerServing: carbsPerServing ?? this.carbsPerServing,
      proteinPerServing: proteinPerServing ?? this.proteinPerServing,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
      fiberPerServing: fiberPerServing ?? this.fiberPerServing,
      importBatchId: importBatchId ?? this.importBatchId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gramsPerServing.present) {
      map['grams_per_serving'] = Variable<double>(gramsPerServing.value);
    }
    if (caloriesPerServing.present) {
      map['calories_per_serving'] = Variable<double>(caloriesPerServing.value);
    }
    if (fatPerServing.present) {
      map['fat_per_serving'] = Variable<double>(fatPerServing.value);
    }
    if (carbsPerServing.present) {
      map['carbs_per_serving'] = Variable<double>(carbsPerServing.value);
    }
    if (proteinPerServing.present) {
      map['protein_per_serving'] = Variable<double>(proteinPerServing.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (cholesterolMg.present) {
      map['cholesterol_mg'] = Variable<double>(cholesterolMg.value);
    }
    if (fiberPerServing.present) {
      map['fiber_per_serving'] = Variable<double>(fiberPerServing.value);
    }
    if (importBatchId.present) {
      map['import_batch_id'] = Variable<String>(importBatchId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodCatalogCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gramsPerServing: $gramsPerServing, ')
          ..write('caloriesPerServing: $caloriesPerServing, ')
          ..write('fatPerServing: $fatPerServing, ')
          ..write('carbsPerServing: $carbsPerServing, ')
          ..write('proteinPerServing: $proteinPerServing, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('fiberPerServing: $fiberPerServing, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

class $LoggedFoodsTable extends LoggedFoods
    with TableInfo<$LoggedFoodsTable, LoggedFoodData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoggedFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _epochDayMeta =
      const VerificationMeta('epochDay');
  @override
  late final GeneratedColumn<int> epochDay = GeneratedColumn<int>(
      'epoch_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealTimeMeta =
      const VerificationMeta('mealTime');
  @override
  late final GeneratedColumn<String> mealTime = GeneratedColumn<String>(
      'meal_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
      'grams', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _proteinGramsMeta =
      const VerificationMeta('proteinGrams');
  @override
  late final GeneratedColumn<int> proteinGrams = GeneratedColumn<int>(
      'protein_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _carbsGramsMeta =
      const VerificationMeta('carbsGrams');
  @override
  late final GeneratedColumn<int> carbsGrams = GeneratedColumn<int>(
      'carbs_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fatGramsMeta =
      const VerificationMeta('fatGrams');
  @override
  late final GeneratedColumn<int> fatGrams = GeneratedColumn<int>(
      'fat_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fiberGramsMeta =
      const VerificationMeta('fiberGrams');
  @override
  late final GeneratedColumn<int> fiberGrams = GeneratedColumn<int>(
      'fiber_grams', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _foodCatalogIdMeta =
      const VerificationMeta('foodCatalogId');
  @override
  late final GeneratedColumn<int> foodCatalogId = GeneratedColumn<int>(
      'food_catalog_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MANUAL'));
  static const VerificationMeta _calorieMinMeta =
      const VerificationMeta('calorieMin');
  @override
  late final GeneratedColumn<int> calorieMin = GeneratedColumn<int>(
      'calorie_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _calorieMaxMeta =
      const VerificationMeta('calorieMax');
  @override
  late final GeneratedColumn<int> calorieMax = GeneratedColumn<int>(
      'calorie_max', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _proteinMinGramsMeta =
      const VerificationMeta('proteinMinGrams');
  @override
  late final GeneratedColumn<double> proteinMinGrams = GeneratedColumn<double>(
      'protein_min_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _proteinMaxGramsMeta =
      const VerificationMeta('proteinMaxGrams');
  @override
  late final GeneratedColumn<double> proteinMaxGrams = GeneratedColumn<double>(
      'protein_max_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carbsMinGramsMeta =
      const VerificationMeta('carbsMinGrams');
  @override
  late final GeneratedColumn<double> carbsMinGrams = GeneratedColumn<double>(
      'carbs_min_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carbsMaxGramsMeta =
      const VerificationMeta('carbsMaxGrams');
  @override
  late final GeneratedColumn<double> carbsMaxGrams = GeneratedColumn<double>(
      'carbs_max_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fatMinGramsMeta =
      const VerificationMeta('fatMinGrams');
  @override
  late final GeneratedColumn<double> fatMinGrams = GeneratedColumn<double>(
      'fat_min_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fatMaxGramsMeta =
      const VerificationMeta('fatMaxGrams');
  @override
  late final GeneratedColumn<double> fatMaxGrams = GeneratedColumn<double>(
      'fat_max_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _analysisConfidenceMeta =
      const VerificationMeta('analysisConfidence');
  @override
  late final GeneratedColumn<String> analysisConfidence =
      GeneratedColumn<String>('analysis_confidence', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _analysisImageTypeMeta =
      const VerificationMeta('analysisImageType');
  @override
  late final GeneratedColumn<String> analysisImageType =
      GeneratedColumn<String>('analysis_image_type', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _calculationSummaryMeta =
      const VerificationMeta('calculationSummary');
  @override
  late final GeneratedColumn<String> calculationSummary =
      GeneratedColumn<String>('calculation_summary', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        epochDay,
        name,
        mealTime,
        grams,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        fiberGrams,
        foodCatalogId,
        timestamp,
        source,
        calorieMin,
        calorieMax,
        proteinMinGrams,
        proteinMaxGrams,
        carbsMinGrams,
        carbsMaxGrams,
        fatMinGrams,
        fatMaxGrams,
        analysisConfidence,
        analysisImageType,
        calculationSummary
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logged_foods';
  @override
  VerificationContext validateIntegrity(Insertable<LoggedFoodData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epoch_day')) {
      context.handle(_epochDayMeta,
          epochDay.isAcceptableOrUnknown(data['epoch_day']!, _epochDayMeta));
    } else if (isInserting) {
      context.missing(_epochDayMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('meal_time')) {
      context.handle(_mealTimeMeta,
          mealTime.isAcceptableOrUnknown(data['meal_time']!, _mealTimeMeta));
    } else if (isInserting) {
      context.missing(_mealTimeMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
          _gramsMeta, grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta));
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
          _proteinGramsMeta,
          proteinGrams.isAcceptableOrUnknown(
              data['protein_grams']!, _proteinGramsMeta));
    } else if (isInserting) {
      context.missing(_proteinGramsMeta);
    }
    if (data.containsKey('carbs_grams')) {
      context.handle(
          _carbsGramsMeta,
          carbsGrams.isAcceptableOrUnknown(
              data['carbs_grams']!, _carbsGramsMeta));
    } else if (isInserting) {
      context.missing(_carbsGramsMeta);
    }
    if (data.containsKey('fat_grams')) {
      context.handle(_fatGramsMeta,
          fatGrams.isAcceptableOrUnknown(data['fat_grams']!, _fatGramsMeta));
    } else if (isInserting) {
      context.missing(_fatGramsMeta);
    }
    if (data.containsKey('fiber_grams')) {
      context.handle(
          _fiberGramsMeta,
          fiberGrams.isAcceptableOrUnknown(
              data['fiber_grams']!, _fiberGramsMeta));
    }
    if (data.containsKey('food_catalog_id')) {
      context.handle(
          _foodCatalogIdMeta,
          foodCatalogId.isAcceptableOrUnknown(
              data['food_catalog_id']!, _foodCatalogIdMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('calorie_min')) {
      context.handle(
          _calorieMinMeta,
          calorieMin.isAcceptableOrUnknown(
              data['calorie_min']!, _calorieMinMeta));
    }
    if (data.containsKey('calorie_max')) {
      context.handle(
          _calorieMaxMeta,
          calorieMax.isAcceptableOrUnknown(
              data['calorie_max']!, _calorieMaxMeta));
    }
    if (data.containsKey('protein_min_grams')) {
      context.handle(
          _proteinMinGramsMeta,
          proteinMinGrams.isAcceptableOrUnknown(
              data['protein_min_grams']!, _proteinMinGramsMeta));
    }
    if (data.containsKey('protein_max_grams')) {
      context.handle(
          _proteinMaxGramsMeta,
          proteinMaxGrams.isAcceptableOrUnknown(
              data['protein_max_grams']!, _proteinMaxGramsMeta));
    }
    if (data.containsKey('carbs_min_grams')) {
      context.handle(
          _carbsMinGramsMeta,
          carbsMinGrams.isAcceptableOrUnknown(
              data['carbs_min_grams']!, _carbsMinGramsMeta));
    }
    if (data.containsKey('carbs_max_grams')) {
      context.handle(
          _carbsMaxGramsMeta,
          carbsMaxGrams.isAcceptableOrUnknown(
              data['carbs_max_grams']!, _carbsMaxGramsMeta));
    }
    if (data.containsKey('fat_min_grams')) {
      context.handle(
          _fatMinGramsMeta,
          fatMinGrams.isAcceptableOrUnknown(
              data['fat_min_grams']!, _fatMinGramsMeta));
    }
    if (data.containsKey('fat_max_grams')) {
      context.handle(
          _fatMaxGramsMeta,
          fatMaxGrams.isAcceptableOrUnknown(
              data['fat_max_grams']!, _fatMaxGramsMeta));
    }
    if (data.containsKey('analysis_confidence')) {
      context.handle(
          _analysisConfidenceMeta,
          analysisConfidence.isAcceptableOrUnknown(
              data['analysis_confidence']!, _analysisConfidenceMeta));
    }
    if (data.containsKey('analysis_image_type')) {
      context.handle(
          _analysisImageTypeMeta,
          analysisImageType.isAcceptableOrUnknown(
              data['analysis_image_type']!, _analysisImageTypeMeta));
    }
    if (data.containsKey('calculation_summary')) {
      context.handle(
          _calculationSummaryMeta,
          calculationSummary.isAcceptableOrUnknown(
              data['calculation_summary']!, _calculationSummaryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoggedFoodData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoggedFoodData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      epochDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}epoch_day'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      mealTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_time'])!,
      grams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grams'])!,
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories'])!,
      proteinGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protein_grams'])!,
      carbsGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}carbs_grams'])!,
      fatGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fat_grams'])!,
      fiberGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiber_grams'])!,
      foodCatalogId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}food_catalog_id']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      calorieMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calorie_min']),
      calorieMax: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calorie_max']),
      proteinMinGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}protein_min_grams']),
      proteinMaxGrams: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}protein_max_grams']),
      carbsMinGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_min_grams']),
      carbsMaxGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_max_grams']),
      fatMinGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_min_grams']),
      fatMaxGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_max_grams']),
      analysisConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}analysis_confidence']),
      analysisImageType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}analysis_image_type']),
      calculationSummary: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calculation_summary']),
    );
  }

  @override
  $LoggedFoodsTable createAlias(String alias) {
    return $LoggedFoodsTable(attachedDatabase, alias);
  }
}

class LoggedFoodData extends DataClass implements Insertable<LoggedFoodData> {
  final int id;
  final int epochDay;
  final String name;
  final String mealTime;
  final double grams;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int fiberGrams;
  final int? foodCatalogId;
  final int timestamp;
  final String source;
  final int? calorieMin;
  final int? calorieMax;
  final double? proteinMinGrams;
  final double? proteinMaxGrams;
  final double? carbsMinGrams;
  final double? carbsMaxGrams;
  final double? fatMinGrams;
  final double? fatMaxGrams;
  final String? analysisConfidence;
  final String? analysisImageType;
  final String? calculationSummary;
  const LoggedFoodData(
      {required this.id,
      required this.epochDay,
      required this.name,
      required this.mealTime,
      required this.grams,
      required this.calories,
      required this.proteinGrams,
      required this.carbsGrams,
      required this.fatGrams,
      required this.fiberGrams,
      this.foodCatalogId,
      required this.timestamp,
      required this.source,
      this.calorieMin,
      this.calorieMax,
      this.proteinMinGrams,
      this.proteinMaxGrams,
      this.carbsMinGrams,
      this.carbsMaxGrams,
      this.fatMinGrams,
      this.fatMaxGrams,
      this.analysisConfidence,
      this.analysisImageType,
      this.calculationSummary});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['epoch_day'] = Variable<int>(epochDay);
    map['name'] = Variable<String>(name);
    map['meal_time'] = Variable<String>(mealTime);
    map['grams'] = Variable<double>(grams);
    map['calories'] = Variable<int>(calories);
    map['protein_grams'] = Variable<int>(proteinGrams);
    map['carbs_grams'] = Variable<int>(carbsGrams);
    map['fat_grams'] = Variable<int>(fatGrams);
    map['fiber_grams'] = Variable<int>(fiberGrams);
    if (!nullToAbsent || foodCatalogId != null) {
      map['food_catalog_id'] = Variable<int>(foodCatalogId);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || calorieMin != null) {
      map['calorie_min'] = Variable<int>(calorieMin);
    }
    if (!nullToAbsent || calorieMax != null) {
      map['calorie_max'] = Variable<int>(calorieMax);
    }
    if (!nullToAbsent || proteinMinGrams != null) {
      map['protein_min_grams'] = Variable<double>(proteinMinGrams);
    }
    if (!nullToAbsent || proteinMaxGrams != null) {
      map['protein_max_grams'] = Variable<double>(proteinMaxGrams);
    }
    if (!nullToAbsent || carbsMinGrams != null) {
      map['carbs_min_grams'] = Variable<double>(carbsMinGrams);
    }
    if (!nullToAbsent || carbsMaxGrams != null) {
      map['carbs_max_grams'] = Variable<double>(carbsMaxGrams);
    }
    if (!nullToAbsent || fatMinGrams != null) {
      map['fat_min_grams'] = Variable<double>(fatMinGrams);
    }
    if (!nullToAbsent || fatMaxGrams != null) {
      map['fat_max_grams'] = Variable<double>(fatMaxGrams);
    }
    if (!nullToAbsent || analysisConfidence != null) {
      map['analysis_confidence'] = Variable<String>(analysisConfidence);
    }
    if (!nullToAbsent || analysisImageType != null) {
      map['analysis_image_type'] = Variable<String>(analysisImageType);
    }
    if (!nullToAbsent || calculationSummary != null) {
      map['calculation_summary'] = Variable<String>(calculationSummary);
    }
    return map;
  }

  LoggedFoodsCompanion toCompanion(bool nullToAbsent) {
    return LoggedFoodsCompanion(
      id: Value(id),
      epochDay: Value(epochDay),
      name: Value(name),
      mealTime: Value(mealTime),
      grams: Value(grams),
      calories: Value(calories),
      proteinGrams: Value(proteinGrams),
      carbsGrams: Value(carbsGrams),
      fatGrams: Value(fatGrams),
      fiberGrams: Value(fiberGrams),
      foodCatalogId: foodCatalogId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodCatalogId),
      timestamp: Value(timestamp),
      source: Value(source),
      calorieMin: calorieMin == null && nullToAbsent
          ? const Value.absent()
          : Value(calorieMin),
      calorieMax: calorieMax == null && nullToAbsent
          ? const Value.absent()
          : Value(calorieMax),
      proteinMinGrams: proteinMinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinMinGrams),
      proteinMaxGrams: proteinMaxGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinMaxGrams),
      carbsMinGrams: carbsMinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsMinGrams),
      carbsMaxGrams: carbsMaxGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsMaxGrams),
      fatMinGrams: fatMinGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(fatMinGrams),
      fatMaxGrams: fatMaxGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(fatMaxGrams),
      analysisConfidence: analysisConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisConfidence),
      analysisImageType: analysisImageType == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisImageType),
      calculationSummary: calculationSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(calculationSummary),
    );
  }

  factory LoggedFoodData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoggedFoodData(
      id: serializer.fromJson<int>(json['id']),
      epochDay: serializer.fromJson<int>(json['epochDay']),
      name: serializer.fromJson<String>(json['name']),
      mealTime: serializer.fromJson<String>(json['mealTime']),
      grams: serializer.fromJson<double>(json['grams']),
      calories: serializer.fromJson<int>(json['calories']),
      proteinGrams: serializer.fromJson<int>(json['proteinGrams']),
      carbsGrams: serializer.fromJson<int>(json['carbsGrams']),
      fatGrams: serializer.fromJson<int>(json['fatGrams']),
      fiberGrams: serializer.fromJson<int>(json['fiberGrams']),
      foodCatalogId: serializer.fromJson<int?>(json['foodCatalogId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      source: serializer.fromJson<String>(json['source']),
      calorieMin: serializer.fromJson<int?>(json['calorieMin']),
      calorieMax: serializer.fromJson<int?>(json['calorieMax']),
      proteinMinGrams: serializer.fromJson<double?>(json['proteinMinGrams']),
      proteinMaxGrams: serializer.fromJson<double?>(json['proteinMaxGrams']),
      carbsMinGrams: serializer.fromJson<double?>(json['carbsMinGrams']),
      carbsMaxGrams: serializer.fromJson<double?>(json['carbsMaxGrams']),
      fatMinGrams: serializer.fromJson<double?>(json['fatMinGrams']),
      fatMaxGrams: serializer.fromJson<double?>(json['fatMaxGrams']),
      analysisConfidence:
          serializer.fromJson<String?>(json['analysisConfidence']),
      analysisImageType:
          serializer.fromJson<String?>(json['analysisImageType']),
      calculationSummary:
          serializer.fromJson<String?>(json['calculationSummary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epochDay': serializer.toJson<int>(epochDay),
      'name': serializer.toJson<String>(name),
      'mealTime': serializer.toJson<String>(mealTime),
      'grams': serializer.toJson<double>(grams),
      'calories': serializer.toJson<int>(calories),
      'proteinGrams': serializer.toJson<int>(proteinGrams),
      'carbsGrams': serializer.toJson<int>(carbsGrams),
      'fatGrams': serializer.toJson<int>(fatGrams),
      'fiberGrams': serializer.toJson<int>(fiberGrams),
      'foodCatalogId': serializer.toJson<int?>(foodCatalogId),
      'timestamp': serializer.toJson<int>(timestamp),
      'source': serializer.toJson<String>(source),
      'calorieMin': serializer.toJson<int?>(calorieMin),
      'calorieMax': serializer.toJson<int?>(calorieMax),
      'proteinMinGrams': serializer.toJson<double?>(proteinMinGrams),
      'proteinMaxGrams': serializer.toJson<double?>(proteinMaxGrams),
      'carbsMinGrams': serializer.toJson<double?>(carbsMinGrams),
      'carbsMaxGrams': serializer.toJson<double?>(carbsMaxGrams),
      'fatMinGrams': serializer.toJson<double?>(fatMinGrams),
      'fatMaxGrams': serializer.toJson<double?>(fatMaxGrams),
      'analysisConfidence': serializer.toJson<String?>(analysisConfidence),
      'analysisImageType': serializer.toJson<String?>(analysisImageType),
      'calculationSummary': serializer.toJson<String?>(calculationSummary),
    };
  }

  LoggedFoodData copyWith(
          {int? id,
          int? epochDay,
          String? name,
          String? mealTime,
          double? grams,
          int? calories,
          int? proteinGrams,
          int? carbsGrams,
          int? fatGrams,
          int? fiberGrams,
          Value<int?> foodCatalogId = const Value.absent(),
          int? timestamp,
          String? source,
          Value<int?> calorieMin = const Value.absent(),
          Value<int?> calorieMax = const Value.absent(),
          Value<double?> proteinMinGrams = const Value.absent(),
          Value<double?> proteinMaxGrams = const Value.absent(),
          Value<double?> carbsMinGrams = const Value.absent(),
          Value<double?> carbsMaxGrams = const Value.absent(),
          Value<double?> fatMinGrams = const Value.absent(),
          Value<double?> fatMaxGrams = const Value.absent(),
          Value<String?> analysisConfidence = const Value.absent(),
          Value<String?> analysisImageType = const Value.absent(),
          Value<String?> calculationSummary = const Value.absent()}) =>
      LoggedFoodData(
        id: id ?? this.id,
        epochDay: epochDay ?? this.epochDay,
        name: name ?? this.name,
        mealTime: mealTime ?? this.mealTime,
        grams: grams ?? this.grams,
        calories: calories ?? this.calories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        carbsGrams: carbsGrams ?? this.carbsGrams,
        fatGrams: fatGrams ?? this.fatGrams,
        fiberGrams: fiberGrams ?? this.fiberGrams,
        foodCatalogId:
            foodCatalogId.present ? foodCatalogId.value : this.foodCatalogId,
        timestamp: timestamp ?? this.timestamp,
        source: source ?? this.source,
        calorieMin: calorieMin.present ? calorieMin.value : this.calorieMin,
        calorieMax: calorieMax.present ? calorieMax.value : this.calorieMax,
        proteinMinGrams: proteinMinGrams.present
            ? proteinMinGrams.value
            : this.proteinMinGrams,
        proteinMaxGrams: proteinMaxGrams.present
            ? proteinMaxGrams.value
            : this.proteinMaxGrams,
        carbsMinGrams:
            carbsMinGrams.present ? carbsMinGrams.value : this.carbsMinGrams,
        carbsMaxGrams:
            carbsMaxGrams.present ? carbsMaxGrams.value : this.carbsMaxGrams,
        fatMinGrams: fatMinGrams.present ? fatMinGrams.value : this.fatMinGrams,
        fatMaxGrams: fatMaxGrams.present ? fatMaxGrams.value : this.fatMaxGrams,
        analysisConfidence: analysisConfidence.present
            ? analysisConfidence.value
            : this.analysisConfidence,
        analysisImageType: analysisImageType.present
            ? analysisImageType.value
            : this.analysisImageType,
        calculationSummary: calculationSummary.present
            ? calculationSummary.value
            : this.calculationSummary,
      );
  LoggedFoodData copyWithCompanion(LoggedFoodsCompanion data) {
    return LoggedFoodData(
      id: data.id.present ? data.id.value : this.id,
      epochDay: data.epochDay.present ? data.epochDay.value : this.epochDay,
      name: data.name.present ? data.name.value : this.name,
      mealTime: data.mealTime.present ? data.mealTime.value : this.mealTime,
      grams: data.grams.present ? data.grams.value : this.grams,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      carbsGrams:
          data.carbsGrams.present ? data.carbsGrams.value : this.carbsGrams,
      fatGrams: data.fatGrams.present ? data.fatGrams.value : this.fatGrams,
      fiberGrams:
          data.fiberGrams.present ? data.fiberGrams.value : this.fiberGrams,
      foodCatalogId: data.foodCatalogId.present
          ? data.foodCatalogId.value
          : this.foodCatalogId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      source: data.source.present ? data.source.value : this.source,
      calorieMin:
          data.calorieMin.present ? data.calorieMin.value : this.calorieMin,
      calorieMax:
          data.calorieMax.present ? data.calorieMax.value : this.calorieMax,
      proteinMinGrams: data.proteinMinGrams.present
          ? data.proteinMinGrams.value
          : this.proteinMinGrams,
      proteinMaxGrams: data.proteinMaxGrams.present
          ? data.proteinMaxGrams.value
          : this.proteinMaxGrams,
      carbsMinGrams: data.carbsMinGrams.present
          ? data.carbsMinGrams.value
          : this.carbsMinGrams,
      carbsMaxGrams: data.carbsMaxGrams.present
          ? data.carbsMaxGrams.value
          : this.carbsMaxGrams,
      fatMinGrams:
          data.fatMinGrams.present ? data.fatMinGrams.value : this.fatMinGrams,
      fatMaxGrams:
          data.fatMaxGrams.present ? data.fatMaxGrams.value : this.fatMaxGrams,
      analysisConfidence: data.analysisConfidence.present
          ? data.analysisConfidence.value
          : this.analysisConfidence,
      analysisImageType: data.analysisImageType.present
          ? data.analysisImageType.value
          : this.analysisImageType,
      calculationSummary: data.calculationSummary.present
          ? data.calculationSummary.value
          : this.calculationSummary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoggedFoodData(')
          ..write('id: $id, ')
          ..write('epochDay: $epochDay, ')
          ..write('name: $name, ')
          ..write('mealTime: $mealTime, ')
          ..write('grams: $grams, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('foodCatalogId: $foodCatalogId, ')
          ..write('timestamp: $timestamp, ')
          ..write('source: $source, ')
          ..write('calorieMin: $calorieMin, ')
          ..write('calorieMax: $calorieMax, ')
          ..write('proteinMinGrams: $proteinMinGrams, ')
          ..write('proteinMaxGrams: $proteinMaxGrams, ')
          ..write('carbsMinGrams: $carbsMinGrams, ')
          ..write('carbsMaxGrams: $carbsMaxGrams, ')
          ..write('fatMinGrams: $fatMinGrams, ')
          ..write('fatMaxGrams: $fatMaxGrams, ')
          ..write('analysisConfidence: $analysisConfidence, ')
          ..write('analysisImageType: $analysisImageType, ')
          ..write('calculationSummary: $calculationSummary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        epochDay,
        name,
        mealTime,
        grams,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        fiberGrams,
        foodCatalogId,
        timestamp,
        source,
        calorieMin,
        calorieMax,
        proteinMinGrams,
        proteinMaxGrams,
        carbsMinGrams,
        carbsMaxGrams,
        fatMinGrams,
        fatMaxGrams,
        analysisConfidence,
        analysisImageType,
        calculationSummary
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggedFoodData &&
          other.id == this.id &&
          other.epochDay == this.epochDay &&
          other.name == this.name &&
          other.mealTime == this.mealTime &&
          other.grams == this.grams &&
          other.calories == this.calories &&
          other.proteinGrams == this.proteinGrams &&
          other.carbsGrams == this.carbsGrams &&
          other.fatGrams == this.fatGrams &&
          other.fiberGrams == this.fiberGrams &&
          other.foodCatalogId == this.foodCatalogId &&
          other.timestamp == this.timestamp &&
          other.source == this.source &&
          other.calorieMin == this.calorieMin &&
          other.calorieMax == this.calorieMax &&
          other.proteinMinGrams == this.proteinMinGrams &&
          other.proteinMaxGrams == this.proteinMaxGrams &&
          other.carbsMinGrams == this.carbsMinGrams &&
          other.carbsMaxGrams == this.carbsMaxGrams &&
          other.fatMinGrams == this.fatMinGrams &&
          other.fatMaxGrams == this.fatMaxGrams &&
          other.analysisConfidence == this.analysisConfidence &&
          other.analysisImageType == this.analysisImageType &&
          other.calculationSummary == this.calculationSummary);
}

class LoggedFoodsCompanion extends UpdateCompanion<LoggedFoodData> {
  final Value<int> id;
  final Value<int> epochDay;
  final Value<String> name;
  final Value<String> mealTime;
  final Value<double> grams;
  final Value<int> calories;
  final Value<int> proteinGrams;
  final Value<int> carbsGrams;
  final Value<int> fatGrams;
  final Value<int> fiberGrams;
  final Value<int?> foodCatalogId;
  final Value<int> timestamp;
  final Value<String> source;
  final Value<int?> calorieMin;
  final Value<int?> calorieMax;
  final Value<double?> proteinMinGrams;
  final Value<double?> proteinMaxGrams;
  final Value<double?> carbsMinGrams;
  final Value<double?> carbsMaxGrams;
  final Value<double?> fatMinGrams;
  final Value<double?> fatMaxGrams;
  final Value<String?> analysisConfidence;
  final Value<String?> analysisImageType;
  final Value<String?> calculationSummary;
  const LoggedFoodsCompanion({
    this.id = const Value.absent(),
    this.epochDay = const Value.absent(),
    this.name = const Value.absent(),
    this.mealTime = const Value.absent(),
    this.grams = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbsGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.fiberGrams = const Value.absent(),
    this.foodCatalogId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.source = const Value.absent(),
    this.calorieMin = const Value.absent(),
    this.calorieMax = const Value.absent(),
    this.proteinMinGrams = const Value.absent(),
    this.proteinMaxGrams = const Value.absent(),
    this.carbsMinGrams = const Value.absent(),
    this.carbsMaxGrams = const Value.absent(),
    this.fatMinGrams = const Value.absent(),
    this.fatMaxGrams = const Value.absent(),
    this.analysisConfidence = const Value.absent(),
    this.analysisImageType = const Value.absent(),
    this.calculationSummary = const Value.absent(),
  });
  LoggedFoodsCompanion.insert({
    this.id = const Value.absent(),
    required int epochDay,
    required String name,
    required String mealTime,
    required double grams,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    this.fiberGrams = const Value.absent(),
    this.foodCatalogId = const Value.absent(),
    required int timestamp,
    this.source = const Value.absent(),
    this.calorieMin = const Value.absent(),
    this.calorieMax = const Value.absent(),
    this.proteinMinGrams = const Value.absent(),
    this.proteinMaxGrams = const Value.absent(),
    this.carbsMinGrams = const Value.absent(),
    this.carbsMaxGrams = const Value.absent(),
    this.fatMinGrams = const Value.absent(),
    this.fatMaxGrams = const Value.absent(),
    this.analysisConfidence = const Value.absent(),
    this.analysisImageType = const Value.absent(),
    this.calculationSummary = const Value.absent(),
  })  : epochDay = Value(epochDay),
        name = Value(name),
        mealTime = Value(mealTime),
        grams = Value(grams),
        calories = Value(calories),
        proteinGrams = Value(proteinGrams),
        carbsGrams = Value(carbsGrams),
        fatGrams = Value(fatGrams),
        timestamp = Value(timestamp);
  static Insertable<LoggedFoodData> custom({
    Expression<int>? id,
    Expression<int>? epochDay,
    Expression<String>? name,
    Expression<String>? mealTime,
    Expression<double>? grams,
    Expression<int>? calories,
    Expression<int>? proteinGrams,
    Expression<int>? carbsGrams,
    Expression<int>? fatGrams,
    Expression<int>? fiberGrams,
    Expression<int>? foodCatalogId,
    Expression<int>? timestamp,
    Expression<String>? source,
    Expression<int>? calorieMin,
    Expression<int>? calorieMax,
    Expression<double>? proteinMinGrams,
    Expression<double>? proteinMaxGrams,
    Expression<double>? carbsMinGrams,
    Expression<double>? carbsMaxGrams,
    Expression<double>? fatMinGrams,
    Expression<double>? fatMaxGrams,
    Expression<String>? analysisConfidence,
    Expression<String>? analysisImageType,
    Expression<String>? calculationSummary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epochDay != null) 'epoch_day': epochDay,
      if (name != null) 'name': name,
      if (mealTime != null) 'meal_time': mealTime,
      if (grams != null) 'grams': grams,
      if (calories != null) 'calories': calories,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (carbsGrams != null) 'carbs_grams': carbsGrams,
      if (fatGrams != null) 'fat_grams': fatGrams,
      if (fiberGrams != null) 'fiber_grams': fiberGrams,
      if (foodCatalogId != null) 'food_catalog_id': foodCatalogId,
      if (timestamp != null) 'timestamp': timestamp,
      if (source != null) 'source': source,
      if (calorieMin != null) 'calorie_min': calorieMin,
      if (calorieMax != null) 'calorie_max': calorieMax,
      if (proteinMinGrams != null) 'protein_min_grams': proteinMinGrams,
      if (proteinMaxGrams != null) 'protein_max_grams': proteinMaxGrams,
      if (carbsMinGrams != null) 'carbs_min_grams': carbsMinGrams,
      if (carbsMaxGrams != null) 'carbs_max_grams': carbsMaxGrams,
      if (fatMinGrams != null) 'fat_min_grams': fatMinGrams,
      if (fatMaxGrams != null) 'fat_max_grams': fatMaxGrams,
      if (analysisConfidence != null) 'analysis_confidence': analysisConfidence,
      if (analysisImageType != null) 'analysis_image_type': analysisImageType,
      if (calculationSummary != null) 'calculation_summary': calculationSummary,
    });
  }

  LoggedFoodsCompanion copyWith(
      {Value<int>? id,
      Value<int>? epochDay,
      Value<String>? name,
      Value<String>? mealTime,
      Value<double>? grams,
      Value<int>? calories,
      Value<int>? proteinGrams,
      Value<int>? carbsGrams,
      Value<int>? fatGrams,
      Value<int>? fiberGrams,
      Value<int?>? foodCatalogId,
      Value<int>? timestamp,
      Value<String>? source,
      Value<int?>? calorieMin,
      Value<int?>? calorieMax,
      Value<double?>? proteinMinGrams,
      Value<double?>? proteinMaxGrams,
      Value<double?>? carbsMinGrams,
      Value<double?>? carbsMaxGrams,
      Value<double?>? fatMinGrams,
      Value<double?>? fatMaxGrams,
      Value<String?>? analysisConfidence,
      Value<String?>? analysisImageType,
      Value<String?>? calculationSummary}) {
    return LoggedFoodsCompanion(
      id: id ?? this.id,
      epochDay: epochDay ?? this.epochDay,
      name: name ?? this.name,
      mealTime: mealTime ?? this.mealTime,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      foodCatalogId: foodCatalogId ?? this.foodCatalogId,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      calorieMin: calorieMin ?? this.calorieMin,
      calorieMax: calorieMax ?? this.calorieMax,
      proteinMinGrams: proteinMinGrams ?? this.proteinMinGrams,
      proteinMaxGrams: proteinMaxGrams ?? this.proteinMaxGrams,
      carbsMinGrams: carbsMinGrams ?? this.carbsMinGrams,
      carbsMaxGrams: carbsMaxGrams ?? this.carbsMaxGrams,
      fatMinGrams: fatMinGrams ?? this.fatMinGrams,
      fatMaxGrams: fatMaxGrams ?? this.fatMaxGrams,
      analysisConfidence: analysisConfidence ?? this.analysisConfidence,
      analysisImageType: analysisImageType ?? this.analysisImageType,
      calculationSummary: calculationSummary ?? this.calculationSummary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epochDay.present) {
      map['epoch_day'] = Variable<int>(epochDay.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mealTime.present) {
      map['meal_time'] = Variable<String>(mealTime.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<int>(proteinGrams.value);
    }
    if (carbsGrams.present) {
      map['carbs_grams'] = Variable<int>(carbsGrams.value);
    }
    if (fatGrams.present) {
      map['fat_grams'] = Variable<int>(fatGrams.value);
    }
    if (fiberGrams.present) {
      map['fiber_grams'] = Variable<int>(fiberGrams.value);
    }
    if (foodCatalogId.present) {
      map['food_catalog_id'] = Variable<int>(foodCatalogId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (calorieMin.present) {
      map['calorie_min'] = Variable<int>(calorieMin.value);
    }
    if (calorieMax.present) {
      map['calorie_max'] = Variable<int>(calorieMax.value);
    }
    if (proteinMinGrams.present) {
      map['protein_min_grams'] = Variable<double>(proteinMinGrams.value);
    }
    if (proteinMaxGrams.present) {
      map['protein_max_grams'] = Variable<double>(proteinMaxGrams.value);
    }
    if (carbsMinGrams.present) {
      map['carbs_min_grams'] = Variable<double>(carbsMinGrams.value);
    }
    if (carbsMaxGrams.present) {
      map['carbs_max_grams'] = Variable<double>(carbsMaxGrams.value);
    }
    if (fatMinGrams.present) {
      map['fat_min_grams'] = Variable<double>(fatMinGrams.value);
    }
    if (fatMaxGrams.present) {
      map['fat_max_grams'] = Variable<double>(fatMaxGrams.value);
    }
    if (analysisConfidence.present) {
      map['analysis_confidence'] = Variable<String>(analysisConfidence.value);
    }
    if (analysisImageType.present) {
      map['analysis_image_type'] = Variable<String>(analysisImageType.value);
    }
    if (calculationSummary.present) {
      map['calculation_summary'] = Variable<String>(calculationSummary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoggedFoodsCompanion(')
          ..write('id: $id, ')
          ..write('epochDay: $epochDay, ')
          ..write('name: $name, ')
          ..write('mealTime: $mealTime, ')
          ..write('grams: $grams, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbsGrams: $carbsGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('foodCatalogId: $foodCatalogId, ')
          ..write('timestamp: $timestamp, ')
          ..write('source: $source, ')
          ..write('calorieMin: $calorieMin, ')
          ..write('calorieMax: $calorieMax, ')
          ..write('proteinMinGrams: $proteinMinGrams, ')
          ..write('proteinMaxGrams: $proteinMaxGrams, ')
          ..write('carbsMinGrams: $carbsMinGrams, ')
          ..write('carbsMaxGrams: $carbsMaxGrams, ')
          ..write('fatMinGrams: $fatMinGrams, ')
          ..write('fatMaxGrams: $fatMaxGrams, ')
          ..write('analysisConfidence: $analysisConfidence, ')
          ..write('analysisImageType: $analysisImageType, ')
          ..write('calculationSummary: $calculationSummary')
          ..write(')'))
        .toString();
  }
}

abstract class _$GymDatabase extends GeneratedDatabase {
  _$GymDatabase(QueryExecutor e) : super(e);
  $GymDatabaseManager get managers => $GymDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $WorkoutSessionsTable workoutSessions =
      $WorkoutSessionsTable(this);
  late final $SessionExercisesTable sessionExercises =
      $SessionExercisesTable(this);
  late final $PersonalProfilesTable personalProfiles =
      $PersonalProfilesTable(this);
  late final $WeightMeasurementsTable weightMeasurements =
      $WeightMeasurementsTable(this);
  late final $DailyNutritionsTable dailyNutritions =
      $DailyNutritionsTable(this);
  late final $WeeklyCheckInsTable weeklyCheckIns = $WeeklyCheckInsTable(this);
  late final $AdaptationDecisionsTable adaptationDecisions =
      $AdaptationDecisionsTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $WorkoutFeedbacksTable workoutFeedbacks =
      $WorkoutFeedbacksTable(this);
  late final $MealTemplatesTable mealTemplates = $MealTemplatesTable(this);
  late final $UserFoodOverridesTable userFoodOverrides =
      $UserFoodOverridesTable(this);
  late final $FoodCatalogTable foodCatalog = $FoodCatalogTable(this);
  late final $LoggedFoodsTable loggedFoods = $LoggedFoodsTable(this);
  late final Index idxFoodCatalogName = Index('idx_food_catalog_name',
      'CREATE INDEX idx_food_catalog_name ON food_catalog (name)');
  late final Index idxFoodCatalogFavName = Index('idx_food_catalog_fav_name',
      'CREATE INDEX idx_food_catalog_fav_name ON food_catalog (is_favorite, name)');
  late final Index idxLoggedFoodsDayTime = Index('idx_logged_foods_day_time',
      'CREATE INDEX idx_logged_foods_day_time ON logged_foods (epoch_day, timestamp)');
  late final WorkoutDao workoutDao = WorkoutDao(this as GymDatabase);
  late final PersonalizationDao personalizationDao =
      PersonalizationDao(this as GymDatabase);
  late final AchievementDao achievementDao =
      AchievementDao(this as GymDatabase);
  late final WorkoutFeedbackDao workoutFeedbackDao =
      WorkoutFeedbackDao(this as GymDatabase);
  late final FoodCatalogDao foodCatalogDao =
      FoodCatalogDao(this as GymDatabase);
  late final LoggedFoodDao loggedFoodDao = LoggedFoodDao(this as GymDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        goals,
        workoutSessions,
        sessionExercises,
        personalProfiles,
        weightMeasurements,
        dailyNutritions,
        weeklyCheckIns,
        adaptationDecisions,
        achievements,
        workoutFeedbacks,
        mealTemplates,
        userFoodOverrides,
        foodCatalog,
        loggedFoods,
        idxFoodCatalogName,
        idxFoodCatalogFavName,
        idxLoggedFoodsDayTime
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('goals',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workout_sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('session_exercises', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workout_feedbacks', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String programId,
  required FitnessGoal goal,
  Value<String> goalsCsv,
  Value<Gender> gender,
  Value<BodyType> bodyType,
  required ExperienceLevel level,
  required EquipmentProfile equipmentProfile,
  required int sessionsPerWeek,
  required int durationWeeks,
  required RestDayMode restDayMode,
  Value<int> trainingDaysMask,
  Value<int> sessionDurationMinutes,
  required int createdEpochDay,
  Value<bool> archived,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> programId,
  Value<FitnessGoal> goal,
  Value<String> goalsCsv,
  Value<Gender> gender,
  Value<BodyType> bodyType,
  Value<ExperienceLevel> level,
  Value<EquipmentProfile> equipmentProfile,
  Value<int> sessionsPerWeek,
  Value<int> durationWeeks,
  Value<RestDayMode> restDayMode,
  Value<int> trainingDaysMask,
  Value<int> sessionDurationMinutes,
  Value<int> createdEpochDay,
  Value<bool> archived,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$GymDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSession>>
      _workoutSessionsRefsTable(_$GymDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutSessions,
              aliasName: 'goals__id__workout_sessions__goal_id');

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager =
        $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions)
            .filter((f) => f.goalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$GymDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programId => $composableBuilder(
      column: $table.programId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FitnessGoal, FitnessGoal, String> get goal =>
      $composableBuilder(
          column: $table.goal,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get goalsCsv => $composableBuilder(
      column: $table.goalsCsv, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Gender, Gender, String> get gender =>
      $composableBuilder(
          column: $table.gender,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<BodyType, BodyType, String> get bodyType =>
      $composableBuilder(
          column: $table.bodyType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ExperienceLevel, ExperienceLevel, String>
      get level => $composableBuilder(
          column: $table.level,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<EquipmentProfile, EquipmentProfile, String>
      get equipmentProfile => $composableBuilder(
          column: $table.equipmentProfile,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get sessionsPerWeek => $composableBuilder(
      column: $table.sessionsPerWeek,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationWeeks => $composableBuilder(
      column: $table.durationWeeks, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RestDayMode, RestDayMode, String>
      get restDayMode => $composableBuilder(
          column: $table.restDayMode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get trainingDaysMask => $composableBuilder(
      column: $table.trainingDaysMask,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionDurationMinutes => $composableBuilder(
      column: $table.sessionDurationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdEpochDay => $composableBuilder(
      column: $table.createdEpochDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutSessionsRefs(
      Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$GymDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programId => $composableBuilder(
      column: $table.programId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goal => $composableBuilder(
      column: $table.goal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goalsCsv => $composableBuilder(
      column: $table.goalsCsv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyType => $composableBuilder(
      column: $table.bodyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipmentProfile => $composableBuilder(
      column: $table.equipmentProfile,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionsPerWeek => $composableBuilder(
      column: $table.sessionsPerWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationWeeks => $composableBuilder(
      column: $table.durationWeeks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restDayMode => $composableBuilder(
      column: $table.restDayMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trainingDaysMask => $composableBuilder(
      column: $table.trainingDaysMask,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionDurationMinutes => $composableBuilder(
      column: $table.sessionDurationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdEpochDay => $composableBuilder(
      column: $table.createdEpochDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$GymDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FitnessGoal, String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get goalsCsv =>
      $composableBuilder(column: $table.goalsCsv, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Gender, String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BodyType, String> get bodyType =>
      $composableBuilder(column: $table.bodyType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExperienceLevel, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EquipmentProfile, String>
      get equipmentProfile => $composableBuilder(
          column: $table.equipmentProfile, builder: (column) => column);

  GeneratedColumn<int> get sessionsPerWeek => $composableBuilder(
      column: $table.sessionsPerWeek, builder: (column) => column);

  GeneratedColumn<int> get durationWeeks => $composableBuilder(
      column: $table.durationWeeks, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RestDayMode, String> get restDayMode =>
      $composableBuilder(
          column: $table.restDayMode, builder: (column) => column);

  GeneratedColumn<int> get trainingDaysMask => $composableBuilder(
      column: $table.trainingDaysMask, builder: (column) => column);

  GeneratedColumn<int> get sessionDurationMinutes => $composableBuilder(
      column: $table.sessionDurationMinutes, builder: (column) => column);

  GeneratedColumn<int> get createdEpochDay => $composableBuilder(
      column: $table.createdEpochDay, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> workoutSessionsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool workoutSessionsRefs})> {
  $$GoalsTableTableManager(_$GymDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> programId = const Value.absent(),
            Value<FitnessGoal> goal = const Value.absent(),
            Value<String> goalsCsv = const Value.absent(),
            Value<Gender> gender = const Value.absent(),
            Value<BodyType> bodyType = const Value.absent(),
            Value<ExperienceLevel> level = const Value.absent(),
            Value<EquipmentProfile> equipmentProfile = const Value.absent(),
            Value<int> sessionsPerWeek = const Value.absent(),
            Value<int> durationWeeks = const Value.absent(),
            Value<RestDayMode> restDayMode = const Value.absent(),
            Value<int> trainingDaysMask = const Value.absent(),
            Value<int> sessionDurationMinutes = const Value.absent(),
            Value<int> createdEpochDay = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            programId: programId,
            goal: goal,
            goalsCsv: goalsCsv,
            gender: gender,
            bodyType: bodyType,
            level: level,
            equipmentProfile: equipmentProfile,
            sessionsPerWeek: sessionsPerWeek,
            durationWeeks: durationWeeks,
            restDayMode: restDayMode,
            trainingDaysMask: trainingDaysMask,
            sessionDurationMinutes: sessionDurationMinutes,
            createdEpochDay: createdEpochDay,
            archived: archived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String programId,
            required FitnessGoal goal,
            Value<String> goalsCsv = const Value.absent(),
            Value<Gender> gender = const Value.absent(),
            Value<BodyType> bodyType = const Value.absent(),
            required ExperienceLevel level,
            required EquipmentProfile equipmentProfile,
            required int sessionsPerWeek,
            required int durationWeeks,
            required RestDayMode restDayMode,
            Value<int> trainingDaysMask = const Value.absent(),
            Value<int> sessionDurationMinutes = const Value.absent(),
            required int createdEpochDay,
            Value<bool> archived = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            programId: programId,
            goal: goal,
            goalsCsv: goalsCsv,
            gender: gender,
            bodyType: bodyType,
            level: level,
            equipmentProfile: equipmentProfile,
            sessionsPerWeek: sessionsPerWeek,
            durationWeeks: durationWeeks,
            restDayMode: restDayMode,
            trainingDaysMask: trainingDaysMask,
            sessionDurationMinutes: sessionDurationMinutes,
            createdEpochDay: createdEpochDay,
            archived: archived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({workoutSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutSessionsRefs) db.workoutSessions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSessionsRefs)
                    await $_getPrefetchedData<Goal, $GoalsTable,
                            WorkoutSession>(
                        currentTable: table,
                        referencedTable: $$GoalsTableReferences
                            ._workoutSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GoalsTableReferences(db, table, p0)
                                .workoutSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.goalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool workoutSessionsRefs})>;
typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<int> id,
  required int goalId,
  required int sequenceIndex,
  required String titleVi,
  required String focusVi,
  required int estimatedMinutes,
  required int dueEpochDay,
  Value<int?> completedEpochDay,
  Value<int> volumeScalePercent,
  Value<int?> selectedTimeBudgetMinutes,
});
typedef $$WorkoutSessionsTableUpdateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<int> id,
  Value<int> goalId,
  Value<int> sequenceIndex,
  Value<String> titleVi,
  Value<String> focusVi,
  Value<int> estimatedMinutes,
  Value<int> dueEpochDay,
  Value<int?> completedEpochDay,
  Value<int> volumeScalePercent,
  Value<int?> selectedTimeBudgetMinutes,
});

final class $$WorkoutSessionsTableReferences extends BaseReferences<
    _$GymDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$GymDatabase db) =>
      db.goals.createAlias('workout_sessions__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<int>('goal_id')!;

    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
      _sessionExercisesRefsTable(_$GymDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessionExercises,
              aliasName: 'workout_sessions__id__session_exercises__session_id');

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager =
        $$SessionExercisesTableTableManager($_db, $_db.sessionExercises)
            .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_sessionExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutFeedbacksTable, List<WorkoutFeedbackData>>
      _workoutFeedbacksRefsTable(_$GymDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutFeedbacks,
              aliasName: 'workout_sessions__id__workout_feedbacks__session_id');

  $$WorkoutFeedbacksTableProcessedTableManager get workoutFeedbacksRefs {
    final manager =
        $$WorkoutFeedbacksTableTableManager($_db, $_db.workoutFeedbacks)
            .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutFeedbacksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$GymDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequenceIndex => $composableBuilder(
      column: $table.sequenceIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleVi => $composableBuilder(
      column: $table.titleVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get focusVi => $composableBuilder(
      column: $table.focusVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueEpochDay => $composableBuilder(
      column: $table.dueEpochDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get volumeScalePercent => $composableBuilder(
      column: $table.volumeScalePercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get selectedTimeBudgetMinutes => $composableBuilder(
      column: $table.selectedTimeBudgetMinutes,
      builder: (column) => ColumnFilters(column));

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> sessionExercisesRefs(
      Expression<bool> Function($$SessionExercisesTableFilterComposer f) f) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessionExercises,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionExercisesTableFilterComposer(
              $db: $db,
              $table: $db.sessionExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutFeedbacksRefs(
      Expression<bool> Function($$WorkoutFeedbacksTableFilterComposer f) f) {
    final $$WorkoutFeedbacksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutFeedbacks,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutFeedbacksTableFilterComposer(
              $db: $db,
              $table: $db.workoutFeedbacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$GymDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
      column: $table.sequenceIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleVi => $composableBuilder(
      column: $table.titleVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get focusVi => $composableBuilder(
      column: $table.focusVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueEpochDay => $composableBuilder(
      column: $table.dueEpochDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get volumeScalePercent => $composableBuilder(
      column: $table.volumeScalePercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get selectedTimeBudgetMinutes => $composableBuilder(
      column: $table.selectedTimeBudgetMinutes,
      builder: (column) => ColumnOrderings(column));

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$GymDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
      column: $table.sequenceIndex, builder: (column) => column);

  GeneratedColumn<String> get titleVi =>
      $composableBuilder(column: $table.titleVi, builder: (column) => column);

  GeneratedColumn<String> get focusVi =>
      $composableBuilder(column: $table.focusVi, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes, builder: (column) => column);

  GeneratedColumn<int> get dueEpochDay => $composableBuilder(
      column: $table.dueEpochDay, builder: (column) => column);

  GeneratedColumn<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay, builder: (column) => column);

  GeneratedColumn<int> get volumeScalePercent => $composableBuilder(
      column: $table.volumeScalePercent, builder: (column) => column);

  GeneratedColumn<int> get selectedTimeBudgetMinutes => $composableBuilder(
      column: $table.selectedTimeBudgetMinutes, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> sessionExercisesRefs<T extends Object>(
      Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessionExercises,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.sessionExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutFeedbacksRefs<T extends Object>(
      Expression<T> Function($$WorkoutFeedbacksTableAnnotationComposer a) f) {
    final $$WorkoutFeedbacksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutFeedbacks,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutFeedbacksTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutFeedbacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $WorkoutSessionsTable,
    WorkoutSession,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (WorkoutSession, $$WorkoutSessionsTableReferences),
    WorkoutSession,
    PrefetchHooks Function(
        {bool goalId, bool sessionExercisesRefs, bool workoutFeedbacksRefs})> {
  $$WorkoutSessionsTableTableManager(
      _$GymDatabase db, $WorkoutSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> goalId = const Value.absent(),
            Value<int> sequenceIndex = const Value.absent(),
            Value<String> titleVi = const Value.absent(),
            Value<String> focusVi = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<int> dueEpochDay = const Value.absent(),
            Value<int?> completedEpochDay = const Value.absent(),
            Value<int> volumeScalePercent = const Value.absent(),
            Value<int?> selectedTimeBudgetMinutes = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion(
            id: id,
            goalId: goalId,
            sequenceIndex: sequenceIndex,
            titleVi: titleVi,
            focusVi: focusVi,
            estimatedMinutes: estimatedMinutes,
            dueEpochDay: dueEpochDay,
            completedEpochDay: completedEpochDay,
            volumeScalePercent: volumeScalePercent,
            selectedTimeBudgetMinutes: selectedTimeBudgetMinutes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int goalId,
            required int sequenceIndex,
            required String titleVi,
            required String focusVi,
            required int estimatedMinutes,
            required int dueEpochDay,
            Value<int?> completedEpochDay = const Value.absent(),
            Value<int> volumeScalePercent = const Value.absent(),
            Value<int?> selectedTimeBudgetMinutes = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion.insert(
            id: id,
            goalId: goalId,
            sequenceIndex: sequenceIndex,
            titleVi: titleVi,
            focusVi: focusVi,
            estimatedMinutes: estimatedMinutes,
            dueEpochDay: dueEpochDay,
            completedEpochDay: completedEpochDay,
            volumeScalePercent: volumeScalePercent,
            selectedTimeBudgetMinutes: selectedTimeBudgetMinutes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {goalId = false,
              sessionExercisesRefs = false,
              workoutFeedbacksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionExercisesRefs) db.sessionExercises,
                if (workoutFeedbacksRefs) db.workoutFeedbacks
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable:
                        $$WorkoutSessionsTableReferences._goalIdTable(db),
                    referencedColumn:
                        $$WorkoutSessionsTableReferences._goalIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionExercisesRefs)
                    await $_getPrefetchedData<WorkoutSession,
                            $WorkoutSessionsTable, SessionExercise>(
                        currentTable: table,
                        referencedTable: $$WorkoutSessionsTableReferences
                            ._sessionExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSessionsTableReferences(db, table, p0)
                                .sessionExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items),
                  if (workoutFeedbacksRefs)
                    await $_getPrefetchedData<WorkoutSession,
                            $WorkoutSessionsTable, WorkoutFeedbackData>(
                        currentTable: table,
                        referencedTable: $$WorkoutSessionsTableReferences
                            ._workoutFeedbacksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSessionsTableReferences(db, table, p0)
                                .workoutFeedbacksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutSessionsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $WorkoutSessionsTable,
    WorkoutSession,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (WorkoutSession, $$WorkoutSessionsTableReferences),
    WorkoutSession,
    PrefetchHooks Function(
        {bool goalId, bool sessionExercisesRefs, bool workoutFeedbacksRefs})>;
typedef $$SessionExercisesTableCreateCompanionBuilder
    = SessionExercisesCompanion Function({
  required int sessionId,
  required int orderIndex,
  required String exerciseId,
  Value<String?> originalExerciseId,
  required int sets,
  Value<int?> minReps,
  Value<int?> maxReps,
  Value<int?> durationSeconds,
  required int restSeconds,
  Value<bool> isChecked,
  Value<bool> omittedByTimeBudget,
  Value<int> rowid,
});
typedef $$SessionExercisesTableUpdateCompanionBuilder
    = SessionExercisesCompanion Function({
  Value<int> sessionId,
  Value<int> orderIndex,
  Value<String> exerciseId,
  Value<String?> originalExerciseId,
  Value<int> sets,
  Value<int?> minReps,
  Value<int?> maxReps,
  Value<int?> durationSeconds,
  Value<int> restSeconds,
  Value<bool> isChecked,
  Value<bool> omittedByTimeBudget,
  Value<int> rowid,
});

final class $$SessionExercisesTableReferences extends BaseReferences<
    _$GymDatabase, $SessionExercisesTable, SessionExercise> {
  $$SessionExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$GymDatabase db) =>
      db.workoutSessions
          .createAlias('session_exercises__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager =
        $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SessionExercisesTableFilterComposer
    extends Composer<_$GymDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalExerciseId => $composableBuilder(
      column: $table.originalExerciseId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minReps => $composableBuilder(
      column: $table.minReps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxReps => $composableBuilder(
      column: $table.maxReps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get omittedByTimeBudget => $composableBuilder(
      column: $table.omittedByTimeBudget,
      builder: (column) => ColumnFilters(column));

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$GymDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalExerciseId => $composableBuilder(
      column: $table.originalExerciseId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minReps => $composableBuilder(
      column: $table.minReps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxReps => $composableBuilder(
      column: $table.maxReps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get omittedByTimeBudget => $composableBuilder(
      column: $table.omittedByTimeBudget,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$GymDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<String> get originalExerciseId => $composableBuilder(
      column: $table.originalExerciseId, builder: (column) => column);

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<int> get minReps =>
      $composableBuilder(column: $table.minReps, builder: (column) => column);

  GeneratedColumn<int> get maxReps =>
      $composableBuilder(column: $table.maxReps, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<bool> get omittedByTimeBudget => $composableBuilder(
      column: $table.omittedByTimeBudget, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionExercisesTableTableManager extends RootTableManager<
    _$GymDatabase,
    $SessionExercisesTable,
    SessionExercise,
    $$SessionExercisesTableFilterComposer,
    $$SessionExercisesTableOrderingComposer,
    $$SessionExercisesTableAnnotationComposer,
    $$SessionExercisesTableCreateCompanionBuilder,
    $$SessionExercisesTableUpdateCompanionBuilder,
    (SessionExercise, $$SessionExercisesTableReferences),
    SessionExercise,
    PrefetchHooks Function({bool sessionId})> {
  $$SessionExercisesTableTableManager(
      _$GymDatabase db, $SessionExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> sessionId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<String?> originalExerciseId = const Value.absent(),
            Value<int> sets = const Value.absent(),
            Value<int?> minReps = const Value.absent(),
            Value<int?> maxReps = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int> restSeconds = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            Value<bool> omittedByTimeBudget = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionExercisesCompanion(
            sessionId: sessionId,
            orderIndex: orderIndex,
            exerciseId: exerciseId,
            originalExerciseId: originalExerciseId,
            sets: sets,
            minReps: minReps,
            maxReps: maxReps,
            durationSeconds: durationSeconds,
            restSeconds: restSeconds,
            isChecked: isChecked,
            omittedByTimeBudget: omittedByTimeBudget,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int sessionId,
            required int orderIndex,
            required String exerciseId,
            Value<String?> originalExerciseId = const Value.absent(),
            required int sets,
            Value<int?> minReps = const Value.absent(),
            Value<int?> maxReps = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            required int restSeconds,
            Value<bool> isChecked = const Value.absent(),
            Value<bool> omittedByTimeBudget = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionExercisesCompanion.insert(
            sessionId: sessionId,
            orderIndex: orderIndex,
            exerciseId: exerciseId,
            originalExerciseId: originalExerciseId,
            sets: sets,
            minReps: minReps,
            maxReps: maxReps,
            durationSeconds: durationSeconds,
            restSeconds: restSeconds,
            isChecked: isChecked,
            omittedByTimeBudget: omittedByTimeBudget,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SessionExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$SessionExercisesTableReferences._sessionIdTable(db),
                    referencedColumn: $$SessionExercisesTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SessionExercisesTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $SessionExercisesTable,
    SessionExercise,
    $$SessionExercisesTableFilterComposer,
    $$SessionExercisesTableOrderingComposer,
    $$SessionExercisesTableAnnotationComposer,
    $$SessionExercisesTableCreateCompanionBuilder,
    $$SessionExercisesTableUpdateCompanionBuilder,
    (SessionExercise, $$SessionExercisesTableReferences),
    SessionExercise,
    PrefetchHooks Function({bool sessionId})>;
typedef $$PersonalProfilesTableCreateCompanionBuilder
    = PersonalProfilesCompanion Function({
  Value<int> id,
  required int birthDateEpochDay,
  required MetabolicSex metabolicSex,
  required double heightCm,
  required double currentWeightKg,
  required double targetWeightKg,
  required ActivityLevel activityLevel,
  required GoalPace goalPace,
  required bool personalizationConsent,
  required bool cloudAiConsent,
  required int updatedAtEpochMillis,
});
typedef $$PersonalProfilesTableUpdateCompanionBuilder
    = PersonalProfilesCompanion Function({
  Value<int> id,
  Value<int> birthDateEpochDay,
  Value<MetabolicSex> metabolicSex,
  Value<double> heightCm,
  Value<double> currentWeightKg,
  Value<double> targetWeightKg,
  Value<ActivityLevel> activityLevel,
  Value<GoalPace> goalPace,
  Value<bool> personalizationConsent,
  Value<bool> cloudAiConsent,
  Value<int> updatedAtEpochMillis,
});

class $$PersonalProfilesTableFilterComposer
    extends Composer<_$GymDatabase, $PersonalProfilesTable> {
  $$PersonalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthDateEpochDay => $composableBuilder(
      column: $table.birthDateEpochDay,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MetabolicSex, MetabolicSex, String>
      get metabolicSex => $composableBuilder(
          column: $table.metabolicSex,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentWeightKg => $composableBuilder(
      column: $table.currentWeightKg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, String>
      get activityLevel => $composableBuilder(
          column: $table.activityLevel,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<GoalPace, GoalPace, String> get goalPace =>
      $composableBuilder(
          column: $table.goalPace,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get personalizationConsent => $composableBuilder(
      column: $table.personalizationConsent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get cloudAiConsent => $composableBuilder(
      column: $table.cloudAiConsent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$PersonalProfilesTableOrderingComposer
    extends Composer<_$GymDatabase, $PersonalProfilesTable> {
  $$PersonalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthDateEpochDay => $composableBuilder(
      column: $table.birthDateEpochDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metabolicSex => $composableBuilder(
      column: $table.metabolicSex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentWeightKg => $composableBuilder(
      column: $table.currentWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goalPace => $composableBuilder(
      column: $table.goalPace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get personalizationConsent => $composableBuilder(
      column: $table.personalizationConsent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get cloudAiConsent => $composableBuilder(
      column: $table.cloudAiConsent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$PersonalProfilesTableAnnotationComposer
    extends Composer<_$GymDatabase, $PersonalProfilesTable> {
  $$PersonalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get birthDateEpochDay => $composableBuilder(
      column: $table.birthDateEpochDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MetabolicSex, String> get metabolicSex =>
      $composableBuilder(
          column: $table.metabolicSex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get currentWeightKg => $composableBuilder(
      column: $table.currentWeightKg, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, String> get activityLevel =>
      $composableBuilder(
          column: $table.activityLevel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalPace, String> get goalPace =>
      $composableBuilder(column: $table.goalPace, builder: (column) => column);

  GeneratedColumn<bool> get personalizationConsent => $composableBuilder(
      column: $table.personalizationConsent, builder: (column) => column);

  GeneratedColumn<bool> get cloudAiConsent => $composableBuilder(
      column: $table.cloudAiConsent, builder: (column) => column);

  GeneratedColumn<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis, builder: (column) => column);
}

class $$PersonalProfilesTableTableManager extends RootTableManager<
    _$GymDatabase,
    $PersonalProfilesTable,
    PersonalProfileData,
    $$PersonalProfilesTableFilterComposer,
    $$PersonalProfilesTableOrderingComposer,
    $$PersonalProfilesTableAnnotationComposer,
    $$PersonalProfilesTableCreateCompanionBuilder,
    $$PersonalProfilesTableUpdateCompanionBuilder,
    (
      PersonalProfileData,
      BaseReferences<_$GymDatabase, $PersonalProfilesTable, PersonalProfileData>
    ),
    PersonalProfileData,
    PrefetchHooks Function()> {
  $$PersonalProfilesTableTableManager(
      _$GymDatabase db, $PersonalProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> birthDateEpochDay = const Value.absent(),
            Value<MetabolicSex> metabolicSex = const Value.absent(),
            Value<double> heightCm = const Value.absent(),
            Value<double> currentWeightKg = const Value.absent(),
            Value<double> targetWeightKg = const Value.absent(),
            Value<ActivityLevel> activityLevel = const Value.absent(),
            Value<GoalPace> goalPace = const Value.absent(),
            Value<bool> personalizationConsent = const Value.absent(),
            Value<bool> cloudAiConsent = const Value.absent(),
            Value<int> updatedAtEpochMillis = const Value.absent(),
          }) =>
              PersonalProfilesCompanion(
            id: id,
            birthDateEpochDay: birthDateEpochDay,
            metabolicSex: metabolicSex,
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
            targetWeightKg: targetWeightKg,
            activityLevel: activityLevel,
            goalPace: goalPace,
            personalizationConsent: personalizationConsent,
            cloudAiConsent: cloudAiConsent,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int birthDateEpochDay,
            required MetabolicSex metabolicSex,
            required double heightCm,
            required double currentWeightKg,
            required double targetWeightKg,
            required ActivityLevel activityLevel,
            required GoalPace goalPace,
            required bool personalizationConsent,
            required bool cloudAiConsent,
            required int updatedAtEpochMillis,
          }) =>
              PersonalProfilesCompanion.insert(
            id: id,
            birthDateEpochDay: birthDateEpochDay,
            metabolicSex: metabolicSex,
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
            targetWeightKg: targetWeightKg,
            activityLevel: activityLevel,
            goalPace: goalPace,
            personalizationConsent: personalizationConsent,
            cloudAiConsent: cloudAiConsent,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PersonalProfilesTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $PersonalProfilesTable,
    PersonalProfileData,
    $$PersonalProfilesTableFilterComposer,
    $$PersonalProfilesTableOrderingComposer,
    $$PersonalProfilesTableAnnotationComposer,
    $$PersonalProfilesTableCreateCompanionBuilder,
    $$PersonalProfilesTableUpdateCompanionBuilder,
    (
      PersonalProfileData,
      BaseReferences<_$GymDatabase, $PersonalProfilesTable, PersonalProfileData>
    ),
    PersonalProfileData,
    PrefetchHooks Function()>;
typedef $$WeightMeasurementsTableCreateCompanionBuilder
    = WeightMeasurementsCompanion Function({
  Value<int> epochDay,
  required double weightKg,
  required int recordedAtEpochMillis,
});
typedef $$WeightMeasurementsTableUpdateCompanionBuilder
    = WeightMeasurementsCompanion Function({
  Value<int> epochDay,
  Value<double> weightKg,
  Value<int> recordedAtEpochMillis,
});

class $$WeightMeasurementsTableFilterComposer
    extends Composer<_$GymDatabase, $WeightMeasurementsTable> {
  $$WeightMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$WeightMeasurementsTableOrderingComposer
    extends Composer<_$GymDatabase, $WeightMeasurementsTable> {
  $$WeightMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$WeightMeasurementsTableAnnotationComposer
    extends Composer<_$GymDatabase, $WeightMeasurementsTable> {
  $$WeightMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get epochDay =>
      $composableBuilder(column: $table.epochDay, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis, builder: (column) => column);
}

class $$WeightMeasurementsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $WeightMeasurementsTable,
    WeightMeasurement,
    $$WeightMeasurementsTableFilterComposer,
    $$WeightMeasurementsTableOrderingComposer,
    $$WeightMeasurementsTableAnnotationComposer,
    $$WeightMeasurementsTableCreateCompanionBuilder,
    $$WeightMeasurementsTableUpdateCompanionBuilder,
    (
      WeightMeasurement,
      BaseReferences<_$GymDatabase, $WeightMeasurementsTable, WeightMeasurement>
    ),
    WeightMeasurement,
    PrefetchHooks Function()> {
  $$WeightMeasurementsTableTableManager(
      _$GymDatabase db, $WeightMeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightMeasurementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> epochDay = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<int> recordedAtEpochMillis = const Value.absent(),
          }) =>
              WeightMeasurementsCompanion(
            epochDay: epochDay,
            weightKg: weightKg,
            recordedAtEpochMillis: recordedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> epochDay = const Value.absent(),
            required double weightKg,
            required int recordedAtEpochMillis,
          }) =>
              WeightMeasurementsCompanion.insert(
            epochDay: epochDay,
            weightKg: weightKg,
            recordedAtEpochMillis: recordedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeightMeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $WeightMeasurementsTable,
    WeightMeasurement,
    $$WeightMeasurementsTableFilterComposer,
    $$WeightMeasurementsTableOrderingComposer,
    $$WeightMeasurementsTableAnnotationComposer,
    $$WeightMeasurementsTableCreateCompanionBuilder,
    $$WeightMeasurementsTableUpdateCompanionBuilder,
    (
      WeightMeasurement,
      BaseReferences<_$GymDatabase, $WeightMeasurementsTable, WeightMeasurement>
    ),
    WeightMeasurement,
    PrefetchHooks Function()>;
typedef $$DailyNutritionsTableCreateCompanionBuilder = DailyNutritionsCompanion
    Function({
  Value<int> epochDay,
  Value<int> consumedCalories,
  Value<int> consumedProteinGrams,
  Value<int> consumedCarbsGrams,
  Value<int> consumedFatGrams,
  Value<int> consumedFiberGrams,
  Value<int?> targetBasalCalories,
  Value<int?> targetMaintenanceCalories,
  Value<int?> targetCalories,
  Value<int?> targetProteinGrams,
  Value<int?> targetCarbsGrams,
  Value<int?> targetFatGrams,
  Value<String?> lastEntrySource,
  Value<int> waterIntakeMl,
  Value<int> updatedAtEpochMillis,
});
typedef $$DailyNutritionsTableUpdateCompanionBuilder = DailyNutritionsCompanion
    Function({
  Value<int> epochDay,
  Value<int> consumedCalories,
  Value<int> consumedProteinGrams,
  Value<int> consumedCarbsGrams,
  Value<int> consumedFatGrams,
  Value<int> consumedFiberGrams,
  Value<int?> targetBasalCalories,
  Value<int?> targetMaintenanceCalories,
  Value<int?> targetCalories,
  Value<int?> targetProteinGrams,
  Value<int?> targetCarbsGrams,
  Value<int?> targetFatGrams,
  Value<String?> lastEntrySource,
  Value<int> waterIntakeMl,
  Value<int> updatedAtEpochMillis,
});

class $$DailyNutritionsTableFilterComposer
    extends Composer<_$GymDatabase, $DailyNutritionsTable> {
  $$DailyNutritionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consumedCalories => $composableBuilder(
      column: $table.consumedCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consumedProteinGrams => $composableBuilder(
      column: $table.consumedProteinGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consumedCarbsGrams => $composableBuilder(
      column: $table.consumedCarbsGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consumedFatGrams => $composableBuilder(
      column: $table.consumedFatGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consumedFiberGrams => $composableBuilder(
      column: $table.consumedFiberGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetBasalCalories => $composableBuilder(
      column: $table.targetBasalCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetMaintenanceCalories => $composableBuilder(
      column: $table.targetMaintenanceCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetProteinGrams => $composableBuilder(
      column: $table.targetProteinGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCarbsGrams => $composableBuilder(
      column: $table.targetCarbsGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetFatGrams => $composableBuilder(
      column: $table.targetFatGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastEntrySource => $composableBuilder(
      column: $table.lastEntrySource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get waterIntakeMl => $composableBuilder(
      column: $table.waterIntakeMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$DailyNutritionsTableOrderingComposer
    extends Composer<_$GymDatabase, $DailyNutritionsTable> {
  $$DailyNutritionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consumedCalories => $composableBuilder(
      column: $table.consumedCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consumedProteinGrams => $composableBuilder(
      column: $table.consumedProteinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consumedCarbsGrams => $composableBuilder(
      column: $table.consumedCarbsGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consumedFatGrams => $composableBuilder(
      column: $table.consumedFatGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consumedFiberGrams => $composableBuilder(
      column: $table.consumedFiberGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetBasalCalories => $composableBuilder(
      column: $table.targetBasalCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetMaintenanceCalories => $composableBuilder(
      column: $table.targetMaintenanceCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetProteinGrams => $composableBuilder(
      column: $table.targetProteinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCarbsGrams => $composableBuilder(
      column: $table.targetCarbsGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetFatGrams => $composableBuilder(
      column: $table.targetFatGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastEntrySource => $composableBuilder(
      column: $table.lastEntrySource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get waterIntakeMl => $composableBuilder(
      column: $table.waterIntakeMl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$DailyNutritionsTableAnnotationComposer
    extends Composer<_$GymDatabase, $DailyNutritionsTable> {
  $$DailyNutritionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get epochDay =>
      $composableBuilder(column: $table.epochDay, builder: (column) => column);

  GeneratedColumn<int> get consumedCalories => $composableBuilder(
      column: $table.consumedCalories, builder: (column) => column);

  GeneratedColumn<int> get consumedProteinGrams => $composableBuilder(
      column: $table.consumedProteinGrams, builder: (column) => column);

  GeneratedColumn<int> get consumedCarbsGrams => $composableBuilder(
      column: $table.consumedCarbsGrams, builder: (column) => column);

  GeneratedColumn<int> get consumedFatGrams => $composableBuilder(
      column: $table.consumedFatGrams, builder: (column) => column);

  GeneratedColumn<int> get consumedFiberGrams => $composableBuilder(
      column: $table.consumedFiberGrams, builder: (column) => column);

  GeneratedColumn<int> get targetBasalCalories => $composableBuilder(
      column: $table.targetBasalCalories, builder: (column) => column);

  GeneratedColumn<int> get targetMaintenanceCalories => $composableBuilder(
      column: $table.targetMaintenanceCalories, builder: (column) => column);

  GeneratedColumn<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories, builder: (column) => column);

  GeneratedColumn<int> get targetProteinGrams => $composableBuilder(
      column: $table.targetProteinGrams, builder: (column) => column);

  GeneratedColumn<int> get targetCarbsGrams => $composableBuilder(
      column: $table.targetCarbsGrams, builder: (column) => column);

  GeneratedColumn<int> get targetFatGrams => $composableBuilder(
      column: $table.targetFatGrams, builder: (column) => column);

  GeneratedColumn<String> get lastEntrySource => $composableBuilder(
      column: $table.lastEntrySource, builder: (column) => column);

  GeneratedColumn<int> get waterIntakeMl => $composableBuilder(
      column: $table.waterIntakeMl, builder: (column) => column);

  GeneratedColumn<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis, builder: (column) => column);
}

class $$DailyNutritionsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $DailyNutritionsTable,
    DailyNutritionData,
    $$DailyNutritionsTableFilterComposer,
    $$DailyNutritionsTableOrderingComposer,
    $$DailyNutritionsTableAnnotationComposer,
    $$DailyNutritionsTableCreateCompanionBuilder,
    $$DailyNutritionsTableUpdateCompanionBuilder,
    (
      DailyNutritionData,
      BaseReferences<_$GymDatabase, $DailyNutritionsTable, DailyNutritionData>
    ),
    DailyNutritionData,
    PrefetchHooks Function()> {
  $$DailyNutritionsTableTableManager(
      _$GymDatabase db, $DailyNutritionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNutritionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNutritionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyNutritionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> epochDay = const Value.absent(),
            Value<int> consumedCalories = const Value.absent(),
            Value<int> consumedProteinGrams = const Value.absent(),
            Value<int> consumedCarbsGrams = const Value.absent(),
            Value<int> consumedFatGrams = const Value.absent(),
            Value<int> consumedFiberGrams = const Value.absent(),
            Value<int?> targetBasalCalories = const Value.absent(),
            Value<int?> targetMaintenanceCalories = const Value.absent(),
            Value<int?> targetCalories = const Value.absent(),
            Value<int?> targetProteinGrams = const Value.absent(),
            Value<int?> targetCarbsGrams = const Value.absent(),
            Value<int?> targetFatGrams = const Value.absent(),
            Value<String?> lastEntrySource = const Value.absent(),
            Value<int> waterIntakeMl = const Value.absent(),
            Value<int> updatedAtEpochMillis = const Value.absent(),
          }) =>
              DailyNutritionsCompanion(
            epochDay: epochDay,
            consumedCalories: consumedCalories,
            consumedProteinGrams: consumedProteinGrams,
            consumedCarbsGrams: consumedCarbsGrams,
            consumedFatGrams: consumedFatGrams,
            consumedFiberGrams: consumedFiberGrams,
            targetBasalCalories: targetBasalCalories,
            targetMaintenanceCalories: targetMaintenanceCalories,
            targetCalories: targetCalories,
            targetProteinGrams: targetProteinGrams,
            targetCarbsGrams: targetCarbsGrams,
            targetFatGrams: targetFatGrams,
            lastEntrySource: lastEntrySource,
            waterIntakeMl: waterIntakeMl,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> epochDay = const Value.absent(),
            Value<int> consumedCalories = const Value.absent(),
            Value<int> consumedProteinGrams = const Value.absent(),
            Value<int> consumedCarbsGrams = const Value.absent(),
            Value<int> consumedFatGrams = const Value.absent(),
            Value<int> consumedFiberGrams = const Value.absent(),
            Value<int?> targetBasalCalories = const Value.absent(),
            Value<int?> targetMaintenanceCalories = const Value.absent(),
            Value<int?> targetCalories = const Value.absent(),
            Value<int?> targetProteinGrams = const Value.absent(),
            Value<int?> targetCarbsGrams = const Value.absent(),
            Value<int?> targetFatGrams = const Value.absent(),
            Value<String?> lastEntrySource = const Value.absent(),
            Value<int> waterIntakeMl = const Value.absent(),
            Value<int> updatedAtEpochMillis = const Value.absent(),
          }) =>
              DailyNutritionsCompanion.insert(
            epochDay: epochDay,
            consumedCalories: consumedCalories,
            consumedProteinGrams: consumedProteinGrams,
            consumedCarbsGrams: consumedCarbsGrams,
            consumedFatGrams: consumedFatGrams,
            consumedFiberGrams: consumedFiberGrams,
            targetBasalCalories: targetBasalCalories,
            targetMaintenanceCalories: targetMaintenanceCalories,
            targetCalories: targetCalories,
            targetProteinGrams: targetProteinGrams,
            targetCarbsGrams: targetCarbsGrams,
            targetFatGrams: targetFatGrams,
            lastEntrySource: lastEntrySource,
            waterIntakeMl: waterIntakeMl,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyNutritionsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $DailyNutritionsTable,
    DailyNutritionData,
    $$DailyNutritionsTableFilterComposer,
    $$DailyNutritionsTableOrderingComposer,
    $$DailyNutritionsTableAnnotationComposer,
    $$DailyNutritionsTableCreateCompanionBuilder,
    $$DailyNutritionsTableUpdateCompanionBuilder,
    (
      DailyNutritionData,
      BaseReferences<_$GymDatabase, $DailyNutritionsTable, DailyNutritionData>
    ),
    DailyNutritionData,
    PrefetchHooks Function()>;
typedef $$WeeklyCheckInsTableCreateCompanionBuilder = WeeklyCheckInsCompanion
    Function({
  Value<int> weekStartEpochDay,
  required double weightKg,
  required int energy,
  required int hunger,
  required int recovery,
  required int sleepQuality,
  Value<String?> note,
  required int createdAtEpochMillis,
});
typedef $$WeeklyCheckInsTableUpdateCompanionBuilder = WeeklyCheckInsCompanion
    Function({
  Value<int> weekStartEpochDay,
  Value<double> weightKg,
  Value<int> energy,
  Value<int> hunger,
  Value<int> recovery,
  Value<int> sleepQuality,
  Value<String?> note,
  Value<int> createdAtEpochMillis,
});

class $$WeeklyCheckInsTableFilterComposer
    extends Composer<_$GymDatabase, $WeeklyCheckInsTable> {
  $$WeeklyCheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get weekStartEpochDay => $composableBuilder(
      column: $table.weekStartEpochDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hunger => $composableBuilder(
      column: $table.hunger, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recovery => $composableBuilder(
      column: $table.recovery, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$WeeklyCheckInsTableOrderingComposer
    extends Composer<_$GymDatabase, $WeeklyCheckInsTable> {
  $$WeeklyCheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get weekStartEpochDay => $composableBuilder(
      column: $table.weekStartEpochDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hunger => $composableBuilder(
      column: $table.hunger, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recovery => $composableBuilder(
      column: $table.recovery, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$WeeklyCheckInsTableAnnotationComposer
    extends Composer<_$GymDatabase, $WeeklyCheckInsTable> {
  $$WeeklyCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get weekStartEpochDay => $composableBuilder(
      column: $table.weekStartEpochDay, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<int> get hunger =>
      $composableBuilder(column: $table.hunger, builder: (column) => column);

  GeneratedColumn<int> get recovery =>
      $composableBuilder(column: $table.recovery, builder: (column) => column);

  GeneratedColumn<int> get sleepQuality => $composableBuilder(
      column: $table.sleepQuality, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis, builder: (column) => column);
}

class $$WeeklyCheckInsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $WeeklyCheckInsTable,
    WeeklyCheckInData,
    $$WeeklyCheckInsTableFilterComposer,
    $$WeeklyCheckInsTableOrderingComposer,
    $$WeeklyCheckInsTableAnnotationComposer,
    $$WeeklyCheckInsTableCreateCompanionBuilder,
    $$WeeklyCheckInsTableUpdateCompanionBuilder,
    (
      WeeklyCheckInData,
      BaseReferences<_$GymDatabase, $WeeklyCheckInsTable, WeeklyCheckInData>
    ),
    WeeklyCheckInData,
    PrefetchHooks Function()> {
  $$WeeklyCheckInsTableTableManager(
      _$GymDatabase db, $WeeklyCheckInsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> weekStartEpochDay = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<int> energy = const Value.absent(),
            Value<int> hunger = const Value.absent(),
            Value<int> recovery = const Value.absent(),
            Value<int> sleepQuality = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> createdAtEpochMillis = const Value.absent(),
          }) =>
              WeeklyCheckInsCompanion(
            weekStartEpochDay: weekStartEpochDay,
            weightKg: weightKg,
            energy: energy,
            hunger: hunger,
            recovery: recovery,
            sleepQuality: sleepQuality,
            note: note,
            createdAtEpochMillis: createdAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> weekStartEpochDay = const Value.absent(),
            required double weightKg,
            required int energy,
            required int hunger,
            required int recovery,
            required int sleepQuality,
            Value<String?> note = const Value.absent(),
            required int createdAtEpochMillis,
          }) =>
              WeeklyCheckInsCompanion.insert(
            weekStartEpochDay: weekStartEpochDay,
            weightKg: weightKg,
            energy: energy,
            hunger: hunger,
            recovery: recovery,
            sleepQuality: sleepQuality,
            note: note,
            createdAtEpochMillis: createdAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeeklyCheckInsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $WeeklyCheckInsTable,
    WeeklyCheckInData,
    $$WeeklyCheckInsTableFilterComposer,
    $$WeeklyCheckInsTableOrderingComposer,
    $$WeeklyCheckInsTableAnnotationComposer,
    $$WeeklyCheckInsTableCreateCompanionBuilder,
    $$WeeklyCheckInsTableUpdateCompanionBuilder,
    (
      WeeklyCheckInData,
      BaseReferences<_$GymDatabase, $WeeklyCheckInsTable, WeeklyCheckInData>
    ),
    WeeklyCheckInData,
    PrefetchHooks Function()>;
typedef $$AdaptationDecisionsTableCreateCompanionBuilder
    = AdaptationDecisionsCompanion Function({
  Value<int> id,
  required AdaptationKind kind,
  required AdaptationMode mode,
  required AdaptationStatus status,
  required String reasonVi,
  required int payloadVersion,
  required String inputsJson,
  required String beforeJson,
  required String afterJson,
  required String undoJson,
  required int createdAtEpochMillis,
  Value<int?> resolvedAtEpochMillis,
});
typedef $$AdaptationDecisionsTableUpdateCompanionBuilder
    = AdaptationDecisionsCompanion Function({
  Value<int> id,
  Value<AdaptationKind> kind,
  Value<AdaptationMode> mode,
  Value<AdaptationStatus> status,
  Value<String> reasonVi,
  Value<int> payloadVersion,
  Value<String> inputsJson,
  Value<String> beforeJson,
  Value<String> afterJson,
  Value<String> undoJson,
  Value<int> createdAtEpochMillis,
  Value<int?> resolvedAtEpochMillis,
});

class $$AdaptationDecisionsTableFilterComposer
    extends Composer<_$GymDatabase, $AdaptationDecisionsTable> {
  $$AdaptationDecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AdaptationKind, AdaptationKind, String>
      get kind => $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<AdaptationMode, AdaptationMode, String>
      get mode => $composableBuilder(
          column: $table.mode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<AdaptationStatus, AdaptationStatus, String>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get reasonVi => $composableBuilder(
      column: $table.reasonVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputsJson => $composableBuilder(
      column: $table.inputsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get afterJson => $composableBuilder(
      column: $table.afterJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get undoJson => $composableBuilder(
      column: $table.undoJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resolvedAtEpochMillis => $composableBuilder(
      column: $table.resolvedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$AdaptationDecisionsTableOrderingComposer
    extends Composer<_$GymDatabase, $AdaptationDecisionsTable> {
  $$AdaptationDecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonVi => $composableBuilder(
      column: $table.reasonVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputsJson => $composableBuilder(
      column: $table.inputsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get afterJson => $composableBuilder(
      column: $table.afterJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get undoJson => $composableBuilder(
      column: $table.undoJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resolvedAtEpochMillis => $composableBuilder(
      column: $table.resolvedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$AdaptationDecisionsTableAnnotationComposer
    extends Composer<_$GymDatabase, $AdaptationDecisionsTable> {
  $$AdaptationDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdaptationKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdaptationMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdaptationStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reasonVi =>
      $composableBuilder(column: $table.reasonVi, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion, builder: (column) => column);

  GeneratedColumn<String> get inputsJson => $composableBuilder(
      column: $table.inputsJson, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => column);

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);

  GeneratedColumn<String> get undoJson =>
      $composableBuilder(column: $table.undoJson, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpochMillis => $composableBuilder(
      column: $table.createdAtEpochMillis, builder: (column) => column);

  GeneratedColumn<int> get resolvedAtEpochMillis => $composableBuilder(
      column: $table.resolvedAtEpochMillis, builder: (column) => column);
}

class $$AdaptationDecisionsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $AdaptationDecisionsTable,
    AdaptationDecisionData,
    $$AdaptationDecisionsTableFilterComposer,
    $$AdaptationDecisionsTableOrderingComposer,
    $$AdaptationDecisionsTableAnnotationComposer,
    $$AdaptationDecisionsTableCreateCompanionBuilder,
    $$AdaptationDecisionsTableUpdateCompanionBuilder,
    (
      AdaptationDecisionData,
      BaseReferences<_$GymDatabase, $AdaptationDecisionsTable,
          AdaptationDecisionData>
    ),
    AdaptationDecisionData,
    PrefetchHooks Function()> {
  $$AdaptationDecisionsTableTableManager(
      _$GymDatabase db, $AdaptationDecisionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdaptationDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdaptationDecisionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdaptationDecisionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<AdaptationKind> kind = const Value.absent(),
            Value<AdaptationMode> mode = const Value.absent(),
            Value<AdaptationStatus> status = const Value.absent(),
            Value<String> reasonVi = const Value.absent(),
            Value<int> payloadVersion = const Value.absent(),
            Value<String> inputsJson = const Value.absent(),
            Value<String> beforeJson = const Value.absent(),
            Value<String> afterJson = const Value.absent(),
            Value<String> undoJson = const Value.absent(),
            Value<int> createdAtEpochMillis = const Value.absent(),
            Value<int?> resolvedAtEpochMillis = const Value.absent(),
          }) =>
              AdaptationDecisionsCompanion(
            id: id,
            kind: kind,
            mode: mode,
            status: status,
            reasonVi: reasonVi,
            payloadVersion: payloadVersion,
            inputsJson: inputsJson,
            beforeJson: beforeJson,
            afterJson: afterJson,
            undoJson: undoJson,
            createdAtEpochMillis: createdAtEpochMillis,
            resolvedAtEpochMillis: resolvedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required AdaptationKind kind,
            required AdaptationMode mode,
            required AdaptationStatus status,
            required String reasonVi,
            required int payloadVersion,
            required String inputsJson,
            required String beforeJson,
            required String afterJson,
            required String undoJson,
            required int createdAtEpochMillis,
            Value<int?> resolvedAtEpochMillis = const Value.absent(),
          }) =>
              AdaptationDecisionsCompanion.insert(
            id: id,
            kind: kind,
            mode: mode,
            status: status,
            reasonVi: reasonVi,
            payloadVersion: payloadVersion,
            inputsJson: inputsJson,
            beforeJson: beforeJson,
            afterJson: afterJson,
            undoJson: undoJson,
            createdAtEpochMillis: createdAtEpochMillis,
            resolvedAtEpochMillis: resolvedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AdaptationDecisionsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $AdaptationDecisionsTable,
    AdaptationDecisionData,
    $$AdaptationDecisionsTableFilterComposer,
    $$AdaptationDecisionsTableOrderingComposer,
    $$AdaptationDecisionsTableAnnotationComposer,
    $$AdaptationDecisionsTableCreateCompanionBuilder,
    $$AdaptationDecisionsTableUpdateCompanionBuilder,
    (
      AdaptationDecisionData,
      BaseReferences<_$GymDatabase, $AdaptationDecisionsTable,
          AdaptationDecisionData>
    ),
    AdaptationDecisionData,
    PrefetchHooks Function()>;
typedef $$AchievementsTableCreateCompanionBuilder = AchievementsCompanion
    Function({
  required String type,
  required int unlockedAtEpochMillis,
  Value<int> rowid,
});
typedef $$AchievementsTableUpdateCompanionBuilder = AchievementsCompanion
    Function({
  Value<String> type,
  Value<int> unlockedAtEpochMillis,
  Value<int> rowid,
});

class $$AchievementsTableFilterComposer
    extends Composer<_$GymDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unlockedAtEpochMillis => $composableBuilder(
      column: $table.unlockedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$GymDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unlockedAtEpochMillis => $composableBuilder(
      column: $table.unlockedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$GymDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get unlockedAtEpochMillis => $composableBuilder(
      column: $table.unlockedAtEpochMillis, builder: (column) => column);
}

class $$AchievementsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      Achievement,
      BaseReferences<_$GymDatabase, $AchievementsTable, Achievement>
    ),
    Achievement,
    PrefetchHooks Function()> {
  $$AchievementsTableTableManager(_$GymDatabase db, $AchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> type = const Value.absent(),
            Value<int> unlockedAtEpochMillis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion(
            type: type,
            unlockedAtEpochMillis: unlockedAtEpochMillis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String type,
            required int unlockedAtEpochMillis,
            Value<int> rowid = const Value.absent(),
          }) =>
              AchievementsCompanion.insert(
            type: type,
            unlockedAtEpochMillis: unlockedAtEpochMillis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AchievementsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (
      Achievement,
      BaseReferences<_$GymDatabase, $AchievementsTable, Achievement>
    ),
    Achievement,
    PrefetchHooks Function()>;
typedef $$WorkoutFeedbacksTableCreateCompanionBuilder
    = WorkoutFeedbacksCompanion Function({
  Value<int> sessionId,
  required int goalId,
  required int completedEpochDay,
  required WorkoutDifficulty difficulty,
  required int recordedAtEpochMillis,
});
typedef $$WorkoutFeedbacksTableUpdateCompanionBuilder
    = WorkoutFeedbacksCompanion Function({
  Value<int> sessionId,
  Value<int> goalId,
  Value<int> completedEpochDay,
  Value<WorkoutDifficulty> difficulty,
  Value<int> recordedAtEpochMillis,
});

final class $$WorkoutFeedbacksTableReferences extends BaseReferences<
    _$GymDatabase, $WorkoutFeedbacksTable, WorkoutFeedbackData> {
  $$WorkoutFeedbacksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$GymDatabase db) =>
      db.workoutSessions
          .createAlias('workout_feedbacks__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager =
        $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutFeedbacksTableFilterComposer
    extends Composer<_$GymDatabase, $WorkoutFeedbacksTable> {
  $$WorkoutFeedbacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WorkoutDifficulty, WorkoutDifficulty, String>
      get difficulty => $composableBuilder(
          column: $table.difficulty,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis,
      builder: (column) => ColumnFilters(column));

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutFeedbacksTableOrderingComposer
    extends Composer<_$GymDatabase, $WorkoutFeedbacksTable> {
  $$WorkoutFeedbacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutFeedbacksTableAnnotationComposer
    extends Composer<_$GymDatabase, $WorkoutFeedbacksTable> {
  $$WorkoutFeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<int> get completedEpochDay => $composableBuilder(
      column: $table.completedEpochDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkoutDifficulty, String> get difficulty =>
      $composableBuilder(
          column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get recordedAtEpochMillis => $composableBuilder(
      column: $table.recordedAtEpochMillis, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutFeedbacksTableTableManager extends RootTableManager<
    _$GymDatabase,
    $WorkoutFeedbacksTable,
    WorkoutFeedbackData,
    $$WorkoutFeedbacksTableFilterComposer,
    $$WorkoutFeedbacksTableOrderingComposer,
    $$WorkoutFeedbacksTableAnnotationComposer,
    $$WorkoutFeedbacksTableCreateCompanionBuilder,
    $$WorkoutFeedbacksTableUpdateCompanionBuilder,
    (WorkoutFeedbackData, $$WorkoutFeedbacksTableReferences),
    WorkoutFeedbackData,
    PrefetchHooks Function({bool sessionId})> {
  $$WorkoutFeedbacksTableTableManager(
      _$GymDatabase db, $WorkoutFeedbacksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutFeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutFeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutFeedbacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> sessionId = const Value.absent(),
            Value<int> goalId = const Value.absent(),
            Value<int> completedEpochDay = const Value.absent(),
            Value<WorkoutDifficulty> difficulty = const Value.absent(),
            Value<int> recordedAtEpochMillis = const Value.absent(),
          }) =>
              WorkoutFeedbacksCompanion(
            sessionId: sessionId,
            goalId: goalId,
            completedEpochDay: completedEpochDay,
            difficulty: difficulty,
            recordedAtEpochMillis: recordedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> sessionId = const Value.absent(),
            required int goalId,
            required int completedEpochDay,
            required WorkoutDifficulty difficulty,
            required int recordedAtEpochMillis,
          }) =>
              WorkoutFeedbacksCompanion.insert(
            sessionId: sessionId,
            goalId: goalId,
            completedEpochDay: completedEpochDay,
            difficulty: difficulty,
            recordedAtEpochMillis: recordedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutFeedbacksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$WorkoutFeedbacksTableReferences._sessionIdTable(db),
                    referencedColumn: $$WorkoutFeedbacksTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutFeedbacksTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $WorkoutFeedbacksTable,
    WorkoutFeedbackData,
    $$WorkoutFeedbacksTableFilterComposer,
    $$WorkoutFeedbacksTableOrderingComposer,
    $$WorkoutFeedbacksTableAnnotationComposer,
    $$WorkoutFeedbacksTableCreateCompanionBuilder,
    $$WorkoutFeedbacksTableUpdateCompanionBuilder,
    (WorkoutFeedbackData, $$WorkoutFeedbacksTableReferences),
    WorkoutFeedbackData,
    PrefetchHooks Function({bool sessionId})>;
typedef $$MealTemplatesTableCreateCompanionBuilder = MealTemplatesCompanion
    Function({
  Value<int> id,
  required String nameVi,
  required int calories,
  required int proteinGrams,
  required int carbsGrams,
  required int fatGrams,
  Value<int> fiberGrams,
  required int updatedAtEpochMillis,
});
typedef $$MealTemplatesTableUpdateCompanionBuilder = MealTemplatesCompanion
    Function({
  Value<int> id,
  Value<String> nameVi,
  Value<int> calories,
  Value<int> proteinGrams,
  Value<int> carbsGrams,
  Value<int> fatGrams,
  Value<int> fiberGrams,
  Value<int> updatedAtEpochMillis,
});

class $$MealTemplatesTableFilterComposer
    extends Composer<_$GymDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameVi => $composableBuilder(
      column: $table.nameVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnFilters(column));
}

class $$MealTemplatesTableOrderingComposer
    extends Composer<_$GymDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameVi => $composableBuilder(
      column: $table.nameVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$MealTemplatesTableAnnotationComposer
    extends Composer<_$GymDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameVi =>
      $composableBuilder(column: $table.nameVi, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => column);

  GeneratedColumn<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => column);

  GeneratedColumn<int> get fatGrams =>
      $composableBuilder(column: $table.fatGrams, builder: (column) => column);

  GeneratedColumn<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => column);

  GeneratedColumn<int> get updatedAtEpochMillis => $composableBuilder(
      column: $table.updatedAtEpochMillis, builder: (column) => column);
}

class $$MealTemplatesTableTableManager extends RootTableManager<
    _$GymDatabase,
    $MealTemplatesTable,
    MealTemplateData,
    $$MealTemplatesTableFilterComposer,
    $$MealTemplatesTableOrderingComposer,
    $$MealTemplatesTableAnnotationComposer,
    $$MealTemplatesTableCreateCompanionBuilder,
    $$MealTemplatesTableUpdateCompanionBuilder,
    (
      MealTemplateData,
      BaseReferences<_$GymDatabase, $MealTemplatesTable, MealTemplateData>
    ),
    MealTemplateData,
    PrefetchHooks Function()> {
  $$MealTemplatesTableTableManager(_$GymDatabase db, $MealTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nameVi = const Value.absent(),
            Value<int> calories = const Value.absent(),
            Value<int> proteinGrams = const Value.absent(),
            Value<int> carbsGrams = const Value.absent(),
            Value<int> fatGrams = const Value.absent(),
            Value<int> fiberGrams = const Value.absent(),
            Value<int> updatedAtEpochMillis = const Value.absent(),
          }) =>
              MealTemplatesCompanion(
            id: id,
            nameVi: nameVi,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            fiberGrams: fiberGrams,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nameVi,
            required int calories,
            required int proteinGrams,
            required int carbsGrams,
            required int fatGrams,
            Value<int> fiberGrams = const Value.absent(),
            required int updatedAtEpochMillis,
          }) =>
              MealTemplatesCompanion.insert(
            id: id,
            nameVi: nameVi,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            fiberGrams: fiberGrams,
            updatedAtEpochMillis: updatedAtEpochMillis,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $MealTemplatesTable,
    MealTemplateData,
    $$MealTemplatesTableFilterComposer,
    $$MealTemplatesTableOrderingComposer,
    $$MealTemplatesTableAnnotationComposer,
    $$MealTemplatesTableCreateCompanionBuilder,
    $$MealTemplatesTableUpdateCompanionBuilder,
    (
      MealTemplateData,
      BaseReferences<_$GymDatabase, $MealTemplatesTable, MealTemplateData>
    ),
    MealTemplateData,
    PrefetchHooks Function()>;
typedef $$UserFoodOverridesTableCreateCompanionBuilder
    = UserFoodOverridesCompanion Function({
  required String dishName,
  required int totalCalories,
  required int proteinGrams,
  required int carbsGrams,
  required int fatGrams,
  Value<int> rowid,
});
typedef $$UserFoodOverridesTableUpdateCompanionBuilder
    = UserFoodOverridesCompanion Function({
  Value<String> dishName,
  Value<int> totalCalories,
  Value<int> proteinGrams,
  Value<int> carbsGrams,
  Value<int> fatGrams,
  Value<int> rowid,
});

class $$UserFoodOverridesTableFilterComposer
    extends Composer<_$GymDatabase, $UserFoodOverridesTable> {
  $$UserFoodOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dishName => $composableBuilder(
      column: $table.dishName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCalories => $composableBuilder(
      column: $table.totalCalories, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnFilters(column));
}

class $$UserFoodOverridesTableOrderingComposer
    extends Composer<_$GymDatabase, $UserFoodOverridesTable> {
  $$UserFoodOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dishName => $composableBuilder(
      column: $table.dishName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCalories => $composableBuilder(
      column: $table.totalCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnOrderings(column));
}

class $$UserFoodOverridesTableAnnotationComposer
    extends Composer<_$GymDatabase, $UserFoodOverridesTable> {
  $$UserFoodOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dishName =>
      $composableBuilder(column: $table.dishName, builder: (column) => column);

  GeneratedColumn<int> get totalCalories => $composableBuilder(
      column: $table.totalCalories, builder: (column) => column);

  GeneratedColumn<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => column);

  GeneratedColumn<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => column);

  GeneratedColumn<int> get fatGrams =>
      $composableBuilder(column: $table.fatGrams, builder: (column) => column);
}

class $$UserFoodOverridesTableTableManager extends RootTableManager<
    _$GymDatabase,
    $UserFoodOverridesTable,
    UserFoodOverrideData,
    $$UserFoodOverridesTableFilterComposer,
    $$UserFoodOverridesTableOrderingComposer,
    $$UserFoodOverridesTableAnnotationComposer,
    $$UserFoodOverridesTableCreateCompanionBuilder,
    $$UserFoodOverridesTableUpdateCompanionBuilder,
    (
      UserFoodOverrideData,
      BaseReferences<_$GymDatabase, $UserFoodOverridesTable,
          UserFoodOverrideData>
    ),
    UserFoodOverrideData,
    PrefetchHooks Function()> {
  $$UserFoodOverridesTableTableManager(
      _$GymDatabase db, $UserFoodOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFoodOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFoodOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFoodOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dishName = const Value.absent(),
            Value<int> totalCalories = const Value.absent(),
            Value<int> proteinGrams = const Value.absent(),
            Value<int> carbsGrams = const Value.absent(),
            Value<int> fatGrams = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserFoodOverridesCompanion(
            dishName: dishName,
            totalCalories: totalCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dishName,
            required int totalCalories,
            required int proteinGrams,
            required int carbsGrams,
            required int fatGrams,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserFoodOverridesCompanion.insert(
            dishName: dishName,
            totalCalories: totalCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserFoodOverridesTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $UserFoodOverridesTable,
    UserFoodOverrideData,
    $$UserFoodOverridesTableFilterComposer,
    $$UserFoodOverridesTableOrderingComposer,
    $$UserFoodOverridesTableAnnotationComposer,
    $$UserFoodOverridesTableCreateCompanionBuilder,
    $$UserFoodOverridesTableUpdateCompanionBuilder,
    (
      UserFoodOverrideData,
      BaseReferences<_$GymDatabase, $UserFoodOverridesTable,
          UserFoodOverrideData>
    ),
    UserFoodOverrideData,
    PrefetchHooks Function()>;
typedef $$FoodCatalogTableCreateCompanionBuilder = FoodCatalogCompanion
    Function({
  Value<int> id,
  required String name,
  Value<double> gramsPerServing,
  Value<double> caloriesPerServing,
  Value<double> fatPerServing,
  Value<double> carbsPerServing,
  Value<double> proteinPerServing,
  Value<double> potassiumMg,
  Value<double> sodiumMg,
  Value<double> cholesterolMg,
  Value<double> fiberPerServing,
  Value<String> importBatchId,
  Value<bool> isFavorite,
});
typedef $$FoodCatalogTableUpdateCompanionBuilder = FoodCatalogCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<double> gramsPerServing,
  Value<double> caloriesPerServing,
  Value<double> fatPerServing,
  Value<double> carbsPerServing,
  Value<double> proteinPerServing,
  Value<double> potassiumMg,
  Value<double> sodiumMg,
  Value<double> cholesterolMg,
  Value<double> fiberPerServing,
  Value<String> importBatchId,
  Value<bool> isFavorite,
});

class $$FoodCatalogTableFilterComposer
    extends Composer<_$GymDatabase, $FoodCatalogTable> {
  $$FoodCatalogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gramsPerServing => $composableBuilder(
      column: $table.gramsPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesPerServing => $composableBuilder(
      column: $table.caloriesPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatPerServing => $composableBuilder(
      column: $table.fatPerServing, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsPerServing => $composableBuilder(
      column: $table.carbsPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinPerServing => $composableBuilder(
      column: $table.proteinPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get potassiumMg => $composableBuilder(
      column: $table.potassiumMg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sodiumMg => $composableBuilder(
      column: $table.sodiumMg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cholesterolMg => $composableBuilder(
      column: $table.cholesterolMg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fiberPerServing => $composableBuilder(
      column: $table.fiberPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importBatchId => $composableBuilder(
      column: $table.importBatchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));
}

class $$FoodCatalogTableOrderingComposer
    extends Composer<_$GymDatabase, $FoodCatalogTable> {
  $$FoodCatalogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gramsPerServing => $composableBuilder(
      column: $table.gramsPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesPerServing => $composableBuilder(
      column: $table.caloriesPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatPerServing => $composableBuilder(
      column: $table.fatPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsPerServing => $composableBuilder(
      column: $table.carbsPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinPerServing => $composableBuilder(
      column: $table.proteinPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
      column: $table.potassiumMg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
      column: $table.sodiumMg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cholesterolMg => $composableBuilder(
      column: $table.cholesterolMg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fiberPerServing => $composableBuilder(
      column: $table.fiberPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importBatchId => $composableBuilder(
      column: $table.importBatchId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));
}

class $$FoodCatalogTableAnnotationComposer
    extends Composer<_$GymDatabase, $FoodCatalogTable> {
  $$FoodCatalogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get gramsPerServing => $composableBuilder(
      column: $table.gramsPerServing, builder: (column) => column);

  GeneratedColumn<double> get caloriesPerServing => $composableBuilder(
      column: $table.caloriesPerServing, builder: (column) => column);

  GeneratedColumn<double> get fatPerServing => $composableBuilder(
      column: $table.fatPerServing, builder: (column) => column);

  GeneratedColumn<double> get carbsPerServing => $composableBuilder(
      column: $table.carbsPerServing, builder: (column) => column);

  GeneratedColumn<double> get proteinPerServing => $composableBuilder(
      column: $table.proteinPerServing, builder: (column) => column);

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
      column: $table.potassiumMg, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get cholesterolMg => $composableBuilder(
      column: $table.cholesterolMg, builder: (column) => column);

  GeneratedColumn<double> get fiberPerServing => $composableBuilder(
      column: $table.fiberPerServing, builder: (column) => column);

  GeneratedColumn<String> get importBatchId => $composableBuilder(
      column: $table.importBatchId, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);
}

class $$FoodCatalogTableTableManager extends RootTableManager<
    _$GymDatabase,
    $FoodCatalogTable,
    FoodCatalogData,
    $$FoodCatalogTableFilterComposer,
    $$FoodCatalogTableOrderingComposer,
    $$FoodCatalogTableAnnotationComposer,
    $$FoodCatalogTableCreateCompanionBuilder,
    $$FoodCatalogTableUpdateCompanionBuilder,
    (
      FoodCatalogData,
      BaseReferences<_$GymDatabase, $FoodCatalogTable, FoodCatalogData>
    ),
    FoodCatalogData,
    PrefetchHooks Function()> {
  $$FoodCatalogTableTableManager(_$GymDatabase db, $FoodCatalogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodCatalogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodCatalogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodCatalogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> gramsPerServing = const Value.absent(),
            Value<double> caloriesPerServing = const Value.absent(),
            Value<double> fatPerServing = const Value.absent(),
            Value<double> carbsPerServing = const Value.absent(),
            Value<double> proteinPerServing = const Value.absent(),
            Value<double> potassiumMg = const Value.absent(),
            Value<double> sodiumMg = const Value.absent(),
            Value<double> cholesterolMg = const Value.absent(),
            Value<double> fiberPerServing = const Value.absent(),
            Value<String> importBatchId = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
          }) =>
              FoodCatalogCompanion(
            id: id,
            name: name,
            gramsPerServing: gramsPerServing,
            caloriesPerServing: caloriesPerServing,
            fatPerServing: fatPerServing,
            carbsPerServing: carbsPerServing,
            proteinPerServing: proteinPerServing,
            potassiumMg: potassiumMg,
            sodiumMg: sodiumMg,
            cholesterolMg: cholesterolMg,
            fiberPerServing: fiberPerServing,
            importBatchId: importBatchId,
            isFavorite: isFavorite,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> gramsPerServing = const Value.absent(),
            Value<double> caloriesPerServing = const Value.absent(),
            Value<double> fatPerServing = const Value.absent(),
            Value<double> carbsPerServing = const Value.absent(),
            Value<double> proteinPerServing = const Value.absent(),
            Value<double> potassiumMg = const Value.absent(),
            Value<double> sodiumMg = const Value.absent(),
            Value<double> cholesterolMg = const Value.absent(),
            Value<double> fiberPerServing = const Value.absent(),
            Value<String> importBatchId = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
          }) =>
              FoodCatalogCompanion.insert(
            id: id,
            name: name,
            gramsPerServing: gramsPerServing,
            caloriesPerServing: caloriesPerServing,
            fatPerServing: fatPerServing,
            carbsPerServing: carbsPerServing,
            proteinPerServing: proteinPerServing,
            potassiumMg: potassiumMg,
            sodiumMg: sodiumMg,
            cholesterolMg: cholesterolMg,
            fiberPerServing: fiberPerServing,
            importBatchId: importBatchId,
            isFavorite: isFavorite,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FoodCatalogTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $FoodCatalogTable,
    FoodCatalogData,
    $$FoodCatalogTableFilterComposer,
    $$FoodCatalogTableOrderingComposer,
    $$FoodCatalogTableAnnotationComposer,
    $$FoodCatalogTableCreateCompanionBuilder,
    $$FoodCatalogTableUpdateCompanionBuilder,
    (
      FoodCatalogData,
      BaseReferences<_$GymDatabase, $FoodCatalogTable, FoodCatalogData>
    ),
    FoodCatalogData,
    PrefetchHooks Function()>;
typedef $$LoggedFoodsTableCreateCompanionBuilder = LoggedFoodsCompanion
    Function({
  Value<int> id,
  required int epochDay,
  required String name,
  required String mealTime,
  required double grams,
  required int calories,
  required int proteinGrams,
  required int carbsGrams,
  required int fatGrams,
  Value<int> fiberGrams,
  Value<int?> foodCatalogId,
  required int timestamp,
  Value<String> source,
  Value<int?> calorieMin,
  Value<int?> calorieMax,
  Value<double?> proteinMinGrams,
  Value<double?> proteinMaxGrams,
  Value<double?> carbsMinGrams,
  Value<double?> carbsMaxGrams,
  Value<double?> fatMinGrams,
  Value<double?> fatMaxGrams,
  Value<String?> analysisConfidence,
  Value<String?> analysisImageType,
  Value<String?> calculationSummary,
});
typedef $$LoggedFoodsTableUpdateCompanionBuilder = LoggedFoodsCompanion
    Function({
  Value<int> id,
  Value<int> epochDay,
  Value<String> name,
  Value<String> mealTime,
  Value<double> grams,
  Value<int> calories,
  Value<int> proteinGrams,
  Value<int> carbsGrams,
  Value<int> fatGrams,
  Value<int> fiberGrams,
  Value<int?> foodCatalogId,
  Value<int> timestamp,
  Value<String> source,
  Value<int?> calorieMin,
  Value<int?> calorieMax,
  Value<double?> proteinMinGrams,
  Value<double?> proteinMaxGrams,
  Value<double?> carbsMinGrams,
  Value<double?> carbsMaxGrams,
  Value<double?> fatMinGrams,
  Value<double?> fatMaxGrams,
  Value<String?> analysisConfidence,
  Value<String?> analysisImageType,
  Value<String?> calculationSummary,
});

class $$LoggedFoodsTableFilterComposer
    extends Composer<_$GymDatabase, $LoggedFoodsTable> {
  $$LoggedFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealTime => $composableBuilder(
      column: $table.mealTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get foodCatalogId => $composableBuilder(
      column: $table.foodCatalogId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calorieMin => $composableBuilder(
      column: $table.calorieMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calorieMax => $composableBuilder(
      column: $table.calorieMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinMinGrams => $composableBuilder(
      column: $table.proteinMinGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinMaxGrams => $composableBuilder(
      column: $table.proteinMaxGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsMinGrams => $composableBuilder(
      column: $table.carbsMinGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsMaxGrams => $composableBuilder(
      column: $table.carbsMaxGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatMinGrams => $composableBuilder(
      column: $table.fatMinGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatMaxGrams => $composableBuilder(
      column: $table.fatMaxGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisConfidence => $composableBuilder(
      column: $table.analysisConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisImageType => $composableBuilder(
      column: $table.analysisImageType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calculationSummary => $composableBuilder(
      column: $table.calculationSummary,
      builder: (column) => ColumnFilters(column));
}

class $$LoggedFoodsTableOrderingComposer
    extends Composer<_$GymDatabase, $LoggedFoodsTable> {
  $$LoggedFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get epochDay => $composableBuilder(
      column: $table.epochDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealTime => $composableBuilder(
      column: $table.mealTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fatGrams => $composableBuilder(
      column: $table.fatGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get foodCatalogId => $composableBuilder(
      column: $table.foodCatalogId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calorieMin => $composableBuilder(
      column: $table.calorieMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calorieMax => $composableBuilder(
      column: $table.calorieMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinMinGrams => $composableBuilder(
      column: $table.proteinMinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinMaxGrams => $composableBuilder(
      column: $table.proteinMaxGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsMinGrams => $composableBuilder(
      column: $table.carbsMinGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsMaxGrams => $composableBuilder(
      column: $table.carbsMaxGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatMinGrams => $composableBuilder(
      column: $table.fatMinGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatMaxGrams => $composableBuilder(
      column: $table.fatMaxGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisConfidence => $composableBuilder(
      column: $table.analysisConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisImageType => $composableBuilder(
      column: $table.analysisImageType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calculationSummary => $composableBuilder(
      column: $table.calculationSummary,
      builder: (column) => ColumnOrderings(column));
}

class $$LoggedFoodsTableAnnotationComposer
    extends Composer<_$GymDatabase, $LoggedFoodsTable> {
  $$LoggedFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get epochDay =>
      $composableBuilder(column: $table.epochDay, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mealTime =>
      $composableBuilder(column: $table.mealTime, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get proteinGrams => $composableBuilder(
      column: $table.proteinGrams, builder: (column) => column);

  GeneratedColumn<int> get carbsGrams => $composableBuilder(
      column: $table.carbsGrams, builder: (column) => column);

  GeneratedColumn<int> get fatGrams =>
      $composableBuilder(column: $table.fatGrams, builder: (column) => column);

  GeneratedColumn<int> get fiberGrams => $composableBuilder(
      column: $table.fiberGrams, builder: (column) => column);

  GeneratedColumn<int> get foodCatalogId => $composableBuilder(
      column: $table.foodCatalogId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get calorieMin => $composableBuilder(
      column: $table.calorieMin, builder: (column) => column);

  GeneratedColumn<int> get calorieMax => $composableBuilder(
      column: $table.calorieMax, builder: (column) => column);

  GeneratedColumn<double> get proteinMinGrams => $composableBuilder(
      column: $table.proteinMinGrams, builder: (column) => column);

  GeneratedColumn<double> get proteinMaxGrams => $composableBuilder(
      column: $table.proteinMaxGrams, builder: (column) => column);

  GeneratedColumn<double> get carbsMinGrams => $composableBuilder(
      column: $table.carbsMinGrams, builder: (column) => column);

  GeneratedColumn<double> get carbsMaxGrams => $composableBuilder(
      column: $table.carbsMaxGrams, builder: (column) => column);

  GeneratedColumn<double> get fatMinGrams => $composableBuilder(
      column: $table.fatMinGrams, builder: (column) => column);

  GeneratedColumn<double> get fatMaxGrams => $composableBuilder(
      column: $table.fatMaxGrams, builder: (column) => column);

  GeneratedColumn<String> get analysisConfidence => $composableBuilder(
      column: $table.analysisConfidence, builder: (column) => column);

  GeneratedColumn<String> get analysisImageType => $composableBuilder(
      column: $table.analysisImageType, builder: (column) => column);

  GeneratedColumn<String> get calculationSummary => $composableBuilder(
      column: $table.calculationSummary, builder: (column) => column);
}

class $$LoggedFoodsTableTableManager extends RootTableManager<
    _$GymDatabase,
    $LoggedFoodsTable,
    LoggedFoodData,
    $$LoggedFoodsTableFilterComposer,
    $$LoggedFoodsTableOrderingComposer,
    $$LoggedFoodsTableAnnotationComposer,
    $$LoggedFoodsTableCreateCompanionBuilder,
    $$LoggedFoodsTableUpdateCompanionBuilder,
    (
      LoggedFoodData,
      BaseReferences<_$GymDatabase, $LoggedFoodsTable, LoggedFoodData>
    ),
    LoggedFoodData,
    PrefetchHooks Function()> {
  $$LoggedFoodsTableTableManager(_$GymDatabase db, $LoggedFoodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoggedFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoggedFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoggedFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> epochDay = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> mealTime = const Value.absent(),
            Value<double> grams = const Value.absent(),
            Value<int> calories = const Value.absent(),
            Value<int> proteinGrams = const Value.absent(),
            Value<int> carbsGrams = const Value.absent(),
            Value<int> fatGrams = const Value.absent(),
            Value<int> fiberGrams = const Value.absent(),
            Value<int?> foodCatalogId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int?> calorieMin = const Value.absent(),
            Value<int?> calorieMax = const Value.absent(),
            Value<double?> proteinMinGrams = const Value.absent(),
            Value<double?> proteinMaxGrams = const Value.absent(),
            Value<double?> carbsMinGrams = const Value.absent(),
            Value<double?> carbsMaxGrams = const Value.absent(),
            Value<double?> fatMinGrams = const Value.absent(),
            Value<double?> fatMaxGrams = const Value.absent(),
            Value<String?> analysisConfidence = const Value.absent(),
            Value<String?> analysisImageType = const Value.absent(),
            Value<String?> calculationSummary = const Value.absent(),
          }) =>
              LoggedFoodsCompanion(
            id: id,
            epochDay: epochDay,
            name: name,
            mealTime: mealTime,
            grams: grams,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            fiberGrams: fiberGrams,
            foodCatalogId: foodCatalogId,
            timestamp: timestamp,
            source: source,
            calorieMin: calorieMin,
            calorieMax: calorieMax,
            proteinMinGrams: proteinMinGrams,
            proteinMaxGrams: proteinMaxGrams,
            carbsMinGrams: carbsMinGrams,
            carbsMaxGrams: carbsMaxGrams,
            fatMinGrams: fatMinGrams,
            fatMaxGrams: fatMaxGrams,
            analysisConfidence: analysisConfidence,
            analysisImageType: analysisImageType,
            calculationSummary: calculationSummary,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int epochDay,
            required String name,
            required String mealTime,
            required double grams,
            required int calories,
            required int proteinGrams,
            required int carbsGrams,
            required int fatGrams,
            Value<int> fiberGrams = const Value.absent(),
            Value<int?> foodCatalogId = const Value.absent(),
            required int timestamp,
            Value<String> source = const Value.absent(),
            Value<int?> calorieMin = const Value.absent(),
            Value<int?> calorieMax = const Value.absent(),
            Value<double?> proteinMinGrams = const Value.absent(),
            Value<double?> proteinMaxGrams = const Value.absent(),
            Value<double?> carbsMinGrams = const Value.absent(),
            Value<double?> carbsMaxGrams = const Value.absent(),
            Value<double?> fatMinGrams = const Value.absent(),
            Value<double?> fatMaxGrams = const Value.absent(),
            Value<String?> analysisConfidence = const Value.absent(),
            Value<String?> analysisImageType = const Value.absent(),
            Value<String?> calculationSummary = const Value.absent(),
          }) =>
              LoggedFoodsCompanion.insert(
            id: id,
            epochDay: epochDay,
            name: name,
            mealTime: mealTime,
            grams: grams,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            fiberGrams: fiberGrams,
            foodCatalogId: foodCatalogId,
            timestamp: timestamp,
            source: source,
            calorieMin: calorieMin,
            calorieMax: calorieMax,
            proteinMinGrams: proteinMinGrams,
            proteinMaxGrams: proteinMaxGrams,
            carbsMinGrams: carbsMinGrams,
            carbsMaxGrams: carbsMaxGrams,
            fatMinGrams: fatMinGrams,
            fatMaxGrams: fatMaxGrams,
            analysisConfidence: analysisConfidence,
            analysisImageType: analysisImageType,
            calculationSummary: calculationSummary,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoggedFoodsTableProcessedTableManager = ProcessedTableManager<
    _$GymDatabase,
    $LoggedFoodsTable,
    LoggedFoodData,
    $$LoggedFoodsTableFilterComposer,
    $$LoggedFoodsTableOrderingComposer,
    $$LoggedFoodsTableAnnotationComposer,
    $$LoggedFoodsTableCreateCompanionBuilder,
    $$LoggedFoodsTableUpdateCompanionBuilder,
    (
      LoggedFoodData,
      BaseReferences<_$GymDatabase, $LoggedFoodsTable, LoggedFoodData>
    ),
    LoggedFoodData,
    PrefetchHooks Function()>;

class $GymDatabaseManager {
  final _$GymDatabase _db;
  $GymDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$PersonalProfilesTableTableManager get personalProfiles =>
      $$PersonalProfilesTableTableManager(_db, _db.personalProfiles);
  $$WeightMeasurementsTableTableManager get weightMeasurements =>
      $$WeightMeasurementsTableTableManager(_db, _db.weightMeasurements);
  $$DailyNutritionsTableTableManager get dailyNutritions =>
      $$DailyNutritionsTableTableManager(_db, _db.dailyNutritions);
  $$WeeklyCheckInsTableTableManager get weeklyCheckIns =>
      $$WeeklyCheckInsTableTableManager(_db, _db.weeklyCheckIns);
  $$AdaptationDecisionsTableTableManager get adaptationDecisions =>
      $$AdaptationDecisionsTableTableManager(_db, _db.adaptationDecisions);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$WorkoutFeedbacksTableTableManager get workoutFeedbacks =>
      $$WorkoutFeedbacksTableTableManager(_db, _db.workoutFeedbacks);
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db, _db.mealTemplates);
  $$UserFoodOverridesTableTableManager get userFoodOverrides =>
      $$UserFoodOverridesTableTableManager(_db, _db.userFoodOverrides);
  $$FoodCatalogTableTableManager get foodCatalog =>
      $$FoodCatalogTableTableManager(_db, _db.foodCatalog);
  $$LoggedFoodsTableTableManager get loggedFoods =>
      $$LoggedFoodsTableTableManager(_db, _db.loggedFoods);
}
