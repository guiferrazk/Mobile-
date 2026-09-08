
import 'package:mobile/models/questao_model.dart';

class Materia {
  final String id;
  final String descricao;
  final List<Questao> questoes;

  Materia({
    required this.id,
    required this.descricao,
    required this.questoes,
  });
}