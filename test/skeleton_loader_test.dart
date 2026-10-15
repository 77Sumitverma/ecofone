import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecofone/core/widgets/skeleton_loader.dart';

void main() {
  group('EcoSkeletonShimmer and Skeleton Preset Tests', () {
    testWidgets('EcoSkeletonShimmer renders child elements cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EcoSkeletonShimmer(
              child: EcoSkeletonBox(width: 100, height: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EcoSkeletonBox), findsOneWidget);
    });

    testWidgets('PhoneCardSkeleton renders placeholder bones', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: PhoneCardSkeleton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PhoneCardSkeleton), findsOneWidget);
      expect(find.byType(EcoSkeletonBox), findsWidgets);
      expect(find.byType(EcoSkeletonCircle), findsWidgets);
    });

    testWidgets('StockGridSkeletonView renders correct count of cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                StockGridSkeletonView(itemCount: 4),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PhoneCardSkeleton), findsNWidgets(4));
    });

    testWidgets('WishlistCardSkeleton and StoreCardSkeleton render properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WishlistCardSkeleton(),
                StoreCardSkeleton(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WishlistCardSkeleton), findsOneWidget);
      expect(find.byType(StoreCardSkeleton), findsOneWidget);
    });

    testWidgets('PhoneDetailSkeletonView renders complete screen skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PhoneDetailSkeletonView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PhoneDetailSkeletonView), findsOneWidget);
    });

    testWidgets('WishlistCardSkeleton and StoreCardSkeleton render properly in slivers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const WishlistCardSkeleton(),
                    childCount: 2,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const StoreCardSkeleton(),
                    childCount: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WishlistCardSkeleton), findsNWidgets(2));
      expect(find.byType(StoreCardSkeleton), findsNWidgets(2));
    });
  });
}
