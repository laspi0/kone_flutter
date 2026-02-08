import '../models.dart';

String normalizeHeader(String value) {
  return normalizeText(value);
}

String normalizeText(String value) {
  final trimmed = value.trim().toLowerCase();
  final withoutAccents = trimmed
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c');
  return withoutAccents.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String cellValue(List<dynamic> row, int index) {
  if (index >= row.length) return '';
  final value = row[index]?.value;
  return value == null ? '' : value.toString().trim();
}

double? parseDouble(String raw) {
  if (raw.isEmpty) return null;
  var cleaned = raw.replaceAll('\u00A0', ' ').trim();
  cleaned = cleaned.replaceAll(RegExp(r'[^\d,.\-]'), '');
  if (cleaned.isEmpty) return null;
  if (cleaned.contains(',') && !cleaned.contains('.')) {
    cleaned = cleaned.replaceAll(',', '.');
  } else {
    cleaned = cleaned.replaceAll(',', '');
  }
  return double.tryParse(cleaned);
}

int? parseInt(String raw) {
  if (raw.isEmpty) return null;
  var cleaned = raw.replaceAll('\u00A0', ' ').trim();
  cleaned = cleaned.replaceAll(RegExp(r'[^\d\-]'), '');
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}

List<String> findNearNameMatches(
  String normalizedName,
  List<Product> products,
) {
  if (normalizedName.isEmpty) return [];
  final results = <String>[];
  for (final product in products) {
    final normalizedExisting = normalizeText(product.name);
    if (normalizedExisting.isEmpty || normalizedExisting == normalizedName) {
      continue;
    }
    final contains = normalizedExisting.contains(normalizedName) ||
        normalizedName.contains(normalizedExisting);
    final prefixRatio = commonPrefixRatio(normalizedExisting, normalizedName);
    final lengthDiff =
        (normalizedExisting.length - normalizedName.length).abs();
    final isNear = contains || (prefixRatio >= 0.85 && lengthDiff <= 3);
    if (isNear) {
      results.add('"${product.name}"');
      if (results.length >= 3) break;
    }
  }
  return results;
}

double commonPrefixRatio(String a, String b) {
  final minLen = a.length < b.length ? a.length : b.length;
  int i = 0;
  while (i < minLen && a[i] == b[i]) {
    i++;
  }
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 0;
  return i / maxLen;
}
