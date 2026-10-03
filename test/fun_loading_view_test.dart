import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aone_ui/features/ai_quiz/ui/fun_loading_view.dart';

void main() {
  testWidgets('FunLoadingView shows hint, timer copy and a nugget card',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FunLoadingView(hint: 'Loading Air Brakes questions…')),
    ));

    expect(find.text('Loading Air Brakes questions…'), findsOneWidget);
    expect(find.textContaining('Starting engine…'), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
  });

  testWidgets('FunLoadingView falls back to the AI tutor hint',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FunLoadingView()),
    ));

    expect(find.text('Waking up your AI tutor…'), findsOneWidget);
  });

  testWidgets('FunLoadingView rotates nuggets over time', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FunLoadingView()),
    ));

    expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);

    await tester.pump(const Duration(seconds: 6)); // rotation timer fires
    await tester.pump(const Duration(milliseconds: 500)); // switcher settles

    expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(0)), findsNothing);
  });
}
