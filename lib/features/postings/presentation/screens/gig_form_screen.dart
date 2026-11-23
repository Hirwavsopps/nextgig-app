import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/core/widgets/cloudinary_image_field.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GigFormScreen extends StatefulWidget {
  const GigFormScreen({super.key, this.gig});

  final Gig? gig;

  @override
  State<GigFormScreen> createState() => _GigFormScreenState();
}

class _GigFormScreenState extends State<GigFormScreen> {
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

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _skills.dispose();
    _pay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gig == null ? 'New gig' : 'Edit gig')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: _title, label: 'Title'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _description,
            label: 'Description',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _skills,
            label: 'Required skills',
            hint: 'Flutter, Firebase',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _pay,
            label: 'Pay (RWF)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final category in AppConstants.gigCategories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _neighborhood,
            decoration: const InputDecoration(
              labelText: 'Neighborhood',
              border: OutlineInputBorder(),
            ),
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
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deadline'),
            subtitle: Text(
              _deadline == null
                  ? 'None'
                  : '${_deadline!.year}-${_deadline!.month}-${_deadline!.day}',
            ),
            trailing: IconButton(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
            ),
          ),
          CloudinaryImageField(
            imageUrl: _imageUrl,
            label: 'Cover photo',
            onUploaded: (url) => setState(() => _imageUrl = url),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Save', isLoading: _saving, onPressed: _save),
        ],
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
    final pay = int.tryParse(_pay.text.trim());
    final skills = _skills.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
    if (_title.text.trim().isEmpty ||
        pay == null ||
        pay <= 0 ||
        skills.isEmpty) {
      showAppMessage(
        context,
        'Title, pay, and at least one skill are required.',
      );
      return;
    }
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
