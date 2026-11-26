import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mobile/models/layout_folha.dart';

class LeituraFolhaException implements Exception {
  final String mensagem;

  LeituraFolhaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// O que foi reconhecido na foto da folha de respostas.
class MarcacoesLidas {
  /// Alternativa marcada em cada questão, na ordem da folha (a mesma da
  /// variação do aluno). `null` quando a questão está em branco ou tem mais
  /// de uma alternativa marcada.
  final List<int?> respostas;

  /// Questões sem nenhuma marcação (índices começando em 0).
  final List<int> emBranco;

  /// Questões com mais de uma alternativa marcada (índices começando em 0).
  final List<int> marcacaoDupla;

  const MarcacoesLidas({
    required this.respostas,
    required this.emBranco,
    required this.marcacaoDupla,
  });

  int get lidas => respostas.whereType<int>().length;
}

/// Reconhece as alternativas marcadas na foto da folha de respostas gerada
/// pelo app (ver [LayoutFolha]).
///
/// Passos: separa tinta de papel com um limiar que se adapta à luz de cada
/// região da foto; encontra os quatro quadrados pretos dos cantos; calcula a
/// perspectiva da foto a partir deles; e mede quanto de cada bolinha está
/// pintado.
class LeitorMarcacoes {
  /// Lado maior usado no processamento. Fotos maiores são reduzidas, o que
  /// deixa a leitura rápida sem perder as bolinhas (cerca de 30 px cada).
  static const ladoTrabalho = 1400;

  /// Fração pintada a partir da qual a bolinha conta como marcada.
  static const limiarMarcada = 0.40;

  /// Abaixo de [limiarMarcada], uma bolinha ainda é aceita se for a única
  /// claramente mais escura que as outras da questão (caneta fraca).
  static const limiarFraca = 0.20;

  /// Lê a foto. [alternativasPorQuestao] tem, para cada questão da folha,
  /// quantas alternativas ela tem.
  static MarcacoesLidas ler(
    Uint8List foto, {
    required List<int> alternativasPorQuestao,
  }) {
    if (alternativasPorQuestao.isEmpty ||
        alternativasPorQuestao.length > LayoutFolha.maxQuestoes) {
      throw ArgumentError('Quantidade de questões fora do limite da folha.');
    }

    final imagem = _abrir(foto);
    final binaria = _Binaria.daImagem(imagem);
    final cantos = _encontrarMarcadores(binaria);
    final folha = _orientar(binaria, cantos);

    final respostas = <int?>[];
    final emBranco = <int>[];
    final duplas = <int>[];

    for (var q = 0; q < alternativasPorQuestao.length; q++) {
      final pintado = [
        for (var a = 0; a < alternativasPorQuestao[q]; a++)
          _fracaoPintada(binaria, folha, LayoutFolha.centroBolha(q, a)),
      ];

      final resposta = _decidir(pintado);
      respostas.add(resposta.alternativa);
      if (resposta.dupla) {
        duplas.add(q);
      } else if (resposta.alternativa == null) {
        emBranco.add(q);
      }
    }

    return MarcacoesLidas(
      respostas: respostas,
      emBranco: emBranco,
      marcacaoDupla: duplas,
    );
  }

  static img.Image _abrir(Uint8List foto) {
    final img.Image? decodificada;
    try {
      decodificada = img.decodeImage(foto);
    } catch (_) {
      throw LeituraFolhaException('Não foi possível abrir a foto.');
    }
    if (decodificada == null) {
      throw LeituraFolhaException('Não foi possível abrir a foto.');
    }

    // Fotos de celular guardam a rotação no EXIF; aplica antes de medir.
    var imagem = img.bakeOrientation(decodificada);
    final maior = math.max(imagem.width, imagem.height);
    if (maior > ladoTrabalho) {
      imagem = imagem.width >= imagem.height
          ? img.copyResize(
              imagem,
              width: ladoTrabalho,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              imagem,
              height: ladoTrabalho,
              interpolation: img.Interpolation.average,
            );
    }
    return imagem;
  }

  static ({int? alternativa, bool dupla}) _decidir(List<double> pintado) {
    final marcadas = [
      for (var a = 0; a < pintado.length; a++)
        if (pintado[a] >= limiarMarcada) a,
    ];

    if (marcadas.length > 1) return (alternativa: null, dupla: true);
    if (marcadas.length == 1) {
      return (alternativa: marcadas.single, dupla: false);
    }

    // Nenhuma passou do limiar: aceita a mais escura só se ela se destacar.
    final ordenadas = [...pintado]..sort();
    final maior = ordenadas.last;
    final segunda = ordenadas.length > 1
        ? ordenadas[ordenadas.length - 2]
        : 0.0;
    if (maior >= limiarFraca && maior - segunda >= limiarFraca) {
      return (alternativa: pintado.indexOf(maior), dupla: false);
    }
    return (alternativa: null, dupla: false);
  }

  /// Fração dos pixels escuros no miolo da bolinha. O contorno impresso fica
  /// de fora (só conta até 55% do raio), então uma bolinha vazia dá perto de 0.
  static double _fracaoPintada(
    _Binaria binaria,
    _Homografia folha,
    PontoFolha centroMm,
  ) {
    const r = LayoutFolha.raioBolha;
    final centro = folha.aplicar(centroMm.x, centroMm.y);
    final ladoX = folha.aplicar(centroMm.x + r, centroMm.y);
    final ladoY = folha.aplicar(centroMm.x, centroMm.y + r);

    final raioPx =
        0.55 * math.min(_distancia(centro, ladoX), _distancia(centro, ladoY));
    if (raioPx < 2) {
      throw LeituraFolhaException(
        'A folha ficou muito pequena na foto. Aproxime a câmera.',
      );
    }

    var total = 0;
    var escuros = 0;
    final raio2 = raioPx * raioPx;
    for (
      var y = (centro.$2 - raioPx).floor();
      y <= (centro.$2 + raioPx).ceil();
      y++
    ) {
      for (
        var x = (centro.$1 - raioPx).floor();
        x <= (centro.$1 + raioPx).ceil();
        x++
      ) {
        final dx = x - centro.$1;
        final dy = y - centro.$2;
        if (dx * dx + dy * dy > raio2) continue;
        if (!binaria.dentro(x, y)) continue;
        total++;
        if (binaria.escuro(x, y)) escuros++;
      }
    }
    return total == 0 ? 0 : escuros / total;
  }

  /// Procura os quatro quadrados pretos dos cantos e os devolve na ordem
  /// superior esquerdo, superior direito, inferior esquerdo, inferior direito
  /// (como aparecem na foto).
  static List<(double, double)> _encontrarMarcadores(_Binaria binaria) {
    final candidatos =
        _Componente.encontrar(binaria)
            .where((c) => c.pareceQuadradoCheio(binaria))
            .toList()
          ..sort((a, b) => b.area.compareTo(a.area));

    // Os marcadores são os maiores quadrados da folha; limitar aos maiores
    // mantém a busca rápida mesmo com muitas bolinhas pintadas.
    final maiores = candidatos.take(12).toList();
    if (maiores.length < 4) throw _semMarcadores();

    List<(double, double)>? melhor;
    var melhorArea = 0;

    for (var i = 0; i < maiores.length; i++) {
      for (var j = i + 1; j < maiores.length; j++) {
        for (var k = j + 1; k < maiores.length; k++) {
          for (var l = k + 1; l < maiores.length; l++) {
            final grupo = [maiores[i], maiores[j], maiores[k], maiores[l]];
            final areas = grupo.map((c) => c.area).toList()..sort();
            if (areas.last > areas.first * 2.5) continue;

            final cantos = _ordenarCantos([for (final c in grupo) c.centro]);
            if (cantos == null || !_formaDeFolha(cantos)) continue;

            final soma = areas.reduce((a, b) => a + b);
            if (soma > melhorArea) {
              melhorArea = soma;
              melhor = cantos;
            }
          }
        }
      }
    }

    if (melhor == null) throw _semMarcadores();
    return melhor;
  }

  static LeituraFolhaException _semMarcadores() {
    return LeituraFolhaException(
      'Não foi possível encontrar os quatro quadrados pretos dos cantos da '
      'folha. Fotografe a folha inteira, de frente e com boa luz.',
    );
  }

  /// Ordena quatro pontos como superior esquerdo, superior direito, inferior
  /// esquerdo e inferior direito. Devolve `null` se não formarem um
  /// quadrilátero bem definido.
  static List<(double, double)>? _ordenarCantos(List<(double, double)> pontos) {
    (double, double) extremo(
      double Function((double, double)) valor, {
      required bool maior,
    }) {
      return pontos.reduce((a, b) {
        final va = valor(a);
        final vb = valor(b);
        return (maior ? va >= vb : va <= vb) ? a : b;
      });
    }

    final se = extremo((p) => p.$1 + p.$2, maior: false);
    final id = extremo((p) => p.$1 + p.$2, maior: true);
    final sd = extremo((p) => p.$1 - p.$2, maior: true);
    final ie = extremo((p) => p.$1 - p.$2, maior: false);

    final cantos = [se, sd, ie, id];
    if (cantos.toSet().length != 4) return null;
    return cantos;
  }

  /// Confere se os quatro pontos formam um quadrilátero convexo com a
  /// proporção da folha (em pé ou deitada).
  static bool _formaDeFolha(List<(double, double)> c) {
    final topo = _distancia(c[0], c[1]);
    final base = _distancia(c[2], c[3]);
    final esquerda = _distancia(c[0], c[2]);
    final direita = _distancia(c[1], c[3]);

    if ([topo, base, esquerda, direita].any((lado) => lado < 40)) return false;
    // Lados opostos parecidos: a perspectiva de uma foto razoável não
    // distorce tanto.
    if (math.max(topo, base) > 1.6 * math.min(topo, base)) return false;
    if (math.max(esquerda, direita) > 1.6 * math.min(esquerda, direita)) {
      return false;
    }

    final esperado =
        (LayoutFolha.centrosMarcadores[1].x -
            LayoutFolha.centrosMarcadores[0].x) /
        (LayoutFolha.centrosMarcadores[2].y -
            LayoutFolha.centrosMarcadores[0].y);
    final razao = (topo + base) / (esquerda + direita);
    final emPe = razao > esperado * 0.7 && razao < esperado * 1.35;
    final deitada =
        razao > (1 / esperado) * 0.7 && razao < (1 / esperado) * 1.35;
    if (!emPe && !deitada) return false;

    return _convexo([c[0], c[1], c[3], c[2]]);
  }

  static bool _convexo(List<(double, double)> poligono) {
    double? sinal;
    for (var i = 0; i < poligono.length; i++) {
      final a = poligono[i];
      final b = poligono[(i + 1) % poligono.length];
      final c = poligono[(i + 2) % poligono.length];
      final cruz =
          (b.$1 - a.$1) * (c.$2 - b.$2) - (b.$2 - a.$2) * (c.$1 - b.$1);
      if (cruz.abs() < 1e-6) return false;
      sinal ??= cruz.sign;
      if (cruz.sign != sinal) return false;
    }
    return true;
  }

  /// A folha pode estar girada na foto. Testa as quatro rotações e fica com
  /// a que põe o QR Code (a região mais escura do cabeçalho) no lugar certo.
  static _Homografia _orientar(
    _Binaria binaria,
    List<(double, double)> cantos,
  ) {
    final [se, sd, ie, id] = cantos;
    // Para cada rotação, qual ponto da foto corresponde a cada canto da folha.
    final rotacoes = [
      [se, sd, ie, id],
      [ie, se, id, sd],
      [id, ie, sd, se],
      [sd, id, se, ie],
    ];

    _Homografia? melhor;
    var melhorDensidade = -1.0;

    for (final rotacao in rotacoes) {
      final homografia = _Homografia.dosCantos(rotacao);
      if (homografia == null) continue;

      final densidade = _densidadeQrCode(binaria, homografia);
      if (densidade > melhorDensidade) {
        melhorDensidade = densidade;
        melhor = homografia;
      }
    }

    if (melhor == null || melhorDensidade < 0.2) {
      throw LeituraFolhaException(
        'Não foi possível reconhecer a folha. Confira se é a folha de '
        'respostas gerada pelo app.',
      );
    }
    return melhor;
  }

  /// Fração de pontos escuros na região do QR Code: perto de 50% quando a
  /// orientação está certa, bem menos nas outras.
  static double _densidadeQrCode(_Binaria binaria, _Homografia folha) {
    const passos = 14;
    const lado = LayoutFolha.ladoQrCode;
    final origem = LayoutFolha.cantoQrCode;

    var escuros = 0;
    var total = 0;
    for (var i = 0; i < passos; i++) {
      for (var j = 0; j < passos; j++) {
        final x = origem.x + lado * (i + 0.5) / passos;
        final y = origem.y + lado * (j + 0.5) / passos;
        final p = folha.aplicar(x, y);
        final px = p.$1.round();
        final py = p.$2.round();
        if (!binaria.dentro(px, py)) continue;
        total++;
        if (binaria.escuro(px, py)) escuros++;
      }
    }
    return total == 0 ? 0 : escuros / total;
  }

  static double _distancia((double, double) a, (double, double) b) {
    final dx = a.$1 - b.$1;
    final dy = a.$2 - b.$2;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// Imagem em preto e branco: cada pixel é tinta ou papel.
///
/// Usa o limiar adaptativo de Bradley: o pixel é tinta se for bem mais
/// escuro que a média da vizinhança. Assim sombras e luz desigual na foto
/// não viram "tinta".
class _Binaria {
  final int largura;
  final int altura;
  final Uint8List _escuro;

  _Binaria(this.largura, this.altura, this._escuro);

  factory _Binaria.daImagem(img.Image imagem) {
    final w = imagem.width;
    final h = imagem.height;
    final luz = Uint8List(w * h);
    for (final pixel in imagem) {
      luz[pixel.y * w + pixel.x] = (pixel.luminanceNormalized * 255)
          .round()
          .clamp(0, 255);
    }

    // Soma acumulada para tirar a média de qualquer janela em tempo constante.
    final integral = Float64List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var somaLinha = 0.0;
      for (var x = 0; x < w; x++) {
        somaLinha += luz[y * w + x];
        integral[(y + 1) * (w + 1) + x + 1] =
            integral[y * (w + 1) + x + 1] + somaLinha;
      }
    }

    // Janela maior que os quadrados dos cantos, para o miolo deles não
    // ser confundido com papel.
    final meia = math.max(8, math.max(w, h) ~/ 14);
    const sensibilidade = 0.82;
    final escuro = Uint8List(w * h);

    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - meia);
      final y1 = math.min(h - 1, y + meia);
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - meia);
        final x1 = math.min(w - 1, x + meia);
        final area = (x1 - x0 + 1) * (y1 - y0 + 1);
        final soma =
            integral[(y1 + 1) * (w + 1) + x1 + 1] -
            integral[y0 * (w + 1) + x1 + 1] -
            integral[(y1 + 1) * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        if (luz[y * w + x] * area < soma * sensibilidade) {
          escuro[y * w + x] = 1;
        }
      }
    }

    return _Binaria(w, h, escuro);
  }

  bool dentro(int x, int y) => x >= 0 && y >= 0 && x < largura && y < altura;

  bool escuro(int x, int y) => _escuro[y * largura + x] == 1;
}

/// Mancha contínua de pixels escuros.
class _Componente {
  int area = 0;
  double somaX = 0, somaY = 0;
  double somaXX = 0, somaYY = 0, somaXY = 0;
  int minX = 1 << 30, maxX = -1, minY = 1 << 30, maxY = -1;
  bool tocaBorda = false;

  (double, double) get centro => (somaX / area, somaY / area);

  /// Quadrado sólido, em qualquer rotação: compara a área com a de um
  /// retângulo cheio que teria a mesma distribuição de pixels.
  bool pareceQuadradoCheio(_Binaria binaria) {
    if (tocaBorda) return false;
    final total = binaria.largura * binaria.altura;
    if (area < total * 0.0002 || area > total * 0.03) return false;

    final (cx, cy) = centro;
    final vxx = somaXX / area - cx * cx;
    final vyy = somaYY / area - cy * cy;
    final vxy = somaXY / area - cx * cy;
    final traco = vxx + vyy;
    final det = vxx * vyy - vxy * vxy;
    if (det <= 0) return false;

    final delta = math.sqrt(math.max(0, traco * traco / 4 - det));
    final l1 = traco / 2 + delta;
    final l2 = traco / 2 - delta;
    if (l2 <= 0 || l1 / l2 > 1.6) return false;

    // Para um retângulo cheio de lados a e b: variâncias a²/12 e b²/12.
    final areaRetangulo = 12 * math.sqrt(l1 * l2);
    final solidez = area / areaRetangulo;
    return solidez > 0.88 && solidez < 1.12;
  }

  static List<_Componente> encontrar(_Binaria binaria) {
    final w = binaria.largura;
    final h = binaria.altura;
    final visitado = Uint8List(w * h);
    final pilha = Int32List(w * h);
    final componentes = <_Componente>[];

    for (var inicio = 0; inicio < w * h; inicio++) {
      if (visitado[inicio] == 1 || binaria._escuro[inicio] == 0) continue;

      final c = _Componente();
      var topo = 0;
      pilha[topo++] = inicio;
      visitado[inicio] = 1;

      while (topo > 0) {
        final indice = pilha[--topo];
        final x = indice % w;
        final y = indice ~/ w;

        c.area++;
        c.somaX += x;
        c.somaY += y;
        c.somaXX += x * x;
        c.somaYY += y * y;
        c.somaXY += x * y;
        if (x < c.minX) c.minX = x;
        if (x > c.maxX) c.maxX = x;
        if (y < c.minY) c.minY = y;
        if (y > c.maxY) c.maxY = y;
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) c.tocaBorda = true;

        void vizinho(int v) {
          if (visitado[v] == 0 && binaria._escuro[v] == 1) {
            visitado[v] = 1;
            pilha[topo++] = v;
          }
        }

        if (x > 0) vizinho(indice - 1);
        if (x < w - 1) vizinho(indice + 1);
        if (y > 0) vizinho(indice - w);
        if (y < h - 1) vizinho(indice + w);
      }

      componentes.add(c);
    }

    return componentes;
  }
}

/// Transformação de perspectiva da folha (mm) para a foto (pixels).
class _Homografia {
  final List<double> _h;

  _Homografia(this._h);

  /// [cantos]: pontos da foto que correspondem aos marcadores superior
  /// esquerdo, superior direito, inferior esquerdo e inferior direito.
  static _Homografia? dosCantos(List<(double, double)> cantos) {
    final origem = LayoutFolha.centrosMarcadores;

    // Monta o sistema 8x8 de A·h = b com h33 = 1.
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = origem[i].x;
      final y = origem[i].y;
      final u = cantos[i].$1;
      final v = cantos[i].$2;
      a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }

    final solucao = _resolver(a);
    if (solucao == null) return null;
    return _Homografia([...solucao, 1]);
  }

  (double, double) aplicar(double x, double y) {
    final w = _h[6] * x + _h[7] * y + _h[8];
    return (
      (_h[0] * x + _h[1] * y + _h[2]) / w,
      (_h[3] * x + _h[4] * y + _h[5]) / w,
    );
  }

  /// Eliminação de Gauss com pivotamento parcial.
  static List<double>? _resolver(List<List<double>> m) {
    const n = 8;
    for (var col = 0; col < n; col++) {
      var pivo = col;
      for (var lin = col + 1; lin < n; lin++) {
        if (m[lin][col].abs() > m[pivo][col].abs()) pivo = lin;
      }
      if (m[pivo][col].abs() < 1e-12) return null;
      final troca = m[col];
      m[col] = m[pivo];
      m[pivo] = troca;

      for (var lin = 0; lin < n; lin++) {
        if (lin == col) continue;
        final fator = m[lin][col] / m[col][col];
        for (var k = col; k <= n; k++) {
          m[lin][k] -= fator * m[col][k];
        }
      }
    }
    return [for (var i = 0; i < n; i++) m[i][n] / m[i][i]];
  }
}
