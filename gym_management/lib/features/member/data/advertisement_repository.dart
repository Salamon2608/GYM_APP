import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/features/shared/data/models/advertisement_model.dart';

class AdvertisementRepository {
  final String? gymId;

  AdvertisementRepository({
    this.gymId,
  });

  /// Fetches active ads matching user's segment and gym
  Future<List<AdvertisementModel>> getActiveAds() async {
    try {
      final response = await ApiService.get('/member/ads');
      final list = response.data as List;
      final List<AdvertisementModel> ads = [];
      for (var item in list) {
        try {
          ads.add(AdvertisementModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return ads;
    } catch (e) {
      return [];
    }
  }

  /// Logs a 'VIEW' or 'CLICK' interaction
  Future<void> logInteraction(String adId, String interactionType) async {
    try {
      await ApiService.post('/member/ads/$adId/interact', data: {
        'interaction_type': interactionType,
      });
    } catch (_) {}
  }
}
