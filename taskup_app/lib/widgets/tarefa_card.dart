import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarefa.dart';
import '../state/task_store.dart';
import 'common.dart';

class TarefaCard extends StatelessWidget {
  const TarefaCard({super.key, required this.tarefa, required this.onTap});

  final Tarefa tarefa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final store = context.read<TaskStore>();
    final categoria = store.categoriaPorId(tarefa.categoria);
    final feita = tarefa.concluida;

    return Dismissible(
      key: ValueKey('tarefa-${tarefa.id}'),
      background: _swipeBg(
        context,
        alignment: Alignment.centerLeft,
        color: scheme.primaryContainer,
        icon: feita ? Icons.undo : Icons.check,
        label: feita ? 'Reabrir' : 'Concluir',
        fg: scheme.onPrimaryContainer,
      ),
      secondaryBackground: _swipeBg(
        context,
        alignment: Alignment.centerRight,
        color: scheme.errorContainer,
        icon: Icons.delete_outline,
        label: 'Excluir',
        fg: scheme.onErrorContainer,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await runSafely(context, () => store.alternarConclusao(tarefa));
          return false; // o item continua na lista, só muda de estado
        }
        return _excluir(context, store);
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: tarefa.atrasada
                ? scheme.error.withValues(alpha: 0.45)
                : scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: feita ? 'Marcar como pendente' : 'Concluir',
                  onPressed: () =>
                      runSafely(context, () => store.alternarConclusao(tarefa)),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                      feita
                          ? Icons.check_circle_rounded
                          : (tarefa.status == StatusTarefa.emAndamento
                                ? Icons.timelapse_rounded
                                : Icons.radio_button_unchecked),
                      key: ValueKey('${tarefa.id}-${tarefa.status}'),
                      color: feita
                          ? scheme.primary
                          : tarefa.prioridade.color.withValues(alpha: 0.9),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tarefa.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: feita
                                ? TextDecoration.lineThrough
                                : null,
                            color: feita
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        if (tarefa.descricao.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tarefa.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PrioridadeBadge(tarefa.prioridade),
                            if (categoria != null) CategoriaTag(categoria),
                            if (tarefa.prazo != null) _PrazoTag(tarefa: tarefa),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mais ações',
                  icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                  onSelected: (v) {
                    if (v == 'status') {
                      runSafely(context, () => store.alternarConclusao(tarefa));
                    } else {
                      _excluir(context, store);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(feita ? Icons.undo : Icons.check),
                        title: Text(feita ? 'Reabrir' : 'Concluir'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Excluir'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _excluir(BuildContext context, TaskStore store) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir tarefa?',
      mensagem: '"${tarefa.titulo}" será removida permanentemente.',
    );
    if (!ok || !context.mounted) return false;
    return runSafely(
      context,
      () => store.excluirTarefa(tarefa.id),
      success: 'Tarefa excluída',
    );
  }

  Widget _swipeBg(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required Color fg,
    required IconData icon,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) Text(label, style: TextStyle(color: fg)),
          if (!isLeft) const SizedBox(width: 8),
          Icon(icon, color: fg),
          if (isLeft) const SizedBox(width: 8),
          if (isLeft) Text(label, style: TextStyle(color: fg)),
        ],
      ),
    );
  }
}

class _PrazoTag extends StatelessWidget {
  const _PrazoTag({required this.tarefa});

  final Tarefa tarefa;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atrasada = tarefa.atrasada;
    final color = atrasada ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          atrasada ? Icons.warning_amber_rounded : Icons.event_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          atrasada
              ? 'Atrasada · ${formatarPrazo(tarefa.prazo!)}'
              : formatarPrazo(tarefa.prazo!),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: atrasada ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
