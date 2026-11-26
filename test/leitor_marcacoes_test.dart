import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/services/leitor_marcacoes.dart';

import 'apoio/folha_sintetica.dart';

const _largura = 900;
const _altura = 1200;

/// Respostas de exemplo: uma alternativa diferente em cada questão.
final _alternativas = List.generate(12, (q) => q % 3 == 0 ? 5 : 4);
final _respostas = {
  for (var q = 0; q < 12; q++) q: [(q * 3) % _alternativas[q]],
};
final _esperado = [for (var q = 0; q < 12; q++) (q * 3) % _alternativas[q]];

void main() {
  test('lê uma foto de frente', () {
    final foto =
        FolhaSintetica(alternativas: _alternativas, pintadas: _respostas).foto(
          largura: _largura,
          altura: _altura,
          cantos: cantosDeFrente(_largura, _altura),
        );

    final lidas = LeitorMarcacoes.ler(
      foto,
      alternativasPorQuestao: _alternativas,
    );

    expect(lidas.respostas, _esperado);
    expect(lidas.emBranco, isEmpty);
    expect(lidas.marcacaoDupla, isEmpty);
  });

  test('lê uma foto inclinada e em perspectiva', () {
    final cantos = cantosDeFrente(_largura, _altura, margem: 0.1);
    // Parte de cima mais estreita, como foto tirada de um ângulo, e girada.
    final perspectiva = [
      (cantos[0].$1 + 40, cantos[0].$2 + 10),
      (cantos[1].$1 - 30, cantos[1].$2 + 25),
      cantos[2],
      cantos[3],
    ];

    final foto =
        FolhaSintetica(alternativas: _alternativas, pintadas: _respostas).foto(
          largura: _largura,
          altura: _altura,
          cantos: girar(perspectiva, 8, _largura, _altura),
        );

    final lidas = LeitorMarcacoes.ler(
      foto,
      alternativasPorQuestao: _alternativas,
    );

    expect(lidas.respostas, _esperado);
  });

  test('lê a folha de cabeça para baixo', () {
    final foto =
        FolhaSintetica(alternativas: _alternativas, pintadas: _respostas).foto(
          largura: _largura,
          altura: _altura,
          cantos: girar(
            cantosDeFrente(_largura, _altura),
            180,
            _largura,
            _altura,
          ),
        );

    final lidas = LeitorMarcacoes.ler(
      foto,
      alternativasPorQuestao: _alternativas,
    );

    expect(lidas.respostas, _esperado);
  });

  test('aponta questões em branco e com marcação dupla', () {
    final pintadas = {
      0: [1],
      1: <int>[],
      2: [0, 2],
      3: [3],
    };
    final alternativas = [4, 4, 4, 4];

    final foto = FolhaSintetica(alternativas: alternativas, pintadas: pintadas)
        .foto(
          largura: _largura,
          altura: _altura,
          cantos: cantosDeFrente(_largura, _altura),
        );

    final lidas = LeitorMarcacoes.ler(
      foto,
      alternativasPorQuestao: alternativas,
    );

    expect(lidas.respostas, [1, null, null, 3]);
    expect(lidas.emBranco, [1]);
    expect(lidas.marcacaoDupla, [2]);
    expect(lidas.lidas, 2);
  });

  test('avisa quando a foto não tem a folha', () {
    final vazia = img.Image(width: 600, height: 800);
    img.fill(vazia, color: img.ColorRgb8(200, 200, 200));

    expect(
      () => LeitorMarcacoes.ler(
        Uint8List.fromList(img.encodeJpg(vazia)),
        alternativasPorQuestao: _alternativas,
      ),
      throwsA(isA<LeituraFolhaException>()),
    );
  });

  test('avisa quando o arquivo não é uma imagem', () {
    expect(
      () => LeitorMarcacoes.ler(
        Uint8List.fromList([1, 2, 3, 4]),
        alternativasPorQuestao: _alternativas,
      ),
      throwsA(
        isA<LeituraFolhaException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('abrir a foto'),
        ),
      ),
    );
  });
}
