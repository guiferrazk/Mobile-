import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/alternativa_model.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/layout_folha.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/models/questao_model.dart';
import 'package:mobile/models/variacao_prova_model.dart';
import 'package:mobile/services/folha_respostas_pdf.dart';

const _prova = Prova(id: 'provaN3', titulo: 'Avaliação 1', questaoIds: ['q1', 'q2', 'q3']);

final _aluno = Aluno(
  id: 'aluno1',
  nome: 'Ana Beatriz Souza',
  email: 'ana@email.com',
  matricula: '2024001',
);

QuestaoVariada _questaoVariada(String id, int alternativas, {String? enunciado}) {
  return QuestaoVariada(
    questaoId: id,
    enunciado: enunciado ?? 'Enunciado da questão $id',
    alternativas: [
      for (var i = 0; i < alternativas; i++)
        Alternativa(texto: 'Alternativa $i', isCorreta: i == 0),
    ],
    indicesOriginais: List.generate(alternativas, (i) => i),
  );
}

VariacaoProva _variacao(int questoes, {int alternativas = 4, String alunoId = 'aluno1'}) {
  return VariacaoProva(
    provaId: _prova.id,
    alunoId: alunoId,
    questoes: [for (var i = 0; i < questoes; i++) _questaoVariada('q$i', alternativas)],
  );
}

/// Quantas páginas o PDF tem (cada página é um objeto "/Type /Page").
int _paginas(Uint8List pdf) {
  return RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(pdf)).length;
}

Matcher _erroCom(String trecho) {
  return throwsA(
    isA<FolhaRespostasException>().having((e) => e.mensagem, 'mensagem', contains(trecho)),
  );
}

void main() {
  group('Layout da folha', () {
    test('todas as bolinhas ficam dentro da área entre os marcadores', () {
      const meio = LayoutFolha.ladoMarcador / 2;
      final esquerda = LayoutFolha.centrosMarcadores[0].x + meio;
      final direita = LayoutFolha.centrosMarcadores[1].x - meio;
      final topo = LayoutFolha.centrosMarcadores[0].y + meio;
      final base = LayoutFolha.centrosMarcadores[2].y - meio;

      for (var q = 0; q < LayoutFolha.maxQuestoes; q++) {
        for (var a = 0; a < LayoutFolha.maxAlternativas; a++) {
          final c = LayoutFolha.centroBolha(q, a);
          expect(c.x - LayoutFolha.raioBolha, greaterThan(esquerda), reason: 'q$q a$a');
          expect(c.x + LayoutFolha.raioBolha, lessThan(direita), reason: 'q$q a$a');
          expect(c.y - LayoutFolha.raioBolha, greaterThan(topo), reason: 'q$q a$a');
          expect(c.y + LayoutFolha.raioBolha, lessThan(base), reason: 'q$q a$a');
        }
      }
    });

    test('as bolinhas não encostam umas nas outras', () {
      const folgaMinima = 2.0;
      expect(
        LayoutFolha.distanciaEntreBolhas - 2 * LayoutFolha.raioBolha,
        greaterThanOrEqualTo(folgaMinima),
      );
      expect(
        LayoutFolha.alturaLinha - 2 * LayoutFolha.raioBolha,
        greaterThanOrEqualTo(folgaMinima),
      );

      // A última bolinha da primeira coluna fica longe da numeração da segunda.
      final ultimaColuna1 = LayoutFolha.centroBolha(0, LayoutFolha.maxAlternativas - 1);
      final primeiraColuna2 = LayoutFolha.centroBolha(LayoutFolha.questoesPorColuna, 0);
      expect(primeiraColuna2.x - ultimaColuna1.x, greaterThan(30));
    });

    test('a grade começa abaixo do QR Code', () {
      final topoGrade = LayoutFolha.centroBolha(0, 0).y - LayoutFolha.raioBolha;
      final baseQrCode = LayoutFolha.cantoQrCode.y + LayoutFolha.ladoQrCode;
      expect(topoGrade, greaterThan(baseQrCode + 10));
    });

    test('a questão 21 vai para a segunda coluna', () {
      final q20 = LayoutFolha.centroBolha(19, 0);
      final q21 = LayoutFolha.centroBolha(20, 0);

      expect(q21.x, greaterThan(q20.x));
      expect(q21.y, LayoutFolha.inicioGrade);
    });

    test('recusa questão ou alternativa fora da folha', () {
      expect(() => LayoutFolha.centroBolha(LayoutFolha.maxQuestoes, 0), throwsRangeError);
      expect(() => LayoutFolha.centroBolha(0, LayoutFolha.maxAlternativas), throwsRangeError);
      expect(() => LayoutFolha.centroBolha(-1, 0), throwsRangeError);
    });
  });

  group('PDF da prova do aluno', () {
    test('gera a prova e a folha de respostas', () async {
      final pdf = await FolhaRespostasPdf().gerarProvaDoAluno(
        prova: _prova,
        aluno: _aluno,
        variacao: _variacao(3),
      );

      expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(_paginas(pdf), 2);
    });

    test('prova com muitas questões ocupa mais páginas antes da folha', () async {
      final pdf = await FolhaRespostasPdf().gerarProvaDoAluno(
        prova: _prova,
        aluno: _aluno,
        variacao: _variacao(LayoutFolha.maxQuestoes, alternativas: 5),
      );

      expect(_paginas(pdf), greaterThan(2));
    });

    test('aceita texto com aspas curvas, travessão e símbolos fora do Latin-1', () async {
      final variacao = VariacaoProva(
        provaId: _prova.id,
        alunoId: _aluno.id,
        questoes: [
          _questaoVariada('q1', 4, enunciado: 'O “princípio” — da legalidade… é ✓ válido?'),
        ],
      );

      final pdf = await FolhaRespostasPdf().gerarProvaDoAluno(
        prova: _prova,
        aluno: _aluno,
        variacao: variacao,
      );

      expect(pdf, isNotEmpty);
    });

    test('recusa variação de outro aluno', () {
      expect(
        () => FolhaRespostasPdf().gerarProvaDoAluno(
          prova: _prova,
          aluno: _aluno,
          variacao: _variacao(3, alunoId: 'outro'),
        ),
        _erroCom('não pertence'),
      );
    });

    test('recusa mais questões do que cabem na folha', () {
      expect(
        () => FolhaRespostasPdf().gerarProvaDoAluno(
          prova: _prova,
          aluno: _aluno,
          variacao: _variacao(LayoutFolha.maxQuestoes + 1),
        ),
        _erroCom('no máximo'),
      );
    });

    test('recusa questão com menos de 2 ou mais de 5 alternativas', () {
      for (final alternativas in [1, 6]) {
        expect(
          () => FolhaRespostasPdf().gerarProvaDoAluno(
            prova: _prova,
            aluno: _aluno,
            variacao: _variacao(2, alternativas: alternativas),
          ),
          _erroCom('de 2 a 5 alternativas'),
          reason: '$alternativas alternativas',
        );
      }
    });
  });

  group('PDF do gabarito', () {
    final questoes = [
      Questao(
        id: 'q1',
        enunciado: 'Qual é a norma máxima?',
        alternativas: [
          Alternativa(texto: 'Código Civil', isCorreta: false),
          Alternativa(texto: 'Constituição Federal', isCorreta: true),
        ],
      ),
      Questao(
        id: 'q2',
        enunciado: 'Outra questão',
        alternativas: [
          Alternativa(texto: 'Certa', isCorreta: true),
          Alternativa(texto: 'Errada', isCorreta: false),
        ],
      ),
    ];

    test('gera o gabarito com as questões da prova', () async {
      final pdf = await FolhaRespostasPdf().gerarGabarito(prova: _prova, questoes: questoes);

      expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(_paginas(pdf), 1);
    });

    test('recusa prova sem questões cadastradas', () {
      expect(
        () => FolhaRespostasPdf().gerarGabarito(prova: _prova, questoes: const []),
        _erroCom('não tem questões'),
      );
    });
  });

  group('Salvar o PDF', () {
    test('envia o PDF para o seletor de arquivos', () async {
      String? nomeRecebido;
      String? tipoRecebido;
      final servico = FolhaRespostasPdf(
        salvarArquivo: ({required fileName, required bytes, required mimeType}) async {
          nomeRecebido = fileName;
          tipoRecebido = mimeType;
          return Uri.parse('file:///prova.pdf');
        },
      );

      final destino = await servico.salvar('prova.pdf', Uint8List.fromList([1, 2, 3]));

      expect(destino, Uri.parse('file:///prova.pdf'));
      expect(nomeRecebido, 'prova.pdf');
      expect(tipoRecebido, 'application/pdf');
    });

    test('falha ao salvar vira mensagem amigável', () async {
      final servico = FolhaRespostasPdf(
        salvarArquivo: ({required fileName, required bytes, required mimeType}) async =>
            throw StateError('disco cheio'),
      );

      await expectLater(
        servico.salvar('prova.pdf', Uint8List(0)),
        _erroCom('Não foi possível salvar'),
      );
    });

    test('nome do arquivo sem acentos e espaços', () {
      expect(
        FolhaRespostasPdf.nomeArquivo('Avaliação 1 2024001 João Conceição'),
        'Avaliacao_1_2024001_Joao_Conceicao.pdf',
      );
      expect(FolhaRespostasPdf.nomeArquivo('   '), 'prova.pdf');
    });
  });
}
