import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'health_report_engine.dart';
import 'nutrition_report_engine.dart';
import 'analysis_report_engine.dart';
import 'travel_report_engine.dart';
import 'identity_plans_report_engine.dart';
import 'gallery_report_engine.dart';
import 'agenda_partners_report_engine.dart';
import 'occurrences_report_engine.dart';

import 'walk_report_engine.dart';

enum ReportType {
  health,
  nutrition,
  analysis,
  travel,
  identityPlans,
  gallery,
  agendaPartners,
  occurrences,
  walk,
}

class ReportMicroApps {
  static Future<pw.Document> generate({
    required ReportType type,
    required PetProfileExtended profile,
    required AppLocalizations l10n,
  }) async {
    switch (type) {
      case ReportType.health:
        return HealthReportEngine.generate(profile, l10n);
      case ReportType.nutrition:
        return NutritionReportEngine.generate(profile, l10n);
      case ReportType.analysis:
        return AnalysisReportEngine.generate(profile, l10n);
      case ReportType.travel:
        return TravelReportEngine.generate(profile, l10n);
      case ReportType.identityPlans:
        return IdentityPlansReportEngine.generate(profile, l10n);
      case ReportType.gallery:
        return GalleryReportEngine.generate(profile, l10n);
      case ReportType.agendaPartners:
        return AgendaPartnersReportEngine.generate(profile, l10n);
      case ReportType.occurrences:
        return OccurrencesReportEngine.generate(profile, l10n);
      case ReportType.walk:
        return ScanWalkReportEngine.generate(profile, l10n);
    }
  }
}
