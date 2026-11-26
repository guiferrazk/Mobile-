import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/resultado_model.dart';

enum SituacaoCorrecao { naoIniciada, emAndamento, concluida }

/// Andamento da correção de uma prova: quantos alunos já foram corrigidos
/// entre os que receberam a prova.
class StatusProva {
  final String provaId;
  final String titulo;
  final int corrigidos;
  final int total;

  /// Média das notas dos corrigidos; `null` se ninguém foi corrigido.
  final double? media;

  const StatusProva({
    required this.provaId,
    required this.titulo,
    required this.corrigidos,
    required this.total,
    required this.media,
  });

  SituacaoCorrecao get situacao {
    if (corrigidos == 0) return SituacaoCorrecao.naoIniciada;
    if (corrigidos >= total) return SituacaoCorrecao.concluida;
    return SituacaoCorrecao.emAndamento;
  }

  /// Fração corrigida, de 0 a 1.
  double get progresso => total == 0 ? 0 : corrigidos / total;

  /// Monta o status de cada prova que tem alunos.
  ///
  /// [alunosComProva] traz, por prova, os alunos que receberam a prova
  /// (variação gerada). Alunos com resultado também entram no total, para
  /// o status continuar certo mesmo que a variação tenha sido apagada.
  static List<StatusProva> calcular({
    required List<Prova> provas,
    required Map<String, Set<String>> alunosComProva,
    required List<Resultado> resultados,
  }) {
    final status = <StatusProva>[];

    for (final prova in provas) {
      final daProva = resultados.where((r) => r.provaId == prova.id);
      final corrigidos = {for (final r in daProva) r.alunoId};
      final todos = {...?alunosComProva[prova.id], ...corrigidos};
      if (todos.isEmpty) continue;

      final notas = [for (final r in daProva) r.nota];
      status.add(
        StatusProva(
          provaId: prova.id,
          titulo: prova.titulo,
          corrigidos: corrigidos.length,
          total: todos.length,
          media: notas.isEmpty
              ? null
              : notas.reduce((a, b) => a + b) / notas.length,
        ),
      );
    }

    // Provas com correção em andamento primeiro, depois as não iniciadas e
    // por último as concluídas; dentro de cada grupo, por título.
    const ordem = {
      SituacaoCorrecao.emAndamento: 0,
      SituacaoCorrecao.naoIniciada: 1,
      SituacaoCorrecao.concluida: 2,
    };
    status.sort((a, b) {
      final porSituacao = ordem[a.situacao]!.compareTo(ordem[b.situacao]!);
      return porSituacao != 0 ? porSituacao : a.titulo.compareTo(b.titulo);
    });
    return status;
  }
}
