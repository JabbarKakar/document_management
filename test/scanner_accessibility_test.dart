import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/theme/app_theme.dart';
import 'package:document_management/features/documents/presentation/screens/camera_scanner_screen.dart';

void main() {
  testWidgets('scanner fits a small phone with large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const CameraScannerScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Capture page'), findsOneWidget);
    expect(find.text('Document B/W'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
