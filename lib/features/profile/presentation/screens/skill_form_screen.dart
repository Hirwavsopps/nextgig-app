import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/storage/proof_uploader.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/core/widgets/cloudinary_image_field.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';

class SkillFormScreen extends StatefulWidget {
  const SkillFormScreen({super.key, required this.uid, this.skill});

  final String uid;
  final Skill? skill;

  @override
  State<SkillFormScreen> createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends State<SkillFormScreen> {
  late final _name = TextEditingController(text: widget.skill?.name ?? '');
  late String _proficiency = widget.skill?.proficiency ?? 'beginner';
  late final List<_PortfolioDraft> _portfolio = [
    for (final item in widget.skill?.portfolio ?? const <PortfolioItem>[])
      _PortfolioDraft(item),
  ];
  late final String? _proofUrl = widget.skill?.proofUrl;
  late final String? _proofPath = widget.skill?.proofStoragePath;
  PlatformFile? _pendingProof;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    for (final item in _portfolio) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill == null ? 'Add skill' : 'Edit skill'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: _name, label: 'Skill name'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _proficiency,
            decoration: const InputDecoration(
              labelText: 'Proficiency',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final level in Skill.proficiencies)
                DropdownMenuItem(value: level, child: Text(level)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _proficiency = value);
            },
          ),
          const SizedBox(height: 16),
          Text('Portfolio', style: Theme.of(context).textTheme.titleMedium),
          for (final item in _portfolio) ...[
            const SizedBox(height: 8),
            AppTextField(controller: item.title, label: 'Title'),
            const SizedBox(height: 8),
            AppTextField(controller: item.link, label: 'Link'),
            const SizedBox(height: 8),
            CloudinaryImageField(
              imageUrl: item.imageUrl,
              label: 'Portfolio image',
              onUploaded: (url) => setState(() => item.imageUrl = url),
            ),
          ],
          TextButton(
            onPressed: () => setState(
              () => _portfolio.add(
                _PortfolioDraft(const PortfolioItem(title: '')),
              ),
            ),
            child: const Text('Add portfolio item'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickProof,
            child: Text(
              _pendingProof?.name ??
                  (_proofUrl == null
                      ? 'Upload certificate or proof'
                      : 'Proof attached'),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Save', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _pickProof() async {
    final file = await sl<ProofUploader>().pick();
    if (file == null) return;
    setState(() => _pendingProof = file);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppMessage(context, 'Skill name is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final cubit = context.read<ProfileCubit>();
      var skill = Skill(
        id: widget.skill?.id ?? '',
        name: _name.text,
        proficiency: _proficiency,
        portfolio: [for (final item in _portfolio) item.toItem()],
        proofUrl: _proofUrl,
        proofStoragePath: _proofPath,
        verified: widget.skill?.verified ?? false,
      );
      final id = await cubit.saveSkill(widget.uid, skill);
      final proof = _pendingProof;
      if (proof != null) {
        final uploaded = await sl<ProofUploader>().upload(
          uid: widget.uid,
          skillId: id,
          file: proof,
        );
        skill = Skill(
          id: id,
          name: skill.name,
          proficiency: skill.proficiency,
          portfolio: skill.portfolio,
          proofUrl: uploaded.url,
          proofStoragePath: uploaded.path,
          verified: skill.verified,
        );
        await cubit.saveSkill(widget.uid, skill);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not save the skill.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PortfolioDraft {
  _PortfolioDraft(PortfolioItem item)
    : title = TextEditingController(text: item.title),
      link = TextEditingController(text: item.link),
      imageUrl = item.imageUrl;

  final TextEditingController title;
  final TextEditingController link;
  String imageUrl;

  PortfolioItem toItem() =>
      PortfolioItem(title: title.text, link: link.text, imageUrl: imageUrl);

  void dispose() {
    title.dispose();
    link.dispose();
  }
}
