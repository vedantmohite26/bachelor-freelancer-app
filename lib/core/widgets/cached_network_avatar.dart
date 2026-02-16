import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A reusable avatar widget that caches network images for performance.
///
/// Replaces raw `CircleAvatar(backgroundImage: NetworkImage(...))` patterns
/// with disk+memory caching, a shimmer loading indicator, and graceful
/// fallback to an icon or text initial when no image is available.
class CachedNetworkAvatar extends StatelessWidget {
  /// URL of the profile image. If null or empty, the fallback is shown.
  final String? imageUrl;

  /// Radius of the avatar circle. Defaults to 20.
  final double radius;

  /// Background color when no image is loaded.
  final Color? backgroundColor;

  /// Single-character text to display when no image is available.
  /// Takes priority over [fallbackIcon] if both are provided.
  final String? fallbackText;

  /// Text style for the fallback initial letter.
  final TextStyle? fallbackTextStyle;

  /// Icon to display when no image and no fallback text is available.
  final IconData fallbackIcon;

  /// Color of the fallback icon.
  final Color? fallbackIconColor;

  /// Optional border around the avatar (e.g. selection highlight).
  final Border? border;

  const CachedNetworkAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackText,
    this.fallbackTextStyle,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
    this.border,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget avatar;

    if (_hasImage) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: SizedBox(
            width: radius,
            height: radius,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(bgColor),
      );
    } else {
      avatar = _buildFallback(bgColor);
    }

    if (border != null) {
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(Color bgColor) {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackText![0].toUpperCase(),
          style:
              fallbackTextStyle ??
              TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
                color: fallbackIconColor,
              ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        fallbackIcon,
        size: radius,
        color: fallbackIconColor ?? Colors.grey,
      ),
    );
  }
}
