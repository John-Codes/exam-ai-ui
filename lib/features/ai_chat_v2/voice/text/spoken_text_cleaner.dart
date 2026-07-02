String cleanTextForSpeech(String text) {
  return text
      .replaceAll(RegExp(r'\*+'), '')
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAll(RegExp(r'`[^`]*`'), '')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'),
        (match) => match.group(1) ?? '',
      )
      .trim();
}
