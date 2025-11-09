import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_tracks/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: HappyTracksApp(),
      ),
    );

    // Verify app bar is present
    expect(find.text('HappyTracks'), findsOneWidget);

    // Verify welcome message is present
    expect(find.text('Welcome to HappyTracks'), findsOneWidget);
  });
}
