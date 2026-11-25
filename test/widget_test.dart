
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/widgets/titulo_pagina.dart';

void main() {
  testWidgets(
    'Deve exibir o título da tela Corrigir Prova',
    (WidgetTester tester) async {
      // Monta um componente real do projeto.
      // Não precisa inicializar o Firebase.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const TituloPagina(
                icone: Icons.document_scanner_outlined,
                texto: 'Corrigir Prova',
              ),
            ),
          ),
        ),
      );

      // Verifica se o título aparece na tela.
      expect(
        find.text('Corrigir Prova'),
        findsOneWidget,
      );

      // Verifica se o ícone aparece na tela.
      expect(
        find.byIcon(Icons.document_scanner_outlined),
        findsOneWidget,
      );
    },
  );
}
