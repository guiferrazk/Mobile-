import 'package:flutter/material.dart';

import 'banco_questoes.dart';
import 'cadastro_aluno.dart';
import 'consulta_aluno.dart';
import 'corrigir_prova.dart';
import 'criar_prova.dart';
import 'relatorio_provas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CriarProvaScreen(),
    BancoQuestoesScreen(),
    CorrigirProvaScreen(),
    RelatorioProvasScreen(),
  ];

  void _abrirTela(Widget tela) {
    Navigator.pop(context); // fecha o Drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corretor de Provas'),
        centerTitle: true, // Centraliza o texto no topo da tela
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Corretor de Provas',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Alunos',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Cadastrar aluno'),
              onTap: () => _abrirTela(const CadastroAlunoScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Consultar alunos'),
              onTap: () => _abrirTela(const ConsultaAlunoScreen()),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Criar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Banco',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Corrigir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}