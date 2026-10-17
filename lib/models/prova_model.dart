
class Prova {
  final String id;
  final String titulo;
  final List<String> questaoIds;

  const Prova({
    required this.id,
    required this.titulo,
    required this.questaoIds,
  });

  // Converte a prova em dados para o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'questaoIds': questaoIds,
    };
  }

  // Converte os dados do Firestore em uma Prova.
  factory Prova.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Prova(
      id: id,
      titulo: map['titulo'] as String? ?? '',
      questaoIds: List<String>.from(
        map['questaoIds'] ?? [],
      ),
    );
  }
}
