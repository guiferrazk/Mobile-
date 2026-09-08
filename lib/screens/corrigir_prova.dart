import 'package:flutter/material.dart';

import '../mocks/mock_materia.dart';
import '../mocks/mock_aluno.dart';
import '../models/materia_model.dart';
import '../models/aluno_model.dart';

/// Tela que simula o fluxo de correção de provas.
///
/// Ainda não há integração com a câmera: os botões apenas navegam
/// para telas de resultado usando dados fixos vindos dos mocks,
/// como se a leitura tivesse sido feita com sucesso.
class CorrigirProvaScreen extends StatelessWidget {
  const CorrigirProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir Prova'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // Limita a largura do conteúdo em telas grandes (web/desktop)
            // e deixa tudo centralizado, evitando botões esticados
            // de ponta a ponta da tela.
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Para corrigir a prova, leia primeiro o QR Code do '
                      'gabarito e, em seguida, a prova do aluno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _lerQrCodeGabarito(context),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Ler QR Code do gabarito'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _lerProvaAluno(context),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Ler prova do aluno'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Simula a leitura do QR Code do gabarito.
  /// Sem câmera real ainda: usa a primeira matéria do mock como se
  /// tivesse sido identificada a partir do QR Code escaneado.
  void _lerQrCodeGabarito(BuildContext context) {
    final Materia gabarito = listaMateria.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GabaritoLidoScreen(materia: gabarito),
      ),
    );
  }

  /// Simula a leitura da folha de respostas do aluno.
  /// Sem câmera real ainda: usa o primeiro aluno do mock como se
  /// tivesse sido identificado a partir da prova escaneada.
  void _lerProvaAluno(BuildContext context) {
    final Aluno aluno = listaAluno.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaAlunoLidaScreen(aluno: aluno),
      ),
    );
  }
}

/// Tela exibida após a simulação da leitura do QR Code do gabarito.
class GabaritoLidoScreen extends StatelessWidget {
  final Materia materia;

  const GabaritoLidoScreen({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gabarito Lido'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Gabarito identificado com sucesso!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text('Matéria: ${materia.descricao}'),
                const SizedBox(height: 8),
                Text('Quantidade de questões: ${materia.questoes.length}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela exibida após a simulação da leitura da prova do aluno.
class ProvaAlunoLidaScreen extends StatelessWidget {
  final Aluno aluno;

  const ProvaAlunoLidaScreen({super.key, required this.aluno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prova do Aluno Lida'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Prova identificada com sucesso!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text('Aluno: ${aluno.nome}'),
                const SizedBox(height: 8),
                Text('Matrícula: ${aluno.matricula}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}