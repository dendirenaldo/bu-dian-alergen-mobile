import 'package:flutter/material.dart';

/// Meter kekuatan password — informatif saja, TIDAK memblokir submit.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  static bool _hasMinLength(String v) => v.length >= 8;
  static bool _hasUpper(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool _hasLower(String v) => RegExp(r'[a-z]').hasMatch(v);
  static bool _hasDigit(String v) => RegExp(r'[0-9]').hasMatch(v);
  static bool _hasSymbolOrLong(String v) =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(v) || v.length >= 12;

  int get _score {
    var s = 0;
    if (_hasMinLength(password)) s++;
    if (_hasUpper(password)) s++;
    if (_hasLower(password)) s++;
    if (_hasDigit(password)) s++;
    if (_hasSymbolOrLong(password)) s++;
    return s;
  }

  String get _label {
    if (_score <= 2) return 'Lemah';
    if (_score <= 4) return 'Sedang';
    return 'Kuat';
  }

  Color _color(BuildContext context) {
    if (_score <= 2) return Theme.of(context).colorScheme.error;
    if (_score <= 4) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = _color(context);
    final criteria = [
      ('Minimal 8 karakter', _hasMinLength(password)),
      ('Huruf besar (A-Z)', _hasUpper(password)),
      ('Huruf kecil (a-z)', _hasLower(password)),
      ('Angka (0-9)', _hasDigit(password)),
      ('Simbol atau ≥12 karakter', _hasSymbolOrLong(password)),
    ];

    return Semantics(
      label: 'Kekuatan kata sandi: $_label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: password.isEmpty ? 0 : score / 5,
                    minHeight: 6,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in criteria)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    c.$2 ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: c.$2
                        ? const Color(0xFF10B981)
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
