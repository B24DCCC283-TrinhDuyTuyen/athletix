import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athletix/main.dart';

void main() {
  testWidgets('Athletix app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AthletixApp(),
      ),
    );

    // Verify app title exists
    expect(find.text('ATHLETIX'), findsOneWidget);
  });
}
