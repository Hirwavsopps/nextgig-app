import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/storage/cv_uploader.dart';
import 'package:nextgig/features/profile/data/profile_repository.dart';

class CvState extends Equatable {
  const CvState({this.isBusy = false, this.message});

  /// True while picking, uploading or removing.
  final bool isBusy;

  /// One-shot SnackBar text.
  final String? message;

  @override
  List<Object?> get props => [isBusy, message];
}

/// Uploads, replaces and removes the signed-in user's CV. The CV link itself
/// is read from the live profile in ProfileCubit.
class CvCubit extends Cubit<CvState> {
  CvCubit(this._uploader, this._profiles) : super(const CvState());

  final CvUploader _uploader;
  final ProfileRepository _profiles;

  /// CREATE or UPDATE: pick a PDF and upload it.
  Future<void> upload(String uid) async {
    if (state.isBusy) return;
    emit(const CvState(isBusy: true));
    try {
      final file = await _uploader.pick();
      if (file == null) {
        emit(const CvState());
        return;
      }
      final url = await _uploader.upload(uid: uid, file: file);
      await _profiles.setCv(uid: uid, cvUrl: url, cvName: file.name);
      emit(const CvState(message: 'CV uploaded.'));
    } on StateError catch (error) {
      emit(CvState(message: error.message));
    } catch (_) {
      emit(const CvState(message: 'Could not upload your CV. Try again.'));
    }
  }

  /// DELETE: remove the file and the link on the profile.
  Future<void> remove(String uid) async {
    if (state.isBusy) return;
    emit(const CvState(isBusy: true));
    try {
      await _profiles.setCv(uid: uid, cvUrl: '', cvName: '');
      try {
        await _uploader.delete(uid);
      } catch (_) {
        // The link is already gone; a missing file is fine.
      }
      emit(const CvState(message: 'CV removed.'));
    } catch (_) {
      emit(const CvState(message: 'Could not remove your CV. Try again.'));
    }
  }
}
