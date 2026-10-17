
import 'package:flutter/material.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/services/prova_service.dart';
import 'package:mobile/services/questao_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

/// Tela para montar provas com questões cadastradas no Firestore.
/// A prova é salva no Firestore; a variação embaralhada é apenas uma prévia.
class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

/// Mantém as questões disponíveis na prévia da prova gerada.
class _ProvaGerada {
  final String titulo;
  final List<Questao> questoes;

  _ProvaGerada({
    required this.titulo,
    required this.questoes,
  });
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  final TextEditingController _tituloController =
      TextEditingController();

  final QuestaoService _questaoService = QuestaoService();
  final ProvaService _provaService = ProvaService();

  late final Stream<List<Questao>> _questoesStream =
      _questaoService.listar();

  List<Questao> _questoesDisponiveis = [];

  final Set<String> _idsSelecionados = {};

  _ProvaGerada? _provaGerada;
  List<Questao>? _variacaoAtual;

  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  /// Retorna o nome da matéria pelo seu ID.
  String _nomeMateria(String? materiaId) {
    for (final materia in listaMateria) {
      if (materia.id == materiaId) {
        return materia.descricao;
      }
    }

    return 'Sem matéria';
  }

  /// Retorna as questões na ordem em que foram selecionadas.
  List<Questao> get _questoesSelecionadas {
    final mapa = {
      for (final q in _questoesDisponiveis) q.id: q
    };

    return [
      for (final id in _idsSelecionados)
        if (mapa[id] != null) mapa[id]!,
    ];
  }

  /// Seleciona ou remove uma questão da prova.
  void _alternarSelecao(String questaoId, bool? selecionado) {
    setState(() {
      if (selecionado == true) {
        _idsSelecionados.add(questaoId);
      } else {
        _idsSelecionados.remove(questaoId);
      }

      // A alteração invalida a prova gerada anteriormente.
      _provaGerada = null;
      _variacaoAtual = null;
    });
  }

  /// Valida os dados e salva a prova no Firebase Firestore.
  Future<void> _gerarProva() async {
    if (_salvando) return;

    final titulo = _tituloController.text.trim();

    final questoesSelecionadas =
        List<Questao>.from(_questoesSelecionadas);

    // Verifica se o professor informou um título.
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um título para a prova.'),
        ),
      );
      return;
    }

    // Verifica se existem questões selecionadas.
    if (questoesSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione ao menos uma questão para gerar a prova.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      // Cria um objeto Prova com os dados selecionados.
      final prova = Prova(
        id: '',
        titulo: titulo,
        questaoIds: questoesSelecionadas
            .map((questao) => questao.id)
            .toList(),
      );

      // Salva a prova no Firestore.
      // O Firebase gera automaticamente o ID do documento.
      await _provaService.cadastrar(prova);

      if (!mounted) return;

      // Mostra a prova gerada somente após salvar.
      setState(() {
        _provaGerada = _ProvaGerada(
          titulo: titulo,
          questoes: questoesSelecionadas,
        );

        _variacaoAtual = null;
      });

      // Mensagem de sucesso.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prova salva com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      // Mensagem caso o Firebase apresente algum erro.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar prova: $erro'),
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

  /// Gera uma variação embaralhada da prova.
  /// A variação é apenas uma prévia, não sendo salva.
  void _gerarVariacao() {
    final prova = _provaGerada;

    if (prova == null) return;

    // Embaralha a ordem das questões.
    final questoesEmbaralhadas =
        List<Questao>.from(prova.questoes)..shuffle();

    // Embaralha as alternativas de cada questão.
    final variacao = questoesEmbaralhadas.map((questao) {
      final alternativasEmbaralhadas =
          List<Alternativa>.from(questao.alternativas)
            ..shuffle();

      return Questao(
        id: questao.id,
        enunciado: questao.enunciado,
        alternativas: alternativasEmbaralhadas,
        materiaId: questao.materiaId,
      );
    }).toList();

    setState(() {
      _variacaoAtual = variacao;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.edit_note,
          texto: 'Criar Prova',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dê um título à prova e selecione as questões do banco. '
                  'Depois, gere a prova. A partir dela você pode gerar '
                  'variações, embaralhando a ordem das questões e das '
                  'alternativas — útil para dificultar a cola entre alunos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 16),

                // Campo para informar o título da prova.
                TextFormField(
                  controller: _tituloController,
                  readOnly: _salvando,
                  onChanged: (_) {
                    // Invalida a prévia se o título for alterado.
                    if (_provaGerada != null ||
                        _variacaoAtual != null) {
                      setState(() {
                        _provaGerada = null;
                        _variacaoAtual = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Título da prova',
                    hintText:
                        'Ex: Avaliação de Direito - 1º Bimestre',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de questões disponíveis no Firestore.
                SizedBox(
                  height: 320,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: StreamBuilder<List<Questao>>(
                      stream: _questoesStream,
                      builder: (context, snapshot) {
                        // Verifica possíveis erros.
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar questões:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        // Exibe carregamento enquanto busca os dados.
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final questoes = snapshot.data!;

                        _questoesDisponiveis = questoes;

                        // Verifica se existem questões cadastradas.
                        if (questoes.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhuma questão cadastrada no banco.',
                            ),
                          );
                        }

                        // Exibe as questões com opção de seleção.
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          itemCount: questoes.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final questao = questoes[index];

                            final selecionada =
                                _idsSelecionados.contains(
                              questao.id,
                            );

                            return CheckboxListTile(
                              value: selecionada,
                              onChanged: _salvando
                                  ? null
                                  : (valor) =>
                                      _alternarSelecao(
                                        questao.id,
                                        valor,
                                      ),
                              title: Text(questao.enunciado),
                              subtitle: Text(
                                _nomeMateria(questao.materiaId),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quantidade de questões selecionadas.
                Text(
                  '${_idsSelecionados.length} questão(ões) selecionada(s)',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Botão para gerar e salvar a prova.
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _gerarProva,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.description_outlined,
                        ),
                  label: Text(
                    _salvando ? 'Salvando...' : 'Gerar Prova',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ),
                  ),
                ),

                // Exibe a prova após o salvamento.
                if (_provaGerada != null) ...[
                  const SizedBox(height: 24),

                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _provaGerada!.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_provaGerada!.questoes.length} questões nesta prova',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Questões da prova',
                      style:
                          Theme.of(context).textTheme.titleMedium,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Prévia da prova original.
                  _ListaQuestoesPreview(
                    questoes: _provaGerada!.questoes,
                  ),

                  const SizedBox(height: 24),

                  // Botão para gerar uma variação embaralhada.
                  ElevatedButton.icon(
                    onPressed: _gerarVariacao,
                    icon: const Icon(Icons.shuffle),
                    label: const Text(
                      'Gerar variação embaralhada',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                    ),
                  ),

                  // Prévia da variação embaralhada.
                  if (_variacaoAtual != null) ...[
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prévia da variação embaralhada',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _ListaQuestoesPreview(
                      questoes: _variacaoAtual!,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exibe as questões com alternativas numeradas.
class _ListaQuestoesPreview extends StatelessWidget {
  final List<Questao> questoes;

  const _ListaQuestoesPreview({
    required this.questoes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < questoes.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${questoes[i].enunciado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  for (var j = 0;
                      j < questoes[i].alternativas.length;
                      j++)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 2.0,
                      ),
                      child: Text(
                        '${String.fromCharCode(65 + j)}) ${questoes[i].alternativas[j].texto}',
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
