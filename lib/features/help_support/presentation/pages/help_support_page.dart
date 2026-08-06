import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/help_support/data/repositories/image_picker_support_attachment_repository.dart';
import 'package:krishi_sech/features/help_support/data/repositories/local_help_support_repository.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/help_support_repository.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/support_attachment_repository.dart';
import 'package:krishi_sech/features/help_support/presentation/controllers/help_support_controller.dart';
import 'package:krishi_sech/features/help_support/presentation/help_support_config.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({
    super.key,
    this.repository,
    this.attachmentRepository,
  });

  final HelpSupportRepository? repository;
  final SupportAttachmentRepository? attachmentRepository;

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  HelpSupportController? _controller;
  late final SupportAttachmentRepository _attachmentRepository;
  String? _screenshotPath;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _attachmentRepository =
        widget.attachmentRepository ?? ImagePickerSupportAttachmentRepository();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final repository =
          widget.repository ?? await LocalHelpSupportRepository.create();
      if (!mounted) return;
      final controller = HelpSupportController(repository)
        ..addListener(_onControllerChanged);
      setState(() => _controller = controller);
      await controller.load();
    } catch (error) {
      if (mounted) setState(() => _initializationError = error);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpSupport)),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initializationError != null) {
      return _CenteredState(
        icon: Icons.support_agent_outlined,
        message: context.l10n.helpSupportLoadError,
        actionLabel: context.l10n.retry,
        onAction: () {
          setState(() => _initializationError = null);
          _initialize();
        },
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      key: const Key('help_support_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        ResponsiveContent(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                icon: Icons.quiz_outlined,
                title: context.l10n.frequentlyAskedQuestions,
              ),
              const SizedBox(height: 8),
              _FaqTile(
                index: 0,
                question: context.l10n.faqLanguageQuestion,
                answer: context.l10n.faqLanguageAnswer,
              ),
              _FaqTile(
                index: 1,
                question: context.l10n.faqCropQuestion,
                answer: context.l10n.faqCropAnswer,
              ),
              _FaqTile(
                index: 2,
                question: context.l10n.faqOfflineQuestion,
                answer: context.l10n.faqOfflineAnswer,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.contact_support_outlined,
                title: context.l10n.contactSupport,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.email_outlined,
                        label: context.l10n.supportEmail,
                        value: HelpSupportConfig.supportEmail,
                      ),
                      const Divider(height: 24),
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        label: context.l10n.supportPhone,
                        value: HelpSupportConfig.supportPhone,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.supportContactPlaceholderNotice,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.bug_report_outlined,
                title: context.l10n.reportAProblem,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('support_report_subject'),
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: context.l10n.reportSubject,
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? context.l10n.reportSubjectRequired
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('support_report_description'),
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 7,
                          decoration: InputDecoration(
                            labelText: context.l10n.reportDescription,
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? context.l10n.reportDescriptionRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('support_attach_screenshot'),
                          onPressed: controller.isSubmitting
                              ? null
                              : _chooseScreenshot,
                          icon: Icon(
                            _screenshotPath == null
                                ? Icons.add_photo_alternate_outlined
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            _screenshotPath == null
                                ? context.l10n.attachScreenshotOptional
                                : context.l10n.screenshotAttached,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const Key('support_report_submit'),
                          onPressed: controller.isSubmitting
                              ? null
                              : _submitReport,
                          icon: controller.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(context.l10n.submitReport),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildReportState(controller),
              const SizedBox(height: 24),
              _PolicyTile(
                key: const Key('privacy_policy_section'),
                icon: Icons.privacy_tip_outlined,
                title: context.l10n.privacyPolicy,
                body: context.l10n.privacyPolicySummary,
              ),
              _PolicyTile(
                key: const Key('terms_conditions_section'),
                icon: Icons.description_outlined,
                title: context.l10n.termsAndConditions,
                body: context.l10n.termsConditionsSummary,
              ),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(context.l10n.appVersion),
                  subtitle: const Text(HelpSupportConfig.appVersion),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportState(HelpSupportController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return _CenteredState(
        icon: Icons.error_outline,
        message: context.l10n.supportReportsLoadError,
        actionLabel: context.l10n.retry,
        onAction: controller.load,
      );
    }
    if (controller.reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          context.l10n.noSupportReports,
          key: const Key('support_reports_empty'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Text(
      context.l10n.supportReportsSaved(controller.reports.length),
      key: const Key('support_reports_success'),
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
    );
  }

  Future<void> _chooseScreenshot() async {
    try {
      final path = await _attachmentRepository.chooseScreenshot();
      if (mounted && path != null) setState(() => _screenshotPath = path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.screenshotSelectionFailed)),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = _controller;
    if (controller == null) return;
    final submitted = await controller.submit(
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotPath: _screenshotPath,
    );
    if (!mounted) return;
    if (!submitted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.reportSubmitError)));
      return;
    }
    _subjectController.clear();
    _descriptionController.clear();
    setState(() => _screenshotPath = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('support_report_success_notice'),
        content: Text(context.l10n.reportSubmittedSuccessfully),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.index,
    required this.question,
    required this.answer,
  });
  final int index;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: Key('support_faq_$index'),
      title: Text(question),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(answer, key: Key('support_faq_answer_$index')),
        ),
      ],
    ),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            SelectableText(value),
          ],
        ),
      ),
    ],
  );
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Text(body)],
    ),
  );
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
