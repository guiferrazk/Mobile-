/// Ponto na folha, em milímetros, a partir do canto superior esquerdo.
class PontoFolha {
  final double x;
  final double y;

  const PontoFolha(this.x, this.y);

  @override
  String toString() => '($x, $y)';
}

/// Posições fixas da folha de respostas (A4 em pé), em milímetros.
///
/// É a mesma referência para quem gera o PDF e para quem lê a foto da folha:
/// as quatro marcas pretas dos cantos servem para alinhar a foto, e as
/// bolinhas de cada questão ficam sempre no mesmo lugar em relação a elas.
class LayoutFolha {
  static const double largura = 210;
  static const double altura = 297;

  /// Quadrados pretos de alinhamento, um em cada canto.
  static const double ladoMarcador = 12;

  /// Centros dos marcadores, na ordem: superior esquerdo, superior direito,
  /// inferior esquerdo, inferior direito.
  static const List<PontoFolha> centrosMarcadores = [
    PontoFolha(16, 16),
    PontoFolha(194, 16),
    PontoFolha(16, 281),
    PontoFolha(194, 281),
  ];

  /// QR Code da folha do aluno (canto superior direito, dentro dos marcadores).
  static const PontoFolha cantoQrCode = PontoFolha(150, 30);
  static const double ladoQrCode = 36;

  static const double raioBolha = 3;
  static const double distanciaEntreBolhas = 9;
  static const double alturaLinha = 9;

  static const int colunas = 2;
  static const int questoesPorColuna = 20;
  static const int maxQuestoes = colunas * questoesPorColuna;
  static const int maxAlternativas = 5;

  /// Altura (centro) da linha da primeira questão.
  static const double inicioGrade = 92;

  /// Posição horizontal da bolinha "A" em cada coluna.
  static const List<double> inicioColunas = [42, 128];

  static int colunaDa(int questao) => questao ~/ questoesPorColuna;
  static int linhaDa(int questao) => questao % questoesPorColuna;

  /// Centro da bolinha da [alternativa] na [questao] (os dois começam em 0).
  static PontoFolha centroBolha(int questao, int alternativa) {
    if (questao < 0 || questao >= maxQuestoes) {
      throw RangeError.range(questao, 0, maxQuestoes - 1, 'questao');
    }
    if (alternativa < 0 || alternativa >= maxAlternativas) {
      throw RangeError.range(
        alternativa,
        0,
        maxAlternativas - 1,
        'alternativa',
      );
    }

    return PontoFolha(
      inicioColunas[colunaDa(questao)] + alternativa * distanciaEntreBolhas,
      inicioGrade + linhaDa(questao) * alturaLinha,
    );
  }

  /// Letra exibida para cada alternativa (0 → A).
  static String letra(int alternativa) => String.fromCharCode(65 + alternativa);
}
