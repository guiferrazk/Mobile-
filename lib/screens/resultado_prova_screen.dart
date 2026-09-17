import 'package:flutter/material.dart';
import 'home_screen.dart'; // Importação adicionada para a Home

class ResultadoProvaScreen extends StatelessWidget {
  // 1. Dados fixos (mockados) para simular o resultado
  final double notaFinal = 8.0;
  final int totalAcertos = 4;
  final int totalQuestoes = 5;

  // Lista simulando quais questões o aluno acertou/errou
  final List<Map<String, dynamic>> resultadoQuestoes = [
    {'questao': 1, 'status': 'Correta', 'cor': Colors.green, 'icone': Icons.check_circle},
    {'questao': 2, 'status': 'Correta', 'cor': Colors.green, 'icone': Icons.check_circle},
    {'questao': 3, 'status': 'Incorreta', 'cor': Colors.red, 'icone': Icons.cancel},
    {'questao': 4, 'status': 'Correta', 'cor': Colors.green, 'icone': Icons.check_circle},
    {'questao': 5, 'status': 'Correta', 'cor': Colors.green, 'icone': Icons.check_circle},
  ];

  ResultadoProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Correção'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Card de Destaque para a Nota Final
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Nota Final',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notaFinal.toStringAsFixed(1), // Mostra "8.0"
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        // Muda a cor da nota dependendo se foi bem ou mal
                        color: notaFinal >= 6.0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Acertos: $totalAcertos de $totalQuestoes',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
            
            // 3. Lista (ListView) rolável mostrando as questões
            Expanded(
              child: ListView.builder(
                itemCount: resultadoQuestoes.length,
                itemBuilder: (context, index) {
                  final item = resultadoQuestoes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        item['icone'],
                        color: item['cor'],
                        size: 32,
                      ),
                      title: Text(
                        'Questão ${item['questao']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item['status'],
                        style: TextStyle(
                          color: item['cor'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 4. Botão para voltar à tela principal (Home)
            ElevatedButton(
              onPressed: () {
                // Apaga todo o histórico de telas e joga para a HomeScreen
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