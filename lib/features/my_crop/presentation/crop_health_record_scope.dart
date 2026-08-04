import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_health_record_controller.dart';

class CropHealthRecordScope
    extends InheritedNotifier<CropHealthRecordController> {
  const CropHealthRecordScope({
    required CropHealthRecordController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CropHealthRecordController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CropHealthRecordScope>();
    assert(scope != null, 'CropHealthRecordScope is missing above context.');
    return scope!.notifier!;
  }
}
