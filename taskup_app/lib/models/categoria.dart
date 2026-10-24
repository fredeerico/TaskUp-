import 'package:flutter/material.dart';

class Categoria {
  Categoria({
    required this.id,
    required this.nome,
    required this.cor,
    required this.usuario,
  });

  final int id;
  final String nome;

  /// Cor salva como texto hexadecimal (ex.: `#8B7CF6`).
  final String cor;
  final int usuario;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'] as int,
    nome: (json['nome'] ?? '') as String,
    cor: (json['cor'] ?? '#8B7CF6') as String,
    usuario: json['usuario'] as int,
  );

  Color get color => parseHex(cor);

  static Color parseHex(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value == null ? const Color(0xFF8B7CF6) : Color(value);
  }

  /// Paleta oferecida ao criar/editar categorias.
  static const paleta = [
    '#8B7CF6',
    '#60A5FA',
    '#34D399',
    '#FBBF24',
    '#F87171',
    '#F472B6',
    '#22D3EE',
    '#A3E635',
    '#FB923C',
    '#94A3B8',
  ];
}
