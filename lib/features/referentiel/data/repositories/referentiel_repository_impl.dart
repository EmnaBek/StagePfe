import 'package:interface_stage/core/session/user_session.dart';

import '../../domain/entities/referentiel_entry.dart';
import '../../domain/repositories/referentiel_repository.dart';
import '../datasources/referentiel_remote_data_source.dart';

class ReferentielRepositoryImpl implements ReferentielRepository {
  ReferentielRepositoryImpl(this._remoteDataSource);

  final ReferentielRemoteDataSource _remoteDataSource;

  @override
  Future<List<ReferentielEntry>> fetchItems(
    String model, {
    bool filterByStructure = true,
  }) async {
    final String? token = UserSession.authToken.value;
    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Aucun token disponible. Veuillez scanner le QR code avant de charger le référentiel.',
      );
    }

    final String? structureType = UserSession.structureType.value;
    final List<ReferentielEntry> items = await _remoteDataSource.fetchItems(
      token: token,
      model: model,
    );

    return items
        .where(
          (ReferentielEntry item) =>
              item.isActive &&
              (!filterByStructure || item.matchesStructure(structureType)),
        )
        .toList()
      ..sort(
        (ReferentielEntry a, ReferentielEntry b) => a.displayLabel
            .toLowerCase()
            .compareTo(b.displayLabel.toLowerCase()),
      );
  }

  @override
  Future<List<ReferentielEntry>> fetchCim10() {
    return fetchItems('Cim_10', filterByStructure: false);
  }

  @override
  Future<List<ReferentielEntry>> fetchProductsByCategory(String category) async {
    final String normalizedCategory = normalizeCategory(category);
    final List<ReferentielEntry> products = await fetchItems('Product');
    return products
        .where(
          (ReferentielEntry item) =>
              normalizeCategory(item.category) == normalizedCategory,
        )
        .toList();
  }

  static String normalizeCategory(String category) {
    return category.trim().toUpperCase().replaceAll(' ', '');
  }
}
