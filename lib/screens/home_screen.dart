import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corretor de Provas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: navegar para a tela de Criar Prova
              },
              child: const Text('Criar Prova'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: navegar para a tela de Banco de Questões
              },
              child: const Text('Banco de Questões'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: navegar para a tela de Corrigir Prova
              },
              child: const Text('Corrigir Prova'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: navegar para a tela de Relatórios
              },
              child: const Text('Relatórios'),
            ),
          ],
        ),
      ),
    );
  }
}