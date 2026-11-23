import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/models/resultado_model.dart';

class ExportacaoResultadosException implements Exception {
  const ExportacaoResultadosException(this.mensagem, {this.causa});

  final String mensagem;
  final Object? causa;

  @override
  String toString() => mensagem;
}

typedef _SalvarArquivo = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
});

class ExportacaoResultadosService {
  ExportacaoResultadosService({this._salvarArquivo = FilePicker.saveFile});

  final _SalvarArquivo _salvarArquivo;

  static const nomeAba = 'Provas corrigidas';
  static const _mimeXlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Uint8List gerarPlanilha(List<Resultado> resultados) {
    try {
      final excel = Excel.createExcel();
      excel.rename(excel.getDefaultSheet()!, nomeAba);
      final aba = excel[nomeAba];
      final estiloData = CellStyle(
        numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy'),
      );

      aba.appendRow([
        TextCellValue('Aluno'),
        TextCellValue('Matrícula'),
        TextCellValue('Nota'),
        TextCellValue('Acertos'),
        TextCellValue('Data da correção'),
      ]);

      for (final resultado in resultados) {
        final data = resultado.corrigidoEm;
        final linha = aba.maxRows;
        aba.appendRow([
          TextCellValue(resultado.alunoNome),
          TextCellValue(resultado.alunoMatricula),
          DoubleCellValue(resultado.nota),
          IntCellValue(resultado.acertos),
          data == null ? null : DateCellValue.fromDateTime(data),
        ]);
        if (data != null) {
          final indice = CellIndex.indexByColumnRow(
            columnIndex: 4,
            rowIndex: linha,
          );
          aba.cell(indice).cellStyle = estiloData;
        }
      }

      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('A planilha gerada está vazia.');
      }
      return Uint8List.fromList(bytes);
    } catch (erro, pilha) {
      Error.throwWithStackTrace(
        ExportacaoResultadosException(
          'Não foi possível gerar a planilha de resultados.',
          causa: erro,
        ),
        pilha,
      );
    }
  }

  /// Retorna o URI salvo ou `null` se o usuário cancelar o seletor.
  Future<Uri?> salvarPlanilha(List<Resultado> resultados) async {
    final bytes = gerarPlanilha(resultados);
    try {
      return await _salvarArquivo(
        fileName: 'provas_corrigidas.xlsx',
        bytes: bytes,
        mimeType: _mimeXlsx,
      );
    } catch (erro, pilha) {
      Error.throwWithStackTrace(
        ExportacaoResultadosException(
          'Não foi possível salvar a planilha de resultados.',
          causa: erro,
        ),
        pilha,
      );
    }
  }
}
