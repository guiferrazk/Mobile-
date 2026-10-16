import 'package:flutter/material.dart';
import 'package:mobile/models/turma_model.dart';
import 'package:mobile/screens/cadastro_turma.dart';
import 'package:mobile/services/turma_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

class ConsultaTurmaScreen extends StatefulWidget {
  const ConsultaTurmaScreen({super.key});

  @override
  State<ConsultaTurmaScreen> createState() => _ConsultaTurmaScreenState();
}

class _ConsultaTurmaScreenState extends State<ConsultaTurmaScreen> {
  final _turmaService = TurmaService();
  late final Stream<List<Turma>> _turmasStream = _turmaService.listar();
  String _filtro = '';

  void _editarTurma(Turma turma) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroTurmaScreen(turma: turma),
      ),
    );
  }

  Future<void> _confirmarExclusao(Turma turma) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Turma'),
        content: Text('Deseja realmente excluir a turma "${turma.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      try {
        await _turmaService.excluir(turma.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma excluída com sucesso!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir turma: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.school_outlined,
          texto: 'Consultar Turmas',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar turma pelo nome',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _filtro = valor.toLowerCase().trim();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Turma>>(
                  stream: _turmasStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro ao carregar turmas: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final turmas = snapshot.data ?? [];
                    final turmasFiltradas = turmas.where((t) {
                      return t.nome.toLowerCase().contains(_filtro);
                    }).toList();

                    if (turmasFiltradas.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma turma encontrada.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: turmasFiltradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final turma = turmasFiltradas[index];
                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppCores.vinho,
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              turma.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${turma.alunos.length} aluno(s) vinculado(s)',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarTurma(turma),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmarExclusao(turma),
                                  tooltip: 'Excluir',
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}