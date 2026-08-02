import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';

class CropTaskScope extends InheritedNotifier<CropTaskController> {
  const CropTaskScope({
    required CropTaskController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CropTaskController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CropTaskScope>();
    assert(scope != null, 'CropTaskScope is missing above this context.');
    return scope!.notifier!;
  }
}
