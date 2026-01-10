import 'package:hive/hive.dart';
part 'partner_model.g.dart';

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
  
  @HiveField(16)
  final String? email;
  
  @HiveField(17)
  final List<String> teamMembers; // Lista de nomes de atendentes/veterinários

  @HiveField(18)
  final String? website;

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
    this.email,
    required this.address,
    required this.openingHours,
    this.rating = 5.0,
    this.photos = const [],
    this.specialties = const [],
    this.metadata = const {},
    this.isFavorite = false,
    this.teamMembers = const [],
    this.website,
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
      email: json['email'],
      address: json['address'] ?? '',
      openingHours: Map<String, dynamic>.from(json['opening_hours'] ?? {}),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      photos: List<String>.from(json['photos'] ?? []),
      specialties: List<String>.from(json['specialties'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isFavorite: json['is_favorite'] ?? false,
      teamMembers: List<String>.from(json['team_members'] ?? []),
      website: json['website'],
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
      'email': email,
      'address': address,
      'opening_hours': openingHours,
      'rating': rating,
      'photos': photos,
      'specialties': specialties,
      'metadata': metadata,
      'is_favorite': isFavorite,
      'team_members': teamMembers,
      'website': website,
    };
  }

  PartnerModel copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? category,
    double? latitude,
    double? longitude,
    String? phone,
    String? whatsapp,
    String? instagram,
    String? email,
    String? address,
    Map<String, dynamic>? openingHours,
    double? rating,
    List<String>? photos,
    List<String>? specialties,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    List<String>? teamMembers,
    String? website,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      email: email ?? this.email,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      photos: photos ?? this.photos,
      specialties: specialties ?? this.specialties,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      teamMembers: teamMembers ?? this.teamMembers,
      website: website ?? this.website,
    );
  }
}
