// TextToSessionObjectParser.dart
// ✅ Clean, platform-safe version (no Firebase, no Crashlytics)

import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/generator/parsed_summary.dart';

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

/// 🧠 Parser for AI-generated swim text.
/// Now completely Firebase-free — `userId` must be provided in constructor.
class TextToSessionObjectParser {
  final RegExp _lineBreak = RegExp(r'\r\n?|\n');
  static int _idCounter = 0;

  /// The ID of the user owning or creating this parsed session.
  final String userId;

  TextToSessionObjectParser({required this.userId});

  String _id([String prefix = 'id']) =>
      '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Parser] $msg');
  }

  // ---------------------------------------------------------------------------
  // REGEX DEFINITIONS
  // ---------------------------------------------------------------------------
  static final RegExp _sectionHeader = RegExp(
    r'^\s*(warm\s*up|main\s*set|pre\s*set|post\s*set|cool\s*down|kick\s*set|pull\s*set|drill\s*set|sprint\s*set|recovery|technique\s*set|main|warmup|cooldown)\b',
    caseSensitive: false,
  );

  static final RegExp _groupTag =
  RegExp(r"#group[:\-\s]*([A-Za-z0-9_ ]+?)(?=\s*[\d\'#]|$)", caseSensitive: false);

  static final RegExp _swimmerTag =
  RegExp(r"#swimmers?\s+([^#\n\r]+)", caseSensitive: false);

  static final RegExp _standaloneReps =
  RegExp(r'^\s*(\d+)\s*(?:x|rounds?)\s*$', caseSensitive: false);

  static final RegExp _inlineReps =
  RegExp(r'^\s*(\d+)\s*x\s*', caseSensitive: false);

  static final RegExp _distance = RegExp(r'^\s*(\d+)\s*([A-Za-z]{0,10})');
  static final RegExp _interval = RegExp(r'@?\s*(\d{1,2}):(\d{2})');

  static final RegExp _intensityIndex =
  RegExp(r'\bi\s*([1-5])\b', caseSensitive: false);

  static final RegExp _intensityWord = RegExp(
    r'\b(max|easy|moderate|hard|threshold|sp1|sp2|sp3|drill|race|racepace|rp)\b',
    caseSensitive: false,
  );

  static final RegExp _equipment = RegExp(r'\[(.*?)\]', caseSensitive: false);

  static final RegExp _subItemLine = RegExp(r'^(?:\s{2,}|[-•>]\s+)(.+)$');

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

  static final RegExp _kickWord = RegExp(r'\bkick(ing)?\b', caseSensitive: false);
  static final RegExp _pullWord = RegExp(r'\bpull(ing)?\b', caseSensitive: false);
  static final RegExp _drillWord = RegExp(r'\bdrill(s)?\b', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 MAIN ENTRY POINT
  // ---------------------------------------------------------------------------
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
          // 🔧 Do NOT add empty sections to configs
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

        _log("Flushed section '${snapshot.rawSetTypeHeaderFromText}' "
            "with ${currentItems.length} items, reps=$sectionReps, "
            "groups=${sectionGroups.join(',')}");

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
          final hdr = _sectionHeader.firstMatch(raw);
          if (hdr != null) {
            _log("Section header: '${hdr.group(0)}'");
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
              specificSwimmerIds: const [],
              specificGroupIds: const [],
              swimSet: SwimSet(
                setId: _id('set'),
                type: currentType,
                items: const [],
                assignedGroupNames: sectionGroups.toList(),
              ),
              rawSetTypeHeaderFromText: hdr.group(0),
              unparsedTextLines: const [],
            );
            continue;
          }

          final rep = _standaloneReps.firstMatch(raw);
          if (rep != null) {
            final val = int.tryParse(rep.group(1) ?? '1') ?? 1;
            sectionReps *= val;
            _log('Section reps now $sectionReps');
            continue;
          }

          final addedGroups = _extractGroups(raw);
          if (addedGroups.isNotEmpty) {
            sectionGroups.addAll(addedGroups);
            _log('Inline #group found: ${addedGroups.join(", ")}');
          }

          final addedSwimmers = _extractSwimmers(raw);
          if (addedSwimmers.isNotEmpty) {
            sectionSwimmers.addAll(addedSwimmers);
            _log('Inline #swimmers found: ${addedSwimmers.join(", ")}');
          }

          final subMatch = _subItemLine.firstMatch(raw);
          if (subMatch != null && currentItems.isNotEmpty) {
            final lastParent = currentItems.last;
            final existingSubItems = lastParent.subItems ?? const <SubItem>[];
            final sub = _parseSubItem(subMatch.group(1)!, existingSubItems.length);
            if (sub != null) {
              final updated = List<SubItem>.from(existingSubItems)..add(sub);
              currentItems[currentItems.length - 1] =
                  lastParent.copyWith(subItems: updated);
              _log("Added subitem '${subMatch.group(1)}'");
            }
            continue;
          }

          final item = _parseItem(raw, itemOrder);
          if (item != null) {
            currentConfig ??= SessionSetConfiguration(
              sessionSetConfigId: _id('ssc'),
              swimSetId: _id('swconf'),
              order: sectionCount,
              repetitions: 1,
              storedSet: false,
              coachId: userId,
              specificSwimmerIds: const [],
              specificGroupIds: const [],
              swimSet: SwimSet(
                setId: _id('set'),
                type: currentType,
                items: const [],
                assignedGroupNames: const [],
              ),
              rawSetTypeHeaderFromText: "(auto) ${currentType.name}",
              unparsedTextLines: const [],
            );
            currentItems.add(item);
            _log("Parsed item: '$raw'");
            itemOrder++;
          }
        } catch (e, st) {
          _log('Parser line error: "$raw" — $e\n$st');
        }
      }

      flushSection();
      _log("Completed parsing ${configs.length} sections");
      return configs;
    } catch (e, st) {
      _log('Critical failure in parse(): $e\n$st');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ITEM + SUBITEM PARSERS
  // ---------------------------------------------------------------------------
  SetItem? _parseItem(String raw, int order) {
    try {
      String line = raw.trim();
      if (line.isEmpty) return null;

      // Rest detection (e.g. "1:00 rest")
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
          stroke: null,
          interval: Duration(minutes: mm, seconds: ss),
          intensityZone: null,
          equipment: const [],
          itemNotes: 'Rest $mm:${ss.toString().padLeft(2, '0')}',
          rawTextLine: raw,
          subItems: const [],
        );
      }

      // Inline repetitions
      int reps = 1;
      final rm = _inlineReps.firstMatch(line);
      if (rm != null) {
        reps = int.tryParse(rm.group(1) ?? '1') ?? 1;
        line = line.substring(rm.end).trimLeft();
      }

      // Distance
      final dm = _distance.firstMatch(line);
      if (dm == null) return null;

      final dist = int.tryParse(dm.group(1) ?? '0') ?? 0;

      // Token found immediately after distance (could be unit or stroke)
      final trailing = (dm.group(2) ?? '').toLowerCase().trim();

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;
      if (_strokeMap.containsKey(trailing)) {
        // e.g., "50 fr"
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        // e.g., "50m", "50yd"
        unit = _parseUnit(trailing);
      }

      // Advance the line past the matched distance+token
      line = line.substring(dm.end).trimLeft();

      // Interval
      Duration? interval;
      final im = _interval.firstMatch(line);
      if (im != null) {
        final mm = int.parse(im.group(1)!);
        final ss = int.parse(im.group(2)!);
        interval = Duration(minutes: mm, seconds: ss);
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

      // Augment stroke from remaining tokens if still null
      for (final token in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[token.toLowerCase()];
      }

      // Swim way
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
            .where((e) => e.isNotEmpty)
            .toList();
        detectedEquipment = names.map(_mapEquipment).toList();
      }

      // Notes
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
      _log('Error in _parseItem(): "$raw" — $e\n$st');
      return null;
    }
  }

  SubItem? _parseSubItem(String raw, int order) {
    try {
      String line = raw.trim();

      final dm = _distance.firstMatch(line);
      final int? dist = dm != null ? int.tryParse(dm.group(1) ?? '0') : null;

      DistanceUnit unit = DistanceUnit.meters;
      Stroke? stroke;

      // Treat the token after distance as unit OR stroke (same as items)
      final trailing = (dm?.group(2) ?? '').toLowerCase().trim();
      if (_strokeMap.containsKey(trailing)) {
        stroke = _strokeMap[trailing];
      } else if (trailing.isNotEmpty) {
        unit = _parseUnit(trailing);
      }

      // If still no stroke, augment from remaining tokens
      for (final token in line.split(RegExp(r'\s+'))) {
        stroke ??= _strokeMap[token.toLowerCase()];
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
      final eq = _equipment.firstMatch(line);
      List<EquipmentType> detectedEquipment = [];
      if (eq != null) {
        final names = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
        detectedEquipment = names.map(_mapEquipment).toList();
      }

      // Notes
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
      _log('Error in _parseSubItem(): "$raw" — $e\n$st');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SUMMARY + HELPERS
  // ---------------------------------------------------------------------------
  ParsedSummary parseWithSummary(
      String? unparsedText, {
        String? sessionId,
        Iterable<String>? allGroupNames, // 👈 NEW (optional)
      }) {
    try {
      final configs = parse(unparsedText, sessionId: sessionId);
      final metersByGroup = <String, double>{};
      double totalMeters = 0;
      int totalItems = 0;

      // Normalize provided global group names (if any)
      final globalGroups = (allGroupNames ?? const <String>[])
          .map((g) => g.trim().toLowerCase())
          .where((g) => g.isNotEmpty)
          .toList();

      for (final config in configs) {
        final assigned = config.swimSet?.assignedGroupNames;
        final sectionGroups = (assigned != null && assigned.isNotEmpty)
            ? assigned.map((g) => g.trim().toLowerCase()).toList()
            : <String>[];

        for (final item in config.swimSet?.items ?? []) {
          final d = (item.itemDistance ?? 0).toDouble();
          final r = (item.itemRepetition ?? 1);
          final dist = d * r * (config.repetitions);

          totalItems++;
          if ((item.itemDistance ?? 0) > 0) totalMeters += dist;

          // ✅ Decide which groups to credit
          final groupsToCredit = sectionGroups.isNotEmpty
              ? sectionGroups
              : (globalGroups.isNotEmpty
              ? globalGroups
              : (metersByGroup.keys.isNotEmpty
              ? metersByGroup.keys.toList()
              : const <String>['all'])); // final fallback

          // Always keep a global 'all' total too
          final withAll = {...groupsToCredit, 'all'};

          for (final g in withAll) {
            final key = g.trim().toLowerCase();
            metersByGroup[key] = (metersByGroup[key] ?? 0) + dist;
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
      _log('Error in parseWithSummary(): $e\n$st');
      return ParsedSummary(
        metersByGroup: {},
        totalMeters: 0,
        totalItems: 0,
        totalSections: 0,
      );
    }
  }


  // ---------------------------------------------------------------------------
  // MAPPERS
  // ---------------------------------------------------------------------------
  DistanceUnit _parseUnit(String? u) {
    final s = (u ?? '').toLowerCase();
    if (s.startsWith('y')) return DistanceUnit.yards;
    if (s.startsWith('k')) return DistanceUnit.kilometers;
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
      default:
        return null;
    }
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
      .map((m) => (m.group(1) ?? '').trim())
      .where((x) => x.isNotEmpty)
      .toList();

  List<String> _extractSwimmers(String text) {
    final res = _swimmerTag.firstMatch(text);
    if (res == null) return [];
    return res
        .group(1)!
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  EquipmentType _mapEquipment(String name) {
    final n = name.toLowerCase().trim();
    for (final type in EquipmentType.values) {
      for (final kw in type.parsingKeywords) {
        if (n == kw.toLowerCase()) return type;
      }
    }
    for (final type in EquipmentType.values) {
      for (final kw in type.parsingKeywords) {
        if (kw.isNotEmpty && n.contains(kw.toLowerCase())) return type;
      }
    }
    return EquipmentType.other;
  }
}
