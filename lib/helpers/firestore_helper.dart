// File: swim_apps_shared/lib/helpers/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/helpers/analyzes_repository.dart';
import 'package:swim_apps_shared/helpers/base_repository.dart';
import 'package:swim_apps_shared/helpers/user_repository.dart';

import '../auth_service.dart';

class FirestoreHelper {
  final FirebaseFirestore _db;
  final AuthService _authService;

  // --- Shared Repositories ---
  late final UserRepository userRepository;
  late final AnalyzesRepository raceRepository;

  // A private map to hold any app-specific repositories.
  final Map<Type, BaseRepository> _injectedRepositories = {};

  FirestoreHelper({
    required FirebaseFirestore firestore,
    required AuthService authService,
  }) : _db = firestore,
       _authService = authService {
    userRepository = UserRepository(_db, authService: _authService);

    // The other repositories that don't need auth are fine.
    raceRepository = AnalyzesRepository(_db);
  }

  /// Call this from main.dart to register an app-specific repository.
  void registerRepository<T extends BaseRepository>(T repository) {
    _injectedRepositories[T] = repository;
  }

  /// Use this within your app to get an instance of an injected repository.
  T get<T extends BaseRepository>() {
    final repo = _injectedRepositories[T];
    if (repo == null) {
      throw Exception(
        'Repository of type $T was not registered. '
        'Make sure to call registerRepository() in your main.dart setup.',
      );
    }
    return repo as T;
  }
}
