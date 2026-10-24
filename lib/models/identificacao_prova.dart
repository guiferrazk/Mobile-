/// Dados que identificam de qual prova e de qual aluno é uma folha de
/// resposta. É o conteúdo do QR Code impresso na folha (RF04 e RF12).
///
/// O texto gerado tem o formato `CORRETOR|1|<provaId>|<alunoId>`. O
/// prefixo e a versão permitem recusar QR Codes que não foram gerados
/// pelo app e mudar o formato no futuro sem quebrar folhas já impressas.
class IdentificacaoProva {
  static const _prefixo = 'CORRETOR';
  static const _versao = '1';
  static const _separador = '|';

  final String provaId;
  final String alunoId;

  IdentificacaoProva({required this.provaId, required this.alunoId}) {
    if (!_idValido(provaId) || !_idValido(alunoId)) {
      throw ArgumentError('Id de prova ou aluno inválido para o QR Code.');
    }
  }

  /// Texto que vai dentro do QR Code.
  String codificar() {
    return [_prefixo, _versao, provaId, alunoId].join(_separador);
  }

  /// Lê o texto de um QR Code. Devolve `null` se ele não for uma folha de
  /// resposta gerada pelo app.
  static IdentificacaoProva? decodificar(String conteudo) {
    final partes = conteudo.trim().split(_separador);

    if (partes.length != 4 ||
        partes[0] != _prefixo ||
        partes[1] != _versao ||
        !_idValido(partes[2]) ||
        !_idValido(partes[3])) {
      return null;
    }

    return IdentificacaoProva(provaId: partes[2], alunoId: partes[3]);
  }

  /// Ids de documento do Firestore não podem ser vazios nem ter `/`.
  static bool _idValido(String id) {
    return id.isNotEmpty && !id.contains('/') && !id.contains(_separador);
  }

  @override
  bool operator ==(Object other) {
    return other is IdentificacaoProva &&
        other.provaId == provaId &&
        other.alunoId == alunoId;
  }

  @override
  int get hashCode => Object.hash(provaId, alunoId);
}
