// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advertisement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdvertisementModel _$AdvertisementModelFromJson(Map<String, dynamic> json) =>
    _AdvertisementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      targetSegment: $enumDecode(
        _$TargetSegmentEnumMap,
        json['target_segment'],
      ),
      redirectType: $enumDecode(_$RedirectTypeEnumMap, json['redirect_type']),
      redirectUrl: json['redirect_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AdvertisementModelToJson(_AdvertisementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image_url': instance.imageUrl,
      'target_segment': _$TargetSegmentEnumMap[instance.targetSegment]!,
      'redirect_type': _$RedirectTypeEnumMap[instance.redirectType]!,
      'redirect_url': instance.redirectUrl,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$TargetSegmentEnumMap = {
  TargetSegment.all: 'ALL',
  TargetSegment.expiring: 'EXPIRING',
  TargetSegment.inactive: 'INACTIVE',
  TargetSegment.premium: 'PREMIUM',
  TargetSegment.expired: 'EXPIRED',
};

const _$RedirectTypeEnumMap = {
  RedirectType.pt: 'PT',
  RedirectType.renewal: 'RENEWAL',
  RedirectType.upgrade: 'UPGRADE',
  RedirectType.externalUrl: 'EXTERNAL',
};

_AdInteractionModel _$AdInteractionModelFromJson(Map<String, dynamic> json) =>
    _AdInteractionModel(
      id: json['id'] as String,
      adId: json['ad_id'] as String,
      userId: json['user_id'] as String,
      interactionType: json['interaction_type'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AdInteractionModelToJson(_AdInteractionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ad_id': instance.adId,
      'user_id': instance.userId,
      'interaction_type': instance.interactionType,
      'created_at': instance.createdAt?.toIso8601String(),
    };
