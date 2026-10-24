import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../widgets/common.dart';
import '../widgets/server_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _cadastro = false;
  bool _loading = false;
  bool _ocultarSenha = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<Session>().sessionExpired) {
        showMessage(context, 'Sua sessão expirou. Entre novamente.');
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final session = context.read<Session>();
    try {
      if (_cadastro) {
        await session.register(
          nome: _nome.text,
          username: _username.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await session.login(_username.text, _password.text);
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.watch<Session>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -1.0),
            radius: 1.4,
            colors: [scheme.primary.withValues(alpha: 0.18), scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: 'Servidor: ${session.baseUrl}',
                  icon: const Icon(Icons.settings_ethernet),
                  onPressed: () => showServerDialog(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Logo(scheme: scheme),
                            const SizedBox(height: 24),
                            Text(
                              _cadastro
                                  ? 'Crie sua conta'
                                  : 'Bem-vindo de volta',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _cadastro
                                  ? 'Organize suas tarefas em poucos toques.'
                                  : 'Entre para ver suas tarefas.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: _cadastro
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: _nome,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Nome',
                                            prefixIcon: Icon(
                                              Icons.badge_outlined,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v ?? '').trim().isEmpty
                                              ? 'Informe seu nome'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.email,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'E-mail',
                                            prefixIcon: Icon(
                                              Icons.alternate_email,
                                            ),
                                          ),
                                          validator: (v) {
                                            final s = (v ?? '').trim();
                                            if (s.isEmpty) return null;
                                            return RegExp(
                                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                                ).hasMatch(s)
                                                ? null
                                                : 'E-mail inválido';
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            TextFormField(
                              controller: _username,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                labelText: 'Usuário',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Informe o usuário'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _ocultarSenha,
                              textInputAction: TextInputAction.done,
                              autofillHints: [
                                _cadastro
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _ocultarSenha
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _ocultarSenha = !_ocultarSenha,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? '').isEmpty) return 'Informe a senha';
                                if (_cadastro && v!.length < 8) {
                                  return 'Use pelo menos 8 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(_cadastro ? 'Criar conta' : 'Entrar'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () =>
                                        setState(() => _cadastro = !_cadastro),
                              child: Text(
                                _cadastro
                                    ? 'Já tenho conta — entrar'
                                    : 'Não tem conta? Cadastre-se',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.tertiary],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.task_alt_rounded, size: 38, color: scheme.onPrimary),
      ),
    );
  }
}
