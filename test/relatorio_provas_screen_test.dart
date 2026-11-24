import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/screens/relatorio_provas_screen.dart';

void main() {
  const mensagemVazia = 'Nenhuma prova corrigida ainda.';
  const mensagemErro = 'Não foi possível carregar as provas corrigidas.';
  final carregamento = find.byType(CircularProgressIndicator);
  final exportarExcel = find.text('Exportar Excel');
  final tentarNovamente = find.text('Tentar novamente');

  late StreamController<List<Resultado>> consulta;

  setUp(() {
    consulta = StreamController<List<Resultado>>();
    addTearDown(consulta.close);
  });

  Future<void> abrirRelatorio(
    WidgetTester tester,
    Stream<List<Resultado>> Function() listarResultados,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: RelatorioProvasScreen(listarResultados: listarResultados),
      ),
    );
  }

  testWidgets('mostra o carregamento enquanto a consulta não responde', (
    tester,
  ) async {
    await abrirRelatorio(tester, () => consulta.stream);

    expect(carregamento, findsOneWidget);
    expect(find.text(mensagemVazia), findsNothing);
    expect(find.text(mensagemErro), findsNothing);
    expect(exportarExcel, findsNothing);
  });

  testWidgets(
    'mostra o estado vazio quando a consulta retorna uma lista vazia',
    (tester) async {
      await abrirRelatorio(tester, () => consulta.stream);
      consulta.add([]);
      await tester.pump();

      expect(find.text(mensagemVazia), findsOneWidget);
      expect(carregamento, findsNothing);
      expect(exportarExcel, findsNothing);
    },
  );

  testWidgets('mostra a mensagem e a ação de nova tentativa após erro', (
    tester,
  ) async {
    await abrirRelatorio(tester, () => consulta.stream);
    consulta.addError(StateError('Falha na consulta'));
    await tester.pump();

    expect(find.text(mensagemErro), findsOneWidget);
    expect(tentarNovamente, findsOneWidget);
    expect(carregamento, findsNothing);
    expect(exportarExcel, findsNothing);
  });

  testWidgets('solicita uma nova consulta e se recupera do erro', (
    tester,
  ) async {
    final novaConsulta = StreamController<List<Resultado>>();
    addTearDown(novaConsulta.close);
    var chamadas = 0;

    await abrirRelatorio(tester, () {
      chamadas++;
      return chamadas == 1 ? consulta.stream : novaConsulta.stream;
    });
    expect(chamadas, 1);
    consulta.addError(StateError('Falha na primeira consulta'));
    await tester.pump();

    await tester.tap(tentarNovamente);
    await tester.pump();
    expect(chamadas, 2);

    novaConsulta.add([
      Resultado(
        alunoId: 'aluno-1',
        provaId: 'prova-1',
        alunoNome: 'Ana Souza',
        alunoMatricula: '000123',
        respostas: {},
        acertos: 2,
        totalQuestoes: 3,
      ),
    ]);
    await tester.pump();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(exportarExcel, findsOneWidget);
    expect(find.text(mensagemErro), findsNothing);
    expect(tentarNovamente, findsNothing);
  });
}
