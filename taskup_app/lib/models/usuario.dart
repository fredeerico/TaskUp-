class Usuario {
  Usuario({
    required this.id,
    required this.username,
    required this.nome,
    required this.email,
  });

  final int id;
  final String username;
  final String nome;
  final String email;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    username: (json['username'] ?? '') as String,
    nome: (json['nome'] ?? '') as String,
    email: (json['email'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nome': nome,
    'email': email,
  };

  String get displayName => nome.isNotEmpty ? nome : username;

  String get iniciais {
    final partes = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
