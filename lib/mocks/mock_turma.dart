import 'package:mobile/mocks/mock_aluno.dart';
import 'package:mobile/models/turma_model.dart';

final List<Turma> listaTurma = <Turma>[
  Turma(
    id: '1',
    nome: 'Turma A - Direito Matutino',
    alunos: listaAluno.sublist(0, 10),
  ),
  Turma(
    id: '2',
    nome: 'Turma B - Direito Vespertino',
    alunos: listaAluno.sublist(10, 20),
  ),
  Turma(
    id: '3',
    nome: 'Turma C - Direito Noturno',
    alunos: listaAluno.sublist(20, 30),
  ),
];