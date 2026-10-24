import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/categoria.dart';
import '../models/tarefa.dart';

void showMessage(BuildContext context, String msg, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? scheme.errorContainer : null,
        showCloseIcon: true,
        closeIconColor: error ? scheme.onErrorContainer : null,
      ),
    );
}

/// Executa uma ação assíncrona mostrando erro em SnackBar se falhar.
Future<bool> runSafely(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, e.toString(), error: true);
    return false;
  }
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String acao = 'Excluir',
  bool destrutivo = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(destrutivo ? Icons.delete_outline : Icons.help_outline),
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destrutivo
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size(64, 40),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(acao),
        ),
      ],
    ),
  );
  return ok ?? false;
}

String formatarPrazo(DateTime prazo) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(prazo.year, prazo.month, prazo.day);
  final diff = dia.difference(hoje).inDays;
  final hora = DateFormat.Hm().format(prazo);
  final horaTxt = (prazo.hour == 23 && prazo.minute == 59) ? '' : ', $hora';

  if (diff == 0) return 'Hoje$horaTxt';
  if (diff == 1) return 'Amanhã$horaTxt';
  if (diff == -1) return 'Ontem$horaTxt';
  if (diff > 1 && diff < 7) {
    final semana = DateFormat.EEEE().format(prazo);
    return '${semana[0].toUpperCase()}${semana.substring(1)}$horaTxt';
  }
  final fmt = prazo.year == agora.year
      ? DateFormat("d 'de' MMM")
      : DateFormat("d 'de' MMM 'de' y");
  return '${fmt.format(prazo)}$horaTxt';
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  final IconData icon;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(
                mensagem!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 20), acao!],
          ],
        ),
      ),
    );
  }
}

class PrioridadeBadge extends StatelessWidget {
  const PrioridadeBadge(this.prioridade, {super.key, this.compact = false});

  final Prioridade prioridade;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = prioridade.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prioridade.icon, size: 14, color: c),
          if (!compact) ...[
            const SizedBox(width: 2),
            Text(
              prioridade.label,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategoriaTag extends StatelessWidget {
  const CategoriaTag(this.categoria, {super.key});

  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final c = categoria.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              categoria.nome,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
