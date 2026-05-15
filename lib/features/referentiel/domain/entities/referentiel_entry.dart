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

  String get displayValue => code.isEmpty ? displayLabel : '$code - $displayLabel';

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
}
