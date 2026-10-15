import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/screens/explore_screen.dart';
import 'package:ecofone/screens/profile_screen.dart';
import 'package:ecofone/screens/stock_screen.dart';
import 'package:ecofone/screens/wishlist_screen.dart';
import 'package:ecofone/state/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _bgColor = EcoColors.background;

  int _navIndex = 0;
  late final PageController _pageController;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navIndex);
  }

 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_navIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _navIndex = index);
    _isProgrammaticScroll = true;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    ).then((_) {
      _isProgrammaticScroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (!_isProgrammaticScroll && _navIndex != index) {
            setState(() => _navIndex = index);
          }
        },
        children: [
          StockScreen(
            onProfileTap: () => _onTabTapped(3),
            onCartTap: () => _onTabTapped(2),
          ),
          ExploreScreen(
            onTradeInTap: () => Navigator.of(context).pushNamed('/trade_in'),
          ),
          WishlistScreen(
            onExploreTap: () => _onTabTapped(1),
          ),
          ProfileScreen(
            onTradeInTap: () => Navigator.of(context).pushNamed('/trade_in'),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---- Bottom nav (Butter-Smooth Luxury Dock with Frosted Glass & Haptics) ---
  Widget _buildBottomNav() {
    final items = [
      (Icons.phone_iphone_rounded, 'Stock'),
      (Icons.storefront_rounded, 'Stores'),
      (Icons.favorite_border_rounded, 'Wishlist'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    final wishlistCount = AppState.instance.wishlistedIds.length;

    return SafeArea(
      child: RepaintBoundary(
        child: Container(
          height: 62,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: EcoColors.darkEmerald.withOpacity(0.38),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F3B28),
                      Color(0xFF082619),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == _navIndex;
                    final (icon, label) = items[i];
                    final isWishlistTab = i == 2;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(i),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: selected ? 9 : 4,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [EcoColors.vibrantOrange, EcoColors.brightAmber],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: EcoColors.vibrantOrange.withOpacity(0.38),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: selected ? 1.08 : 1.0,
                                      duration: const Duration(milliseconds: 240),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        icon,
                                        color: selected ? Colors.white : Colors.white.withOpacity(0.68),
                                        size: 19,
                                      ),
                                    ),
                                    if (isWishlistTab && wishlistCount > 0 && !selected)
                                      Positioned(
                                        top: -3,
                                        right: -5,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: EcoColors.vibrantOrange,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 7,
                                            minHeight: 7,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  child: selected
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(width: 4.5),
                                            AnimatedOpacity(
                                              opacity: selected ? 1.0 : 0.0,
                                              duration: const Duration(milliseconds: 180),
                                              curve: Curves.easeIn,
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 52),
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}