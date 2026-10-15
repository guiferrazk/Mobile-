import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/turma_model.dart';

class TurmaServiceException implements Exception {
  final String mensagem;
  TurmaServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

class TurmaService {
  final CollectionReference<Map<String, dynamic>> _colecao =
  FirebaseFirestore.instance.collection('turmas');

  Stream<List<Turma>> listar() {
    return _colecao.orderBy('nome').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Turma.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> cadastrar(Turma turma) async {
    await _validarNomeUnico(turma.nome);
    await _colecao.add(turma.toMap());
  }

  Future<void> atualizar(Turma turma) async {
    await _validarNomeUnico(turma.nome, ignorarId: turma.id);
    await _colecao.doc(turma.id).update(turma.toMap());
  }

  Future<void> excluir(String id) {
    return _colecao.doc(id).delete();
  }

  Future<void> _validarNomeUnico(String nome, {String? ignorarId}) async {
    final resultado = await _colecao
        .where('nome', isEqualTo: nome)
        .limit(2)
        .get();

    final existeOutro = resultado.docs.any((doc) => doc.id != ignorarId);

    if (existeOutro) {
      throw TurmaServiceException('Já existe uma turma cadastrada com este nome.');
    }
  }
}