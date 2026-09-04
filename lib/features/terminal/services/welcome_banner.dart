import 'package:konsol/data/models/host.dart';

/// Renders the ASCII-art welcome banner shown once a session connects, in
/// place of whatever login banner/MOTD the server prints.
///
/// This is plain ANSI text built once client-side and fed straight into
/// [Terminal.write] — the same true-colour SGR sequences (`ESC[38;2;r;g;bm`)
/// any program would use, nothing SSH- or PTY-specific about it.
class WelcomeBanner {
  WelcomeBanner._();

  static const _reset = '\x1b[0m';
  static const _bold = '\x1b[1m';

  static String _rgb(int r, int g, int b) => '\x1b[38;2;$r;$g;${b}m';

  static final _blue = _rgb(0x2E, 0x7D, 0xE0);
  static final _cyan = _rgb(0x00, 0xD9, 0xF0);
  static final _mint = _rgb(0x00, 0xE5, 0xC4);
  static final _label = _rgb(0x5C, 0x6B, 0x85);
  static final _value = _rgb(0xE8, 0xED, 0xF5);

  /// The swatch row echoes the host-colour palette hosts are tinted with
  /// elsewhere in the app, so the banner reads as unmistakably Konsol's own.
  static final _swatch = [
    _rgb(0x00, 0xD9, 0xF0),
    _rgb(0x00, 0xE5, 0xC4),
    _rgb(0x2E, 0x7D, 0xE0),
    _rgb(0x8B, 0x7B, 0xF7),
    _rgb(0xFB, 0xBF, 0x24),
    _rgb(0xFB, 0x71, 0x85),
    _rgb(0x34, 0xD3, 0x99),
    _rgb(0xF4, 0x72, 0xB6),
  ];

  /// The ANSI Shadow "K" glyph, with the mark's ">_" motif set beside it —
  /// a character-built echo of the app icon rather than a pasted image.
  static final List<String> _art = [
    '$_blue██╗  ██╗',
    '$_blue██║ ██╔╝    $_mint$_bold>_$_reset',
    '$_cyan█████╔╝ ',
    '$_cyan██╔═██╗ ',
    '$_cyan██║  ██╗',
    '$_cyan╚═╝  ╚═╝$_reset',
  ];

  static String build(Host host) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final rows = <MapEntry<String, String>>[
      MapEntry('host', host.name),
      MapEntry('target', '${host.username}@${host.address}:${host.port}'),
      MapEntry('auth', host.authMethod == 'key' ? 'ssh key' : 'password'),
      MapEntry('connected', time),
    ];
    final labelWidth =
        rows.map((r) => r.key.length).reduce((a, b) => a > b ? a : b) + 1;

    final b = StringBuffer()..write('\r\n');
    for (final line in _art) {
      b.write('  $line$_reset\r\n');
    }
    b.write('\r\n');
    b.write('  $_bold${_cyan}KONSOL$_reset\r\n');
    b.write('  ${_label}Connect. SSH. Control.$_reset\r\n');
    b.write('\r\n');
    for (final row in rows) {
      final label = row.key.padRight(labelWidth);
      b.write('  $_label$label$_reset$_value${row.value}$_reset\r\n');
    }
    b.write('\r\n  ');
    for (final swatch in _swatch) {
      b.write('$swatch██');
    }
    b.write('$_reset\r\n\r\n');

    return b.toString();
  }
}
