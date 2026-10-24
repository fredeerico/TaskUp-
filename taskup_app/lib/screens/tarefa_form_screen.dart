import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tarefa.dart';
import '../state/task_store.dart';
import '../widgets/common.dart';

/// Criação e edição de tarefas.
class TarefaFormScreen extends StatefulWidget {
  const TarefaFormScreen({super.key, this.tarefa});

  final Tarefa? tarefa;

  @override
  State<TarefaFormScreen> createState() => _TarefaFormScreenState();
}

class _TarefaFormScreenState extends State<TarefaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late StatusTarefa _status;
  late Prioridade _prioridade;
  DateTime? _prazo;
  int? _categoria;
  bool _salvando = false;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarefa;
    _titulo = TextEditingController(text: t?.titulo ?? '');
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _status = t?.status ?? StatusTarefa.pendente;
    _prioridade = t?.prioridade ?? Prioridade.media;
    _prazo = t?.prazo;
    _categoria = t?.categoria;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherPrazo() async {
    final agora = DateTime.now();
    final inicial = _prazo ?? agora;
    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(agora.year - 1),
      lastDate: DateTime(agora.year + 5),
      helpText: 'Prazo da tarefa',
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _prazo != null
          ? TimeOfDay.fromDateTime(_prazo!)
          : const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Horário (opcional)',
      cancelText: 'Sem horário',
    );
    if (!mounted) return;
    setState(() {
      _prazo = hora == null
          ? DateTime(data.year, data.month, data.day, 23, 59)
          : DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final store = context.read<TaskStore>();
    final payload = Tarefa.payload(
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      status: _status,
      prioridade: _prioridade,
      prazo: _prazo,
      categoria: _categoria,
    );
    final ok = await runSafely(context, () async {
      if (_editando) {
        await store.atualizarTarefa(widget.tarefa!.id, payload);
      } else {
        await store.criarTarefa(payload);
      }
    }, success: _editando ? 'Tarefa atualizada' : 'Tarefa criada');
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_editando ? 'Editar tarefa' : 'Nova tarefa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                TextFormField(
                  controller: _titulo,
                  autofocus: !_editando,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 255,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Dê um título à tarefa' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descricao,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Descreva a tarefa (obrigatório na API)'
                      : null,
                ),
                const SizedBox(height: 24),
                const _Secao('Prioridade'),
                SegmentedButton<Prioridade>(
                  segments: [
                    for (final p in Prioridade.values)
                      ButtonSegment(
                        value: p,
                        label: Text(p.label),
                        icon: Icon(p.icon, color: p.color),
                      ),
                  ],
                  selected: {_prioridade},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _prioridade = s.first),
                ),
                const SizedBox(height: 24),
                const _Secao('Status'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final st in StatusTarefa.values)
                      ChoiceChip(
                        avatar: Icon(st.icon, size: 18),
                        label: Text(st.label),
                        selected: _status == st,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _status = st),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const _Secao('Prazo'),
                Material(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _prazo == null
                          ? 'Sem prazo'
                          : DateFormat("EEE, d 'de' MMM 'de' y · HH:mm")
                                .format(_prazo!),
                    ),
                    subtitle: _prazo == null
                        ? const Text('Toque para definir')
                        : null,
                    trailing: _prazo == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Remover prazo',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _prazo = null),
                          ),
                    onTap: _escolherPrazo,
                  ),
                ),
                const SizedBox(height: 24),
                const _Secao('Categoria'),
                LayoutBuilder(
                  builder: (context, c) => DropdownMenu<int?>(
                    width: c.maxWidth,
                    initialSelection: _categoria,
                    leadingIcon: const Icon(Icons.label_outline),
                    hintText: 'Sem categoria',
                    onSelected: (v) => setState(() => _categoria = v),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry<int?>(
                        value: null,
                        label: 'Sem categoria',
                      ),
                      for (final cat in store.categorias)
                        DropdownMenuEntry<int?>(
                          value: cat.id,
                          label: cat.nome,
                          leadingIcon: CircleAvatar(
                            radius: 6,
                            backgroundColor: cat.color,
                          ),
                        ),
                    ],
                  ),
                ),
                if (store.categorias.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Crie categorias na aba "Categorias".',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
