import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mobile/models/layout_folha.dart';

/// Gera "fotos" da folha de respostas para testar a leitura sem câmera.
///
/// A folha é desenhada a partir de [LayoutFolha] (as mesmas posições do PDF)
/// e projetada numa imagem com a perspectiva, rotação, ruído e iluminação
/// pedidos, como numa foto tirada com o celular.
class FolhaSintetica {
  /// Alternativas de cada questão.
  final List<int> alternativas;

  /// Bolinhas pintadas: questão → alternativas pintadas.
  final Map<int, List<int>> pintadas;

  /// Quanto cada bolinha é pintada (1 = toda, 0.5 = só o miolo, como caneta
  /// apressada).
  final double cobertura;

  /// Tom da tinta (0 = preto). Valores maiores simulam lápis ou caneta fraca.
  final int tomTinta;

  /// Marcador do canto que não aparece (rasgado ou fora da foto), se houver.
  final int? marcadorAusente;

  FolhaSintetica({
    required this.alternativas,
    this.pintadas = const {},
    this.cobertura = 1,
    this.tomTinta = 25,
    this.marcadorAusente,
  });

  /// Gera a foto. [cantos] são as posições, na foto, dos cantos da folha na
  /// ordem: superior esquerdo, superior direito, inferior esquerdo, inferior
  /// direito. [gradienteLuz] escurece a foto de um lado para o outro (0 a 1).
  Uint8List foto({
    required int largura,
    required int altura,
    required List<(double, double)> cantos,
    double gradienteLuz = 0,
    int ruido = 8,
    int semente = 1,
    bool desfocar = true,
  }) {
    final paraFolha = _homografia(cantos, const [
      (0, 0),
      (LayoutFolha.largura, 0),
      (0, LayoutFolha.altura),
      (LayoutFolha.largura, LayoutFolha.altura),
    ]);
    final aleatorio = math.Random(semente);
    final qr = _modulosQrCode(semente);

    var imagem = img.Image(width: largura, height: altura);
    for (var y = 0; y < altura; y++) {
      for (var x = 0; x < largura; x++) {
        final (mx, my) = _aplicar(paraFolha, x + 0.5, y + 0.5);
        var tom = _tom(mx, my, qr).toDouble();

        // Luz mais fraca para um dos lados da foto.
        tom *= 1 - gradienteLuz * (x / largura);
        tom += (aleatorio.nextDouble() * 2 - 1) * ruido;

        final valor = tom.round().clamp(0, 255);
        imagem.setPixelRgb(x, y, valor, valor, valor);
      }
    }

    if (desfocar) imagem = img.gaussianBlur(imagem, radius: 1);
    return Uint8List.fromList(img.encodeJpg(imagem, quality: 85));
  }

  /// Tom do ponto (x, y) da folha, em milímetros.
  int _tom(double x, double y, List<List<bool>> qr) {
    const fundo = 70; // mesa
    const papel = 232;

    if (x < 0 || y < 0 || x > LayoutFolha.largura || y > LayoutFolha.altura) {
      return fundo;
    }

    for (var i = 0; i < 4; i++) {
      if (i == marcadorAusente) continue;
      final c = LayoutFolha.centrosMarcadores[i];
      const meio = LayoutFolha.ladoMarcador / 2;
      if ((x - c.x).abs() <= meio && (y - c.y).abs() <= meio) return 15;
    }

    final origem = LayoutFolha.cantoQrCode;
    if (x >= origem.x &&
        y >= origem.y &&
        x < origem.x + LayoutFolha.ladoQrCode &&
        y < origem.y + LayoutFolha.ladoQrCode) {
      final n = qr.length;
      final i = ((x - origem.x) / LayoutFolha.ladoQrCode * n).floor();
      final j = ((y - origem.y) / LayoutFolha.ladoQrCode * n).floor();
      return qr[j][i] ? 15 : papel;
    }

    // Cabeçalho com texto (blocos finos, como linhas escritas).
    if (x > 30 && x < 140 && y > 30 && y < 72) {
      final linha = ((y - 30) / 6).floor();
      final dentroLinha = (y - 30) % 6 < 2.2;
      final comprimento = 60 + (linha * 17) % 50;
      if (dentroLinha && x < 30 + comprimento && (x * 3).floor() % 4 != 0) {
        return 40;
      }
    }

    for (var q = 0; q < alternativas.length; q++) {
      final primeira = LayoutFolha.centroBolha(q, 0);
      if ((y - primeira.y).abs() > LayoutFolha.raioBolha + 1) continue;

      // Número da questão à esquerda das bolinhas.
      if (x > primeira.x - 13 &&
          x < primeira.x - 8 &&
          (y - primeira.y).abs() < 1.6) {
        return (x * 4).floor() % 3 == 0 ? papel : 40;
      }

      for (var a = 0; a < alternativas[q]; a++) {
        final c = LayoutFolha.centroBolha(q, a);
        final d = math.sqrt((x - c.x) * (x - c.x) + (y - c.y) * (y - c.y));
        if ((pintadas[q] ?? const []).contains(a) &&
            d <= LayoutFolha.raioBolha * 0.95 * cobertura) {
          return tomTinta;
        }
        if ((d - LayoutFolha.raioBolha).abs() <= 0.18) return 30;
      }
    }

    return papel;
  }

  /// Módulos de um QR Code de mentira (29×29), com os três quadrados de
  /// posição e o resto aleatório.
  static List<List<bool>> _modulosQrCode(int semente) {
    const n = 29;
    final aleatorio = math.Random(semente + 99);
    final modulos = List.generate(
      n,
      (_) => List.generate(n, (_) => aleatorio.nextBool()),
    );

    void localizador(int ox, int oy) {
      for (var j = 0; j < 7; j++) {
        for (var i = 0; i < 7; i++) {
          final borda = i == 0 || j == 0 || i == 6 || j == 6;
          final miolo = i >= 2 && i <= 4 && j >= 2 && j <= 4;
          modulos[oy + j][ox + i] = borda || miolo;
        }
      }
    }

    localizador(0, 0);
    localizador(n - 7, 0);
    localizador(0, n - 7);
    return modulos;
  }

  static List<double> _homografia(
    List<(double, double)> de,
    List<(double, double)> para,
  ) {
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final (x, y) = de[i];
      final (u, v) = para[i];
      a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }

    for (var col = 0; col < 8; col++) {
      var pivo = col;
      for (var lin = col + 1; lin < 8; lin++) {
        if (a[lin][col].abs() > a[pivo][col].abs()) pivo = lin;
      }
      final troca = a[col];
      a[col] = a[pivo];
      a[pivo] = troca;
      for (var lin = 0; lin < 8; lin++) {
        if (lin == col) continue;
        final fator = a[lin][col] / a[col][col];
        for (var k = col; k <= 8; k++) {
          a[lin][k] -= fator * a[col][k];
        }
      }
    }
    return [for (var i = 0; i < 8; i++) a[i][8] / a[i][i], 1];
  }

  static (double, double) _aplicar(List<double> h, double x, double y) {
    final w = h[6] * x + h[7] * y + h[8];
    return ((h[0] * x + h[1] * y + h[2]) / w, (h[3] * x + h[4] * y + h[5]) / w);
  }
}

/// Cantos da folha numa foto de frente, ocupando boa parte da imagem.
List<(double, double)> cantosDeFrente(
  int largura,
  int altura, {
  double margem = 0.08,
}) {
  final usadaAltura = altura * (1 - 2 * margem);
  final usadaLargura = usadaAltura * LayoutFolha.largura / LayoutFolha.altura;
  final esquerda = (largura - usadaLargura) / 2;
  final topo = altura * margem;
  return [
    (esquerda, topo),
    (esquerda + usadaLargura, topo),
    (esquerda, topo + usadaAltura),
    (esquerda + usadaLargura, topo + usadaAltura),
  ];
}

/// Gira os cantos em torno do centro da foto (graus, sentido horário).
List<(double, double)> girar(
  List<(double, double)> cantos,
  double graus,
  int largura,
  int altura,
) {
  final rad = graus * math.pi / 180;
  final cx = largura / 2;
  final cy = altura / 2;
  return [
    for (final (x, y) in cantos)
      (
        cx + (x - cx) * math.cos(rad) - (y - cy) * math.sin(rad),
        cy + (x - cx) * math.sin(rad) + (y - cy) * math.cos(rad),
      ),
  ];
}
