import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProofUploader {
  ProofUploader(this._storage);

  final FirebaseStorage _storage;

  Future<PlatformFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (files.isEmpty) return null;
    return files.single;
  }

  Future<({String url, String path})> upload({
    required String uid,
    required String skillId,
    required PlatformFile file,
  }) async {
    final path = 'proofs/$uid/$skillId/${file.name}';
    final ref = _storage.ref(path);
    final localPath = file.path;
    if (localPath == null) {
      throw StateError('Could not read the selected file.');
    }
    await ref.putFile(File(localPath));
    final url = await ref.getDownloadURL();
    return (url: url, path: path);
  }
}
