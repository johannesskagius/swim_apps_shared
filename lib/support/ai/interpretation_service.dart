import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AIInterpretationService {
  final _functions = FirebaseFunctions.instance;

  Future<String?> interpretRace({required Map<String, dynamic> json}) async {
    try {
      final callable = _functions.httpsCallable('interpretAnalysis');

      final response = await callable.call({'type': 'race', 'data': json});

      if (response.data == null) return null;

      if (response.data['success'] == true) {
        return response.data['interpretation'];
      }

      return null;
    } catch (e) {
      debugPrint("🔥 error requesting interpretation: $e");
      return null;
    }
  }
}
