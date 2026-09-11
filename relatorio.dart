import 'package:flutter/material.dart';

// Tela principal da Issue 6: exibição de relatórios usando StatelessWidget por ser estática na N1

class RelatorioProvasScreen extends StatelessWidget {

  const RelatorioProvasScreen({super.key});

  // MOCK DE DADOS: Dados simulados em memória para atender aos requisitos visuais e de UI da N1 sem necessidade de backend real

  final List<Map<String, dynamic>> _provasCorrigidasMock = const [

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

  // REGRA DE NEGÓCIO VISUAL: Define dynamicamente a cor do badge com base no desempenho (Verde >= 7, Laranja >= 5, Vermelho < 5)

  Color _getNotaColor(double nota) {

    if (nota >= 7.0) return Colors.green.shade700;

    if (nota >= 5.0) return Colors.orange.shade700;

    return Colors.red.shade700;

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Provas Corrigidas'),

        actions: [

          // BOTÃO DE AÇÃO FUTURA: Prepara o local para a funcionalidade exigida no escopo do cliente (Exportação Excel) sem quebrar a execução na N1

          IconButton(

            icon: const Icon(Icons.file_download_outlined),

            tooltip: 'Exportar Excel (Em breve)',

            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(

                const SnackBar(

                  content: Text('Funcionalidade de exportação para Excel na N2/N3'), // Feedback visual provisório[cite: 1]

                ),

              );

            },

          )

        ],

      ),

      // RENDERIZAÇÃO DE LISTA: ListView.builder garante boa performance reciclando elementos visuais na tela

      body: ListView.builder(

        padding: const EdgeInsets.all(12.0),

        itemCount: _provasCorrigidasMock.length,

        itemBuilder: (context, index) {

          final prova = _provasCorrigidasMock[index];

          final double nota = prova['nota'];

          return Card(

            elevation: 2,

            margin: const EdgeInsets.symmetric(vertical: 6.0),

            child: ListTile(

              // BADGE EM DESTAQUE: CircleAvatar exibe a nota formatada com a cor dinâmica calculada

              leading: CircleAvatar(

                backgroundColor: _getNotaColor(nota).withOpacity(0.15),

                child: Text(

                  nota.toStringAsFixed(1),

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    color: _getNotaColor(nota),

                  ),

                ),

              ),

              // DADOS RELEVANTES: Exibe o nome do aluno em destaque principal

              title: Text(

                prova['aluno'],

                style: const TextStyle(fontWeight: FontWeight.bold),

              ),

              // INFORMAÇÕES SECUNDÁRIAS: Mostra turma, quantitativo de acertos e data da avaliação formatados em múltiplas linhas

              subtitle: Text('${prova['turma']}\nAcertos: ${prova['acertos']} • Data: ${prova['data']}'),

              isThreeLine: true,

              trailing: const Icon(Icons.chevron_right),

              // NAVEGAÇÃO PROVISÓRIA: Espaço reservado para abrir os detalhes das alternativas marcadas na Fase N2[cite: 1]

              onTap: () {},

            ),

          );

        },

      ),

    );

  }

}
