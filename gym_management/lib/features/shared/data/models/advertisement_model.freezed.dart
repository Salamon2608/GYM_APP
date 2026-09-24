// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advertisement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdvertisementModel {

 String get id; String get title;@JsonKey(name: 'image_url') String get imageUrl;@JsonKey(name: 'target_segment') TargetSegment get targetSegment;@JsonKey(name: 'redirect_type') RedirectType get redirectType;@JsonKey(name: 'redirect_url') String? get redirectUrl;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime get endDate;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of AdvertisementModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvertisementModelCopyWith<AdvertisementModel> get copyWith => _$AdvertisementModelCopyWithImpl<AdvertisementModel>(this as AdvertisementModel, _$identity);

  /// Serializes this AdvertisementModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvertisementModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.targetSegment, targetSegment) || other.targetSegment == targetSegment)&&(identical(other.redirectType, redirectType) || other.redirectType == redirectType)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,targetSegment,redirectType,redirectUrl,startDate,endDate,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'AdvertisementModel(id: $id, title: $title, imageUrl: $imageUrl, targetSegment: $targetSegment, redirectType: $redirectType, redirectUrl: $redirectUrl, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AdvertisementModelCopyWith<$Res>  {
  factory $AdvertisementModelCopyWith(AdvertisementModel value, $Res Function(AdvertisementModel) _then) = _$AdvertisementModelCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'target_segment') TargetSegment targetSegment,@JsonKey(name: 'redirect_type') RedirectType redirectType,@JsonKey(name: 'redirect_url') String? redirectUrl,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$AdvertisementModelCopyWithImpl<$Res>
    implements $AdvertisementModelCopyWith<$Res> {
  _$AdvertisementModelCopyWithImpl(this._self, this._then);

  final AdvertisementModel _self;
  final $Res Function(AdvertisementModel) _then;

/// Create a copy of AdvertisementModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? targetSegment = null,Object? redirectType = null,Object? redirectUrl = freezed,Object? startDate = null,Object? endDate = null,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,targetSegment: null == targetSegment ? _self.targetSegment : targetSegment // ignore: cast_nullable_to_non_nullable
as TargetSegment,redirectType: null == redirectType ? _self.redirectType : redirectType // ignore: cast_nullable_to_non_nullable
as RedirectType,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdvertisementModel].
extension AdvertisementModelPatterns on AdvertisementModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdvertisementModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdvertisementModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdvertisementModel value)  $default,){
final _that = this;
switch (_that) {
case _AdvertisementModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdvertisementModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdvertisementModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'target_segment')  TargetSegment targetSegment, @JsonKey(name: 'redirect_type')  RedirectType redirectType, @JsonKey(name: 'redirect_url')  String? redirectUrl, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdvertisementModel() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.targetSegment,_that.redirectType,_that.redirectUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'target_segment')  TargetSegment targetSegment, @JsonKey(name: 'redirect_type')  RedirectType redirectType, @JsonKey(name: 'redirect_url')  String? redirectUrl, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AdvertisementModel():
return $default(_that.id,_that.title,_that.imageUrl,_that.targetSegment,_that.redirectType,_that.redirectUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'target_segment')  TargetSegment targetSegment, @JsonKey(name: 'redirect_type')  RedirectType redirectType, @JsonKey(name: 'redirect_url')  String? redirectUrl, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'end_date')  DateTime endDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AdvertisementModel() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.targetSegment,_that.redirectType,_that.redirectUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdvertisementModel extends AdvertisementModel {
  const _AdvertisementModel({required this.id, required this.title, @JsonKey(name: 'image_url') required this.imageUrl, @JsonKey(name: 'target_segment') required this.targetSegment, @JsonKey(name: 'redirect_type') required this.redirectType, @JsonKey(name: 'redirect_url') this.redirectUrl, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') required this.endDate, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _AdvertisementModel.fromJson(Map<String, dynamic> json) => _$AdvertisementModelFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(name: 'image_url') final  String imageUrl;
@override@JsonKey(name: 'target_segment') final  TargetSegment targetSegment;
@override@JsonKey(name: 'redirect_type') final  RedirectType redirectType;
@override@JsonKey(name: 'redirect_url') final  String? redirectUrl;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime endDate;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of AdvertisementModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdvertisementModelCopyWith<_AdvertisementModel> get copyWith => __$AdvertisementModelCopyWithImpl<_AdvertisementModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdvertisementModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdvertisementModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.targetSegment, targetSegment) || other.targetSegment == targetSegment)&&(identical(other.redirectType, redirectType) || other.redirectType == redirectType)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,targetSegment,redirectType,redirectUrl,startDate,endDate,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'AdvertisementModel(id: $id, title: $title, imageUrl: $imageUrl, targetSegment: $targetSegment, redirectType: $redirectType, redirectUrl: $redirectUrl, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AdvertisementModelCopyWith<$Res> implements $AdvertisementModelCopyWith<$Res> {
  factory _$AdvertisementModelCopyWith(_AdvertisementModel value, $Res Function(_AdvertisementModel) _then) = __$AdvertisementModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'target_segment') TargetSegment targetSegment,@JsonKey(name: 'redirect_type') RedirectType redirectType,@JsonKey(name: 'redirect_url') String? redirectUrl,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$AdvertisementModelCopyWithImpl<$Res>
    implements _$AdvertisementModelCopyWith<$Res> {
  __$AdvertisementModelCopyWithImpl(this._self, this._then);

  final _AdvertisementModel _self;
  final $Res Function(_AdvertisementModel) _then;

/// Create a copy of AdvertisementModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? targetSegment = null,Object? redirectType = null,Object? redirectUrl = freezed,Object? startDate = null,Object? endDate = null,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AdvertisementModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,targetSegment: null == targetSegment ? _self.targetSegment : targetSegment // ignore: cast_nullable_to_non_nullable
as TargetSegment,redirectType: null == redirectType ? _self.redirectType : redirectType // ignore: cast_nullable_to_non_nullable
as RedirectType,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AdInteractionModel {

 String get id;@JsonKey(name: 'ad_id') String get adId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'interaction_type') String get interactionType;// 'VIEW' or 'CLICK'
@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of AdInteractionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdInteractionModelCopyWith<AdInteractionModel> get copyWith => _$AdInteractionModelCopyWithImpl<AdInteractionModel>(this as AdInteractionModel, _$identity);

  /// Serializes this AdInteractionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdInteractionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.adId, adId) || other.adId == adId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.interactionType, interactionType) || other.interactionType == interactionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adId,userId,interactionType,createdAt);

@override
String toString() {
  return 'AdInteractionModel(id: $id, adId: $adId, userId: $userId, interactionType: $interactionType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdInteractionModelCopyWith<$Res>  {
  factory $AdInteractionModelCopyWith(AdInteractionModel value, $Res Function(AdInteractionModel) _then) = _$AdInteractionModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'ad_id') String adId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'interaction_type') String interactionType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$AdInteractionModelCopyWithImpl<$Res>
    implements $AdInteractionModelCopyWith<$Res> {
  _$AdInteractionModelCopyWithImpl(this._self, this._then);

  final AdInteractionModel _self;
  final $Res Function(AdInteractionModel) _then;

/// Create a copy of AdInteractionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? adId = null,Object? userId = null,Object? interactionType = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adId: null == adId ? _self.adId : adId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,interactionType: null == interactionType ? _self.interactionType : interactionType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdInteractionModel].
extension AdInteractionModelPatterns on AdInteractionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdInteractionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdInteractionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdInteractionModel value)  $default,){
final _that = this;
switch (_that) {
case _AdInteractionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdInteractionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdInteractionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ad_id')  String adId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'interaction_type')  String interactionType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdInteractionModel() when $default != null:
return $default(_that.id,_that.adId,_that.userId,_that.interactionType,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'ad_id')  String adId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'interaction_type')  String interactionType, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdInteractionModel():
return $default(_that.id,_that.adId,_that.userId,_that.interactionType,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'ad_id')  String adId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'interaction_type')  String interactionType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdInteractionModel() when $default != null:
return $default(_that.id,_that.adId,_that.userId,_that.interactionType,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdInteractionModel extends AdInteractionModel {
  const _AdInteractionModel({required this.id, @JsonKey(name: 'ad_id') required this.adId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'interaction_type') required this.interactionType, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _AdInteractionModel.fromJson(Map<String, dynamic> json) => _$AdInteractionModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'ad_id') final  String adId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'interaction_type') final  String interactionType;
// 'VIEW' or 'CLICK'
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of AdInteractionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdInteractionModelCopyWith<_AdInteractionModel> get copyWith => __$AdInteractionModelCopyWithImpl<_AdInteractionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdInteractionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdInteractionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.adId, adId) || other.adId == adId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.interactionType, interactionType) || other.interactionType == interactionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adId,userId,interactionType,createdAt);

@override
String toString() {
  return 'AdInteractionModel(id: $id, adId: $adId, userId: $userId, interactionType: $interactionType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdInteractionModelCopyWith<$Res> implements $AdInteractionModelCopyWith<$Res> {
  factory _$AdInteractionModelCopyWith(_AdInteractionModel value, $Res Function(_AdInteractionModel) _then) = __$AdInteractionModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'ad_id') String adId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'interaction_type') String interactionType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$AdInteractionModelCopyWithImpl<$Res>
    implements _$AdInteractionModelCopyWith<$Res> {
  __$AdInteractionModelCopyWithImpl(this._self, this._then);

  final _AdInteractionModel _self;
  final $Res Function(_AdInteractionModel) _then;

/// Create a copy of AdInteractionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? adId = null,Object? userId = null,Object? interactionType = null,Object? createdAt = freezed,}) {
  return _then(_AdInteractionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adId: null == adId ? _self.adId : adId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,interactionType: null == interactionType ? _self.interactionType : interactionType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
