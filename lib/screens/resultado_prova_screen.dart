import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:mobile/theme/app_theme.dart';

import '../models/questao_model.dart';
import '../models/resultado_model.dart';

/// Mostra o resultado de uma correção: nota, acertos e, para cada
/// questão, se o aluno acertou, errou ou deixou em branco.
///
/// [questoes] deve ser a lista original (não embaralhada) usada para
/// corrigir o [resultado], na mesma ordem do gabarito da prova.
class ResultadoProvaScreen extends StatelessWidget {
  final Resultado resultado;
  final List<Questao> questoes;

  const ResultadoProvaScreen({
    super.key,
    required this.resultado,
    required this.questoes,
  });

  @override
  Widget build(BuildContext context) {
    final nota = resultado.nota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Correção'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      resultado.alunoNome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nota Final',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nota.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: nota >= 6.0 ? AppCores.sucesso : AppCores.erro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Acertos: ${resultado.acertos} de ${resultado.totalQuestoes}',
                      style: const TextStyle(fontSize: 16, color: AppCores.textoSuave),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Detalhes das Questões',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: questoes.length,
                itemBuilder: (context, index) {
                  final questao = questoes[index];
                  final indiceCorreto =
                      questao.alternativas.indexWhere((a) => a.isCorreta);
                  final marcada = resultado.respostas[questao.id];

                  final acertou = marcada != null && marcada == indiceCorreto;
                  final status = marcada == null
                      ? 'Em branco'
                      : (acertou ? 'Correta' : 'Incorreta');
                  final cor = marcada == null
                      ? AppCores.textoSuave
                      : (acertou ? AppCores.sucesso : AppCores.erro);
                  final icone = marcada == null
                      ? Icons.remove_circle_outline
                      : (acertou ? Icons.check_circle : Icons.cancel);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(icone, color: cor, size: 32),
                      title: Text(
                        'Questão ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        status,
                        style: TextStyle(color: cor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
