/// Regras de validação dos dados do aluno, usadas tanto no cadastro
/// manual quanto na importação por planilha.
///
/// Cada função devolve a mensagem de erro, ou `null` se o valor é válido,
/// no mesmo formato esperado pelo `validator` de um `TextFormField`.
class ValidadoresAluno {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _matricula = RegExp(r'^[A-Za-z0-9./-]+$');

  static String? nome(String? valor) {
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe o nome';
    if (nome.length < 3) return 'Nome muito curto';
    return null;
  }

  static String? email(String? valor) {
    final email = valor?.trim() ?? '';
    if (email.isEmpty) return 'Informe o e-mail';
    if (!_email.hasMatch(email)) return 'E-mail inválido';
    return null;
  }

  static String? matricula(String? valor) {
    final matricula = valor?.trim() ?? '';
    if (matricula.isEmpty) return 'Informe a matrícula';
    if (!_matricula.hasMatch(matricula)) {
      return 'Matrícula inválida (use só letras, números, ponto, hífen ou barra)';
    }
    return null;
  }
}
