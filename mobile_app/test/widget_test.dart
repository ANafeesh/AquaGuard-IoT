import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaguard/main.dart';

void main() {
  testWidgets('AquaGuard smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AquaGuardApp(),
      ),
    );

    // Verify that AquaGuard brand title appears
    expect(find.text('AquaGuard'), findsOneWidget);
  });
}
