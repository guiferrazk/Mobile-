
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';

/// Gerencia as variações individuais das provas.
class VariacaoProvaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cada aluno possui uma variação própria em cada prova.
  DocumentReference<Map<String, dynamic>> _documento(
    String provaId,
    String alunoId,
  ) {
    return _firestore
        .collection('provas')
        .doc(provaId)
        .collection('variacoes')
        .doc(alunoId);
  }

  /// Recupera uma variação já cadastrada.
  /// Não gera uma nova ordem.
  Future<VariacaoProva?> buscar(
    String provaId,
    String alunoId,
  ) async {
    final snapshot =
        await _documento(provaId, alunoId).get();

    final dados = snapshot.data();

    if (!snapshot.exists || dados == null) {
      return null;
    }

    return VariacaoProva.fromMap(dados);
  }

  /// Ids dos alunos que já têm a variação desta prova gerada. O id de cada
  /// documento da subcoleção é o id do aluno.
  Future<Set<String>> alunosComVariacao(String provaId) async {
    final snapshot = await _firestore
        .collection('provas')
        .doc(provaId)
        .collection('variacoes')
        .get();

    return {for (final doc in snapshot.docs) doc.id};
  }

  /// Gera e salva uma variação se ela ainda não existir.
  /// Caso exista, devolve sempre a mesma versão.
  Future<VariacaoProva> gerarOuRecuperar({
    required Prova prova,
    required String alunoId,
    required List<Questao> questoesOriginais,
  }) async {
    if (prova.id.isEmpty || alunoId.isEmpty) {
      throw ArgumentError('Prova ou aluno inválido.');
    }

    // Se já foi gerada, reutiliza a mesma variação.
    final existente = await buscar(prova.id, alunoId);

    if (existente != null) {
      return existente;
    }

    if (prova.questaoIds.isEmpty) {
      throw StateError('A prova não possui questões.');
    }

    final mapaQuestoes = {
      for (final questao in questoesOriginais)
        questao.id: questao,
    };

    // Confere se todas as questões ainda estão disponíveis.
    for (final id in prova.questaoIds) {
      final questao = mapaQuestoes[id];

      if (questao == null || questao.alternativas.isEmpty) {
        throw StateError(
          'Questão não encontrada ou sem alternativas: $id',
        );
      }
    }

    // Cria uma nova ordem para as questões.
    final idsEmbaralhados =
        List<String>.from(prova.questaoIds)..shuffle();

    final questoesVariadas = <QuestaoVariada>[];

    for (final id in idsEmbaralhados) {
      final questao = mapaQuestoes[id]!;

      // Embaralha os índices das alternativas.
      final ordem = List<int>.generate(
        questao.alternativas.length,
        (indice) => indice,
      )..shuffle();

      questoesVariadas.add(
        QuestaoVariada(
          questaoId: questao.id,
          enunciado: questao.enunciado,
          alternativas: [
            for (final indice in ordem)
              questao.alternativas[indice],
          ],
          indicesOriginais: ordem,
        ),
      );
    }

    final novaVariacao = VariacaoProva(
      provaId: prova.id,
      alunoId: alunoId,
      questoes: questoesVariadas,
    );

    final referencia = _documento(prova.id, alunoId);

    // Transação para impedir que duas operações simultâneas
    // criem variações diferentes para o mesmo aluno.
    return _firestore.runTransaction<VariacaoProva>(
      (transacao) async {
        final snapshot = await transacao.get(referencia);

        if (snapshot.exists) {
          final dados = snapshot.data();

          if (dados == null) {
            throw StateError(
              'Variação cadastrada sem dados.',
            );
          }

          return VariacaoProva.fromMap(dados);
        }

        transacao.set(referencia, {
          ...novaVariacao.toMap(),
          'criadoEm': FieldValue.serverTimestamp(),
        });

        return novaVariacao;
      },
    );
  }
}
