import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/earnings/domain/entities/earning.dart';

class EarningsRepository {
  EarningsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _earnings(String uid) =>
      _firestore.collection('users').doc(uid).collection('earnings');

  Stream<List<Earning>> watch(String uid) {
    return _earnings(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final created = data['createdAt'];
            return Earning(
              id: doc.id,
              amount: (data['amount'] as num?)?.toInt() ?? 0,
              gigTitle: data['gigTitle'] as String? ?? '',
              gigId: data['gigId'] as String? ?? '',
              mobileMoneyRef: data['mobileMoneyRef'] as String? ?? '',
              createdAt: created is Timestamp ? created.toDate() : null,
            );
          }).toList(),
        );
  }

  Future<void> add({
    required String uid,
    required int amount,
    required String gigTitle,
    String gigId = '',
    String mobileMoneyRef = '',
  }) {
    return _earnings(uid).add({
      'amount': amount,
      'gigTitle': gigTitle.trim(),
      'gigId': gigId,
      'mobileMoneyRef': mobileMoneyRef.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
