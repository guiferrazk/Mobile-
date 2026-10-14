class Aluno {
  final String id;
  final String nome;
  final String email;
  final String matricula;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    required this.matricula,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'matricula': matricula,
    };
  }

  factory Aluno.fromMap(String id, Map<String, dynamic> map) {
    return Aluno(
      id: id,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      matricula: map['matricula'] as String? ?? '',
    );
  }
}