import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/core/widgets/cloudinary_image_field.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late String _photoUrl = widget.profile.photoUrl;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CloudinaryImageField(
            imageUrl: _photoUrl,
            label: 'Profile photo',
            onUploaded: (url) => setState(() => _photoUrl = url),
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _name, label: 'Name'),
          const SizedBox(height: 12),
          AppTextField(controller: _bio, label: 'Bio', maxLines: 3),
          const SizedBox(height: 16),
          AppButton(label: 'Save', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppMessage(context, 'Name is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ProfileCubit>().saveProfile(
        uid: widget.profile.uid,
        name: _name.text,
        bio: _bio.text,
        photoUrl: _photoUrl,
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not save your profile.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
