import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/shared/providers/connectivity_provider.dart';

class ConnectivityBannerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityBannerWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityBannerWrapper> createState() => _ConnectivityBannerWrapperState();
}

class _ConnectivityBannerWrapperState extends ConsumerState<ConnectivityBannerWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  bool _showSuccessBanner = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // Initial check: if already offline on load, show banner without animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialStatus = ref.read(connectionStatusProvider);
      if (initialStatus != ConnectionStatus.online) {
        _animController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ConnectionStatus>(connectionStatusProvider, (previous, next) {
      if (next != ConnectionStatus.online) {
        setState(() {
          _showSuccessBanner = false;
        });
        _animController.forward();
      } else if (previous != null && previous != ConnectionStatus.online) {
        // We transitioned back to online from an offline state
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showSuccessBanner = true;
            });
            _animController.forward();
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) {
                _animController.reverse().then((_) {
                  if (mounted) {
                    setState(() {
                      _showSuccessBanner = false;
                    });
                  }
                });
              }
            });
          }
        });
      }
    });

    final status = ref.watch(connectionStatusProvider);
    final isBannerVisible = (status != ConnectionStatus.online) || _showSuccessBanner;

    return Stack(
      children: [
        widget.child,
        if (isBannerVisible)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final topOffset = (MediaQuery.of(context).padding.top + 12) * _slideAnimation.value - (120 * (1 - _slideAnimation.value));
              return Positioned(
                top: topOffset,
                left: 16,
                right: 16,
                child: Opacity(
                  opacity: _slideAnimation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: _buildBannerContent(status),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerContent(ConnectionStatus status) {
    if (_showSuccessBanner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green[800]?.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.green.shade600, width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connection Restored',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isOffline = status == ConnectionStatus.offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOffline
            ? Colors.red[900]?.withValues(alpha: 0.95)
            : Colors.orange[900]?.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isOffline ? Colors.red.shade700 : Colors.orange.shade700,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOffline ? 'No Internet Connection' : 'Server Unreachable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOffline
                      ? 'Please check your network settings.'
                      : 'We are having trouble connecting to the server.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ref.read(connectionStatusProvider.notifier).checkServerRealtime();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
