import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addFavoriteStock(String symbol, String category) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(symbol)
        .set({'category': category});
  }

  Stream<Map<String, List<String>>> getCategorizedFavorites() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          final Map<String, List<String>> categorized = {};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final symbol = doc.id;
            final category = data['category'] ?? 'Other';
            categorized.putIfAbsent(category, () => []).add(symbol);
          }
          return categorized;
        });
  }
}
