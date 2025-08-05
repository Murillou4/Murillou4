// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_correction_app/main.dart';
import 'package:exam_correction_app/src/core/repositories/correction_repository.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    // Initialize repository for testing
    final repository = CorrectionRepository();
    await repository.initialize();

    // Build our app and trigger a frame.
    await tester.pumpWidget(ExamCorrectionApp(repository: repository));

    // Verify that the home screen loads with expected text.
    expect(find.text('Correção Automática'), findsOneWidget);
    expect(find.text('Iniciar Escaneamento'), findsOneWidget);

    // Clean up
    await repository.close();
  });
}
