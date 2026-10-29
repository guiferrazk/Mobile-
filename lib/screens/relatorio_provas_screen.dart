import 'package:flutter/material.dart';
import 'package:mobile/models/resultado_model.dart';
import 'package:mobile/services/resultado_service.dart';
import 'package:mobile/widgets/titulo_pagina.dart';
import 'package:mobile/screens/estatisticas_prova_screen.dart';

/// Lista as provas já corrigidas, lendo os resultados do Firestore
/// (coleção `resultados`). A lista atualiza sozinha quando um resultado
/// novo é salvo.
class RelatorioProvasScreen extends StatefulWidget {
  const RelatorioProvasScreen({super.key});

  @override
  State<RelatorioProvasScreen> createState() => _RelatorioProvasScreenState();
}

class _RelatorioProvasScreenState extends State<RelatorioProvasScreen> {
  final ResultadoService _resultadoService = ResultadoService();

  late Stream<List<Resultado>> _resultadosStream;

  @override
  void initState() {
    super.initState();
    _resultadosStream = _resultadoService.listarTodos();
  }

  // Cria o stream de novo. Usado no botão "Tentar novamente".
  void _recarregar() {
    setState(() {
      _resultadosStream = _resultadoService.listarTodos();
    });
  }

  Color _corDaNota(double nota) {
    if (nota >= 7) {
      return Colors.green;
    } else if (nota >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Formata a data como dd/MM/aaaa. Logo depois de salvar, o Firestore
  // ainda não devolveu a data do servidor, então ela pode vir nula.
  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Sem data';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloPagina(
          icone: Icons.insights,
          texto: 'Provas Corrigidas',
        ),
      ),
      body: StreamBuilder<List<Resultado>>(
        stream: _resultadosStream,
        builder: (context, snapshot) {
          // Estado de erro.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar as provas corrigidas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Verifique a conexão e tente novamente.',
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

          // Estado de carregamento.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resultados = snapshot.data!;

          // Estado vazio.
          if (resultados.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma prova corrigida ainda.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'As provas aparecem aqui depois de corrigidas.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Lista de resultados.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final resultado = resultados[index];
                  final Color corDaNota = _corDaNota(resultado.nota);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                                            onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EstatisticasProvaScreen(
                              provaId: resultado.provaId,
                            ),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.bar_chart),
                      leading: CircleAvatar(
                        backgroundColor: corDaNota.withValues(alpha: 0.15),
                        child: Text(
                          resultado.nota.toStringAsFixed(1),
                          style: TextStyle(
                            color: corDaNota,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        resultado.alunoNome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Matrícula: ${resultado.alunoMatricula}'),
                          Text(
                            'Acertos: ${resultado.acertos}/${resultado.totalQuestoes}',
                          ),
                          Text('Data: ${_formatarData(resultado.corrigidoEm)}'),
                        ],
                      ),
                    ),
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
