import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecofone/core/widgets/connectivity_banner_overlay.dart';
import 'package:ecofone/services/network/connectivity_service.dart';

void main() {
  group('ConnectivityService & Network Error Tests', () {
    test('Initial status starts in online state during testing', () {
      final service = ConnectivityService.instance;
      expect(service.isOnline, isTrue);
      expect(service.isWeakConnection, isFalse);
      expect(service.status, equals(ConnectivityStatus.online));
    });

    test('Simulating offline state updates properties and stream', () async {
      final service = ConnectivityService.instance;
      final statuses = <ConnectivityStatus>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      service.setSimulatedStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);
      expect(service.isOnline, isFalse);
      expect(service.status, equals(ConnectivityStatus.offline));

      service.setSimulatedStatus(ConnectivityStatus.weak);
      await Future.delayed(Duration.zero);
      expect(service.isOnline, isTrue);
      expect(service.isWeakConnection, isTrue);
      expect(service.status, equals(ConnectivityStatus.weak));

      service.setSimulatedStatus(ConnectivityStatus.online);
      await Future.delayed(Duration.zero);
      expect(service.isOnline, isTrue);
      expect(service.isWeakConnection, isFalse);
      expect(service.status, equals(ConnectivityStatus.online));

      await sub.cancel();
      expect(statuses, contains(ConnectivityStatus.offline));
      expect(statuses, contains(ConnectivityStatus.weak));
      expect(statuses, contains(ConnectivityStatus.online));
    });

    testWidgets('ConnectivityBannerOverlay renders child and responds to offline state',
        (WidgetTester tester) async {
      final service = ConnectivityService.instance;
      service.setSimulatedStatus(ConnectivityStatus.online);

      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectivityBannerOverlay(
            child: Scaffold(
              body: Center(child: Text('Main Content Screen')),
            ),
          ),
        ),
      );

      expect(find.text('Main Content Screen'), findsOneWidget);
      expect(find.text('No Internet Connection'), findsNothing);

      // Trigger offline simulation
      service.setSimulatedStatus(ConnectivityStatus.offline);
      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Please connect to internet to browse stock & place orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Trigger restored online simulation
      service.setSimulatedStatus(ConnectivityStatus.online);
      await tester.pumpAndSettle();

      expect(find.text('Back Online'), findsOneWidget);
      expect(find.text('Connection restored • Syncing latest catalog'), findsOneWidget);
    });
  });
}
