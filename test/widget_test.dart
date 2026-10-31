import 'package:flutter_test/flutter_test.dart';

import 'package:habitflow/main.dart';

void main() {
  testWidgets('HabitFlow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitFlowApp());
    // Basic smoke test - app loads without errors
    expect(find.byType(HabitFlowApp), findsOneWidget);
  });
}
