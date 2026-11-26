import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';
import 'package:mobile/utils/mensagens_erro.dart';

import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/services/aluno_service.dart';
import 'package:mobile/services/variacao_prova_service.dart';
import 'package:mobile/theme/app_theme.dart';

/// Lista os alunos cadastrados no Firestore para o professor escolher
/// de quem é a prova que está sendo corrigida.
///
/// Com [provaId], mostra só os alunos que têm a prova gerada (variação
/// salva). Se nenhum tiver, mostra todos. Devolve o [Aluno] selecionado com
/// `Navigator.pop`.
class SelecionarAlunoScreen extends StatefulWidget {
  final String? provaId;

  const SelecionarAlunoScreen({super.key, this.provaId});

  /// Alunos de [todos] que estão em [comProva]. Se ninguém tiver a prova
  /// (conjunto vazio ou nulo), devolve todos.
  static List<Aluno> alunosDaProva(List<Aluno> todos, Set<String>? comProva) {
    if (comProva == null || comProva.isEmpty) return todos;
    return todos.where((aluno) => comProva.contains(aluno.id)).toList();
  }

  @override
  State<SelecionarAlunoScreen> createState() => _SelecionarAlunoScreenState();
}

class _SelecionarAlunoScreenState extends State<SelecionarAlunoScreen> {
  final _alunoService = AlunoService();
  late final Stream<List<Aluno>> _alunosStream = _alunoService.listar();

  String _busca = '';

  /// Alunos com a prova gerada; `null` enquanto carrega ou sem prova.
  Set<String>? _comProva;
  bool _mostrarTodos = false;

  @override
  void initState() {
    super.initState();
    final provaId = widget.provaId;
    if (provaId != null) _carregarAlunosDaProva(provaId);
  }

  Future<void> _carregarAlunosDaProva(String provaId) async {
    try {
      final ids = await VariacaoProvaService().alunosComVariacao(provaId);
      if (mounted) setState(() => _comProva = ids);
    } catch (_) {
      // Se não der para saber quem tem a prova, a lista mostra todos.
      if (mounted) setState(() => _comProva = {});
    }
  }

  List<Aluno> _filtrar(List<Aluno> todos) {
    final alunos = _mostrarTodos
        ? todos
        : SelecionarAlunoScreen.alunosDaProva(todos, _comProva);

    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return alunos;

    return alunos.where((aluno) {
      return aluno.nome.toLowerCase().contains(termo) ||
          aluno.matricula.toLowerCase().contains(termo);
    }).toList();
  }

  /// Explica o que a lista está mostrando quando uma prova foi escolhida.
  Widget? _avisoDaLista(int totalAlunos) {
    final comProva = _comProva;
    if (widget.provaId == null || comProva == null) return null;

    final String texto;
    Widget? acao;

    if (comProva.isEmpty) {
      texto = 'Nenhum aluno tem esta prova gerada ainda. '
          'Mostrando todos os alunos.';
    } else if (_mostrarTodos) {
      texto = 'Mostrando todos os $totalAlunos alunos.';
      acao = TextButton(
        onPressed: () => setState(() => _mostrarTodos = false),
        child: const Text('Só os desta prova'),
      );
    } else {
      texto = 'Mostrando os alunos com esta prova gerada.';
      acao = TextButton(
        onPressed: () => setState(() => _mostrarTodos = true),
        child: const Text('Mostrar todos'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppCores.textoSuave),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: AppCores.textoSuave),
            ),
          ),
          ?acao,
        ],
      ),
    );
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
                            'Não foi possível carregar os alunos.\n${MensagensErro.de(snapshot.error)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Espera saber quem tem a prova para não mostrar a
                    // lista completa e logo em seguida trocar.
                    if (widget.provaId != null && _comProva == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final alunos = _filtrar(snapshot.data!);
                    final aviso = _avisoDaLista(snapshot.data!.length);

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
                      itemCount: alunos.length + (aviso == null ? 0 : 1),
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        if (aviso != null && index == 0) return aviso;
                        final aluno = alunos[aviso == null ? index : index - 1];

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
