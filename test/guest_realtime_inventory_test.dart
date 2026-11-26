import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecofone/screens/stock_screen.dart';
import 'package:ecofone/state/app_state.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.getInstance();
    AppState.instance.storage = storage;
    AppState.instance.logout();
  });

  test('Guest or logged out user sees all inventory and allInventory getter matches liveInventory', () async {
    final state = AppState.instance;
    expect(state.isLoggedIn, isFalse);
    expect(state.liveInventory.isNotEmpty, isTrue);
    expect(state.allInventory.length, equals(state.liveInventory.length));

    // When refreshInventory is invoked without storeId, it does not default to a single store
    await state.refreshInventory();
    expect(state.liveInventory.isNotEmpty, isTrue);
    expect(state.allInventory.length, greaterThanOrEqualTo(11));
  });

  testWidgets('StockScreen hides internal live inventory banner and supports pull-to-refresh', (tester) async {
    AppState.instance.logout();
    expect(AppState.instance.isLoggedIn, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: StockScreen(),
      ),
    );

    // Pump frames to render widget without waiting forever on repeating banner timer
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify internal Live Inventory status banner & manual refresh icon are NOT shown
    expect(find.textContaining('All Live Inventory'), findsNothing);
    expect(find.text('LIVE POS'), findsNothing);
    expect(find.textContaining('Guest Mode'), findsNothing);
    expect(find.byIcon(Icons.sync_rounded), findsNothing);

    // Verify RefreshIndicator is attached for pull-to-refresh stock updates
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    // Verify phone items from all inventory are displayed
    expect(find.textContaining('iPhone'), findsWidgets);
  });
}
