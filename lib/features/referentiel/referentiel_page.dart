import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/session/user_session.dart';
import '../../core/services/taka_usb_service.dart';

class ReferentielPage extends StatefulWidget {
  const ReferentielPage({super.key});

  @override
  State<ReferentielPage> createState() => _ReferentielPageState();
}

class _ReferentielPageState extends State<ReferentielPage> {
  static final Uri _syncUri =
      Uri.parse('https://archtpa.bridges-corp.cloud/api/sync-mobile');

  static const List<String> _tabs = <String>[
    'Tout',
    'CIM 10',
    'ACTE',
    'RADIO',
    'PHARMACIE',
    'LABO',
  ];

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedItemId;
  List<ReferentielItem> _items = <ReferentielItem>[];
  List<ReferentielItem> _cim10Items = <ReferentielItem>[];

  // Card reading functionality
  final TakaUsbService _takaUsb = TakaUsbService();
  String _cardStatus = 'Appuyez sur READ CARD pour lire la carte';
  bool _isCardLoading = false;
  Map<String, dynamic>? _cardData;

  @override
  void initState() {
    super.initState();
    _loadReferentiel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ReferentielItem>> _fetchReferentielItems(
    String token,
    String model,
  ) async {
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

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(ReferentielItem.fromJson)
        .where((ReferentielItem item) => item.isActive)
        .toList()
      ..sort((ReferentielItem a, ReferentielItem b) {
        final int categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        return a.displayLabel.toLowerCase().compareTo(
              b.displayLabel.toLowerCase(),
            );
      });
  }

  Future<void> _loadReferentiel() async {
    final String? token = UserSession.authToken.value;
    final String? structureType = UserSession.structureType.value;

    if (token == null || token.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Aucun token disponible. Veuillez scanner le QR code avant de consulter le referentiel.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<ReferentielItem> loadedItems = await _fetchReferentielItems(
        token,
        'Product',
      );
      final List<ReferentielItem> loadedCim10Items =
          await _fetchReferentielItems(
        token,
        'Cim_10',
      );

      setState(() {
        _items = loadedItems
            .where(
                (ReferentielItem item) => item.matchesStructure(structureType))
            .toList();
        _cim10Items = loadedCim10Items;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chargement du referentiel impossible: $error';
      });
    }
  }

  List<ReferentielItem> _filteredItems(String category) {
    final String query = _searchQuery.trim().toLowerCase();
    final List<ReferentielItem> sourceItems =
        category == 'CIM 10' ? _cim10Items : _items;

    return sourceItems.where((ReferentielItem item) {
      final bool matchesCategory = category == 'Tout' ||
          category == 'CIM 10' ||
          _normalizeCategory(item.category) == _normalizeCategory(category);
      final bool matchesSearch = query.isEmpty ||
          item.displayLabel.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  static String _normalizeCategory(String category) {
    return category.trim().toLowerCase().replaceAll(' ', '');
  }

  int _getInitialTabIndex() {
    final String? structureType =
        UserSession.structureType.value?.trim().toLowerCase();
    switch (structureType) {
      case 'cs':
        return 1; // CIM 10
      case 'hz':
        return 3; // RADIO
      case 'chd':
      case 'chud':
        return 2; // ACTE
      default:
        return 0; // Tout
    }
  }

  void _toggleFavorite(ReferentielItem item) {
    setState(() {
      item.isFavorite = !item.isFavorite;
    });
  }

  // Card reading methods
  Future<void> _readCard() async {
    setState(() {
      _isCardLoading = true;
      _cardStatus = "Connexion...";
      _cardData = null;
    });

    bool connected = await _takaUsb.connect();
    if (!connected) {
      setState(() {
        _cardStatus = "USB NON TROUVÉ";
        _isCardLoading = false;
      });
      return;
    }

    setState(() => _cardStatus = "USB CONNECTÉ...");

    String response = "AUCUNE PERMISSION";
    int retries = 10;
    while (retries-- > 0 && response == "AUCUNE PERMISSION") {
      await Future.delayed(const Duration(seconds: 1));
      response = await _takaUsb.readCard();
    }

    try {
      Map<String, dynamic> parsedData = _parseMRZResponse(response);
      setState(() {
        _cardData = parsedData;
        _cardStatus = "CARTE LUE AVEC SUCCÈS";
        _isCardLoading = false;
      });
    } catch (e) {
      setState(() {
        _cardStatus = "ERREUR: $e";
        _isCardLoading = false;
      });
    }
  }

  Future<void> _disconnectCard() async {
    await _takaUsb.disconnect();
    setState(() => _cardStatus = "DÉCONNECTÉ");
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

    var parsedData = _parseMRZ(mrzLine);

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
      var firstNameIdx = rev.indexOf('<<');
      if (firstNameIdx < 0) return parsedData;
      var firstName = rev.substring(0, firstNameIdx);
      rev = rev.replaceFirst(firstName, '');
      rev = rev.replaceFirst(RegExp(r'^<<+'), '');

      var lastNameIdx = _findFirstDigitIndex(rev);
      if (lastNameIdx < 0) return parsedData;
      var lastName = rev.substring(0, lastNameIdx);
      rev = rev.replaceFirst(lastName, '');
      if (rev.length > 1) rev = rev.substring(1);
      var nextPos = rev.indexOf('<');
      if (nextPos < 0) nextPos = rev.indexOf('N');

      if (nextPos < 0) nextPos = rev.length;
      var uniqueId = rev.substring(0, nextPos);
      rev = rev.replaceFirst(uniqueId, '');
      if (rev.length > 1) rev = rev.substring(1);
      var ccDateIdx = rev.indexOf('<');
      if (ccDateIdx < 0) ccDateIdx = rev.length;
      var ccDate = rev.substring(0, ccDateIdx);

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
      var cardNumIdx = rev.indexOf('<');
      if (cardNumIdx > 1) {
        var cardNumber = rev.substring(1, cardNumIdx);
        parsedData['cardId'] = cardNumber
            .split('')
            .reversed
            .join()
            .replaceAll(RegExp(r'[A-Za-z]+'), '');
      }

      var dateStr = parsedData['date_naissance'];
      if (dateStr != null && dateStr.length >= 6) {
        var yearSuffix = int.tryParse(dateStr.substring(0, 2)) ?? 0;
        var year = yearSuffix < 50 ? 2000 + yearSuffix : 1900 + yearSuffix;
        var month = dateStr.substring(2, 4);
        var day = dateStr.substring(4, 6);
        parsedData['date_naissance'] = '$day-$month-$year';
      }
    } catch (e) {
      debugPrint('Erreur lors du parsing MRZ: $e');
    }

    return parsedData;
  }

  int _findFirstDigitIndex(String str) {
    for (int i = 0; i < str.length; i++) {
      final code = str.codeUnitAt(i);
      if (code >= 48 && code <= 57) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: _getInitialTabIndex(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Referentiel')),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Image.asset('assets/logo_ministere.png', height: 40),
                  Image.asset('assets/logo_arch.png', height: 40),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFFE91E63),
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xFFE91E63),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                tabs: _tabs.map((String label) => Tab(text: label)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) => setState(() {
                  _searchQuery = value;
                }),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE91E63),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE91E63),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE91E63),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialCategoryContent(String category) {
    if (_cardData == null) {
      return _buildBlurredCardReadingInterface(category);
    }
    return _buildCategoryForm(category);
  }

  Widget _buildBlurredCardReadingInterface(String category) {
    return Stack(
      children: [
        // Blurred content
        Opacity(
          opacity: 0.3,
          child: _buildCategoryForm(category),
        ),
        // Card reading interface
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Color(0xFFE91E63),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lecture de carte requise pour $category',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _cardStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isCardLoading ? Colors.orange : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCardLoading ? null : _readCard,
                        icon: _isCardLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.nfc, size: 16),
                        label: Text(
                          _isCardLoading ? 'Lecture...' : 'READ CARD',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _disconnectCard,
                      icon: const Icon(Icons.usb_off, size: 16),
                      label: const Text('USB', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryForm(String category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Patient card
          if (_cardData != null) _buildPatientCard(),
          const SizedBox(height: 16),
          // Category specific section
          _buildCategorySection(category),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    final firstName = _cardData?['firstName'] ?? 'N/A';
    final lastName = _cardData?['lastName'] ?? 'N/A';
    final cardId = _cardData?['cardId'] ?? 'N/A';
    final birthDate = _cardData?['date_naissance'] ?? 'N/A';
    final gender = _cardData?['gender'] ?? 'N/A';
    final country = _cardData?['countryCode'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border.all(color: Colors.teal, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Affiliation",
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
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.teal.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("PATIENT ID", cardId),
                    const SizedBox(height: 8),
                    _buildInfoRow("DATE DE NAISSANCE", birthDate),
                    const SizedBox(height: 8),
                    _buildInfoRow("GENRE", gender),
                    const SizedBox(height: 8),
                    _buildInfoRow("PAYS", country),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "INFORMATIONS",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.teal.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Prénom", firstName),
                const Divider(height: 12),
                _buildDetailRow("Nom", lastName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final List<ReferentielItem> items = _filteredItems(category);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Aucun élément disponible')
          else
            ...items.map((item) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '[${item.code}] ${item.displayLabel}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item.isFavorite ? Icons.star : Icons.star_border,
                          color: item.isFavorite
                              ? const Color(0xFF00897B)
                              : Colors.grey,
                        ),
                        onPressed: () => _toggleFavorite(item),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
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
          "$label: ",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadReferentiel,
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      children: _tabs.map((String category) {
        if (category == 'PHARMACIE' ||
            category == 'LABO' ||
            category == 'RADIO') {
          return _buildSpecialCategoryContent(category);
        }
        final List<ReferentielItem> items = _filteredItems(category);
        return items.isEmpty
            ? const Center(child: Text('Aucun resultat'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final ReferentielItem item = items[index];
                  final bool isSelected = _selectedItemId == item.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? const Border(
                              right: BorderSide(
                                color: Color(0xFF2196F3),
                                width: 4,
                              ),
                            )
                          : null,
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedItemId = isSelected ? null : item.id;
                        });
                      },
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        '[${item.code}] ${item.displayLabel}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          item.isFavorite ? Icons.star : Icons.star_border,
                          color: item.isFavorite
                              ? const Color(0xFF00897B)
                              : Colors.grey,
                          size: 24,
                        ),
                        onPressed: () => _toggleFavorite(item),
                      ),
                    ),
                  );
                },
              );
      }).toList(),
    );
  }
}

class ReferentielItem {
  ReferentielItem({
    required this.id,
    required this.code,
    required this.label,
    required this.category,
    required this.isActive,
    required this.isCs,
    required this.isHz,
    required this.isChd,
    required this.isChud,
    this.isFavorite = false,
  });

  factory ReferentielItem.fromJson(Map<String, dynamic> json) {
    final String discipline = _extractDiscipline(json);
    return ReferentielItem(
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

  final int id;
  final String code;
  final String label;
  final String category;
  final bool isActive;
  final bool isCs;
  final bool isHz;
  final bool isChd;
  final bool isChud;
  bool isFavorite;

  String get displayLabel => label.isEmpty ? code : label;

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
