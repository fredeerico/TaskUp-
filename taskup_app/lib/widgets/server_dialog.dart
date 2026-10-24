import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/session.dart';

/// Permite trocar o endereço da API sem recompilar o app.
Future<void> showServerDialog(BuildContext context) async {
  final session = context.read<Session>();
  final controller = TextEditingController(text: session.baseUrl);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.dns_outlined),
      title: const Text('Servidor da API'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                hintText: 'http://192.168.0.10:8000',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (v) {
                final uri = Uri.tryParse((v ?? '').trim());
                if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                  return 'Informe uma URL válida (com http://)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Local: http://127.0.0.1:8000\n'
              'O endereço do front precisa estar liberado no CORS do Django.',
              style: Theme.of(ctx).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => controller.text = ApiClient.defaultBaseUrl,
          child: const Text('Padrão'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await session.setBaseUrl(controller.text);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}
