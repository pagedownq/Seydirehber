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

class SearchItemShimmer extends StatelessWidget {
  const SearchItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerWidget(
          width: 50,
          height: 50,
          borderRadius: 8,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerWidget(height: 16, width: 150),
              const SizedBox(height: 6),
              const ShimmerWidget(height: 12, width: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class ShimmerSearchList extends StatelessWidget {
  const ShimmerSearchList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const SearchItemShimmer(),
    );
  }
}

class CouponCardShimmer extends StatelessWidget {
  const CouponCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const ShimmerWidget(
            width: 80,
            height: 120,
            borderRadius: 0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerWidget(height: 16, width: double.infinity),
                  SizedBox(height: 8),
                  ShimmerWidget(height: 12, width: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalCardShimmer extends StatelessWidget {
  const HorizontalCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerWidget(
            height: 120,
            width: 160,
            borderRadius: 16,
          ),
          SizedBox(height: 8),
          ShimmerWidget(height: 14, width: 120),
          SizedBox(height: 4),
          ShimmerWidget(height: 10, width: 80),
        ],
      ),
    );
  }
}

class BannerShimmer extends StatelessWidget {
  const BannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const ShimmerWidget(
        height: 180,
        width: double.infinity,
        borderRadius: 20,
      ),
    );
  }
}

class DetailShimmer extends StatelessWidget {
  const DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Area
          const ShimmerWidget(
            width: double.infinity,
            height: 450,
            borderRadius: 0,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const ShimmerWidget(
                  width: 250,
                  height: 30,
                  borderRadius: 15,
                ),
                const SizedBox(height: 12),
                // Category
                const ShimmerWidget(
                  width: 100,
                  height: 20,
                  borderRadius: 10,
                ),
                const SizedBox(height: 32),
                // Info Cards Grid-like
                Row(
                  children: [
                    Expanded(child: _buildInfoCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCardShimmer()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInfoCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCardShimmer()),
                  ],
                ),
                const SizedBox(height: 32),
                // About Title
                const ShimmerWidget(
                  width: 140,
                  height: 24,
                  borderRadius: 12,
                ),
                const SizedBox(height: 16),
                // About Content
                for (int i = 0; i < 4; i++) ...[
                  ShimmerWidget(
                    width: i == 3 ? 200 : double.infinity,
                    height: 14,
                    borderRadius: 7,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 32),
                // Map Area
                const ShimmerWidget(
                  width: double.infinity,
                  height: 200,
                  borderRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [
          ShimmerWidget(
            width: 32,
            height: 32,
            borderRadius: 10,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget(
                width: 60,
                height: 10,
                borderRadius: 5,
              ),
              SizedBox(height: 4),
              ShimmerWidget(
                width: 80,
                height: 12,
                borderRadius: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WebViewShimmer extends StatelessWidget {
  const WebViewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const ShimmerWidget(
              width: double.infinity,
              height: 300,
              borderRadius: 20,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < 6; i++) ...[
              const ShimmerWidget(
                width: double.infinity,
                height: 40,
                borderRadius: 12,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class ReviewShimmer extends StatelessWidget {
  const ReviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget(
            width: double.infinity,
            height: 120,
            borderRadius: 20,
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerWidget(
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerWidget(
                          width: 120,
                          height: 16,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 8),
                        const ShimmerWidget(
                          width: double.infinity,
                          height: 12,
                          borderRadius: 6,
                        ),
                        const SizedBox(height: 6),
                        const ShimmerWidget(
                          width: 180,
                          height: 12,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
