import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full screen portrait & landscape for pro video editing
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
      title: 'CineCut Studio Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEAB308),
          surface: Color(0xFF09090B),
        ),
      ),
      home: const CineCutHomeScreen(),
    );
  }
}

class CineCutHomeScreen extends StatefulWidget {
  const CineCutHomeScreen({super.key});

  @override
  State<CineCutHomeScreen> createState() => _CineCutHomeScreenState();
}

class _CineCutHomeScreenState extends State<CineCutHomeScreen> {
  WebViewController? _controller;
  HttpServer? _server;
  int _port = 0;
  bool _isLoading = true;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startServerAndLoad();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _startServerAndLoad() async {
    try {
      // Start local embedded server on loopback IPv4
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;

      _server!.listen((HttpRequest request) async {
        String path = request.uri.path;
        if (path == '/' || path.isEmpty) {
          path = '/index.html';
        }

        // Clean path and build asset path
        final cleanPath = path.startsWith('/') ? path.substring(1) : path;
        final assetPath = 'assets/dist/$cleanPath';

        try {
          ByteData data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();

          // Set correct Content-Type header
          if (cleanPath.endsWith('.html')) {
            request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
          } else if (cleanPath.endsWith('.js') || cleanPath.endsWith('.mjs')) {
            request.response.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
          } else if (cleanPath.endsWith('.css')) {
            request.response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
          } else if (cleanPath.endsWith('.svg')) {
            request.response.headers.contentType = ContentType('image', 'svg+xml');
          } else if (cleanPath.endsWith('.json')) {
            request.response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
          } else if (cleanPath.endsWith('.png')) {
            request.response.headers.contentType = ContentType('image', 'png');
          } else if (cleanPath.endsWith('.jpg') || cleanPath.endsWith('.jpeg')) {
            request.response.headers.contentType = ContentType('image', 'jpeg');
          } else if (cleanPath.endsWith('.ico')) {
            request.response.headers.contentType = ContentType('image', 'x-icon');
          }

          request.response.headers.add('Access-Control-Allow-Origin', '*');
          request.response.headers.add('Cache-Control', 'public, max-age=31536000, immutable');
          request.response.add(bytes);
          await request.response.close();
        } catch (_) {
          // SPA Fallback: return index.html for client-side routing
          try {
            ByteData fallbackData = await rootBundle.load('assets/dist/index.html');
            request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
            request.response.headers.add('Access-Control-Allow-Origin', '*');
            request.response.add(fallbackData.buffer.asUint8List());
            await request.response.close();
          } catch (e) {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('Not found: $cleanPath');
            await request.response.close();
          }
        }
      });

      final localUrl = 'http://127.0.0.1:$_port';

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36')
        ..setBackgroundColor(const Color(0xFF05060A))
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              // Allow all internal loopback requests
              if (url.startsWith('http://127.0.0.1') || url.startsWith('http://localhost')) {
                return NavigationDecision.navigate;
              }
              // Prevent external pages from breaking the app, open in external device browser
              try {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('External link launch note: $e');
              }
              return NavigationDecision.prevent;
            },
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView resource error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(localUrl));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
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
              if (_controller != null)
                WebViewWidget(controller: _controller!),

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
                              color: const Color(0xFFEAB308).withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEAB308).withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFFEAB308),
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CineCut Pro Studio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Launching local studio engine...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 150,
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

              if (_errorMessage != null)
                Container(
                  color: const Color(0xFF05060A),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFF43F5E),
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Studio Launch Error',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
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
                            _startServerAndLoad();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Restart Studio'),
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
