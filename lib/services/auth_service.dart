import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/models/professor_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  Stream<User?> get statusAutenticacao => _auth.authStateChanges();

  /// Login de professor
  Future<UserCredential> login(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha.trim(),
    );
  }

  Future<void> atualizarPerfil({
    required String nomeCompleto,
    required String dataNascimento, // Adicionado aqui
    String? fotoUrl,
  }) async {
    final uid = usuarioAtual?.uid;
    if (uid == null) return;

    await _db.collection('professores').doc(uid).update({
      'nomeCompleto': nomeCompleto.trim(),
      'dataNascimento': dataNascimento.trim(), // Salvando a data corrigida
      'fotoUrl': fotoUrl,
    });
  }

  /// Cadastro de professor
  Future<void> cadastrarProfessor({
    required String nomeCompleto,
    required String dataNascimento,
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha.trim(),
    );

    final uid = credencial.user!.uid;

    final novoProfessor = Professor(
      uid: uid,
      nomeCompleto: nomeCompleto.trim(),
      dataNascimento: dataNascimento.trim(),
      email: email.trim(),
    );

    await _db.collection('professores').doc(uid).set(novoProfessor.toMap());
  }

  /// Busca os dados do professor logado no Firestore
  Future<Professor?> obterPerfil() async {
    final uid = usuarioAtual?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('professores').doc(uid).get();
    if (!doc.exists) return null;

    return Professor.fromMap(doc.data()!, uid);
  }

  /// Logout
  Future<void> sair() async {
    await _auth.signOut();
  }
}