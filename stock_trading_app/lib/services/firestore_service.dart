import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addFavoriteStock(String symbol) async {
    final docRef = _firestore.collection('users').doc(_userId);
    await docRef.set({
      'favorites': FieldValue.arrayUnion([symbol]),
    }, SetOptions(merge: true));
  }

  Stream<List<String>> getFavoriteStocks() {
    return _firestore.collection('users').doc(_userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || !data.containsKey('favorites')) return [];
      return List<String>.from(data['favorites']);
    });
  }
}
