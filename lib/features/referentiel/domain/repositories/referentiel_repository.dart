import '../entities/referentiel_entry.dart';

abstract class ReferentielRepository {
  Future<List<ReferentielEntry>> fetchItems(
    String model, {
    bool filterByStructure = true,
  });

  Future<List<ReferentielEntry>> fetchCim10();

  Future<List<ReferentielEntry>> fetchProductsByCategory(String category);
}
