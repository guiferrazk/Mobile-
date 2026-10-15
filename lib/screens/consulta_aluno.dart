import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/services/aluno_service.dart';
import 'cadastro_aluno.dart';

class ConsultaAlunoScreen extends StatefulWidget {
  const ConsultaAlunoScreen({super.key});

  @override
  State<ConsultaAlunoScreen> createState() => _ConsultaAlunoScreenState();
}

class _ConsultaAlunoScreenState extends State<ConsultaAlunoScreen> {
  final _alunoService = AlunoService();

  String _busca = '';

  List<Aluno> _filtrar(List<Aluno> alunos) {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return alunos;

    return alunos.where((aluno) {
      return aluno.nome.toLowerCase().contains(termo) ||
          aluno.matricula.toLowerCase().contains(termo) ||
          aluno.email.toLowerCase().contains(termo);
    }).toList();
  }

  void _abrirCadastro([Aluno? aluno]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CadastroAlunoScreen(aluno: aluno)),
    );
  }

  Future<void> _confirmarExclusao(Aluno aluno) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Deseja excluir ${aluno.nome}? Essa ação não pode ser desfeita.'),
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
      await _alunoService.excluir(aluno.id);
      _mostrarMensagem('Aluno excluído.');
    } catch (e) {
      _mostrarMensagem('Não foi possível excluir: $e');
    }
  }

  Future<void> _importarMock() async {
    try {
      final quantidade = await _alunoService.importarMock();
      _mostrarMensagem('$quantidade alunos importados do mock.');
    } catch (e) {
      _mostrarMensagem('Não foi possível importar: $e');
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
        title: const TituloPagina(icone: Icons.groups_outlined, texto: 'Consultar Alunos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (opcao) {
              if (opcao == 'importar') _importarMock();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'importar',
                child: Text('Importar alunos do mock'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nome, matrícula ou e-mail',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Aluno>>(
                  stream: _alunoService.listar(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Erro ao carregar alunos:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final alunos = _filtrar(snapshot.data!);

                    if (alunos.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Nenhum aluno encontrado.\n'
                                'Use "Cadastrar aluno" ou importe os alunos do mock '
                                'pelo menu no canto superior direito.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: alunos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final aluno = alunos[index];

                        return Card(
                          child: ListTile(
                            onTap: () => _abrirCadastro(aluno),
                            leading: CircleAvatar(
                              child: Text(
                                aluno.nome.isNotEmpty
                                    ? aluno.nome[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(aluno.nome),
                            subtitle: Text(
                              'Matrícula: ${aluno.matricula}\n${aluno.email}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir',
                              onPressed: () => _confirmarExclusao(aluno),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCadastro(),
        icon: const Icon(Icons.person_add),
        label: const Text('Cadastrar aluno'),
      ),
    );
  }
}