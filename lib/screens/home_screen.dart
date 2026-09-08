import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('Tela: Criar Prova')),
    Center(child: Text('Tela: Banco de Questões')),
    Center(child: Text('Tela: Corrigir Prova')),
    Center(child: Text('Tela: Relatórios')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corretor de Provas'),
        centerTitle: true, // Centraliza o texto no topo da tela
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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