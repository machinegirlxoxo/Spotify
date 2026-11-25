import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/cover_color.dart';
import '/models/thumbnail.dart';

/// Spotify-style header gradient that follows the dominant color of the cover.
class CoverGradientBackground extends StatefulWidget {
  const CoverGradientBackground(
      {super.key, required this.imageUrl, this.height = 460});
  final String imageUrl;
  final double height;

  @override
  State<CoverGradientBackground> createState() =>
      _CoverGradientBackgroundState();
}

class _CoverGradientBackgroundState extends State<CoverGradientBackground> {
  Color? _color;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CoverGradientBackground old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) _load();
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    final c = await CoverColor.fromUrl(url);
    if (mounted && url == widget.imageUrl) setState(() => _color = c);
  }

  @override
  Widget build(BuildContext context) {
    final canvas = Theme.of(context).canvasColor;
    final fallback = Color.lerp(canvas, Colors.white, 0.12)!;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: fallback, end: _color ?? fallback),
      duration: const Duration(milliseconds: 600),
      builder: (context, c, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c!, Color.lerp(c, canvas, 0.65)!, canvas],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Centered rounded cover with soft shadow (Spotify header).
class CoverArtHeader extends StatelessWidget {
  const CoverArtHeader({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final side = (w * 0.62).clamp(160.0, 280.0);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      child: Center(
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 30, offset: Offset(0, 12))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: Thumbnail(imageUrl).extraHigh,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: Colors.black26),
            ),
          ),
        ),
      ),
    );
  }
}
