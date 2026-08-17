import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/localization/app_date_format.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_notification_content.dart';

/// Locales the app ships but the Flutter framework does not localize. They
/// route through the app's fallback Material delegate, so `intl` never gets
/// date symbols for them and `DateFormat(pattern, code)` throws `ArgumentError`.
///
/// This crashed crop task reminders: `CropTaskController._scheduleReminder`
/// builds notification content with no guard around it, and it is awaited from
/// addTask, updateTask and toggleComplete — so saving a task in any of these
/// languages threw straight out of the controller.
const _frameworkFallbackLocales = [
  'brx',
  'doi',
  'kok',
  'ks',
  'mai',
  'mni',
  'sa',
  'sat',
  'sd',
];

const _localizedLocales = ['en', 'hi', 'bn', 'ta', 'te', 'mr', 'gu', 'pa'];

const _shippedLocales = [..._localizedLocales, ..._frameworkFallbackLocales];

Crop _crop() => Crop(
  id: 'crop-1',
  kind: CropKind.wheat,
  variety: 'HD-2967',
  sowingDate: DateTime(2026, 6, 1),
  landArea: 2,
  landAreaUnit: LandAreaUnit.acre,
  growthStage: GrowthStage.vegetative,
  irrigationType: IrrigationType.manual,
);

CropTask _task() => CropTask(
  id: 'task-1',
  cropId: 'crop-1',
  type: CropTaskReminderType.irrigation,
  dueDate: DateTime(2026, 8, 14, 15, 30),
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

void main() {
  group('AppDateFormat', () {
    for (final code in _shippedLocales) {
      test('formats a time for "$code" without throwing', () {
        expect(
          AppDateFormat.time(code).format(DateTime(2026, 8, 14, 15, 30)),
          isNotEmpty,
        );
      });

      test('formats a date pattern for "$code" without throwing', () {
        expect(
          AppDateFormat.pattern(
            'dd MMM yyyy',
            code,
          ).format(DateTime(2026, 8, 14)),
          isNotEmpty,
        );
      });
    }

    test('falls back rather than throwing for an unknown language code', () {
      expect(
        AppDateFormat.time('zz').format(DateTime(2026, 8, 14, 15, 30)),
        isNotEmpty,
      );
    });

    test('still localizes where intl has symbols', () async {
      // Everything above holds with no date symbols loaded at all, which is
      // the state a background isolate can start in. This one asserts the
      // other half: once main() has run initializeDateFormatting, the fallback
      // must not have quietly cost correct output for locales that do work.
      // Bengali digits prove the requested locale is still honoured.
      await initializeDateFormatting();
      expect(
        AppDateFormat.time('bn').format(DateTime(2026, 8, 14, 15, 30)),
        contains('৩'),
      );
      // And the unsupported locales still fall back rather than throw.
      expect(
        AppDateFormat.time('brx').format(DateTime(2026, 8, 14, 15, 30)),
        isNotEmpty,
      );
    });
  });

  group('crop task reminder content', () {
    // Called with no BuildContext, exactly as the controller calls it, so this
    // cannot pass by accident on a delegate having loaded symbols first.
    for (final code in _shippedLocales) {
      test('builds in "$code" without throwing', () {
        final content = buildCropTaskNotificationContent(
          crop: _crop(),
          task: _task(),
          languageCode: code,
        );
        expect(content.title, isNotEmpty);
        expect(content.body, isNotEmpty);
      });
    }
  });
}
