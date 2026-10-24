import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/identificacao_prova.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/resultado_model.dart';

Questao _questao(String id, int indiceCorreta) {
  return Questao(
    id: id,
    enunciado: 'Questão $id',
    alternativas: [
      for (var i = 0; i < 4; i++)
        Alternativa(texto: 'Alternativa $i', isCorreta: i == indiceCorreta),
    ],
  );
}

void main() {
  group('IdentificacaoProva', () {
    test('o texto codificado volta para a mesma prova e aluno', () {
      final original = IdentificacaoProva(provaId: 'prova123', alunoId: 'aluno456');

      expect(original.codificar(), 'CORRETOR|1|prova123|aluno456');
      expect(IdentificacaoProva.decodificar(original.codificar()), original);
    });

    test('recusa QR Codes que não são do app', () {
      for (final conteudo in [
        '',
        'https://exemplo.com',
        'CORRETOR|1|prova123',
        'CORRETOR|2|prova123|aluno456',
        'OUTRO|1|prova123|aluno456',
        'CORRETOR|1||aluno456',
        'CORRETOR|1|pro/va|aluno456',
      ]) {
        expect(IdentificacaoProva.decodificar(conteudo), isNull, reason: conteudo);
      }
    });

    test('não aceita ids inválidos ao gerar o QR Code', () {
      expect(
        () => IdentificacaoProva(provaId: '', alunoId: 'aluno456'),
        throwsArgumentError,
      );
    });
  });

  group('Resultado', () {
    final aluno = Aluno(
      id: 'aluno456',
      nome: 'Ana Souza',
      email: 'ana@email.com',
      matricula: '2024001',
    );
    final questoes = [_questao('q1', 0), _questao('q2', 2), _questao('q3', 1)];

    test('conta acertos comparando com a alternativa correta', () {
      final resultado = Resultado.corrigir(
        provaId: 'prova123',
        aluno: aluno,
        questoes: questoes,
        respostas: {'q1': 0, 'q2': 1, 'q3': null},
      );

      expect(resultado.acertos, 1);
      expect(resultado.totalQuestoes, 3);
      expect(resultado.nota, closeTo(3.33, 0.01));
      expect(resultado.id, 'prova123_aluno456');
      expect(resultado.alunoNome, 'Ana Souza');
    });

    test('questões sem resposta entram como em branco', () {
      final resultado = Resultado.corrigir(
        provaId: 'prova123',
        aluno: aluno,
        questoes: questoes,
        respostas: {'q1': 0, 'outra': 3},
      );

      expect(resultado.respostas, {'q1': 0, 'q2': null, 'q3': null});
    });

    test('prova sem questões tem nota zero', () {
      final resultado = Resultado.corrigir(
        provaId: 'prova123',
        aluno: aluno,
        questoes: [],
        respostas: {},
      );

      expect(resultado.nota, 0);
    });

    test('toMap e fromMap preservam os dados', () {
      final original = Resultado.corrigir(
        provaId: 'prova123',
        aluno: aluno,
        questoes: questoes,
        respostas: {'q1': 0, 'q2': 2, 'q3': null},
      );
      final data = DateTime(2026, 10, 24);

      final lido = Resultado.fromMap(original.toMap(), corrigidoEm: data);

      expect(lido.id, original.id);
      expect(lido.alunoMatricula, '2024001');
      expect(lido.respostas, original.respostas);
      expect(lido.acertos, 2);
      expect(lido.totalQuestoes, 3);
      expect(lido.corrigidoEm, data);
    });
  });
}
