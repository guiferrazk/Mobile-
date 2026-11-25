import 'package:firebase_auth/firebase_auth.dart';

/// Nome do campo, em cada documento, com o uid do professor dono dele.
const campoProfessorId = 'professorId';

/// Uid do professor logado. Todo dado do app (alunos, turmas, matérias,
/// questões, provas e resultados) pertence a um professor e só é visto
/// por ele. Lança erro se ninguém estiver logado.
String professorIdAtual() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Nenhum professor logado.');
  }
  return uid;
}
