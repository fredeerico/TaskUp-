import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/subtarefa.dart';
import '../models/tarefa.dart';
import '../state/task_store.dart';
import '../widgets/common.dart';
import 'tarefa_form_screen.dart';

class TarefaDetailScreen extends StatefulWidget {
  const TarefaDetailScreen({super.key, required this.tarefaId});

  final int tarefaId;

  @override
  State<TarefaDetailScreen> createState() => _TarefaDetailScreenState();
}

class _TarefaDetailScreenState extends State<TarefaDetailScreen> {
  final _novaSub = TextEditingController();
  bool _carregandoSubs = true;
  String? _erroSubs;

  @override
  void initState() {
    super.initState();
    _carregarSubs();
  }

  @override
  void dispose() {
    _novaSub.dispose();
    super.dispose();
  }

  Future<void> _carregarSubs() async {
    setState(() {
      _carregandoSubs = true;
      _erroSubs = null;
    });
    try {
      await context.read<TaskStore>().carregarSubtarefas(widget.tarefaId);
    } catch (e) {
      _erroSubs = e.toString();
    }
    if (mounted) setState(() => _carregandoSubs = false);
  }

  Future<void> _adicionarSub() async {
    final texto = _novaSub.text.trim();
    if (texto.isEmpty) return;
    final ok = await runSafely(
      context,
      () =>
          context.read<TaskStore>().adicionarSubtarefa(widget.tarefaId, texto),
    );
    if (ok) _novaSub.clear();
  }

  Future<void> _excluir(Tarefa t) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir tarefa?',
      mensagem:
          '"${t.titulo}" e suas subtarefas serão removidas permanentemente.',
    );
    if (!ok || !mounted) return;
    final store = context.read<TaskStore>();
    final nav = Navigator.of(context);
    final feito = await runSafely(
      context,
      () => store.excluirTarefa(t.id),
      success: 'Tarefa excluída',
    );
    if (feito) nav.pop();
  }

  void _editar(Tarefa t) {
    final store = context.read<TaskStore>();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: store,
          child: TarefaFormScreen(tarefa: t),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final t = store.tarefaPorId(widget.tarefaId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          titulo: 'Tarefa não encontrada',
        ),
      );
    }

    final categoria = store.categoriaPorId(t.categoria);
    final subs = store.subtarefasDe(t.id) ?? const <Subtarefa>[];
    final subsFeitas = subs.where((s) => s.concluida).length;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editar(t),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _excluir(t),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              Text(
                t.titulo,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: t.concluida ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final st in StatusTarefa.values)
                    ChoiceChip(
                      avatar: Icon(st.icon, size: 18),
                      label: Text(st.label),
                      selected: t.status == st,
                      showCheckmark: false,
                      onSelected: (_) =>
                          runSafely(context, () => store.definirStatus(t, st)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Prioridade',
                      child: PrioridadeBadge(t.prioridade),
                    ),
                    const Divider(indent: 56),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Prazo',
                      child: Text(
                        t.prazo == null
                            ? 'Sem prazo'
                            : (t.atrasada ? 'Atrasada · ' : '') +
                                  formatarPrazo(t.prazo!),
                        style: TextStyle(
                          color: t.atrasada ? scheme.error : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Divider(indent: 56),
                    _InfoRow(
                      icon: Icons.label_outline,
                      label: 'Categoria',
                      child: categoria == null
                          ? const Text('Nenhuma')
                          : CategoriaTag(categoria),
                    ),
                    if (t.dataCriacao != null) ...[
                      const Divider(indent: 56),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Criada em',
                        child: Text(
                          DateFormat("d 'de' MMM 'de' y, HH:mm")
                              .format(t.dataCriacao!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (t.descricao.trim().isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Descrição', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(
                  t.descricao,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subtarefas',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (subs.isNotEmpty)
                    Text(
                      '$subsFeitas/${subs.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
              if (subs.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: subsFeitas / subs.length,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_carregandoSubs && subs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_erroSubs != null)
                ListTile(
                  leading: Icon(Icons.error_outline, color: scheme.error),
                  title: Text(_erroSubs!),
                  trailing: IconButton(
                    onPressed: _carregarSubs,
                    icon: const Icon(Icons.refresh),
                  ),
                )
              else
                ...subs.map((s) => _SubtarefaTile(sub: s)),
              const SizedBox(height: 8),
              TextField(
                controller: _novaSub,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _adicionarSub(),
                decoration: InputDecoration(
                  hintText: 'Adicionar subtarefa',
                  prefixIcon: const Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _adicionarSub,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: scheme.onSurfaceVariant),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}

class _SubtarefaTile extends StatelessWidget {
  const _SubtarefaTile({required this.sub});

  final Subtarefa sub;

  @override
  Widget build(BuildContext context) {
    final store = context.read<TaskStore>();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: CheckboxListTile(
          value: sub.concluida,
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onChanged: (_) =>
              runSafely(context, () => store.alternarSubtarefa(sub)),
          title: Text(
            sub.descricao,
            style: TextStyle(
              decoration: sub.concluida ? TextDecoration.lineThrough : null,
              color: sub.concluida ? scheme.onSurfaceVariant : null,
            ),
          ),
          secondary: IconButton(
            tooltip: 'Remover',
            icon: const Icon(Icons.close, size: 20),
            onPressed: () =>
                runSafely(context, () => store.excluirSubtarefa(sub)),
          ),
        ),
      ),
    );
  }
}
