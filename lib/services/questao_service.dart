import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/questao_model.dart';

/// Acesso aos dados de questões na coleção "questoes" do Cloud Firestore.
class QuestaoService {
  final CollectionReference<Map<String, dynamic>> _colecao =
  FirebaseFirestore.instance.collection('questoes');

  /// Lista de questões em tempo real, da mais antiga para a mais nova.
  Stream<List<Questao>> listar() {
    return _colecao.orderBy('criadoEm').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Questao.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Cadastra uma nova questão. O id é gerado pelo Firestore, então o
  /// [Questao.id] recebido aqui é ignorado.
  Future<void> cadastrar(Questao questao) {
    return _colecao.add({
      ...questao.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Atualiza uma questão que já existe (enunciado, matéria e
  /// alternativas). A data de criação é mantida.
  Future<void> atualizar(Questao questao) {
    return _colecao.doc(questao.id).update(questao.toMap());
  }

  Future<void> excluir(String id) {
    return _colecao.doc(id).delete();
  }

  /// Envia as questões do mock ([listaMateria]) para o Firestore, usando
  /// o id do mock como id do documento e guardando a matéria de cada uma.
  /// Rodar de novo não duplica nada: os mesmos documentos são apenas
  /// sobrescritos. Retorna a quantidade de questões enviadas.
  Future<int> importarMock() async {
    final batch = FirebaseFirestore.instance.batch();
    var total = 0;

    for (final materia in listaMateria) {
      for (final questao in materia.questoes) {
        batch.set(_colecao.doc(questao.id), {
          ...questao.toMap(),
          'materiaId': materia.id,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        total++;
      }
    }

    await batch.commit();
    return total;
  }
}