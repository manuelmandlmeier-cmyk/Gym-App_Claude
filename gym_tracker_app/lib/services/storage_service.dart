import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/body_model.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';

class StorageService {
  static const String _keyWorkouts = 'workouts_history';
  static const String _keyRoutines = 'routines_list';
  static const String _keyBodyweight = 'bodyweight_history';
  static const String _keyCustomExercises = 'custom_exercises';
  static const String _keyMeasurements = 'body_measurements';

  static const List<String> _allKeys = [
    _keyWorkouts,
    _keyRoutines,
    _keyBodyweight,
    _keyCustomExercises,
    _keyMeasurements,
  ];

  // ---------- Trainings ----------

  Future<List<WorkoutSessionRecord>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyWorkouts);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => WorkoutSessionRecord.fromJson(j)).toList();
  }

  Future<void> saveWorkout(WorkoutSessionRecord workout) async {
    final workouts = await getWorkouts();
    workouts.insert(0, workout);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWorkouts, jsonEncode(workouts.map((w) => w.toJson()).toList()));
  }

  // ---------- Pläne ----------

  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyRoutines);
    if (data == null) {
      return [
        Routine(id: '1', name: 'Push (Brust, Schulter, Trizeps)', exerciseIds: ['1', '5']),
        Routine(id: '2', name: 'Pull (Rücken, Bizeps)', exerciseIds: ['3', '4']),
        Routine(id: '3', name: 'Legs (Beine)', exerciseIds: ['2']),
      ];
    }
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => Routine.fromJson(j)).toList();
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoutines, jsonEncode(routines.map((r) => r.toJson()).toList()));
  }

  // ---------- Körpergewicht ----------

  Future<List<BodyweightEntry>> getBodyweightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyBodyweight);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => BodyweightEntry.fromJson(j)).toList();
  }

  Future<void> saveBodyweightEntry(BodyweightEntry entry) async {
    final entries = await getBodyweightEntries();
    entries.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBodyweight, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  // ---------- Übungen ----------

  Future<List<Exercise>> getExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyCustomExercises);
    List<Exercise> custom = [];
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      custom = jsonList.map((j) => Exercise.fromJson(j)).toList();
    }
    return [...defaultExercises, ...custom];
  }

  Future<void> addCustomExercise(Exercise exercise) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyCustomExercises);
    List<Exercise> custom = [];
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      custom = jsonList.map((j) => Exercise.fromJson(j)).toList();
    }
    custom.add(exercise);
    await prefs.setString(_keyCustomExercises, jsonEncode(custom.map((e) => e.toJson()).toList()));
  }

  // ---------- Körpermaße & Heatmap ----------

  Future<List<BodyMeasurements>> _getMeasurementHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyMeasurements);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => BodyMeasurements.fromJson(j)).toList();
  }

  Future<BodyMeasurements> getLatestMeasurements() async {
    final history = await _getMeasurementHistory();
    if (history.isEmpty) return BodyMeasurements(date: DateTime.now());
    return history.first;
  }

  Future<void> saveMeasurements(BodyMeasurements measurements) async {
    final history = await _getMeasurementHistory();
    measurements.date = DateTime.now();
    history.insert(0, measurements);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMeasurements, jsonEncode(history.map((m) => m.toJson()).toList()));
  }

  List<MuscleGroup> _groupsForTarget(String target) {
    final t = target.toLowerCase();
    final groups = <MuscleGroup>[];
    if (t.contains('brust')) groups.add(MuscleGroup.chest);
    if (t.contains('rücken')) groups.add(MuscleGroup.back);
    if (t.contains('schulter')) groups.add(MuscleGroup.shoulders);
    if (t.contains('bizeps')) groups.add(MuscleGroup.biceps);
    if (t.contains('trizeps')) groups.add(MuscleGroup.triceps);
    if (t.contains('bein')) groups.add(MuscleGroup.legs);
    if (t.contains('core') || t.contains('bauch') || t.contains('rumpf')) groups.add(MuscleGroup.core);
    return groups;
  }

  /// Intensität je Muskelgruppe (0.0 bis 1.0) aus den abgeschlossenen
  /// Arbeitssätzen (ohne Aufwärmsätze) der letzten 7 Tage.
  Future<Map<MuscleGroup, double>> getMuscleHeatmapLast7Days() async {
    final workouts = await getWorkouts();
    final exercises = await getExercises();
    final targetById = {for (final e in exercises) e.id: e.targetMuscle};
    final since = DateTime.now().subtract(const Duration(days: 7));

    final counts = {for (final g in MuscleGroup.values) g: 0};
    for (final w in workouts) {
      if (w.date.isBefore(since)) continue;
      for (final e in w.exercises) {
        final groups = _groupsForTarget(targetById[e.exerciseId] ?? '');
        final workingSets =
            e.sets.where((s) => s.isCompleted && s.category != SetCategory.warmUp).length;
        for (final g in groups) {
          counts[g] = counts[g]! + workingSets;
        }
      }
    }

    return {
      for (final g in MuscleGroup.values)
        g: MuscleActivity(group: g, setVolumeLast7Days: counts[g]!).intensityRatio,
    };
  }

  // ---------- Auto-Fill & PR ----------

  Future<Map<String, dynamic>?> getLastSetForExercise(String exerciseId) async {
    final workouts = await getWorkouts();
    for (final w in workouts) {
      for (final e in w.exercises) {
        if (e.exerciseId == exerciseId && e.sets.isNotEmpty) {
          final lastSet = e.sets.last;
          return {'weight': lastSet.weight, 'reps': lastSet.reps};
        }
      }
    }
    return null;
  }

  Future<bool> checkIsPR(String exerciseId, double currentWeight, int currentReps) async {
    final workouts = await getWorkouts();
    double maxWeight = 0;
    int maxRepsAtMaxWeight = 0;

    for (final w in workouts) {
      for (final e in w.exercises) {
        if (e.exerciseId != exerciseId) continue;
        for (final s in e.sets) {
          if (!s.isCompleted) continue;
          if (s.weight > maxWeight) {
            maxWeight = s.weight;
            maxRepsAtMaxWeight = s.reps;
          } else if (s.weight == maxWeight && s.reps > maxRepsAtMaxWeight) {
            maxRepsAtMaxWeight = s.reps;
          }
        }
      }
    }

    if (currentWeight > maxWeight) return true;
    if (currentWeight == maxWeight && currentReps > maxRepsAtMaxWeight) return true;
    return false;
  }

  // ---------- Backup ----------

  Future<String> exportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final key in _allKeys) {
      final raw = prefs.getString(key);
      if (raw != null) data[key] = jsonDecode(raw);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importAll(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültiges Backup-Format');
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in _allKeys) {
      final value = decoded[key];
      if (value == null) continue;
      if (value is! List) throw FormatException('Ungültige Daten bei $key');
      await prefs.setString(key, jsonEncode(value));
    }
  }
}
