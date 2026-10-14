import 'package:art_platform/ui/widgets/profile_screen_widgets/rank_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [RankProgressBar], which shows a user's rank based on their Artist Points.
void main() {
  Future<void> pumpRankBar(WidgetTester tester, int artistPoints) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RankProgressBar(artistPoints: artistPoints))),
    );
  }

  testWidgets('a new user starts as Novice', (tester) async {
    await pumpRankBar(tester, 0);
    expect(find.text('NOVICE'), findsOneWidget);
    expect(find.text('0 / 500 AP'), findsOneWidget);
  });

  testWidgets('reaching a rank threshold moves the user to the next rank', (tester) async {
    await pumpRankBar(tester, 499);
    expect(find.text('NOVICE'), findsOneWidget);

    await pumpRankBar(tester, 500);
    expect(find.text('APPRENTICE'), findsOneWidget);
    expect(find.text('500 / 1500 AP'), findsOneWidget);
  });

  testWidgets('shows the progress towards the next rank', (tester) async {
    await pumpRankBar(tester, 2250); // halfway through Artisan (1500 - 3000)
    expect(find.text('ARTISAN'), findsOneWidget);

    final progressBar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressBar.value, closeTo(0.5, 0.001));
  });

  testWidgets('users above the highest threshold stay Legend with a full bar', (tester) async {
    await pumpRankBar(tester, 50000);
    expect(find.text('LEGEND'), findsOneWidget);

    final progressBar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressBar.value, 1.0);
  });
}
