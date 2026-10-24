import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/utils/validadores_aluno.dart';

class ImportacaoException implements Exception {
  final String mensagem;

  ImportacaoException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Uma linha da planilha já lida, com os erros encontrados na validação.
class LinhaImportacao {
  /// Número da linha na planilha (começando em 1, como o Excel mostra).
  final int numeroLinha;
  final String nome;
  final String email;
  final String matricula;
  final List<String> erros;

  LinhaImportacao({
    required this.numeroLinha,
    required this.nome,
    required this.email,
    required this.matricula,
    required this.erros,
  });

  bool get valida => erros.isEmpty;

  Aluno paraAluno() {
    return Aluno(id: '', nome: nome, email: email, matricula: matricula);
  }
}

/// Lê a lista de alunos de um arquivo `.xlsx` ou `.csv` e valida cada
/// linha antes de qualquer gravação no Firestore.
///
/// O arquivo deve ter as colunas Nome, E-mail e Matrícula. Se a primeira
/// linha tiver esses títulos, as colunas podem estar em qualquer ordem;
/// sem cabeçalho, a ordem esperada é nome, e-mail, matrícula.
class ImportacaoAlunos {
  static const extensoesAceitas = ['xlsx', 'csv'];

  static const _apelidosColunas = {
    'nome': ['nome', 'nome completo', 'aluno', 'nome do aluno'],
    'email': ['email', 'e-mail', 'e mail'],
    'matricula': ['matricula', 'ra', 'registro', 'numero da matricula'],
  };

  /// Converte o conteúdo do arquivo em linhas de texto.
  static List<List<String>> lerArquivo(String nomeArquivo, Uint8List bytes) {
    final extensao = nomeArquivo.split('.').last.toLowerCase();

    final linhas = switch (extensao) {
      'xlsx' => _lerXlsx(bytes),
      'csv' => _lerCsv(bytes),
      _ => throw ImportacaoException(
          'Formato não suportado. Use um arquivo .xlsx ou .csv.',
        ),
    };

    final naoVazias = linhas
        .where((linha) => linha.any((celula) => celula.isNotEmpty))
        .toList();

    if (naoVazias.isEmpty) {
      throw ImportacaoException('O arquivo está vazio.');
    }

    return naoVazias;
  }

  /// Valida as linhas lidas. [matriculasCadastradas] são as matrículas que
  /// já existem no Firestore, para não importar o mesmo aluno duas vezes.
  static List<LinhaImportacao> validar(
    List<List<String>> linhas, {
    Set<String> matriculasCadastradas = const {},
  }) {
    final indices = _indicesDoCabecalho(linhas.first);
    final temCabecalho = indices != null;
    final colunas = indices ?? {'nome': 0, 'email': 1, 'matricula': 2};
    final dados = temCabecalho ? linhas.skip(1) : linhas;

    final primeiraLinhaPorMatricula = <String, int>{};
    final resultado = <LinhaImportacao>[];
    var numeroLinha = temCabecalho ? 1 : 0;

    for (final linha in dados) {
      numeroLinha++;

      String celula(String coluna) {
        final indice = colunas[coluna]!;
        return indice < linha.length ? linha[indice].trim() : '';
      }

      final nome = celula('nome');
      final email = celula('email').toLowerCase();
      final matricula = celula('matricula');

      final erros = [
        ValidadoresAluno.nome(nome),
        ValidadoresAluno.email(email),
        ValidadoresAluno.matricula(matricula),
      ].whereType<String>().toList();

      if (matricula.isNotEmpty) {
        final repetida = primeiraLinhaPorMatricula[matricula];
        if (repetida != null) {
          erros.add('Matrícula repetida no arquivo (linha $repetida)');
        } else {
          primeiraLinhaPorMatricula[matricula] = numeroLinha;
        }

        if (matriculasCadastradas.contains(matricula)) {
          erros.add('Matrícula já cadastrada no sistema');
        }
      }

      resultado.add(LinhaImportacao(
        numeroLinha: numeroLinha,
        nome: nome,
        email: email,
        matricula: matricula,
        erros: erros,
      ));
    }

    return resultado;
  }

  static List<List<String>> _lerXlsx(Uint8List bytes) {
    final Excel planilha;
    try {
      planilha = Excel.decodeBytes(bytes);
    } catch (_) {
      throw ImportacaoException('Não foi possível ler a planilha .xlsx.');
    }

    if (planilha.tables.isEmpty) {
      throw ImportacaoException('A planilha não tem nenhuma aba.');
    }

    // Usa só a primeira aba da planilha.
    final aba = planilha.tables.values.first;
    return aba.rows
        .map((linha) => linha.map((celula) => _textoDaCelula(celula?.value)).toList())
        .toList();
  }

  static String _textoDaCelula(CellValue? valor) {
    return switch (valor) {
      null => '',
      // Matrículas digitadas como número chegam como double (2024001.0).
      DoubleCellValue(:final value) when value == value.truncateToDouble() =>
        value.toInt().toString(),
      _ => valor.toString(),
    };
  }

  static List<List<String>> _lerCsv(Uint8List bytes) {
    final texto = _decodificarTexto(bytes);
    return Csv()
        .decode(texto)
        .map((linha) => linha.map((celula) => '$celula').toList())
        .toList();
  }

  /// O Excel em português costuma salvar CSV em Windows-1252, não UTF-8.
  /// Tenta UTF-8 primeiro e, se falhar, lê como Latin-1.
  static String _decodificarTexto(Uint8List bytes) {
    String texto;
    try {
      texto = utf8.decode(bytes);
    } on FormatException {
      texto = latin1.decode(bytes);
    }
    return texto.startsWith('﻿') ? texto.substring(1) : texto;
  }

  /// Procura os títulos das colunas na primeira linha. Devolve `null` se
  /// ela não parecer um cabeçalho.
  static Map<String, int>? _indicesDoCabecalho(List<String> primeiraLinha) {
    final titulos = primeiraLinha.map(_normalizar).toList();
    final indices = <String, int>{};

    _apelidosColunas.forEach((coluna, apelidos) {
      final indice = titulos.indexWhere(apelidos.contains);
      if (indice >= 0) indices[coluna] = indice;
    });

    if (indices.isEmpty) return null;

    if (indices.length < _apelidosColunas.length) {
      final faltando = _apelidosColunas.keys
          .where((coluna) => !indices.containsKey(coluna))
          .map((coluna) => switch (coluna) {
                'email' => 'E-mail',
                'matricula' => 'Matrícula',
                _ => 'Nome',
              })
          .join(', ');
      throw ImportacaoException('Coluna obrigatória não encontrada: $faltando.');
    }

    return indices;
  }

  static String _normalizar(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçº°';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucoo';

    final minusculo = texto.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final letra in minusculo.split('')) {
      final indice = comAcento.indexOf(letra);
      buffer.write(indice >= 0 ? semAcento[indice] : letra);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 -]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
