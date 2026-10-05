class DailyActivityRecord {
  final String date; // YYYY-MM-DD
  final int steps;
  final int goal;
  final double distanceKm;
  final int activeMinutes;
  final int calories;
  final int morningSteps;
  final int afternoonSteps;
  final int eveningSteps;
  final DateTime updatedAt;

  const DailyActivityRecord({
    required this.date,
    required this.steps,
    this.goal = 10000,
    required this.distanceKm,
    required this.activeMinutes,
    required this.calories,
    this.morningSteps = 0,
    this.afternoonSteps = 0,
    this.eveningSteps = 0,
    required this.updatedAt,
  });

  double get progressRatio => (goal > 0) ? (steps / goal).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (goal > 0) ? ((steps / goal) * 100).toInt() : 0;
  bool get isGoalCompleted => goal > 0 && steps >= goal;

  factory DailyActivityRecord.empty(String date) {
    return DailyActivityRecord(
      date: date,
      steps: 0,
      goal: 10000,
      distanceKm: 0.0,
      activeMinutes: 0,
      calories: 0,
      morningSteps: 0,
      afternoonSteps: 0,
      eveningSteps: 0,
      updatedAt: DateTime.now(),
    );
  }

  int get updatedTimestamp => updatedAt.millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
      'goal': goal,
      'distanceKm': distanceKm,
      'activeMinutes': activeMinutes,
      'calories': calories,
      'morning': morningSteps,
      'afternoon': afternoonSteps,
      'evening': eveningSteps,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedTimestamp': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DailyActivityRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedUpdated;
    if (json['updatedTimestamp'] != null && json['updatedTimestamp'] is num) {
      parsedUpdated = DateTime.fromMillisecondsSinceEpoch((json['updatedTimestamp'] as num).toInt());
    } else if (json['updatedAt'] != null) {
      parsedUpdated = DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now();
    } else {
      parsedUpdated = DateTime.now();
    }

    return DailyActivityRecord(
      date: json['date']?.toString() ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      goal: (json['goal'] as num?)?.toInt() ?? 10000,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      morningSteps: (json['morning'] as num?)?.toInt() ?? (json['morningSteps'] as num?)?.toInt() ?? 0,
      afternoonSteps: (json['afternoon'] as num?)?.toInt() ?? (json['afternoonSteps'] as num?)?.toInt() ?? 0,
      eveningSteps: (json['evening'] as num?)?.toInt() ?? (json['eveningSteps'] as num?)?.toInt() ?? 0,
      updatedAt: parsedUpdated,
    );
  }

  DailyActivityRecord copyWith({
    String? date,
    int? steps,
    int? goal,
    double? distanceKm,
    int? activeMinutes,
    int? calories,
    int? morningSteps,
    int? afternoonSteps,
    int? eveningSteps,
    DateTime? updatedAt,
  }) {
    return DailyActivityRecord(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      distanceKm: distanceKm ?? this.distanceKm,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      calories: calories ?? this.calories,
      morningSteps: morningSteps ?? this.morningSteps,
      afternoonSteps: afternoonSteps ?? this.afternoonSteps,
      eveningSteps: eveningSteps ?? this.eveningSteps,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
