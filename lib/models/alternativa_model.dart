class Alternativa {
  final String texto;
  final bool isCorreta;

  Alternativa({
    required this.texto,
    required this.isCorreta,
  });

  /// Converte a alternativa para o formato salvo no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'isCorreta': isCorreta,
    };
  }

  /// Cria uma alternativa a partir dos dados lidos do Firestore.
  factory Alternativa.fromMap(Map<String, dynamic> map) {
    return Alternativa(
      texto: map['texto'] as String? ?? '',
      isCorreta: map['isCorreta'] as bool? ?? false,
    );
  }
}