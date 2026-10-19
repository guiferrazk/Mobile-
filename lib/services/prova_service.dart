
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/prova_model.dart';

/// Responsável pelas operações das provas no Firestore.
class ProvaService {
  final CollectionReference<Map<String, dynamic>> _colecao =
      FirebaseFirestore.instance.collection('provas');

  /// Cadastra uma nova prova no Firestore.
  /// Retorna o ID gerado automaticamente.
  Future<String> cadastrar(Prova prova) async {
    final documento = await _colecao.add({
      ...prova.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return documento.id;
  }

  /// Lista todas as provas cadastradas em tempo real.
  Stream<List<Prova>> listar() {
    return _colecao.orderBy('criadoEm').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => Prova.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList(),
    );
  }

  /// Busca uma prova específica pelo ID.
  Future<Prova?> buscarPorId(String id) async {
    final documento = await _colecao.doc(id).get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return Prova.fromMap(
      documento.id,
      documento.data()!,
    );
  }

  /// Atualiza o título e as questões de uma prova existente.
  /// Mantém a data original de criação.
  Future<void> atualizar(Prova prova) async {
    await _colecao.doc(prova.id).update(
      prova.toMap(),
    );
  }
}
