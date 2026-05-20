import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Wrapper único sobre [CachedNetworkImage] para que toda la app cachee
/// imágenes en disco (no solo en RAM).
///
/// Drop-in para `Image.network(url, fit: ..., width: ..., height: ...)`.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      // Sin fade-in: la imagen aparece apenas termina de descargar.
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      // Mantiene la imagen vieja mientras carga la nueva (evita placeholder flash).
      useOldImageOnUrlChange: true,
      placeholder: (context, _) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, _, __) => errorWidget ?? _defaultError(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.grayNeutral.withValues(alpha: 0.08),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.lightBackground,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 24,
        color: AppColors.darkText.withValues(alpha: 0.35),
      ),
    );
  }
}
