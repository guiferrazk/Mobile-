import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/leitor_qrcode_screen.dart';

void main() {
  // Sem câmera no ambiente de teste, o caminho testado é o de digitar o
  // código, que é o mesmo usado quando a câmera do aparelho não funciona.
  testWidgets('devolve o código digitado para a tela anterior', (tester) async {
    String? recebido;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              recebido = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeitorQrCodeScreen(
                    titulo: 'Ler Gabarito',
                    instrucao: 'Aponte a câmera para o QR Code do gabarito.',
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Aponte a câmera para o QR Code do gabarito.'), findsOneWidget);

    await tester.tap(find.text('Digitar código').first);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField), '  GABARITO|1|prova-n3-direito  ');
    await tester.tap(find.text('Confirmar'));
    await tester.pump(const Duration(seconds: 1));

    expect(recebido, 'GABARITO|1|prova-n3-direito');
  });
}
