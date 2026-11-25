
import 'package:mobile/models/alternativa_model.dart';

/// Representa uma questão na ordem recebida pelo aluno.
class QuestaoVariada {
  final String questaoId;
  final String enunciado;
  final List<Alternativa> alternativas;

  /// Relaciona a posição embaralhada com o índice original.
  final List<int> indicesOriginais;

  const QuestaoVariada({
    required this.questaoId,
    required this.enunciado,
    required this.alternativas,
    required this.indicesOriginais,
  });

  /// Converte o índice marcado na folha para o índice
  /// da alternativa original, utilizado na correção.
  int? indiceOriginal(int? indiceMarcado) {
    if (indiceMarcado == null ||
        indiceMarcado < 0 ||
        indiceMarcado >= indicesOriginais.length) {
      return null;
    }

    return indicesOriginais[indiceMarcado];
  }

  Map<String, dynamic> toMap() {
    return {
      'questaoId': questaoId,
      'enunciado': enunciado,
      'alternativas': alternativas
          .map((alternativa) => alternativa.toMap())
          .toList(),
      'indicesOriginais': indicesOriginais,
    };
  }

  factory QuestaoVariada.fromMap(Map<String, dynamic> map) {
    final dadosAlternativas =
        map['alternativas'] as List<dynamic>? ?? [];

    final dadosIndices =
        map['indicesOriginais'] as List<dynamic>? ?? [];

    return QuestaoVariada(
      questaoId: map['questaoId'] as String? ?? '',
      enunciado: map['enunciado'] as String? ?? '',
      alternativas: dadosAlternativas
          .map(
            (item) => Alternativa.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      indicesOriginais: dadosIndices
          .map((item) => (item as num).toInt())
          .toList(),
    );
  }
}

/// Variação individual vinculada a uma prova e a um aluno.
class VariacaoProva {
  final String provaId;
  final String alunoId;
  final List<QuestaoVariada> questoes;

  const VariacaoProva({
    required this.provaId,
    required this.alunoId,
    required this.questoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'provaId': provaId,
      'alunoId': alunoId,
      'questoes': questoes
          .map((questao) => questao.toMap())
          .toList(),
    };
  }

  factory VariacaoProva.fromMap(Map<String, dynamic> map) {
    final dadosQuestoes =
        map['questoes'] as List<dynamic>? ?? [];

    return VariacaoProva(
      provaId: map['provaId'] as String? ?? '',
      alunoId: map['alunoId'] as String? ?? '',
      questoes: dadosQuestoes
          .map(
            (item) => QuestaoVariada.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
