import '../entities/referentiel_entry.dart';
import '../repositories/referentiel_repository.dart';

class FetchReferentielItems {
  FetchReferentielItems(this._repository);

  final ReferentielRepository _repository;

  Future<List<ReferentielEntry>> call(
    String model, {
    bool filterByStructure = true,
  }) {
    return _repository.fetchItems(
      model,
      filterByStructure: filterByStructure,
    );
  }
}
