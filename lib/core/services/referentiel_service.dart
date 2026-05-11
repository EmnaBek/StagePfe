import 'dart:convert';

import 'package:http/http.dart' as http;

import '../session/user_session.dart';

class ReferentielService {
  ReferentielService._();

  static final Uri _syncUri =
      Uri.parse('https://archtpa.bridges-corp.cloud/api/sync-mobile');

  static Future<List<ReferentielEntry>> fetchItems(
    String model, {
    bool filterByStructure = true,
  }) async {
    final String? token = UserSession.authToken.value;
    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Aucun token disponible. Veuillez scanner le QR code avant de charger le référentiel.',
      );
    }

    final http.Response response = await http.post(
      _syncUri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'token': token,
        'model': model,
        'lastSync': '1970-01-01 00:00:00',
        'serial': '999',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> rawResults = decoded is Map<String, dynamic>
        ? (decoded['results'] as List<dynamic>? ?? <dynamic>[])
        : <dynamic>[];
    final String? structureType = UserSession.structureType.value;

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(ReferentielEntry.fromJson)
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

  static Future<List<ReferentielEntry>> fetchCim10() {
    return fetchItems('Cim_10', filterByStructure: false);
  }

  static Future<List<ReferentielEntry>> fetchProductsByCategory(
    String category,
  ) async {
    final String normalizedCategory = normalizeCategory(category);
    final List<ReferentielEntry> products = await fetchItems('Product');
    return products
        .where((ReferentielEntry item) =>
            normalizeCategory(item.category) == normalizedCategory)
        .toList();
  }

  static String normalizeCategory(String category) {
    return category.trim().toUpperCase().replaceAll(' ', '');
  }
}

class ReferentielEntry {
  ReferentielEntry({
    required this.id,
    required this.code,
    required this.label,
    required this.category,
    required this.isActive,
    required this.isCs,
    required this.isHz,
    required this.isChd,
    required this.isChud,
  });

  factory ReferentielEntry.fromJson(Map<String, dynamic> json) {
    final String discipline = _extractDiscipline(json);
    return ReferentielEntry(
      id: _asInt(json['id']),
      code: (json['code'] ?? '').toString().trim(),
      label: (json['name'] ?? json['nom_affiche'] ?? '').toString().trim(),
      category: _mapCategory(discipline),
      isActive: _asBool(json['is_active']),
      isCs: _asBool(json['is_cs']),
      isHz: _asBool(json['is_hz']),
      isChd: _asBool(json['is_chd']),
      isChud: _asBool(json['is_chud']),
    );
  }

  final int id;
  final String code;
  final String label;
  final String category;
  final bool isActive;
  final bool isCs;
  final bool isHz;
  final bool isChd;
  final bool isChud;

  String get displayLabel => label.isEmpty ? code : label;

  String get displayValue =>
      code.isEmpty ? displayLabel : '$code - $displayLabel';

  bool matchesStructure(String? structureType) {
    switch ((structureType ?? '').trim().toLowerCase()) {
      case 'cs':
        return isCs;
      case 'hz':
        return isHz;
      case 'chd':
        return isChd;
      case 'chud':
        return isChud;
      default:
        return true;
    }
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

  static String _mapCategory(String discipline) {
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
