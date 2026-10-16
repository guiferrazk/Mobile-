class Professor {
  final String uid;
  final String nomeCompleto;
  final String dataNascimento;
  final String email;
  final String? fotoUrl;

  Professor({
    required this.uid,
    required this.nomeCompleto,
    required this.dataNascimento,
    required this.email,
    this.fotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nomeCompleto': nomeCompleto,
      'dataNascimento': dataNascimento,
      'email': email,
      'fotoUrl': fotoUrl,
    };
  }

  factory Professor.fromMap(Map<String, dynamic> map, String uid) {
    return Professor(
      uid: uid,
      nomeCompleto: map['nomeCompleto'] as String? ?? '',
      dataNascimento: map['dataNascimento'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fotoUrl: map['fotoUrl'] as String?,
    );
  }
}