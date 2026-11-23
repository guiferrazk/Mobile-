import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/models/identificacao_gabarito.dart';
import 'package:mobile/models/identificacao_prova.dart';
import 'package:mobile/models/prova_model.dart';
import 'package:mobile/services/localizador_prova.dart';

// Ids no formato gerado pelo Firestore (20 caracteres) e em outros formatos
// que podem aparecer, como ids criados à mão ou importados.
const _idsDeProva = [
  'Xk3P9qLmZ2vR8tYw1aBc',
  'prova-n3-direito',
  'prova_2026_turma_a',
  '123',
];

Aluno _aluno(String id, String nome, String matricula) {
  return Aluno(
    id: id,
    nome: nome,
    email: '${nome.split(' ').first.toLowerCase()}@email.com',
    matricula: matricula,
  );
}

/// Localizador com um "banco" em memória, que também guarda os ids
/// buscados para conferir se a busca foi feita com o id certo.
class _BancoFalso {
  final provas = <String, Prova>{
    'Xk3P9qLmZ2vR8tYw1aBc': const Prova(
      id: 'Xk3P9qLmZ2vR8tYw1aBc',
      titulo: 'Direito Constitucional - P1',
      questaoIds: ['q1', 'q2', 'q3'],
    ),
    'prova-n3-direito': const Prova(
      id: 'prova-n3-direito',
      titulo: 'Direito Civil - P2',
      questaoIds: ['q4', 'q5'],
    ),
  };

  final alunos = <String, Aluno>{
    'aBc123DeF456gHi789Jk': _aluno('aBc123DeF456gHi789Jk', 'Ana Souza', '2024001'),
    'aluno-002': _aluno('aluno-002', 'Bruno Lima', '2024002'),
    'aluno_003': _aluno('aluno_003', 'Camila Alves', '2024003'),
  };

  final provasBuscadas = <String>[];
  final alunosBuscados = <String>[];

  LocalizadorProva get localizador => LocalizadorProva(
        buscarProva: (id) async {
          provasBuscadas.add(id);
          return provas[id];
        },
        buscarAluno: (id) async {
          alunosBuscados.add(id);
          return alunos[id];
        },
      );
}

Matcher _erroCom(String trecho) {
  return throwsA(
    isA<LeituraQrCodeException>().having((e) => e.mensagem, 'mensagem', contains(trecho)),
  );
}

void main() {
  group('QR Code do gabarito', () {
    test('o código gerado volta para a mesma prova com diferentes ids', () {
      for (final id in _idsDeProva) {
        final codigo = IdentificacaoGabarito(provaId: id).codificar();

        expect(codigo, 'GABARITO|1|$id');
        expect(IdentificacaoGabarito.decodificar(codigo)?.provaId, id, reason: id);
      }
    });

    test('ignora espaços e quebra de linha em volta do texto lido', () {
      final lido = IdentificacaoGabarito.decodificar('  GABARITO|1|prova-n3-direito\n');

      expect(lido?.provaId, 'prova-n3-direito');
    });

    test('recusa códigos que não são de gabarito', () {
      for (final conteudo in [
        '',
        'https://exemplo.com/prova/123',
        'gabarito|1|prova-n3-direito',
        'GABARITO|2|prova-n3-direito',
        'GABARITO|1|',
        'GABARITO|1|prova/123',
        'GABARITO|1|prova|extra',
        'CORRETOR|1|prova-n3-direito|aluno-002',
      ]) {
        expect(IdentificacaoGabarito.decodificar(conteudo), isNull, reason: conteudo);
      }
    });

    test('não gera QR Code com id inválido', () {
      expect(() => IdentificacaoGabarito(provaId: ''), throwsArgumentError);
      expect(() => IdentificacaoGabarito(provaId: 'a/b'), throwsArgumentError);
    });

    test('o QR Code da folha do aluno não é lido como gabarito', () {
      final folha = IdentificacaoProva(provaId: 'prova-n3-direito', alunoId: 'aluno-002');

      expect(IdentificacaoGabarito.decodificar(folha.codificar()), isNull);
    });
  });

  group('Localizar a prova pelo gabarito', () {
    test('encontra a prova certa para cada id', () async {
      final banco = _BancoFalso();

      for (final id in banco.provas.keys) {
        final prova = await banco.localizador.localizarGabarito('GABARITO|1|$id');
        expect(prova.id, id);
        expect(prova.titulo, banco.provas[id]!.titulo);
      }

      expect(banco.provasBuscadas, banco.provas.keys.toList());
    });

    test('avisa quando a prova não existe mais', () async {
      final banco = _BancoFalso();

      await expectLater(
        banco.localizador.localizarGabarito('GABARITO|1|prova_2026_turma_a'),
        _erroCom('não foi encontrada'),
      );
    });

    test('avisa quando o professor lê a folha do aluno no lugar do gabarito', () async {
      final banco = _BancoFalso();

      await expectLater(
        banco.localizador.localizarGabarito('CORRETOR|1|prova-n3-direito|aluno-002'),
        _erroCom('folha de um aluno'),
      );
      expect(banco.provasBuscadas, isEmpty);
    });

    test('recusa QR Code de outro sistema sem consultar o banco', () async {
      final banco = _BancoFalso();

      await expectLater(
        banco.localizador.localizarGabarito('https://exemplo.com'),
        _erroCom('não reconhecido'),
      );
      expect(banco.provasBuscadas, isEmpty);
    });
  });

  group('Localizar o aluno pela folha', () {
    late _BancoFalso banco;
    late Prova provaP1;

    setUp(() {
      banco = _BancoFalso();
      provaP1 = banco.provas['Xk3P9qLmZ2vR8tYw1aBc']!;
    });

    test('encontra o aluno certo para cada folha da prova', () async {
      for (final aluno in banco.alunos.values) {
        final codigo = IdentificacaoProva(provaId: provaP1.id, alunoId: aluno.id).codificar();

        final encontrado = await banco.localizador.localizarAlunoDaFolha(codigo, prova: provaP1);

        expect(encontrado.id, aluno.id);
        expect(encontrado.nome, aluno.nome);
        expect(encontrado.matricula, aluno.matricula);
      }

      expect(banco.alunosBuscados, banco.alunos.keys.toList());
    });

    test('recusa a folha de outra prova sem buscar o aluno', () async {
      final codigo = IdentificacaoProva(provaId: 'prova-n3-direito', alunoId: 'aluno-002').codificar();

      await expectLater(
        banco.localizador.localizarAlunoDaFolha(codigo, prova: provaP1),
        _erroCom('outra prova'),
      );
      expect(banco.alunosBuscados, isEmpty);
    });

    test('avisa quando o aluno da folha não está cadastrado', () async {
      final codigo = IdentificacaoProva(provaId: provaP1.id, alunoId: 'aluno-removido').codificar();

      await expectLater(
        banco.localizador.localizarAlunoDaFolha(codigo, prova: provaP1),
        _erroCom('não está cadastrado'),
      );
    });

    test('avisa quando o professor lê o gabarito no lugar da folha', () async {
      final codigo = IdentificacaoGabarito(provaId: provaP1.id).codificar();

      await expectLater(
        banco.localizador.localizarAlunoDaFolha(codigo, prova: provaP1),
        _erroCom('gabarito'),
      );
      expect(banco.alunosBuscados, isEmpty);
    });

    test('recusa QR Code que não é de folha de resposta', () async {
      await expectLater(
        banco.localizador.localizarAlunoDaFolha('CORRETOR|1|so-a-prova', prova: provaP1),
        _erroCom('não reconhecido'),
      );
    });
  });

  test('fluxo completo: gabarito e depois as folhas de dois alunos', () async {
    final banco = _BancoFalso();
    final localizador = banco.localizador;

    final prova = await localizador.localizarGabarito('GABARITO|1|prova-n3-direito');
    final ana = await localizador.localizarAlunoDaFolha(
      'CORRETOR|1|prova-n3-direito|aBc123DeF456gHi789Jk',
      prova: prova,
    );
    final bruno = await localizador.localizarAlunoDaFolha(
      'CORRETOR|1|prova-n3-direito|aluno-002',
      prova: prova,
    );

    expect(prova.titulo, 'Direito Civil - P2');
    expect(ana.nome, 'Ana Souza');
    expect(bruno.nome, 'Bruno Lima');
  });
}
