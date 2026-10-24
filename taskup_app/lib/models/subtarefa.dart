class Subtarefa {
  Subtarefa({
    required this.id,
    required this.tarefa,
    required this.descricao,
    required this.concluida,
    required this.ordem,
  });

  final int id;
  final int tarefa;
  final String descricao;
  final bool concluida;
  final int ordem;

  factory Subtarefa.fromJson(Map<String, dynamic> json) => Subtarefa(
    id: json['id'] as int,
    tarefa: json['tarefa'] as int,
    descricao: (json['descricao'] ?? '') as String,
    concluida: (json['concluida'] ?? false) as bool,
    ordem: (json['ordem'] ?? 0) as int,
  );
}
