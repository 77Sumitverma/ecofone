import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/state/app_state.dart';

/// Luxury Store Directions & Route Navigator Bottom Sheet
class StoreDirectionsSheet extends StatefulWidget {
  final EcoStore store;

  const StoreDirectionsSheet({super.key, required this.store});

  static Future<void> show(BuildContext context, EcoStore store) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreDirectionsSheet(store: store),
    );
  }

  @override
  State<StoreDirectionsSheet> createState() => _StoreDirectionsSheetState();
}

class _StoreDirectionsSheetState extends State<StoreDirectionsSheet>
    with SingleTickerProviderStateMixin {
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(String url) async {
    setState(() => _isLaunching = true);
    final uri = Uri.parse(url);
    try {
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {
          launched = false;
        }
      }

      if (!launched) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Map link copied to clipboard! Paste in browser to open route.'),
              backgroundColor: _copper,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[DirectionsSheet] Launch error: $e');
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Map link copied to clipboard!'),
            backgroundColor: _forestGreen,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  String _estimateDriveTime(double distanceKm) {
    if (distanceKm <= 0.5) return '~2 mins drive • 6 mins walk';
    final driveMins = (distanceKm * 2.5).round().clamp(3, 120);
    final walkMins = (distanceKm * 12).round().clamp(5, 300);
    if (driveMins < 60) {
      return '~$driveMins mins drive • $walkMins mins walk';
    } else {
      final hours = (driveMins / 60).toStringAsFixed(1);
      return '~$hours hrs drive';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final distance = AppState.instance.getLiveDistanceFrom(store);
    final userLoc = AppState.instance.userLocation;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Pill
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row: Store Name, Distance, Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _forestGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: _forestGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                store.name,
                                style: const TextStyle(
                                  color: _forestGreen,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.city,
                          style: TextStyle(
                            color: _forestGreen.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _copper,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _copper.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '📍 $distance km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Interactive Route Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_forestGreen, EcoColors.darkEmerald],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _forestGreen.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Start point (GPS)
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: EcoColors.brightAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userLoc.shortDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 14),
                        ),
                        const Icon(Icons.storefront_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            store.area,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, color: EcoColors.brightAmber, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _estimateDriveTime(distance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            store.timings.split('(').first.trim(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Address & Landmark Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EcoColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_rounded, color: _copper, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.address,
                            style: TextStyle(
                              color: _forestGreen.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (store.landmark.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flag_circle_rounded, color: _softGreen, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Landmark: ${store.landmark}',
                              style: TextStyle(
                                color: _forestGreen.withOpacity(0.75),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (store.metroStation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.directions_subway_rounded, color: _forestGreen, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Metro: ${store.metroStation}',
                              style: TextStyle(
                                color: _forestGreen.withOpacity(0.75),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Primary Action: Open in Google Maps with Ultra-Sleek Circular Loader
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLaunching ? null : () => _launchMaps(store.googleMapsUrl),
                  icon: _isLaunching
                      ? const EcoCircularProgressLoader(
                          size: 18,
                          color: Colors.white,
                          strokeWidth: 2.2,
                        )
                      : const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(
                    _isLaunching ? 'Opening Google Maps...' : 'Start Route in Google Maps',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary Actions Row: Call Store & Copy Link
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: store.phone));
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📞 Store Contact Copied: ${store.phone}'),
                            backgroundColor: _copper,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, size: 15, color: _forestGreen),
                      label: Text(
                        'Call: ${store.phone}',
                        style: const TextStyle(fontSize: 11.5, color: _forestGreen, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _forestGreen.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: store.googleMapsUrl));
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 Google Maps link copied to clipboard!'),
                            backgroundColor: _forestGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 15, color: _copper),
                      label: const Text(
                        'Share Map Link',
                        style: TextStyle(fontSize: 11.5, color: _copper, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _copper.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
