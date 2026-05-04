import 'package:flutter/material.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

import 'screens/article_screen.dart';
import 'screens/experiences_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/video_screen.dart';

void main() {
  runApp(const MarfeelExampleApp());
}

class MarfeelExampleApp extends StatefulWidget {
  const MarfeelExampleApp({super.key});

  @override
  State<MarfeelExampleApp> createState() => _MarfeelExampleAppState();
}

class _MarfeelExampleAppState extends State<MarfeelExampleApp> {
  @override
  void initState() {
    super.initState();
    CompassTracking.initialize('1659', pageTechnology: 105);
    CompassTracking.setConsent(true);
    CompassTracking.setLandingPage('http://dev.marfeel.co/');
    CompassTracking.trackScreen('home');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marfeel SDK Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      routes: {'/article': (_) => const ArticleScreen()},
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    VideoScreen(),
    ExperiencesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.video_library), label: 'Video'),
          NavigationDestination(
              icon: Icon(Icons.science), label: 'Experiences'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
