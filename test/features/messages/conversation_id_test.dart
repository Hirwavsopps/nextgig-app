import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/messages/domain/conversation_id.dart';

void main() {
  test('conversation id is the same whichever person is named first', () {
    expect(
      conversationId('seed-mentor', 'seed-talent'),
      'seed-mentor_seed-talent',
    );
    expect(
      conversationId('seed-talent', 'seed-mentor'),
      conversationId('seed-mentor', 'seed-talent'),
    );
  });
}
