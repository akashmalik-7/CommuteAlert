import 'package:flutter_test/flutter_test.dart';

import 'package:commutealert_app/main.dart';

void main() {
  testWidgets('CommuteAlert starts on the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CommuteAlertApp());
    expect(find.text('CommuteAlert'), findsOneWidget);
    expect(find.text('Your Journey, Our Priority'), findsOneWidget);
  });
}
