import 'package:flutter/material.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import 'active_workout_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final StorageService _storage = StorageService();
  List<Routine> _routines = [];
  List<WorkoutSessionRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routines = await _storage.getRoutines();
    final history = await _storage.getWorkouts();
    if (!mounted) return;
    setState(() {
      _routines = routines;
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _startWorkout(Routine routine) async {
    final exercises = await _storage.getExercises();
    final routineExercises = exercises.where((e) => routine.exerciseIds.contains(e.id)).toList();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(
          routineName: routine.name,
          initialExercises: routineExercises,
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _startFreeWorkout() async {
    final exercises = await _storage.getExercises();
    if (!mounted) return;

    final selected = <String>{};
    final chosen = await showDialog<List<Exercise>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Übungen wählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: exercises
                  .map((e) => CheckboxListTile(
                        value: selected.contains(e.id),
                        title: Text(e.name),
                        subtitle: Text(e.targetMuscle),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selected.add(e.id);
                          } else {
                            selected.remove(e.id);
                          }
                        }),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, exercises.where((e) => selected.contains(e.id)).toList()),
              child: const Text('Starten'),
            ),
          ],
        ),
      ),
    );

    if (chosen == null || chosen.isEmpty || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(
          routineName: 'Freies Training',
          initialExercises: chosen,
          isFreeWorkout: true,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kraftsport Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _startFreeWorkout,
            tooltip: 'Freies Training',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Deine Trainingspläne', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._routines.map((routine) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                  title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${routine.exerciseIds.length} Übungen hinterlegt'),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _startWorkout(routine),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'),
                  ),
                ),
              )),
          const SizedBox(height: 20),
          const Text('Letzte Trainings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_history.isEmpty)
            const Text('Noch keine Trainings absolviert. Starte jetzt deine erste Session!',
                style: TextStyle(color: Colors.grey))
          else
            ..._history.take(5).map((record) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(record.routineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${record.date.day}.${record.date.month}.${record.date.year} • Bewertung: ${'⭐' * record.rating}'),
                    trailing: Text('${record.exercises.length} Üb.'),
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startFreeWorkout,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Training starten'),
      ),
    );
  }
}
