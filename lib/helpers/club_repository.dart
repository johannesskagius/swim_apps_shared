import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../swim_apps_shared.dart' show SwimClub;

class ClubRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _clubsCollection;

  ClubRepository(this._firestore)
      : _clubsCollection = _firestore.collection('swimClubs');

  Future<String> addClub({required SwimClub club}) async {
    try {
      // Use toJson but exclude the ID since Firestore generates it.
      final data = club.toJson()..remove('id');
      DocumentReference docRef = await _clubsCollection.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding club to Firestore: $e');
      rethrow;
    }
  }

  /// Fetches a club's details from Firestore.
  Future<SwimClub?> getClub(String clubId) async {
    if (clubId.isEmpty) {
      debugPrint("Error: clubId cannot be empty.");
      return null;
    }
    try {
      final DocumentSnapshot<Object?> doc =
      await _clubsCollection.doc(clubId).get();
      if (doc.exists && doc.data() != null) {
        return SwimClub.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      } else {
        debugPrint("No club document found for ID: $clubId");
        return null;
      }
    } catch (e) {
      debugPrint("Error getting club $clubId: $e");
      return null; // Return null on error to prevent crashes.
    }
  }
}