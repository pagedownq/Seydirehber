import 'package:flutter/material.dart';
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
                icon: Icons.local_pharmacy_rounded,
                title: 'Nöbetçi Eczane',
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                ),
                iconColor: Colors.white,
                onTap: () => context.push('/pharmacy'),
              ),
              _ServiceCard(
                icon: Icons.gavel_rounded,
                title: 'Noterler',
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                ),
                iconColor: Colors.white,
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
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.iconColor,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          height: isFullWidth ? 80 : null,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
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
}
