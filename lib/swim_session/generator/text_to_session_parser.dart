// TextToSessionObjectParser.dart
// 🔥 Refactored to use shared SessionSyntaxPatterns

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


/// Parser for plain/AI-generated swim text.
class TextToSessionObjectParser {
  final RegExp _lineBreak = RegExp(r'\r\n?|\n');
  static int _idCounter = 0;

  final String userId;

  TextToSessionObjectParser({required this.userId});

  String _id([String prefix = 'id']) =>
      '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Parser] $msg');
  }

  // ---------------------------------------------------------------------------
  // 🔗  SHARED PATTERNS (from session_syntax_patterns.dart)
  // ---------------------------------------------------------------------------
  static final RegExp _sectionHeader = SessionSyntaxPatterns.sectionHeader;
  static final RegExp _groupTag = SessionSyntaxPatterns.groupTag;
  static final RegExp _swimmerTag = SessionSyntaxPatterns.swimmerTag;
  static final RegExp _standaloneReps = SessionSyntaxPatterns.standaloneReps;
  static final RegExp _inlineReps = SessionSyntaxPatterns.inlineReps;
  static final RegExp _distance = SessionSyntaxPatterns.distance;
  static final RegExp _interval = SessionSyntaxPatterns.interval;

  static final RegExp _intensityIndex = SessionSyntaxPatterns.intensityIndex;
  static final RegExp _intensityWord = SessionSyntaxPatterns.intensityWord;

  static final RegExp _equipment = SessionSyntaxPatterns.equipment;

  static final RegExp _subItemLine = SessionSyntaxPatterns.subItemLine;

  static final RegExp _kickWord = SessionSyntaxPatterns.kickWord;
  static final RegExp _pullWord = SessionSyntaxPatterns.pullWord;
  static final RegExp _drillWord = SessionSyntaxPatterns.drillWord;

  // ---------------------------------------------------------------------------
  // Stroke map stays internal to parser
  // ---------------------------------------------------------------------------
  static const Map<String, Stroke> _strokeMap = {
    'fr': Stroke.freestyle,
    'free': Stroke.freestyle,
    'freestyle': Stroke.freestyle,
    'bk': Stroke.backstroke,
    'back': Stroke.backstroke,
    'backstroke': Stroke.backstroke,
    'br': Stroke.breaststroke,
    'breast': Stroke.breaststroke,
    'breaststroke': Stroke.breaststroke,
    'fly': Stroke.butterfly,
    'butterfly': Stroke.butterfly,
    'im': Stroke.medley,
  };

  // ===========================================================================
  // 🔥 MAIN PARSE LOGIC (unchanged except regex now pulled from shared file)
  // ===========================================================================
  List<SessionSetConfiguration> parse(
      String? unparsedText, {
        String? sessionId,
      }) {
    _log('parse() start | user=$userId | session=${sessionId ?? 'none'}');

    try {
      if (unparsedText == null || unparsedText.trim().isEmpty) {
        _log('Empty input text — returning [].');
        return [];
      }

      final lines = unparsedText
          .split(_lineBreak)
          .map((l) => l.trimRight())
          .where((l) => l.isNotEmpty)
          .toList();

      final configs = <SessionSetConfiguration>[];
      SessionSetConfiguration? currentConfig;
      final currentItems = <SetItem>[];

      SetType currentType = SetType.mainSet;
      var sectionReps = 1;
      final sectionGroups = <String>{};
      final sectionSwimmers = <String>{};
      final unparsedBuffer = <String>[];

      void flushSection() {
        if (currentConfig == null) return;

        final snapshot = currentConfig!.copyWith(
          unparsedTextLines: List.from(unparsedBuffer),
        );

        if (currentItems.isEmpty) {
          _log("Skipping empty section '${snapshot.rawSetTypeHeaderFromText}'");
          currentConfig = null;
          sectionReps = 1;
          sectionGroups.clear();
          sectionSwimmers.clear();
          unparsedBuffer.clear();
          return;
        }

        final swimSet = (snapshot.swimSet ??
            SwimSet(setId: _id('set'), type: currentType, items: const []))
            .copyWith(
          items: List.from(currentItems),
          assignedGroupNames:
          sectionGroups.map((e) => e.toLowerCase().trim()).toList(),
        );

        final done = snapshot.copyWith(
          repetitions: sectionReps,
          swimSet: swimSet,
          specificGroupIds:
          sectionGroups.map((e) => e.toLowerCase().trim()).toList(),
          specificSwimmerIds: sectionSwimmers.toList(),
        );

        configs.add(done);

        currentConfig = null;
        currentItems.clear();
        sectionReps = 1;
        sectionGroups.clear();
        sectionSwimmers.clear();
        unparsedBuffer.clear();
      }

      int sectionCount = 0;
      int itemOrder = 0;

      for (final raw in lines) {
        unparsedBuffer.add(raw);
        try {
          // Section header
          final hdr = _sectionHeader.firstMatch(raw);
          if (hdr != null) {
            flushSection();

            currentType = _mapSectionType(hdr.group(1)!);
            sectionReps = 1;
            sectionGroups.clear();
            sectionSwimmers.clear();

            unparsedBuffer
              ..clear()
              ..add(raw);

            sectionGroups.addAll(_extractGroups(raw));
            sectionSwimmers.addAll(_extractSwimmers(raw));

            currentConfig = SessionSetConfiguration(
              sessionSetConfigId: _id('ssc'),
              swimSetId: _id('swconf'),
              order: sectionCount++,
              repetitions: 1,
              storedSet: false,
              coachId: userId,
              swimSet: SwimSet(
                setId: _id('set'),
                type: currentType,
                items: const [],
                assignedGroupNames: sectionGroups.toList(),
              ),
              rawSetTypeHeaderFromText: hdr.group(0),
              unparsedTextLines: const [],
              specificGroupIds: const [],
              specificSwimmerIds: const [],
            );

            continue;
          }

          // Standalone reps
          final rep = _standaloneReps.firstMatch(raw);
          if (rep != null) {
            sectionReps *= int.tryParse(rep.group(1) ?? '1') ?? 1;
            continue;
          }

          // Group & swimmer tags
          final addedGroups = _extractGroups(raw);
          if (addedGroups.isNotEmpty) sectionGroups.addAll(addedGroups);

          final addedSwimmers = _extractSwimmers(raw);
          if (addedSwimmers.isNotEmpty) sectionSwimmers.addAll(addedSwimmers);

          // Sub-items
          final subMatch = _subItemLine.firstMatch(raw);
          if (subMatch != null && currentItems.isNotEmpty) {
            final lastParent = currentItems.last;
            final existing = lastParent.subItems ?? const <SubItem>[];
            final sub = _parseSubItem(subMatch.group(1)!, existing.length);

            if (sub != null) {
              final updated = [...existing, sub];
              currentItems[currentItems.length - 1] =
                  lastParent.copyWith(subItems: updated);
            }
            continue;
          }

          // Item line
          final item = _parseItem(raw, itemOrder);
          if (item != null) {
            currentConfig ??= SessionSetConfiguration(
              sessionSetConfigId: _id('ssc'),
              swimSetId: _id('swconf'),
              order: sectionCount,
              repetitions: 1,
              storedSet: false,
              coachId: userId,
              swimSet: SwimSet(
                setId: _id('set'),
                type: currentType,
                items: const [],
                assignedGroupNames: const [],
              ),
              rawSetTypeHeaderFromText: "(auto) ${currentType.name}",
              unparsedTextLines: const [],
              specificGroupIds: const [],
              specificSwimmerIds: const [],
            );

            currentItems.add(item);
            itemOrder++;
          }
        } catch (e, st) {
          _log('Parser line error: "$raw" — $e\n$st');
        }
      }

      flushSection();
      return configs;
    } catch (e, st) {
      _log('Critical failure in parse(): $e\n$st');
      return [];
    }
  }

  // ===========================================================================
  // ITEM PARSING (unchanged — only regex sources changed)
  // ===========================================================================

  SetItem? _parseItem(String raw, int order) {
    try {
      String line = raw.trim();
      if (line.isEmpty) return null;

      // Rest detection
      final rest = RegExp(r'(\d{1,2}):(\d{2})\s*rest', caseSensitive: false)
          .firstMatch(line);
      if (rest != null) {
        final mm = int.parse(rest.group(1)!);
        final ss = int.parse(rest.group(2)!);
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
        );
      }

      // Inline reps: "4x"
      int reps = 1;
      final rm = _inlineReps.firstMatch(line);
      if (rm != null) {
        reps = int.parse(rm.group(1)!);
        line = line.substring(rm.end).trimLeft();
      }

      // Distance
      final dm = _distance.firstMatch(line);
      if (dm == null) return null;

      final dist = int.parse(dm.group(1)!);
      final trailing = (dm.group(2) ?? '').toLowerCase();

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;
      if (_strokeMap.containsKey(trailing)) {
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        unit = _parseUnit(trailing);
      }

      line = line.substring(dm.end).trimLeft();

      // Interval
      Duration? interval;
      final im = _interval.firstMatch(line);
      if (im != null) {
        interval = Duration(
          minutes: int.parse(im.group(1)!),
          seconds: int.parse(im.group(2)!),
        );
        line = line.replaceFirst(im.group(0)!, '').trim();
      }

      // Intensity
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

      // Stroke if still missing
      for (final t in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[t.toLowerCase()];
      }

      // Way
      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      // Equipment
      List<EquipmentType> detectedEquipment = [];
      final eq = _equipment.firstMatch(raw);
      if (eq != null) {
        final names = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .toList();
        detectedEquipment = names.map(_mapEquipment).toList();
      }

      // Notes in quotes
      final q = RegExp(r"'([^']+)'").firstMatch(raw);
      final notes = q?.group(1);

      return SetItem(
        id: _id('item'),
        order: order,
        itemRepetition: reps,
        itemDistance: dist,
        distanceUnit: unit,
        swimWay: way,
        stroke: stroke,
        interval: interval,
        intensityZone: zone,
        equipment: detectedEquipment,
        itemNotes: notes,
        rawTextLine: raw,
        subItems: const [],
      );
    } catch (e, st) {
      _log('Error in _parseItem: $raw — $e\n$st');
      return null;
    }
  }

  // ===========================================================================
  // SUBITEM PARSING (unchanged)
  // ===========================================================================

  SubItem? _parseSubItem(String raw, int order) {
    try {
      final line = raw.trim();
      final dm = _distance.firstMatch(line);

      final dist = dm != null ? int.parse(dm.group(1)!) : null;
      final trailing = (dm?.group(2) ?? '').toLowerCase();

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;

      if (_strokeMap.containsKey(trailing)) {
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        unit = _parseUnit(trailing);
      }

      for (final t in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[t.toLowerCase()];
      }

      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      IntensityZone? zone;
      final iz = _intensityIndex.firstMatch(line);
      if (iz != null) {
        zone = _mapIntensityIndex(int.parse(iz.group(1)!));
      } else {
        final iw = _intensityWord.firstMatch(line);
        if (iw != null) zone = _mapIntensityWord(iw.group(1)!);
      }

      List<EquipmentType> detectedEquipment = [];
      final eq = _equipment.firstMatch(line);
      if (eq != null) {
        final names = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .toList();
        detectedEquipment = names.map(_mapEquipment).toList();
      }

      final q = RegExp(r"'([^']+)'").firstMatch(raw);
      final notes = q?.group(1);

      return SubItem(
        subItemDistance: dist,
        distanceUnit: unit,
        swimWay: way,
        stroke: stroke,
        intensityZone: zone,
        equipment: detectedEquipment,
        itemNotes: notes,
      );
    } catch (e, st) {
      _log('Error in _parseSubItem: $raw — $e\n$st');
      return null;
    }
  }

  // ===========================================================================
  // GROUPS, UNIT, INTENSITY MAPPERS (unchanged)
  // ===========================================================================

  ParsedSummary parseWithSummary(
      String? unparsedText, {
        String? sessionId,
        Iterable<String>? allGroupNames,
      }) {
    try {
      final configs = parse(unparsedText, sessionId: sessionId);

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
            .toList();

        for (final item in config.swimSet?.items ?? []) {
          final dist =
              (item.itemDistance ?? 0) * (item.itemRepetition ?? 1) * config.repetitions;

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
              : ['all']));

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
        metersByGroup: {},
        totalMeters: 0,
        totalItems: 0,
        totalSections: 0,
      );
    }
  }

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

  List<String> _extractGroups(String text) => _groupTag
      .allMatches(text)
      .map((m) => m.group(1)!.trim())
      .where((x) => x.isNotEmpty)
      .toList();

  List<String> _extractSwimmers(String text) {
    final m = _swimmerTag.firstMatch(text);
    if (m == null) return [];
    return m
        .group(1)!
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
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
