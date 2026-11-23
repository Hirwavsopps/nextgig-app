import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/core/storage/cv_uploader.dart';
import 'package:nextgig/features/profile/data/profile_repository.dart';
import 'package:nextgig/features/profile/presentation/cubit/cv_cubit.dart';

class _FakeUploader implements CvUploader {
  bool deleteFails = false;
  final deleted = <String>[];

  @override
  Future<PlatformFile?> pick() async => null; // the user cancelled

  @override
  Future<void> delete(String uid) async {
    if (deleteFails) throw StateError('object-not-found');
    deleted.add(uid);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfiles implements ProfileRepository {
  final saved = <Map<String, String>>[];

  @override
  Future<void> setCv({
    required String uid,
    required String cvUrl,
    required String cvName,
  }) async => saved.add({'uid': uid, 'cvUrl': cvUrl, 'cvName': cvName});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeUploader uploader;
  late _FakeProfiles profiles;
  late CvCubit cubit;

  setUp(() {
    uploader = _FakeUploader();
    profiles = _FakeProfiles();
    cubit = CvCubit(uploader, profiles);
  });

  tearDown(() => cubit.close());

  test('cancelling the file picker changes nothing', () async {
    await cubit.upload('alice');

    expect(profiles.saved, isEmpty);
    expect(cubit.state, const CvState());
  });

  test('remove clears the CV link and deletes the file', () async {
    await cubit.remove('alice');

    expect(profiles.saved.single, {'uid': 'alice', 'cvUrl': '', 'cvName': ''});
    expect(uploader.deleted, ['alice']);
    expect(cubit.state.message, 'CV removed.');
    expect(cubit.state.isBusy, isFalse);
  });

  test('remove still succeeds when the file is already gone', () async {
    uploader.deleteFails = true;

    await cubit.remove('alice');

    expect(profiles.saved, hasLength(1));
    expect(cubit.state.message, 'CV removed.');
  });
}
