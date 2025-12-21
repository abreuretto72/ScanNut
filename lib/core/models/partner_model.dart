import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class PartnerModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? cnpj;
  
  @HiveField(3)
  final String category; // Veterinário, Farmácia, Pet Shop, Banho e Tosa, Creche, Outros
  
  @HiveField(4)
  final double latitude;
  
  @HiveField(5)
  final double longitude;
  
  @HiveField(6)
  final String phone;
  
  @HiveField(7)
  final String? whatsapp;
  
  @HiveField(8)
  final String? instagram;
  
  @HiveField(9)
  final String address;
  
  @HiveField(10)
  final Map<String, dynamic> openingHours; // e.g., {'seg': '08:00-18:00', 'plantao24h': true}
  
  @HiveField(11)
  final double rating;
  
  @HiveField(12)
  final List<String> photos;
  
  @HiveField(13)
  final List<String> specialties; // ex: ['Dermatologia', 'Oncologia', 'Manipulados']
  
  @HiveField(14)
  final Map<String, dynamic> metadata;
  
  @HiveField(15)
  final bool isFavorite;

  PartnerModel({
    required this.id,
    required this.name,
    this.cnpj,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.whatsapp,
    this.instagram,
    required this.address,
    required this.openingHours,
    this.rating = 5.0,
    this.photos = const [],
    this.specialties = const [],
    this.metadata = const {},
    this.isFavorite = false,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] != null ? Map<String, dynamic>.from(json['coordinates']) : null;
    
    return PartnerModel(
      id: (json['partner_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? 'Sem Nome',
      cnpj: json['cnpj'],
      category: json['category'] ?? 'Outros',
      latitude: coords != null 
          ? (coords['lat'] as num?)?.toDouble() ?? 0.0 
          : (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: coords != null 
          ? (coords['lng'] as num?)?.toDouble() ?? 0.0 
          : (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? json['whatsapp'] ?? '',
      whatsapp: json['whatsapp'],
      instagram: json['instagram'],
      address: json['address'] ?? '',
      openingHours: Map<String, dynamic>.from(json['opening_hours'] ?? {}),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      photos: List<String>.from(json['photos'] ?? []),
      specialties: List<String>.from(json['specialties'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_id': id,
      'name': name,
      'cnpj': cnpj,
      'category': category,
      'coordinates': {
        'lat': latitude,
        'lng': longitude,
      },
      'whatsapp': whatsapp,
      'phone': phone,
      'instagram': instagram,
      'address': address,
      'opening_hours': openingHours,
      'rating': rating,
      'photos': photos,
      'specialties': specialties,
      'metadata': metadata,
      'is_favorite': isFavorite,
    };
  }
}
