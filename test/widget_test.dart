import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_goat/main.dart';

void main() {
  testWidgets('VPN Goat app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VpnGoatApp());
    
    // Verify app title is shown
    expect(find.text('VPN Goat'), findsOneWidget);
  });
}
