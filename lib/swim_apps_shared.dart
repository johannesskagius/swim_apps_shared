library swim_apps_shared;

// --- HELPERS ---
export 'helpers/base_repository.dart';
export 'helpers/firestore_helper.dart';

// --- REPOSITORIES ---
// Note: Assuming repositories are in a 'repositories' folder.
// If not, this path will need to be adjusted.
export 'helpers/race_repository.dart';
export 'helpers/user_repository.dart';

// --- EVENTS ---
export 'src/events/event.dart';
export 'src/events/fifty_meter_race.dart';
// Add other event files here if any, e.g. hundred_meter_race.dart

// --- OBJECTS / MODELS ---
export 'src/objects/user.dart';
export 'src/objects/coach.dart';
export 'src/objects/swimmer.dart';
export 'src/objects/race.dart';
export 'src/objects/stroke.dart';
export 'src/objects/analyzed_segment.dart';
//export 'src/objects/check_point.dart';
//export 'src/objects/completed_swim_session.dart';
//export 'src/objects/competition.dart';
export 'src/objects/interval_attributes.dart';
//export 'src/objects/macro_cycle.dart';
//export 'src/objects/plan_features.dart';
export 'src/objects/race_segment.dart';
//export 'src/objects/swim_camp.dart';
//export 'src/objects/swim_group.dart';
//export 'src/objects/swim_set.dart';
//export 'src/objects/user_subscription.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
