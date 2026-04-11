import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 2x2 Grid for standard services
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _ServiceCard(
                imagePath: 'assets/eczane_logo.png',
                title: 'Nöbetçi Eczane',
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                ),
                iconColor: Colors.white,
                imageSize: 32,
                onTap: () => context.push('/pharmacy'),
              ),
              _ServiceCard(
                imagePath: 'assets/noter.png',
                title: 'Noterler',
                backgroundColor: Colors.white,
                borderColor: Colors.black,
                textColor: Colors.black,
                iconColor: Colors.black,
                applyColorToImage: false,
                imageSize: 38,
                onTap: () => context.push('/noterler'),
              ),
              _ServiceCard(
                icon: Icons.storefront_rounded,
                title: 'Halk Pazarları',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
                ),
                iconColor: Colors.white,
                onTap: () => context.push('/pazarlar'),
              ),
              _ServiceCard(
                icon: Icons.directions_bus_rounded,
                title: 'Otobüs Saatleri',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                ),
                iconColor: Colors.white,
                onTap: () => context.push('/otobus'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Full width Haberler button
          _ServiceCard(
            icon: Icons.newspaper_rounded,
            title: 'Haberler',
            isFullWidth: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            iconColor: Colors.white,
            onTap: () => context.push('/news'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isFullWidth;
  final bool applyColorToImage;
  final double? imageSize;

  const _ServiceCard({
    this.icon,
    this.imagePath,
    required this.title,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    required this.iconColor,
    this.textColor = Colors.white,
    required this.onTap,
    this.isFullWidth = false,
    this.applyColorToImage = true,
    this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          height: isFullWidth ? 80 : null,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: (gradient?.colors.first ?? backgroundColor ?? Colors.black).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: isFullWidth
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _buildIcon(imageSize ?? 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.7), size: 14),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _buildIcon(imageSize ?? 28),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: size,
        height: size,
        color: applyColorToImage ? iconColor : null,
        colorBlendMode: applyColorToImage ? BlendMode.srcIn : null,
        fit: BoxFit.contain,
      );
    }
    return Icon(icon ?? Icons.help_outline, color: iconColor, size: size);
  }
}
