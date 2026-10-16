import 'package:flutter/material.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/turma_model.dart';
import 'package:mobile/services/aluno_service.dart';
import 'package:mobile/services/turma_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

class CadastroTurmaScreen extends StatefulWidget {
  final Turma? turma;

  const CadastroTurmaScreen({super.key, this.turma});

  @override
  State<CadastroTurmaScreen> createState() => _CadastroTurmaScreenState();
}

class _CadastroTurmaScreenState extends State<CadastroTurmaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _turmaService = TurmaService();
  final _alunoService = AlunoService();
  late final Stream<List<Aluno>> _alunosStream = _alunoService.listar();

  late final TextEditingController _nomeController;
  List<Aluno> _alunosSelecionados = [];
  bool _salvando = false;

  bool get _editando => widget.turma != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.turma?.nome);
    _alunosSelecionados = List.from(widget.turma?.alunos ?? []);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final turma = Turma(
      id: widget.turma?.id ?? '',
      nome: _nomeController.text.trim(),
      alunos: _alunosSelecionados,
    );

    try {
      if (_editando) {
        await _turmaService.atualizar(turma);
      } else {
        await _turmaService.cadastrar(turma);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Turma atualizada!' : 'Turma cadastrada!',
          ),
        ),
      );
      Navigator.pop(context);
    } on TurmaServiceException catch (e) {
      _mostrarErro(e.mensagem);
    } catch (e) {
      _mostrarErro('Não foi possível salvar a turma: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TituloPagina(
          icone: Icons.class_outlined,
          texto: _editando ? 'Editar Turma' : 'Cadastrar Turma',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Turma (ex: 3º Ano A)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor == null || valor.trim().isEmpty)
                        ? 'Informe o nome da turma'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Alunos vinculados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Aluno>>(
                    stream: _alunosStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData && !snapshot.hasError) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final todosAlunos = snapshot.data ?? [];

                      if (todosAlunos.isEmpty) {
                        return const Text(
                          'Nenhum aluno cadastrado no sistema.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todosAlunos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final aluno = todosAlunos[index];
                            final estaSelecionado = _alunosSelecionados
                                .any((a) => a.id == aluno.id);

                            return CheckboxListTile(
                              title: Text(aluno.nome),
                              subtitle: Text('Matrícula: ${aluno.matricula}'),
                              value: estaSelecionado,
                              onChanged: (marcado) {
                                setState(() {
                                  if (marcado == true) {
                                    _alunosSelecionados.add(aluno);
                                  } else {
                                    _alunosSelecionados
                                        .removeWhere((a) => a.id == aluno.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
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
                    label: Text(_salvando ? 'Salvando...' : 'Salvar turma'),
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