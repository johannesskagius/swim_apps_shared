import 'package:swim_apps_shared/objects/completed/completed_set_configuration.dart';
import 'package:swim_apps_shared/objects/planned/swim_set_config.dart';

/// Provides temporary runtime storage of per-set adjustments without
/// modifying or persisting the base model.
///
/// Expando allows associating local data with an object dynamically
/// without adding a real field to its class.
final Expando<CompletedSetConfiguration> _completedConfigExpando =
Expando<CompletedSetConfiguration>('completedConfig');

extension EditableSessionSet on SessionSetConfiguration {
  /// Get the locally adjusted configuration (if any)
  CompletedSetConfiguration? get completedConfig =>
      _completedConfigExpando[this];

  /// Set or replace the locally adjusted configuration
  set completedConfig(CompletedSetConfiguration? value) {
    _completedConfigExpando[this] = value;
  }
}
