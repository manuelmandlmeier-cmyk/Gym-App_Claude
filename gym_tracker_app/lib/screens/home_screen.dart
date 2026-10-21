import 'package:flutter/material.dart';
import 'workouts_screen.dart';
import 'exercises_screen.dart';
import 'bodyweight_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WorkoutsScreen(),
    ExercisesScreen(),
    BodyweightScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Training'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Übungen'),
          NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Gewicht'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Mehr'),
        ],
      ),
    );
  }
}
