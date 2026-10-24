import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tarefa.dart';
import '../state/session.dart';
import '../state/task_store.dart';
import '../widgets/common.dart';
import '../widgets/tarefa_card.dart';
import 'tarefa_detail_screen.dart';
import 'tarefa_form_screen.dart';

class TarefasTab extends StatelessWidget {
  const TarefasTab({super.key});

  void _abrir(BuildContext context, Tarefa t) {
    final store = context.read<TaskStore>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: store,
          child: TarefaDetailScreen(tarefaId: t.id),
        ),
      ),
    );
  }

  void _nova(BuildContext context) {
    final store = context.read<TaskStore>();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: store,
          child: const TarefaFormScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final user = context.watch<Session>().user!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lista = store.tarefasFiltradas;
    final filtrosExtras =
        (store.filtroPrioridade != null ? 1 : 0) +
        (store.filtroCategoria != null ? 1 : 0);

    final hoje = DateFormat("EEEE, d 'de' MMMM").format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nova(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: RefreshIndicator(
              onRefresh: store.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hoje[0].toUpperCase()}${hoje.substring(1)}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Olá, ${user.displayName.split(' ').first}',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Filtros',
                            onPressed: () => _abrirFiltros(context),
                            icon: Badge(
                              isLabelVisible: filtrosExtras > 0,
                              label: Text('$filtrosExtras'),
                              child: const Icon(Icons.tune),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _Resumo(store: store)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: SearchBar(
                        hintText: 'Buscar tarefas',
                        leading: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.search),
                        ),
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: WidgetStatePropertyAll(
                          scheme.surfaceContainerHigh,
                        ),
                        onChanged: store.setBusca,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: FiltroTarefa.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = FiltroTarefa.values[i];
                          return ChoiceChip(
                            label: Text('${f.label} · ${store.contar(f)}'),
                            selected: store.filtro == f,
                            showCheckmark: false,
                            onSelected: (_) => store.setFiltro(f),
                          );
                        },
                      ),
                    ),
                  ),
                  if (store.loading && store.tarefas.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (store.error != null && store.tarefas.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.cloud_off_outlined,
                        titulo: 'Não foi possível carregar',
                        mensagem: store.error,
                        acao: FilledButton.tonalIcon(
                          onPressed: store.load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ),
                    )
                  else if (lista.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: store.tarefas.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox_outlined,
                              titulo: 'Nenhuma tarefa ainda',
                              mensagem: 'Toque em "Nova tarefa" para começar.',
                            )
                          : const EmptyState(
                              icon: Icons.filter_alt_off_outlined,
                              titulo: 'Nada por aqui',
                              mensagem:
                                  'Nenhuma tarefa corresponde aos filtros.',
                            ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => TarefaCard(
                          tarefa: lista[i],
                          onTap: () => _abrir(context, lista[i]),
                        ),
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

  void _abrirFiltros(BuildContext context) {
    final store = context.read<TaskStore>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: store,
        child: const _FiltrosSheet(),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = store.tarefas.length;
    final feitas = store.totalConcluidas;
    final progresso = total == 0 ? 0.0 : feitas / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.85),
              scheme.tertiaryContainer.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progresso),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.onPrimaryContainer.withValues(
                        alpha: 0.15,
                      ),
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progresso * 100).round()}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total == 0
                        ? 'Comece adicionando uma tarefa'
                        : '$feitas de $total concluídas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _Mini(
                        icon: Icons.pending_actions,
                        texto: '${store.totalAbertas} em aberto',
                        color: scheme.onPrimaryContainer,
                      ),
                      if (store.totalAtrasadas > 0)
                        _Mini(
                          icon: Icons.warning_amber_rounded,
                          texto: '${store.totalAtrasadas} atrasada(s)',
                          color: scheme.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.icon, required this.texto, required this.color});

  final IconData icon;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _FiltrosSheet extends StatelessWidget {
  const _FiltrosSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filtros', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () {
                    store.setFiltroPrioridade(null);
                    store.setFiltroCategoria(null);
                  },
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Prioridade', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in Prioridade.values.reversed)
                  FilterChip(
                    avatar: Icon(p.icon, size: 18, color: p.color),
                    label: Text(p.label),
                    selected: store.filtroPrioridade == p,
                    onSelected: (sel) =>
                        store.setFiltroPrioridade(sel ? p : null),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Categoria', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (store.categorias.isEmpty)
              Text(
                'Você ainda não criou categorias.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in store.categorias)
                    FilterChip(
                      avatar: CircleAvatar(backgroundColor: c.color, radius: 6),
                      label: Text(c.nome),
                      selected: store.filtroCategoria == c.id,
                      onSelected: (sel) =>
                          store.setFiltroCategoria(sel ? c.id : null),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
