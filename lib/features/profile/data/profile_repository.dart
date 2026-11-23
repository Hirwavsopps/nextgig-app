import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _skills(String uid) =>
      _firestore.collection('users').doc(uid).collection('skills');

  Stream<UserProfile> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      return UserProfile(
        uid: uid,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        bio: data['bio'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? '',
        role: data['role'] as String? ?? '',
        location: data['location'] as String? ?? '',
        cvUrl: data['cvUrl'] as String? ?? '',
        cvName: data['cvName'] as String? ?? '',
      );
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
    required String photoUrl,
    String? location,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name.trim(),
      'bio': bio.trim(),
      'photoUrl': photoUrl.trim(),
      if (location != null) 'location': location.trim(),
    }, SetOptions(merge: true));
    if (_auth.currentUser?.uid == uid) {
      await _auth.currentUser?.updateDisplayName(name.trim());
    }
  }

  /// Saves (or, with empty values, clears) the CV link on the profile.
  Future<void> setCv({
    required String uid,
    required String cvUrl,
    required String cvName,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'cvUrl': cvUrl,
      'cvName': cvName,
    }, SetOptions(merge: true));
  }

  Stream<List<Skill>> watchSkills(String uid) {
    return _skills(uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_skillFromDoc).toList());
  }

  /// Creates or edits a skill. The verification fields are never sent from
  /// here: a new skill starts unverified, and an edit leaves them untouched
  /// (only a reviewer may change them, see firestore.rules).
  Future<String> saveSkill(String uid, Skill skill) async {
    final data = <String, dynamic>{
      'name': skill.name.trim(),
      'proficiency': skill.proficiency,
      'portfolio': [
        for (final item in skill.portfolio)
          if (item.title.trim().isNotEmpty)
            {
              'title': item.title.trim(),
              'imageUrl': item.imageUrl.trim(),
              'link': item.link.trim(),
            },
      ],
      'proofUrl': skill.proofUrl,
      'proofStoragePath': skill.proofStoragePath,
    };
    if (skill.id.isEmpty) {
      final ref = _skills(uid).doc();
      await ref.set({
        ...data,
        'verified': false,
        'verificationStatus': 'unverified',
      });
      return ref.id;
    }
    final ref = _skills(uid).doc(skill.id);
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteSkill(String uid, String skillId) =>
      _skills(uid).doc(skillId).delete();

  Skill _skillFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final portfolio = data['portfolio'] as List<dynamic>? ?? const [];
    final verifiedAt = data['verifiedAt'];
    return Skill(
      id: doc.id,
      name: data['name'] as String? ?? '',
      proficiency: data['proficiency'] as String? ?? 'beginner',
      portfolio: [
        for (final raw in portfolio)
          if (raw is Map)
            PortfolioItem(
              title: raw['title'] as String? ?? '',
              imageUrl: raw['imageUrl'] as String? ?? '',
              link: raw['link'] as String? ?? '',
            ),
      ],
      proofUrl: data['proofUrl'] as String?,
      proofStoragePath: data['proofStoragePath'] as String?,
      verified: data['verified'] as bool? ?? false,
      verificationStatus: data['verificationStatus'] as String?,
      verificationId: data['verificationId'] as String?,
      verifiedAt: verifiedAt is Timestamp ? verifiedAt.toDate() : null,
      verifiedById: data['verifiedById'] as String?,
      verifiedByName: data['verifiedByName'] as String? ?? '',
      verifiedByRelationship: data['verifiedByRelationship'] as String? ?? '',
    );
  }
}
