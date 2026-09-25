import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/auth/auth_manager.dart';
import 'package:document_management/features/auth/presentation/providers/auth_state_provider.dart';
import 'support/auth_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAuthManager manager;
  late MemorySecurityStorage storage;
  late AuthStateProvider auth;
  late DateTime now;
  setUp(() async {
    manager = FakeAuthManager();
    storage = MemorySecurityStorage();
    now = DateTime(2026, 9, 25, 9);
    auth = AuthStateProvider(
      authManager: manager,
      secureStorageService: storage,
      now: () => now,
    );
    await auth.init();
  });
  tearDown(() => auth.dispose());

  test('new PINs use one 4–8 digit policy', () {
    for (final invalid in ['123', '123456789', 'abcd', '12 34', '１２３４']) {
      expect(AuthManager.validatePin(invalid), isNotNull);
    }
    expect(AuthManager.validatePin('1234'), isNull);
    expect(AuthManager.validatePin('12345678'), isNull);
  });
  test(
    'device credentials unlock without biometric enrollment preference',
    () async {
      expect(await auth.unlockWithDevice(), isTrue);
      expect(auth.isLocked, isFalse);
      expect(manager.deviceChecks, 1);
    },
  );
  test('cancelled/failed device recovery never changes PIN', () async {
    for (final outcome in [null, false]) {
      manager.deviceResult = outcome;
      expect(await auth.resetPinWithDevice('5678', '5678'), isFalse);
      expect(manager.pin, '1234');
      expect(auth.isLocked, isTrue);
    }
  });
  test('forgotten PIN recovery requires fresh device verification', () async {
    expect(await auth.resetPinWithDevice('5678', '5678'), isTrue);
    expect(manager.deviceChecks, 1);
    expect(manager.pin, '5678');
    auth.lock();
    expect(await auth.unlockWithPin('1234'), isFalse);
    expect(await auth.unlockWithPin('5678'), isTrue);
  });
  test('setup cannot reset an existing PIN without authentication', () async {
    expect(await auth.setPin('9999', '9999'), isFalse);
    expect(manager.pin, '1234');
  });
  test(
    'PIN cooldown survives provider recreation; device recovery still works',
    () async {
      for (var i = 0; i < 5; i++) {
        await auth.unlockWithPin('0000');
      }
      auth.dispose();
      auth = AuthStateProvider(
        authManager: manager,
        secureStorageService: storage,
        now: () => now,
      );
      await auth.init();
      expect(await auth.unlockWithPin('1234'), isFalse);
      expect(manager.pinChecks, 5);
      expect(await auth.unlockWithDevice(), isTrue);
      expect(auth.isLocked, isFalse);
    },
  );
  test(
    'backgrounding does not extend inactivity and locked reads are rejected',
    () async {
      await auth.unlockWithPin('1234');
      now = now.add(const Duration(seconds: 59));
      auth.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 2));
      expect(auth.requireUnlocked, throwsStateError);
      expect(auth.isLocked, isTrue);
    },
  );
  test('legacy long PIN remains usable at authentication boundary', () async {
    manager.pin = '123456789';
    expect(await auth.unlockWithPin(manager.pin), isTrue);
  });
}
