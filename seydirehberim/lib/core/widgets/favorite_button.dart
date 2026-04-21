import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/favorites/providers/favorites_provider.dart';
import '../utils/app_notification.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  final String id;
  final String type;
  final double size;
  final Color? color;
  final bool showBackground;

  const FavoriteButton({
    super.key,
    required this.id,
    required this.type,
    this.size = 20,
    this.color,
    this.showBackground = true,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _particleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Haptic feedback
    HapticService.vibrate();
    final isNowFavorited = !ref.read(favoritesProvider).any((e) => e.id == widget.id && e.type == widget.type);
    
    // Toggle favorite logic
    ref.read(favoritesProvider.notifier).toggleFavorite(widget.id, widget.type);
    
    // Start animation always for better feel
    _controller.forward(from: 0);

    // Show floating notification
    if (mounted) {
      if (isNowFavorited) {
        AppNotification.success(context, 'Favorilere eklendi');
      } else {
        AppNotification.show(context, message: 'Favorilerden çıkarıldı', icon: Icons.favorite_border_rounded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.any((e) => e.id == widget.id && e.type == widget.type);

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle burst effect
          if (isFav)
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size * 3, widget.size * 3),
                  painter: ParticlePainter(
                    progress: _particleAnimation.value,
                    color: Colors.red,
                  ),
                );
              },
            ),
          
          // Icon with scale animation
          GestureDetector(
            onTap: _onTap,
            child: Container(
              margin: widget.showBackground ? const EdgeInsets.all(8) : EdgeInsets.zero,
              padding: widget.showBackground ? const EdgeInsets.all(8) : EdgeInsets.zero,
              decoration: widget.showBackground ? BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ) : null,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : (widget.color ?? Colors.white),
                  size: widget.size,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const int particleCount = 10;
    for (int i = 0; i < particleCount; i++) {
      final double angle = (i * 2 * pi) / particleCount;
      
      // Particle distance expands
      final double distance = radius * progress * 1.1;
      
      // Particle opacity fades out
      final double opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity);
      
      // Particle size shrinks
      final double particleSize = (1 - progress) * 3 + 1;
      
      // Trig for position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);
      
      canvas.drawCircle(Offset(x, y), particleSize, paint);
      
      // Add a smaller sub-particle for extra details
      final double subAngle = angle + (pi / particleCount);
      final double subDistance = distance * 0.7;
      final double subX = center.dx + subDistance * cos(subAngle);
      final double subY = center.dy + subDistance * sin(subAngle);
      final subPaint = Paint()..color = color.withOpacity(opacity * 0.7);
      canvas.drawCircle(Offset(subX, subY), particleSize * 0.6, subPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
