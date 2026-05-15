import '../../domain/entities/referentiel_entry.dart';

class ReferentielModel extends ReferentielEntry {
  ReferentielModel({
    required super.id,
    required super.code,
    required super.label,
    required super.category,
    required super.isActive,
    required super.isCs,
    required super.isHz,
    required super.isChd,
    required super.isChud,
  });

  factory ReferentielModel.fromJson(Map<String, dynamic> json) {
    final String discipline = _extractDiscipline(json);
    return ReferentielModel(
      id: _asInt(json['id']),
      code: (json['code'] ?? '').toString().trim(),
      label: (json['name'] ?? json['nom_affiche'] ?? '').toString().trim(),
      category: mapCategory(discipline),
      isActive: _asBool(json['is_active']),
      isCs: _asBool(json['is_cs']),
      isHz: _asBool(json['is_hz']),
      isChd: _asBool(json['is_chd']),
      isChud: _asBool(json['is_chud']),
    );
  }

  static String mapCategory(String discipline) {
    final String normalized = discipline.trim().toUpperCase();
    if (normalized.contains('ACTE')) {
      return 'ACTE';
    }
    if (normalized.contains('RADIO')) {
      return 'RADIO';
    }
    if (normalized.contains('CIM')) {
      return 'CIM 10';
    }
    if (normalized.contains('PHARMACIE') || normalized.contains('PHARMACY')) {
      return 'PHARMACIE';
    }
    if (normalized.contains('LABO') ||
        normalized.contains('LABORATOIRE') ||
        normalized.contains('LABORATORY')) {
      return 'LABO';
    }
    return 'Tout';
  }

  static String _extractDiscipline(Map<String, dynamic> json) {
    const List<String> keys = <String>[
      'discipline',
      'category',
      'categorie',
      'type',
      'discipline_name',
      'disciplineLabel',
    ];

    for (final String key in keys) {
      final dynamic value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
