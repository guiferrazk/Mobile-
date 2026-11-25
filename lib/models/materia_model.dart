
import 'package:mobile/models/questao_model.dart';

class Materia {
  final String id;
  final String descricao;
  final List<Questao> questoes;

  Materia({
    required this.id,
    required this.descricao,
    this.questoes = const [],
  });

  /// Converte a matéria para o formato salvo no Firestore.
  /// As questões não vão junto: elas guardam o `materiaId` à parte.
  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
    };
  }

  /// Cria uma matéria a partir de um documento do Firestore.
  factory Materia.fromMap(String id, Map<String, dynamic> map) {
    return Materia(
      id: id,
      descricao: map['descricao'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is Materia && other.id == id;

  @override
  int get hashCode => id.hashCode;
}