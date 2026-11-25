import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';

class CorrecaoFolhaException implements Exception {
  final String mensagem;

  CorrecaoFolhaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Transforma as respostas da folha do aluno no resultado que é salvo no
/// Firestore.
///
/// A folha segue a ordem embaralhada da variação do aluno. O resultado guarda,
/// para cada questão, o índice da alternativa na ordem original, que é o que
/// as estatísticas e relatórios usam.
class CorrecaoFolha {
  /// [marcadas]: posição da questão na folha → alternativa marcada na folha
  /// (as duas começando em 0). Questões ausentes ficam em branco.
  static Resultado corrigir({
    required Prova prova,
    required Aluno aluno,
    required VariacaoProva variacao,
    required Map<int, int> marcadas,
  }) {
    if (variacao.provaId != prova.id || variacao.alunoId != aluno.id) {
      throw CorrecaoFolhaException(
        'A variação não corresponde à prova e ao aluno identificados.',
      );
    }
    if (variacao.questoes.isEmpty) {
      throw CorrecaoFolhaException('A prova do aluno não tem questões.');
    }

    final respostas = <String, int?>{};
    var acertos = 0;

    for (var i = 0; i < variacao.questoes.length; i++) {
      final questao = variacao.questoes[i];

      // A resposta certa vem da própria variação, a mesma impressa na prova
      // do aluno, para a nota não mudar se a questão for editada depois.
      final certaNaFolha = questao.alternativas.indexWhere((a) => a.isCorreta);
      final certaOriginal = questao.indiceOriginal(certaNaFolha);
      if (certaOriginal == null) {
        throw CorrecaoFolhaException(
          'A questão ${i + 1} não tem alternativa correta cadastrada.',
        );
      }

      final marcadaOriginal = questao.indiceOriginal(marcadas[i]);
      respostas[questao.questaoId] = marcadaOriginal;
      if (marcadaOriginal == certaOriginal) acertos++;
    }

    return Resultado(
      provaId: prova.id,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
      alunoMatricula: aluno.matricula,
      respostas: respostas,
      acertos: acertos,
      totalQuestoes: variacao.questoes.length,
    );
  }

  /// Questões da folha (começando em 0) que ficaram sem resposta.
  static List<int> emBranco(VariacaoProva variacao, Map<int, int> marcadas) {
    return [
      for (var i = 0; i < variacao.questoes.length; i++)
        if (variacao.questoes[i].indiceOriginal(marcadas[i]) == null) i,
    ];
  }
}
