// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseDefinition {

 String get id; String get sourceId; String get nameVi; ExperienceLevel get level; List<Equipment> get equipment; MovementPattern get movementPattern;@JsonKey(name: 'primaryMuscle') MuscleGroup get primaryMuscleGroup;@JsonKey(name: 'secondaryMuscles') List<MuscleGroup> get secondaryMuscleGroups; List<String> get instructionsVi; List<String> get substituteIds; String? get animationId;
/// Create a copy of ExerciseDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseDefinitionCopyWith<ExerciseDefinition> get copyWith => _$ExerciseDefinitionCopyWithImpl<ExerciseDefinition>(this as ExerciseDefinition, _$identity);

  /// Serializes this ExerciseDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.nameVi, nameVi) || other.nameVi == nameVi)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.equipment, equipment)&&(identical(other.movementPattern, movementPattern) || other.movementPattern == movementPattern)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other.secondaryMuscleGroups, secondaryMuscleGroups)&&const DeepCollectionEquality().equals(other.instructionsVi, instructionsVi)&&const DeepCollectionEquality().equals(other.substituteIds, substituteIds)&&(identical(other.animationId, animationId) || other.animationId == animationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceId,nameVi,level,const DeepCollectionEquality().hash(equipment),movementPattern,primaryMuscleGroup,const DeepCollectionEquality().hash(secondaryMuscleGroups),const DeepCollectionEquality().hash(instructionsVi),const DeepCollectionEquality().hash(substituteIds),animationId);

@override
String toString() {
  return 'ExerciseDefinition(id: $id, sourceId: $sourceId, nameVi: $nameVi, level: $level, equipment: $equipment, movementPattern: $movementPattern, primaryMuscleGroup: $primaryMuscleGroup, secondaryMuscleGroups: $secondaryMuscleGroups, instructionsVi: $instructionsVi, substituteIds: $substituteIds, animationId: $animationId)';
}


}

/// @nodoc
abstract mixin class $ExerciseDefinitionCopyWith<$Res>  {
  factory $ExerciseDefinitionCopyWith(ExerciseDefinition value, $Res Function(ExerciseDefinition) _then) = _$ExerciseDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String sourceId, String nameVi, ExperienceLevel level, List<Equipment> equipment, MovementPattern movementPattern,@JsonKey(name: 'primaryMuscle') MuscleGroup primaryMuscleGroup,@JsonKey(name: 'secondaryMuscles') List<MuscleGroup> secondaryMuscleGroups, List<String> instructionsVi, List<String> substituteIds, String? animationId
});




}
/// @nodoc
class _$ExerciseDefinitionCopyWithImpl<$Res>
    implements $ExerciseDefinitionCopyWith<$Res> {
  _$ExerciseDefinitionCopyWithImpl(this._self, this._then);

  final ExerciseDefinition _self;
  final $Res Function(ExerciseDefinition) _then;

/// Create a copy of ExerciseDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceId = null,Object? nameVi = null,Object? level = null,Object? equipment = null,Object? movementPattern = null,Object? primaryMuscleGroup = null,Object? secondaryMuscleGroups = null,Object? instructionsVi = null,Object? substituteIds = null,Object? animationId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,nameVi: null == nameVi ? _self.nameVi : nameVi // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExperienceLevel,equipment: null == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<Equipment>,movementPattern: null == movementPattern ? _self.movementPattern : movementPattern // ignore: cast_nullable_to_non_nullable
as MovementPattern,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,secondaryMuscleGroups: null == secondaryMuscleGroups ? _self.secondaryMuscleGroups : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,instructionsVi: null == instructionsVi ? _self.instructionsVi : instructionsVi // ignore: cast_nullable_to_non_nullable
as List<String>,substituteIds: null == substituteIds ? _self.substituteIds : substituteIds // ignore: cast_nullable_to_non_nullable
as List<String>,animationId: freezed == animationId ? _self.animationId : animationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseDefinition].
extension ExerciseDefinitionPatterns on ExerciseDefinition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseDefinition() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseDefinition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseDefinition() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourceId,  String nameVi,  ExperienceLevel level,  List<Equipment> equipment,  MovementPattern movementPattern, @JsonKey(name: 'primaryMuscle')  MuscleGroup primaryMuscleGroup, @JsonKey(name: 'secondaryMuscles')  List<MuscleGroup> secondaryMuscleGroups,  List<String> instructionsVi,  List<String> substituteIds,  String? animationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseDefinition() when $default != null:
return $default(_that.id,_that.sourceId,_that.nameVi,_that.level,_that.equipment,_that.movementPattern,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.instructionsVi,_that.substituteIds,_that.animationId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourceId,  String nameVi,  ExperienceLevel level,  List<Equipment> equipment,  MovementPattern movementPattern, @JsonKey(name: 'primaryMuscle')  MuscleGroup primaryMuscleGroup, @JsonKey(name: 'secondaryMuscles')  List<MuscleGroup> secondaryMuscleGroups,  List<String> instructionsVi,  List<String> substituteIds,  String? animationId)  $default,) {final _that = this;
switch (_that) {
case _ExerciseDefinition():
return $default(_that.id,_that.sourceId,_that.nameVi,_that.level,_that.equipment,_that.movementPattern,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.instructionsVi,_that.substituteIds,_that.animationId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourceId,  String nameVi,  ExperienceLevel level,  List<Equipment> equipment,  MovementPattern movementPattern, @JsonKey(name: 'primaryMuscle')  MuscleGroup primaryMuscleGroup, @JsonKey(name: 'secondaryMuscles')  List<MuscleGroup> secondaryMuscleGroups,  List<String> instructionsVi,  List<String> substituteIds,  String? animationId)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseDefinition() when $default != null:
return $default(_that.id,_that.sourceId,_that.nameVi,_that.level,_that.equipment,_that.movementPattern,_that.primaryMuscleGroup,_that.secondaryMuscleGroups,_that.instructionsVi,_that.substituteIds,_that.animationId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseDefinition implements ExerciseDefinition {
  const _ExerciseDefinition({required this.id, required this.sourceId, required this.nameVi, required this.level, required final  List<Equipment> equipment, required this.movementPattern, @JsonKey(name: 'primaryMuscle') required this.primaryMuscleGroup, @JsonKey(name: 'secondaryMuscles') final  List<MuscleGroup> secondaryMuscleGroups = const [], required final  List<String> instructionsVi, final  List<String> substituteIds = const [], this.animationId}): _equipment = equipment,_secondaryMuscleGroups = secondaryMuscleGroups,_instructionsVi = instructionsVi,_substituteIds = substituteIds;
  factory _ExerciseDefinition.fromJson(Map<String, dynamic> json) => _$ExerciseDefinitionFromJson(json);

@override final  String id;
@override final  String sourceId;
@override final  String nameVi;
@override final  ExperienceLevel level;
 final  List<Equipment> _equipment;
@override List<Equipment> get equipment {
  if (_equipment is EqualUnmodifiableListView) return _equipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equipment);
}

@override final  MovementPattern movementPattern;
@override@JsonKey(name: 'primaryMuscle') final  MuscleGroup primaryMuscleGroup;
 final  List<MuscleGroup> _secondaryMuscleGroups;
@override@JsonKey(name: 'secondaryMuscles') List<MuscleGroup> get secondaryMuscleGroups {
  if (_secondaryMuscleGroups is EqualUnmodifiableListView) return _secondaryMuscleGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryMuscleGroups);
}

 final  List<String> _instructionsVi;
@override List<String> get instructionsVi {
  if (_instructionsVi is EqualUnmodifiableListView) return _instructionsVi;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructionsVi);
}

 final  List<String> _substituteIds;
@override@JsonKey() List<String> get substituteIds {
  if (_substituteIds is EqualUnmodifiableListView) return _substituteIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_substituteIds);
}

@override final  String? animationId;

/// Create a copy of ExerciseDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseDefinitionCopyWith<_ExerciseDefinition> get copyWith => __$ExerciseDefinitionCopyWithImpl<_ExerciseDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.nameVi, nameVi) || other.nameVi == nameVi)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._equipment, _equipment)&&(identical(other.movementPattern, movementPattern) || other.movementPattern == movementPattern)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other._secondaryMuscleGroups, _secondaryMuscleGroups)&&const DeepCollectionEquality().equals(other._instructionsVi, _instructionsVi)&&const DeepCollectionEquality().equals(other._substituteIds, _substituteIds)&&(identical(other.animationId, animationId) || other.animationId == animationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceId,nameVi,level,const DeepCollectionEquality().hash(_equipment),movementPattern,primaryMuscleGroup,const DeepCollectionEquality().hash(_secondaryMuscleGroups),const DeepCollectionEquality().hash(_instructionsVi),const DeepCollectionEquality().hash(_substituteIds),animationId);

@override
String toString() {
  return 'ExerciseDefinition(id: $id, sourceId: $sourceId, nameVi: $nameVi, level: $level, equipment: $equipment, movementPattern: $movementPattern, primaryMuscleGroup: $primaryMuscleGroup, secondaryMuscleGroups: $secondaryMuscleGroups, instructionsVi: $instructionsVi, substituteIds: $substituteIds, animationId: $animationId)';
}


}

/// @nodoc
abstract mixin class _$ExerciseDefinitionCopyWith<$Res> implements $ExerciseDefinitionCopyWith<$Res> {
  factory _$ExerciseDefinitionCopyWith(_ExerciseDefinition value, $Res Function(_ExerciseDefinition) _then) = __$ExerciseDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourceId, String nameVi, ExperienceLevel level, List<Equipment> equipment, MovementPattern movementPattern,@JsonKey(name: 'primaryMuscle') MuscleGroup primaryMuscleGroup,@JsonKey(name: 'secondaryMuscles') List<MuscleGroup> secondaryMuscleGroups, List<String> instructionsVi, List<String> substituteIds, String? animationId
});




}
/// @nodoc
class __$ExerciseDefinitionCopyWithImpl<$Res>
    implements _$ExerciseDefinitionCopyWith<$Res> {
  __$ExerciseDefinitionCopyWithImpl(this._self, this._then);

  final _ExerciseDefinition _self;
  final $Res Function(_ExerciseDefinition) _then;

/// Create a copy of ExerciseDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceId = null,Object? nameVi = null,Object? level = null,Object? equipment = null,Object? movementPattern = null,Object? primaryMuscleGroup = null,Object? secondaryMuscleGroups = null,Object? instructionsVi = null,Object? substituteIds = null,Object? animationId = freezed,}) {
  return _then(_ExerciseDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,nameVi: null == nameVi ? _self.nameVi : nameVi // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExperienceLevel,equipment: null == equipment ? _self._equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<Equipment>,movementPattern: null == movementPattern ? _self.movementPattern : movementPattern // ignore: cast_nullable_to_non_nullable
as MovementPattern,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,secondaryMuscleGroups: null == secondaryMuscleGroups ? _self._secondaryMuscleGroups : secondaryMuscleGroups // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,instructionsVi: null == instructionsVi ? _self._instructionsVi : instructionsVi // ignore: cast_nullable_to_non_nullable
as List<String>,substituteIds: null == substituteIds ? _self._substituteIds : substituteIds // ignore: cast_nullable_to_non_nullable
as List<String>,animationId: freezed == animationId ? _self.animationId : animationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ExercisePrescription {

 String get exerciseId; int get sets;@JsonKey(name: 'repsMin') int? get minReps;@JsonKey(name: 'repsMax') int? get maxReps; int? get durationSeconds; int get restSeconds;
/// Create a copy of ExercisePrescription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExercisePrescriptionCopyWith<ExercisePrescription> get copyWith => _$ExercisePrescriptionCopyWithImpl<ExercisePrescription>(this as ExercisePrescription, _$identity);

  /// Serializes this ExercisePrescription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExercisePrescription&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.minReps, minReps) || other.minReps == minReps)&&(identical(other.maxReps, maxReps) || other.maxReps == maxReps)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,sets,minReps,maxReps,durationSeconds,restSeconds);

@override
String toString() {
  return 'ExercisePrescription(exerciseId: $exerciseId, sets: $sets, minReps: $minReps, maxReps: $maxReps, durationSeconds: $durationSeconds, restSeconds: $restSeconds)';
}


}

/// @nodoc
abstract mixin class $ExercisePrescriptionCopyWith<$Res>  {
  factory $ExercisePrescriptionCopyWith(ExercisePrescription value, $Res Function(ExercisePrescription) _then) = _$ExercisePrescriptionCopyWithImpl;
@useResult
$Res call({
 String exerciseId, int sets,@JsonKey(name: 'repsMin') int? minReps,@JsonKey(name: 'repsMax') int? maxReps, int? durationSeconds, int restSeconds
});




}
/// @nodoc
class _$ExercisePrescriptionCopyWithImpl<$Res>
    implements $ExercisePrescriptionCopyWith<$Res> {
  _$ExercisePrescriptionCopyWithImpl(this._self, this._then);

  final ExercisePrescription _self;
  final $Res Function(ExercisePrescription) _then;

/// Create a copy of ExercisePrescription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? sets = null,Object? minReps = freezed,Object? maxReps = freezed,Object? durationSeconds = freezed,Object? restSeconds = null,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,minReps: freezed == minReps ? _self.minReps : minReps // ignore: cast_nullable_to_non_nullable
as int?,maxReps: freezed == maxReps ? _self.maxReps : maxReps // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExercisePrescription].
extension ExercisePrescriptionPatterns on ExercisePrescription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExercisePrescription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExercisePrescription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExercisePrescription value)  $default,){
final _that = this;
switch (_that) {
case _ExercisePrescription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExercisePrescription value)?  $default,){
final _that = this;
switch (_that) {
case _ExercisePrescription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String exerciseId,  int sets, @JsonKey(name: 'repsMin')  int? minReps, @JsonKey(name: 'repsMax')  int? maxReps,  int? durationSeconds,  int restSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExercisePrescription() when $default != null:
return $default(_that.exerciseId,_that.sets,_that.minReps,_that.maxReps,_that.durationSeconds,_that.restSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String exerciseId,  int sets, @JsonKey(name: 'repsMin')  int? minReps, @JsonKey(name: 'repsMax')  int? maxReps,  int? durationSeconds,  int restSeconds)  $default,) {final _that = this;
switch (_that) {
case _ExercisePrescription():
return $default(_that.exerciseId,_that.sets,_that.minReps,_that.maxReps,_that.durationSeconds,_that.restSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String exerciseId,  int sets, @JsonKey(name: 'repsMin')  int? minReps, @JsonKey(name: 'repsMax')  int? maxReps,  int? durationSeconds,  int restSeconds)?  $default,) {final _that = this;
switch (_that) {
case _ExercisePrescription() when $default != null:
return $default(_that.exerciseId,_that.sets,_that.minReps,_that.maxReps,_that.durationSeconds,_that.restSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExercisePrescription implements ExercisePrescription {
  const _ExercisePrescription({required this.exerciseId, required this.sets, @JsonKey(name: 'repsMin') this.minReps, @JsonKey(name: 'repsMax') this.maxReps, this.durationSeconds, required this.restSeconds});
  factory _ExercisePrescription.fromJson(Map<String, dynamic> json) => _$ExercisePrescriptionFromJson(json);

@override final  String exerciseId;
@override final  int sets;
@override@JsonKey(name: 'repsMin') final  int? minReps;
@override@JsonKey(name: 'repsMax') final  int? maxReps;
@override final  int? durationSeconds;
@override final  int restSeconds;

/// Create a copy of ExercisePrescription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExercisePrescriptionCopyWith<_ExercisePrescription> get copyWith => __$ExercisePrescriptionCopyWithImpl<_ExercisePrescription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExercisePrescriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExercisePrescription&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.minReps, minReps) || other.minReps == minReps)&&(identical(other.maxReps, maxReps) || other.maxReps == maxReps)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,sets,minReps,maxReps,durationSeconds,restSeconds);

@override
String toString() {
  return 'ExercisePrescription(exerciseId: $exerciseId, sets: $sets, minReps: $minReps, maxReps: $maxReps, durationSeconds: $durationSeconds, restSeconds: $restSeconds)';
}


}

/// @nodoc
abstract mixin class _$ExercisePrescriptionCopyWith<$Res> implements $ExercisePrescriptionCopyWith<$Res> {
  factory _$ExercisePrescriptionCopyWith(_ExercisePrescription value, $Res Function(_ExercisePrescription) _then) = __$ExercisePrescriptionCopyWithImpl;
@override @useResult
$Res call({
 String exerciseId, int sets,@JsonKey(name: 'repsMin') int? minReps,@JsonKey(name: 'repsMax') int? maxReps, int? durationSeconds, int restSeconds
});




}
/// @nodoc
class __$ExercisePrescriptionCopyWithImpl<$Res>
    implements _$ExercisePrescriptionCopyWith<$Res> {
  __$ExercisePrescriptionCopyWithImpl(this._self, this._then);

  final _ExercisePrescription _self;
  final $Res Function(_ExercisePrescription) _then;

/// Create a copy of ExercisePrescription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? sets = null,Object? minReps = freezed,Object? maxReps = freezed,Object? durationSeconds = freezed,Object? restSeconds = null,}) {
  return _then(_ExercisePrescription(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,minReps: freezed == minReps ? _self.minReps : minReps // ignore: cast_nullable_to_non_nullable
as int?,maxReps: freezed == maxReps ? _self.maxReps : maxReps // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WorkoutTemplate {

 int get sequence; int get week; String get titleVi; String get focusVi; int get estimatedMinutes; int get restDaysAfter; List<ExercisePrescription> get exercises;
/// Create a copy of WorkoutTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutTemplateCopyWith<WorkoutTemplate> get copyWith => _$WorkoutTemplateCopyWithImpl<WorkoutTemplate>(this as WorkoutTemplate, _$identity);

  /// Serializes this WorkoutTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutTemplate&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.week, week) || other.week == week)&&(identical(other.titleVi, titleVi) || other.titleVi == titleVi)&&(identical(other.focusVi, focusVi) || other.focusVi == focusVi)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.restDaysAfter, restDaysAfter) || other.restDaysAfter == restDaysAfter)&&const DeepCollectionEquality().equals(other.exercises, exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sequence,week,titleVi,focusVi,estimatedMinutes,restDaysAfter,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'WorkoutTemplate(sequence: $sequence, week: $week, titleVi: $titleVi, focusVi: $focusVi, estimatedMinutes: $estimatedMinutes, restDaysAfter: $restDaysAfter, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $WorkoutTemplateCopyWith<$Res>  {
  factory $WorkoutTemplateCopyWith(WorkoutTemplate value, $Res Function(WorkoutTemplate) _then) = _$WorkoutTemplateCopyWithImpl;
@useResult
$Res call({
 int sequence, int week, String titleVi, String focusVi, int estimatedMinutes, int restDaysAfter, List<ExercisePrescription> exercises
});




}
/// @nodoc
class _$WorkoutTemplateCopyWithImpl<$Res>
    implements $WorkoutTemplateCopyWith<$Res> {
  _$WorkoutTemplateCopyWithImpl(this._self, this._then);

  final WorkoutTemplate _self;
  final $Res Function(WorkoutTemplate) _then;

/// Create a copy of WorkoutTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sequence = null,Object? week = null,Object? titleVi = null,Object? focusVi = null,Object? estimatedMinutes = null,Object? restDaysAfter = null,Object? exercises = null,}) {
  return _then(_self.copyWith(
sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,titleVi: null == titleVi ? _self.titleVi : titleVi // ignore: cast_nullable_to_non_nullable
as String,focusVi: null == focusVi ? _self.focusVi : focusVi // ignore: cast_nullable_to_non_nullable
as String,estimatedMinutes: null == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int,restDaysAfter: null == restDaysAfter ? _self.restDaysAfter : restDaysAfter // ignore: cast_nullable_to_non_nullable
as int,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExercisePrescription>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutTemplate].
extension WorkoutTemplatePatterns on WorkoutTemplate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutTemplate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutTemplate value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutTemplate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutTemplate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sequence,  int week,  String titleVi,  String focusVi,  int estimatedMinutes,  int restDaysAfter,  List<ExercisePrescription> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutTemplate() when $default != null:
return $default(_that.sequence,_that.week,_that.titleVi,_that.focusVi,_that.estimatedMinutes,_that.restDaysAfter,_that.exercises);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sequence,  int week,  String titleVi,  String focusVi,  int estimatedMinutes,  int restDaysAfter,  List<ExercisePrescription> exercises)  $default,) {final _that = this;
switch (_that) {
case _WorkoutTemplate():
return $default(_that.sequence,_that.week,_that.titleVi,_that.focusVi,_that.estimatedMinutes,_that.restDaysAfter,_that.exercises);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sequence,  int week,  String titleVi,  String focusVi,  int estimatedMinutes,  int restDaysAfter,  List<ExercisePrescription> exercises)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutTemplate() when $default != null:
return $default(_that.sequence,_that.week,_that.titleVi,_that.focusVi,_that.estimatedMinutes,_that.restDaysAfter,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutTemplate implements WorkoutTemplate {
  const _WorkoutTemplate({required this.sequence, required this.week, required this.titleVi, required this.focusVi, required this.estimatedMinutes, required this.restDaysAfter, required final  List<ExercisePrescription> exercises}): _exercises = exercises;
  factory _WorkoutTemplate.fromJson(Map<String, dynamic> json) => _$WorkoutTemplateFromJson(json);

@override final  int sequence;
@override final  int week;
@override final  String titleVi;
@override final  String focusVi;
@override final  int estimatedMinutes;
@override final  int restDaysAfter;
 final  List<ExercisePrescription> _exercises;
@override List<ExercisePrescription> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of WorkoutTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutTemplateCopyWith<_WorkoutTemplate> get copyWith => __$WorkoutTemplateCopyWithImpl<_WorkoutTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutTemplate&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.week, week) || other.week == week)&&(identical(other.titleVi, titleVi) || other.titleVi == titleVi)&&(identical(other.focusVi, focusVi) || other.focusVi == focusVi)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.restDaysAfter, restDaysAfter) || other.restDaysAfter == restDaysAfter)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sequence,week,titleVi,focusVi,estimatedMinutes,restDaysAfter,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'WorkoutTemplate(sequence: $sequence, week: $week, titleVi: $titleVi, focusVi: $focusVi, estimatedMinutes: $estimatedMinutes, restDaysAfter: $restDaysAfter, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$WorkoutTemplateCopyWith<$Res> implements $WorkoutTemplateCopyWith<$Res> {
  factory _$WorkoutTemplateCopyWith(_WorkoutTemplate value, $Res Function(_WorkoutTemplate) _then) = __$WorkoutTemplateCopyWithImpl;
@override @useResult
$Res call({
 int sequence, int week, String titleVi, String focusVi, int estimatedMinutes, int restDaysAfter, List<ExercisePrescription> exercises
});




}
/// @nodoc
class __$WorkoutTemplateCopyWithImpl<$Res>
    implements _$WorkoutTemplateCopyWith<$Res> {
  __$WorkoutTemplateCopyWithImpl(this._self, this._then);

  final _WorkoutTemplate _self;
  final $Res Function(_WorkoutTemplate) _then;

/// Create a copy of WorkoutTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sequence = null,Object? week = null,Object? titleVi = null,Object? focusVi = null,Object? estimatedMinutes = null,Object? restDaysAfter = null,Object? exercises = null,}) {
  return _then(_WorkoutTemplate(
sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,titleVi: null == titleVi ? _self.titleVi : titleVi // ignore: cast_nullable_to_non_nullable
as String,focusVi: null == focusVi ? _self.focusVi : focusVi // ignore: cast_nullable_to_non_nullable
as String,estimatedMinutes: null == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int,restDaysAfter: null == restDaysAfter ? _self.restDaysAfter : restDaysAfter // ignore: cast_nullable_to_non_nullable
as int,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExercisePrescription>,
  ));
}


}


/// @nodoc
mixin _$ProgramTemplate {

 String get id; FitnessGoal get goal; ExperienceLevel get level; EquipmentProfile get equipmentProfile; int get sessionsPerWeek; int get durationWeeks; List<WorkoutTemplate> get workouts;
/// Create a copy of ProgramTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramTemplateCopyWith<ProgramTemplate> get copyWith => _$ProgramTemplateCopyWithImpl<ProgramTemplate>(this as ProgramTemplate, _$identity);

  /// Serializes this ProgramTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgramTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.level, level) || other.level == level)&&(identical(other.equipmentProfile, equipmentProfile) || other.equipmentProfile == equipmentProfile)&&(identical(other.sessionsPerWeek, sessionsPerWeek) || other.sessionsPerWeek == sessionsPerWeek)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&const DeepCollectionEquality().equals(other.workouts, workouts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goal,level,equipmentProfile,sessionsPerWeek,durationWeeks,const DeepCollectionEquality().hash(workouts));

@override
String toString() {
  return 'ProgramTemplate(id: $id, goal: $goal, level: $level, equipmentProfile: $equipmentProfile, sessionsPerWeek: $sessionsPerWeek, durationWeeks: $durationWeeks, workouts: $workouts)';
}


}

/// @nodoc
abstract mixin class $ProgramTemplateCopyWith<$Res>  {
  factory $ProgramTemplateCopyWith(ProgramTemplate value, $Res Function(ProgramTemplate) _then) = _$ProgramTemplateCopyWithImpl;
@useResult
$Res call({
 String id, FitnessGoal goal, ExperienceLevel level, EquipmentProfile equipmentProfile, int sessionsPerWeek, int durationWeeks, List<WorkoutTemplate> workouts
});




}
/// @nodoc
class _$ProgramTemplateCopyWithImpl<$Res>
    implements $ProgramTemplateCopyWith<$Res> {
  _$ProgramTemplateCopyWithImpl(this._self, this._then);

  final ProgramTemplate _self;
  final $Res Function(ProgramTemplate) _then;

/// Create a copy of ProgramTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? goal = null,Object? level = null,Object? equipmentProfile = null,Object? sessionsPerWeek = null,Object? durationWeeks = null,Object? workouts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as FitnessGoal,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExperienceLevel,equipmentProfile: null == equipmentProfile ? _self.equipmentProfile : equipmentProfile // ignore: cast_nullable_to_non_nullable
as EquipmentProfile,sessionsPerWeek: null == sessionsPerWeek ? _self.sessionsPerWeek : sessionsPerWeek // ignore: cast_nullable_to_non_nullable
as int,durationWeeks: null == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int,workouts: null == workouts ? _self.workouts : workouts // ignore: cast_nullable_to_non_nullable
as List<WorkoutTemplate>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgramTemplate].
extension ProgramTemplatePatterns on ProgramTemplate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgramTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgramTemplate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgramTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ProgramTemplate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgramTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ProgramTemplate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  FitnessGoal goal,  ExperienceLevel level,  EquipmentProfile equipmentProfile,  int sessionsPerWeek,  int durationWeeks,  List<WorkoutTemplate> workouts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgramTemplate() when $default != null:
return $default(_that.id,_that.goal,_that.level,_that.equipmentProfile,_that.sessionsPerWeek,_that.durationWeeks,_that.workouts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  FitnessGoal goal,  ExperienceLevel level,  EquipmentProfile equipmentProfile,  int sessionsPerWeek,  int durationWeeks,  List<WorkoutTemplate> workouts)  $default,) {final _that = this;
switch (_that) {
case _ProgramTemplate():
return $default(_that.id,_that.goal,_that.level,_that.equipmentProfile,_that.sessionsPerWeek,_that.durationWeeks,_that.workouts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  FitnessGoal goal,  ExperienceLevel level,  EquipmentProfile equipmentProfile,  int sessionsPerWeek,  int durationWeeks,  List<WorkoutTemplate> workouts)?  $default,) {final _that = this;
switch (_that) {
case _ProgramTemplate() when $default != null:
return $default(_that.id,_that.goal,_that.level,_that.equipmentProfile,_that.sessionsPerWeek,_that.durationWeeks,_that.workouts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgramTemplate implements ProgramTemplate {
  const _ProgramTemplate({required this.id, required this.goal, required this.level, required this.equipmentProfile, required this.sessionsPerWeek, required this.durationWeeks, required final  List<WorkoutTemplate> workouts}): _workouts = workouts;
  factory _ProgramTemplate.fromJson(Map<String, dynamic> json) => _$ProgramTemplateFromJson(json);

@override final  String id;
@override final  FitnessGoal goal;
@override final  ExperienceLevel level;
@override final  EquipmentProfile equipmentProfile;
@override final  int sessionsPerWeek;
@override final  int durationWeeks;
 final  List<WorkoutTemplate> _workouts;
@override List<WorkoutTemplate> get workouts {
  if (_workouts is EqualUnmodifiableListView) return _workouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workouts);
}


/// Create a copy of ProgramTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramTemplateCopyWith<_ProgramTemplate> get copyWith => __$ProgramTemplateCopyWithImpl<_ProgramTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgramTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgramTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.level, level) || other.level == level)&&(identical(other.equipmentProfile, equipmentProfile) || other.equipmentProfile == equipmentProfile)&&(identical(other.sessionsPerWeek, sessionsPerWeek) || other.sessionsPerWeek == sessionsPerWeek)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&const DeepCollectionEquality().equals(other._workouts, _workouts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goal,level,equipmentProfile,sessionsPerWeek,durationWeeks,const DeepCollectionEquality().hash(_workouts));

@override
String toString() {
  return 'ProgramTemplate(id: $id, goal: $goal, level: $level, equipmentProfile: $equipmentProfile, sessionsPerWeek: $sessionsPerWeek, durationWeeks: $durationWeeks, workouts: $workouts)';
}


}

/// @nodoc
abstract mixin class _$ProgramTemplateCopyWith<$Res> implements $ProgramTemplateCopyWith<$Res> {
  factory _$ProgramTemplateCopyWith(_ProgramTemplate value, $Res Function(_ProgramTemplate) _then) = __$ProgramTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, FitnessGoal goal, ExperienceLevel level, EquipmentProfile equipmentProfile, int sessionsPerWeek, int durationWeeks, List<WorkoutTemplate> workouts
});




}
/// @nodoc
class __$ProgramTemplateCopyWithImpl<$Res>
    implements _$ProgramTemplateCopyWith<$Res> {
  __$ProgramTemplateCopyWithImpl(this._self, this._then);

  final _ProgramTemplate _self;
  final $Res Function(_ProgramTemplate) _then;

/// Create a copy of ProgramTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? goal = null,Object? level = null,Object? equipmentProfile = null,Object? sessionsPerWeek = null,Object? durationWeeks = null,Object? workouts = null,}) {
  return _then(_ProgramTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as FitnessGoal,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExperienceLevel,equipmentProfile: null == equipmentProfile ? _self.equipmentProfile : equipmentProfile // ignore: cast_nullable_to_non_nullable
as EquipmentProfile,sessionsPerWeek: null == sessionsPerWeek ? _self.sessionsPerWeek : sessionsPerWeek // ignore: cast_nullable_to_non_nullable
as int,durationWeeks: null == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int,workouts: null == workouts ? _self._workouts : workouts // ignore: cast_nullable_to_non_nullable
as List<WorkoutTemplate>,
  ));
}


}

// dart format on
