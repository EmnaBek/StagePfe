import 'dart:convert';

class QrTokenParser {
  const QrTokenParser();

  String extractToken(String value) {
    final Uri? uri = Uri.tryParse(value);
    final String? tokenFromQuery = uri?.queryParameters['token'];
    if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
      return _normalizeTokenCandidate(tokenFromQuery);
    }

    final dynamic decoded = _tryDecodeJson(value);
    if (decoded is Map<String, dynamic>) {
      final dynamic tokenField = decoded['token'];
      if (tokenField is String && tokenField.isNotEmpty) {
        return _normalizeTokenCandidate(tokenField);
      }
    }

    return _normalizeTokenCandidate(value);
  }

  Map<String, dynamic>? tryDecodeJwtPayload(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final String normalizedPayload = base64Url.normalize(parts[1]);
      final String payloadJson = utf8.decode(
        base64Url.decode(normalizedPayload),
      );
      final dynamic decoded = jsonDecode(payloadJson);

      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> claims = Map<String, dynamic>.from(decoded);
        final dynamic exp = claims['exp'];
        if (exp is int) {
          claims['exp_readable_utc'] = DateTime.fromMillisecondsSinceEpoch(
            exp * 1000,
            isUtc: true,
          ).toIso8601String();
        }
        return claims;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? extractDisplayName(Map<String, dynamic>? claims) {
    if (claims == null) return null;

    const List<String> preferredKeys = <String>[
      'displayName',
      'display_name',
      'displayname',
      'name',
      'fullName',
      'full_name',
      'username',
      'preferred_username',
      'given_name',
    ];

    String? searchIn(dynamic node) {
      if (node is Map<String, dynamic>) {
        for (final String key in preferredKeys) {
          final dynamic value = node[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        for (final dynamic child in node.values) {
          final String? nested = searchIn(child);
          if (nested != null) return nested;
        }
      } else if (node is List<dynamic>) {
        for (final dynamic child in node) {
          final String? nested = searchIn(child);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return searchIn(claims);
  }

  String? extractStructureType(Map<String, dynamic>? claims) {
    if (claims == null) return null;

    const List<String> preferredKeys = <String>[
      'structure_type',
      'structureType',
      'type_structure',
      'typeStructure',
      'structure',
      'structureCode',
      'structure_code',
      'facility_type',
      'facilityType',
      'user_structure_type',
    ];

    String? normalize(dynamic value) {
      if (value is! String) return null;
      final String normalized = value.trim().toLowerCase();
      const Set<String> allowed = <String>{'cs', 'hz', 'chd', 'chud'};
      return allowed.contains(normalized) ? normalized : null;
    }

    String? searchIn(dynamic node) {
      if (node is Map<String, dynamic>) {
        for (final String key in preferredKeys) {
          final String? candidate = normalize(node[key]);
          if (candidate != null) {
            return candidate;
          }
        }

        for (final dynamic child in node.values) {
          final String? nested = searchIn(child);
          if (nested != null) return nested;
        }
      } else if (node is List<dynamic>) {
        for (final dynamic child in node) {
          final String? nested = searchIn(child);
          if (nested != null) return nested;
        }
      } else {
        return normalize(node);
      }

      return null;
    }

    return searchIn(claims);
  }

  String formatBody(String body) {
    final dynamic decoded = _tryDecodeJson(body);
    if (decoded != null) {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    }
    return body;
  }

  String _normalizeTokenCandidate(String value) {
    final String compact = value
        .trim()
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '');

    final RegExp jwtPattern = RegExp(
      r'([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)',
    );
    final RegExpMatch? match = jwtPattern.firstMatch(compact);
    if (match != null) {
      return match.group(1) ?? compact;
    }

    return compact;
  }

  dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }
}
