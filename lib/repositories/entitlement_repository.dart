import 'package:cloud_firestore/cloud_firestore.dart';

class EntitlementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Cached map: product -> planId -> data
  final Map<String, Map<String, Map<String, dynamic>>> _cache = {};

  /// Load all plans for a product (club, analyzer, etc)
  Future<Map<String, Map<String, dynamic>>> getPlans(String product) async {
    if (_cache.containsKey(product)) return _cache[product]!;

    final snapshot = await _db
        .collection('entitlements')
        .doc(product)
        .collection('plans')
        .get();

    final plans = {
      for (var doc in snapshot.docs) doc.id: doc.data(),
    };

    _cache[product] = plans;
    return plans;
  }

  /// Get one plan
  Future<Map<String, dynamic>?> getPlan(
      String product,
      String planId,
      ) async {
    final plans = await getPlans(product);
    return plans[planId];
  }

  /// Listen to updates (future-proofing if RC updates automatically)
  Stream<Map<String, dynamic>?> watchPlan(
      String product,
      String planId,
      ) {
    return _db
        .collection('entitlements')
        .doc(product)
        .collection('plans')
        .doc(planId)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Clear cache (if user logs out / refresh)
  void clearCache() {
    _cache.clear();
  }
}
