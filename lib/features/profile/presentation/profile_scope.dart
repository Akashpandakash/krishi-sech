import 'package:flutter/widgets.dart';
import 'controllers/profile_controller.dart';

class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    required ProfileController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static ProfileController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null);
    return scope!.notifier!;
  }

  static ProfileController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileScope>()?.notifier;
}
