import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/layout_folha.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';
import 'package:mobile/services/correcao_folha.dart';
import 'package:mobile/services/leitor_marcacoes.dart';

import 'apoio/folha_sintetica.dart';

const _largura = 1000;
const _altura = 1333;

final _aluno = Aluno(
  id: 'aluno1',
  nome: 'Ana Beatriz Souza',
  email: 'ana@email.com',
  matricula: '2024001',
);

/// Prova com [total] questões. A alternativa certa de cada questão, na ordem
/// original, é `q % alternativas`. A variação do aluno embaralha questões e
/// alternativas com a [semente], como faz o VariacaoProvaService.
({Prova prova, VariacaoProva variacao}) _provaEmbaralhada(
  int total, {
  int semente = 7,
  int Function(int questao)? alternativas,
}) {
  final aleatorio = math.Random(semente);
  final ids = [for (var q = 0; q < total; q++) 'q$q'];
  final prova = Prova(id: 'provaN3', titulo: 'Avaliação 1', questaoIds: ids);

  final ordemQuestoes = [...ids]..shuffle(aleatorio);
  final questoes = <QuestaoVariada>[];
  for (final id in ordemQuestoes) {
    final q = int.parse(id.substring(1));
    final n = alternativas?.call(q) ?? 4;
    final originais = [
      for (var a = 0; a < n; a++)
        Alternativa(texto: 'Alternativa $a', isCorreta: a == q % n),
    ];
    final ordem = List.generate(n, (a) => a)..shuffle(aleatorio);
    questoes.add(
      QuestaoVariada(
        questaoId: id,
        enunciado: 'Questão $id',
        alternativas: [for (final a in ordem) originais[a]],
        indicesOriginais: ordem,
      ),
    );
  }

  return (
    prova: prova,
    variacao: VariacaoProva(
      provaId: prova.id,
      alunoId: _aluno.id,
      questoes: questoes,
    ),
  );
}

/// Posição, na folha, da alternativa certa de cada questão da variação.
List<int> _certasNaFolha(VariacaoProva variacao) => [
  for (final q in variacao.questoes)
    q.alternativas.indexWhere((a) => a.isCorreta),
];

/// Lê a foto e monta o resultado, como a tela faz ao conferir.
Resultado _lerEConferir(Prova prova, VariacaoProva variacao, Uint8List foto) {
  final lidas = LeitorMarcacoes.ler(
    foto,
    alternativasPorQuestao: [
      for (final q in variacao.questoes) q.alternativas.length,
    ],
  );

  return CorrecaoFolha.corrigir(
    prova: prova,
    aluno: _aluno,
    variacao: variacao,
    marcadas: {
      for (var i = 0; i < lidas.respostas.length; i++)
        if (lidas.respostas[i] != null) i: lidas.respostas[i]!,
    },
  );
}

/// O resultado esperado a partir do que o aluno pintou na folha.
Map<String, int?> _esperado(
  VariacaoProva variacao,
  Map<int, List<int>> pintadas,
) {
  return {
    for (var i = 0; i < variacao.questoes.length; i++)
      variacao.questoes[i].questaoId: (pintadas[i]?.length ?? 0) == 1
          ? variacao.questoes[i].indicesOriginais[pintadas[i]!.single]
          : null,
  };
}

void main() {
  group('Fluxo completo: folha pintada → leitura → resultado salvo', () {
    test('aluno acerta 15 de 20 questões embaralhadas', () {
      final (:prova, :variacao) = _provaEmbaralhada(20);
      final certas = _certasNaFolha(variacao);

      // Erra as questões 3, 7, 11, 15 e 19 da folha (marca a alternativa ao lado).
      final pintadas = {
        for (var i = 0; i < 20; i++)
          i: [i % 4 == 3 ? (certas[i] + 1) % 4 : certas[i]],
      };

      final foto =
          FolhaSintetica(
            alternativas: [
              for (final q in variacao.questoes) q.alternativas.length,
            ],
            pintadas: pintadas,
          ).foto(
            largura: _largura,
            altura: _altura,
            cantos: cantosDeFrente(_largura, _altura),
          );

      final resultado = _lerEConferir(prova, variacao, foto);

      expect(resultado.acertos, 15);
      expect(resultado.totalQuestoes, 20);
      expect(resultado.nota, 7.5);
      expect(resultado.respostas, _esperado(variacao, pintadas));
    });

    test('o dado salvo e lido de volta do Firestore é o mesmo', () {
      final (:prova, :variacao) = _provaEmbaralhada(10, semente: 3);
      final pintadas = {
        for (var i = 0; i < 10; i++) i: [i % 4],
      };

      final foto =
          FolhaSintetica(
            alternativas: List.filled(10, 4),
            pintadas: pintadas,
          ).foto(
            largura: _largura,
            altura: _altura,
            cantos: cantosDeFrente(_largura, _altura),
          );

      final salvo = _lerEConferir(prova, variacao, foto);
      final lido = Resultado.fromMap(salvo.toMap());

      expect(lido.id, 'provaN3_aluno1');
      expect(lido.alunoMatricula, '2024001');
      expect(lido.respostas, salvo.respostas);
      expect(lido.respostas, _esperado(variacao, pintadas));
      expect(lido.acertos, salvo.acertos);
      expect(lido.nota, salvo.nota);
    });

    test('folha cheia: 40 questões com até 5 alternativas', () {
      final (:prova, :variacao) = _provaEmbaralhada(
        LayoutFolha.maxQuestoes,
        semente: 11,
        alternativas: (q) => q % 2 == 0 ? 5 : 4,
      );
      final alternativas = [
        for (final q in variacao.questoes) q.alternativas.length,
      ];
      final pintadas = {
        for (var i = 0; i < alternativas.length; i++)
          i: [(i * 7) % alternativas[i]],
      };

      final foto =
          FolhaSintetica(alternativas: alternativas, pintadas: pintadas).foto(
            largura: _largura,
            altura: _altura,
            cantos: cantosDeFrente(_largura, _altura),
          );

      final resultado = _lerEConferir(prova, variacao, foto);

      expect(resultado.respostas, _esperado(variacao, pintadas));
    });

    test(
      'questões em branco e com marcação dupla ficam em branco no resultado',
      () {
        final (:prova, :variacao) = _provaEmbaralhada(8, semente: 5);
        final certas = _certasNaFolha(variacao);
        final pintadas = {
          for (var i = 0; i < 8; i++) i: [certas[i]],
          2: <int>[],
          5: [0, 3],
        };

        final foto =
            FolhaSintetica(
              alternativas: List.filled(8, 4),
              pintadas: pintadas,
            ).foto(
              largura: _largura,
              altura: _altura,
              cantos: cantosDeFrente(_largura, _altura),
            );

        final resultado = _lerEConferir(prova, variacao, foto);

        expect(resultado.respostas, _esperado(variacao, pintadas));
        expect(resultado.respostas[variacao.questoes[2].questaoId], isNull);
        expect(resultado.respostas[variacao.questoes[5].questaoId], isNull);
        expect(resultado.acertos, 6);
      },
    );
  });

  group('Fotos em condições difíceis', () {
    final (:prova, :variacao) = _provaEmbaralhada(16, semente: 21);
    final alternativas = [
      for (final q in variacao.questoes) q.alternativas.length,
    ];
    final pintadas = {
      for (var i = 0; i < 16; i++) i: [(i * 3 + 1) % 4],
    };
    final esperado = _esperado(variacao, pintadas);

    void confere(Uint8List foto) {
      expect(_lerEConferir(prova, variacao, foto).respostas, esperado);
    }

    test('perspectiva forte, girada e com luz desigual', () {
      final c = cantosDeFrente(_largura, _altura, margem: 0.12);
      final perspectiva = [
        (c[0].$1 + 70, c[0].$2 + 30),
        (c[1].$1 - 50, c[1].$2 + 10),
        (c[2].$1 - 10, c[2].$2),
        (c[3].$1 + 20, c[3].$2 - 15),
      ];

      confere(
        FolhaSintetica(alternativas: alternativas, pintadas: pintadas).foto(
          largura: _largura,
          altura: _altura,
          cantos: girar(perspectiva, -12, _largura, _altura),
          gradienteLuz: 0.45,
        ),
      );
    });

    test('folha deitada na foto (girada 90 graus)', () {
      confere(
        FolhaSintetica(alternativas: alternativas, pintadas: pintadas).foto(
          largura: _altura,
          altura: _largura,
          cantos: girar(
            cantosDeFrente(_altura, _largura, margem: 0.05),
            90,
            _altura,
            _largura,
          ),
        ),
      );
    });

    test('caneta fraca e bolinha pintada só pela metade', () {
      confere(
        FolhaSintetica(
          alternativas: alternativas,
          pintadas: pintadas,
          tomTinta: 120,
          cobertura: 0.65,
        ).foto(
          largura: _largura,
          altura: _altura,
          cantos: cantosDeFrente(_largura, _altura),
        ),
      );
    });

    test('foto com bastante ruído', () {
      confere(
        FolhaSintetica(alternativas: alternativas, pintadas: pintadas).foto(
          largura: _largura,
          altura: _altura,
          cantos: cantosDeFrente(_largura, _altura),
          ruido: 30,
          semente: 4,
        ),
      );
    });

    test('foto de baixa resolução, com a folha pequena', () {
      confere(
        FolhaSintetica(alternativas: alternativas, pintadas: pintadas).foto(
          largura: 700,
          altura: 900,
          cantos: cantosDeFrente(700, 900, margem: 0.12),
        ),
      );
    });

    test('foto grande, como a de um celular, é reduzida antes de ler', () {
      confere(
        FolhaSintetica(
          alternativas: alternativas,
          pintadas: pintadas,
        ).foto(largura: 2250, altura: 3000, cantos: cantosDeFrente(2250, 3000)),
      );
    });

    test('várias folhas diferentes seguidas, todas lidas corretamente', () {
      for (var semente = 100; semente < 105; semente++) {
        final (:prova, :variacao) = _provaEmbaralhada(12, semente: semente);
        final aleatorio = math.Random(semente);
        final pintadas = {
          for (var i = 0; i < 12; i++) i: [aleatorio.nextInt(4)],
        };

        final foto =
            FolhaSintetica(
              alternativas: List.filled(12, 4),
              pintadas: pintadas,
            ).foto(
              largura: _largura,
              altura: _altura,
              cantos: girar(
                cantosDeFrente(_largura, _altura, margem: 0.1),
                aleatorio.nextDouble() * 16 - 8,
                _largura,
                _altura,
              ),
              gradienteLuz: aleatorio.nextDouble() * 0.4,
              semente: semente,
            );

        expect(
          _lerEConferir(prova, variacao, foto).respostas,
          _esperado(variacao, pintadas),
          reason: 'folha $semente',
        );
      }
    });
  });

  group('Fotos que não podem ser lidas', () {
    test('um dos quadrados dos cantos não aparece', () {
      final foto =
          FolhaSintetica(
            alternativas: List.filled(10, 4),
            pintadas: {
              0: [1],
            },
            marcadorAusente: 3,
          ).foto(
            largura: _largura,
            altura: _altura,
            cantos: cantosDeFrente(_largura, _altura),
          );

      expect(
        () => LeitorMarcacoes.ler(
          foto,
          alternativasPorQuestao: List.filled(10, 4),
        ),
        throwsA(
          isA<LeituraFolhaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('quatro quadrados pretos'),
          ),
        ),
      );
    });
  });
}
