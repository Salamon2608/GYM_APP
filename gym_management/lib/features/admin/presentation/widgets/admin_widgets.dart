import 'package:flutter/material.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';

// ═══════════════════════════════════════════════════════════════
// GLASS CARD — Dark glass container with optional orange accent
// ═══════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? accentColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardLiftEffect(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 10),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: accentColor != null
            ? AdminTheme.glassDecorationWithAccent(accentColor)
            : AdminTheme.glassDecoration,
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANALYTICS CARD — Stat card with icon, value, label
// ═══════════════════════════════════════════════════════════════

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored accent bar at top
            Container(height: 3, color: color),
            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATUS BADGE — Colored label badge
// ═══════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: AdminTheme.badgeText.copyWith(color: color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD LIFT EFFECT — Tap animation wrapper
// ═══════════════════════════════════════════════════════════════

class CardLiftEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CardLiftEffect({super.key, required this.child, this.onTap});

  @override
  State<CardLiftEffect> createState() => _CardLiftEffectState();
}

class _CardLiftEffectState extends State<CardLiftEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AdminTheme.microDuration,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN SEARCH FIELD — Styled dark search bar
// ═══════════════════════════════════════════════════════════════

class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const AdminSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AdminTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AdminTheme.bodySmall,
          prefixIcon: const Icon(
            Icons.search,
            color: AdminTheme.textMuted,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORANGE GLOW FAB — Floating button with pulse glow
// ═══════════════════════════════════════════════════════════════

class OrangeGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const OrangeGlowButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<OrangeGlowButton> createState() => _OrangeGlowButtonState();
}

class _OrangeGlowButtonState extends State<OrangeGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.15,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AdminTheme.orange.withValues(alpha: _glowAnim.value),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AdminTheme.orange,
          foregroundColor: Colors.white,
          icon: Icon(widget.icon),
          label: Text(widget.label),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED GRADIENT BACKGROUND — Subtle orange glow bg
// ═══════════════════════════════════════════════════════════════

class AnimatedAdminBackground extends StatelessWidget {
  final Widget child;

  const AnimatedAdminBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: AdminTheme.scaffold, child: child);
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER — Title with optional action
// ═══════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AdminTheme.headingSmall),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AdminTheme.bodySmall.copyWith(color: AdminTheme.orange),
              ),
            ),
        ],
      ),
    );
  }
}
