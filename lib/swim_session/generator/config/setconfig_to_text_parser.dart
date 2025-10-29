import 'package:swim_apps_shared/swim_session/generator/enums/set_types.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/distance_units.dart';

import '../../../objects/planned/set_item.dart';
import '../../../objects/planned/sub_item.dart';
import '../../../objects/planned/swim_set_config.dart';
import '../../../objects/stroke.dart';
import '../enums/swim_way.dart';

/// 🧩 Converts structured [SessionSetConfiguration]s back into coach-readable text
/// matching TextToSessionObjectParser v3.7 syntax:
/// - Single quotes for comments
/// - Equipment in [brackets]
/// - Sub-items inline in parentheses "(...)"
/// - Group tags via `#group Sprint, Distance`
/// - Notes and intervals inline
class SessionSetConfigToTextParser {
  static final _lapsHeaderRegex = RegExp(r"^\d+\s*x|^\d+\s*rounds?");

  String sessionConfigsToFormattedText({
    required List<SessionSetConfiguration> sessionConfigs,
    DistanceUnit defaultSessionUnit = DistanceUnit.meters,
    Map<String, dynamic>? swimmersMap, // Map<swimmerId, {name: ...}>
    Map<String, dynamic>? groupsMap, // Map<groupId, {name: ...}>
  }) {
    if (sessionConfigs.isEmpty) return "";

    final StringBuffer mainSb = StringBuffer();

    for (int i = 0; i < sessionConfigs.length; i++) {
      final SessionSetConfiguration config = sessionConfigs[i];

      // ---- SECTION HEADER ----
      if (config.rawSetTypeHeaderFromText != null &&
          config.rawSetTypeHeaderFromText!.isNotEmpty) {
        mainSb.writeln(config.rawSetTypeHeaderFromText!.trim());
      } else {
        final typeDisplay =
        setTypeToDisplayString(config.swimSet?.type ?? SetType.mainSet);

        final groupNames = _resolveGroups(config, groupsMap);
        final hasGroups = groupNames.isNotEmpty;
        final note = (config.notesForThisInstanceOfSet ?? "").trim();

        final parts = <String>[];
        parts.add(typeDisplay);
        if (hasGroups) parts.add("#group ${groupNames.join(", ")}");
        if (note.isNotEmpty) parts.add("'$note'");

        mainSb.writeln(parts.join(" "));
      }

      // ---- REPS (2x blocks etc.) ----
      final hasInlineReps =
          config.rawSetTypeHeaderFromText?.startsWith(_lapsHeaderRegex) ?? false;
      if (config.repetitions > 1 && !hasInlineReps) {
        mainSb.writeln("${config.repetitions}x");
      }

      // ---- ITEMS ----
      if (config.swimSet != null && config.swimSet!.items.isNotEmpty) {
        for (final SetItem item in config.swimSet!.items) {
          mainSb.writeln(_setItemToText(item, defaultSessionUnit));
        }
      }

      // ---- SET NOTES (definition-level notes) ----
      if (config.swimSet?.setNotes != null &&
          config.swimSet!.setNotes!.trim().isNotEmpty) {
        for (final noteLine in config.swimSet!.setNotes!.split('\n')) {
          if (noteLine.trim().isNotEmpty) {
            mainSb.writeln("  '${noteLine.trim()}'");
          }
        }
      }

      if (i < sessionConfigs.length - 1) {
        mainSb.writeln();
      }
    }

    return mainSb.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // 🧱 SET ITEM
  // ---------------------------------------------------------------------------
  String _setItemToText(SetItem item, DistanceUnit defaultSessionUnit) {
    final sb = StringBuffer();

    if (item.itemRepetition != null && item.itemRepetition! > 1) {
      sb.write("${item.itemRepetition}x ");
    }

    if (item.itemDistance != null && item.itemDistance! > 0) {
      sb.write(item.itemDistance);
      if (item.distanceUnit != null &&
          item.distanceUnit != defaultSessionUnit) {
        sb.write(item.distanceUnit!.name);
      }
      sb.write(" ");
    }

    // SWIM WAY + STROKE
    final wayIsSwim = item.swimWay == SwimWay.swim;
    final strokeIsChoice = item.stroke == null || item.stroke == Stroke.choice;

    if (!wayIsSwim) sb.write("${item.swimWay.name} ");
    if (!strokeIsChoice) sb.write("${item.stroke!.short} ");

    // INTENSITY
    if (item.intensityZone != null) {
      sb.write("${item.intensityZone!.name} ");
    }

    // SUBITEMS
    if ((item.subItems ?? const <SubItem>[]).isNotEmpty) {
      final subItems = item.subItems!;
      sb.write("(");
      sb.write(
        subItems
            .map((si) =>
            _subItemToText(si, item.distanceUnit ?? defaultSessionUnit))
            .join(", "),
      );
      sb.write(") ");
    }

    // INTERVAL
    if (item.interval != null && item.interval != Duration.zero) {
      sb.write("@${_formatDurationForInterval(item.interval!)} ");
    }

    // EQUIPMENT (nullable-safe)
    final equipmentList = item.equipment ?? const [];
    if (equipmentList.isNotEmpty) {
      sb.write("[${equipmentList.map((e) => e.name).join(", ")}] ");
    }

    // NOTES
    if (item.itemNotes != null && item.itemNotes!.isNotEmpty) {
      sb.write("'${item.itemNotes!.trim()}' ");
    }

    return sb.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // 🧩 SUB ITEM
  // ---------------------------------------------------------------------------
  String _subItemToText(SubItem subItem, DistanceUnit parentUnit) {
    final sb = StringBuffer();

    if (subItem.subItemDistance != null && subItem.subItemDistance! > 0) {
      sb.write(subItem.subItemDistance);
      if (subItem.distanceUnit != parentUnit) {
        sb.write(subItem.distanceUnit.name);
      }
      sb.write(" ");
    }

    final wayIsSwim = subItem.swimWay == SwimWay.swim;
    final strokeIsChoice =
        subItem.stroke == null || subItem.stroke == Stroke.choice;

    if (!wayIsSwim) sb.write("${subItem.swimWay.name} ");
    if (!strokeIsChoice) sb.write("${subItem.stroke!.short} ");

    if (subItem.intensityZone != null) {
      sb.write("${subItem.intensityZone!.name} ");
    }

    if (subItem.equipment.isNotEmpty) {
      sb.write("[${subItem.equipment.map((e) => e.name).join(", ")}] ");
    }

    if (subItem.itemNotes != null && subItem.itemNotes!.isNotEmpty) {
      sb.write("'${subItem.itemNotes!.trim()}' ");
    }

    return sb.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // 🔹 HELPERS
  // ---------------------------------------------------------------------------
  List<String> _resolveGroups(
      SessionSetConfiguration config, Map<String, dynamic>? groupsMap) {
    if (groupsMap == null || config.specificGroupIds.isEmpty) return [];
    return config.specificGroupIds
        .map((id) {
      final g = groupsMap[id];
      if (g == null) return id;
      // Try common shapes: {name: ...} or object with .name
      if (g is Map && g['name'] is String) return g['name'] as String;
      try {
        // ignore: avoid_dynamic_calls
        final dynName = g.name;
        if (dynName is String) return dynName;
      } catch (_) {}
      return id;
    })
        .whereType<String>()
        .toList();
  }
}

/// Top-level helper to avoid extension name collisions in your codebase.
String setTypeToDisplayString(SetType type) {
  switch (type) {
    case SetType.warmUp:
      return 'Warm Up';
    case SetType.mainSet:
      return 'Main Set';
    case SetType.coolDown:
      return 'Cool Down';
    case SetType.kickSet:
      return 'Kick Set';
    case SetType.pullSet:
      return 'Pull Set';
    case SetType.drillSet:
      return 'Drill Set';
    case SetType.preSet:
      return 'Pre Set';
    case SetType.postSet:
      return 'Post Set';
    case SetType.recovery:
      return 'Recovery';
    default:
      return type.name;
  }
}

String _formatDurationForInterval(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return "$minutes:${seconds.toString().padLeft(2, '0')}";
}
