// File: swim_apps_shared/lib/helpers/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/helpers/base_repository.dart';
import 'package:swim_apps_shared/helpers/analyzes_repository.dart';
import 'package:swim_apps_shared/helpers/user_repository.dart';

class FirestoreHelper {
  final FirebaseFirestore _db;

  // --- Shared Repositories ---
  // These are available to all apps that use this package.
  late final UserRepository userRepository;
  late final AnalyzesRepository raceRepository;

  // A private map to hold any app-specific repositories.
  final Map<Type, BaseRepository> _injectedRepositories = {};

  FirestoreHelper({required FirebaseFirestore firestore}) : _db = firestore {
    // Initialize all shared repositories
    userRepository = UserRepository(_db);
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