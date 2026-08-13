import 'package:flutter/foundation.dart';

/// Global dark/light mode state, toggled by the switch in [Header].
///
/// A [ValueNotifier] is enough here since there's a single boolean flag shared
/// across the whole app — no need for a full state-management package.
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);
