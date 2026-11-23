/// Identifica a prova a partir do QR Code impresso no gabarito.
///
/// O texto gerado tem o formato `GABARITO|1|<provaId>`. O prefixo é
/// diferente do usado na folha do aluno (`CORRETOR|1|...`, ver
/// `IdentificacaoProva`), para o app saber qual dos dois foi lido e avisar
/// o professor quando ele ler a folha no lugar do gabarito, ou o contrário.
class IdentificacaoGabarito {
  static const _prefixo = 'GABARITO';
  static const _versao = '1';
  static const _separador = '|';

  final String provaId;

  IdentificacaoGabarito({required this.provaId}) {
    if (!_idValido(provaId)) {
      throw ArgumentError('Id de prova inválido para o QR Code do gabarito.');
    }
  }

  /// Texto que vai dentro do QR Code do gabarito.
  String codificar() => [_prefixo, _versao, provaId].join(_separador);

  /// Lê o texto de um QR Code. Devolve `null` se ele não for o gabarito de
  /// uma prova gerada pelo app.
  static IdentificacaoGabarito? decodificar(String conteudo) {
    final partes = conteudo.trim().split(_separador);

    if (partes.length != 3 ||
        partes[0] != _prefixo ||
        partes[1] != _versao ||
        !_idValido(partes[2])) {
      return null;
    }

    return IdentificacaoGabarito(provaId: partes[2]);
  }

  /// Ids de documento do Firestore não podem ser vazios nem ter `/`.
  static bool _idValido(String id) {
    return id.isNotEmpty && !id.contains('/') && !id.contains(_separador);
  }

  @override
  bool operator ==(Object other) {
    return other is IdentificacaoGabarito && other.provaId == provaId;
  }

  @override
  int get hashCode => provaId.hashCode;
}
