import 'package:flutter/services.dart';

/// Capitalises the first letter of each word as it's typed, e.g. "nathan reid" → "Nathan Reid".
/// Only touches letters right after a word boundary, so it never fights the user mid-word.
class TitleCaseTextFormatter extends TextInputFormatter {
  const TitleCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    var atWordStart = true;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (atWordStart && RegExp(r'[a-z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
      } else {
        buffer.write(char);
      }
      atWordStart = char.trim().isEmpty;
    }

    final formatted = buffer.toString();
    if (formatted == text) return newValue;
    final lengthDiff = formatted.length - text.length;
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: (newValue.selection.end + lengthDiff).clamp(0, formatted.length)),
    );
  }
}

/// A password needs at least one lowercase letter, one uppercase letter, one symbol, and 8+ characters.
class PasswordStrength {
  static final _lower = RegExp('[a-z]');
  static final _upper = RegExp('[A-Z]');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');

  static bool isValid(String password) =>
      password.length >= 8 && _lower.hasMatch(password) && _upper.hasMatch(password) && _symbol.hasMatch(password);

  /// A short message describing what's still missing, or null if the password is valid.
  static String? describe(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'At least 8 characters';
    final missing = [
      if (!_lower.hasMatch(password)) 'a lowercase letter',
      if (!_upper.hasMatch(password)) 'an uppercase letter',
      if (!_symbol.hasMatch(password)) 'a symbol',
    ];
    if (missing.isEmpty) return null;
    return 'Needs ${missing.join(', ')}';
  }
}
