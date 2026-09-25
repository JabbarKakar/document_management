import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:document_management/core/widgets/vault_session_gate.dart';
import 'package:document_management/features/auth/presentation/providers/auth_state_provider.dart';
import 'support/auth_fakes.dart';

void main() {
  testWidgets(
    'idle lock hides pushed routes and dialogs; unlock retains the route',
    (tester) async {
      final auth = AuthStateProvider(
        authManager: FakeAuthManager(),
        secureStorageService: MemorySecurityStorage(),
      );
      await auth.init();
      await auth.unlockWithPin('1234');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
            home: VaultSessionGate(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          body: TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              useRootNavigator: false,
                              builder: (_) => const AlertDialog(
                                content: Text('Sensitive dialog'),
                              ),
                            ),
                            child: const Text('Private document'),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open document'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open document'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private document'));
      await tester.pumpAndSettle();
      expect(find.text('Sensitive dialog'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(auth.isLocked, isTrue);
      expect(find.text('Vault locked'), findsOneWidget);
      expect(find.text('Sensitive dialog'), findsNothing);
      expect(find.text('Private document'), findsNothing);
      expect(
        find.text('Sensitive dialog', skipOffstage: false),
        findsOneWidget,
      );
      await auth.unlockWithDevice();
      await tester.pumpAndSettle();
      expect(find.text('Sensitive dialog'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
