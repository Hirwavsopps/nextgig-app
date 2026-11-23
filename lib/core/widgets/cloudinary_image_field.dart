import 'package:flutter/material.dart';
import 'package:nextgig/core/cloudinary/cloudinary_uploader.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/utils/messenger.dart';

/// Picks a gallery image, uploads it, and reports the Cloudinary URL.
class CloudinaryImageField extends StatefulWidget {
  const CloudinaryImageField({
    super.key,
    required this.imageUrl,
    required this.onUploaded,
    this.label = 'Photo',
  });

  final String imageUrl;
  final ValueChanged<String> onUploaded;
  final String label;

  @override
  State<CloudinaryImageField> createState() => _CloudinaryImageFieldState();
}

class _CloudinaryImageFieldState extends State<CloudinaryImageField> {
  var _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final uploader = sl<CloudinaryUploader>();
      final file = await uploader.pick();
      if (file == null || !mounted) return;
      final url = await uploader.upload(file);
      if (!mounted) return;
      widget.onUploaded(url);
    } on CloudinaryNotConfigured catch (error) {
      if (mounted) showAppMessage(context, error.toString());
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not upload the image.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: url.isEmpty ? null : NetworkImage(url),
          child: url.isEmpty ? const Icon(Icons.image_outlined) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : _pick,
            child: Text(_busy ? 'Uploading…' : widget.label),
          ),
        ),
      ],
    );
  }
}
