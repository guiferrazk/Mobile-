import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/utils/mensagens_erro.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import '../models/aluno_model.dart';
import '../models/prova_model.dart';
import '../models/questao_model.dart';
import '../models/resultado_model.dart';
import '../services/questao_service.dart';
import '../services/resultado_service.dart';
import 'resultado_prova_screen.dart';

/// Tela em que o professor reconhece, questão por questão, qual
/// alternativa o aluno marcou na folha de resposta física.
///
/// Não há leitura automática (OCR) da folha: o professor olha a folha e
/// toca na alternativa marcada, do mesmo jeito que já digita manualmente
/// o código da prova ou a matrícula do aluno quando a câmera não resolve.
/// Ao concluir, grava o resultado pelo [ResultadoService] (substituindo
/// um resultado anterior do mesmo aluno nessa prova, se existir) e mostra
/// a tela de resultado já corrigida.
class CorrigirRespostasScreen extends StatefulWidget {
  final Aluno aluno;
  final Prova prova;

  const CorrigirRespostasScreen({
    super.key,
    required this.aluno,
    required this.prova,
  });

  @override
  State<CorrigirRespostasScreen> createState() =>
      _CorrigirRespostasScreenState();
}

class _CorrigirRespostasScreenState extends State<CorrigirRespostasScreen> {
  final _questaoService = QuestaoService();
  final _resultadoService = ResultadoService();

  late Future<List<Questao>> _questoes;
  final Map<String, int?> _respostas = {};

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _questoes = _carregarQuestoes();
  }

  // Busca todas as questões e mantém só as da prova, na ordem do gabarito.
  Future<List<Questao>> _carregarQuestoes() async {
    final todasQuestoes = await _questaoService.listar().first;
    final questoesPorId = {for (final q in todasQuestoes) q.id: q};

    return [
      for (final id in widget.prova.questaoIds)
        if (questoesPorId[id] != null) questoesPorId[id]!,
    ];
  }

  Future<void> _concluirCorrecao(List<Questao> questoes) async {
    if (_salvando) return;

    setState(() => _salvando = true);

    try {
      final resultado = Resultado.corrigir(
        provaId: widget.prova.id,
        aluno: widget.aluno,
        questoes: questoes,
        respostas: _respostas,
      );

      await _resultadoService.salvar(resultado);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoProvaScreen(
            resultado: resultado,
            questoes: questoes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar o resultado. ${MensagensErro.de(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.fact_check_outlined,
          texto: 'Marcar Respostas',
        ),
      ),
      body: FutureBuilder<List<Questao>>(
        future: _questoes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar as questões da prova.\n${MensagensErro.de(snapshot.error)}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final questoes = snapshot.data!;

          if (questoes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Esta prova não tem questões cadastradas.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(widget.aluno.nome),
                      subtitle: Text(
                        'Matrícula: ${widget.aluno.matricula} · ${widget.prova.titulo}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: questoes.length,
                      itemBuilder: (context, index) {
                        return _CartaoQuestao(
                          numero: index + 1,
                          questao: questoes[index],
                          marcada: _respostas[questoes[index].id],
                          aoMarcar: (indice) {
                            setState(() {
                              _respostas[questoes[index].id] = indice;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed:
                          _salvando ? null : () => _concluirCorrecao(questoes),
                      icon: _salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _salvando ? 'Salvando...' : 'Concluir correção',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Uma questão com suas alternativas, para o professor marcar qual delas
/// o aluno escolheu na folha física (ou deixar em branco).
class _CartaoQuestao extends StatelessWidget {
  final int numero;
  final Questao questao;
  final int? marcada;
  final ValueChanged<int?> aoMarcar;

  const _CartaoQuestao({
    required this.numero,
    required this.questao,
    required this.marcada,
    required this.aoMarcar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questão $numero',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(questao.enunciado),
            const SizedBox(height: 8),
            for (var i = 0; i < questao.alternativas.length; i++)
              RadioListTile<int?>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: i,
                groupValue: marcada,
                onChanged: aoMarcar,
                title: Text(
                  '${String.fromCharCode(65 + i)}) ${questao.alternativas[i].texto}',
                ),
              ),
            RadioListTile<int?>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: null,
              groupValue: marcada,
              onChanged: aoMarcar,
              title: const Text(
                'Em branco / marcação inválida',
                style: TextStyle(color: AppCores.textoSuave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
