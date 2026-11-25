import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracts a gradient-friendly color from a cover image (cached per url).
class CoverColor {
  static final Map<String, Color> _cache = {};

  static ImageProvider _provider(String url) {
    if (url.startsWith('/') || url.startsWith('file:')) {
      return FileImage(File(url.replaceFirst('file://', '')));
    }
    return CachedNetworkImageProvider(url);
  }

  static Future<Color?> fromUrl(String url) async {
    if (url.isEmpty) return null;
    final cached = _cache[url];
    if (cached != null) return cached;
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        _provider(url),
        size: const Size(120, 120),
        maximumColorCount: 16,
      );
      final picked = generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          generator.mutedColor?.color;
      if (picked == null) return null;
      final hsl = HSLColor.fromColor(picked);
      // keep it dark enough that white text stays readable
      final color = hsl
          .withLightness(hsl.lightness.clamp(0.22, 0.36))
          .withSaturation(hsl.saturation.clamp(0.0, 0.7))
          .toColor();
      _cache[url] = color;
      return color;
    } catch (_) {
      return null;
    }
  }
}
