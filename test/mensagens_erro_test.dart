import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/mensagens_erro.dart';

FirebaseException _erroBanco(String codigo) =>
    FirebaseException(plugin: 'cloud_firestore', code: codigo);

void main() {
  group('Erros do banco de dados', () {
    test('sem permissão', () {
      expect(MensagensErro.de(_erroBanco('permission-denied')), contains('não tem permissão'));
    });

    test('sem conexão', () {
      expect(MensagensErro.de(_erroBanco('unavailable')), contains('Sem conexão'));
    });

    test('registro excluído', () {
      expect(MensagensErro.de(_erroBanco('not-found')), contains('não foi encontrado'));
    });

    test('sessão expirada', () {
      expect(MensagensErro.de(_erroBanco('unauthenticated')), contains('Entre novamente'));
    });
  });

  group('Erros de login e cadastro', () {
    test('e-mail já cadastrado', () {
      final erro = FirebaseAuthException(code: 'email-already-in-use');
      expect(MensagensErro.de(erro), contains('já está cadastrado'));
    });

    test('senha errada e usuário inexistente dão a mesma mensagem', () {
      for (final codigo in ['wrong-password', 'user-not-found', 'invalid-credential']) {
        expect(
          MensagensErro.de(FirebaseAuthException(code: codigo)),
          'E-mail ou senha incorretos.',
          reason: codigo,
        );
      }
    });

    test('senha fraca', () {
      expect(
        MensagensErro.de(FirebaseAuthException(code: 'weak-password')),
        contains('pelo menos 6 caracteres'),
      );
    });

    test('código com prefixo auth/, como chega no navegador', () {
      final erro = FirebaseException(plugin: 'firebase_auth', code: 'auth/too-many-requests');
      expect(MensagensErro.de(erro), contains('Muitas tentativas'));
    });

    test('erro de banco durante o cadastro também é traduzido', () {
      final erro = FirebaseException(plugin: 'firebase_auth', code: 'permission-denied');
      expect(MensagensErro.de(erro), contains('não tem permissão'));
    });
  });

  group('Mensagem genérica', () {
    test('código desconhecido não mostra texto técnico', () {
      final mensagem = MensagensErro.de(_erroBanco('codigo-novo-qualquer'));
      expect(mensagem, MensagensErro.generica);
    });

    test('erros que não são do Firebase', () {
      expect(MensagensErro.de(Exception('falha interna')), MensagensErro.generica);
      expect(MensagensErro.de(StateError('x')), MensagensErro.generica);
      expect(MensagensErro.de(null), MensagensErro.generica);
    });

    test('nenhuma mensagem expõe código ou texto em inglês', () {
      final codigos = [
        'permission-denied', 'unavailable', 'deadline-exceeded', 'not-found',
        'already-exists', 'resource-exhausted', 'cancelled', 'unauthenticated',
      ];
      for (final codigo in codigos) {
        final mensagem = MensagensErro.de(_erroBanco(codigo));
        expect(mensagem, isNot(contains(codigo)), reason: codigo);
        expect(mensagem, isNot(contains('Missing')), reason: codigo);
      }
    });
  });
}
