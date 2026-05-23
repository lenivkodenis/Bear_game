import 'package:flutter/material.dart';

class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  static const routeName = '/parents';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Родителям')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Безопасный детский MVP',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16),
          Text(
            'Игра помогает ребёнку тренировать таблицу умножения через короткие уровни и добрые подсказки.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'В текущей версии нет регистрации, рекламы, онлайн-платежей, аналитики и сбора персональных данных ребёнка.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
