import 'package:flutter/material.dart';
import 'package:mobile/models/professor_model.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/utils/formatadores.dart';


class PerfilProfessorScreen extends StatefulWidget {
  const PerfilProfessorScreen({super.key});

  @override
  State<PerfilProfessorScreen> createState() => _PerfilProfessorScreenState();
}

class _PerfilProfessorScreenState extends State<PerfilProfessorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nomeController = TextEditingController();
  final _fotoUrlController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  Professor? _professor;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final prof = await _authService.obterPerfil();
      if (!mounted) return;
      setState(() {
        _professor = prof;
        if (prof != null) {
          _nomeController.text = prof.nomeCompleto;
          _fotoUrlController.text = prof.fotoUrl ?? '';
          _dataNascimentoController.text = prof.dataNascimento;
        }
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      await _authService.atualizarPerfil(
        nomeCompleto: _nomeController.text,
        dataNascimento: _dataNascimentoController.text, // Passando a data
        fotoUrl: _fotoUrlController.text.trim().isEmpty ? null : _fotoUrlController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna true para recarregar o perfil na Home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    await _authService.sair();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fotoUrlController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final foto = _fotoUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair da Conta',
            onPressed: _sair,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  foto.isNotEmpty ? NetworkImage(foto) : null,
                  child: foto.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fotoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Foto de Perfil',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_professor?.email ?? ''),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dataNascimentoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    DataInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Data de Nascimento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe a data';
                    if (v.length != 10) return 'Data incompleta';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvarAlteracoes,
                  icon: const Icon(Icons.save),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar Alterações'),
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
