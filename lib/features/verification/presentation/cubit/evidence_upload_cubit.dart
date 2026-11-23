import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';

enum UploadPhase { editing, uploading, success, failure }

class EvidenceUploadState extends Equatable {
  const EvidenceUploadState({
    this.file,
    this.evidenceType = EvidenceType.professionalCertificate,
    this.phase = UploadPhase.editing,
    this.progress = 0,
    this.fileError,
    this.error,
    this.requestId,
  });

  final EvidenceFile? file;
  final EvidenceType evidenceType;
  final UploadPhase phase;

  /// 0 to 1 while uploading.
  final double progress;

  /// Problem with the picked file, shown under the picker.
  final String? fileError;

  /// Problem with the submission, shown as a SnackBar.
  final String? error;
  final String? requestId;

  bool get busy => phase == UploadPhase.uploading;
  bool get canSubmit => file != null && fileError == null && !busy;

  EvidenceUploadState copyWith({
    EvidenceFile? file,
    EvidenceType? evidenceType,
    UploadPhase? phase,
    double? progress,
    String? fileError,
    bool clearFileError = false,
    String? error,
    String? requestId,
  }) => EvidenceUploadState(
    file: file ?? this.file,
    evidenceType: evidenceType ?? this.evidenceType,
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    fileError: clearFileError ? null : fileError ?? this.fileError,
    error: error,
    requestId: requestId ?? this.requestId,
  );

  @override
  List<Object?> get props => [
    file,
    evidenceType,
    phase,
    progress,
    fileError,
    error,
    requestId,
  ];
}

class EvidenceUploadCubit extends Cubit<EvidenceUploadState> {
  EvidenceUploadCubit(this._repo, this._submit)
    : super(const EvidenceUploadState());

  final VerificationRepository _repo;
  final SubmitSkillEvidence _submit;

  Future<void> pickFile() async {
    if (state.busy) return;
    try {
      final file = await _repo.pickEvidence();
      if (file == null) return; // cancelled
      final problem = EvidencePolicy.validate(file);
      emit(
        state.copyWith(
          file: file,
          phase: UploadPhase.editing,
          fileError: problem,
          clearFileError: problem == null,
        ),
      );
    } on VerificationException catch (error) {
      emit(state.copyWith(error: error.message));
    } catch (_) {
      emit(state.copyWith(error: 'Could not open the file picker.'));
    }
  }

  void setType(EvidenceType type) => emit(state.copyWith(evidenceType: type));

  Future<void> submit({
    required String userId,
    required String userName,
    required Skill skill,
    required String note,
  }) async {
    if (state.busy) return;
    emit(state.copyWith(phase: UploadPhase.uploading, progress: 0));
    try {
      final id = await _submit(
        userId: userId,
        userName: userName,
        skill: skill,
        file: state.file,
        evidenceType: state.evidenceType,
        note: note,
        onProgress: (value) {
          if (!isClosed) emit(state.copyWith(progress: value));
        },
      );
      emit(
        state.copyWith(phase: UploadPhase.success, progress: 1, requestId: id),
      );
    } on VerificationException catch (error) {
      emit(state.copyWith(phase: UploadPhase.failure, error: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          phase: UploadPhase.failure,
          error: 'Upload failed. Check your connection and try again.',
        ),
      );
    }
  }
}
