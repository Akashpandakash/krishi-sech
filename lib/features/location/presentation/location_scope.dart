import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';

class LocationScope extends InheritedNotifier<LocationController> {
  const LocationScope({
    required LocationController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LocationController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocationScope>();
    assert(scope != null, 'LocationScope is missing above this context.');
    return scope!.notifier!;
  }
}
