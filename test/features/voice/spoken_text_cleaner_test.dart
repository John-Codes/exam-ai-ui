import 'package:aone_ui/features/ai_chat_v2/voice/text/spoken_text_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes markdown before synthesis', () {
    expect(
      cleanTextForSpeech('## **Hello** [Thor](https://example.com)'),
      'Hello Thor',
    );
  });
}
