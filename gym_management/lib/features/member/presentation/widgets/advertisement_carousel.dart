import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/member/providers/advertisement_provider.dart';
import 'package:gym_management/features/shared/data/models/advertisement_model.dart';

class AdvertisementCarousel extends ConsumerStatefulWidget {
  const AdvertisementCarousel({super.key});

  @override
  ConsumerState<AdvertisementCarousel> createState() =>
      _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends ConsumerState<AdvertisementCarousel> {
  final PageController _pageController = PageController();
  final Set<String> _viewedAds = {};
  Timer? _timer;
  int _currentPage = 0;
  bool _isAutoScrolling = false;

  void _startTimer(int totalAds) {
    _isAutoScrolling = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % totalAds;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onAdVisible(AdvertisementModel ad) {
    if (!_viewedAds.contains(ad.id)) {
      _viewedAds.add(ad.id);
      ref.read(advertisementRepositoryProvider).logInteraction(ad.id, 'VIEW');
    }
  }

  Future<void> _onAdTap(AdvertisementModel ad) async {
    // Log CLICK
    ref.read(advertisementRepositoryProvider).logInteraction(ad.id, 'CLICK');

    // Handle Redirect
    switch (ad.redirectType) {
      case RedirectType.pt:
        context.push(AppRoutes.memberTrainerRating); // Placeholder
        break;
      case RedirectType.renewal:
      case RedirectType.upgrade:
        context.push(AppRoutes.memberMembership);
        break;
      case RedirectType.externalUrl:
        if (ad.redirectUrl != null && ad.redirectUrl!.isNotEmpty) {
          final uri = Uri.parse(ad.redirectUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch external URL')),
              );
            }
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(activeAdvertisementsProvider);

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();

        if (ads.length > 1 && !_isAutoScrolling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(ads.length);
          });
        }

        return SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: ads.length,
            onPageChanged: (index) {
              _currentPage = index;
            },
            itemBuilder: (context, index) {
              final ad = ads[index];
              return VisibilityDetector(
                key: Key('ad_${ad.id}'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.5) {
                    _onAdVisible(ad);
                  }
                },
                child: GestureDetector(
                  onTap: () => _onAdTap(ad),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            AppConstants.getFullImageUrl(ad.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                ad.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
