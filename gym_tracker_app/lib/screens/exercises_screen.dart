import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final StorageService _storage = StorageService();
  List<Exercise> _exercises = [];
  String _searchQuery = '';
  String _selectedFilter = 'Alle';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _storage.getExercises();
      if (!mounted) return;
      setState(() => _exercises = exercises);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Alle', ...{for (final e in _exercises) e.equipment}];

    final filtered = _exercises.where((e) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = e.name.toLowerCase().contains(q) || e.targetMuscle.toLowerCase().contains(q);
      final matchesFilter = _selectedFilter == 'Alle' || e.equipment == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Übungs-Lexikon & Guides')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Übung suchen...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText('Fehler: $_error'),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ex = filtered[index];
                return ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ziel: ${ex.targetMuscle} • Equipment: ${ex.equipment}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Beschreibung:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(ex.description),
                          const SizedBox(height: 10),
                          const Text('Technik-Tipps (Offline Guide):',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...ex.tips.map((tip) => Text('• $tip')),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
