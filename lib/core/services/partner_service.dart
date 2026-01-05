import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/partner_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as sdk;
import 'package:http/http.dart' as http;
import 'dart:convert';

class PartnerService {
  static final PartnerService _instance = PartnerService._internal();
  factory PartnerService() => _instance;
  PartnerService._internal();

  static const String _boxName = 'partners_box';
  Box? _box;
  sdk.FlutterGooglePlacesSdk? _places;

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen && _places != null) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName, encryptionCipher: cipher);
      } else {
        _box = Hive.box(_boxName);
      }
      
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _places = sdk.FlutterGooglePlacesSdk(apiKey);
        logger.info('✅ Places SDK initialized');
      }

      debugPrint('✅ PartnerService initialized (Secure). Box Open: ${_box?.isOpen}');
    } catch (e, stack) {
      debugPrint('❌ CRITICAL: Failed to open Secure Partner Box: $e\n$stack');
    }
  }

  Box get _getBox {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
        return _box!;
      }
      throw Exception('PartnerService not initialized. Call init() first.');
    }
    return _box!;
  }

  Future<void> clearAllPartners() async {
    await _getBox.clear();
  }

  List<PartnerModel> getAllPartners() {
    return _getBox.values.map((e) => PartnerModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> savePartner(PartnerModel partner) async {
    await _getBox.put(partner.id, partner.toJson());
    await _getBox.flush();
  }

  PartnerModel? getPartner(String id) {
    final data = _getBox.get(id);
    if (data != null) {
      return PartnerModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // -------------------------------------------------
  // Powerful search using Google Places TextSearch + Pagination + Identity Headers
  // -------------------------------------------------
  Future<List<PartnerModel>> searchPlacesByText({
    String query = 'veterinario petshop clinica veterinaria',
    required double lat,
    required double lng,
    double radiusMeters = 20000,
    int maxPages = 3,
  }) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.error('Google Places API key não configurada no .env');
      throw 'Google Places API key não configurada no .env';
    }

    final List<PartnerModel> allFound = [];
    String? nextPageToken;
    int currentPage = 0;

    // Package Identity Headers for Security/SHA-1 validation
    final headers = {
      'X-Android-Package': 'com.multiversodigital.scannut',
      'X-Android-Cert': 'AC9222DC063FB2A500056B40AE6F3E44E2A95FF6', // Clean SHA-1
    };

    try {
      do {
        currentPage++;
        logger.info('📡 Efetuando TextSearch (Página $currentPage): Query: "$query"');
        
        final baseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';
        final params = <String, String>{
          'query': query,
          'location': '$lat,$lng',
          'radius': radiusMeters.toString(),
          'key': apiKey,
          'language': 'pt-BR',
        };

        if (nextPageToken != null) {
          params['pagetoken'] = nextPageToken;
          // Google dictates a short delay before the token becomes valid
          await Future.delayed(const Duration(seconds: 2));
        }

        final uri = Uri.parse(baseUrl).replace(queryParameters: params);
        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw 'HTTP ${response.statusCode}: ${response.body}';
        }

        final data = json.decode(response.body);
        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          throw 'Google API Error: ${data['status']} - ${data['error_message'] ?? ''}';
        }

        final List results = data['results'] ?? [];
        nextPageToken = data['next_page_token'];

        final List<PartnerModel> pageItems = results.map((r) {
          final geo = r['geometry']?['location'];
          final lat = (geo?['lat'] ?? 0.0).toDouble();
          final lng = (geo?['lng'] ?? 0.0).toDouble();
          final bool isOpen = r['opening_hours']?['open_now'] ?? false;
          final num rating = r['rating'] ?? 0.0;

          return PartnerModel(
            id: r['place_id'] ?? '',
            name: r['name'] ?? 'Parceiro Pet',
            category: 'Veterinário', 
            latitude: lat,
            longitude: lng,
            phone: '', 
            whatsapp: '',
            instagram: '',
            address: r['formatted_address'] ?? '',
            rating: rating.toDouble(),
            specialties: [],
            openingHours: {
              'plantao24h': false,
              'raw': isOpen ? 'Aberto Agora' : 'Fechado',
            },
          );
        }).toList();

        allFound.addAll(pageItems);
        logger.info('✅ Página $currentPage: Encontrados ${pageItems.length} parceiros.');

      } while (nextPageToken != null && currentPage < maxPages);

      logger.info('🏁 Busca Finalizada: Total de ${allFound.length} parceiros no Radar.');
      return allFound;

    } catch (e, stack) {
      logger.error('❌ Erro crítico no TextSearch', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Legacy/Alias updated to use the new power search
  Future<List<PartnerModel>> discoverNearbyPartners({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) async {
    return await searchPlacesByText(
      lat: lat, 
      lng: lng, 
      radiusMeters: radiusKm * 1000
    );
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
