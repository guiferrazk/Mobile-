import 'package:flutter/material.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/materia_model.dart';
import 'package:mobile/models/questao_model.dart';

/// Tela onde o professor monta uma prova escolhendo questões do banco
/// (mock), dá um título a ela e gera a prova. A partir da prova gerada,
/// é possível simular a criação de variações, embaralhando a ordem das
/// questões e das alternativas de cada uma.
///
/// Ainda não há persistência real: a prova e as variações existem
/// apenas em memória, só para fins de visualização do fluxo.
class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

/// Representa a prova já montada pelo professor: um título e a lista
/// de questões escolhidas, na ordem em que foram selecionadas.
class _ProvaGerada {
  final String titulo;
  final List<Questao> questoes;

  _ProvaGerada({required this.titulo, required this.questoes});
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  final TextEditingController _tituloController = TextEditingController();

  final Set<String> _idsSelecionados = {};

  _ProvaGerada? _provaGerada;
  List<Questao>? _variacaoAtual;

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  /// Achata a lista de matérias em uma lista de pares (matéria, questão).
  List<MapEntry<Materia, Questao>> get _todasQuestoes {
    final List<MapEntry<Materia, Questao>> resultado = [];

    for (final materia in listaMateria) {
      for (final questao in materia.questoes) {
        resultado.add(MapEntry(materia, questao));
      }
    }

    return resultado;
  }

  /// Questões selecionadas, na ordem em que o professor as marcou
  /// (o Set mantém a ordem de inserção).
  List<Questao> get _questoesSelecionadas {
    final mapa = {for (final e in _todasQuestoes) e.value.id: e.value};
    return _idsSelecionados.map((id) => mapa[id]!).toList();
  }

  void _alternarSelecao(String questaoId, bool? selecionado) {
    setState(() {
      if (selecionado == true) {
        _idsSelecionados.add(questaoId);
      } else {
        _idsSelecionados.remove(questaoId);
      }
      // Qualquer mudança na seleção invalida a prova e a variação
      // já geradas, pois elas não refletiriam mais a seleção atual.
      _provaGerada = null;
      _variacaoAtual = null;
    });
  }

  /// Gera a prova de fato: valida título e seleção e monta a
  /// [_ProvaGerada] com as questões escolhidas.
  void _gerarProva() {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a prova.')),
      );
      return;
    }

    if (_questoesSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos uma questão para gerar a prova.'),
        ),
      );
      return;
    }

    setState(() {
      _provaGerada = _ProvaGerada(
        titulo: titulo,
        questoes: List<Questao>.from(_questoesSelecionadas),
      );
      _variacaoAtual = null;
    });
  }

  /// Simula a geração de uma variação da prova já gerada: embaralha a
  /// ordem das questões e, dentro de cada uma, a ordem das alternativas.
  /// Cada clique gera uma nova ordem aleatória.
  void _gerarVariacao() {
    final prova = _provaGerada;
    if (prova == null) return;

    final questoesEmbaralhadas = List<Questao>.from(prova.questoes)
      ..shuffle();

    final variacao = questoesEmbaralhadas.map((questao) {
      final alternativasEmbaralhadas =
      List<Alternativa>.from(questao.alternativas)..shuffle();

      return Questao(
        id: questao.id,
        enunciado: questao.enunciado,
        alternativas: alternativasEmbaralhadas,
      );
    }).toList();

    setState(() => _variacaoAtual = variacao);
  }

  @override
  Widget build(BuildContext context) {
    final questoes = _todasQuestoes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Prova'),
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
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título da prova',
                    hintText: 'Ex: Avaliação de Direito - 1º Bimestre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Altura fixa para a lista de seleção: ela rola por conta
                // própria, sem depender do espaço restante da tela — é
                // isso que evita overflow quando o conteúdo abaixo cresce.
                SizedBox(
                  height: 320,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: questoes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final materia = questoes[index].key;
                        final questao = questoes[index].value;
                        final selecionada =
                        _idsSelecionados.contains(questao.id);

                        return CheckboxListTile(
                          value: selecionada,
                          onChanged: (valor) =>
                              _alternarSelecao(questao.id, valor),
                          title: Text(questao.enunciado),
                          subtitle: Text(materia.descricao),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_idsSelecionados.length} questão(ões) selecionada(s)',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _gerarProva,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Gerar Prova'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                if (_provaGerada != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ListaQuestoesPreview(questoes: _provaGerada!.questoes),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _gerarVariacao,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Gerar variação embaralhada'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  if (_variacaoAtual != null) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prévia da variação embaralhada',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ListaQuestoesPreview(questoes: _variacaoAtual!),
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

/// Mostra uma lista numerada de questões com suas alternativas
/// relabeladas como A, B, C, D — usada tanto para exibir a prova
/// gerada (ordem original de seleção) quanto uma variação embaralhada.
class _ListaQuestoesPreview extends StatelessWidget {
  final List<Questao> questoes;

  const _ListaQuestoesPreview({required this.questoes});

  @override
  Widget build(BuildContext context) {
    const letras = ['A', 'B', 'C', 'D', 'E', 'F'];

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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (var j = 0; j < questoes[i].alternativas.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        '${letras[j]}) ${questoes[i].alternativas[j].texto}',
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