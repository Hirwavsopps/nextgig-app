import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';

class MentorRepository {
  MentorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<UserProfile>> watchMentors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return UserProfile(
              uid: doc.id,
              name: data['name'] as String? ?? '',
              email: data['email'] as String? ?? '',
              bio: data['bio'] as String? ?? '',
              photoUrl: data['photoUrl'] as String? ?? '',
              role: data['role'] as String? ?? '',
            );
          }).toList(),
        );
  }
}
