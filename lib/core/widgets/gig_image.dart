import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/constants/app_images.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// The picture for a gig: its own image if it has one, otherwise the photo
/// of its category. If a web image fails to load (no data, bad link), it
/// falls back to the category photo instead of showing an error.
class GigImage extends StatelessWidget {
  const GigImage({super.key, required this.gig, this.fit = BoxFit.cover});

  final Gig gig;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      AppImages.forCategory(gig.category),
      fit: fit,
      // Decode at screen size, not full size: saves memory in long lists.
      cacheWidth: 800,
    );
    final url = gig.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}

/// A photo with a dark gradient, so white text on top stays readable.
class PhotoBackdrop extends StatelessWidget {
  const PhotoBackdrop({
    super.key,
    required this.asset,
    required this.child,
    this.darkness = 0.55,
    this.alignment = Alignment.center,
  });

  final String asset;
  final Widget child;

  /// 0 = no tint, 1 = black at the bottom.
  final double darkness;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: Image.asset(asset, fit: BoxFit.cover, alignment: alignment),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: darkness * 0.35),
                  Colors.black.withValues(alpha: darkness),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
