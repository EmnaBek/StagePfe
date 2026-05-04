import 'package:flutter/material.dart';

import 'card_reading_page.dart';

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardReadingPage(
      title: 'Radio',
      description:
          'La page Radio est floutée pour ressembler à une carte. Appuyez sur le bouton ci-dessous pour lire la carte.',
    );
  }
}
