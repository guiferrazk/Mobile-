import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/services/professor_atual.dart';
import 'package:mobile/mocks/mock_aluno.dart';
import 'package:mobile/models/aluno_model.dart';

class AlunoServiceException implements Exception {
  final String mensagem;

  AlunoServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

class AlunoService {
  final CollectionReference<Map<String, dynamic>> _colecao = FirebaseFirestore
      .instance
      .collection('alunos');

  Stream<List<Aluno>> listar() {
    return _meus().snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Aluno.fromMap(doc.id, doc.data())).toList()
            ..sort((a, b) => a.nome.compareTo(b.nome)),
    );
  }

  /// Alunos do professor logado. A ordenação é feita no app para não
  /// exigir índice composto no Firestore.
  Query<Map<String, dynamic>> _meus() =>
      _colecao.where(campoProfessorId, isEqualTo: professorIdAtual());

  Map<String, dynamic> _comDono(Aluno aluno) => {
    ...aluno.toMap(),
    campoProfessorId: professorIdAtual(),
  };

  Future<Aluno?> buscarPorId(String id) async {
    final documento = await _colecao.doc(id).get();
    final dados = documento.data();

    if (!documento.exists ||
        dados == null ||
        dados[campoProfessorId] != professorIdAtual()) {
      return null;
    }

    return Aluno.fromMap(documento.id, dados);
  }

  Future<Aluno?> buscarPorMatricula(String matricula) async {
    final resultado = await _meus()
        .where('matricula', isEqualTo: matricula)
        .limit(1)
        .get();

    if (resultado.docs.isEmpty) {
      return null;
    }

    final doc = resultado.docs.first;
    return Aluno.fromMap(doc.id, doc.data());
  }

  Future<void> cadastrar(Aluno aluno) async {
    await _validarMatriculaUnica(aluno.matricula);
    await _colecao.add(_comDono(aluno));
  }

  Future<void> atualizar(Aluno aluno) async {
    await _validarMatriculaUnica(aluno.matricula, ignorarId: aluno.id);
    await _colecao.doc(aluno.id).update(_comDono(aluno));
  }

  Future<void> excluir(String id) {
    return _colecao.doc(id).delete();
  }

  Future<Set<String>> matriculasCadastradas() async {
    final resultado = await _meus().get();
    return resultado.docs
        .map((doc) => doc.data()['matricula'] as String? ?? '')
        .where((matricula) => matricula.isNotEmpty)
        .toSet();
  }

  /// Grava vários alunos de uma vez. Os dados já devem ter sido validados
  /// (ver `ImportacaoAlunos.validar`).
  Future<void> importar(List<Aluno> alunos) async {
    // O Firestore aceita no máximo 500 operações por batch.
    const tamanhoLote = 500;

    for (var inicio = 0; inicio < alunos.length; inicio += tamanhoLote) {
      final batch = FirebaseFirestore.instance.batch();
      final lote = alunos.skip(inicio).take(tamanhoLote);

      for (final aluno in lote) {
        batch.set(_colecao.doc(), _comDono(aluno));
      }

      await batch.commit();
    }
  }

  Future<int> importarMock() async {
    final batch = FirebaseFirestore.instance.batch();

    for (final aluno in listaAluno) {
      batch.set(_colecao.doc(aluno.id), _comDono(aluno));
    }

    await batch.commit();
    return listaAluno.length;
  }

  Future<void> _validarMatriculaUnica(
    String matricula, {
    String? ignorarId,
  }) async {
    final resultado = await _meus()
        .where('matricula', isEqualTo: matricula)
        .limit(2)
        .get();

    final existeOutro = resultado.docs.any((doc) => doc.id != ignorarId);

    if (existeOutro) {
      throw AlunoServiceException('Já existe um aluno com esta matrícula.');
    }
  }
}
