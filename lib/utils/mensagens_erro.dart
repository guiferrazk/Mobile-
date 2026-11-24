import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Traduz os erros do Firebase em mensagens que o professor entende.
///
/// As telas mostram o que estavam fazendo ("Não foi possível salvar o
/// aluno.") seguido de [MensagensErro.de], que explica o motivo e o que
/// fazer. O erro original continua no console, para quem estiver depurando.
class MensagensErro {
  static const generica = 'Tente novamente em instantes.';

  static const _semConexao =
      'Sem conexão com o servidor. Verifique a internet e tente de novo.';
  static const _loginInvalido = 'E-mail ou senha incorretos.';

  static const _banco = {
    'permission-denied':
        'Você não tem permissão para acessar esses dados. '
        'Entre novamente ou fale com o responsável pelo sistema.',
    'unauthenticated': 'Sua sessão expirou. Entre novamente.',
    'unavailable': _semConexao,
    'deadline-exceeded': 'O servidor demorou para responder. Tente de novo.',
    'not-found': 'O registro não foi encontrado. Ele pode ter sido excluído.',
    'already-exists': 'Este registro já existe.',
    'resource-exhausted':
        'O limite de uso do servidor foi atingido. Tente mais tarde.',
    'cancelled': 'A operação foi cancelada. Tente de novo.',
  };

  static const _login = {
    'email-already-in-use':
        'Este e-mail já está cadastrado. Volte e use a opção de entrar.',
    'invalid-email': 'O e-mail informado não é válido.',
    'weak-password': 'A senha é fraca. Use pelo menos 6 caracteres.',
    'user-not-found': _loginInvalido,
    'wrong-password': _loginInvalido,
    'invalid-credential': _loginInvalido,
    'invalid-login-credentials': _loginInvalido,
    'user-disabled': 'Esta conta foi desativada.',
    'too-many-requests':
        'Muitas tentativas seguidas. Aguarde alguns minutos e tente de novo.',
    'network-request-failed': _semConexao,
    'operation-not-allowed': 'Este tipo de acesso não está habilitado.',
    'requires-recent-login': 'Por segurança, entre novamente para continuar.',
  };

  /// Explicação do erro em português, pronta para mostrar na tela.
  static String de(Object? erro) {
    debugPrint('Erro: $erro');

    if (erro is FirebaseException) {
      // No navegador, alguns códigos chegam com o prefixo "auth/".
      final codigo = erro.code.replaceFirst('auth/', '');
      final mapa = erro.plugin == 'firebase_auth' ? _login : _banco;
      return mapa[codigo] ?? _banco[codigo] ?? generica;
    }

    return generica;
  }
}
