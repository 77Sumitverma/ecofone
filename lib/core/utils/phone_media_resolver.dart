import 'package:flutter/material.dart';

/// Shared color-aware resolver for EcoFone's authentic studio phone renders and color swatches.
class PhoneMediaResolver {
  PhoneMediaResolver._();

  /// Resolves the exact studio PNG asset path matching [brand], [modelName], and [color].
  static String resolveColorAsset(String brand, String modelName, [String color = '']) {
    final m = modelName.toLowerCase().trim();
    final b = brand.toLowerCase().trim();
    final c = color.toLowerCase().trim();
    final combined = '$b $m';

    if (combined.contains('adapter') || combined.contains('charger') || combined.contains('power')) {
      return 'assets/phones/apple_20w_adapter.png';
    }

    // Samsung
    if (m.contains('s23') || m.contains('s24') || m.contains('s22') || m.contains('ultra')) {
      if (c.contains('green')) return 'assets/phones/galaxy_s23_ultra_green.png';
      if (c.contains('cream') || c.contains('gold') || c.contains('white')) {
        return 'assets/phones/galaxy_s23_ultra_cream.png';
      }
      if (c.contains('lavender') || c.contains('purple')) {
        return 'assets/phones/galaxy_s23_ultra_lavender.png';
      }
      return 'assets/phones/galaxy_s23_ultra.png';
    }
    if (m.contains('flip') || m.contains('fold')) {
      if (c.contains('graphite') || c.contains('black') || c.contains('gray') || c.contains('grey')) {
        return 'assets/phones/galaxy_z_flip_4_graphite.png';
      }
      if (c.contains('pink') || c.contains('gold') || c.contains('rose')) {
        return 'assets/phones/galaxy_z_flip_4_pink_gold.png';
      }
      if (c.contains('blue')) return 'assets/phones/galaxy_z_flip_4_blue.png';
      return 'assets/phones/galaxy_z_flip_4.png';
    }

    // Google Pixel
    if (m.contains('pixel 7') || m.contains('pixel 8')) {
      if (c.contains('obsidian') || c.contains('black')) {
        return 'assets/phones/pixel_7_pro_obsidian.png';
      }
      if (c.contains('snow') || c.contains('white') || c.contains('silver')) {
        return 'assets/phones/pixel_7_pro_snow.png';
      }
      return 'assets/phones/pixel_7_pro.png';
    }
    if (m.contains('pixel 6') || m.contains('pixel 7a') || b.contains('google') || m.contains('pixel')) {
      if (c.contains('chalk') || c.contains('white')) return 'assets/phones/pixel_6a_chalk.png';
      if (c.contains('sage') || c.contains('green')) return 'assets/phones/pixel_6a_sage.png';
      return 'assets/phones/pixel_6a.png';
    }

    // OnePlus (evaluated BEFORE Apple numeric checks so "OnePlus 12R" never matches "12")
    if (m.contains('12r') || m.contains('12 r') || m.contains('oneplus 12')) {
      if (c.contains('iron') || c.contains('gray') || c.contains('grey')) {
        return 'assets/phones/oneplus_12r_iron_gray.png';
      }
      return 'assets/phones/oneplus_12r.png';
    }
    if (m.contains('nord') || m.contains('ce 2')) {
      if (c.contains('black') || c.contains('dusk') || c.contains('gray') || c.contains('grey')) {
        return 'assets/phones/oneplus_nord_ce_2_lite_black_dusk.png';
      }
      return 'assets/phones/oneplus_nord_ce_2_lite.png';
    }
    if (m.contains('oneplus') || b.contains('oneplus')) {
      if (c.contains('black') || c.contains('titan') || c.contains('gray') || c.contains('grey')) {
        return 'assets/phones/oneplus_11_titan_black.png';
      }
      return 'assets/phones/oneplus_11.png';
    }

    // Xiaomi / Redmi
    if (m.contains('redmi') || m.contains('note 12') || b.contains('xiaomi')) {
      if (c.contains('blue') || c.contains('glacier')) return 'assets/phones/redmi_note_12_pro_blue.png';
      if (c.contains('purple') || c.contains('stardust')) {
        return 'assets/phones/redmi_note_12_pro_purple.png';
      }
      return 'assets/phones/redmi_note_12_pro.png';
    }

    // Apple iPhones
    if (combined.contains('iphone 14 pro') || (b.contains('apple') && m.contains('14 pro'))) {
      if (c.contains('purple')) return 'assets/phones/iphone_14_pro_deep_purple.png';
      if (c.contains('silver') || c.contains('white')) {
        return 'assets/phones/iphone_14_pro_silver.png';
      }
      if (c.contains('gold')) return 'assets/phones/iphone_14_pro_gold.png';
      return 'assets/phones/iphone_14_pro.png';
    }
    if (combined.contains('iphone 14') || (b.contains('apple') && m.contains('14'))) {
      if (c.contains('starlight') || c.contains('white')) return 'assets/phones/iphone_14_starlight.png';
      if (c.contains('blue')) return 'assets/phones/iphone_14_blue.png';
      if (c.contains('purple')) return 'assets/phones/iphone_14_purple.png';
      if (c.contains('yellow')) return 'assets/phones/iphone_14_yellow.png';
      if (c.contains('red')) return 'assets/phones/iphone_14_red.png';
      return 'assets/phones/iphone_14.png';
    }
    if (combined.contains('iphone 13') || (b.contains('apple') && m.contains('13'))) {
      if (c.contains('starlight') || c.contains('white')) return 'assets/phones/iphone_13_starlight.png';
      if (c.contains('pink')) return 'assets/phones/iphone_13_pink.png';
      if (c.contains('green')) return 'assets/phones/iphone_13_green.png';
      if (c == 'blue') return 'assets/phones/iphone_13_blue.png';
      return 'assets/phones/iphone_13.png';
    }
    if (combined.contains('iphone 12') || (b.contains('apple') && m.contains('12'))) {
      if (c.contains('black') || c.contains('midnight')) return 'assets/phones/iphone_12_black.png';
      if (c.contains('white') || c.contains('starlight')) return 'assets/phones/iphone_12_white.png';
      if (c.contains('green')) return 'assets/phones/iphone_12_green.png';
      if (c.contains('red')) return 'assets/phones/iphone_12_red.png';
      if (c.contains('purple')) return 'assets/phones/iphone_12_purple.png';
      return 'assets/phones/iphone_12.png';
    }
    if (combined.contains('iphone 11') || (b.contains('apple') && m.contains('11'))) {
      if (c.contains('white') || c.contains('starlight')) return 'assets/phones/iphone_11_white.png';
      if (c.contains('purple')) return 'assets/phones/iphone_11_purple.png';
      if (c.contains('green')) return 'assets/phones/iphone_11_green.png';
      if (c.contains('yellow')) return 'assets/phones/iphone_11_yellow.png';
      return 'assets/phones/iphone_11.png';
    }

    if (b.contains('samsung') || m.contains('galaxy')) return 'assets/phones/galaxy_s23_ultra.png';
    if (b.contains('apple') || m.contains('iphone')) return 'assets/phones/iphone_14_pro.png';

    return 'assets/phones/pixel_7_pro.png';
  }

  /// Resolves the image path/URL to display for the active [selectedColor],
  /// preserving server/custom [rawImageUrl] for [initialColor] while dynamically
  /// switching to the authentic color studio asset when the user selects another color.
  static String resolveEffectiveImageUrl({
    required String brand,
    required String modelName,
    required String selectedColor,
    required String initialColor,
    String? rawImageUrl,
  }) {
    final sameColor = selectedColor.trim().toLowerCase() == initialColor.trim().toLowerCase();
    if (sameColor && rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      final trimmed = rawImageUrl.trim();
      return trimmed.startsWith('assets/') ? trimmed.replaceAll('.jpg', '.png') : trimmed;
    }
    return resolveColorAsset(brand, modelName, selectedColor);
  }

  /// Official color list tailored to each smartphone model.
  static List<String> colorsForPhone(
    String brand,
    String modelName, {
    String? primaryColor,
  }) {
    final m = modelName.toLowerCase().trim();
    final b = brand.toLowerCase().trim();

    List<String> modelColors;
    if (m.contains('14 pro')) {
      modelColors = const ['Space Black', 'Deep Purple', 'Silver', 'Gold'];
    } else if ((b.contains('apple') || m.contains('iphone')) && m.contains('14')) {
      modelColors = const ['Midnight', 'Starlight', 'Blue', 'Purple', 'Yellow', 'Product Red'];
    } else if ((b.contains('apple') || m.contains('iphone')) && m.contains('13')) {
      modelColors = const ['Midnight Blue', 'Starlight', 'Blue', 'Pink', 'Green'];
    } else if ((b.contains('apple') || m.contains('iphone')) && m.contains('12')) {
      modelColors = const ['Pacific Blue', 'Black', 'White', 'Green', 'Product Red', 'Purple'];
    } else if ((b.contains('apple') || m.contains('iphone')) && m.contains('11')) {
      modelColors = const ['Midnight Black', 'White', 'Purple', 'Green', 'Yellow'];
    } else if (m.contains('s23') || m.contains('s24') || m.contains('ultra')) {
      modelColors = const ['Phantom Black', 'Cream', 'Green', 'Lavender'];
    } else if (m.contains('flip') || m.contains('fold')) {
      modelColors = const ['Bora Purple', 'Graphite', 'Pink Gold', 'Blue'];
    } else if (m.contains('12r') || m.contains('oneplus 12')) {
      modelColors = const ['Cool Blue', 'Iron Gray'];
    } else if (m.contains('nord')) {
      modelColors = const ['Blue Tide', 'Black Dusk'];
    } else if (m.contains('oneplus') || b.contains('oneplus')) {
      modelColors = const ['Eternal Green', 'Titan Black'];
    } else if (m.contains('pixel 7') || m.contains('pixel 8')) {
      modelColors = const ['Hazel & Gold', 'Obsidian', 'Snow'];
    } else if (m.contains('pixel 6') || b.contains('google') || m.contains('pixel')) {
      modelColors = const ['Charcoal Black', 'Chalk White', 'Sage'];
    } else if (m.contains('redmi') || m.contains('note 12') || b.contains('xiaomi')) {
      modelColors = const ['Onyx Black', 'Glacier Blue', 'Stardust Purple'];
    } else {
      modelColors = const ['Space Black', 'Silver'];
    }

    final result = <String>[];
    final seen = <String>{};
    if (primaryColor != null && primaryColor.trim().isNotEmpty) {
      final p = primaryColor.trim();
      result.add(p);
      seen.add(p.toLowerCase());
    }
    for (final c in modelColors) {
      final key = c.toLowerCase();
      // Treat Starlight White / Starlight as equivalent when inventory color is Starlight White
      if (key == 'starlight' && seen.contains('starlight white')) continue;
      if (seen.add(key)) {
        result.add(c);
      }
    }
    return result;
  }

  /// Representative metallic/glass swatch color dot for a color option name.
  static Color swatchColor(String colorName) {
    final c = colorName.toLowerCase();
    if (c.contains('deep purple') || c.contains('bora purple') || c.contains('stardust purple')) {
      return const Color(0xFF6B4E9B);
    }
    if (c.contains('lavender')) return const Color(0xFFD4C1EC);
    if (c.contains('purple')) return const Color(0xFF9E84CC);
    if (c.contains('pink gold') || c.contains('pink')) return const Color(0xFFE7B8AE);
    if (c.contains('gold')) return const Color(0xFFD6BE8A);
    if (c.contains('silver')) return const Color(0xFFD5D7DB);
    if (c.contains('starlight') || c.contains('chalk') || c.contains('snow') || c.contains('white')) {
      return const Color(0xFFF1EFEA);
    }
    if (c.contains('cream')) return const Color(0xFFF2E8D5);
    if (c.contains('yellow')) return const Color(0xFFF3D458);
    if (c.contains('red')) return const Color(0xFFD92632);
    if (c.contains('pacific blue')) return const Color(0xFF1D4E73);
    if (c.contains('midnight blue')) return const Color(0xFF1F2D3D);
    if (c.contains('cool blue') || c.contains('glacier blue') || c.contains('tide')) {
      return const Color(0xFF5CA4D6);
    }
    if (c.contains('blue')) return const Color(0xFF3E7CB1);
    if (c.contains('eternal green') || c.contains('botanic')) return const Color(0xFF2D4F40);
    if (c.contains('hazel')) return const Color(0xFF6C766D);
    if (c.contains('sage')) return const Color(0xFF8FA98E);
    if (c.contains('green')) return const Color(0xFF3C6E52);
    if (c.contains('iron gray') || c.contains('graphite')) return const Color(0xFF4B4E54);
    if (c.contains('black') || c.contains('midnight') || c.contains('obsidian') || c.contains('charcoal') || c.contains('onyx') || c.contains('dusk')) {
      return const Color(0xFF1E2024);
    }
    return const Color(0xFF64748B);
  }
}
