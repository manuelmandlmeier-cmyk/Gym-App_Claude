import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/storage_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String routineName;
  final List<Exercise> initialExercises;
  final bool isFreeWorkout;

  const ActiveWorkoutScreen({
    super.key,
    required this.routineName,
    required this.initialExercises,
    this.isFreeWorkout = false,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final StorageService _storage = StorageService();
  final List<ExerciseSession> _exerciseSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSessions();
  }

  Future<void> _initSessions() async {
    final sessions = <ExerciseSession>[];
    for (final ex in widget.initialExercises) {
      // Smart Auto-Fill: letzte Werte der Übung übernehmen
      final lastSet = await _storage.getLastSetForExercise(ex.id);
      final double defaultWeight = (lastSet?['weight'] as num?)?.toDouble() ?? 50.0;
      final int defaultReps = (lastSet?['reps'] as num?)?.toInt() ?? 10;

      sessions.add(ExerciseSession(
        exerciseId: ex.id,
        exerciseName: ex.name,
        sets: [WorkoutSet(setNumber: 1, weight: defaultWeight, reps: defaultReps)],
      ));
    }
    if (!mounted) return;
    setState(() {
      _exerciseSessions
        ..clear()
        ..addAll(sessions);
      _isLoading = false;
    });
  }

  void _addSet(int exerciseIndex) {
    final session = _exerciseSessions[exerciseIndex];
    final lastSet = session.sets.isNotEmpty ? session.sets.last : null;
    final double w = lastSet?.weight ?? 50.0;
    final int r = lastSet?.reps ?? 10;

    setState(() {
      session.sets.add(WorkoutSet(setNumber: session.sets.length + 1, weight: w, reps: r));
    });
  }

  Future<void> _completeSet(int exerciseIndex, int setIndex) async {
    final set = _exerciseSessions[exerciseIndex].sets[setIndex];
    final exId = _exerciseSessions[exerciseIndex].exerciseId;

    if (set.isCompleted) {
      setState(() {
        set.isCompleted = false;
        set.isPr = false;
      });
      return;
    }

    final isPr = await _storage.checkIsPR(exId, set.weight, set.reps);
    if (!mounted) return;
    setState(() {
      set.isCompleted = true;
      set.isPr = isPr && set.category != SetCategory.warmUp;
    });
  }

  String _fmtWeight(double w) => w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toString();

  void _finishWorkout() {
    int rating = 5;
    String notes = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Training beenden?'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Wie war dein Training? (1-5 Sterne)'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setStateDialog(() => rating = index + 1),
                    );
                  }),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Notizen zum Training (optional)'),
                  onChanged: (val) => notes = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final record = WorkoutSessionRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  routineName: widget.routineName,
                  date: DateTime.now(),
                  exercises: _exerciseSessions,
                  rating: rating,
                  generalNotes: notes,
                );
                await _storage.saveWorkout(record);
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext); // Dialog schließen
                Navigator.pop(context); // Training schließen
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineName),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishWorkout,
            tooltip: 'Training beenden',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exerciseSessions.length,
              itemBuilder: (context, exIndex) {
                final session = _exerciseSessions[exIndex];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.exerciseName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(48),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                            3: FixedColumnWidth(64),
                            4: FixedColumnWidth(48),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              children: [
                                Text('Satz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Gewicht (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Reps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Typ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            ...List.generate(session.sets.length, (setIndex) {
                              final set = session.sets[setIndex];
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Text('${set.setNumber}'),
                                        if (set.isPr) const Text(' 🏆', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: _NumberField(
                                      key: ValueKey('w_${exIndex}_$setIndex'),
                                      initialText: _fmtWeight(set.weight),
                                      decimal: true,
                                      onChanged: (val) {
                                        set.weight = double.tryParse(val.replaceAll(',', '.')) ?? set.weight;
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: _NumberField(
                                      key: ValueKey('r_${exIndex}_$setIndex'),
                                      initialText: set.reps.toString(),
                                      decimal: false,
                                      onChanged: (val) {
                                        set.reps = int.tryParse(val) ?? set.reps;
                                      },
                                    ),
                                  ),
                                  DropdownButton<SetCategory>(
                                    value: set.category,
                                    isDense: true,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                          value: SetCategory.normal,
                                          child: Text('Norm', style: TextStyle(fontSize: 11))),
                                      DropdownMenuItem(
                                          value: SetCategory.warmUp,
                                          child: Text('Warm', style: TextStyle(fontSize: 11))),
                                      DropdownMenuItem(
                                          value: SetCategory.dropSet,
                                          child: Text('Drop', style: TextStyle(fontSize: 11))),
                                      DropdownMenuItem(
                                          value: SetCategory.failure,
                                          child: Text('Fail', style: TextStyle(fontSize: 11))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => set.category = val);
                                    },
                                  ),
                                  Checkbox(
                                    value: set.isCompleted,
                                    onChanged: (_) => _completeSet(exIndex, setIndex),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _addSet(exIndex),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Satz hinzufügen (Quick-Add)'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Eingabefeld mit eigenem Controller, damit Cursor und Text beim
/// Neuaufbau des Bildschirms nicht zurückspringen.
class _NumberField extends StatefulWidget {
  final String initialText;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _NumberField({
    super.key,
    required this.initialText,
    required this.decimal,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      onChanged: widget.onChanged,
    );
  }
}
