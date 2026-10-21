class BodyMeasurements {
  DateTime date;
  double heightCm;
  double weightKg;
  double chestCm;
  double waistCm;
  double hipsCm;
  double bicepsCm;
  double thighsCm;
  double calvesCm;
  double shouldersCm;

  BodyMeasurements({
    required this.date,
    this.heightCm = 187.0,
    this.weightKg = 92.0,
    this.chestCm = 105.0,
    this.waistCm = 84.0,
    this.hipsCm = 98.0,
    this.bicepsCm = 38.0,
    this.thighsCm = 62.0,
    this.calvesCm = 39.0,
    this.shouldersCm = 120.0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipsCm': hipsCm,
        'bicepsCm': bicepsCm,
        'thighsCm': thighsCm,
        'calvesCm': calvesCm,
        'shouldersCm': shouldersCm,
      };

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) => BodyMeasurements(
        date: DateTime.parse(json['date']),
        heightCm: (json['heightCm'] ?? 187.0).toDouble(),
        weightKg: (json['weightKg'] ?? 92.0).toDouble(),
        chestCm: (json['chestCm'] ?? 105.0).toDouble(),
        waistCm: (json['waistCm'] ?? 84.0).toDouble(),
        hipsCm: (json['hipsCm'] ?? 98.0).toDouble(),
        bicepsCm: (json['bicepsCm'] ?? 38.0).toDouble(),
        thighsCm: (json['thighsCm'] ?? 62.0).toDouble(),
        calvesCm: (json['calvesCm'] ?? 39.0).toDouble(),
        shouldersCm: (json['shouldersCm'] ?? 120.0).toDouble(),
      );
}

enum MuscleGroup { chest, back, shoulders, biceps, triceps, legs, core }

class MuscleActivity {
  final MuscleGroup group;
  final int setVolumeLast7Days;

  MuscleActivity({required this.group, required this.setVolumeLast7Days});

  // Heatmap-Intensität (0.0 bis 1.0)
  double get intensityRatio => (setVolumeLast7Days / 15.0).clamp(0.0, 1.0);
}
