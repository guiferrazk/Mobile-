import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/services/exportacao_resultados_service.dart';

Resultado _resultado({DateTime? corrigidoEm}) => Resultado(
  provaId: 'prova-1',
  alunoId: 'aluno-1',
  alunoNome: 'João da Conceição',
  alunoMatricula: '000123',
  respostas: {},
  acertos: 2,
  totalQuestoes: 3,
  corrigidoEm: corrigidoEm,
);

void main() {
  test('exporta os cabeçalhos, valores e tipos das células', () {
    final resultado = _resultado(corrigidoEm: DateTime(2026, 11, 22, 14));
    final bytes = ExportacaoResultadosService().gerarPlanilha([resultado]);
    final excel = Excel.decodeBytes(bytes);

    expect(excel.tables.keys, [ExportacaoResultadosService.nomeAba]);
    final linhas = excel.tables.values.single.rows;
    expect(linhas, hasLength(2));
    expect(linhas.first.map((celula) => celula?.value.toString()), [
      'Aluno',
      'Matrícula',
      'Nota',
      'Acertos',
      'Data da correção',
    ]);
    final linha = linhas[1];
    expect(linha[0]?.value, TextCellValue('João da Conceição'));
    expect(linha[1]?.value, TextCellValue('000123'));
    expect((linha[2]?.value as DoubleCellValue).value, closeTo(20 / 3, 1e-10));
    expect(linha[3]?.value, const IntCellValue(2));
    expect(linha[4]?.value, DateCellValue.fromDateTime(resultado.corrigidoEm!));
    expect(linha[4]?.cellStyle?.numberFormat.formatCode, 'dd/mm/yyyy');
  });

  test('deixa a célula de data vazia quando corrigidoEm é nulo', () {
    final bytes = ExportacaoResultadosService().gerarPlanilha([_resultado()]);
    final linhas = Excel.decodeBytes(bytes).tables.values.single.rows;

    expect(linhas, hasLength(2));
    expect(linhas[1][4]?.value, isNull);
  });

  test('exporta todos os resultados na ordem da lista recebida', () {
    final primeiro = _resultado(corrigidoEm: DateTime(2026, 11, 21));
    final segundo = Resultado(
      provaId: primeiro.provaId,
      alunoId: 'aluno-2',
      alunoNome: 'Ana Souza',
      alunoMatricula: '000045',
      respostas: {},
      acertos: 1,
      totalQuestoes: 3,
      corrigidoEm: DateTime(2026, 11, 22),
    );
    final bytes = ExportacaoResultadosService().gerarPlanilha([
      primeiro,
      segundo,
    ]);
    final linhas = Excel.decodeBytes(bytes).tables.values.single.rows;

    expect(linhas, hasLength(3));
    expect(linhas.skip(1).map((linha) => [linha[0]?.value, linha[1]?.value]), [
      [TextCellValue(primeiro.alunoNome), TextCellValue(primeiro.alunoMatricula)],
      [TextCellValue(segundo.alunoNome), TextCellValue(segundo.alunoMatricula)],
    ]);
  });

  test('encaminha os bytes XLSX ao seletor e retorna o URI salvo', () async {
    final destino = Uri.parse('content://documentos/provas_corrigidas.xlsx');
    final servico = ExportacaoResultadosService(
      salvarArquivo: ({required fileName, required bytes, required mimeType}) async {
        expect(fileName, 'provas_corrigidas.xlsx');
        expect(
          mimeType,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        expect(bytes, isA<Uint8List>());
        expect(
          Excel.decodeBytes(bytes).tables.values.single.rows,
          hasLength(2),
        );
        return destino;
      },
    );

    expect(await servico.salvarPlanilha([_resultado()]), destino);
  });

  test('retorna nulo ao cancelar o salvamento', () async {
    final servico = ExportacaoResultadosService(
      salvarArquivo: ({
        required fileName,
        required bytes,
        required mimeType,
      }) async => null,
    );

    expect(await servico.salvarPlanilha([_resultado()]), isNull);
  });

  test('informa falha no salvamento e preserva a causa', () async {
    final erro = StateError('Falha ao gravar no destino');
    final servico = ExportacaoResultadosService(
      salvarArquivo: ({
        required fileName,
        required bytes,
        required mimeType,
      }) async => throw erro,
    );

    await expectLater(
      servico.salvarPlanilha([_resultado()]),
      throwsA(
        isA<ExportacaoResultadosException>()
            .having((e) => e.causa, 'causa', same(erro))
            .having(
              (e) => e.mensagem,
              'mensagem',
              'Não foi possível salvar a planilha de resultados.',
            ),
      ),
    );
  });
}
