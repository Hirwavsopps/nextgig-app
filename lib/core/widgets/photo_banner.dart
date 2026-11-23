import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/widgets/gig_image.dart';

/// A rounded, darkened photo with white text on top. Used as the banner on
/// the login and sign-up screens and as the hero card on the home feed.
///
/// Give a [title] (and optional [subtitle]) for a simple caption, or a
/// [child] for custom content; with a [child] the banner takes the child's
/// height unless [height] is set.
class PhotoBanner extends StatelessWidget {
  const PhotoBanner({
    super.key,
    required this.asset,
    this.title,
    this.subtitle,
    this.child,
    this.height,
    this.alignment = Alignment.center,
  });

  final String asset;
  final String? title;
  final String? subtitle;
  final Widget? child;
  final double? height;

  /// Which part of the photo stays visible when it is cropped.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const white = Colors.white;

    final content =
        child ??
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: SizedBox(
        height: height ?? (child == null ? 160 : null),
        width: double.infinity,
        child: PhotoBackdrop(
          asset: asset,
          darkness: 0.65,
          alignment: alignment,
          child: Padding(padding: const EdgeInsets.all(16), child: content),
        ),
      ),
    );
  }
}
