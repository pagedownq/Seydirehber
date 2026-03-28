import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 12,
  });

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 12,
  });

  const ShimmerWidget.circular({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerListWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double itemWidth;
  final double borderRadius;
  final Axis scrollDirection;

  const ShimmerListWidget({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 220,
    this.itemWidth = 250,
    this.borderRadius = 18,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: scrollDirection,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ShimmerWidget(
            width: itemWidth,
            height: itemHeight,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }
}

class NewsCardShimmer extends StatelessWidget {
  const NewsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget(
            height: 200,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget(height: 20, width: 200),
                const SizedBox(height: 10),
                const ShimmerWidget(height: 14),
                const SizedBox(height: 6),
                const ShimmerWidget(height: 14, width: 250),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerWidget(height: 12, width: 80),
                    ShimmerWidget(height: 12, width: 100),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListCardShimmer extends StatelessWidget {
  final bool isGrid;
  const ListCardShimmer({super.key, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isGrid ? null : 220,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ShimmerWidget(
              borderRadius: isGrid ? 16 : 20,
            ),
          ),
          if (!isGrid) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerWidget(height: 16, width: 150),
                          const SizedBox(height: 6),
                          const ShimmerWidget(height: 12, width: 100),
                        ],
                      ),
                    ),
                    const ShimmerWidget(height: 30, width: 30, borderRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShimmerVerticalListWidget extends StatelessWidget {
  final int itemCount;
  final double padding;

  const ShimmerVerticalListWidget({
    super.key,
    this.itemCount = 5,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return const ShimmerWidget(
          height: 120,
          borderRadius: 20,
        );
      },
    );
  }
}
