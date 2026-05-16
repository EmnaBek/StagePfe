import 'package:flutter/material.dart';
import 'package:interface_stage/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:interface_stage/features/caisse/presentation/pages/caisse_page.dart';
import 'package:interface_stage/features/hospitalisation/presentation/pages/hospitalisation_page.dart';
import 'package:interface_stage/features/prestations/presentation/pages/prestations_page.dart';
import 'package:interface_stage/features/validation/presentation/pages/validation_page.dart';
import 'package:interface_stage/features/referentiel/presentation/pages/referentiel_page.dart';
import 'package:interface_stage/features/reclamation/presentation/pages/reclamation_page.dart';
import 'package:interface_stage/features/validation/presentation/pages/qr_token_validation_page.dart';

class AppRoutes {
  static const dashboard = '/';
  static const caisse = '/caisse';
  static const hospitalisation = '/hospitalisation';
  static const prestations = '/prestations';
  static const validation = '/validation';
  static const referentiel = '/referentiel';
  static const reclamation = '/reclamation';
  static const qrTokenValidation = '/qr-token-validation';

  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const DashboardPage(),
    caisse: (_) => const CaissePage(),
    hospitalisation: (_) => const HospitalisationPage(),
    prestations: (_) => const PrestationsPage(),
    validation: (_) => const ValidationPage(),
    referentiel: (_) => const ReferentielPage(),
    reclamation: (_) => const ReclamationPage(),
    qrTokenValidation: (_) => const QrTokenValidationPage(),
  };
}
