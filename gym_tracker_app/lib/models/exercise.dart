class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final String equipment;
  final String description;
  final List<String> tips;
  final String animationAsset;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.equipment,
    required this.description,
    required this.tips,
    required this.animationAsset,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetMuscle': targetMuscle,
        'equipment': equipment,
        'description': description,
        'tips': tips,
        'animationAsset': animationAsset,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'],
        name: json['name'],
        targetMuscle: json['targetMuscle'],
        equipment: json['equipment'],
        description: json['description'],
        tips: List<String>.from(json['tips']),
        animationAsset: json['animationAsset'] ?? '',
      );
}

final List<Exercise> defaultExercises = [
  Exercise(
    id: '1',
    name: 'Bankdrücken (Langhantel)',
    targetMuscle: 'Brust',
    equipment: 'Langhantel',
    description: 'Klassische Grundübung für den Aufbau von Brust, vorderer Schulter und Trizeps.',
    tips: [
      'Schulterblätter fest zusammenziehen und nach unten drücken.',
      'Füße fest auf dem Boden verankern.',
      'Stange kontrolliert auf Höhe der unteren Brust ablassen.'
    ],
    animationAsset: 'assets/animations/bench_press.gif',
  ),
  Exercise(
    id: '2',
    name: 'Kniebeuge (Squat)',
    targetMuscle: 'Beine',
    equipment: 'Langhantel',
    description: 'Die Königsübung für die gesamte Beinmuskulatur und Rumpfstabilität.',
    tips: [
      'Brust raus, Rumpf fest anspannen.',
      'Knie in Richtung der Zehenspitzen drücken.',
      'Tiefe bis mindestens 90 Grad im Kniegelenk.'
    ],
    animationAsset: 'assets/animations/squat.gif',
  ),
  Exercise(
    id: '3',
    name: 'Kreuzheben (Deadlift)',
    targetMuscle: 'Rücken / Beine',
    equipment: 'Langhantel',
    description: 'Ganzkörperübung mit Fokus auf die gesamte hintere Muskelkette.',
    tips: [
      'Langhantel nah am Schienbein führen.',
      'Rücken absolut gerade halten (kein Rundrücken).',
      'Aus den Beinen herausdrücken und Hüfte durchstrecken.'
    ],
    animationAsset: 'assets/animations/deadlift.gif',
  ),
  Exercise(
    id: '4',
    name: 'Latzug zur Brust',
    targetMuscle: 'Rücken',
    equipment: 'Kabelzug',
    description: 'Effektive Übung für die Rückenbreite (Latissimus).',
    tips: [
      'Leicht nach hinten lehnen, Brust stolz machen.',
      'Stange aktiv mit den Ellenbogen nach unten ziehen.',
      'Kontrollierte Rückführung nach oben.'
    ],
    animationAsset: 'assets/animations/lat_pulldown.gif',
  ),
  Exercise(
    id: '5',
    name: 'Schulterdrücken (Langhantel)',
    targetMuscle: 'Schultern',
    equipment: 'Langhantel',
    description: 'Grundübung für starke und definierte Schultern.',
    tips: [
      'Rumpf und Gesäß fest anspannen, um ein Hohlkreuz zu vermeiden.',
      'Stange gerade nach oben über den Kopf führen.'
    ],
    animationAsset: 'assets/animations/overhead_press.gif',
  ),
];
