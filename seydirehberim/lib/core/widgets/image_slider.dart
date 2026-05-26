import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cached_image_widget.dart';

class ImageSlider extends StatefulWidget {
  final List<String> images;
  final double height;
  final String heroTag;

  const ImageSlider({
    super.key,
    required this.images,
    this.height = 450,
    required this.heroTag,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _isPrecached = false;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _startTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPrecached && widget.images.isNotEmpty) {
      _isPrecached = true;
      // Pre-cache all gallery images in the background so they are ready instantly
      for (final imageUrl in widget.images) {
        if (imageUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          ).catchError((_) {});
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < widget.images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Hero(
        tag: widget.heroTag,
        child: const CachedImageWidget(
          imageUrl: '',
          fit: BoxFit.cover,
          isCompany: true,
        ),
      );
    }

    final cacheWidth = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round();

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: index == 0 ? widget.heroTag : 'image-$index-${widget.heroTag}',
              child: CachedImageWidget(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                isCompany: true,
                memCacheWidth: cacheWidth,
              ),
            );
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
