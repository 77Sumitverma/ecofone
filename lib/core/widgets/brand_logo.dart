import 'package:flutter/material.dart';
import 'package:ecofone/core/theme/app_theme.dart';

/// Reusable Brand Logo & Typography for EcoFone
class EcoFoneHeaderLogo extends StatelessWidget {
  final double emblemSize;
  final double titleSize;
  final double subtitleSize;
  final String? customSubtitle;
  final bool showLivePulse;
  final int? stockCount;

  const EcoFoneHeaderLogo({
    super.key,
    this.emblemSize = 42.0,
    this.titleSize = 22.0,
    this.subtitleSize = 10.5,
    this.customSubtitle,
    this.showLivePulse = false,
    this.stockCount,
  });

  @override
  Widget build(BuildContext context) {
    if (customSubtitle == null && !showLivePulse) {
      return Image.asset(
        'assets/logo/ecofone_horizontal_logo.png',
        height: emblemSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/logo/logo_transparent.png',
          height: emblemSize,
          fit: BoxFit.contain,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/ecofone_horizontal_logo.png',
          height: (emblemSize * 0.72).clamp(24.0, 36.0),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/logo/logo_transparent.png',
            height: (emblemSize * 0.72).clamp(24.0, 36.0),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 2),
        if (showLivePulse && stockCount != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.5,
                height: 5.5,
                decoration: BoxDecoration(
                  color: EcoColors.mintGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EcoColors.mintGreen.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Luxury within reach • $stockCount in stock',
                  style: TextStyle(
                    color: EcoColors.luxuryBronze,
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        else if (customSubtitle != null)
          Text(
            customSubtitle!,
            style: TextStyle(
              color: EcoColors.luxuryBronze,
              fontSize: subtitleSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// Large Centered Brand Logo for Welcome Gate, Modals & About Sheets
class EcoFoneFullLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const EcoFoneFullLogo({
    super.key,
    this.size = 90.0,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/ecofone_horizontal_logo.png',
      height: size.clamp(36.0, 90.0),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/logo/logo_transparent.png',
        height: size.clamp(36.0, 90.0),
        fit: BoxFit.contain,
      ),
    );
  }
}
