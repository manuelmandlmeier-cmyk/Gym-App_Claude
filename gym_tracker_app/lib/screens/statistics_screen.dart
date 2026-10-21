import 'package:flutter/material.dart';
import '../models/workout_set.dart';
import '../services/storage_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StorageService _storage = StorageService();
  List<WorkoutSessionRecord> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workouts = await _storage.getWorkouts();
    if (!mounted) return;
    setState(() => _workouts = workouts);
  }

  // 1RM nach Brzycki: 1RM = Gewicht * (36 / (37 - Wiederholungen))
  double calculate1RM(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps >= 37) return weight;
    return weight * (36 / (37 - reps));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik & 1RM-Rechner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Deine Trainings-Historie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_workouts.isEmpty)
            const Text('Keine Daten für Statistiken vorhanden.')
          else
            ..._workouts.map((w) {
              double max1RM = 0;
              for (final e in w.exercises) {
                for (final s in e.sets) {
                  if (!s.isCompleted) continue;
                  final rm = calculate1RM(s.weight, s.reps);
                  if (rm > max1RM) max1RM = rm;
                }
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.routineName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Datum: ${w.date.day}.${w.date.month}.${w.date.year}'),
                      const Divider(),
                      Text('Geschätzter Max-1RM in dieser Session: ${max1RM.toStringAsFixed(1)} kg',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      if (w.generalNotes.isNotEmpty) Text('Notiz: ${w.generalNotes}'),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
