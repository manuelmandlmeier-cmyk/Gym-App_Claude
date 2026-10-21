enum SetCategory { warmUp, normal, dropSet, failure }

class WorkoutSet {
  int setNumber;
  double weight;
  int reps;
  SetCategory category;
  bool isCompleted;
  bool isPr;

  WorkoutSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.category = SetCategory.normal,
    this.isCompleted = false,
    this.isPr = false,
  });

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'category': category.index,
        'isCompleted': isCompleted,
        'isPr': isPr,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        setNumber: json['setNumber'],
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'],
        category: SetCategory.values[json['category']],
        isCompleted: json['isCompleted'],
        isPr: json['isPr'] ?? false,
      );
}

class ExerciseSession {
  String exerciseId;
  String exerciseName;
  List<WorkoutSet> sets;
  String notes;

  ExerciseSession({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  factory ExerciseSession.fromJson(Map<String, dynamic> json) => ExerciseSession(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        sets: (json['sets'] as List).map((s) => WorkoutSet.fromJson(s)).toList(),
        notes: json['notes'] ?? '',
      );
}

class WorkoutSessionRecord {
  String id;
  String routineName;
  DateTime date;
  List<ExerciseSession> exercises;
  int rating;
  String generalNotes;

  WorkoutSessionRecord({
    required this.id,
    required this.routineName,
    required this.date,
    required this.exercises,
    required this.rating,
    this.generalNotes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineName': routineName,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'rating': rating,
        'generalNotes': generalNotes,
      };

  factory WorkoutSessionRecord.fromJson(Map<String, dynamic> json) => WorkoutSessionRecord(
        id: json['id'],
        routineName: json['routineName'],
        date: DateTime.parse(json['date']),
        exercises: (json['exercises'] as List).map((e) => ExerciseSession.fromJson(e)).toList(),
        rating: json['rating'],
        generalNotes: json['generalNotes'] ?? '',
      );
}

class Routine {
  String id;
  String name;
  List<String> exerciseIds;

  Routine({required this.id, required this.name, required this.exerciseIds});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exerciseIds': exerciseIds,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'],
        name: json['name'],
        exerciseIds: List<String>.from(json['exerciseIds']),
      );
}

class BodyweightEntry {
  DateTime date;
  double weightKg;

  BodyweightEntry({required this.date, required this.weightKg});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
      };

  factory BodyweightEntry.fromJson(Map<String, dynamic> json) => BodyweightEntry(
        date: DateTime.parse(json['date']),
        weightKg: (json['weightKg'] as num).toDouble(),
      );
}
