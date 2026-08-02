import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';

class CropScope extends InheritedNotifier<CropController> {
  const CropScope({
    required CropController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CropController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CropScope>();
    assert(scope != null, 'CropScope is missing above this context.');
    return scope!.notifier!;
  }
}
