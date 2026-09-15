import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_config.dart';
import '../constants/app_colors.dart';

class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Backend mengembalikan path relatif (/uploads/...). Resolve ke absolut
    // agar tidak 404 saat baseUrl production.
    final resolved = AppConfig.resolveImageUrl(imageUrl) ?? imageUrl;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ??
            Container(
              width: width,
              height: height,
              color: AppColors.inputBackground,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) => errorWidget ??
            Container(
              width: width,
              height: height,
              color: AppColors.inputBackground,
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.grey,
                  size: 24,
                ),
              ),
            ),
      ),
    );
  }
}