// ============================================================================
//  TextToSessionObjectParser — Clean, Deterministic, Patched Version
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/generator/parsed_summary.dart';
import 'package:swim_apps_shared/swim_session/generator/session_syntax_patterns.dart';

import '../../objects/intensity_zones.dart';
import '../../objects/planned/set_item.dart';
import '../../objects/planned/sub_item.dart';
import '../../objects/planned/swim_set.dart';
import '../../objects/planned/swim_set_config.dart';
import '../../objects/stroke.dart';
import 'enums/distance_units.dart';
import 'enums/equipment.dart';
import 'enums/set_types.dart';
import 'enums/swim_way.dart';

// ============================================================================
// INTERNAL SECTION MODEL
// ============================================================================

class _ParsedSection {
  final SetType type;
  final List<String> rawLines;
  int repetitions = 1;
  final Set<String> groupNamesLower;
  final List<String> swimmerNames;

  _ParsedSection({
    required this.type,
    List<String>? rawLines,
    Set<String>? groupNamesLower,
    List<String>? swimmerNames,
  }) : rawLines = rawLines ?? <String>[],
       groupNamesLower = groupNamesLower ?? <String>{},
       swimmerNames = swimmerNames ?? <String>[];
}

// ============================================================================
// MAIN PARSER
// ============================================================================

class TextToSessionObjectParser {
  final String userId;
  final RegExp _lineBreak = RegExp(r'\r\n?|\n');
  static int _idCounter = 0;

  TextToSessionObjectParser({required this.userId});

  String _id([String prefix = 'id']) =>
      '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Parser] $msg');
  }

  // Shortcuts to shared regex
  static final RegExp _sectionHeader = SessionSyntaxPatterns.sectionHeader;
  static final RegExp _standaloneReps = SessionSyntaxPatterns.standaloneReps;
  static final RegExp _inlineReps = SessionSyntaxPatterns.inlineReps;
  static final RegExp _distance = SessionSyntaxPatterns.distance;
  static final RegExp _interval = SessionSyntaxPatterns.interval;
  static final RegExp _equipment = SessionSyntaxPatterns.equipment;
  static final RegExp _kickWord = SessionSyntaxPatterns.kickWord;
  static final RegExp _pullWord = SessionSyntaxPatterns.pullWord;
  static final RegExp _drillWord = SessionSyntaxPatterns.drillWord;
  static final RegExp _intensityIndex = SessionSyntaxPatterns.intensityIndex;
  static final RegExp _intensityWord = SessionSyntaxPatterns.intensityWord;
  static final RegExp _subItemLine = SessionSyntaxPatterns.subItemLine;
  static final RegExp _groupTag = SessionSyntaxPatterns.groupTag;
  static final RegExp _swimmerTag = SessionSyntaxPatterns.swimmerTag;
  static final RegExp _requiresResultTag =
      SessionSyntaxPatterns.requiresResultTag;
  static final RegExp _resultTag = SessionSyntaxPatterns.resultTag;

  // Stroke mapping
  static const Map<String, Stroke> _strokeMap = {
    'fr': Stroke.freestyle,
    'free': Stroke.freestyle,
    'freestyle': Stroke.freestyle,
    'bk': Stroke.backstroke,
    'back': Stroke.backstroke,
    'br': Stroke.breaststroke,
    'breast': Stroke.breaststroke,
    'breaststroke': Stroke.breaststroke,
    'fly': Stroke.butterfly,
    'butterfly': Stroke.butterfly,
    'im': Stroke.medley,
  };

  // ==========================================================================
  // 1) TOKENIZATION — break input into logical sections
  // ==========================================================================

  List<_ParsedSection> _tokenize(String text) {
    final lines = text
        .split(_lineBreak)
        .map((e) => e.trimRight()) // keep leading spaces for sub-items
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final sections = <_ParsedSection>[];
    _ParsedSection? current;

    void extractTagsIntoSection(_ParsedSection sec, String raw) {
      // Groups
      for (final m in _groupTag.allMatches(raw)) {
        final name = m.group(1)?.trim();
        if (name != null && name.isNotEmpty) {
          sec.groupNamesLower.add(name.toLowerCase());
        }
      }

      // Swimmers
      final sm = _swimmerTag.firstMatch(raw);
      if (sm != null) {
        final part = sm.group(1) ?? '';
        final names = part
            .split(RegExp(r'[,;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        sec.swimmerNames.addAll(names);
      }
    }

    for (final raw in lines) {
      // New section header
      final hdr = _sectionHeader.firstMatch(raw);
      if (hdr != null) {
        if (current != null) sections.add(current);

        current = _ParsedSection(
          type: _mapSectionType(hdr.group(1)!),
          rawLines: [],
        );

        current.rawLines.add(raw);
        extractTagsIntoSection(current, raw);
        continue;
      }

      // Ensure we have a section (default main set)
      current ??= _ParsedSection(type: SetType.mainSet, rawLines: []);

      current.rawLines.add(raw);
      extractTagsIntoSection(current, raw);

      // Standalone repetitions "2x"
      final rep = _standaloneReps.firstMatch(raw);
      if (rep != null) {
        current.repetitions = int.parse(rep.group(1)!);
      }
    }

    if (current != null) sections.add(current);
    return sections;
  }

  // ==========================================================================
  // 2) PARSE SECTIONS → SessionSetConfiguration
  // ==========================================================================

  List<SessionSetConfiguration> parse(String? text, {String? sessionId}) {
    if (text == null || text.trim().isEmpty) return [];

    try {
      final sections = _tokenize(text);
      final configs = <SessionSetConfiguration>[];

      int sectionOrder = 0;

      for (final sec in sections) {
        final items = <SetItem>[];
        int itemOrder = 0;

        for (final raw in sec.rawLines) {
          // Skip pure section header lines (optional – safe)
          if (_sectionHeader.hasMatch(raw)) continue;

          // --- 1) Sub-items FIRST (so "  25 kick" doesn't become a parent item)
          final subm = _subItemLine.firstMatch(raw);
          if (subm != null && items.isNotEmpty) {
            final last = items.last;
            final parsedSub = _parseSubItem(
              subm.group(1)!,
              last.subItems?.length ?? 0,
            );

            if (parsedSub != null) {
              final List<SubItem> updated = [
                ...(last.subItems ?? const <SubItem>[]),
                parsedSub,
              ];
              items[items.length - 1] = last.copyWith(subItems: updated);
            }
            continue;
          }

          // --- 2) Normal / rest / distance item
          final item = _parseItem(raw, itemOrder);
          if (item != null) {
            items.add(item);
            itemOrder++;
          }
        }

        // Skip empty section
        if (items.isEmpty) continue;

        configs.add(
          SessionSetConfiguration(
            sessionSetConfigId: _id('ssc'),
            swimSetId: _id('swconf'),
            order: sectionOrder++,
            repetitions: sec.repetitions,
            storedSet: false,
            coachId: userId,
            rawSetTypeHeaderFromText: sec.type.toString(),
            unparsedTextLines: List<String>.from(sec.rawLines),
            specificGroupIds: List<String>.from(sec.swimmerNames),
            specificSwimmerIds: List<String>.from(sec.swimmerNames),
            swimSet: SwimSet(
              setId: _id('set'),
              type: sec.type,
              items: items,
              assignedGroupNames: sec.groupNamesLower.toList(),
            ),
          ),
        );
      }

      return configs;
    } catch (e, st) {
      _log('Critical failure in parse(): $e\n$st');
      return [];
    }
  }

  // ==========================================================================
  // 3) ITEM PARSING
  // ==========================================================================

  SetItem? _parseItem(String raw, int order) {
    try {
      String line = raw.trim();
      if (line.isEmpty) return null;

      // --- Rest detection: "1:00 rest"
      final rest = RegExp(
        r'^(\d{1,2}):(\d{2})\s*rest\b',
        caseSensitive: false,
      ).firstMatch(line);
      if (rest != null) {
        final mm = int.parse(rest.group(1)!);
        final ss = int.parse(rest.group(2)!);

        // --- Result expectation tagging
        bool requiresResult = _requiresResultTag.hasMatch(raw);

        final resultTags = <String>[];
        for (final m in _resultTag.allMatches(raw)) {
          final tag = m.group(1);
          if (tag != null && tag.isNotEmpty) {
            resultTags.add(tag.toLowerCase());
          }
        }


        return SetItem(
          id: _id('rest'),
          order: order,
          itemRepetition: 1,
          itemDistance: 0,
          distanceUnit: DistanceUnit.meters,
          swimWay: SwimWay.rest,
          interval: Duration(minutes: mm, seconds: ss),
          itemNotes: 'Rest $mm:${ss.toString().padLeft(2, '0')}',
          rawTextLine: raw,
          subItems: const [],
          stroke: null,
          intensityZone: null,
          equipment: const [],
          requiresResult: requiresResult,
          resultTags: resultTags.isNotEmpty ? null : resultTags,
          resultSchema: null, // can be filled later by another layer if desired
        );
      }

      // --- Inline reps: "4x100"
      int reps = 1;
      final rm = _inlineReps.firstMatch(line);
      if (rm != null) {
        reps = int.parse(rm.group(1)!);
        line = line.substring(rm.end).trim();
      }

      // --- Distance: "100", "100fr", "100m"
      final dm = _distance.firstMatch(line);
      if (dm == null) return null;

      final distance = int.parse(dm.group(1)!);
      String trailing = (dm.group(2) ?? '').toLowerCase();

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;

      if (_strokeMap.containsKey(trailing)) {
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        unit = _parseUnit(trailing);
      }

      line = line.substring(dm.end).trim();

      // --- Interval: "@1:20"
      Duration? interval;
      final im = _interval.firstMatch(line);
      if (im != null) {
        interval = Duration(
          minutes: int.parse(im.group(1)!),
          seconds: int.parse(im.group(2)!),
        );
        line = line.replaceFirst(im.group(0)!, '').trim();
      }

      // --- Intensity (i1 / easy / etc.)
      IntensityZone? zone;
      final iz = _intensityIndex.firstMatch(line);
      if (iz != null) {
        zone = _mapIntensityIndex(int.parse(iz.group(1)!));
        line = line.replaceFirst(iz.group(0)!, '').trim();
      } else {
        final iw = _intensityWord.firstMatch(line);
        if (iw != null) {
          zone = _mapIntensityWord(iw.group(1)!);
          line = line.replaceFirst(iw.group(0)!, '').trim();
        }
      }

      // --- Stroke from remaining tokens
      for (final t in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[t.toLowerCase()];
      }

      // --- Swim way
      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      // --- Equipment
      List<EquipmentType> equipment = [];
      final eq = _equipment.firstMatch(raw);
      if (eq != null) {
        final names = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty);
        equipment = names.map(_mapEquipment).toList();
      }

      // --- Notes in quotes
      final q = RegExp(r"'([^']+)'").firstMatch(raw);
      final notes = q?.group(1);

      return SetItem(
        id: _id('item'),
        order: order,
        itemRepetition: reps,
        itemDistance: distance,
        distanceUnit: unit,
        swimWay: way,
        stroke: stroke,
        interval: interval,
        intensityZone: zone,
        equipment: equipment,
        itemNotes: notes,
        rawTextLine: raw,
        subItems: const [],
      );
    } catch (e, st) {
      _log('Error in _parseItem: $raw — $e\n$st');
      return null;
    }
  }

  // ==========================================================================
  // 4) SUBITEM PARSING
  // ==========================================================================

  SubItem? _parseSubItem(String raw, int order) {
    try {
      String line = raw.trim();

      final dm = _distance.firstMatch(line);
      final dist = dm != null ? int.parse(dm.group(1)!) : null;

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;
      final trailing = (dm?.group(2) ?? '').toLowerCase();

      if (_strokeMap.containsKey(trailing)) {
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        unit = _parseUnit(trailing);
      }

      // Stroke from free text if still null
      for (final t in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[t.toLowerCase()];
      }

      // Swim way
      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      // Intensity
      IntensityZone? zone;
      final iz = _intensityIndex.firstMatch(line);
      if (iz != null) {
        zone = _mapIntensityIndex(int.parse(iz.group(1)!));
      } else {
        final iw = _intensityWord.firstMatch(line);
        if (iw != null) zone = _mapIntensityWord(iw.group(1)!);
      }

      // Equipment
      List<EquipmentType> equipment = [];
      final eq = _equipment.firstMatch(raw);
      if (eq != null) {
        final names = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty);
        equipment = names.map(_mapEquipment).toList();
      }

      final q = RegExp(r"'([^']+)'").firstMatch(raw);
      final notes = q?.group(1);

      return SubItem(
        subItemDistance: dist,
        distanceUnit: unit,
        swimWay: way,
        stroke: stroke,
        intensityZone: zone,
        equipment: equipment,
        itemNotes: notes,
      );
    } catch (e, st) {
      _log('Error in _parseSubItem: $raw — $e\n$st');
      return null;
    }
  }

  // ==========================================================================
  // 5) SUMMARY BUILDER (with groups)
  // ==========================================================================

  ParsedSummary parseWithSummary(
    String? text, {
    String? sessionId,
    Iterable<String>? allGroupNames,
  }) {
    try {
      final configs = parse(text, sessionId: sessionId);

      final metersByGroup = <String, double>{};
      double totalMeters = 0;
      int totalItems = 0;

      final globalGroups = (allGroupNames ?? const <String>[])
          .map((g) => g.toLowerCase().trim())
          .where((g) => g.isNotEmpty)
          .toList();

      for (final config in configs) {
        final sectionGroups = (config.swimSet?.assignedGroupNames ?? [])
            .map((g) => g.trim().toLowerCase())
            .where((g) => g.isNotEmpty)
            .toList();

        for (final item in config.swimSet?.items ?? []) {
          final dist =
              (item.itemDistance ?? 0) *
              (item.itemRepetition ?? 1) *
              config.repetitions;

          if (item.itemDistance != null && item.itemDistance! > 0) {
            totalMeters += dist;
          }
          totalItems++;

          final groupsToCredit = sectionGroups.isNotEmpty
              ? sectionGroups
              : (globalGroups.isNotEmpty
                    ? globalGroups
                    : (metersByGroup.isNotEmpty
                          ? metersByGroup.keys.toList()
                          : <String>['all']));

          for (final g in {...groupsToCredit, 'all'}) {
            metersByGroup[g] = (metersByGroup[g] ?? 0) + dist;
          }
        }
      }

      return ParsedSummary(
        metersByGroup: metersByGroup,
        totalMeters: totalMeters,
        totalItems: totalItems,
        totalSections: configs.length,
      );
    } catch (e, st) {
      _log("Summary error: $e\n$st");
      return ParsedSummary(
        metersByGroup: const {},
        totalMeters: 0,
        totalItems: 0,
        totalSections: 0,
      );
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  DistanceUnit _parseUnit(String u) {
    u = u.toLowerCase();
    if (u.startsWith('y')) return DistanceUnit.yards;
    if (u.startsWith('k')) return DistanceUnit.kilometers;
    return DistanceUnit.meters;
  }

  IntensityZone? _mapIntensityIndex(int i) => {
    1: IntensityZone.i1,
    2: IntensityZone.i2,
    3: IntensityZone.i3,
    4: IntensityZone.i4,
    5: IntensityZone.max,
  }[i];

  IntensityZone? _mapIntensityWord(String w) {
    switch (w.toLowerCase()) {
      case 'easy':
        return IntensityZone.i1;
      case 'moderate':
        return IntensityZone.i2;
      case 'threshold':
        return IntensityZone.i3;
      case 'hard':
        return IntensityZone.i4;
      case 'max':
      case 'maximum':
      case 'sprint':
        return IntensityZone.max;
      case 'sp1':
        return IntensityZone.sp1;
      case 'sp2':
        return IntensityZone.sp2;
      case 'sp3':
        return IntensityZone.sp3;
      case 'drill':
        return IntensityZone.drill;
      case 'race':
      case 'racepace':
      case 'rp':
        return IntensityZone.racePace;
    }
    return null;
  }

  SetType _mapSectionType(String header) {
    final h = header.toLowerCase();

    if (h.contains('warm')) return SetType.warmUp;
    if (h.contains('cool')) return SetType.coolDown;
    if (h.contains('kick')) return SetType.kickSet;
    if (h.contains('pull')) return SetType.pullSet;
    if (h.contains('drill')) return SetType.drillSet;
    if (h.contains('recovery')) return SetType.recovery;
    if (h.contains('pre')) return SetType.preSet;
    if (h.contains('post')) return SetType.postSet;

    return SetType.mainSet;
  }

  EquipmentType _mapEquipment(String name) {
    final n = name.toLowerCase();
    for (final t in EquipmentType.values) {
      if (t.parsingKeywords.contains(n)) return t;
      for (final kw in t.parsingKeywords) {
        if (kw.isNotEmpty && n.contains(kw)) return t;
      }
    }
    return EquipmentType.other;
  }
}
