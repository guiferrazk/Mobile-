import 'package:flutter/material.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/services/prova_service.dart';
import 'package:mobile/services/questao_service.dart';
import 'package:mobile/services/resultado_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

/// Dados necessários para montar as estatísticas de uma prova.
class _DadosEstatisticas {
  final Prova prova;
  final List<Questao> questoes;
  final List<Resultado> resultados;

  _DadosEstatisticas({
    required this.prova,
    required this.questoes,
    required this.resultados,
  });
}

/// Mostra, para cada questão da prova, quantos alunos marcaram cada
/// alternativa. A alternativa correta aparece em verde.
class EstatisticasProvaScreen extends StatefulWidget {
  final String provaId;

  const EstatisticasProvaScreen({super.key, required this.provaId});

  @override
  State<EstatisticasProvaScreen> createState() =>
      _EstatisticasProvaScreenState();
}

class _EstatisticasProvaScreenState extends State<EstatisticasProvaScreen> {
  final ProvaService _provaService = ProvaService();
  final QuestaoService _questaoService = QuestaoService();
  final ResultadoService _resultadoService = ResultadoService();

  late Future<_DadosEstatisticas> _dados;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  void _recarregar() {
    setState(() {
      _dados = _carregar();
    });
  }

  // Busca a prova, as questões e os resultados no Firestore.
  Future<_DadosEstatisticas> _carregar() async {
    final prova = await _provaService.buscarPorId(widget.provaId);
    if (prova == null) {
      throw Exception('Prova não encontrada.');
    }

    final todasQuestoes = await _questaoService.listar().first;
    final resultados =
        await _resultadoService.listarPorProva(widget.provaId).first;

    // Mantém as questões na ordem em que aparecem na prova.
    final questoesPorId = {for (final q in todasQuestoes) q.id: q};
    final questoes = <Questao>[];
    for (final id in prova.questaoIds) {
      final questao = questoesPorId[id];
      if (questao != null) {
        questoes.add(questao);
      }
    }

    return _DadosEstatisticas(
      prova: prova,
      questoes: questoes,
      resultados: resultados,
    );
  }

  // Conta quantos alunos marcaram cada alternativa da questão.
  List<int> _contarMarcacoes(Questao questao, List<Resultado> resultados) {
    final contagem = List<int>.filled(questao.alternativas.length, 0);

    for (final resultado in resultados) {
      final marcada = resultado.respostas[questao.id];
      if (marcada != null && marcada >= 0 && marcada < contagem.length) {
        contagem[marcada]++;
      }
    }

    return contagem;
  }

  Widget _mensagem(IconData icone, Color cor, String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: cor),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(_DadosEstatisticas dados) {
    final resultados = dados.resultados;
    final media =
        resultados.fold<double>(0, (soma, r) => soma + r.nota) /
            resultados.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dados.prova.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Provas corrigidas: ${resultados.length}'),
            Text('Média das notas: ${media.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  Widget _linhaAlternativa({
    required String letra,
    required String texto,
    required int quantidade,
    required int total,
    required bool correta,
  }) {
    final double proporcao = total == 0 ? 0 : quantidade / total;
    final Color cor = correta ? Colors.green : Colors.deepPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$letra) $texto',
                  style: TextStyle(
                    fontWeight: correta ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (correta)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                ),
              const SizedBox(width: 8),
              Text('$quantidade (${(proporcao * 100).round()}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: proporcao,
            minHeight: 8,
            color: cor,
            backgroundColor: cor.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _cartaoQuestao(
    int numero,
    Questao questao,
    List<Resultado> resultados,
  ) {
    final total = resultados.length;
    final contagem = _contarMarcacoes(questao, resultados);
    final marcadas = contagem.fold<int>(0, (soma, valor) => soma + valor);
    final emBranco = total - marcadas;

    final indiceCorreto = questao.alternativas.indexWhere((a) => a.isCorreta);
    final acertos = indiceCorreto >= 0 ? contagem[indiceCorreto] : 0;
    final taxaAcerto = total == 0 ? 0 : (acertos * 100 / total).round();

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
            const SizedBox(height: 12),
            for (var i = 0; i < questao.alternativas.length; i++)
              _linhaAlternativa(
                letra: String.fromCharCode(65 + i),
                texto: questao.alternativas[i].texto,
                quantidade: contagem[i],
                total: total,
                correta: questao.alternativas[i].isCorreta,
              ),
            const Divider(),
            Text('Acertos: $acertos de $total ($taxaAcerto%)'),
            if (emBranco > 0) Text('Em branco ou inválidas: $emBranco'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.bar_chart,
          texto: 'Estatísticas da Prova',
        ),
      ),
      body: FutureBuilder<_DadosEstatisticas>(
        future: _dados,
        builder: (context, snapshot) {
          // Estado de carregamento.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de erro.
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar as estatísticas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dados = snapshot.data!;

          // Estados vazios.
          if (dados.resultados.isEmpty) {
            return _mensagem(
              Icons.assignment_outlined,
              Colors.grey,
              'Esta prova ainda não tem resultados.',
            );
          }
          if (dados.questoes.isEmpty) {
            return _mensagem(
              Icons.help_outline,
              Colors.grey,
              'Esta prova não tem questões cadastradas.',
            );
          }

          // Cabeçalho e uma carta por questão.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dados.questoes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _cabecalho(dados);
                  }
                  return _cartaoQuestao(
                    index,
                    dados.questoes[index - 1],
                    dados.resultados,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}