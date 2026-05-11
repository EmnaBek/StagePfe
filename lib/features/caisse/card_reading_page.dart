import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/referentiel_service.dart';
import '../../core/services/taka_usb_service.dart';

class CardReadingPage extends StatefulWidget {
  const CardReadingPage({
    super.key,
    required this.title,
    required this.description,
    this.backgroundColor = const Color(0xFFF1F8E9),
    this.accentColor = const Color(0xFF155724),
    this.referentielCategory,
  });

  final String title;
  final String description;
  final Color backgroundColor;
  final Color accentColor;
  final String? referentielCategory;

  @override
  State<CardReadingPage> createState() => _CardReadingPageState();
}

class _CardReadingPageState extends State<CardReadingPage> {
  final TakaUsbService _takaUsb = TakaUsbService();
  String _cardStatus = 'Appuyez sur READ CARD pour lire la carte';
  bool _isCardLoading = false;
  bool _isReferentielLoading = false;
  String? _referentielError;
  Map<String, dynamic>? _cardData;
  List<ReferentielEntry> _referentielItems = <ReferentielEntry>[];
  final List<String> _selectedReferentielItems = <String>[];

  @override
  void initState() {
    super.initState();
    _loadReferentiel();
  }

  Future<void> _loadReferentiel() async {
    final String? category = widget.referentielCategory;
    if (category == null) return;

    setState(() {
      _isReferentielLoading = true;
      _referentielError = null;
    });

    try {
      final List<ReferentielEntry> items =
          await ReferentielService.fetchProductsByCategory(category);
      if (!mounted) return;
      setState(() {
        _referentielItems = items;
        _isReferentielLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isReferentielLoading = false;
        _referentielError = 'Chargement du référentiel impossible: $error';
      });
    }
  }

  Future<void> _readCard() async {
    setState(() {
      _isCardLoading = true;
      _cardStatus = 'Connexion...';
      _cardData = null;
    });

    bool connected = await _takaUsb.connect();
    if (!connected) {
      setState(() {
        _cardStatus = 'USB NON TROUVÉ';
        _isCardLoading = false;
      });
      return;
    }

    setState(() => _cardStatus = 'USB CONNECTÉ...');

    String response = 'AUCUNE PERMISSION';
    int retries = 10;
    while (retries-- > 0 && response == 'AUCUNE PERMISSION') {
      await Future.delayed(const Duration(seconds: 1));
      response = await _takaUsb.readCard();
    }

    try {
      final Map<String, dynamic> parsedData = _parseMRZResponse(response);
      setState(() {
        _cardData = parsedData;
        _cardStatus = 'CARTE LUE AVEC SUCCÈS';
        _isCardLoading = false;
      });
    } catch (e) {
      setState(() {
        _cardStatus = 'ERREUR: $e';
        _isCardLoading = false;
      });
    }
  }

  Future<void> _disconnectCard() async {
    await _takaUsb.disconnect();
    setState(() {
      _cardStatus = 'DÉCONNECTÉ';
      _isCardLoading = false;
    });
  }

  Map<String, dynamic> _parseMRZResponse(String response) {
    final lines = response.split('\n');
    String mrzLine = '';
    String faceImageUri = '';
    String faceBase64 = '';

    for (final String line in lines) {
      if (line.startsWith('MRZ:')) {
        mrzLine = line.substring(4).trim();
      } else if (line.startsWith('FACE:')) {
        faceImageUri = line.substring(5).trim();
      } else if (line.startsWith('FACE_BASE64:')) {
        faceBase64 = line.substring(12).trim();
      }
    }

    if (mrzLine.isEmpty) {
      throw Exception('Aucune donnée MRZ trouvée');
    }

    final parsedData = _parseMRZ(mrzLine);
    if (faceImageUri.isNotEmpty && faceImageUri != 'null') {
      parsedData['faceImagePath'] = faceImageUri;
    } else if (faceBase64.isNotEmpty) {
      parsedData['faceImageBase64'] = faceBase64;
    }
    return parsedData;
  }

  Map<String, dynamic> _parseMRZ(String mrz) {
    final parsedData = {
      'mrz': mrz,
      'countryCode': null,
      'cardId': null,
      'gender': null,
      'deliveryDate': null,
      'uniqueId': null,
      'lastName': null,
      'firstName': null,
      'date_naissance': null,
    };

    try {
      var rev = mrz.split('').reversed.join();
      rev = rev.replaceAll(RegExp(r'^<+'), '');
      final int firstNameIdx = rev.indexOf('<<');
      if (firstNameIdx < 0) return parsedData;
      final String firstName = rev.substring(0, firstNameIdx);
      rev = rev.replaceFirst(firstName, '');
      rev = rev.replaceFirst(RegExp(r'^<<+'), '');

      final int lastNameIdx = _findFirstDigitIndex(rev);
      if (lastNameIdx < 0) return parsedData;
      final String lastName = rev.substring(0, lastNameIdx);
      rev = rev.replaceFirst(lastName, '');
      if (rev.length > 1) rev = rev.substring(1);

      int nextPos = rev.indexOf('<');
      if (nextPos < 0) nextPos = rev.indexOf('N');
      if (nextPos < 0) nextPos = rev.length;
      final String uniqueId = rev.substring(0, nextPos);
      rev = rev.replaceFirst(uniqueId, '');
      if (rev.length > 1) rev = rev.substring(1);

      int ccDateIdx = rev.indexOf('<');
      if (ccDateIdx < 0) ccDateIdx = rev.length;
      String ccDate = rev.substring(0, ccDateIdx);

      parsedData['firstName'] =
          firstName.split('').reversed.join().replaceAll('<', ' ');
      parsedData['lastName'] = lastName.split('').reversed.join();
      parsedData['uniqueId'] =
          uniqueId.split('').reversed.join().replaceAll('<', '');
      rev = rev.replaceFirst(ccDate, '');

      if (ccDate.contains('NEB')) {
        ccDate = ccDate.replaceAll('NEB', '');
        parsedData['countryCode'] = 'BEN';
      } else if (ccDate.contains('EB')) {
        ccDate = ccDate.replaceAll('EB', '');
        parsedData['countryCode'] = 'BEN';
      }

      ccDate = ccDate.split('').reversed.join();
      if (ccDate.length >= 6) {
        parsedData['date_naissance'] = ccDate.substring(0, 6);
      }

      if (ccDate.contains('M')) {
        parsedData['gender'] = 'M';
      } else if (ccDate.contains('F')) {
        parsedData['gender'] = 'F';
      }

      rev = rev.replaceAll(RegExp(r'^<+'), '');
      final int cardNumIdx = rev.indexOf('<');
      if (cardNumIdx > 1) {
        final String cardNumber = rev.substring(1, cardNumIdx);
        parsedData['cardId'] = cardNumber
            .split('')
            .reversed
            .join()
            .replaceAll(RegExp(r'[A-Za-z]+'), '');
      }

      final String? dateStr = parsedData['date_naissance'];
      if (dateStr != null && dateStr.length >= 6) {
        final int yearSuffix = int.tryParse(dateStr.substring(0, 2)) ?? 0;
        final int year =
            yearSuffix < 50 ? 2000 + yearSuffix : 1900 + yearSuffix;
        final String month = dateStr.substring(2, 4);
        final String day = dateStr.substring(4, 6);
        parsedData['date_naissance'] = '$day-$month-$year';
      }
    } catch (_) {
      // Ignore parsing errors and return partial results.
    }

    return parsedData;
  }

  int _findFirstDigitIndex(String str) {
    for (int i = 0; i < str.length; i++) {
      final int code = str.codeUnitAt(i);
      if (code >= 48 && code <= 57) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        color: widget.backgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _cardData == null
                ? _buildBlurredCardReadingInterface()
                : _buildCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurredCardReadingInterface() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.accentColor.withOpacity(0.12)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.person_outline,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 92,
                        height: 118,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPlaceholderField(widthFactor: 1),
                            const SizedBox(height: 10),
                            _buildPlaceholderField(widthFactor: 0.92),
                            const SizedBox(height: 10),
                            _buildPlaceholderField(widthFactor: 0.84),
                            const SizedBox(height: 10),
                            _buildPlaceholderField(widthFactor: 0.76),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPlaceholderSection(
                    title: 'Affiliation',
                    rows: const [0.95, 0.72],
                  ),
                  const SizedBox(height: 14),
                  _buildPlaceholderSection(
                    title: 'Libelles et total des actes',
                    rows: const [1, 1, 0.68],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCardLoading ? null : _readCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCardLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lire la carte',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _cardStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      _isCardLoading ? Colors.orange.shade800 : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _disconnectCard,
                icon: const Icon(Icons.usb_off, size: 18),
                label: const Text('Déconnecter USB'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  backgroundColor: Colors.white.withOpacity(0.88),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderSection({
    required String title,
    required List<double> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: widget.accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          for (final widthFactor in rows) ...[
            _buildPlaceholderField(widthFactor: widthFactor),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderField({required double widthFactor}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final String firstName = _cardData?['firstName'] ?? 'N/A';
    final String lastName = _cardData?['lastName'] ?? 'N/A';
    final String cardId = _cardData?['cardId'] ?? 'N/A';
    final String birthDate = _cardData?['date_naissance'] ?? 'N/A';
    final String gender = _cardData?['gender'] ?? 'N/A';
    final String country = _cardData?['countryCode'] ?? 'N/A';

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.backgroundColor.withOpacity(0.9),
              border: Border.all(
                  color: widget.accentColor.withOpacity(0.7), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Affiliation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.person, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoContainer(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('PATIENT ID', cardId),
                          const SizedBox(height: 8),
                          _buildInfoRow('DATE DE NAISSANCE', birthDate),
                          const SizedBox(height: 8),
                          _buildInfoRow('GENRE', gender),
                          const SizedBox(height: 8),
                          _buildInfoRow('PAYS', country),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReferentielPanel(),
                const SizedBox(height: 16),
                const Text(
                  'INFORMATIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Prénom', firstName),
                      const Divider(height: 12),
                      _buildDetailRow('Nom', lastName),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _disconnectCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Déconnecter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cardData = null;
                      _cardStatus = 'Appuyez sur READ CARD pour lire la carte';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Nouvelle lecture'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildReferentielPanel() {
    if (widget.referentielCategory == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: widget.accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Référentiel ${widget.title}',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isReferentielLoading ? null : _showReferentielPicker,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          if (_isReferentielLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (_referentielError != null) ...[
            Text(
              _referentielError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: _loadReferentiel,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ] else if (_selectedReferentielItems.isEmpty)
            const Text('Aucun élément sélectionné.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedReferentielItems
                  .map(
                    (String item) => Chip(
                      label: Text(item),
                      onDeleted: () => setState(
                        () => _selectedReferentielItems.remove(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _showReferentielPicker() {
    final TextEditingController searchCtrl = TextEditingController();
    List<ReferentielEntry> filteredItems = _referentielItems;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          void filterItems(String value) {
            final String query = value.trim().toLowerCase();
            setDialogState(() {
              filteredItems = query.isEmpty
                  ? _referentielItems
                  : _referentielItems
                      .where((ReferentielEntry item) =>
                          item.displayLabel.toLowerCase().contains(query) ||
                          item.code.toLowerCase().contains(query))
                      .toList();
            });
          }

          return AlertDialog(
            title: Text('Choisir ${widget.title.toLowerCase()}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: filterItems,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rechercher dans le référentiel...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text('Aucun élément trouvé.'))
                        : ListView.separated(
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, int index) {
                              final ReferentielEntry item = filteredItems[index];
                              return ListTile(
                                dense: true,
                                title: Text(item.displayLabel),
                                subtitle:
                                    item.code.isEmpty ? null : Text(item.code),
                                trailing: Icon(
                                  _selectedReferentielItems
                                          .contains(item.displayValue)
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: widget.accentColor,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (!_selectedReferentielItems
                                        .contains(item.displayValue)) {
                                      _selectedReferentielItems
                                          .add(item.displayValue);
                                    }
                                  });
                                  Navigator.pop(dialogContext);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchCtrl.dispose);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildPhotoContainer() {
    final String? faceImagePath = _cardData?['faceImagePath'];
    final String? faceImageBase64 = _cardData?['faceImageBase64'];

    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(
          color: widget.accentColor.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: faceImagePath != null && faceImagePath.isNotEmpty
          ? Image.file(
              File(faceImagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, size: 40, color: Colors.grey);
              },
            )
          : faceImageBase64 != null && faceImageBase64.isNotEmpty
              ? Image.memory(
                  base64Decode(faceImageBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person,
                        size: 40, color: Colors.grey);
                  },
                )
              : const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }
}
