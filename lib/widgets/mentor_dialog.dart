import 'package:flutter/material.dart';

class MentorDialog extends StatelessWidget {
  const MentorDialog({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Мудрец',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Привет, маленький медвежонок. Я помогу тебе найти путь, если ты решишь пример.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onClose,
                    child: const Text('Хорошо'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
