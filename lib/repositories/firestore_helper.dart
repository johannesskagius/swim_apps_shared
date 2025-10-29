// File: swim_apps_shared/lib/repositories/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// Removed: The import for Firebase Crashlytics is no longer needed.
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swim_apps_shared/repositories/user_repository.dart';

import '../auth_service.dart';
import 'analyzes_repository.dart';
import 'base_repository.dart';

class FirestoreHelper {
  final FirebaseFirestore _db;
  final AuthService _authService;

  // A private map to hold all registered repositories.
  final Map<Type, BaseRepository> _repositories = {};

  // --- Shared Repositories (accessed via public getters) ---

  /// Provides access to the user-related data repository.
  /// Throws an exception if the UserRepository has not been registered.
  UserRepository get userRepository => get<UserRepository>();

  /// Provides access to the analysis data repository.
  /// Throws an exception if the AnalyzesRepository has not been registered.
  AnalyzesRepository get raceRepository => get<AnalyzesRepository>();

  FirestoreHelper({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _db = firestore,
        _authService = authService {
    // This pattern provides a consistent way to set up all repositories.
    _registerSharedRepositories();
  }

  /// Initializes and registers all standard shared repositories.
  /// This keeps the constructor clean and centralizes repository setup.
  void _registerSharedRepositories() {
    registerRepository(UserRepository(_db, authService: _authService));
    registerRepository(AnalyzesRepository(_db));
  }

  /// Registers an app-specific repository. This should be called during app
  /// initialization (e.g., in main.dart) for any repositories not included
  /// in the shared package.
  void registerRepository<T extends BaseRepository>(T repository) {
    _repositories[T] = repository;
  }

  /// Retrieves a registered repository instance by its type.
  ///
  /// This method includes robust error handling to detect configuration issues
  /// during development.
  T get<T extends BaseRepository>() {
    final repo = _repositories[T];
    if (repo == null) {
      // --- Error Handling Improvement ---
      // A detailed ArgumentError is thrown if a repository is not found.
      // This provides clear, actionable feedback to the developer.
      // All calls to FirebaseCrashlytics have been removed.
      final error = ArgumentError(
        'Repository of type $T was not registered. '
            'Ensure registerRepository() is called during app initialization.',
      );

      // Throwing a specific error type makes it easier for developers to
      // debug setup and dependency injection problems.
      throw error;
    }

    // The cast is safe due to the check above and the generic constraint.
    return repo as T;
  }
}
