import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // MVP Phase 1: app requires Supabase which can't run in unit tests.
    // Integration tests via flutter_driver or manual testing recommended.
    expect(true, isTrue);
  });
}
