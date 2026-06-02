String? optionalString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? optionalDateTime(dynamic value) {
  final text = optionalString(value);
  return text == null ? null : DateTime.tryParse(text);
}
