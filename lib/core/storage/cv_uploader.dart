import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Picks a CV (PDF) and stores it in Firebase Storage at `cvs/{uid}/cv.pdf`.
///
/// Same approach as [ProofUploader], but one fixed file per user: uploading
/// again replaces the old CV instead of piling up copies.
class CvUploader {
  CvUploader(this._storage);

  final FirebaseStorage _storage;

  static const int maxBytes = 5 * 1024 * 1024;

  static String pathFor(String uid) => 'cvs/$uid/cv.pdf';

  Future<PlatformFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) return null;
    return files.single;
  }

  /// Uploads the file and returns its download URL.
  Future<String> upload({
    required String uid,
    required PlatformFile file,
  }) async {
    final localPath = file.path;
    if (localPath == null) {
      throw StateError('Could not read the selected file.');
    }
    final local = File(localPath);
    if (await local.length() > maxBytes) {
      throw StateError('The CV must be smaller than 5 MB.');
    }
    final ref = _storage.ref(pathFor(uid));
    await ref.putFile(local, SettableMetadata(contentType: 'application/pdf'));
    return ref.getDownloadURL();
  }

  Future<void> delete(String uid) => _storage.ref(pathFor(uid)).delete();
}
