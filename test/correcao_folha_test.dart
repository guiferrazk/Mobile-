import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';
import 'package:mobile/services/correcao_folha.dart';

const _prova = Prova(
  id: 'provaN3',
  titulo: 'Avaliação 1',
  questaoIds: ['q1', 'q2', 'q3'],
);

final _aluno = Aluno(
  id: 'aluno1',
  nome: 'Ana Souza',
  email: 'ana@email.com',
  matricula: '2024001',
);

/// Questão com alternativas originais A-D, a certa na posição original
/// [certaOriginal], embaralhadas na ordem [ordem] (como no Firestore).
QuestaoVariada _questao(
  String id, {
  required int certaOriginal,
  required List<int> ordem,
}) {
  final originais = [
    for (var i = 0; i < 4; i++)
      Alternativa(texto: 'Original $i', isCorreta: i == certaOriginal),
  ];
  return QuestaoVariada(
    questaoId: id,
    enunciado: 'Questão $id',
    alternativas: [for (final i in ordem) originais[i]],
    indicesOriginais: ordem,
  );
}

/// q1: certa é a original 1, que na folha aparece na posição 3.
/// q2: certa é a original 0, que na folha aparece na posição 1.
/// q3: certa é a original 2, sem embaralhar.
final _variacao = VariacaoProva(
  provaId: 'provaN3',
  alunoId: 'aluno1',
  questoes: [
    _questao('q1', certaOriginal: 1, ordem: [2, 0, 3, 1]),
    _questao('q2', certaOriginal: 0, ordem: [3, 0, 1, 2]),
    _questao('q3', certaOriginal: 2, ordem: [0, 1, 2, 3]),
  ],
);

void main() {
  test(
    'converte a posição da folha para o índice original de cada questão',
    () {
      final resultado = CorrecaoFolha.corrigir(
        prova: _prova,
        aluno: _aluno,
        variacao: _variacao,
        marcadas: {0: 3, 1: 2, 2: 2},
      );

      // q1: folha 3 → original 1; q2: folha 2 → original 1; q3: folha 2 → original 2.
      expect(resultado.respostas, {'q1': 1, 'q2': 1, 'q3': 2});
    },
  );

  test('conta os acertos pela resposta certa da variação', () {
    final todasCertas = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 3, 1: 1, 2: 2},
    );
    final umaCerta = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 0, 1: 1, 2: 3},
    );

    expect(todasCertas.acertos, 3);
    expect(todasCertas.nota, 10);
    expect(umaCerta.acertos, 1);
    expect(umaCerta.totalQuestoes, 3);
  });

  test('questões sem resposta ficam em branco e contam como erro', () {
    final resultado = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 3},
    );

    expect(resultado.respostas, {'q1': 1, 'q2': null, 'q3': null});
    expect(resultado.acertos, 1);
    expect(CorrecaoFolha.emBranco(_variacao, {0: 3}), [1, 2]);
  });

  test('posição marcada que não existe na questão vira em branco', () {
    final resultado = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 9, 1: -1, 2: 2},
    );

    expect(resultado.respostas, {'q1': null, 'q2': null, 'q3': 2});
    expect(CorrecaoFolha.emBranco(_variacao, {0: 9, 1: -1, 2: 2}), [0, 1]);
  });

  test('o resultado fica ligado à prova e ao aluno identificados', () {
    final resultado = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 3, 1: 1, 2: 2},
    );

    expect(resultado.provaId, 'provaN3');
    expect(resultado.alunoId, 'aluno1');
    expect(resultado.alunoNome, 'Ana Souza');
    expect(resultado.alunoMatricula, '2024001');
    expect(resultado.id, 'provaN3_aluno1');
  });

  test('o que vai para o Firestore tem as respostas na ordem original', () {
    final resultado = CorrecaoFolha.corrigir(
      prova: _prova,
      aluno: _aluno,
      variacao: _variacao,
      marcadas: {0: 3, 2: 2},
    );

    final dados = resultado.toMap();

    expect(dados['provaId'], 'provaN3');
    expect(dados['alunoId'], 'aluno1');
    expect(dados['respostas'], {'q1': 1, 'q2': null, 'q3': 2});
    expect(dados['acertos'], 2);
    expect(dados['totalQuestoes'], 3);
  });

  test('recusa variação de outra prova ou de outro aluno', () {
    final deOutroAluno = VariacaoProva(
      provaId: 'provaN3',
      alunoId: 'outro',
      questoes: _variacao.questoes,
    );
    final deOutraProva = VariacaoProva(
      provaId: 'outra',
      alunoId: 'aluno1',
      questoes: _variacao.questoes,
    );

    for (final variacao in [deOutroAluno, deOutraProva]) {
      expect(
        () => CorrecaoFolha.corrigir(
          prova: _prova,
          aluno: _aluno,
          variacao: variacao,
          marcadas: {},
        ),
        throwsA(isA<CorrecaoFolhaException>()),
      );
    }
  });

  test('avisa quando a questão não tem alternativa correta cadastrada', () {
    final semCerta = VariacaoProva(
      provaId: 'provaN3',
      alunoId: 'aluno1',
      questoes: [
        QuestaoVariada(
          questaoId: 'q1',
          enunciado: 'Sem resposta certa',
          alternativas: [
            Alternativa(texto: 'A', isCorreta: false),
            Alternativa(texto: 'B', isCorreta: false),
          ],
          indicesOriginais: const [0, 1],
        ),
      ],
    );

    expect(
      () => CorrecaoFolha.corrigir(
        prova: _prova,
        aluno: _aluno,
        variacao: semCerta,
        marcadas: {0: 0},
      ),
      throwsA(
        isA<CorrecaoFolhaException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('questão 1'),
        ),
      ),
    );
  });
}
