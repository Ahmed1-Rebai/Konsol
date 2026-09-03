import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// Terminal palettes tuned to the Konsol brand.
class TermThemes {
  TermThemes._();

  /// Resolve a TerminalTheme from the persisted settings key.
  static TerminalTheme resolve(String? key) {
    switch (key) {
      case 'green':
        return greenOnBlack;
      case 'tokyo':
        return tokyoNight;
      default:
        return konsol;
    }
  }

  static const Color _bg = Color(0xFF060A12);
  static const Color _fg = Color(0xFFD5D6DB);

  /// Default scheme: neon cyan and mint over the app's deep navy.
  static TerminalTheme get konsol => const TerminalTheme(
        cursor: Color(0xFF00D9F0),
        selection: Color(0xFF1D3A5C),
        foreground: Color(0xFFDCE5F0),
        background: Color(0xFF060A12),
        black: Color(0xFF1B2839),
        red: Color(0xFFF87171),
        green: Color(0xFF00E5C4),
        yellow: Color(0xFFFBBF24),
        blue: Color(0xFF60A5FA),
        magenta: Color(0xFFA78BFA),
        cyan: Color(0xFF00D9F0),
        white: Color(0xFFCBD5E1),
        brightBlack: Color(0xFF3E4E66),
        brightRed: Color(0xFFFCA5A5),
        brightGreen: Color(0xFF5EEAD4),
        brightYellow: Color(0xFFFDE047),
        brightBlue: Color(0xFF93C5FD),
        brightMagenta: Color(0xFFC4B5FD),
        brightCyan: Color(0xFF6BEBFA),
        brightWhite: Color(0xFFF1F5F9),
        searchHitBackground: Color(0xFFFBBF24),
        searchHitBackgroundCurrent: Color(0xFF00D9F0),
        searchHitForeground: Color(0xFF060A12),
      );

  static TerminalTheme get tokyoNight => const TerminalTheme(
        cursor: Color(0xFFC0CAF5),
        selection: Color(0xFF3B4261),
        foreground: _fg,
        background: _bg,
        black: Color(0xFF414868),
        red: Color(0xFFF7768E),
        green: Color(0xFF9ECE6A),
        yellow: Color(0xFFE0AF68),
        blue: Color(0xFF7AA2F7),
        magenta: Color(0xFFBB9AF7),
        cyan: Color(0xFF7DCFFF),
        white: Color(0xFFC0CAF5),
        brightBlack: Color(0xFF414868),
        brightRed: Color(0xFFF7768E),
        brightGreen: Color(0xFF9ECE6A),
        brightYellow: Color(0xFFE0AF68),
        brightBlue: Color(0xFF7AA2F7),
        brightMagenta: Color(0xFFBB9AF7),
        brightCyan: Color(0xFF7DCFFF),
        brightWhite: Color(0xFFE0E0E8),
        searchHitBackground: Color(0xFFE0AF68),
        searchHitBackgroundCurrent: Color(0xFF7AA2F7),
        searchHitForeground: Color(0xFF0D0D18),
      );

  /// A classic green-on-black scheme for a nostalgic terminal.
  static TerminalTheme get greenOnBlack => const TerminalTheme(
        cursor: Color(0xFF00FF00),
        selection: Color(0xFF1A3A1A),
        foreground: Color(0xFF00FF00),
        background: Color(0xFF000000),
        black: Color(0xFF000000),
        red: Color(0xFFC14C4C),
        green: Color(0xFF00FF00),
        yellow: Color(0xFFE4C34A),
        blue: Color(0xFF4C6EC1),
        magenta: Color(0xFFA04CA6),
        cyan: Color(0xFF42B8C1),
        white: Color(0xFFC0C0C0),
        brightBlack: Color(0xFF808080),
        brightRed: Color(0xFFFF5454),
        brightGreen: Color(0xFF7DFF7D),
        brightYellow: Color(0xFFFFFF54),
        brightBlue: Color(0xFF7D9EFF),
        brightMagenta: Color(0xFFE37DE3),
        brightCyan: Color(0xFF7DE8FF),
        brightWhite: Color(0xFFFFFFFF),
        searchHitBackground: Color(0xFFFFFF54),
        searchHitBackgroundCurrent: Color(0xFF7D9EFF),
        searchHitForeground: Color(0xFF000000),
      );
}
