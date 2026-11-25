import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/services/professor_atual.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/materia_model.dart';

/// Acesso aos dados de matérias na coleção "materias" do Cloud Firestore.
class MateriaService {
  final CollectionReference<Map<String, dynamic>> _colecao = FirebaseFirestore
      .instance
      .collection('materias');

  /// Lista de matérias em tempo real, em ordem alfabética.
  Stream<List<Materia>> listar() {
    // Ordenação no app para não exigir índice composto no Firestore.
    return _colecao
        .where(campoProfessorId, isEqualTo: professorIdAtual())
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Materia.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => a.descricao.compareTo(b.descricao)),
        );
  }

  /// Cadastra uma nova matéria. O id é gerado pelo Firestore e devolvido
  /// para permitir selecioná-la logo em seguida.
  Future<String> cadastrar(Materia materia) async {
    final documento = await _colecao.add({
      ...materia.toMap(),
      campoProfessorId: professorIdAtual(),
    });
    return documento.id;
  }

  /// Envia as matérias do mock ([listaMateria]) para o Firestore, usando
  /// o id do mock como id do documento. Rodar de novo não duplica nada:
  /// os mesmos documentos são apenas sobrescritos.
  Future<int> importarMock() async {
    final batch = FirebaseFirestore.instance.batch();
    var total = 0;

    for (final materia in listaMateria) {
      batch.set(_colecao.doc(materia.id), {
        ...materia.toMap(),
        campoProfessorId: professorIdAtual(),
      });
      total++;
    }

    await batch.commit();
    return total;
  }
}
