import 'package:freezed_annotation/freezed_annotation.dart';

part 'advertisement_model.freezed.dart';
part 'advertisement_model.g.dart';

enum TargetSegment {
  @JsonValue('ALL')
  all,
  @JsonValue('EXPIRING')
  expiring,
  @JsonValue('INACTIVE')
  inactive,
  @JsonValue('PREMIUM')
  premium,
  @JsonValue('EXPIRED')
  expired,
}

enum RedirectType {
  @JsonValue('PT')
  pt,
  @JsonValue('RENEWAL')
  renewal,
  @JsonValue('UPGRADE')
  upgrade,
  @JsonValue('EXTERNAL')
  externalUrl,
}

@freezed
abstract class AdvertisementModel with _$AdvertisementModel {
  const AdvertisementModel._();

  const factory AdvertisementModel({
    required String id,
    required String title,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'target_segment') required TargetSegment targetSegment,
    @JsonKey(name: 'redirect_type') required RedirectType redirectType,
    @JsonKey(name: 'redirect_url') String? redirectUrl,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AdvertisementModel;

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) =>
      _$AdvertisementModelFromJson(json);
}

@freezed
abstract class AdInteractionModel with _$AdInteractionModel {
  const AdInteractionModel._();

  const factory AdInteractionModel({
    required String id,
    @JsonKey(name: 'ad_id') required String adId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'interaction_type')
    required String interactionType, // 'VIEW' or 'CLICK'
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AdInteractionModel;

  factory AdInteractionModel.fromJson(Map<String, dynamic> json) =>
      _$AdInteractionModelFromJson(json);
}
