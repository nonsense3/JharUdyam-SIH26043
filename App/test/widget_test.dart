import 'package:flutter_test/flutter_test.dart';
import 'package:jharudyam_citizen/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const JharUdyamApp());
    expect(find.text('JharUdyam'), findsOneWidget);
  });
}
