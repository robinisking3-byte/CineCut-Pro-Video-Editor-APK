import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full screen portrait & landscape for cinematic editor
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Dark edge-to-edge system navigation bar & status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF05060A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CineCutApp());
}

class CineCutApp extends StatelessWidget {
  const CineCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineCut Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEAB308),
          surface: Color(0xFF09090B),
        ),
      ),
      home: const CineCutWebViewScreen(),
    );
  }
}

class CineCutWebViewScreen extends StatefulWidget {
  const CineCutWebViewScreen({super.key});

  @override
  State<CineCutWebViewScreen> createState() => _CineCutWebViewScreenState();
}

class _CineCutWebViewScreenState extends State<CineCutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  String? _errorMessage;

  static const String appUrl =
      'https://ais-pre-2kt5kr7vbmalqzycgw3eay-776276684314.asia-southeast1.run.app';

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF05060A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView resource error: ${error.description}');
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(appUrl));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // Real CineCut Studio WebView
              WebViewWidget(controller: _controller),

              // Animated Loading Screen on First Launch
              if (_isLoading)
                Container(
                  color: const Color(0xFF05060A),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFEAB308).withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEAB308).withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFFEAB308),
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CineCut Pro Studio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Loading latest workspace...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 140,
                          child: LinearProgressIndicator(
                            value: _progress > 0 ? _progress : null,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFEAB308),
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error fallback if offline
              if (_errorMessage != null)
                Container(
                  color: const Color(0xFF05060A),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFFF43F5E),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Network Connection Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not connect to CineCut Cloud servers.\nPlease check your Internet and retry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _controller.reload();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEAB308),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
