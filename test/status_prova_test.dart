import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/models/status_prova.dart';
import 'package:mobile/screens/relatorio_provas_screen.dart';

const _p1 = Prova(id: 'p1', titulo: 'Avaliação 1', questaoIds: ['q1', 'q2']);
const _p2 = Prova(id: 'p2', titulo: 'Avaliação 2', questaoIds: ['q1', 'q2']);
const _p3 = Prova(id: 'p3', titulo: 'Avaliação 3', questaoIds: ['q1', 'q2']);

Resultado _resultado(String provaId, String alunoId, int acertos) {
  return Resultado(
    provaId: provaId,
    alunoId: alunoId,
    alunoNome: 'Aluno $alunoId',
    alunoMatricula: alunoId,
    respostas: const {},
    acertos: acertos,
    totalQuestoes: 2,
  );
}

void main() {
  group('Cálculo do status', () {
    test('conta corrigidos entre os alunos que receberam a prova', () {
      final status = StatusProva.calcular(
        provas: [_p1],
        alunosComProva: {
          'p1': {'a1', 'a2', 'a3'},
        },
        resultados: [_resultado('p1', 'a1', 2), _resultado('p1', 'a2', 1)],
      );

      expect(status.single.corrigidos, 2);
      expect(status.single.total, 3);
      expect(status.single.media, 7.5);
      expect(status.single.situacao, SituacaoCorrecao.emAndamento);
      expect(status.single.progresso, closeTo(2 / 3, 1e-9));
    });

    test('todos corrigidos: correção concluída', () {
      final status = StatusProva.calcular(
        provas: [_p1],
        alunosComProva: {
          'p1': {'a1', 'a2'},
        },
        resultados: [_resultado('p1', 'a1', 2), _resultado('p1', 'a2', 0)],
      );

      expect(status.single.situacao, SituacaoCorrecao.concluida);
      expect(status.single.media, 5);
    });

    test('ninguém corrigido ainda: não iniciada, sem média', () {
      final status = StatusProva.calcular(
        provas: [_p1],
        alunosComProva: {
          'p1': {'a1'},
        },
        resultados: const [],
      );

      expect(status.single.situacao, SituacaoCorrecao.naoIniciada);
      expect(status.single.media, isNull);
    });

    test('aluno corrigido sem variação também entra no total', () {
      final status = StatusProva.calcular(
        provas: [_p1],
        alunosComProva: {
          'p1': {'a1'},
        },
        resultados: [_resultado('p1', 'a1', 2), _resultado('p1', 'a9', 2)],
      );

      expect(status.single.corrigidos, 2);
      expect(status.single.total, 2);
      expect(status.single.situacao, SituacaoCorrecao.concluida);
    });

    test('resultados de outras provas não contam', () {
      final status = StatusProva.calcular(
        provas: [_p1, _p2],
        alunosComProva: {
          'p1': {'a1', 'a2'},
          'p2': {'a1'},
        },
        resultados: [_resultado('p2', 'a1', 2)],
      );

      final p1 = status.firstWhere((s) => s.provaId == 'p1');
      expect(p1.corrigidos, 0);
      expect(p1.total, 2);
    });

    test('prova sem alunos não aparece', () {
      final status = StatusProva.calcular(
        provas: [_p1, _p2],
        alunosComProva: {
          'p1': {'a1'},
        },
        resultados: const [],
      );

      expect(status.map((s) => s.provaId), ['p1']);
    });

    test(
      'em andamento primeiro, depois não iniciadas e por último concluídas',
      () {
        final status = StatusProva.calcular(
          provas: [_p1, _p2, _p3],
          alunosComProva: {
            'p1': {'a1'},
            'p2': {'a1', 'a2'},
            'p3': {'a1'},
          },
          resultados: [_resultado('p1', 'a1', 2), _resultado('p2', 'a1', 2)],
        );

        expect(status.map((s) => s.provaId), ['p2', 'p3', 'p1']);
      },
    );
  });

  group('Status no relatório', () {
    Future<void> abrir(WidgetTester tester) {
      return tester.pumpWidget(
        MaterialApp(
          home: RelatorioProvasScreen(
            listarResultados: () => Stream.value([
              _resultado('p1', 'a1', 2),
              _resultado('p1', 'a2', 1),
            ]),
            carregarProvas: () async => [
              (prova: _p1, alunos: {'a1', 'a2', 'a3'}),
              (prova: _p2, alunos: <String>{}),
            ],
          ),
        ),
      );
    }

    testWidgets('mostra quantos alunos foram corrigidos e a situação', (
      tester,
    ) async {
      await abrir(tester);
      await tester.pumpAndSettle();

      expect(find.text('STATUS DAS PROVAS'), findsOneWidget);
      expect(find.text('Avaliação 1'), findsOneWidget);
      expect(find.text('2 de 3 alunos corrigidos · Média 7.5'), findsOneWidget);
      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.text('RESULTADOS POR ALUNO'), findsOneWidget);
      // A prova sem alunos não aparece no status.
      expect(find.text('Avaliação 2'), findsNothing);
    });

    testWidgets('se o status não carregar, a lista de resultados continua', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RelatorioProvasScreen(
            listarResultados: () => Stream.value([_resultado('p1', 'a1', 2)]),
            carregarProvas: () async => throw StateError('sem conexão'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STATUS DAS PROVAS'), findsNothing);
      expect(find.text('Aluno a1'), findsOneWidget);
    });

    testWidgets('tocar no aluno abre a correção dele', (tester) async {
      final ana = Resultado(
        provaId: 'p1',
        alunoId: 'a1',
        alunoNome: 'Ana Souza',
        alunoMatricula: '2024001',
        respostas: const {'q1': 1, 'q2': null},
        acertos: 1,
        totalQuestoes: 2,
      );
      String? provaBuscada;

      await tester.pumpWidget(
        MaterialApp(
          home: RelatorioProvasScreen(
            listarResultados: () => Stream.value([ana]),
            carregarProvas: () async => const [],
            carregarQuestoes: (provaId) async {
              provaBuscada = provaId;
              return [
                Questao(
                  id: 'q1',
                  enunciado: 'Primeira',
                  alternativas: [
                    Alternativa(texto: 'A', isCorreta: false),
                    Alternativa(texto: 'B', isCorreta: true),
                  ],
                ),
                Questao(
                  id: 'q2',
                  enunciado: 'Segunda',
                  alternativas: [
                    Alternativa(texto: 'A', isCorreta: true),
                    Alternativa(texto: 'B', isCorreta: false),
                  ],
                ),
              ];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      expect(provaBuscada, 'p1');
      expect(find.text('Resultado da Correção'), findsOneWidget);
      expect(find.text('Acertos: 1 de 2'), findsOneWidget);
      expect(find.text('Correta'), findsOneWidget);
      expect(find.text('Em branco'), findsOneWidget);
    });
  });
}
