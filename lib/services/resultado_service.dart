import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/identificacao_prova.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/services/aluno_service.dart';

class ResultadoServiceException implements Exception {
  final String mensagem;

  ResultadoServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Folha de resposta identificada: de qual prova e de qual aluno ela é.
class FolhaIdentificada {
  final String provaId;
  final Aluno aluno;

  FolhaIdentificada({required this.provaId, required this.aluno});
}

/// Operações dos resultados de correção no Firestore (coleção `resultados`).
class ResultadoService {
  final CollectionReference<Map<String, dynamic>> _colecao =
      FirebaseFirestore.instance.collection('resultados');

  final AlunoService _alunoService;

  ResultadoService({AlunoService? alunoService})
      : _alunoService = alunoService ?? AlunoService();

  /// Lê o QR Code da folha e busca o aluno correspondente.
  Future<FolhaIdentificada> identificarFolha(String conteudoQrCode) async {
    final identificacao = IdentificacaoProva.decodificar(conteudoQrCode);
    if (identificacao == null) {
      throw ResultadoServiceException(
        'QR Code não reconhecido. Use uma folha gerada pelo app.',
      );
    }

    final aluno = await _alunoService.buscarPorId(identificacao.alunoId);
    if (aluno == null) {
      throw ResultadoServiceException(
        'O aluno desta folha não está mais cadastrado.',
      );
    }

    return FolhaIdentificada(provaId: identificacao.provaId, aluno: aluno);
  }

  /// Grava o resultado. Se o aluno já tinha resultado nessa prova, ele é
  /// substituído.
  Future<void> salvar(Resultado resultado) {
    return _colecao.doc(resultado.id).set({
      ...resultado.toMap(),
      'corrigidoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<Resultado?> buscar(String provaId, String alunoId) async {
    final documento = await _colecao.doc(Resultado.idPara(provaId, alunoId)).get();
    final dados = documento.data();

    if (!documento.exists || dados == null) {
      return null;
    }

    return _deDocumento(dados);
  }

  /// Resultados de uma prova, em ordem alfabética de aluno.
  Stream<List<Resultado>> listarPorProva(String provaId) {
    return _listarOnde('provaId', provaId, (a, b) => a.alunoNome.compareTo(b.alunoNome));
  }

  /// Resultados de um aluno, do mais recente para o mais antigo.
  Stream<List<Resultado>> listarPorAluno(String alunoId) {
    return _listarOnde('alunoId', alunoId, (a, b) {
      final dataA = a.corrigidoEm ?? DateTime(0);
      final dataB = b.corrigidoEm ?? DateTime(0);
      return dataB.compareTo(dataA);
    });
  }

  Future<void> excluir(String provaId, String alunoId) {
    return _colecao.doc(Resultado.idPara(provaId, alunoId)).delete();
  }

  // A ordenação é feita no app para não exigir índice composto no Firestore.
  Stream<List<Resultado>> _listarOnde(
    String campo,
    String valor,
    int Function(Resultado, Resultado) ordem,
  ) {
    return _colecao.where(campo, isEqualTo: valor).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => _deDocumento(doc.data()))
              .toList()
            ..sort(ordem),
        );
  }

  Resultado _deDocumento(Map<String, dynamic> dados) {
    final corrigidoEm = dados['corrigidoEm'];
    return Resultado.fromMap(
      dados,
      corrigidoEm: corrigidoEm is Timestamp ? corrigidoEm.toDate() : null,
    );
  }
}
