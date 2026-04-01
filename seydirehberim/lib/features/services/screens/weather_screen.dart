import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_widget.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _hasError = false;
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(AppAssets.weatherUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hava Durumu', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: IndexedStack(
        index: _hasError ? 1 : (_isLoading ? 0 : 2),
        children: [
          const WebViewShimmer(),
          ErrorView(
            message: 'Hava durumu bilgilerini görüntülemek için lütfen internet bağlantınızı açın.',
            onRetry: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _controller.reload();
            },
          ),
          AbsorbPointer(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
