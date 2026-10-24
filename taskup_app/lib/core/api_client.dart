import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:http/http.dart' as http;

/// Erro amigável vindo da API (já com a mensagem pronta para exibir).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Cliente HTTP fino para a TaskUp API (Django REST Framework).
///
/// - Autenticação: header `Authorization: Token <token>`
/// - Todas as rotas terminam com `/` (padrão do DRF).
class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  String baseUrl;
  String? token;

  /// Chamado quando a API responde 401 (token inválido/expirado).
  VoidCallback? onUnauthorized;

  static const _timeout = Duration(seconds: 15);

  /// Endereço padrão da API. Em produção é definido no build:
  /// `flutter build web --dart-define=API_URL=https://taskup-api.onrender.com`
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$base/api/$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send(
    () => http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<dynamic> patch(String path, Map<String, dynamic> body) => _send(
    () => http.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send(
    () => http.put(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<void> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou para responder. Verifique o endereço da API.',
      );
    } catch (_) {
      // No navegador, falhas de CORS também caem aqui (sem detalhes).
      throw ApiException(
        'Não foi possível conectar à API em $baseUrl. '
        'Verifique se o Django está rodando e se o CORS está liberado '
        'para este endereço.',
      );
    }

    final text = utf8.decode(res.bodyBytes);
    final dynamic data = text.isEmpty ? null : _tryDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401) onUnauthorized?.call();
    throw ApiException(
      _extractMessage(data, res.statusCode),
      statusCode: res.statusCode,
    );
  }

  static dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  /// Converte o formato de erro do DRF (`{"detail": ...}` ou
  /// `{"campo": ["msg"]}`) em uma frase legível.
  static String _extractMessage(dynamic data, int status) {
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      final parts = <String>[];
      data.forEach((key, value) {
        final msg = value is List ? value.join(' ') : value.toString();
        parts.add(key == 'non_field_errors' ? msg : '${_label(key)}: $msg');
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (data is List && data.isNotEmpty) return data.join('\n');
    switch (status) {
      case 400:
        return 'Dados inválidos.';
      case 403:
        return 'Você não tem permissão para isso.';
      case 404:
        return 'Recurso não encontrado.';
      case 500:
        return 'Erro interno no servidor.';
    }
    return 'Erro inesperado ($status).';
  }

  static String _label(String key) {
    const labels = {
      'username': 'Usuário',
      'password': 'Senha',
      'nome': 'Nome',
      'email': 'E-mail',
      'titulo': 'Título',
      'descricao': 'Descrição',
      'status': 'Status',
      'prazo': 'Prazo',
      'prioridade': 'Prioridade',
      'categoria': 'Categoria',
      'cor': 'Cor',
    };
    return labels[key] ?? key;
  }
}
