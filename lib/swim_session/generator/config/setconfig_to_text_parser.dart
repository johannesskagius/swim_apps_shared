import 'package:swim_apps_shared/swim_session/generator/enums/set_types.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/distance_units.dart';

import '../../../objects/planned/set_item.dart';
import '../../../objects/planned/sub_item.dart';
import '../../../objects/planned/swim_set_config.dart';
import '../../../objects/stroke.dart';
import '../enums/swim_way.dart';

class SessionSetConfigToTextParser {
  static final _lapsHeaderRegex = RegExp(r"^\d+\s*x|^\d+\s*rounds?");

  String sessionConfigsToFormattedText({
    required List<SessionSetConfiguration> sessionConfigs,
    DistanceUnit defaultSessionUnit = DistanceUnit.meters,
    Map<String, dynamic>?
    swimmersMap, // Map<swimmerId, dynamic object with a 'name' property>
    Map<String, dynamic>?
    groupsMap, // Map<groupId, dynamic object with a 'name' property>
  }) {
    if (sessionConfigs.isEmpty) return "";

    StringBuffer mainSb = StringBuffer();

    for (int i = 0; i < sessionConfigs.length; i++) {
      SessionSetConfiguration config = sessionConfigs[i];

      // 1. Section Title
      if (config.rawSetTypeHeaderFromText != null &&
          config.rawSetTypeHeaderFromText!.isNotEmpty) {
        mainSb.writeln(config.rawSetTypeHeaderFromText);
      } else {
        String title = config.swimSet?.type?.name ?? SetType.mainSet.name;
        // Instance notes are now part of the title line if they exist,
        // which matches the UI more closely.
        // If config.notesForThisInstanceOfSet are to be on a separate line,
        // this part needs adjustment. For now, assuming they are part of the title.
        // if (config.notesForThisInstanceOfSet != null &&
        //     config.notesForThisInstanceOfSet!.isNotEmpty) {
        //   title += " #${config.notesForThisInstanceOfSet}";
        // }
        mainSb.writeln(title);
      }

      // --- START: Add Specific Assignments Information ---
      List<String> assignedNames = [];
      if (swimmersMap != null && config.specificSwimmerIds.isNotEmpty) {
        for (String id in config.specificSwimmerIds) {
          assignedNames.add(
            swimmersMap[id]?.showSuccessMessage ?? "Swimmer ID: $id",
          );
        }
      }
      if (groupsMap != null && config.specificGroupIds.isNotEmpty) {
        for (String id in config.specificGroupIds) {
          assignedNames.add(
            groupsMap[id]?.showSuccessMessage ?? "Group ID: $id",
          );
        }
      }

      if (assignedNames.isNotEmpty) {
        mainSb.writeln("  For: ${assignedNames.join(", ")}");
      }
      // --- END: Add Specific Assignments Information ---

      // Display Instance Notes if they exist and are not part of the raw header
      // (Moved after specific assignments for better flow)
      if (config.notesForThisInstanceOfSet != null &&
          config.notesForThisInstanceOfSet!.isNotEmpty &&
          (config.rawSetTypeHeaderFromText == null ||
              !config.rawSetTypeHeaderFromText!.contains(
                config.notesForThisInstanceOfSet!,
              ))) {
        // Indent instance notes slightly if they are separate
        mainSb.writeln("  #${config.notesForThisInstanceOfSet}");
      }

      // 2. Configuration Laps (e.g., "2x" for the whole block)
      bool lapsAlreadyInHeader =
          config.rawSetTypeHeaderFromText?.startsWith(_lapsHeaderRegex) ??
          false;
      if (config.repetitions > 1 && !lapsAlreadyInHeader) {
        if ((config.swimSet != null && config.swimSet!.items.isNotEmpty)) {
          mainSb.writeln("${config.repetitions}x");
        } else if (config.swimSet == null) {
          // Only add "Nx" for notes if it's a note-only block with repetitions
          if (config.notesForThisInstanceOfSet != null &&
              config.notesForThisInstanceOfSet!.isNotEmpty) {
            mainSb.writeln("${config.repetitions}x");
          }
        }
      }

      // 4. Set Items
      if (config.swimSet != null && config.swimSet!.items.isNotEmpty) {
        for (SetItem item in config.swimSet!.items) {
          mainSb.writeln(_setItemToText(item, defaultSessionUnit));
        }
      }

      // 5. SwimSet Definition Notes (not instance notes)
      if (config.swimSet?.setNotes != null &&
          config.swimSet!.setNotes!.isNotEmpty &&
          (config.notesForThisInstanceOfSet ==
                  null || // Ensure it's not the same as instance notes
              !config.notesForThisInstanceOfSet!.contains(
                config.swimSet!.setNotes!,
              )) &&
          (config.rawSetTypeHeaderFromText ==
                  null || // Ensure it's not part of raw header
              !config.rawSetTypeHeaderFromText!.contains(
                config.swimSet!.setNotes!,
              ))) {
        for (final noteLine in config.swimSet!.setNotes!.split('\n')) {
          if (noteLine.trim().isNotEmpty) {
            // Indent set definition notes to distinguish from instance notes or item notes
            mainSb.writeln("  ${noteLine.trim()}");
          }
        }
      }

      if (i < sessionConfigs.length - 1) {
        mainSb.writeln();
      }
    }
    return mainSb.toString().trim();
  }

  String _setItemToText(SetItem item, DistanceUnit defaultSessionUnit) {
    StringBuffer sb = StringBuffer();

    if (item.itemRepetition != null && item.itemRepetition! > 1) {
      sb.write("${item.itemRepetition}x ");
    }

    if (item.itemDistance != null && item.itemDistance! > 0) {
      sb.write(item.itemDistance);
      if (item.distanceUnit != null &&
          item.distanceUnit != defaultSessionUnit) {
        sb.write(item.distanceUnit!.name); // Or .short etc.
      }
      sb.write(" ");
    }

    bool wayIsDefaultSwim = item.swimWay == SwimWay.swim;
    bool strokeIsDefaultChoice =
        item.stroke == null || item.stroke == Stroke.choice;

    if (!wayIsDefaultSwim) {
      sb.write("${item.swimWay.name} "); // Or .toDisplayString()
    }
    if (!strokeIsDefaultChoice ||
        (wayIsDefaultSwim &&
            strokeIsDefaultChoice &&
            (item.subItems == null || item.subItems!.isEmpty))) {
      if (item.stroke != null) {
        sb.write("${item.stroke!.short} "); // Or .toDisplayString()
      }
    }

    if (item.intensityZone != null) {
      sb.write("${item.intensityZone!.name} "); // Or .toDisplayString()
    }

    if (item.subItems != null && item.subItems!.isNotEmpty) {
      sb.write("(");
      sb.write(
        item.subItems!
            .map(
              (si) =>
                  _subItemToText(si, item.distanceUnit ?? defaultSessionUnit),
            )
            .join(", "),
      );
      sb.write(") ");
    }

    if (item.interval != null && item.interval != Duration.zero) {
      sb.write("@${_formatDurationForInterval(item.interval!)} ");
    }

    if (item.equipment != null && item.equipment!.isNotEmpty) {
      sb.write("[");
      sb.write(
        item.equipment!.map((e) => e.toString()).join(" "),
      ); // Or e.toDisplayString()
      sb.write("] ");
    }

    if (item.itemNotes != null && item.itemNotes!.isNotEmpty) {
      // Item notes are typically part of the item line
      sb.write("#${item.itemNotes!.trim()} ");
    }

    return sb.toString().trim();
  }

  String _subItemToText(SubItem subItem, DistanceUnit parentDefaultUnit) {
    StringBuffer sb = StringBuffer();

    if (subItem.subItemDistance > 0) {
      sb.write(subItem.subItemDistance);
      if (subItem.distanceUnit != parentDefaultUnit) {
        sb.write(subItem.distanceUnit.name); // Or .short etc.
      }
      sb.write(" ");
    }

    bool wayIsDefaultSwim = subItem.swimWay == SwimWay.swim;
    bool strokeIsDefaultChoice =
        subItem.stroke == null || subItem.stroke == Stroke.choice;

    if (!wayIsDefaultSwim) {
      sb.write("${subItem.swimWay.name} "); // Or .toDisplayString()
    }
    if (!strokeIsDefaultChoice || (wayIsDefaultSwim && strokeIsDefaultChoice)) {
      if (subItem.stroke != null) {
        sb.write("${subItem.stroke!.short} "); // Or .toDisplayString()
      }
    }

    if (subItem.intensityZone != null) {
      sb.write("${subItem.intensityZone!.name} "); // Or .toDisplayString()
    }

    if (subItem.equipment.isNotEmpty) {
      sb.write("[");
      sb.write(
        subItem.equipment.map((e) => e?.toString()).join(" "),
      ); // Or e.toDisplayString()
      sb.write("] ");
    }

    if (subItem.itemNotes != null && subItem.itemNotes!.isNotEmpty) {
      sb.write("#${subItem.itemNotes!.trim()} ");
    }

    return sb.toString().trim();
  }
}

// Helper Extensions (ensure they are defined or use .name / .short directly)
extension _SetTypeDisplay on SetType {
  String toDisplayString() {
    // ... (your existing implementation)
    switch (this) {
      case SetType.warmUp:
        return 'Warm Up';
      case SetType.mainSet:
        return 'Main Set';
      case SetType.coolDown:
        return 'Cool Down';
      case SetType.custom:
        return 'Custom'; // Ensure custom has a name if possible
      default:
        return name; // Or a more descriptive default
    }
  }
}

// String _formatDurationForInterval needs to be defined if not already global
// e.g.,
String _formatDurationForInterval(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes > 0) {
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  } else {
    return seconds.toString();
  }
}
