import 'package:flutter/material.dart';

import 'card_reading_page.dart';

class LaboratoirePage extends StatelessWidget {
  const LaboratoirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardReadingPage(
      title: 'Laboratoire',
      description:
          'La page Laboratoire est floutée pour ressembler à une carte. Appuyez sur le bouton ci-dessous pour lire la carte.',
    );
  }
}
