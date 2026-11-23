import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/identificacao_gabarito.dart';
import 'package:mobile/models/identificacao_prova.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/services/aluno_service.dart';
import 'package:mobile/services/prova_service.dart';

class LeituraQrCodeException implements Exception {
  final String mensagem;

  LeituraQrCodeException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Transforma o texto lido de um QR Code na prova e no aluno cadastrados.
///
/// As buscas são recebidas por parâmetro para que a regra de leitura possa
/// ser testada sem acesso ao Firestore. No app, use [LocalizadorProva.firestore].
class LocalizadorProva {
  final Future<Prova?> Function(String id) buscarProva;
  final Future<Aluno?> Function(String id) buscarAluno;

  LocalizadorProva({required this.buscarProva, required this.buscarAluno});

  factory LocalizadorProva.firestore() {
    final provaService = ProvaService();
    final alunoService = AlunoService();

    return LocalizadorProva(
      buscarProva: provaService.buscarPorId,
      buscarAluno: alunoService.buscarPorId,
    );
  }

  /// Lê o QR Code do gabarito e devolve a prova correspondente.
  Future<Prova> localizarGabarito(String conteudo) async {
    final gabarito = IdentificacaoGabarito.decodificar(conteudo);

    if (gabarito == null) {
      if (IdentificacaoProva.decodificar(conteudo) != null) {
        throw LeituraQrCodeException(
          'Este QR Code é da folha de um aluno. '
          'Leia primeiro o QR Code do gabarito.',
        );
      }
      throw LeituraQrCodeException(
        'QR Code não reconhecido. Use o gabarito gerado pelo app.',
      );
    }

    final prova = await buscarProva(gabarito.provaId);
    if (prova == null) {
      throw LeituraQrCodeException(
        'A prova deste gabarito não foi encontrada. '
        'Ela pode ter sido excluída.',
      );
    }

    return prova;
  }

  /// Lê o QR Code da folha de resposta e devolve o aluno, conferindo se a
  /// folha é da mesma [prova] do gabarito lido antes.
  Future<Aluno> localizarAlunoDaFolha(
    String conteudo, {
    required Prova prova,
  }) async {
    final folha = IdentificacaoProva.decodificar(conteudo);

    if (folha == null) {
      if (IdentificacaoGabarito.decodificar(conteudo) != null) {
        throw LeituraQrCodeException(
          'Este é o QR Code de um gabarito. '
          'Leia o QR Code da folha de resposta do aluno.',
        );
      }
      throw LeituraQrCodeException(
        'QR Code não reconhecido. Use a folha de resposta gerada pelo app.',
      );
    }

    if (folha.provaId != prova.id) {
      throw LeituraQrCodeException(
        'Esta folha é de outra prova. '
        'Confira se ela é da prova "${prova.titulo}".',
      );
    }

    final aluno = await buscarAluno(folha.alunoId);
    if (aluno == null) {
      throw LeituraQrCodeException(
        'O aluno desta folha não está cadastrado.',
      );
    }

    return aluno;
  }
}
