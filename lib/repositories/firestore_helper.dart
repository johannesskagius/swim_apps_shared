// File: swim_apps_shared/lib/repositories/firestore_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swim_apps_shared/repositories/user_repository.dart';

import '../auth_service.dart';
import 'analyzes_repository.dart';
import 'base_repository.dart';

class FirestoreHelper {
  final FirebaseFirestore _db;
  final AuthService _authService;

  // A private map to hold all registered repositories, including shared ones.
  // This simplifies repository management by using a single mechanism.
  final Map<Type, BaseRepository> _repositories = {};

  // --- Shared Repositories (accessed via public getters) ---

  /// Provides access to the user-related data repository.
  /// Throws an exception if the UserRepository has not been registered.
  UserRepository get userRepository => get<UserRepository>();

  /// Provides access to the race analysis data repository.
  /// Throws an exception if the AnalyzesRepository has not been registered.
  AnalyzesRepository get raceRepository => get<AnalyzesRepository>();

  FirestoreHelper({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _db = firestore,
        _authService = authService {
    // Instead of hard-coding instantiation, we now call the same registration
    // method used for app-specific repositories. This creates a single,
    // consistent pattern for repository management.
    _registerSharedRepositories();
  }

  /// Initializes and registers all standard shared repositories.
  /// This keeps the constructor clean and centralizes repository setup.
  void _registerSharedRepositories() {
    registerRepository(UserRepository(_db, authService: _authService));
    registerRepository(AnalyzesRepository(_db));
  }

  /// Call this from main.dart to register an app-specific repository.
  void registerRepository<T extends BaseRepository>(T repository) {
    _repositories[T] = repository;
  }

  /// Use this within your app to get an instance of an injected repository.
  ///
  /// It now includes robust error handling that logs to Crashlytics
  /// for easier debugging of configuration issues in production.
  T get<T extends BaseRepository>() {
    final repo = _repositories[T];
    if (repo == null) {
      // Create a detailed error message for developers.
      final error = ArgumentError(
        'Repository of type $T was not registered. '
            'Ensure registerRepository() is called during app initialization (e.g., in main.dart).',
      );

      // For non-fatal configuration errors like this, logging to Crashlytics
      // helps track issues that occur in production without crashing the app,
      // though in this case, the subsequent throw will be fatal.
      // This is useful for debugging setup problems.
      FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: 'Failed to retrieve a registered repository.',
        fatal: true, // Marking as fatal as this is a critical developer error.
      );

      // Throwing an ArgumentError is more specific than a generic Exception
      // and clearly indicates a problem with the arguments/setup.
      throw error;
    }

    // The cast is still necessary, but the logic is now safer due to the
    // improved registration and retrieval process.
    return repo as T;
  }
}
