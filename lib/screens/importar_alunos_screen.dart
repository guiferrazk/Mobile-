import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'package:mobile/services/aluno_service.dart';
import 'package:mobile/services/importacao_alunos.dart';

/// Importa a lista de alunos de uma planilha (.xlsx ou .csv).
///
/// O fluxo tem duas etapas: primeiro o arquivo é lido e validado, e o
/// professor vê uma prévia com as linhas que têm problema. Só depois de
/// confirmar é que as linhas válidas são gravadas no Firestore.
class ImportarAlunosScreen extends StatefulWidget {
  const ImportarAlunosScreen({super.key});

  @override
  State<ImportarAlunosScreen> createState() => _ImportarAlunosScreenState();
}

class _ImportarAlunosScreenState extends State<ImportarAlunosScreen> {
  final _alunoService = AlunoService();

  String? _nomeArquivo;
  List<LinhaImportacao> _linhas = [];
  bool _lendo = false;
  bool _gravando = false;

  List<LinhaImportacao> get _validas =>
      _linhas.where((linha) => linha.valida).toList();

  List<LinhaImportacao> get _comErro =>
      _linhas.where((linha) => !linha.valida).toList();

  Future<void> _escolherArquivo() async {
    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ImportacaoAlunos.extensoesAceitas,
    );

    if (arquivo == null) return;

    setState(() => _lendo = true);

    try {
      final bytes = await arquivo.readAsBytes();
      final linhasArquivo = ImportacaoAlunos.lerArquivo(arquivo.name, bytes);
      final cadastradas = await _alunoService.matriculasCadastradas();

      setState(() {
        _nomeArquivo = arquivo.name;
        _linhas = ImportacaoAlunos.validar(
          linhasArquivo,
          matriculasCadastradas: cadastradas,
        );
      });
    } on ImportacaoException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (e) {
      _mostrarMensagem('Não foi possível ler o arquivo: $e');
    } finally {
      if (mounted) {
        setState(() => _lendo = false);
      }
    }
  }

  Future<void> _importar() async {
    final validas = _validas;
    setState(() => _gravando = true);

    try {
      await _alunoService.importar(
        validas.map((linha) => linha.paraAluno()).toList(),
      );

      if (!mounted) return;

      _mostrarMensagem('${validas.length} aluno(s) importado(s)!');
      Navigator.pop(context);
    } catch (e) {
      _mostrarMensagem('Não foi possível importar os alunos: $e');
    } finally {
      if (mounted) {
        setState(() => _gravando = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.upload_file_outlined,
          texto: 'Importar Alunos',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _lendo
              ? const Center(child: CircularProgressIndicator())
              : _nomeArquivo == null
                  ? _instrucoes()
                  : _previa(),
        ),
      ),
    );
  }

  Widget _instrucoes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.table_view_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Escolha uma planilha do Excel (.xlsx) ou um arquivo .csv '
            'com a lista de alunos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'A planilha deve ter uma linha com os títulos Nome, E-mail e '
            'Matrícula (pode haver um título antes dela). '
            'Antes de gravar, você verá uma prévia com os dados encontrados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _escolherArquivo,
            icon: const Icon(Icons.folder_open),
            label: const Text('Escolher arquivo'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previa() {
    final validas = _validas;
    final comErro = _comErro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(_nomeArquivo!),
              subtitle: Text(
                '${validas.length} pronto(s) para importar'
                '${comErro.isEmpty ? '' : ' · ${comErro.length} com problema'}',
              ),
              trailing: TextButton(
                onPressed: _gravando ? null : _escolherArquivo,
                child: const Text('Trocar'),
              ),
            ),
          ),
        ),
        if (comErro.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'As linhas com problema não serão importadas. Corrija a '
              'planilha e escolha o arquivo de novo para incluí-las.',
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (final linha in [...comErro, ...validas])
                _LinhaPrevia(linha: linha),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: validas.isEmpty || _gravando ? null : _importar,
            icon: _gravando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _gravando
                  ? 'Importando...'
                  : 'Importar ${validas.length} aluno(s)',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinhaPrevia extends StatelessWidget {
  final LinhaImportacao linha;

  const _LinhaPrevia({required this.linha});

  @override
  Widget build(BuildContext context) {
    final corErro = Theme.of(context).colorScheme.error;

    return Card(
      child: ListTile(
        leading: Icon(
          linha.valida ? Icons.check_circle_outline : Icons.error_outline,
          color: linha.valida ? Colors.green : corErro,
        ),
        title: Text(linha.nome.isEmpty ? '(sem nome)' : linha.nome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Linha ${linha.numeroLinha} · Matrícula: ${linha.matricula}'),
            Text(linha.email),
            for (final erro in linha.erros)
              Text(erro, style: TextStyle(color: corErro)),
          ],
        ),
      ),
    );
  }
}
