import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/importacao_alunos.dart';

Uint8List _bytes(String texto) => Uint8List.fromList(utf8.encode(texto));

void main() {
  group('lerArquivo', () {
    test('lê CSV separado por ponto e vírgula, como o Excel salva', () {
      final linhas = ImportacaoAlunos.lerArquivo(
        'turma.csv',
        _bytes('Nome;E-mail;Matrícula\r\nAna Souza;ana@email.com;2024001\r\n'),
      );

      expect(linhas, [
        ['Nome', 'E-mail', 'Matrícula'],
        ['Ana Souza', 'ana@email.com', '2024001'],
      ]);
    });

    test('lê CSV separado por vírgula e ignora linhas em branco', () {
      final linhas = ImportacaoAlunos.lerArquivo(
        'turma.CSV',
        _bytes('nome,email,matricula\nAna,ana@email.com,1\n,,\n'),
      );

      expect(linhas, hasLength(2));
    });

    test('lê CSV em Latin-1 sem estragar os acentos', () {
      final linhas = ImportacaoAlunos.lerArquivo(
        'turma.csv',
        Uint8List.fromList(latin1.encode('Nome;E-mail;Matrícula\nJoão;joao@email.com;7\n')),
      );

      expect(linhas[1][0], 'João');
    });

    test('lê planilha xlsx e converte matrícula numérica sem ".0"', () {
      final excel = Excel.createExcel();
      final aba = excel[excel.getDefaultSheet()!];
      aba.appendRow([
        TextCellValue('Nome'),
        TextCellValue('E-mail'),
        TextCellValue('Matrícula'),
      ]);
      aba.appendRow([
        TextCellValue('Ana Souza'),
        TextCellValue('ana@email.com'),
        const DoubleCellValue(2024001),
      ]);

      final linhas = ImportacaoAlunos.lerArquivo(
        'turma.xlsx',
        Uint8List.fromList(excel.encode()!),
      );

      expect(linhas[1], ['Ana Souza', 'ana@email.com', '2024001']);
    });

    test('recusa formato não suportado', () {
      expect(
        () => ImportacaoAlunos.lerArquivo('turma.pdf', _bytes('x')),
        throwsA(isA<ImportacaoException>()),
      );
    });

    test('recusa arquivo vazio', () {
      expect(
        () => ImportacaoAlunos.lerArquivo('turma.csv', _bytes('\n;;\n')),
        throwsA(isA<ImportacaoException>()),
      );
    });
  });

  group('validar', () {
    test('usa o cabeçalho para achar as colunas em qualquer ordem', () {
      final linhas = ImportacaoAlunos.validar([
        ['Matrícula', 'Nome completo', 'E-MAIL'],
        ['2024001', 'Ana Souza', 'Ana@Email.com'],
      ]);

      expect(linhas.single.valida, isTrue);
      expect(linhas.single.nome, 'Ana Souza');
      expect(linhas.single.email, 'ana@email.com');
      expect(linhas.single.matricula, '2024001');
      expect(linhas.single.numeroLinha, 2);
    });

    test('sem cabeçalho, assume nome, e-mail e matrícula', () {
      final linhas = ImportacaoAlunos.validar([
        ['Ana Souza', 'ana@email.com', '2024001'],
      ]);

      expect(linhas.single.valida, isTrue);
      expect(linhas.single.numeroLinha, 1);
    });

    test('avisa quando falta uma coluna obrigatória', () {
      expect(
        () => ImportacaoAlunos.validar([
          ['Nome', 'E-mail'],
          ['Ana', 'ana@email.com'],
        ]),
        throwsA(
          isA<ImportacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Matrícula'),
          ),
        ),
      );
    });

    test('marca dados inválidos', () {
      final linhas = ImportacaoAlunos.validar([
        ['Nome', 'E-mail', 'Matrícula'],
        ['', 'sem-arroba', ''],
      ]);

      expect(linhas.single.valida, isFalse);
      expect(linhas.single.erros, [
        'Informe o nome',
        'E-mail inválido',
        'Informe a matrícula',
      ]);
    });

    test('marca matrícula repetida no arquivo e já cadastrada', () {
      final linhas = ImportacaoAlunos.validar(
        [
          ['Nome', 'E-mail', 'Matrícula'],
          ['Ana Souza', 'ana@email.com', '1'],
          ['Bruno Lima', 'bruno@email.com', '1'],
          ['Carla Dias', 'carla@email.com', '2'],
        ],
        matriculasCadastradas: {'2'},
      );

      expect(linhas[0].valida, isTrue);
      expect(linhas[1].erros, ['Matrícula repetida no arquivo (linha 2)']);
      expect(linhas[2].erros, ['Matrícula já cadastrada no sistema']);
    });

    test('linhas com menos colunas não quebram a leitura', () {
      final linhas = ImportacaoAlunos.validar([
        ['Nome', 'E-mail', 'Matrícula'],
        ['Ana Souza'],
      ]);

      expect(linhas.single.erros, contains('Informe o e-mail'));
    });
  });
}
