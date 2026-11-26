import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/screens/selecionar_aluno_screen.dart';

Aluno _aluno(String id, String nome) =>
    Aluno(id: id, nome: nome, email: '$id@email.com', matricula: id);

void main() {
  final todos = [
    _aluno('a1', 'Ana Souza'),
    _aluno('a2', 'Bruno Lima'),
    _aluno('a3', 'Camila Alves'),
  ];

  test('com prova gerada para alguns alunos, lista só esses', () {
    final alunos = SelecionarAlunoScreen.alunosDaProva(todos, {'a1', 'a3'});

    expect(alunos.map((a) => a.nome), ['Ana Souza', 'Camila Alves']);
  });

  test('sem nenhum aluno com a prova gerada, lista todos', () {
    expect(SelecionarAlunoScreen.alunosDaProva(todos, {}), todos);
  });

  test('sem prova escolhida, lista todos', () {
    expect(SelecionarAlunoScreen.alunosDaProva(todos, null), todos);
  });

  test('ignora variações de alunos que não são do professor', () {
    final alunos = SelecionarAlunoScreen.alunosDaProva(todos, {
      'a2',
      'de-outro-professor',
    });

    expect(alunos.map((a) => a.id), ['a2']);
  });
}
