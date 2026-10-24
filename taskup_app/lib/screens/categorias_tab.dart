import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../state/task_store.dart';
import '../widgets/common.dart';

class CategoriasTab extends StatelessWidget {
  const CategoriasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova categoria',
        onPressed: () => showCategoriaDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: RefreshIndicator(
            onRefresh: store.load,
            child: store.categorias.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: EmptyState(
                          icon: Icons.label_outline,
                          titulo: 'Sem categorias',
                          mensagem: 'Agrupe suas tarefas por contexto: trabalho, estudos, casa…',
                          acao: FilledButton.tonalIcon(
                            onPressed: () => showCategoriaDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Criar categoria'),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: store.categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = store.categorias[i];
                      final qtd = store.tarefasDaCategoria(c.id);
                      return Material(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            6,
                            8,
                            6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.label_rounded, color: c.color),
                          ),
                          title: Text(
                            c.nome,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            qtd == 1 ? '1 tarefa' : '$qtd tarefas',
                          ),
                          onTap: () =>
                              showCategoriaDialog(context, categoria: c),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'editar') {
                                showCategoriaDialog(context, categoria: c);
                              } else {
                                _excluir(context, c, qtd);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Editar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Excluir'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _excluir(BuildContext context, Categoria c, int qtd) async {
    final store = context.read<TaskStore>();
    final ok = await confirmar(
      context,
      titulo: 'Excluir "${c.nome}"?',
      mensagem: qtd == 0
          ? 'A categoria será removida.'
          : 'Atenção: as $qtd tarefa(s) desta categoria também serão '
                'excluídas pelo servidor.',
    );
    if (!ok || !context.mounted) return;
    await runSafely(
      context,
      () => store.excluirCategoria(c.id),
      success: 'Categoria excluída',
    );
  }
}

Future<void> showCategoriaDialog(
  BuildContext context, {
  Categoria? categoria,
}) async {
  final store = context.read<TaskStore>();
  final nome = TextEditingController(text: categoria?.nome ?? '');
  var cor = categoria?.cor ?? Categoria.paleta.first;
  final formKey = GlobalKey<FormState>();
  var salvando = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(categoria == null ? 'Nova categoria' : 'Editar categoria'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nome,
                autofocus: true,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.label_rounded,
                    color: Categoria.parseHex(cor),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 20),
              Text('Cor', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final hex in Categoria.paleta)
                    _CorOpcao(
                      color: Categoria.parseHex(hex),
                      selected: hex.toUpperCase() == cor.toUpperCase(),
                      onTap: () => setState(() => cor = hex),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: salvando
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => salvando = true);
                    final ok = await runSafely(ctx, () async {
                      if (categoria == null) {
                        await store.criarCategoria(nome.text, cor);
                      } else {
                        await store.atualizarCategoria(
                          categoria.id,
                          nome.text,
                          cor,
                        );
                      }
                    });
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx);
                    } else {
                      setState(() => salvando = false);
                    }
                  },
            child: Text(categoria == null ? 'Criar' : 'Salvar'),
          ),
        ],
      ),
    ),
  );
}

class _CorOpcao extends StatelessWidget {
  const _CorOpcao({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 20, color: Colors.black87)
            : null,
      ),
    );
  }
}
