class Ansi {
  /// C0 control codes
  static const String carriageReturn = '\r';
  static const String esc = '\x1B';

  /// Fe Escape sequences
  static const String csi = '$esc[';

  /// Control Sequence Introducer commands
  static String cursorUp([int n = 1]) => '$csi${n}A';

  static String cursorDown([int n = 1]) => '$csi${n}B';

  static String cursorForward([int n = 1]) => '$csi${n}C';

  static String cursorBack([int n = 1]) => '$csi${n}D';

  static const String clearDisplayDown = '${csi}0J';
  static const String clearDisplayUp = '${csi}1J';
  static const String clearEntireLine = '${csi}2K';

  /// Select Graphic Rendition parameters
  static const String reset = '${csi}0m';
  static const String bold = '${csi}1m';
  static const String dim = '${csi}2m';
  static const String italic = '${csi}3m';
  static const String underline = '${csi}4m';

  /// Colors - 3-bit and 4-bit
  static const String red = '${csi}31m';
  static const String green = '${csi}32m';
  static const String yellow = '${csi}33m';
  static const String blue = '${csi}34m';
  static const String magenta = '${csi}35m';
  static const String cyan = '${csi}36m';
  static const String white = '${csi}37m';

  /// Colors - 24-bit - from 0 to 255
  static String color({int r = 0, int g = 0, int b = 0}) =>
      '${csi}38;2;$r;$g;${b}m';
}
