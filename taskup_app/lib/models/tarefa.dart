import 'package:flutter/material.dart';

import '../core/theme.dart';

enum Prioridade {
  baixa('baixa', 'Baixa', AppTheme.prioridadeBaixa, Icons.keyboard_arrow_down),
  media('media', 'Média', AppTheme.prioridadeMedia, Icons.drag_handle),
  alta('alta', 'Alta', AppTheme.prioridadeAlta, Icons.keyboard_arrow_up);

  const Prioridade(this.api, this.label, this.color, this.icon);

  final String api;
  final String label;
  final Color color;
  final IconData icon;

  int get peso => index;

  static Prioridade fromApi(String? v) => Prioridade.values.firstWhere(
    (p) => p.api == v,
    orElse: () => Prioridade.media,
  );
}

/// O campo `status` da API é texto livre; o app padroniza estes três.
enum StatusTarefa {
  pendente('pendente', 'Pendente', Icons.radio_button_unchecked),
  emAndamento('em_andamento', 'Em andamento', Icons.timelapse),
  concluida('concluida', 'Concluída', Icons.check_circle);

  const StatusTarefa(this.api, this.label, this.icon);

  final String api;
  final String label;
  final IconData icon;

  static StatusTarefa fromApi(String? v) {
    final s = (v ?? '').toLowerCase().trim();
    if (s.startsWith('conclu')) return StatusTarefa.concluida;
    if (s.contains('andamento') || s == 'fazendo') {
      return StatusTarefa.emAndamento;
    }
    return StatusTarefa.pendente;
  }
}

class Tarefa {
  Tarefa({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.prioridade,
    required this.usuario,
    this.prazo,
    this.categoria,
    this.dataCriacao,
  });

  final int id;
  final String titulo;
  final String descricao;
  final StatusTarefa status;
  final Prioridade prioridade;
  final DateTime? prazo;
  final int? categoria;
  final int usuario;
  final DateTime? dataCriacao;

  bool get concluida => status == StatusTarefa.concluida;

  bool get atrasada =>
      !concluida && prazo != null && prazo!.isBefore(DateTime.now());

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
    id: json['id'] as int,
    titulo: (json['titulo'] ?? '') as String,
    descricao: (json['descricao'] ?? '') as String,
    status: StatusTarefa.fromApi(json['status'] as String?),
    prioridade: Prioridade.fromApi(json['prioridade'] as String?),
    prazo: _date(json['prazo']),
    categoria: json['categoria'] as int?,
    usuario: json['usuario'] as int,
    dataCriacao: _date(json['data_criacao']),
  );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String)?.toLocal();

  /// Corpo enviado em POST/PUT. `usuario` é preenchido pelo back-end.
  static Map<String, dynamic> payload({
    required String titulo,
    required String descricao,
    required StatusTarefa status,
    required Prioridade prioridade,
    DateTime? prazo,
    int? categoria,
  }) => {
    'titulo': titulo,
    'descricao': descricao,
    'status': status.api,
    'prioridade': prioridade.api,
    'prazo': prazo?.toUtc().toIso8601String(),
    'categoria': categoria,
  };
}
