import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ecofone/core/theme/app_theme.dart';

/// Connection health status enumeration
enum ConnectivityStatus {
  online,
  weak,
  offline,
}

/// ConnectivityService provides real-time, zero-dependency network reachability
/// monitoring for the EcoFone mobile and desktop application.
///
/// Features:
/// - Real-time network detection via high-reliability DNS lookup with instant fallback
/// - Weak connection detection (latency threshold > 2200ms)
/// - Periodic polling with smart throttle (every 4 seconds)
/// - Instant `checkNow()` trigger for manual retry buttons
/// - Safe across Android, iOS, Windows, macOS, Linux, and Web
/// - Global ChangeNotifier so any UI element can reactively listen
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();

  ConnectivityService._internal() {
    _init();
  }

  bool _isOnline = true;
  bool _isWeakConnection = false;
  bool _isChecking = false;
  DateTime? _lastChecked;
  Timer? _pollingTimer;

  bool get isOnline => _isOnline;
  bool get isWeakConnection => _isWeakConnection;
  bool get isChecking => _isChecking;
  DateTime? get lastChecked => _lastChecked;

  ConnectivityStatus get status {
    if (!_isOnline) return ConnectivityStatus.offline;
    if (_isWeakConnection) return ConnectivityStatus.weak;
    return ConnectivityStatus.online;
  }

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get onStatusChanged => _statusController.stream;

  bool get isTesting {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  void _init() {
    if (isTesting) {
      _isOnline = true;
      return;
    }

    // Initial immediate reachability check
    checkNow();

    // Periodic heartbeat check every 4 seconds
    startPolling();
  }

  void startPolling({Duration interval = const Duration(seconds: 4)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      _checkReachability();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// For testing environments to simulate network states
  void setSimulatedStatus(ConnectivityStatus newStatus) {
    _isOnline = newStatus != ConnectivityStatus.offline;
    _isWeakConnection = newStatus == ConnectivityStatus.weak;
    _statusController.add(newStatus);
    notifyListeners();
  }

  /// Manually trigger an immediate reachability check (e.g. when user taps 'Retry')
  Future<bool> checkNow() async {
    return await _checkReachability(forceNotify: true);
  }

  Future<bool> _checkReachability({bool forceNotify = false}) async {
    if (_isChecking) return _isOnline;
    _isChecking = true;

    final stopwatch = Stopwatch()..start();
    bool reachable = false;

    if (kIsWeb) {
      // In web browser, navigator.onLine or default reachable
      reachable = true;
      _isWeakConnection = false;
    } else {
      try {
        // Step 1: Primary DNS lookup with 2.5 second aggressive timeout
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(milliseconds: 2500));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          reachable = true;
        }
      } on SocketException catch (_) {
        reachable = false;
      } on TimeoutException catch (_) {
        // Step 2: Fallback check on timeout to 1.1.1.1 (Cloudflare)
        try {
          final fallbackResult = await InternetAddress.lookup('one.one.one.one')
              .timeout(const Duration(milliseconds: 2000));
          if (fallbackResult.isNotEmpty && fallbackResult[0].rawAddress.isNotEmpty) {
            reachable = true;
          }
        } catch (_) {
          reachable = false;
        }
      } catch (_) {
        reachable = false;
      }
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    _lastChecked = DateTime.now();

    final prevOnline = _isOnline;
    final prevWeak = _isWeakConnection;

    _isOnline = reachable;
    // Mark weak if lookup took > 2000ms
    _isWeakConnection = reachable && elapsedMs > 2000;
    _isChecking = false;

    if (forceNotify || prevOnline != _isOnline || prevWeak != _isWeakConnection) {
      _statusController.add(status);
      notifyListeners();
    }

    return _isOnline;
  }

  /// Displays a standardized EcoFone offline or connection error SnackBar
  static void showNetworkErrorSnackBar(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? 'No Internet Connection • Please connect to the internet';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF991B1B), // Crimson Dark
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: EcoColors.brightAmber,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Displays a subtle weak connection notification SnackBar
  static void showWeakConnectionSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD97706), // Amber 600
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
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
              child: Text(
                'Weak Internet Connection • Response may take longer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _statusController.close();
    super.dispose();
  }
}
