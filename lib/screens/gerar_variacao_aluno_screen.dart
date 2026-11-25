import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';
import 'package:mobile/services/folha_respostas_pdf.dart';
import 'package:mobile/services/questao_service.dart';
import 'package:mobile/utils/mensagens_erro.dart';
import 'package:mobile/services/variacao_prova_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'selecionar_aluno_screen.dart';

class GerarVariacaoAlunoScreen extends StatefulWidget {
  final Prova prova;

  const GerarVariacaoAlunoScreen({
    super.key,
    required this.prova,
  });

  @override
  State<GerarVariacaoAlunoScreen> createState() =>
      _GerarVariacaoAlunoScreenState();
}

class _GerarVariacaoAlunoScreenState
    extends State<GerarVariacaoAlunoScreen> {
  final VariacaoProvaService _variacaoService =
      VariacaoProvaService();

  final QuestaoService _questaoService = QuestaoService();
  final FolhaRespostasPdf _pdf = FolhaRespostasPdf();
  bool _gerandoPdf = false;

  Aluno? _alunoSelecionado;
  VariacaoProva? _variacao;
  bool _processando = false;

  Future<void> _selecionarAluno() async {
    final aluno = await Navigator.push<Aluno>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelecionarAlunoScreen(),
      ),
    );

    if (!mounted || aluno == null) return;

    setState(() {
      _alunoSelecionado = aluno;
      _variacao = null;
      _processando = true;
    });

    try {
      // Recupera uma variação existente, sem embaralhar.
      final existente = await _variacaoService.buscar(
        widget.prova.id,
        aluno.id,
      );

      if (!mounted) return;

      setState(() {
        _variacao = existente;
      });
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao consultar variação: $erro'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  Future<void> _gerarVariacao() async {
    final aluno = _alunoSelecionado;

    if (aluno == null || _processando) return;

    setState(() => _processando = true);

    try {
      // Busca as questões cadastradas no Firestore.
      final questoes = await _questaoService.listar().first;

      // Gera uma variação nova ou recupera a já salva.
      final variacao = await _variacaoService.gerarOuRecuperar(
        prova: widget.prova,
        alunoId: aluno.id,
        questoesOriginais: questoes,
      );

      if (!mounted) return;

      setState(() {
        _variacao = variacao;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Variação individual disponível no Firestore!',
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível gerar a variação: $erro'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  /// Gera o PDF com a prova na ordem do aluno e a folha de respostas.
  Future<void> _baixarProvaDoAluno() async {
    final aluno = _alunoSelecionado;
    final variacao = _variacao;
    if (aluno == null || variacao == null) return;

    await _gerarESalvar(
      nomeArquivo: FolhaRespostasPdf.nomeArquivo(
        '${widget.prova.titulo} ${aluno.matricula} ${aluno.nome}',
      ),
      gerar: () => _pdf.gerarProvaDoAluno(
        prova: widget.prova,
        aluno: aluno,
        variacao: variacao,
      ),
    );
  }

  /// Gera o PDF do gabarito, com o QR Code lido no início da correção.
  Future<void> _baixarGabarito() async {
    await _gerarESalvar(
      nomeArquivo: FolhaRespostasPdf.nomeArquivo(
        'Gabarito ${widget.prova.titulo}',
      ),
      gerar: () async {
        final questoes = await _questaoService.listar().first;
        return _pdf.gerarGabarito(prova: widget.prova, questoes: questoes);
      },
    );
  }

  Future<void> _gerarESalvar({
    required String nomeArquivo,
    required Future<Uint8List> Function() gerar,
  }) async {
    if (_gerandoPdf) return;
    setState(() => _gerandoPdf = true);

    try {
      final bytes = await gerar();
      final salvo = await _pdf.salvar(nomeArquivo, bytes);
      if (!mounted || salvo == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF salvo.')),
      );
    } on FolhaRespostasException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (e) {
      _mostrarMensagem('Não foi possível gerar o PDF. ${MensagensErro.de(e)}');
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
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
          icone: Icons.shuffle,
          texto: 'Variação por Aluno',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.prova.titulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              const Text(
                'Selecione um aluno para gerar ou recuperar '
                'sua versão individual da prova.',
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _gerandoPdf ? null : _baixarGabarito,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Baixar gabarito com QR Code (PDF)'),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed:
                    _processando ? null : _selecionarAluno,
                icon: const Icon(Icons.person_search),
                label: Text(
                  _alunoSelecionado == null
                      ? 'Selecionar aluno'
                      : 'Trocar aluno',
                ),
              ),

              if (_alunoSelecionado != null) ...[
                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(_alunoSelecionado!.nome),
                    subtitle: Text(
                      'Matrícula: ${_alunoSelecionado!.matricula}',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed:
                      _processando ? null : _gerarVariacao,
                  icon: const Icon(Icons.shuffle),
                  label: Text(
                    _processando
                        ? 'Processando...'
                        : _variacao == null
                            ? 'Gerar variação'
                            : 'Recuperar mesma variação',
                  ),
                ),
              ],

              if (_processando) ...[
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],

              if (_variacao != null) ...[
                const SizedBox(height: 24),

                const Text(
                  'Variação individual salva',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${_variacao!.questoes.length} questões '
                  'na ordem atribuída ao aluno.',
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _gerandoPdf ? null : _baixarProvaDoAluno,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Baixar prova e folha de respostas (PDF)'),
                ),

                const SizedBox(height: 16),

                for (var i = 0;
                    i < _variacao!.questoes.length;
                    i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. '
                            '${_variacao!.questoes[i].enunciado}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          for (var j = 0;
                              j <
                                  _variacao!
                                      .questoes[i]
                                      .alternativas
                                      .length;
                              j++)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 5),
                              child: Text(
                                '${String.fromCharCode(65 + j)}) '
                                '${_variacao!.questoes[i].alternativas[j].texto}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
