import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/usuario.dart';

/// Guarda a sessão (token + usuário) e o endereço da API.
class Session extends ChangeNotifier {
  Session() : api = ApiClient(baseUrl: ApiClient.defaultBaseUrl) {
    api.onUnauthorized = () {
      if (isLoggedIn) logout(expired: true);
    };
  }

  static const _kBaseUrl = 'taskup.baseUrl';
  static const _kToken = 'taskup.token';
  static const _kUser = 'taskup.user';

  final ApiClient api;
  Usuario? user;
  bool ready = false;
  bool sessionExpired = false;

  bool get isLoggedIn => api.token != null && user != null;
  String get baseUrl => api.baseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    api.baseUrl = prefs.getString(_kBaseUrl) ?? ApiClient.defaultBaseUrl;
    api.token = prefs.getString(_kToken);
    final rawUser = prefs.getString(_kUser);
    if (rawUser != null) {
      user = Usuario.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    }
    if (user == null) api.token = null;
    ready = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    api.baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, api.baseUrl);
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    api.token = null;
    final res = await api.post('login/', {
      'username': username.trim(),
      'password': password,
    }) as Map<String, dynamic>;

    api.token = res['token'] as String;
    user = Usuario.fromJson({...res, 'username': username.trim()});
    sessionExpired = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, api.token!);
    await prefs.setString(_kUser, jsonEncode(user!.toJson()));
    notifyListeners();
  }

  Future<void> register({
    required String nome,
    required String username,
    required String email,
    required String password,
  }) async {
    api.token = null; // a rota é pública; um token antigo causaria 401
    await api.post('usuarios/', {
      'nome': nome.trim(),
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });
    await login(username, password);
  }

  Future<void> logout({bool expired = false}) async {
    api.token = null;
    user = null;
    sessionExpired = expired;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }
}
