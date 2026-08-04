import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Iterable<MethodCall> hapticCalls() =>
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate');

  testWidgets('one completed tap invokes one action and one haptic', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppPressable(
            onTap: () => taps++,
            child: const SizedBox.square(key: Key('pressable'), dimension: 64),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppPressable));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(hapticCalls(), hasLength(1));
  });

  testWidgets('disabled pressable has no action, animation, or haptic', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppPressable(
            enabled: false,
            onTap: () => taps++,
            child: const SizedBox.square(
              key: Key('disabled_pressable'),
              dimension: 64,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('disabled_pressable')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(hapticCalls(), isEmpty);
    final transform = tester.widget<Transform>(find.byType(Transform).first);
    expect(transform.transform.getMaxScaleOnAxis(), 1);
  });

  testWidgets('drag cancellation does not trigger action or haptic', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppPressable(
            onTap: () => taps++,
            child: const SizedBox(
              key: Key('scroll_pressable'),
              width: 200,
              height: 80,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(AppPressable), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(hapticCalls(), isEmpty);
  });
}
