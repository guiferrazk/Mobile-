
import 'package:flutter/material.dart';

import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/services/prova_service.dart';
import 'package:mobile/services/questao_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

/// Tela para consultar e editar provas cadastradas no Firestore.
class ConsultarProvasScreen extends StatefulWidget {
  const ConsultarProvasScreen({super.key});

  @override
  State<ConsultarProvasScreen> createState() =>
      _ConsultarProvasScreenState();
}

class _ConsultarProvasScreenState
    extends State<ConsultarProvasScreen> {
  final ProvaService _provaService = ProvaService();

  late final Stream<List<Prova>> _provasStream =
      _provaService.listar();

  Future<void> _abrirEdicao(Prova prova) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditarProvaDialog(prova: prova),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.library_books_outlined,
          texto: 'Consultar Provas',
        ),
      ),
      body: StreamBuilder<List<Prova>>(
        stream: _provasStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar provas:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final provas = snapshot.data!;

          if (provas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma prova cadastrada.',
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provas.length,
                itemBuilder: (context, index) {
                  final prova = provas[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                      ),
                      title: Text(
                        prova.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${prova.questaoIds.length} questão(ões)',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _abrirEdicao(prova),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Janela para editar o título e as questões de uma prova.
class _EditarProvaDialog extends StatefulWidget {
  final Prova prova;

  const _EditarProvaDialog({required this.prova});

  @override
  State<_EditarProvaDialog> createState() =>
      _EditarProvaDialogState();
}

class _EditarProvaDialogState
    extends State<_EditarProvaDialog> {
  final ProvaService _provaService = ProvaService();
  final QuestaoService _questaoService = QuestaoService();

  late final TextEditingController _tituloController;

  late final Stream<List<Questao>> _questoesStream;

  late final Set<String> _idsSelecionados;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(
      text: widget.prova.titulo,
    );

    _idsSelecionados = widget.prova.questaoIds.toSet();

    _questoesStream = _questaoService.listar();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um título para a prova.'),
        ),
      );
      return;
    }

    if (_idsSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos uma questão.'),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final provaAtualizada = Prova(
        id: widget.prova.id,
        titulo: titulo,
        questaoIds: _idsSelecionados.toList(),
      );

      await _provaService.atualizar(provaAtualizada);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prova atualizada com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar prova: $erro'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Prova'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _tituloController,
                readOnly: _salvando,
                decoration: const InputDecoration(
                  labelText: 'Título da prova',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Questões da prova',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 260,
                child: StreamBuilder<List<Questao>>(
                  stream: _questoesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Erro ao carregar questões.',
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final questoes = snapshot.data!;

                    if (questoes.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhuma questão cadastrada.',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: questoes.length,
                      itemBuilder: (context, index) {
                        final questao = questoes[index];

                        return CheckboxListTile(
                          title: Text(questao.enunciado),
                          value: _idsSelecionados.contains(
                            questao.id,
                          ),
                          onChanged: _salvando
                              ? null
                              : (selecionado) {
                                  setState(() {
                                    if (selecionado == true) {
                                      _idsSelecionados.add(
                                        questao.id,
                                      );
                                    } else {
                                      _idsSelecionados.remove(
                                        questao.id,
                                      );
                                    }
                                  });
                                },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(
            _salvando ? 'Salvando...' : 'Salvar alterações',
          ),
        ),
      ],
    );
  }
}
