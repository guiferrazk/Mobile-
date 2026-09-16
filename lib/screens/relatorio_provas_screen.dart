import 'package:flutter/material.dart';

class RelatorioProvasScreen extends StatelessWidget {
  const RelatorioProvasScreen({super.key});

  static const List<Map<String, dynamic>> provasCorrigidas = [
    {
      'aluno': 'Ana Silva',
      'turma': 'Engenharia de Software - 4º Semestre',
      'nota': 9.5,
      'acertos': '19/20',
      'data': '10/05/2026',
    },
    {
      'aluno': 'Bruno Souza',
      'turma': 'Engenharia de Software - 4º Semestre',
      'nota': 7.0,
      'acertos': '14/20',
      'data': '10/05/2026',
    },
    {
      'aluno': 'Carla Mendes',
      'turma': 'Engenharia de Software - 4º Semestre',
      'nota': 5.5,
      'acertos': '11/20',
      'data': '10/05/2026',
    },
    {
      'aluno': 'Diego Ferreira',
      'turma': 'Engenharia de Software - 4º Semestre',
      'nota': 8.0,
      'acertos': '16/20',
      'data': '10/05/2026',
    },
  ];

  Color getNotaColor(double nota) {
    if (nota >= 7) {
      return Colors.green;
    } else if (nota >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provas Corrigidas'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provasCorrigidas.length,
        itemBuilder: (context, index) {
          final prova = provasCorrigidas[index];

          final String aluno = prova['aluno'];
          final String turma = prova['turma'];
          final double nota = prova['nota'];
          final String acertos = prova['acertos'];
          final String data = prova['data'];

          final Color notaColor = getNotaColor(nota);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: notaColor.withOpacity(0.15),
                child: Text(
                  nota.toStringAsFixed(1),
                  style: TextStyle(
                    color: notaColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                aluno,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(turma),
                  Text('Acertos: $acertos'),
                  Text('Data: $data'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}