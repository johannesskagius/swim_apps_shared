import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

class SwimmerFocusProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('swimmerFocusProfiles');

  Future<void> saveProfile(SwimmerFocusProfile profile) async {
    await _collection.doc(profile.id).set(profile.toJson(), SetOptions(merge: true));
  }

  Future<List<SwimmerFocusProfile>> getProfilesForCoach(String coachId) async {
    final snapshot = await _collection.where('coachId', isEqualTo: coachId).get();
    return snapshot.docs
        .map((doc) => SwimmerFocusProfile.fromJson(doc.data()))
        .toList();
  }

  Future<SwimmerFocusProfile?> getProfileForSwimmer(String swimmerId) async {
    final doc = await _collection.doc(swimmerId).get();
    if (!doc.exists) return null;
    return SwimmerFocusProfile.fromJson(doc.data()!);
  }

  Future<void> deleteProfile(String swimmerId) async {
    await _collection.doc(swimmerId).delete();
  }
}
