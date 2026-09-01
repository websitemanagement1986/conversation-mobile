import 'package:flutter_test/flutter_test.dart';
import 'package:voice_language_tutor/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LanguageTutorApp());
    expect(find.text('Gemini API Key'), findsOneWidget);
  });
}
