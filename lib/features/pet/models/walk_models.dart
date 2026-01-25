// import 'package:google_maps_apis/places.dart';

enum WalkEventType {
  pee, // Xixi
  poo, // Fezes
  water, // Água
  others, // Outros (NEW)
  friend, // Amigo
  bark, // Latido
  hazard, // Perigo
  fight, // Brigas (NEW)
  rest // Descanso (legacy)
}

class WalkEvent {
  final DateTime timestamp;
  final WalkEventType type;
  final String? description;
  final String? photoPath; // For friends or poop
  final String? audioPath; // For barks
  final double? lat;
  final double? lng;
  // Bristol score for poo
  final int? bristolScore;

  WalkEvent({
    required this.timestamp,
    required this.type,
    this.description,
    this.photoPath,
    this.audioPath,
    this.lat,
    this.lng,
    this.bristolScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'description': description,
      'photoPath': photoPath,
      'audioPath': audioPath,
      'lat': lat,
      'lng': lng,
      'bristolScore': bristolScore,
    };
  }

  factory WalkEvent.fromJson(Map<String, dynamic> json) {
    return WalkEvent(
      timestamp: DateTime.parse(json['timestamp']),
      type: WalkEventType.values
          .firstWhere((e) => e.toString().split('.').last == json['type']),
      description: json['description'],
      photoPath: json['photoPath'],
      audioPath: json['audioPath'],
      lat: json['lat'],
      lng: json['lng'],
      bristolScore: json['bristolScore'],
    );
  }
}

class WalkSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<WalkEvent> events;
  final double distanceKm;
  final int caloriesBurned; // Estimated
  final String petId;
  final bool safetyCheckCompleted;

  WalkSession({
    required this.id,
    required this.startTime,
    required this.petId,
    this.endTime,
    this.events = const [],
    this.distanceKm = 0.0,
    this.caloriesBurned = 0,
    this.safetyCheckCompleted = false,
  });

  WalkSession copyWith({
    DateTime? endTime,
    List<WalkEvent>? events,
    double? distanceKm,
    int? caloriesBurned,
    bool? safetyCheckCompleted,
  }) {
    return WalkSession(
      id: id,
      startTime: startTime,
      petId: petId,
      endTime: endTime ?? this.endTime,
      events: events ?? this.events,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      safetyCheckCompleted: safetyCheckCompleted ?? this.safetyCheckCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'petId': petId,
      'events': events.map((e) => e.toJson()).toList(),
      'distanceKm': distanceKm,
      'caloriesBurned': caloriesBurned,
      'safetyCheckCompleted': safetyCheckCompleted,
    };
  }

  factory WalkSession.fromJson(Map<String, dynamic> json) {
    return WalkSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      petId: json['petId'] ?? json['pet_id'],
      events: (json['events'] as List?)
              ?.map((e) => WalkEvent.fromJson(e))
              .toList() ??
          [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      safetyCheckCompleted: json['safetyCheckCompleted'] ?? false,
    );
  }
}
