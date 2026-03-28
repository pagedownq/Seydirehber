import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  final bool isCompany;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.memCacheWidth,
    this.memCacheHeight,
    this.isCompany = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: isCompany
            ? Image.asset(
                'assets/fotoyok.png',
                width: width,
                height: height,
                fit: fit,
              )
            : Container(
                width: width,
                height: height,
                color: AppColors.primarySurface,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppColors.primaryDark),
              ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: RepaintBoundary(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: memCacheWidth ??
              (width != null && width!.isFinite ? (width! * 2).toInt() : null),
          memCacheHeight: memCacheHeight ??
              (height != null && height!.isFinite
                  ? (height! * 2).toInt()
                  : null),
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: AppColors.shimmerBase,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color: AppColors.primarySurface,
            child: isCompany
                ? Image.asset(
                    'assets/fotoyok.png',
                    width: width,
                    height: height,
                    fit: fit,
                  )
                : const Icon(Icons.broken_image_outlined,
                    color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}
