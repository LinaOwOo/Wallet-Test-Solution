String formatAddressForCell(
  String address,
  double textScaleFactor,
) {
  final hasPrefix = address.startsWith('0x');
  final prefix = hasPrefix ? '0x' : '';
  final main = hasPrefix ? address.substring(2) : address;

  if (main.length <= 12) {
    return address;
  }

  final headLength = textScaleFactor < 1.6 ? 6 : 4;
  return '$prefix${main.substring(0, headLength)}…${main.substring(main.length - 4)}';
}
