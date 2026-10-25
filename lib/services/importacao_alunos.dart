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
/// O arquivo deve ter as colunas Nome, E-mail e Matrícula. Se uma das
/// primeiras linhas tiver esses títulos, as colunas podem estar em
/// qualquer ordem e o que vem antes (título da planilha, observações) é
/// ignorado; sem cabeçalho, a ordem esperada é nome, e-mail, matrícula.
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

    if (!linhas.any((linha) => !_vazia(linha))) {
      throw ImportacaoException('O arquivo está vazio.');
    }

    // As linhas em branco são mantidas para que o número de cada linha
    // continue igual ao que o professor vê no Excel.
    return linhas;
  }

  /// Valida as linhas lidas. [matriculasCadastradas] são as matrículas que
  /// já existem no Firestore, para não importar o mesmo aluno duas vezes.
  static List<LinhaImportacao> validar(
    List<List<String>> linhas, {
    Set<String> matriculasCadastradas = const {},
  }) {
    final cabecalho = _procurarCabecalho(linhas);
    final colunas =
        cabecalho?.colunas ?? const {'nome': 0, 'email': 1, 'matricula': 2};
    final inicioDados = cabecalho == null ? 0 : cabecalho.indiceLinha + 1;

    final primeiraLinhaPorMatricula = <String, int>{};
    final resultado = <LinhaImportacao>[];

    for (var i = inicioDados; i < linhas.length; i++) {
      final linha = linhas[i];
      final numeroLinha = i + 1;

      if (_vazia(linha)) continue;

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

    // Sem cabeçalho e com quase tudo inválido, o arquivo provavelmente não
    // é uma lista de alunos. Listar cada linha com erro só confundiria.
    final invalidas = resultado.where((linha) => !linha.valida).length;
    if (cabecalho == null && invalidas * 2 > resultado.length) {
      throw ImportacaoException(
        'Esta planilha não parece uma lista de alunos. Confira se ela tem '
        'uma linha de títulos com as colunas Nome, E-mail e Matrícula.',
      );
    }

    return resultado;
  }

  static bool _vazia(List<String> linha) {
    return linha.every((celula) => celula.trim().isEmpty);
  }

  /// Procura a linha de títulos nas primeiras linhas do arquivo, porque
  /// muitas planilhas têm um título ou observações antes da tabela.
  static ({int indiceLinha, Map<String, int> colunas})? _procurarCabecalho(
    List<List<String>> linhas,
  ) {
    const limite = 10;

    for (var i = 0; i < linhas.length && i < limite; i++) {
      final colunas = _indicesDoCabecalho(linhas[i]);
      if (colunas != null) {
        return (indiceLinha: i, colunas: colunas);
      }
    }

    return null;
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

  /// Procura os títulos das colunas na [linha]. Devolve `null` se ela não
  /// parecer um cabeçalho.
  static Map<String, int>? _indicesDoCabecalho(List<String> linha) {
    final titulos = linha.map(_normalizar).toList();
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
