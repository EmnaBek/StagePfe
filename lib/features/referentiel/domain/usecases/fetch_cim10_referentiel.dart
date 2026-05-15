import '../entities/referentiel_entry.dart';
import '../repositories/referentiel_repository.dart';

class FetchCim10Referentiel {
  FetchCim10Referentiel(this._repository);

  final ReferentielRepository _repository;

  Future<List<ReferentielEntry>> call() => _repository.fetchCim10();
}
