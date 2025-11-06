import 'package:swim_apps_shared/objects/intensity_zones.dart';
import 'package:swim_apps_shared/objects/planned/set_item.dart';
import 'package:swim_apps_shared/objects/planned/sub_item.dart';
import 'package:swim_apps_shared/objects/planned/swim_session.dart';
import 'package:swim_apps_shared/objects/stroke.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/distance_units.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/swim_way.dart';

import 'enums/set_types.dart';

/// 🧠 Converts a SwimSession back to AI-friendly text
class SessionToTextParser {
  String toText(SwimSession session) {
    if (session.setConfigurations.isEmpty) return "";

    final buffer = StringBuffer();

    for (final config in session.setConfigurations) {
      final title = _sectionHeaderText(config.swimSet?.type);
      final groups = (config.swimSet?.assignedGroupNames ?? [])
          .map((g) => "#group $g")
          .join(" ");

      final reps = config.repetitions > 1 ? "${config.repetitions}x\n" : "";

      if (buffer.isNotEmpty) buffer.writeln();

      // ------- SECTION HEADER ---------
      buffer.write(title);
      if (groups.isNotEmpty) buffer.write(" $groups");
      buffer.writeln();
      if (reps.isNotEmpty) buffer.write(reps);

      // ------- ITEMS ---------
      for (final item in (config.swimSet?.items ?? [])) {
        buffer.writeln(_formatItem(item));

        for (final sub in item.subItems ?? []) {
          buffer.writeln("  ${_formatSubItem(sub)}");
        }
      }
    }

    return buffer.toString().trim();
  }

  // ---------------- Helpers ----------------

  String _sectionHeaderText(SetType? type) {
    switch (type) {
      case SetType.warmUp:
        return "Warm up";
      case SetType.preSet:
        return "Pre set";
      case SetType.mainSet:
        return "Main set";
      case SetType.postSet:
        return "Post set";
      case SetType.coolDown:
        return "Cool down";
      case SetType.kickSet:
        return "Kick set";
      case SetType.pullSet:
        return "Pull set";
      case SetType.drillSet:
        return "Drill set";
      case SetType.recovery:
        return "Recovery";
      default:
        return "Main set";
    }
  }

  String _formatItem(SetItem item) {
    final parts = <String>[];

    // Item repetitions
    if ((item.itemRepetition ?? 1) > 1) {
      parts.add("${item.itemRepetition}x");
    }

    // Distance + unit
    parts.add("${item.itemDistance}${_unit(item.distanceUnit)}");

    // Stroke / way
    final strokeText = _stroke(item.stroke);
    if (item.swimWay == SwimWay.kick) {
      parts.add("${strokeText.isNotEmpty ? "$strokeText " : ""}Kick");
    } else if (item.swimWay == SwimWay.pull) {
      parts.add("${strokeText.isNotEmpty ? "$strokeText " : ""}Pull");
    } else if (item.swimWay == SwimWay.drill) {
      parts.add("${strokeText.isNotEmpty ? "$strokeText " : ""}Drill");
    } else if (strokeText.isNotEmpty) {
      parts.add(strokeText);
    }

    // Interval
    if (item.interval != null) {
      final mm = item.interval!.inMinutes;
      final ss = (item.interval!.inSeconds % 60).toString().padLeft(2, '0');
      parts.add("@$mm:$ss");
    }

    // Intensity
    final zone = _intensity(item.intensityZone);
    if (zone.isNotEmpty) parts.add(zone);

    // Equipment
    if (item.equipment?.isNotEmpty ?? false) {
      parts.add("[${item.equipment!.map((e) => e.name).join(', ')}]");
    }

    // Notes
    if (item.itemNotes != null && item.itemNotes!.isNotEmpty) {
      parts.add("'${item.itemNotes!}'");
    }

    return parts.join(" ");
  }

  String _formatSubItem(SubItem sub) {
    final parts = <String>[];

    if (sub.subItemDistance != null) {
      parts.add("${sub.subItemDistance}${_unit(sub.distanceUnit)}");
    }

    final stroke = _stroke(sub.stroke);
    if (stroke.isNotEmpty) parts.add(stroke);

    if (sub.swimWay == SwimWay.kick) parts.add("Kick");
    if (sub.swimWay == SwimWay.pull) parts.add("Pull");
    if (sub.swimWay == SwimWay.drill) parts.add("Drill");

    final zone = _intensity(sub.intensityZone);
    if (zone.isNotEmpty) parts.add(zone);

    if (sub.equipment.isNotEmpty) {
      parts.add("[${sub.equipment.map((e) => e.name).join(', ')}]");
    }

    if (sub.itemNotes != null && sub.itemNotes!.isNotEmpty) {
      parts.add("'${sub.itemNotes!}'");
    }

    return parts.join(" ");
  }

  String _unit(DistanceUnit? u) {
    if (u == DistanceUnit.yards) return "y";
    if (u == DistanceUnit.kilometers) return "k";
    return "m";
  }

  String _stroke(Stroke? s) {
    switch (s) {
      case Stroke.freestyle:
        return "Free";
      case Stroke.backstroke:
        return "Back";
      case Stroke.breaststroke:
        return "Breast";
      case Stroke.butterfly:
        return "Fly";
      case Stroke.medley:
        return "IM";
      default:
        return "";
    }
  }

  String _intensity(IntensityZone? z) {
    switch (z) {
      case IntensityZone.i1:
      case IntensityZone.i2:
      case IntensityZone.i3:
      case IntensityZone.i4:
        return "i${z!.index + 1}";
      case IntensityZone.max:
        return "max";
      default:
        return "";
    }
  }
}
