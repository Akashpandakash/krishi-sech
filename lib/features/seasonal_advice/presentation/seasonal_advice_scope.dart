import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';

class SeasonalAdviceScope extends InheritedNotifier<SeasonalAdviceController> {
  const SeasonalAdviceScope({
    required SeasonalAdviceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static SeasonalAdviceController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SeasonalAdviceScope>();
    assert(scope != null, 'SeasonalAdviceScope is missing above this context.');
    return scope!.notifier!;
  }
}
