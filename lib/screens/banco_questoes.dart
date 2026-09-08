import 'package:flutter/material.dart';

import 'package:mobile/mocks/mock_materia.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/materia_model.dart';
import 'package:mobile/models/questao_model.dart';

/// Tela que lista as questões cadastradas.
///
/// Os dados vêm da lista mock [listaMateria]. O botão "Adicionar questão"
/// apenas abre o formulário de cadastro — nada é salvo de verdade ainda.
class BancoQuestoesScreen extends StatelessWidget {
  const BancoQuestoesScreen({super.key});

  /// Achata a lista de matérias em uma lista de pares (matéria, questão),
  /// já que aqui queremos exibir todas as questões juntas.
  List<MapEntry<Materia, Questao>> _todasQuestoes() {
    final List<MapEntry<Materia, Questao>> resultado = [];

    for (final materia in listaMateria) {
      for (final questao in materia.questoes) {
        resultado.add(MapEntry(materia, questao));
      }
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final questoes = _todasQuestoes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Questões'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: questoes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final materia = questoes[index].key;
          final questao = questoes[index].value;

          return Card(
            child: ExpansionTile(
              title: Text(questao.enunciado),
              subtitle: Text(materia.descricao),
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
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdicionarQuestaoScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Adicionar questão'),
      ),
    );
  }
}

/// Formulário de cadastro de uma nova questão.
///
/// Por enquanto não salva nada de fato — apenas exibe os campos e,
/// ao confirmar, retorna para a tela anterior.
class AdicionarQuestaoScreen extends StatefulWidget {
  const AdicionarQuestaoScreen({super.key});

  @override
  State<AdicionarQuestaoScreen> createState() =>
      _AdicionarQuestaoScreenState();
}

class _AdicionarQuestaoScreenState extends State<AdicionarQuestaoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _enunciadoController = TextEditingController();

  final List<TextEditingController> _alternativasControllers =
  List.generate(4, (_) => TextEditingController());

  Materia? _materiaSelecionada;
  int _alternativaCorretaIndex = 0;

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (final controller in _alternativasControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _salvarQuestao() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ainda não há persistência real: apenas simula o cadastro
    // e volta para a tela de listagem.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Questão cadastrada (simulado)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Questão'),
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
                    validator: (valor) => (valor == null || valor.isEmpty)
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
                              (valor == null || valor.isEmpty)
                                  ? 'Informe o texto da alternativa'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _salvarQuestao,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Salvar questão'),
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