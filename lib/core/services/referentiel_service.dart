import 'package:interface_stage/app/injection.dart';
import 'package:interface_stage/features/referentiel/data/repositories/referentiel_repository_impl.dart';
import 'package:interface_stage/features/referentiel/domain/entities/referentiel_entry.dart';

export 'package:interface_stage/features/referentiel/domain/entities/referentiel_entry.dart';

@Deprecated('Use referentiel domain use cases from AppInjection instead.')
class ReferentielService {
  ReferentielService._();

  static Future<List<ReferentielEntry>> fetchItems(
    String model, {
    bool filterByStructure = true,
  }) {
    return AppInjection.fetchReferentielItems(
      model,
      filterByStructure: filterByStructure,
    );
  }

  static Future<List<ReferentielEntry>> fetchCim10() {
    return AppInjection.fetchCim10Referentiel();
  }

  static Future<List<ReferentielEntry>> fetchProductsByCategory(
    String category,
  ) {
    return AppInjection.fetchProductsByCategory(category);
  }

  static String normalizeCategory(String category) {
    return ReferentielRepositoryImpl.normalizeCategory(category);
  }
}
