
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/models/professor_model.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_theme.dart';

import 'banco_questoes.dart';
import 'cadastro_aluno.dart';
import 'cadastro_turma.dart';
import 'consulta_aluno.dart';
import 'consulta_turma.dart';
import 'consultar_provas_screen.dart';
import 'corrigir_prova.dart';
import 'criar_prova.dart';
import 'importar_alunos_screen.dart';
import 'perfil_professor_screen.dart';
import 'relatorio_provas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _diasSemana = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  String _dataDeHoje() {
    final agora = DateTime.now();
    final dia = _diasSemana[agora.weekday - 1];

    return '$dia, ${agora.day} de ${_meses[agora.month - 1]}';
  }

  void _abrir(BuildContext context, Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => tela),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Column(
          children: [
            _Cabecalho(data: _dataDeHoje()),
            Expanded(
              // A lista ocupa a largura toda (para a barra de rolagem ficar
              // na borda da janela) e o conteúdo fica centralizado com no
              // máximo 560 px de largura.
              child: LayoutBuilder(
                builder: (context, restricoes) {
                  final margem = ((restricoes.maxWidth - 560) / 2)
                      .clamp(20.0, double.infinity);

                  return ListView(
                    padding: EdgeInsets.fromLTRB(margem, 24, margem, 32),
                    children: [
                      _AtalhoPrincipal(
                        icone: Icons.document_scanner_outlined,
                        titulo: 'Corrigir prova',
                        subtitulo: 'Ler o gabarito e a prova do aluno',
                        aoTocar: () =>
                            _abrir(context, const CorrigirProvaScreen()),
                      ),

                      const SizedBox(height: 28),

                      // Seção de provas e questões.
                      _Secao(
                        titulo: 'Provas e questões',
                        atalhos: [
                          _Atalho(
                            icone: Icons.edit_note,
                            titulo: 'Criar prova',
                            subtitulo: 'Escolher questões e gerar variações',
                            aoTocar: () =>
                                _abrir(context, const CriarProvaScreen()),
                          ),

                          // NOVO: Consulta e edição de provas no Firestore.
                          _Atalho(
                            icone: Icons.library_books_outlined,
                            titulo: 'Consultar provas',
                            subtitulo: 'Visualizar e editar provas cadastradas',
                            aoTocar: () => _abrir(
                              context,
                              const ConsultarProvasScreen(),
                            ),
                          ),

                          _Atalho(
                            icone: Icons.quiz_outlined,
                            titulo: 'Banco de questões',
                            subtitulo: 'Cadastrar, editar e excluir questões',
                            aoTocar: () =>
                                _abrir(context, const BancoQuestoesScreen()),
                          ),

                          _Atalho(
                            icone: Icons.insights,
                            titulo: 'Provas corrigidas',
                            subtitulo: 'Notas e acertos por aluno',
                            aoTocar: () =>
                                _abrir(context, const RelatorioProvasScreen()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Seção de alunos.
                      _Secao(
                        titulo: 'Alunos',
                        atalhos: [
                          _Atalho(
                            icone: Icons.person_add_alt_1_outlined,
                            titulo: 'Cadastrar aluno',
                            subtitulo: 'Incluir um novo aluno',
                            aoTocar: () =>
                                _abrir(context, const CadastroAlunoScreen()),
                          ),

                          _Atalho(
                            icone: Icons.groups_outlined,
                            titulo: 'Consultar alunos',
                            subtitulo: 'Buscar, editar e excluir',
                            aoTocar: () =>
                                _abrir(context, const ConsultaAlunoScreen()),
                          ),
                          _Atalho(
                            icone: Icons.upload_file_outlined,
                            titulo: 'Importar alunos',
                            subtitulo: 'Trazer a lista de uma planilha',
                            aoTocar: () =>
                                _abrir(context, const ImportarAlunosScreen()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Seção de turmas.
                      _Secao(
                        titulo: 'Turmas',
                        atalhos: [
                          _Atalho(
                            icone: Icons.domain_add_outlined,
                            titulo: 'Cadastrar turma',
                            subtitulo:
                                'Criar uma nova turma e vincular alunos',
                            aoTocar: () =>
                                _abrir(context, const CadastroTurmaScreen()),
                          ),

                          _Atalho(
                            icone: Icons.school_outlined,
                            titulo: 'Consultar turmas',
                            subtitulo: 'Buscar, editar e excluir turmas',
                            aoTocar: () =>
                                _abrir(context, const ConsultaTurmaScreen()),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho com data, saudação e perfil do professor.
class _Cabecalho extends StatefulWidget {
  final String data;

  const _Cabecalho({required this.data});

  @override
  State<_Cabecalho> createState() => _CabecalhoState();
}

class _CabecalhoState extends State<_Cabecalho> {
  final _authService = AuthService();

  Professor? _professor;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final prof = await _authService.obterPerfil();

    if (mounted) {
      setState(() => _professor = prof);
    }
  }

  void _abrirPerfil() async {
    final atualizou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PerfilProfessorScreen(),
      ),
    );

    if (atualizou == true) {
      _carregarPerfil();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaBarraStatus = MediaQuery.of(context).padding.top;

    final primeiroNome =
        _professor?.nomeCompleto.trim().isNotEmpty == true
            ? _professor!.nomeCompleto.trim().split(' ').first
            : null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppCores.vinho,
          padding: EdgeInsets.fromLTRB(
            24,
            alturaBarraStatus + 20,
            20,
            20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      primeiroNome != null
                          ? 'Olá, $primeiroNome'
                          : 'Corretor de Provas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _abrirPerfil,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        _professor?.fotoUrl != null &&
                                _professor!.fotoUrl!.isNotEmpty
                            ? NetworkImage(_professor!.fotoUrl!)
                            : null,
                    child:
                        _professor?.fotoUrl == null ||
                                _professor!.fotoUrl!.isEmpty
                            ? const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 26,
                              )
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 4,
          color: AppCores.vinhoEscuro,
        ),
      ],
    );
  }
}

/// Atalho principal em destaque.
class _AtalhoPrincipal extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;

  const _AtalhoPrincipal({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppCores.vinho,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.white.withAlpha(215),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Icon(
                icone,
                size: 44,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modelo dos atalhos das seções.
class _Atalho {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;

  const _Atalho({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });
}

/// Seção com os atalhos em grade de cards, dois por linha.
class _Secao extends StatelessWidget {
  final String titulo;
  final List<_Atalho> atalhos;

  const _Secao({
    required this.titulo,
    required this.atalhos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color: AppCores.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),

        for (var i = 0; i < atalhos.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          // IntrinsicHeight deixa os dois cards da linha com a mesma altura,
          // mesmo quando um subtítulo quebra em mais linhas que o outro.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _CardAtalho(atalho: atalhos[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < atalhos.length
                      ? _CardAtalho(atalho: atalhos[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Card clicável de um atalho, com o ícone em destaque.
class _CardAtalho extends StatelessWidget {
  final _Atalho atalho;

  const _CardAtalho({
    required this.atalho,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppCores.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppCores.borda),
      ),
      child: InkWell(
        onTap: atalho.aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppCores.vinho.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  atalho.icone,
                  size: 24,
                  color: AppCores.vinho,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                atalho.titulo,
                style: const TextStyle(
                  color: AppCores.texto,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                atalho.subtitulo,
                style: const TextStyle(
                  color: AppCores.textoSuave,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
