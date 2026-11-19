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

  testWidgets('StockScreen displays all inventory and real-time inventory status for logged-out / guest user', (tester) async {
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

    // Verify Real-Time Inventory status header is visible
    expect(find.textContaining('All Live Inventory'), findsOneWidget);
    expect(find.text('LIVE POS'), findsOneWidget);
    expect(find.textContaining('Guest Mode'), findsOneWidget);

    // Verify phone items from all inventory are displayed
    expect(find.textContaining('iPhone'), findsWidgets);
  });
}
