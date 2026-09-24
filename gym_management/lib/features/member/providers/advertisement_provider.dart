import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/advertisement_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/membership_provider.dart';
import 'package:gym_management/features/shared/data/models/advertisement_model.dart';

final advertisementRepositoryProvider =
    Provider.autoDispose<AdvertisementRepository>((ref) {
      final authState = ref.watch(authProvider);
      return AdvertisementRepository(gymId: authState.gymId);
    });

final activeAdvertisementsProvider =
    FutureProvider.autoDispose<List<AdvertisementModel>>((ref) async {
      final authState = ref.watch(authProvider);
      final userId = authState.user?.id;

      if (userId != null) {
        // Watch membership status to trigger rebuilds when it changes
        ref.watch(membershipStatusProvider(userId));
      }

      final repo = ref.watch(advertisementRepositoryProvider);
      return repo.getActiveAds();
    });
