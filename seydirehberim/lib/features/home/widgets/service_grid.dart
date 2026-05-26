import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/haptic_service.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../forum/widgets/forum_rules_sheet.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 2x3 Grid for main services
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
                showMarketPattern: true,
                onTap: () => context.push('/pazarlar'),
              ),
              _ServiceCard(
                icon: Icons.directions_bus_rounded,
                title: 'Otobüs Saatleri',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                ),
                iconColor: Colors.white,
                showBusPattern: true,
                onTap: () => context.push('/otobus'),
              ),
              _ServiceCard(
                icon: Icons.person_off_rounded,
                title: 'Vefat Edenler',
                gradient: const LinearGradient(
                  colors: [Color(0xFF546E7A), Color(0xFF78909C)],
                ),
                iconColor: Colors.white,
                showVefatPattern: true,
                onTap: () => context.push('/vefat'),
              ),
              _ServiceCard(
                icon: Icons.map_rounded,
                title: 'Seydi Harita',
                backgroundColor: Colors.white,
                borderColor: AppColors.primary.withOpacity(0.3),
                textColor: AppColors.primary,
                iconColor: AppColors.primary,
                showMapPattern: true,
                onTap: () => context.push('/seydi-map'),
              ),
              _ServiceCard(
                icon: Icons.newspaper_rounded,
                title: 'Haberler',
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                iconColor: Colors.white,
                showNewsPattern: true,
                onTap: () => context.push('/news'),
              ),
              _ServiceCard(
                icon: Icons.forum_rounded,
                title: 'Forum',
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C35CC), Color(0xFF7B52E8)],
                ),
                iconColor: Colors.white,
                showForumPattern: true,
                onTap: () => _openForum(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Forum kuralları onaylandıysa direkt aç, değilse kurallar sheet'ini göster.
  static void _openForum(BuildContext context) {
    ForumRulesSheet.showIfNeeded(
      context,
      onAccepted: () => context.push('/forum'),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Schematic "street" lines (Map pattern)
    path.moveTo(0, size.height * 0.4);
    path.lineTo(size.width * 0.3, size.height * 0.35);
    path.lineTo(size.width * 0.4, 0);
    
    path.moveTo(size.width * 0.2, 0);
    path.lineTo(size.width * 0.25, size.height * 0.6);
    path.lineTo(0, size.height * 0.75);
    
    path.moveTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.7, size.height * 0.45);
    path.lineTo(size.width, size.height * 0.55);
    
    path.moveTo(size.width * 0.7, size.height * 0.45);
    path.lineTo(size.width * 0.6, size.height);

    path.moveTo(size.width, size.height * 0.1);
    path.lineTo(size.width * 0.85, size.height * 0.25);

    path.moveTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.55, size.height * 0.7);
    path.lineTo(size.width, size.height * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NewsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Schematic "newspaper lines" or "data flow"
    for (var i = 1; i < 6; i++) {
      double y = size.height * (0.15 + (i * 0.15));
      double startX = size.width * (0.4 + (i % 2 * 0.1));
      double endX = size.width * (0.85 - (i % 3 * 0.05));
      
      path.moveTo(startX, y);
      path.lineTo(endX, y);
    }
    
    // A vertical "divider"
    path.moveTo(size.width * 0.38, size.height * 0.2);
    path.lineTo(size.width * 0.38, size.height * 0.8);

    canvas.drawPath(path, paint);
    
    // Add some small "dot" highlights
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.7), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BusPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Schematic "bus route"
    path.moveTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height * 0.8);

    canvas.drawPath(path, paint);
    
    // Add "stops" (dots)
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.2), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Schematic "market tents" (Triangles/Trapezoids)
    for (var i = 0; i < 3; i++) {
      double xBase = size.width * (0.45 + (i * 0.15));
      double yBase = size.height * (0.3 + (i * 0.15));
      
      final path = Path();
      path.moveTo(xBase, yBase);
      path.lineTo(xBase + 15, yBase - 15);
      path.lineTo(xBase + 30, yBase);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VefatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Abstract respectful "rising" or "flowing" lines
    for (var i = 0; i < 4; i++) {
      double x = size.width * (0.5 + (i * 0.12));
      path.moveTo(x, size.height);
      path.quadraticBezierTo(
        x + 20, size.height * 0.5,
        x - 10, 0,
      );
    }

    canvas.drawPath(path, paint);
    
    // Add some small "light" dots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 2, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final bool showMapPattern;
  final bool showNewsPattern;
  final bool showBusPattern;
  final bool showMarketPattern;
  final bool showVefatPattern;
  final bool showForumPattern;

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
    this.showMapPattern = false,
    this.showNewsPattern = false,
    this.showBusPattern = false,
    this.showMarketPattern = false,
    this.showVefatPattern = false,
    this.showForumPattern = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          height: isFullWidth ? 80 : null,
          clipBehavior: Clip.antiAlias,
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
          child: Stack(
            children: [
              if (showMapPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                  ),
                ),
              if (showNewsPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NewsPatternPainter(),
                  ),
                ),
              if (showBusPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BusPatternPainter(),
                  ),
                ),
              if (showMarketPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MarketPatternPainter(),
                  ),
                ),
              if (showVefatPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _VefatPatternPainter(),
                  ),
                ),
              if (showForumPattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ForumPatternPainter(),
                  ),
                ),
              Padding(
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
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

class _ForumPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Sohbet baloncuklarını andıran şematik çizgiler
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.1,
          size.width * 0.4, size.height * 0.3),
      const Radius.circular(6),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.48, size.height * 0.5,
          size.width * 0.32, size.height * 0.25),
      const Radius.circular(6),
    ));
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.15), 2.5, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.87, size.height * 0.65), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
