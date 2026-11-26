import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/identificacao_gabarito.dart';
import 'package:mobile/models/identificacao_prova.dart';
import 'package:mobile/models/layout_folha.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FolhaRespostasException implements Exception {
  final String mensagem;

  FolhaRespostasException(this.mensagem);

  @override
  String toString() => mensagem;
}

typedef SalvarArquivo = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
});

/// Gera os PDFs impressos da prova: a prova de cada aluno com a folha de
/// respostas e o gabarito do professor.
///
/// A folha de respostas segue as posições de [LayoutFolha], que é o que a
/// leitura pela câmera usa para encontrar as bolinhas.
class FolhaRespostasPdf {
  final SalvarArquivo _salvarArquivo;

  FolhaRespostasPdf({SalvarArquivo? salvarArquivo})
    : _salvarArquivo = salvarArquivo ?? FilePicker.saveFile;

  static const _mimePdf = 'application/pdf';
  static final _mm = PdfPageFormat.mm;

  /// Prova individual do aluno, na ordem da variação dele, seguida da
  /// folha de respostas com o QR Code que identifica a prova e o aluno.
  Future<Uint8List> gerarProvaDoAluno({
    required Prova prova,
    required Aluno aluno,
    required VariacaoProva variacao,
  }) {
    _validarVariacao(prova, aluno, variacao);

    final documento = pw.Document(title: '${prova.titulo} - ${aluno.nome}');

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(18 * _mm),
        header: (_) => _cabecalhoProva(prova, aluno),
        build: (_) => [
          for (var i = 0; i < variacao.questoes.length; i++)
            _questao(i, variacao.questoes[i]),
        ],
      ),
    );

    documento.addPage(_paginaFolha(prova, aluno, variacao));

    return documento.save();
  }

  /// Gabarito do professor: QR Code que identifica a prova na correção e a
  /// resposta certa de cada questão, na ordem original da prova.
  Future<Uint8List> gerarGabarito({
    required Prova prova,
    required List<Questao> questoes,
  }) {
    final porId = {for (final questao in questoes) questao.id: questao};
    final ordenadas = [
      for (final id in prova.questaoIds)
        if (porId[id] != null) porId[id]!,
    ];

    if (ordenadas.isEmpty) {
      throw FolhaRespostasException('A prova não tem questões cadastradas.');
    }

    final documento = pw.Document(title: 'Gabarito - ${prova.titulo}');
    final codigo = IdentificacaoGabarito(provaId: prova.id).codificar();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(18 * _mm),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GABARITO', style: _estilo(18, negrito: true)),
                    pw.SizedBox(height: 4),
                    pw.Text(_texto(prova.titulo), style: _estilo(13)),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Leia este QR Code em "Corrigir prova" antes das folhas '
                      'dos alunos. Sem câmera, digite o código da prova.',
                      style: _estilo(9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              _qrCode(codigo, 'Código da prova: ${prova.id}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Respostas certas', style: _estilo(12, negrito: true)),
          pw.SizedBox(height: 8),
          for (var i = 0; i < ordenadas.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${i + 1}. ${_respostaCerta(ordenadas[i])}  -  '
                '${_texto(ordenadas[i].enunciado)}',
                style: _estilo(10),
              ),
            ),
        ],
      ),
    );

    return documento.save();
  }

  /// Abre o seletor para salvar o PDF. Retorna `null` se o professor cancelar.
  Future<Uri?> salvar(String nomeArquivo, Uint8List bytes) async {
    try {
      return await _salvarArquivo(
        fileName: nomeArquivo,
        bytes: bytes,
        mimeType: _mimePdf,
      );
    } catch (_) {
      throw FolhaRespostasException('Não foi possível salvar o PDF.');
    }
  }

  /// Nome de arquivo sem acentos, espaços ou caracteres especiais.
  static String nomeArquivo(String base) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    final buffer = StringBuffer();
    for (final letra in base.trim().split('')) {
      final indice = comAcento.indexOf(letra);
      buffer.write(indice >= 0 ? semAcento[indice] : letra);
    }

    final limpo = buffer
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${limpo.isEmpty ? 'prova' : limpo}.pdf';
  }

  void _validarVariacao(Prova prova, Aluno aluno, VariacaoProva variacao) {
    if (variacao.provaId != prova.id || variacao.alunoId != aluno.id) {
      throw FolhaRespostasException(
        'A variação não pertence a esta prova e a este aluno.',
      );
    }
    if (variacao.questoes.isEmpty) {
      throw FolhaRespostasException('A prova não tem questões.');
    }
    if (variacao.questoes.length > LayoutFolha.maxQuestoes) {
      throw FolhaRespostasException(
        'A folha de respostas comporta no máximo '
        '${LayoutFolha.maxQuestoes} questões.',
      );
    }
    for (var i = 0; i < variacao.questoes.length; i++) {
      final total = variacao.questoes[i].alternativas.length;
      if (total < 2 || total > LayoutFolha.maxAlternativas) {
        throw FolhaRespostasException(
          'A questão ${i + 1} precisa ter de 2 a '
          '${LayoutFolha.maxAlternativas} alternativas.',
        );
      }
    }
  }

  pw.Widget _cabecalhoProva(Prova prova, Aluno aluno) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_texto(prova.titulo), style: _estilo(13, negrito: true)),
          pw.Text(
            '${_texto(aluno.nome)} - Matrícula ${_texto(aluno.matricula)}',
            style: _estilo(9),
          ),
        ],
      ),
    );
  }

  pw.Widget _questao(int indice, QuestaoVariada questao) {
    // Inseparable evita que o enunciado fique numa página e as
    // alternativas na seguinte.
    return pw.Inseparable(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${indice + 1}. ${_texto(questao.enunciado)}',
              style: _estilo(11, negrito: true),
            ),
            pw.SizedBox(height: 4),
            for (var j = 0; j < questao.alternativas.length; j++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 2),
                child: pw.Text(
                  '${LayoutFolha.letra(j)}) ${_texto(questao.alternativas[j].texto)}',
                  style: _estilo(10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Página da folha de respostas, desenhada com posições absolutas para
  /// bater exatamente com [LayoutFolha].
  pw.Page _paginaFolha(Prova prova, Aluno aluno, VariacaoProva variacao) {
    final codigo = IdentificacaoProva(
      provaId: prova.id,
      alunoId: aluno.id,
    ).codificar();

    pw.Widget emMm(double x, double y, pw.Widget filho) {
      return pw.Positioned(left: x * _mm, top: y * _mm, child: filho);
    }

    final elementos = <pw.Widget>[
      for (final centro in LayoutFolha.centrosMarcadores)
        emMm(
          centro.x - LayoutFolha.ladoMarcador / 2,
          centro.y - LayoutFolha.ladoMarcador / 2,
          pw.Container(
            width: LayoutFolha.ladoMarcador * _mm,
            height: LayoutFolha.ladoMarcador * _mm,
            color: PdfColors.black,
          ),
        ),
      emMm(
        30,
        30,
        pw.SizedBox(
          width: 112 * _mm,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FOLHA DE RESPOSTAS', style: _estilo(16, negrito: true)),
              pw.SizedBox(height: 4),
              pw.Text(_texto(prova.titulo), style: _estilo(12)),
              pw.SizedBox(height: 10),
              pw.Text('Aluno: ${_texto(aluno.nome)}', style: _estilo(11)),
              pw.Text(
                'Matrícula: ${_texto(aluno.matricula)}',
                style: _estilo(11),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Pinte toda a bolinha da alternativa escolhida com caneta '
                'preta ou azul. Marque só uma alternativa por questão e não '
                'rasure nem dobre a folha.',
                style: _estilo(8.5),
              ),
            ],
          ),
        ),
      ),
      emMm(
        LayoutFolha.cantoQrCode.x,
        LayoutFolha.cantoQrCode.y,
        _qrCode(codigo, 'Matrícula: ${aluno.matricula}'),
      ),
    ];

    for (var coluna = 0; coluna < LayoutFolha.colunas; coluna++) {
      final primeira = coluna * LayoutFolha.questoesPorColuna;
      if (primeira >= variacao.questoes.length) break;

      // Letras só até a maior quantidade de alternativas usada na coluna.
      final ultima = (primeira + LayoutFolha.questoesPorColuna).clamp(
        0,
        variacao.questoes.length,
      );
      final letras = variacao.questoes
          .sublist(primeira, ultima)
          .map((questao) => questao.alternativas.length)
          .reduce((a, b) => a > b ? a : b);

      for (var a = 0; a < letras; a++) {
        final centro = LayoutFolha.centroBolha(primeira, a);
        elementos.add(
          emMm(
            centro.x - 2,
            LayoutFolha.inicioGrade - 9,
            pw.SizedBox(
              width: 4 * _mm,
              child: pw.Text(
                LayoutFolha.letra(a),
                textAlign: pw.TextAlign.center,
                style: _estilo(8, negrito: true),
              ),
            ),
          ),
        );
      }
    }

    for (var q = 0; q < variacao.questoes.length; q++) {
      final primeira = LayoutFolha.centroBolha(q, 0);
      elementos.add(
        emMm(
          primeira.x - 15,
          primeira.y - 2,
          pw.SizedBox(
            width: 9 * _mm,
            child: pw.Text(
              '${q + 1}',
              textAlign: pw.TextAlign.right,
              style: _estilo(9, negrito: true),
            ),
          ),
        ),
      );

      for (var a = 0; a < variacao.questoes[q].alternativas.length; a++) {
        final centro = LayoutFolha.centroBolha(q, a);
        const r = LayoutFolha.raioBolha;
        elementos.add(
          emMm(
            centro.x - r,
            centro.y - r,
            pw.Container(
              width: 2 * r * _mm,
              height: 2 * r * _mm,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(width: 0.8),
              ),
            ),
          ),
        );
      }
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Stack(children: elementos),
    );
  }

  pw.Widget _qrCode(String conteudo, String legenda) {
    return pw.Column(
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: conteudo,
          width: LayoutFolha.ladoQrCode * _mm,
          height: LayoutFolha.ladoQrCode * _mm,
          drawText: false,
        ),
        pw.SizedBox(height: 2),
        pw.SizedBox(
          width: LayoutFolha.ladoQrCode * _mm,
          child: pw.Text(
            _texto(legenda),
            textAlign: pw.TextAlign.center,
            style: _estilo(7),
          ),
        ),
      ],
    );
  }

  String _respostaCerta(Questao questao) {
    final indice = questao.alternativas.indexWhere((a) => a.isCorreta);
    return indice < 0 ? '-' : LayoutFolha.letra(indice);
  }

  pw.TextStyle _estilo(double tamanho, {bool negrito = false}) {
    return pw.TextStyle(
      fontSize: tamanho,
      fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  /// A fonte padrão do PDF só tem os caracteres do Latin-1 (que inclui os
  /// acentos do português). Aspas curvas, travessões e outros símbolos são
  /// trocados por equivalentes simples para o PDF não falhar.
  static String _texto(String texto) {
    const trocas = {
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
      '–': '-',
      '—': '-',
      '…': '...',
      ' ': ' ',
    };

    final buffer = StringBuffer();
    for (final rune in texto.runes) {
      final caractere = String.fromCharCode(rune);
      final troca = trocas[caractere];
      if (troca != null) {
        buffer.write(troca);
      } else if (rune == 0x0A || (rune >= 0x20 && rune <= 0xFF)) {
        buffer.write(caractere);
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }
}
