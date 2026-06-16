import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wplus/main.dart';

void main() {
  testWidgets('W+ app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WPlusApp()));
    await tester.pumpAndSettle();

    expect(find.text('W+'), findsOneWidget);
  });
}
