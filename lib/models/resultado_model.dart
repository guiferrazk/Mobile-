import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/questao_model.dart';

/// Resultado da correção da prova de um aluno. Liga a prova, o aluno e
/// as respostas marcadas na folha.
///
/// Cada aluno tem no máximo um resultado por prova: o id do documento é
/// formado por `provaId` e `alunoId` (ver [idPara]), então corrigir a
/// mesma folha de novo substitui o resultado anterior.
class Resultado {
  final String provaId;
  final String alunoId;

  /// Nome e matrícula copiados do aluno no momento da correção, para os
  /// relatórios não precisarem buscar cada aluno de novo.
  final String alunoNome;
  final String alunoMatricula;

  /// Alternativa marcada em cada questão: id da questão -> índice da
  /// alternativa na lista original da questão (antes de embaralhar).
  /// `null` quando a questão ficou em branco ou com marcação inválida.
  final Map<String, int?> respostas;

  final int acertos;
  final int totalQuestoes;
  final DateTime? corrigidoEm;

  Resultado({
    required this.provaId,
    required this.alunoId,
    required this.alunoNome,
    required this.alunoMatricula,
    required this.respostas,
    required this.acertos,
    required this.totalQuestoes,
    this.corrigidoEm,
  });

  String get id => idPara(provaId, alunoId);

  /// Nota de 0 a 10.
  double get nota => totalQuestoes == 0 ? 0 : acertos * 10 / totalQuestoes;

  static String idPara(String provaId, String alunoId) => '${provaId}_$alunoId';

  /// Corrige as [respostas] do [aluno] comparando com a alternativa
  /// correta de cada uma das [questoes] da prova.
  factory Resultado.corrigir({
    required String provaId,
    required Aluno aluno,
    required List<Questao> questoes,
    required Map<String, int?> respostas,
  }) {
    var acertos = 0;

    for (final questao in questoes) {
      final marcada = respostas[questao.id];
      final correta = questao.alternativas.indexWhere((a) => a.isCorreta);

      if (marcada != null && marcada == correta) {
        acertos++;
      }
    }

    return Resultado(
      provaId: provaId,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
      alunoMatricula: aluno.matricula,
      respostas: {
        for (final questao in questoes) questao.id: respostas[questao.id],
      },
      acertos: acertos,
      totalQuestoes: questoes.length,
    );
  }

  /// Converte o resultado para o formato salvo no Firestore.
  /// A data de correção é preenchida pelo serviço com o horário do servidor.
  Map<String, dynamic> toMap() {
    return {
      'provaId': provaId,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'alunoMatricula': alunoMatricula,
      'respostas': respostas,
      'acertos': acertos,
      'totalQuestoes': totalQuestoes,
      'nota': nota,
    };
  }

  /// Cria um resultado a partir de um documento do Firestore.
  /// O Timestamp é convertido pelo serviço e chega aqui em [corrigidoEm].
  factory Resultado.fromMap(Map<String, dynamic> map, {DateTime? corrigidoEm}) {
    final respostas = Map<String, dynamic>.from(map['respostas'] as Map? ?? {});

    return Resultado(
      provaId: map['provaId'] as String? ?? '',
      alunoId: map['alunoId'] as String? ?? '',
      alunoNome: map['alunoNome'] as String? ?? '',
      alunoMatricula: map['alunoMatricula'] as String? ?? '',
      respostas: respostas.map(
        (questaoId, indice) => MapEntry(questaoId, (indice as num?)?.toInt()),
      ),
      acertos: (map['acertos'] as num?)?.toInt() ?? 0,
      totalQuestoes: (map['totalQuestoes'] as num?)?.toInt() ?? 0,
      corrigidoEm: corrigidoEm,
    );
  }
}
