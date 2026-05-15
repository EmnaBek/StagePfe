import '../entities/referentiel_entry.dart';
import '../repositories/referentiel_repository.dart';

class FetchProductsByCategory {
  FetchProductsByCategory(this._repository);

  final ReferentielRepository _repository;

  Future<List<ReferentielEntry>> call(String category) {
    return _repository.fetchProductsByCategory(category);
  }
}
