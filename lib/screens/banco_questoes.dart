import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/materia_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/services/questao_service.dart';

/// Tela que lista as questões cadastradas no Firestore.
///
/// Cada questão pode ser editada ou excluída. O botão "Adicionar questão"
/// abre o formulário de cadastro. As matérias ainda vêm do mock
/// [listaMateria].
class BancoQuestoesScreen extends StatefulWidget {
  const BancoQuestoesScreen({super.key});

  @override
  State<BancoQuestoesScreen> createState() => _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  final _questaoService = QuestaoService();

  /// Descobre o nome da matéria a partir do id guardado na questão.
  String _nomeMateria(String? materiaId) {
    for (final materia in listaMateria) {
      if (materia.id == materiaId) return materia.descricao;
    }
    return 'Sem matéria';
  }

  /// Abre o formulário. Sem [questao] é um cadastro; com [questao] é
  /// uma edição.
  void _abrirFormulario([Questao? questao]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarQuestaoScreen(questao: questao),
      ),
    );
  }

  Future<void> _confirmarExclusao(Questao questao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
          'Deseja excluir esta questão? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await _questaoService.excluir(questao.id);
      _mostrarMensagem('Questão excluída.');
    } catch (e) {
      _mostrarMensagem('Não foi possível excluir: $e');
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
        title: const TituloPagina(icone: Icons.quiz_outlined, texto: 'Banco de Questões'),
      ),
      body: StreamBuilder<List<Questao>>(
        stream: _questaoService.listar(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Erro ao carregar questões:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questoes = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: questoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final questao = questoes[index];

              return Card(
                child: ExpansionTile(
                  title: Text(questao.enunciado),
                  subtitle: Text(_nomeMateria(questao.materiaId)),
                  children: [
                    for (final alternativa in questao.alternativas)
                      ListTile(
                        leading: Icon(
                          alternativa.isCorreta
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: alternativa.isCorreta
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(alternativa.texto),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _abrirFormulario(questao),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            onPressed: () => _confirmarExclusao(questao),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Excluir'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar questão'),
      ),
    );
  }
}

/// Formulário de cadastro de questão.
///
/// Se receber uma [questao], funciona como edição: os campos já vêm
/// preenchidos e ao salvar a questão é atualizada em vez de criada.
class AdicionarQuestaoScreen extends StatefulWidget {
  final Questao? questao;

  const AdicionarQuestaoScreen({super.key, this.questao});

  @override
  State<AdicionarQuestaoScreen> createState() =>
      _AdicionarQuestaoScreenState();
}

class _AdicionarQuestaoScreenState extends State<AdicionarQuestaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questaoService = QuestaoService();

  late final TextEditingController _enunciadoController;
  late final List<TextEditingController> _alternativasControllers;

  Materia? _materiaSelecionada;
  int _alternativaCorretaIndex = 0;
  bool _salvando = false;

  bool get _editando => widget.questao != null;

  @override
  void initState() {
    super.initState();

    final questao = widget.questao;

    _enunciadoController = TextEditingController(text: questao?.enunciado);

    // Na edição, usa as alternativas que a questão já tem; no cadastro,
    // começa com 4 campos vazios.
    _alternativasControllers = questao == null
        ? List.generate(4, (_) => TextEditingController())
        : questao.alternativas
        .map((a) => TextEditingController(text: a.texto))
        .toList();

    if (questao != null) {
      final indiceCorreta = questao.alternativas.indexWhere((a) => a.isCorreta);
      _alternativaCorretaIndex = indiceCorreta >= 0 ? indiceCorreta : 0;

      // Procura na lista de matérias a que corresponde ao id salvo.
      for (final materia in listaMateria) {
        if (materia.id == questao.materiaId) {
          _materiaSelecionada = materia;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (final controller in _alternativasControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarQuestao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _salvando = true);

    final questao = Questao(
      id: widget.questao?.id ?? '',
      enunciado: _enunciadoController.text.trim(),
      materiaId: _materiaSelecionada!.id,
      alternativas: [
        for (var i = 0; i < _alternativasControllers.length; i++)
          Alternativa(
            texto: _alternativasControllers[i].text.trim(),
            isCorreta: i == _alternativaCorretaIndex,
          ),
      ],
    );

    try {
      if (_editando) {
        await _questaoService.atualizar(questao);
      } else {
        await _questaoService.cadastrar(questao);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Questão atualizada!' : 'Questão cadastrada!',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a questão: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Questão' : 'Adicionar Questão'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Materia>(
                    initialValue: _materiaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Matéria',
                      border: OutlineInputBorder(),
                    ),
                    items: listaMateria
                        .map(
                          (materia) => DropdownMenuItem(
                        value: materia,
                        child: Text(materia.descricao),
                      ),
                    )
                        .toList(),
                    onChanged: (materia) {
                      setState(() => _materiaSelecionada = materia);
                    },
                    validator: (materia) =>
                    materia == null ? 'Selecione uma matéria' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enunciadoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Enunciado da questão',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                    (valor == null || valor.trim().isEmpty)
                        ? 'Informe o enunciado'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Alternativas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecione o botão à esquerda para marcar a '
                        'alternativa correta.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _alternativasControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _alternativaCorretaIndex,
                            onChanged: (valor) {
                              setState(() => _alternativaCorretaIndex = valor!);
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _alternativasControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Alternativa ${i + 1}',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (valor) =>
                              (valor == null || valor.trim().isEmpty)
                                  ? 'Informe o texto da alternativa'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvarQuestao,
                    icon: _salvando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar questão'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}