import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';

class WeatherScope extends InheritedNotifier<WeatherController> {
  const WeatherScope({
    required WeatherController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static WeatherController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WeatherScope>();
    assert(scope != null, 'WeatherScope is missing above this context.');
    return scope!.notifier!;
  }
}
