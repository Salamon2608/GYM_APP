import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/membership_provider.dart';

/// A widget that gates gym-specific features behind active membership.
/// Shows a lock overlay with a "Renew" button for expired/no-membership users.
class FeatureGate extends ConsumerWidget {
  final Widget child;
  final String featureLabel;

  const FeatureGate({
    super.key,
    required this.child,
    this.featureLabel = 'This feature',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) return child;

    final status = ref.watch(membershipStatusProvider(userId));

    if (status == MembershipStatus.active ||
        status == MembershipStatus.loading) {
      return child;
    }

    // Expired / No membership → show gated overlay
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Blurred content underneath
        IgnorePointer(child: Opacity(opacity: 0.3, child: child)),
        // Lock overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.textTheme.bodyMedium?.color,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  '$featureLabel requires\nan active membership',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.memberMembership),
                  icon: const Icon(Icons.card_membership, size: 16),
                  label: const Text('Get Membership'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Expiry warning banner shown at top of dashboard
class ExpiryBanner extends ConsumerWidget {
  const ExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) return const SizedBox.shrink();

    final status = ref.watch(membershipStatusProvider(userId));

    if (status == MembershipStatus.active ||
        status == MembershipStatus.loading) {
      return const SizedBox.shrink();
    }

    final isExpired = status == MembershipStatus.expired;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [
                  AppTheme.errorColor.withValues(alpha: 0.2),
                  isDark ? AppTheme.cardDark : AppTheme.cardLight,
                ]
              : [
                  AppTheme.accentColor.withValues(alpha: 0.2),
                  isDark ? AppTheme.cardDark : AppTheme.cardLight,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpired
              ? AppTheme.errorColor.withValues(alpha: 0.4)
              : AppTheme.accentColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isExpired ? AppTheme.errorColor : AppTheme.accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Membership Expired' : 'No Active Membership',
                  style: TextStyle(
                    color: isExpired
                        ? AppTheme.errorColor
                        : AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Basic workout features available. Renew for full access.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.memberMembership),
            child: const Text(
              'Renew',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
