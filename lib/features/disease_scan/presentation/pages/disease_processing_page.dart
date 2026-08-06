import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/entities/disease_scan_failure.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/disease_scan_repository_factory.dart';
import 'package:krishi_sech/features/disease_scan/domain/entities/disease_scan_state.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/disease_scan_repository.dart';
import 'package:krishi_sech/features/disease_scan/presentation/controllers/disease_scan_controller.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_result_page.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_scan_page.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class DiseaseProcessingPage extends StatefulWidget {
  const DiseaseProcessingPage({
    super.key,
    required this.arguments,
    this.repository,
  });

  final DiseaseScanImageArguments arguments;
  final DiseaseScanRepository? repository;

  @override
  State<DiseaseProcessingPage> createState() => _DiseaseProcessingPageState();
}

class _DiseaseProcessingPageState extends State<DiseaseProcessingPage> {
  DiseaseScanController? _controller;
  bool _started = false;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _controller = DiseaseScanController(widget.repository!)
        ..addListener(_handleState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _controller ??= DiseaseScanController(
      DiseaseScanRepositoryFactory.create(
        accessTokenProvider: ({bool forceRefresh = false}) =>
            AuthScope.of(context).getAccessToken(forceRefresh: forceRefresh),
      ),
    )..addListener(_handleState);
    _started = true;
    _scan();
  }

  Future<void> _scan() {
    final crop = widget.arguments.cropId == null
        ? null
        : CropScope.of(context).cropById(widget.arguments.cropId!);
    final location = LocationScope.of(context).location;
    final weather = WeatherScope.of(context).weather;
    return _controller!.scan(
      DiseaseScanRequest(
        imagePath: widget.arguments.imagePath,
        cropId: widget.arguments.cropId,
        cropName: widget.arguments.cropName,
        growthStage: crop?.growthStage.name,
        location: location?.displayName,
        weatherSummary: weather == null
            ? null
            : '${weather.temperatureCelsius.toStringAsFixed(1)}°C, '
                  'humidity ${weather.humidityPercent}%, '
                  'wind ${weather.windSpeedKmh.toStringAsFixed(1)} km/h, '
                  'rain ${weather.rainProbabilityPercent ?? 0}%',
        language: AppLanguageCatalog.serviceCodeFor(
          Localizations.localeOf(context).languageCode,
        ),
        notes: crop?.notes,
      ),
    );
  }

  void _handleState() {
    if (!mounted) return;
    final state = _controller!.state;
    final result = switch (state) {
      DiseaseScanSuccess(:final result) => result,
      DiseaseScanLowConfidence(:final result) => result,
      DiseaseScanExpertReview(:final result) => result,
      _ => null,
    };
    if (result == null || _completing) return;
    _completing = true;
    unawaited(_openResult(state, result));
  }

  Future<void> _openResult(
    DiseaseScanState state,
    DiseaseScanResult result,
  ) async {
    final cropId = widget.arguments.cropId;
    final now = DateTime.now();
    await CropHealthRecordScope.of(context).addRecord(
      CropHealthRecord(
        id: result.scanId,
        cropId: cropId ?? 'unassigned',
        type: CropHealthRecordType.scan,
        title: result.possibleDisease,
        details:
            '${result.cropName} • ${result.severity} • '
            '${(result.confidence * 100).round()}% • '
            '${result.visibleSymptoms.join('; ')} • '
            '${result.recommendedActions.join('; ')}',
        photoPath: widget.arguments.imagePath,
        occurredAt: result.createdAt,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[AI Vision] ✓ step=11 result screen opened');
    }
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.diseaseResult,
      arguments: DiseaseResultArguments(
        imagePath: widget.arguments.imagePath,
        cropId: cropId,
        result: result,
        isLowConfidence: state is DiseaseScanLowConfidence,
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_handleState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.processingImage)),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.arguments.imagePath),
              cacheWidth:
                  (MediaQuery.sizeOf(context).width *
                          MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.lightGreen),
            ),
            const ColoredBox(color: Color(0x99000000)),
            Center(
              child: ListenableBuilder(
                listenable: _controller!,
                builder: (context, _) => _ProcessingStateContent(
                  state: _controller!.state,
                  onRetry: _scan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStateContent extends StatelessWidget {
  const _ProcessingStateContent({required this.state, required this.onRetry});

  final DiseaseScanState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final currentState = state;
    if (currentState is DiseaseScanError) {
      return Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage(context, currentState.cause),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    final progress = currentState is DiseaseScanLoading
        ? currentState.uploadProgress
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 52,
          child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
        ),
        const SizedBox(height: 18),
        if (progress != null) ...[
          SizedBox(width: 220, child: LinearProgressIndicator(value: progress)),
          const SizedBox(height: 10),
          Text(
            context.l10n.uploadProgress((progress * 100).round()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          context.l10n.analyzingCrop,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _errorMessage(BuildContext context, Object cause) => switch (cause) {
    DiseaseScanOfflineFailure() => context.l10n.diseaseScanOffline,
    DiseaseScanTimeoutFailure(:final message) =>
      kDebugMode && message != null ? message : context.l10n.diseaseScanTimeout,
    DiseaseScanInvalidResponseFailure() =>
      context.l10n.diseaseScanInvalidResponse,
    DiseaseScanInvalidImageFailure(:final message) =>
      kDebugMode && message != null
          ? 'Invalid image: $message'
          : context.l10n.diseaseScanInvalidResponse,
    DiseaseScanAuthenticationFailure(:final message) =>
      kDebugMode && message != null
          ? 'Authentication failed: $message'
          : context.l10n.diseaseScanServerError,
    DiseaseScanQuotaFailure(:final message) =>
      kDebugMode && message != null
          ? 'OpenAI insufficient_quota: $message'
          : context.l10n.diseaseScanServerError,
    DiseaseScanServerFailure(:final statusCode, :final message) =>
      kDebugMode && message != null
          ? 'HTTP $statusCode: $message'
          : context.l10n.diseaseScanServerError,
    _ => context.l10n.analysisFailed,
  };
}
