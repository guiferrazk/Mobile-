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

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'alunos': alunos.map((aluno) => aluno.toMap()..['id'] = aluno.id).toList(),
    };
  }

  factory Turma.fromMap(String id, Map<String, dynamic> map) {
    final alunosData = map['alunos'] as List<dynamic>? ?? [];

    return Turma(
      id: id,
      nome: map['nome'] as String? ?? '',
      alunos: alunosData.map((item) {
        final alunoMap = Map<String, dynamic>.from(item as Map);
        final alunoId = alunoMap['id'] as String? ?? '';
        return Aluno.fromMap(alunoId, alunoMap);
      }).toList(),
    );
  }
}