import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  int _calculateScore(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%\^&\*\-_]').hasMatch(value)) score++;
    return score.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore(password);
    final percent = (score / 5.0).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    Color color;
    String label;
    if (percent < 0.34) {
      color = theme.colorScheme.error;
      label = 'Lemah';
    } else if (percent < 0.67) {
      color = Colors.amber;
      label = 'Sedang';
    } else {
      color = theme.colorScheme.primary;
      label = 'Kuat';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percent,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Text('Kekuatan password: $label', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
