import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:interface_stage/app/injection.dart';
import 'package:interface_stage/app/routes.dart';
import 'package:interface_stage/features/validation/domain/entities/qr_token_validation_result.dart';

class QrTokenValidationPage extends StatefulWidget {
  const QrTokenValidationPage({super.key});

  @override
  State<QrTokenValidationPage> createState() => _QrTokenValidationPageState();
}

class _QrTokenValidationPageState extends State<QrTokenValidationPage> {
  final TextEditingController _endpointController = TextEditingController();
  late final MobileScannerController _scannerController;

  bool _scanLocked = false;
  bool _isLoading = false;

  String? _rawQrValue;
  String? _token;
  String? _serverResponse;
  String? _error;
  String? _jwtDecodeNote;
  Map<String, dynamic>? _decodedTokenClaims;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_scanLocked || _isLoading || !mounted) return;

    final String? rawValue =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _scanLocked = true;
      _isLoading = _endpointController.text.trim().isNotEmpty;
      _rawQrValue = rawValue;
      _token = null;
      _decodedTokenClaims = null;
      _jwtDecodeNote = null;
      _serverResponse = null;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _scanLocked = result.token != null;
        _rawQrValue = result.rawQrValue;
        _token = result.token;
        _decodedTokenClaims = result.decodedClaims;
        _jwtDecodeNote = result.jwtDecodeNote;
        _serverResponse = result.serverResponse;
        _error = result.error;
      });


      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _scanLocked = false;
        _error = 'Erreur réseau: $error';
        _serverResponse = null;
      });

  }

  Future<void> _openDashboard() async {
    await _scannerController.stop();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _resetScan() async {
    await _scannerController.start();
    if (!mounted) return;

    setState(() {
      _scanLocked = false;
      _isLoading = false;

      _rawQrValue = null;
      _token = null;
      _decodedTokenClaims = null;
      _jwtDecodeNote = null;
      _serverResponse = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> infoWidgets = <Widget>[];

    if (_rawQrValue != null) {
      infoWidgets.add(SelectableText('QR brut: $_rawQrValue'));
      infoWidgets.add(const SizedBox(height: 6));
    }

    if (_token != null) {
      infoWidgets.add(SelectableText('Token: $_token'));
      infoWidgets.add(const SizedBox(height: 6));
    }

    if (_decodedTokenClaims != null) {
      infoWidgets.add(const Text('Token décodé (payload JWT):'));
      infoWidgets.add(const SizedBox(height: 4));
      infoWidgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(_decodedTokenClaims),
          ),
        ),
      );
      infoWidgets.add(const SizedBox(height: 8));
    }

    if (_jwtDecodeNote != null) {
      infoWidgets.add(
        Text(
          _jwtDecodeNote!,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      );
      infoWidgets.add(const SizedBox(height: 8));
    }

    if (_error != null) {
      infoWidgets.add(
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
      infoWidgets.add(const SizedBox(height: 6));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR + Token')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _endpointController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Endpoint API protégé (optionnel)',
                hintText: 'Laisser vide pour continuer après lecture du token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _scanLocked ? _resetScan : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescanner'),
                ),
                const SizedBox(width: 10),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            if (infoWidgets.isNotEmpty) ...<Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: infoWidgets,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_serverResponse != null)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_serverResponse!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
