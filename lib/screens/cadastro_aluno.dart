import 'package:flutter/material.dart';
import 'package:mobile/widgets/titulo_pagina.dart';

import 'package:mobile/models/aluno_model.dart';
import 'package:mobile/services/aluno_service.dart';
import 'package:mobile/utils/validadores_aluno.dart';

class CadastroAlunoScreen extends StatefulWidget {
  final Aluno? aluno;

  const CadastroAlunoScreen({super.key, this.aluno});

  @override
  State<CadastroAlunoScreen> createState() => _CadastroAlunoScreenState();
}

class _CadastroAlunoScreenState extends State<CadastroAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alunoService = AlunoService();

  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _matriculaController;

  bool _salvando = false;

  bool get _editando => widget.aluno != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.aluno?.nome);
    _emailController = TextEditingController(text: widget.aluno?.email);
    _matriculaController =
        TextEditingController(text: widget.aluno?.matricula);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _salvando = true);

    final aluno = Aluno(
      id: widget.aluno?.id ?? '',
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      matricula: _matriculaController.text.trim(),
    );

    try {
      if (_editando) {
        await _alunoService.atualizar(aluno);
      } else {
        await _alunoService.cadastrar(aluno);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Aluno atualizado!' : 'Aluno cadastrado!',
          ),
        ),
      );
      Navigator.pop(context);
    } on AlunoServiceException catch (e) {
      _mostrarErro(e.mensagem);
    } catch (e) {
      _mostrarErro('Não foi possível salvar o aluno: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TituloPagina(
          icone: Icons.person_add_alt_1_outlined,
          texto: _editando ? 'Editar Aluno' : 'Cadastrar Aluno',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidadoresAluno.nome,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidadoresAluno.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _matriculaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      border: OutlineInputBorder(),
                    ),
                    validator: ValidadoresAluno.matricula,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar aluno'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}