import 'package:flutter/material.dart';

import 'app_state.dart';
import 'app_logo.dart';

/// Боковое меню Vigil AI: сервер ИИ, новый чат, о приложении.
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Drawer(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const AppLogo(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vigil AI', style: text.titleLarge),
                          Text(
                            'Ваш умный помощник',
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _header(context, 'Чат'),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Новый чат'),
                subtitle: Text('Сообщений: ${state.aiChat.length}'),
                onTap: state.aiChat.isEmpty
                    ? null
                    : () {
                        state.clearChat();
                        Navigator.pop(context);
                      },
              ),
              _header(context, 'Сервер ИИ'),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Источник ответов'),
                subtitle: Text(state.aiBase.isEmpty ? 'Бесплатный (без ключа)' : state.aiBase),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => editAiServer(context, state),
              ),
              _header(context, 'Что умеет Vigil AI'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '• Отвечает на любые вопросы, пишет тексты, переводит, объясняет\n'
                  '• Сам решает примеры, уравнения (линейные, квадратные и любые другие — приближённо) '
                  'и проценты — мгновенно и без интернета\n'
                  '• Долгое нажатие на сообщение — копировать',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

Future<void> editAiServer(BuildContext context, AppState state) async {
  final base = TextEditingController(text: state.aiBase);
  final key = TextEditingController(text: state.aiKey);
  final model = TextEditingController(text: state.aiModel);
  final save = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_rounded),
      title: const Text('Сервер Vigil AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Оставьте адрес пустым — Vigil AI будет работать бесплатно без ключа '
              '(не чаще одного ответа в 45 секунд). Или укажите OpenAI-совместимый сервер со своим ключом.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: base,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Адрес API', hintText: 'https://api.openai.com/v1'),
            ),
            TextField(
              controller: key,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ключ API'),
            ),
            TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Модель', hintText: 'gpt-4o-mini'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            base.clear();
            key.clear();
            model.clear();
            Navigator.pop(c, true);
          },
          child: const Text('Бесплатный'),
        ),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Сохранить')),
      ],
    ),
  );
  if (save ?? false) {
    state.setAiServer(base: base.text, key: key.text, model: model.text);
  }
}
