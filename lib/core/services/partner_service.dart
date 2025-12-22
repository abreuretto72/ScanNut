import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/partner_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_apis/places.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PartnerService {
  static const String _boxName = 'partners_box';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
      // Removed _seedDataIfNeeded() to operate with real data/user entries only
    }
  }

  Future<void> clearAllPartners() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }

  List<PartnerModel> getAllPartners() {
    final box = Hive.box(_boxName);
    return box.values.map((e) => PartnerModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> savePartner(PartnerModel partner) async {
    final box = Hive.box(_boxName);
    await box.put(partner.id, partner.toJson());
  }

  PartnerModel? getPartner(String id) {
    final box = Hive.box(_boxName);
    final data = box.get(id);
    if (data != null) {
      return PartnerModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // -------------------------------------------------
  // Search partners using Google Places API (Google Maps APIs)
  // -------------------------------------------------
  // -------------------------------------------------
  // Search partners using Google Places API (Direct Use via HTTP)
  // -------------------------------------------------
  Future<List<PartnerModel>> searchPlaces({
    required double lat,
    required double lng,
    double radiusMeters = 20000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw 'Google Places API key não configurada no .env';
    }

    // Protocol 1: Endpoint
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=$radiusMeters'
        '&keyword=veterinario|petshop|clinica veterinaria'
        '&key=$apiKey');

    try {
      debugPrint('📡 Requesting Google Places API: $url'); // BE CAREFUL LOGGING KEYS IN PROD
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
             throw 'Google API Error: ${data['status']} - ${data['error_message'] ?? ''}';
        }

        final List results = data['results'] ?? [];
        debugPrint('✅ Google Places found ${results.length} results');

        // Protocol 3: Interface results
        return results.map((r) {
           final geo = r['geometry']?['location'];
           final lat = (geo?['lat'] ?? 0.0).toDouble();
           final lng = (geo?['lng'] ?? 0.0).toDouble();
           
           final bool isOpen = r['opening_hours']?['open_now'] ?? false;
           final num rating = r['rating'] ?? 0.0;

           return PartnerModel(
             id: r['place_id'] ?? '',
             name: r['name'] ?? 'Parceiro Pet',
             category: 'Veterinário', // Default to a valid category
             latitude: lat,
             longitude: lng,
             phone: '', // Will be fetched on detail if needed
             whatsapp: '',
             instagram: '',
             address: r['vicinity'] ?? '',
             rating: rating.toDouble(), // Add rating support if PartnerModel has it, else ignore or store in metadata
             specialties: [],
             openingHours: {
               'plantao24h': false, // Can't know for sure from basic search
               'raw': isOpen ? 'Aberto Agora' : 'Fechado',
             },
           );
        }).toList();
      } else {
        throw 'HTTP Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      debugPrint('❌ Erro na busca Google Places: $e');
      return [];
    }
  }

  // Legacy/Alias for compatibility
  Future<List<PartnerModel>> discoverNearbyPartners({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) async {
      // Protocol 2: Execution Logic - GPS checked in UI, now calling search
      return await searchPlaces(lat: lat, lng: lng, radiusMeters: radiusKm * 1000);
  }

  Future<void> deletePartner(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  /// The "Intelligent Filter" logic
  List<PartnerModel> suggestPartners(PetAnalysisResult analysis) {
    final all = getAllPartners();
    
    // 1. Detect issues from analysis
    bool hasWound = false;
    bool needsDiet = false;

    // Direct check in diagnosis
    if (analysis.analysisType == 'diagnosis') {
      final desc = (analysis.descricaoVisualDiag ?? '').toLowerCase();
      if (desc.contains('ferida') || desc.contains('pele') || desc.contains('dermatite') || desc.contains('coceira')) {
        hasWound = true;
      }
    }

    // 2. Filter partners
    if (hasWound) {
      return all.where((p) => p.specialties.contains('Dermatologia') || p.specialties.contains('Dermato')).toList();
    }

    if (needsDiet) {
       return all.where((p) => p.category == 'Pet Shop' && p.specialties.contains('Alimentação Natural')).toList();
    }

    // Fallback: show closest vets
    return all.where((p) => p.category == 'Veterinário').toList();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  List<PartnerModel> getPartnersInRadius({
    required double userLat,
    required double userLon,
    required double radiusKm,
    List<PartnerModel>? sourceList,
  }) {
    final list = sourceList ?? getAllPartners();
    return list.where((p) {
      final dist = calculateDistance(userLat, userLon, p.latitude, p.longitude);
      return dist <= radiusKm;
    }).toList();
  }
}
