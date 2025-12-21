/// Unified Pet Data Envelope - Master data structure for routing
class PetDataEnvelope {
  final String targetPet;
  final PetDataCategory category;
  final Map<String, dynamic> dataPayload;
  final PetDataMetadata metadata;

  PetDataEnvelope({
    required this.targetPet,
    required this.category,
    required this.dataPayload,
    required this.metadata,
  });

  factory PetDataEnvelope.fromJson(Map<String, dynamic> json) {
    return PetDataEnvelope(
      targetPet: json['target_pet'] as String,
      category: _parseCategoryFrom(json['category'] as String),
      dataPayload: json['data_payload'] as Map<String, dynamic>,
      metadata: PetDataMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_pet': targetPet,
      'category': category.toString().split('.').last,
      'data_payload': dataPayload,
      'metadata': metadata.toJson(),
    };
  }

  static PetDataCategory _parseCategoryFrom(String categoryStr) {
    switch (categoryStr.toUpperCase()) {
      case 'RACA_ID':
        return PetDataCategory.racaId;
      case 'SAUDE':
        return PetDataCategory.saude;
      case 'CARDAPIO':
        return PetDataCategory.cardapio;
      case 'AGENDA':
        return PetDataCategory.agenda;
      default:
        throw ArgumentError('Unknown category: $categoryStr');
    }
  }
}

/// Pet Data Category - 4 main data buckets
enum PetDataCategory {
  racaId,   // Breed & ID
  saude,    // Health records
  cardapio, // Weekly menu
  agenda,   // Schedule/events
}

/// Metadata for pet data envelope
class PetDataMetadata {
  final bool hasExistingProfile;
  final DateTime timestamp;
  final String? linkedBreedData;
  final double? confidenceScore;

  PetDataMetadata({
    required this.hasExistingProfile,
    required this.timestamp,
    this.linkedBreedData,
    this.confidenceScore,
  });

  factory PetDataMetadata.fromJson(Map<String, dynamic> json) {
    return PetDataMetadata(
      hasExistingProfile: json['has_existing_profile'] as bool? ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      linkedBreedData: json['linked_breed_data'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_existing_profile': hasExistingProfile,
      'timestamp': timestamp.toIso8601String(),
      if (linkedBreedData != null) 'linked_breed_data': linkedBreedData,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
    };
  }
}
