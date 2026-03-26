import 'package:flutter_test/flutter_test.dart';
import 'package:ai_assistant/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AIAssistantApp());
    expect(find.text('AI Assistant'), findsOneWidget);
  });
}
