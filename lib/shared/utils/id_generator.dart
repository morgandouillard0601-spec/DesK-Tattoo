String generateId([String prefix = '']) {
  final int micros = DateTime.now().microsecondsSinceEpoch;
  return prefix.isEmpty ? '$micros' : '${prefix}_$micros';
}
