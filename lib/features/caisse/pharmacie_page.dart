import 'package:flutter/material.dart';

import 'card_reading_page.dart';

class PharmaciePage extends StatelessWidget {
  const PharmaciePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardReadingPage(
      title: 'Pharmacie',
      description:
          'La page Pharmacie est floutée pour ressembler à une carte. Appuyez sur le bouton ci-dessous pour lire la carte.',
    );
  }
}
