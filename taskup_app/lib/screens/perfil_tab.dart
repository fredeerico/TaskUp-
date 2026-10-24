import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../state/task_store.dart';
import '../widgets/common.dart';
import '../widgets/server_dialog.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final store = context.watch<TaskStore>();
    final user = session.user!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    user.iniciais,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email.isNotEmpty ? user.email : '@${user.username}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _Stat(valor: store.tarefas.length, label: 'Tarefas'),
                  const SizedBox(width: 10),
                  _Stat(valor: store.totalConcluidas, label: 'Concluídas'),
                  const SizedBox(width: 10),
                  _Stat(
                    valor: store.totalAtrasadas,
                    label: 'Atrasadas',
                    destaque: store.totalAtrasadas > 0,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Usuário'),
                      subtitle: Text(user.username),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: const Text('Servidor da API'),
                      subtitle: Text(session.baseUrl),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await showServerDialog(context);
                        if (context.mounted) store.load();
                      },
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Sincronizar agora'),
                      onTap: () async {
                        await store.load();
                        if (context.mounted) {
                          showMessage(
                            context,
                            store.error ?? 'Dados atualizados',
                            error: store.error != null,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                ),
                onPressed: () async {
                  final ok = await confirmar(
                    context,
                    titulo: 'Sair da conta?',
                    mensagem: 'Você precisará entrar novamente.',
                    acao: 'Sair',
                    destrutivo: false,
                  );
                  if (ok) await session.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.valor,
    required this.label,
    this.destaque = false,
  });

  final int valor;
  final String label;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: destaque
              ? scheme.errorContainer.withValues(alpha: 0.5)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              '$valor',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: destaque ? scheme.onErrorContainer : scheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
