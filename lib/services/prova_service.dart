
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/prova_model.dart';

/// Responsável pelo acesso às provas no Firestore.
class ProvaService {
  final CollectionReference<Map<String, dynamic>> _colecao =
      FirebaseFirestore.instance.collection('provas');

  /// Cadastra uma prova e retorna o ID gerado.
  Future<String> cadastrar(Prova prova) async {
    final documento = await _colecao.add({
      ...prova.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return documento.id;
  }

  /// Lista as provas salvas no Firestore em tempo real.
  Stream<List<Prova>> listar() {
    return _colecao.orderBy('criadoEm').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Prova.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }
}
