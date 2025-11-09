import 'package:happy_tracks/core/constants/app_constants.dart';

/// Represents a single timeslot entry for happiness tracking
/// Each timeslot covers a 30-minute period in a day
class Timeslot {
  final int? id;
  final String date; // Format: yyyy-MM-dd
  final int timeIndex; // 0-47 (representing 48 half-hour slots)
  final String time; // Format: HH:mm (e.g., "09:00", "09:30")
  final int happinessScore; // 0-100
  final String? description; // Optional note about what user was doing
  final DateTime createdAt;
  final DateTime updatedAt;

  const Timeslot({
    this.id,
    required this.date,
    required this.timeIndex,
    required this.time,
    this.happinessScore = 0,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a Timeslot from database map
  factory Timeslot.fromMap(Map<String, dynamic> map) {
    return Timeslot(
      id: map['id'] as int?,
      date: map['date'] as String,
      timeIndex: map['time_index'] as int,
      time: map['time'] as String,
      happinessScore: map['happiness_score'] as int? ?? 0,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert Timeslot to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'time_index': timeIndex,
      'time': time,
      'happiness_score': happinessScore,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  Timeslot copyWith({
    int? id,
    String? date,
    int? timeIndex,
    String? time,
    int? happinessScore,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timeslot(
      id: id ?? this.id,
      date: date ?? this.date,
      timeIndex: timeIndex ?? this.timeIndex,
      time: time ?? this.time,
      happinessScore: happinessScore ?? this.happinessScore,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if timeslot has been tracked (score > 0 or has description)
  bool get isTracked => happinessScore > 0 || description != null;

  /// Validate happiness score is within range
  bool get hasValidScore =>
      happinessScore >= AppConstants.minHappinessScore &&
      happinessScore <= AppConstants.maxHappinessScore;

  @override
  String toString() {
    return 'Timeslot(id: $id, date: $date, time: $time, score: $happinessScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Timeslot &&
        other.id == id &&
        other.date == date &&
        other.timeIndex == timeIndex &&
        other.time == time &&
        other.happinessScore == happinessScore &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      timeIndex,
      time,
      happinessScore,
      description,
    );
  }
}
