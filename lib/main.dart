import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/editor/editor_screen.dart';
import 'features/home/home_screen.dart';
import 'features/admin/admin_center_screen.dart';
import 'features/rooms/cinerooms_screen.dart';
import 'features/live/cinelive_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred landscape/portrait orientations for pro editor
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set dark status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF09090B),
  ));

  try {
    // Initialized with google-services.json
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  runApp(const CineCutApp());
}

class CineCutApp extends StatelessWidget {
  const CineCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineCut Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 1; // Default to Editor

  final List<Widget> _screens = const [
    HomeScreen(),
    EditorScreen(),
    CineRoomsScreen(),
    CineLiveScreen(),
    AdminCenterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF09090B),
        indicatorColor: const Color(0xFFEAB308).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.movie_creation_outlined), label: 'Editor'),
          NavigationDestination(icon: Icon(Icons.group_work_outlined), label: 'Rooms'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
        ],
      ),
    );
  }
}
