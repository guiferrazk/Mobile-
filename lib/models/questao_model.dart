
import 'package:mobile/models/alternativa_model.dart';

class Questao {
  final String id;
  final String enunciado;
  final List<Alternativa> alternativas;

  Questao({
    required this.id,
    required this.enunciado,
    required this.alternativas,
  });
}