import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/partner_service.dart';

final partnerServiceProvider = Provider<PartnerService>((ref) {
  return PartnerService();
});
