import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/screens/resultado_prova_screen.dart';

Questao _questao(String id, int correta) => Questao(
      id: id,
      enunciado: 'Questão $id',
      alternativas: [
        for (var i = 0; i < 4; i++)
          Alternativa(texto: 'Alt $i', isCorreta: i == correta),
      ],
    );

void main() {
  testWidgets('mostra nota, acertos e status de cada questão', (tester) async {
    final questoes = [_questao('q1', 0), _questao('q2', 1), _questao('q3', 2)];
    final resultado = Resultado.corrigir(
      provaId: 'p1',
      aluno: Aluno(id: 'a1', nome: 'Maria', email: 'm@x.com', matricula: '1'),
      questoes: questoes,
      respostas: {'q1': 0, 'q2': 3, 'q3': null},
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ResultadoProvaScreen(resultado: resultado, questoes: questoes),
    ));

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('3.3'), findsOneWidget);
    expect(find.text('Acertos: 1 de 3'), findsOneWidget);
    expect(find.text('Correta'), findsOneWidget);
    expect(find.text('Incorreta'), findsOneWidget);
    expect(find.text('Em branco'), findsOneWidget);
  });
}
