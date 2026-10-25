import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/services/aluno_service.dart';

/// Lista os alunos cadastrados no Firestore para o professor escolher
/// de quem é a prova que está sendo corrigida.
///
/// Enquanto a leitura da folha pela câmera não existe, essa escolha
/// substitui a identificação automática do aluno. Devolve o [Aluno]
/// selecionado com `Navigator.pop`.
class SelecionarAlunoScreen extends StatefulWidget {
  const SelecionarAlunoScreen({super.key});

  @override
  State<SelecionarAlunoScreen> createState() => _SelecionarAlunoScreenState();
}

class _SelecionarAlunoScreenState extends State<SelecionarAlunoScreen> {
  final _alunoService = AlunoService();
  late final Stream<List<Aluno>> _alunosStream = _alunoService.listar();

  String _busca = '';

  List<Aluno> _filtrar(List<Aluno> alunos) {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return alunos;

    return alunos.where((aluno) {
      return aluno.nome.toLowerCase().contains(termo) ||
          aluno.matricula.toLowerCase().contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.person_search_outlined,
          texto: 'Selecionar Aluno',
        ),
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
                    labelText: 'Buscar por nome ou matrícula',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Aluno>>(
                  stream: _alunosStream,
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
                            'Cadastre ou importe alunos antes de corrigir.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: alunos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final aluno = alunos[index];

                        return Card(
                          child: ListTile(
                            onTap: () => Navigator.pop(context, aluno),
                            leading: CircleAvatar(
                              child: Text(
                                aluno.nome.isNotEmpty
                                    ? aluno.nome[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(aluno.nome),
                            subtitle: Text('Matrícula: ${aluno.matricula}'),
                            trailing: const Icon(Icons.chevron_right),
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
