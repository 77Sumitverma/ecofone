import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ecofone/services/network/connectivity_service.dart';

/// ConnectivityBannerOverlay wraps the entire application widget tree,
/// displaying an elegant, animated top floating notification whenever
/// the user's internet connection is lost or weak, and confirming when reconnected.
class ConnectivityBannerOverlay extends StatefulWidget {
  final Widget child;

  const ConnectivityBannerOverlay({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBannerOverlay> createState() => _ConnectivityBannerOverlayState();
}

class _ConnectivityBannerOverlayState extends State<ConnectivityBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  ConnectivityStatus _lastStatus = ConnectivityStatus.online;
  bool _showRestoredBanner = false;
  Timer? _restoredDismissTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    ConnectivityService.instance.addListener(_handleConnectivityChange);
    _lastStatus = ConnectivityService.instance.status;

    if (_lastStatus != ConnectivityStatus.online) {
      _animController.value = 1.0;
    }
  }

  void _handleConnectivityChange() {
    final current = ConnectivityService.instance.status;

    if (current == ConnectivityStatus.offline || current == ConnectivityStatus.weak) {
      _restoredDismissTimer?.cancel();
      _showRestoredBanner = false;
      _animController.forward();
    } else if (current == ConnectivityStatus.online) {
      if (_lastStatus == ConnectivityStatus.offline || _lastStatus == ConnectivityStatus.weak) {
        // Transition to green "Back Online" message
        setState(() {
          _showRestoredBanner = true;
        });
        _restoredDismissTimer?.cancel();
        _restoredDismissTimer = Timer(const Duration(milliseconds: 2600), () {
          if (mounted) {
            _animController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showRestoredBanner = false;
                });
              }
            });
          }
        });
      } else {
        _animController.reverse();
      }
    }

    _lastStatus = current;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_handleConnectivityChange);
    _restoredDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final service = ConnectivityService.instance;
    final isOffline = !service.isOnline;
    final isWeak = service.isWeakConnection;
    final isChecking = service.isChecking;

    return Stack(
      children: [
        // The underlying primary application tree
        widget.child,

        // Floating Sticky Connectivity Pill
        if (isOffline || isWeak || _showRestoredBanner || _animController.value > 0)
          Positioned(
            top: topPadding > 0 ? topPadding + 6 : 10,
            left: 14,
            right: 14,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  type: MaterialType.transparency,
                  child: _buildBannerCard(isOffline, isWeak, isChecking),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerCard(bool isOffline, bool isWeak, bool isChecking) {
    if (_showRestoredBanner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFF065F46)], // Forest green to deep emerald
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Back Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Connection restored • Syncing latest catalog',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 20),
          ],
        ),
      );
    }

    if (isWeak && !isOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)], // Amber to Warm Brown
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.network_check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Weak Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Responses may be slower than usual',
                    style: TextStyle(
                      color: Color(0xFFFEF3C7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Offline / Disconnected State
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFF991B1B)], // Vivid Red to Deep Maroon
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF991B1B).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Pulse Warning Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Please connect to internet to browse stock & place orders',
                  style: TextStyle(
                    color: Color(0xFFFEE2E2),
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Retry button with loading state
          InkWell(
            onTap: isChecking
                ? null
                : () async {
                    await ConnectivityService.instance.checkNow();
                  },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
