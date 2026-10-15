import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/screens/home_screen.dart';
import 'package:ecofone/screens/onboarding_screen.dart';
import 'package:ecofone/screens/splash_page.dart';
import 'package:ecofone/screens/stock_screen.dart';
import 'package:ecofone/screens/trade_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ecofone/firebase_options.dart';
import 'package:ecofone/state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boost Flutter image cache for zero-stutter scrolling and instant image rendering
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization: $e');
  }

  await AppState.instance.initServices();

  runApp(const EcoFoneApp());
}

class EcoFoneApp extends StatelessWidget {
  const EcoFoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoFone',
      scrollBehavior: const EcoSmoothScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: EcoColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EcoColors.forestGreen,
          primary: EcoColors.forestGreen,
          secondary: EcoColors.vibrantOrange,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.fixed,
          backgroundColor: EcoColors.darkEmerald,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.windows: SmoothPageTransitionsBuilder(),
            TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomePage(),
        '/stock': (context) => const StockScreen(),
        '/trade_in': (context) => const TradeInScreen(),
      },
    );
  }
}

/// Global Butter-Smooth Bouncing Elastic Scroll Behavior
class EcoSmoothScrollBehavior extends MaterialScrollBehavior {
  const EcoSmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.04, 0.0),
          ).animate(secondaryCurvedAnimation),
          child: child,
        ),
      ),
    );
  }
}