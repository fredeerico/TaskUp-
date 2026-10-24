import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/categoria.dart';
import '../models/subtarefa.dart';
import '../models/tarefa.dart';

enum FiltroTarefa { todas, pendentes, emAndamento, concluidas, atrasadas }

extension FiltroTarefaLabel on FiltroTarefa {
  String get label => switch (this) {
    FiltroTarefa.todas => 'Todas',
    FiltroTarefa.pendentes => 'Pendentes',
    FiltroTarefa.emAndamento => 'Em andamento',
    FiltroTarefa.concluidas => 'Concluídas',
    FiltroTarefa.atrasadas => 'Atrasadas',
  };
}

/// Estado das tarefas, categorias e subtarefas do usuário logado.
class TaskStore extends ChangeNotifier {
  TaskStore(this.api);

  final ApiClient api;

  List<Tarefa> tarefas = [];
  List<Categoria> categorias = [];
  final Map<int, List<Subtarefa>> _subtarefas = {};

  bool loading = false;
  String? error;

  // Filtros da lista
  FiltroTarefa filtro = FiltroTarefa.todas;
  Prioridade? filtroPrioridade;
  int? filtroCategoria;
  String busca = '';

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Evita erro caso uma requisição termine após o logout.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // ---------------------------------------------------------------- carga

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.get('tarefas/', query: {'ordering': 'prazo'}),
        api.get('categorias/'),
      ]);
      tarefas = _lista(results[0], Tarefa.fromJson);
      categorias = _lista(results[1], Categoria.fromJson);
      _ordenarTarefas();
      _ordenarCategorias();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  static List<T> _lista<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromJson,
  ) => (json as List).cast<Map<String, dynamic>>().map(fromJson).toList();

  void _ordenarCategorias() => categorias.sort(
    (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
  );

  /// Abertas primeiro; depois por prazo (sem prazo no fim) e prioridade.
  void _ordenarTarefas() {
    tarefas.sort((a, b) {
      if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
      if (a.prazo != null && b.prazo != null) {
        final c = a.prazo!.compareTo(b.prazo!);
        if (c != 0) return c;
      } else if (a.prazo != null || b.prazo != null) {
        return a.prazo != null ? -1 : 1;
      }
      return b.prioridade.peso.compareTo(a.prioridade.peso);
    });
  }

  // ------------------------------------------------------------- consultas

  Categoria? categoriaPorId(int? id) {
    if (id == null) return null;
    for (final c in categorias) {
      if (c.id == id) return c;
    }
    return null;
  }

  Tarefa? tarefaPorId(int id) {
    for (final t in tarefas) {
      if (t.id == id) return t;
    }
    return null;
  }

  int get totalConcluidas => tarefas.where((t) => t.concluida).length;
  int get totalAtrasadas => tarefas.where((t) => t.atrasada).length;
  int get totalAbertas => tarefas.length - totalConcluidas;

  int contar(FiltroTarefa f) => tarefas.where((t) => _passa(t, f)).length;

  int tarefasDaCategoria(int categoriaId) =>
      tarefas.where((t) => t.categoria == categoriaId).length;

  bool _passa(Tarefa t, FiltroTarefa f) => switch (f) {
    FiltroTarefa.todas => true,
    FiltroTarefa.pendentes => t.status == StatusTarefa.pendente,
    FiltroTarefa.emAndamento => t.status == StatusTarefa.emAndamento,
    FiltroTarefa.concluidas => t.concluida,
    FiltroTarefa.atrasadas => t.atrasada,
  };

  List<Tarefa> get tarefasFiltradas {
    final q = busca.trim().toLowerCase();
    return tarefas.where((t) {
      if (!_passa(t, filtro)) return false;
      if (filtroPrioridade != null && t.prioridade != filtroPrioridade) {
        return false;
      }
      if (filtroCategoria != null && t.categoria != filtroCategoria) {
        return false;
      }
      if (q.isNotEmpty &&
          !t.titulo.toLowerCase().contains(q) &&
          !t.descricao.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void setFiltro(FiltroTarefa f) {
    filtro = f;
    notifyListeners();
  }

  void setFiltroPrioridade(Prioridade? p) {
    filtroPrioridade = p;
    notifyListeners();
  }

  void setFiltroCategoria(int? id) {
    filtroCategoria = id;
    notifyListeners();
  }

  void setBusca(String q) {
    busca = q;
    notifyListeners();
  }

  // --------------------------------------------------------------- tarefas

  Future<Tarefa> criarTarefa(Map<String, dynamic> payload) async {
    final json = await api.post('tarefas/', payload) as Map<String, dynamic>;
    final t = Tarefa.fromJson(json);
    tarefas.add(t);
    _ordenarTarefas();
    notifyListeners();
    return t;
  }

  Future<Tarefa> atualizarTarefa(int id, Map<String, dynamic> payload) async {
    final json =
        await api.patch('tarefas/$id/', payload) as Map<String, dynamic>;
    final t = Tarefa.fromJson(json);
    _replace(t);
    return t;
  }

  Future<void> definirStatus(Tarefa t, StatusTarefa status) async {
    final json = await api.patch('tarefas/${t.id}/', {
      'status': status.api,
    }) as Map<String, dynamic>;
    _replace(Tarefa.fromJson(json));
  }

  Future<void> alternarConclusao(Tarefa t) => definirStatus(
    t,
    t.concluida ? StatusTarefa.pendente : StatusTarefa.concluida,
  );

  Future<void> excluirTarefa(int id) async {
    await api.delete('tarefas/$id/');
    tarefas.removeWhere((t) => t.id == id);
    _subtarefas.remove(id);
    notifyListeners();
  }

  void _replace(Tarefa t) {
    final i = tarefas.indexWhere((x) => x.id == t.id);
    if (i >= 0) tarefas[i] = t;
    _ordenarTarefas();
    notifyListeners();
  }

  // ------------------------------------------------------------ categorias

  Future<Categoria> criarCategoria(String nome, String cor) async {
    final json = await api.post('categorias/', {
      'nome': nome.trim(),
      'cor': cor,
    }) as Map<String, dynamic>;
    final c = Categoria.fromJson(json);
    categorias = [...categorias, c];
    _ordenarCategorias();
    notifyListeners();
    return c;
  }

  Future<void> atualizarCategoria(int id, String nome, String cor) async {
    final json = await api.patch('categorias/$id/', {
      'nome': nome.trim(),
      'cor': cor,
    }) as Map<String, dynamic>;
    final c = Categoria.fromJson(json);
    categorias = categorias.map((x) => x.id == id ? c : x).toList();
    _ordenarCategorias();
    notifyListeners();
  }

  /// Atenção: no back-end, excluir a categoria exclui as tarefas dela (CASCADE).
  Future<void> excluirCategoria(int id) async {
    await api.delete('categorias/$id/');
    categorias = categorias.where((c) => c.id != id).toList();
    tarefas.removeWhere((t) => t.categoria == id);
    if (filtroCategoria == id) filtroCategoria = null;
    notifyListeners();
  }

  // ----------------------------------------------------------- subtarefas

  List<Subtarefa>? subtarefasDe(int tarefaId) => _subtarefas[tarefaId];

  Future<void> carregarSubtarefas(int tarefaId) async {
    final json = await api.get('subtarefas/', query: {'tarefa': '$tarefaId'});
    _subtarefas[tarefaId] = _lista(json, Subtarefa.fromJson);
    notifyListeners();
  }

  Future<void> adicionarSubtarefa(int tarefaId, String descricao) async {
    final atuais = _subtarefas[tarefaId] ?? [];
    final json = await api.post('subtarefas/', {
      'tarefa': tarefaId,
      'descricao': descricao.trim(),
      'concluida': false,
      'ordem': atuais.length,
    }) as Map<String, dynamic>;
    _subtarefas[tarefaId] = [...atuais, Subtarefa.fromJson(json)];
    notifyListeners();
  }

  Future<void> alternarSubtarefa(Subtarefa s) async {
    final json = await api.patch('subtarefas/${s.id}/', {
      'concluida': !s.concluida,
    }) as Map<String, dynamic>;
    final nova = Subtarefa.fromJson(json);
    _subtarefas[s.tarefa] = [
      for (final x in _subtarefas[s.tarefa] ?? <Subtarefa>[])
        x.id == s.id ? nova : x,
    ];
    notifyListeners();
  }

  Future<void> excluirSubtarefa(Subtarefa s) async {
    await api.delete('subtarefas/${s.id}/');
    _subtarefas[s.tarefa] = (_subtarefas[s.tarefa] ?? [])
        .where((x) => x.id != s.id)
        .toList();
    notifyListeners();
  }
}
