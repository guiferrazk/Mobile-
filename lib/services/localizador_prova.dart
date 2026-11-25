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

/// Transforma o texto lido de um QR Code, ou digitado pelo professor, na
/// prova e no aluno cadastrados.
///
/// O QR Code traz o formato completo (`GABARITO|1|...` ou `CORRETOR|1|...`).
/// Quem digita pode usar só o código da prova, no gabarito, e só a
/// matrícula do aluno, na folha.
///
/// As buscas são recebidas por parâmetro para que a regra de leitura possa
/// ser testada sem acesso ao Firestore. No app, use [LocalizadorProva.firestore].
class LocalizadorProva {
  final Future<Prova?> Function(String id) buscarProva;
  final Future<Aluno?> Function(String id) buscarAluno;
  final Future<Aluno?> Function(String matricula)? buscarAlunoPorMatricula;

  LocalizadorProva({
    required this.buscarProva,
    required this.buscarAluno,
    this.buscarAlunoPorMatricula,
  });

  factory LocalizadorProva.firestore() {
    final provaService = ProvaService();
    final alunoService = AlunoService();

    return LocalizadorProva(
      buscarProva: provaService.buscarPorId,
      buscarAluno: alunoService.buscarPorId,
      buscarAlunoPorMatricula: alunoService.buscarPorMatricula,
    );
  }

  /// Lê o gabarito e devolve a prova correspondente.
  Future<Prova> localizarGabarito(String conteudo) async {
    final texto = conteudo.trim();
    final String provaId;

    final gabarito = IdentificacaoGabarito.decodificar(texto);
    if (gabarito != null) {
      provaId = gabarito.provaId;
    } else if (IdentificacaoProva.decodificar(texto) != null) {
      throw LeituraQrCodeException(
        'Este QR Code é da folha de um aluno. '
        'Leia primeiro o QR Code do gabarito.',
      );
    } else if (_codigoSimples(texto)) {
      provaId = texto;
    } else {
      throw LeituraQrCodeException(
        'Código não reconhecido. Leia o QR Code do gabarito '
        'ou digite o código da prova.',
      );
    }

    final prova = await buscarProva(provaId);
    if (prova == null) {
      throw LeituraQrCodeException(
        'A prova não foi encontrada. Confira o código ou se ela foi excluída.',
      );
    }

    return prova;
  }

  /// Lê a folha de resposta e devolve o aluno. Quando a folha é lida pelo
  /// QR Code, também confere se ela é da mesma [prova] do gabarito.
  Future<Aluno> localizarAlunoDaFolha(
    String conteudo, {
    required Prova prova,
  }) async {
    final texto = conteudo.trim();

    final folha = IdentificacaoProva.decodificar(texto);
    if (folha != null) {
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

    if (IdentificacaoGabarito.decodificar(texto) != null) {
      throw LeituraQrCodeException(
        'Este é o QR Code de um gabarito. '
        'Leia o QR Code da folha de resposta do aluno.',
      );
    }

    if (!_codigoSimples(texto)) {
      throw LeituraQrCodeException(
        'Código não reconhecido. Leia o QR Code da folha '
        'ou digite a matrícula do aluno.',
      );
    }

    // Digitado à mão: procura primeiro pela matrícula e, se não achar,
    // pelo código do aluno no banco.
    final aluno =
        await buscarAlunoPorMatricula?.call(texto) ?? await buscarAluno(texto);
    if (aluno == null) {
      throw LeituraQrCodeException(
        'Nenhum aluno encontrado com a matrícula "$texto".',
      );
    }
    return aluno;
  }

  /// Texto digitado sem o formato do QR Code: um código ou uma matrícula,
  /// sem espaços e sem os caracteres que não podem fazer parte de um id.
  static bool _codigoSimples(String texto) {
    return texto.isNotEmpty && !RegExp(r'[|/\s]').hasMatch(texto);
  }
}
