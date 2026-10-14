import 'package:mobile/models/alternativa_model.dart';

class Questao {
  final String id;
  final String enunciado;
  final List<Alternativa> alternativas;

  /// Id da matéria à qual a questão pertence. É opcional para que o
  /// mock (que já agrupa as questões dentro de cada matéria) continue
  /// funcionando sem alteração.
  final String? materiaId;

  Questao({
    required this.id,
    required this.enunciado,
    required this.alternativas,
    this.materiaId,
  });

  /// Converte a questão para o formato salvo no Firestore.
  /// O [id] não vai junto: no Firestore ele é o id do documento.
  Map<String, dynamic> toMap() {
    return {
      'enunciado': enunciado,
      'materiaId': materiaId,
      'alternativas': alternativas.map((a) => a.toMap()).toList(),
    };
  }

  /// Cria uma questão a partir de um documento do Firestore.
  factory Questao.fromMap(String id, Map<String, dynamic> map) {
    final listaAlternativas = map['alternativas'] as List<dynamic>? ?? [];

    return Questao(
      id: id,
      enunciado: map['enunciado'] as String? ?? '',
      materiaId: map['materiaId'] as String?,
      alternativas: listaAlternativas
          .map((item) => Alternativa.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}