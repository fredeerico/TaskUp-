import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskup_app/core/theme.dart';
import 'package:taskup_app/models/tarefa.dart';

void main() {
  test('tema é escuro e usa Material 3', () {
    final theme = AppTheme.dark();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.dark);
  });

  test('converte JSON da API em Tarefa', () {
    final t = Tarefa.fromJson({
      'id': 1,
      'titulo': 'Teste',
      'descricao': 'Desc',
      'status': 'concluida',
      'prioridade': 'alta',
      'prazo': '2026-10-26T02:54:31.918537Z',
      'usuario': 1,
      'categoria': null,
      'data_criacao': '2026-10-24T02:54:31.922219Z',
    });
    expect(t.concluida, isTrue);
    expect(t.prioridade, Prioridade.alta);
    expect(t.atrasada, isFalse);
  });
}
