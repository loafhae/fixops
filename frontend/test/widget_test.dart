import 'package:flutter_test/flutter_test.dart';
import 'package:fixops_frontend/main.dart';

void main() {
  testWidgets('FixOpsApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FixOpsApp());
    expect(find.byType(FixOpsApp), findsOneWidget);
  });
}
