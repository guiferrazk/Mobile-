
import 'package:mobile/models/aluno_model.dart';

class Turma {
  final String id;
  final String nome;
  final List<Aluno> alunos;

  Turma({
    required this.id,
    required this.nome,
    required this.alunos,
  });
}