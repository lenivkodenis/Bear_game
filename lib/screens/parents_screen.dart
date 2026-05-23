import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/game_card.dart';

class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  static const routeName = '/parents';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Родителям')),
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.frostBlue,
                            child: Icon(
                              Icons.family_restroom_rounded,
                              color: AppTheme.softBlue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Родителям',
                              style: AppTheme.screenTitleStyle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Игра помогает ребёнку тренировать таблицу умножения через короткие уровни и добрые подсказки.',
                        style: AppTheme.bodyStyle,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'В текущей версии нет регистрации, рекламы, онлайн-платежей, аналитики и сбора персональных данных ребёнка.',
                        style: AppTheme.bodyStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
