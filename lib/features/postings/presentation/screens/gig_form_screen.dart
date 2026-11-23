import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/cloudinary_image_field.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class GigFormScreen extends StatefulWidget {
  const GigFormScreen({super.key, this.gig});

  final Gig? gig;

  @override
  State<GigFormScreen> createState() => _GigFormScreenState();
}

class _GigFormScreenState extends State<GigFormScreen> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _formKey = GlobalKey<FormState>();

  late final _title = TextEditingController(text: widget.gig?.title ?? '');
  late final _description = TextEditingController(
    text: widget.gig?.description ?? '',
  );
  late final _skills = TextEditingController(
    text: widget.gig?.requiredSkills.join(', ') ?? '',
  );
  late final _pay = TextEditingController(
    text: widget.gig == null ? '' : widget.gig!.pay.toString(),
  );
  late String _category =
      widget.gig?.category ?? AppConstants.gigCategories.first;
  late String _neighborhood =
      widget.gig?.neighborhood ?? AppConstants.neighborhoods.first;
  late DateTime? _deadline = widget.gig?.deadline;
  late String _imageUrl = widget.gig?.imageUrl ?? '';
  var _saving = false;

  bool get _isEditing => widget.gig != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _skills.dispose();
    _pay.dispose();
    super.dispose();
  }

  List<String> _parseSkills(String raw) => raw
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? prefixText,
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: scheme.surface,
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit gig' : 'Post a gig')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: AppButton(
            label: _isEditing ? 'Save changes' : 'Publish gig',
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              _isEditing ? 'Update the details talent will see.' : 'Tell talent what you need. A clear gig gets better applicants.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Basics',
              icon: Icons.edit_note,
              children: [
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: _decoration(
                    context,
                    label: 'Title',
                    hint: 'e.g. Build a landing page',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Give your gig a title'
                      : null,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _description,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 600,
                  decoration: _decoration(
                    context,
                    label: 'Description',
                    hint: 'What needs to be done, and what does success look like?',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Category and location',
              icon: Icons.place_outlined,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: _decoration(context, label: 'Category'),
                  items: [
                    for (final category in AppConstants.gigCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _neighborhood,
                  isExpanded: true,
                  decoration: _decoration(context, label: 'Neighborhood'),
                  items: [
                    for (final neighborhood in AppConstants.neighborhoods)
                      DropdownMenuItem(
                        value: neighborhood,
                        child: Text(neighborhood),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _neighborhood = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Skills and pay',
              icon: Icons.payments_outlined,
              children: [
                TextFormField(
                  controller: _skills,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    context,
                    label: 'Required skills',
                    hint: 'Flutter, Firebase',
                  ).copyWith(helperText: 'Separate skills with commas'),
                  validator: (v) => _parseSkills(v ?? '').isEmpty
                      ? 'Add at least one skill'
                      : null,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _skills,
                  builder: (context, value, _) {
                    final skills = _parseSkills(value.text);
                    if (skills.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final skill in skills)
                            Chip(
                              label: Text(skill),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pay,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(
                    context,
                    label: 'Pay',
                    prefixText: 'RWF  ',
                  ),
                  validator: (v) {
                    final pay = int.tryParse((v ?? '').trim());
                    if (pay == null || pay <= 0) {
                      return 'Enter an amount greater than 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Deadline and cover',
              icon: Icons.event_outlined,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: _decoration(
                      context,
                      label: 'Deadline',
                      icon: Icons.calendar_today_outlined,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _deadline == null
                                ? 'No deadline'
                                : _formatDate(_deadline!),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _deadline == null
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                        if (_deadline != null)
                          GestureDetector(
                            onTap: () => setState(() => _deadline = null),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                CloudinaryImageField(
                  imageUrl: _imageUrl,
                  label: 'Cover photo',
                  onUploaded: (url) => setState(() => _imageUrl = url),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      showAppMessage(context, 'Please fix the highlighted fields.');
      return;
    }
    final pay = int.parse(_pay.text.trim());
    final skills = _parseSkills(_skills.text);
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final gig = Gig(
      id: widget.gig?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      neighborhood: _neighborhood,
      pay: pay,
      requiredSkills: skills,
      posterName: user.name.isEmpty ? 'NextGig user' : user.name,
      posterId: user.uid,
      duration: widget.gig?.duration ?? '',
      level: widget.gig?.level ?? '',
      applicantCount: widget.gig?.applicantCount ?? 0,
      verifiedClient: widget.gig?.verifiedClient ?? false,
      escrowFunded: widget.gig?.escrowFunded ?? false,
      deliverables: widget.gig?.deliverables ?? const [],
      mentorName: widget.gig?.mentorName,
      mentorId: widget.gig?.mentorId,
      imageUrl: _imageUrl.isEmpty ? null : _imageUrl,
      createdAt: widget.gig?.createdAt,
      deadline: _deadline,
    );
    setState(() => _saving = true);
    try {
      await _persist(gig);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not save the gig.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist(Gig gig) {
    final repository = sl<GigRepository>();
    if (gig.id.isEmpty) return repository.createGig(gig);
    return repository.updateGig(gig);
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.onPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
