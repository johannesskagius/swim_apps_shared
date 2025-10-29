// TextToSessionObjectParser.dart
// Fully instrumented with Firebase Crashlytics, including section/item breadcrumbs,
// safe parsing of equipment + sub-items, and a summary helper.

import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

/// 🧠 Context-unaware parser for AI-generated swim text.
/// - Parses sections, items, sub-items, intervals, intensities, equipment.
/// - Adds deep Crashlytics breadcrumbs and error capture (non-fatal on line issues).
class TextToSessionObjectParser {
  final RegExp _lineBreak = RegExp(r'\r\n?|\n');
  static int _idCounter = 0;

  String _id([String prefix = 'id']) =>
      '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

  // --- REGEX DEFINITIONS ---
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

  // Lines starting with 2+ spaces or bullet symbols (-, •, >) become sub-items.
  static final RegExp _subItemLine = RegExp(r'^(?:\s{2,}|[-•>]\s+)(.+)$');

  // --- STROKE MAPPING ---
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
  // 🔹 MAIN ENTRY POINT (Crashlytics integrated, sync API)
  // ---------------------------------------------------------------------------
  List<SessionSetConfiguration> parse(String? unparsedText, {String? sessionId}) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';

    // Safe, non-blocking Crashlytics setup
    unawaited(FirebaseCrashlytics.instance.setUserIdentifier(userId));
    FirebaseCrashlytics.instance.log(
        '🧩 parse() start | user=$userId | session=${sessionId ?? 'none'}');

    try {
      if (unparsedText == null || unparsedText.trim().isEmpty) {
        FirebaseCrashlytics.instance.log('ℹ️ Empty input text — returning [].');
        return [];
      }

      final lines = unparsedText
          .split(_lineBreak)
          .map((l) => l.trimRight()) // keep right-side whitespace for bullet detection
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
        try {
          if (currentConfig == null) return;

          // Always keep what we saw for observability
          final snapshot = currentConfig!.copyWith(
            unparsedTextLines: List.from(unparsedBuffer),
          );

          if (currentItems.isEmpty) {
            FirebaseCrashlytics.instance.log(
                "🗂️ Flushing empty section '${snapshot.rawSetTypeHeaderFromText}' (kept header only)");
            configs.add(snapshot);
            // Reset collectors
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

          FirebaseCrashlytics.instance.log(
              "🗂️ Flushed section '${snapshot.rawSetTypeHeaderFromText}' with ${currentItems.length} items, reps=$sectionReps, groups=${sectionGroups.join(',')}");

          configs.add(done);

          // Reset collectors
          currentConfig = null;
          currentItems.clear();
          sectionReps = 1;
          sectionGroups.clear();
          sectionSwimmers.clear();
          unparsedBuffer.clear();
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(
            e,
            st,
            reason: 'flushSection() failed | user=$userId | session=$sessionId',
            fatal: false,
          );
        }
      }

      int sectionCount = 0;
      int itemOrder = 0;

      for (final raw in lines) {
        unparsedBuffer.add(raw);
        try {
          // SECTION
          final hdr = _sectionHeader.firstMatch(raw);
          if (hdr != null) {
            FirebaseCrashlytics.instance.log("📘 Section header: '${hdr.group(0)}'");
            flushSection(); // finish previous
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

          // STANDALONE REPETITION (e.g., "2x")
          final rep = _standaloneReps.firstMatch(raw);
          if (rep != null) {
            final val = int.tryParse(rep.group(1) ?? '1') ?? 1;
            sectionReps *= val;
            FirebaseCrashlytics.instance.log('🔁 Section reps now $sectionReps');
            continue;
          }

          // INLINE TAGS (rare but allowed)
          final addedGroups = _extractGroups(raw);
          if (addedGroups.isNotEmpty) {
            sectionGroups.addAll(addedGroups);
            FirebaseCrashlytics.instance.log(
                '🏷️ Inline #group found on content line: ${addedGroups.join(", ")}');
          }
          final addedSwimmers = _extractSwimmers(raw);
          if (addedSwimmers.isNotEmpty) {
            sectionSwimmers.addAll(addedSwimmers);
            FirebaseCrashlytics.instance.log(
                '🏷️ Inline #swimmers found on content line: ${addedSwimmers.join(", ")}');
          }

          // SUB-ITEM
          final subMatch = _subItemLine.firstMatch(raw);
          if (subMatch != null && currentItems.isNotEmpty) {
            final lastParent = currentItems.last;
            final existingSubItems = lastParent.subItems ?? const <SubItem>[];
            final sub = _parseSubItem(subMatch.group(1)!, existingSubItems.length);
            if (sub != null) {
              final updatedSubItems = List<SubItem>.from(existingSubItems)..add(sub);
              currentItems[currentItems.length - 1] =
                  lastParent.copyWith(subItems: updatedSubItems);
              FirebaseCrashlytics.instance.log(
                  "↳ Added subitem '${subMatch.group(1)}' under parent '${lastParent.rawTextLine ?? lastParent.itemNotes ?? '(unnamed)'}'");
            }
            continue;
          }

          // MAIN ITEM
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
            FirebaseCrashlytics.instance.log("🧱 Parsed item: '$raw'");
            itemOrder++;
          }
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(
            e,
            st,
            reason: 'Parser line error: "$raw" | user=$userId | session=$sessionId',
            fatal: false,
          );
        }
      }

      // Flush final section
      flushSection();

      if (kDebugMode) {
        final groups = configs.expand((c) => c.swimSet?.assignedGroupNames ?? []).toSet();
        debugPrint("✅ Parsed ${configs.length} sections, groups: $groups");
      }
      FirebaseCrashlytics.instance.log(
          "✅ Completed parsing ${configs.length} sections | user=$userId | session=${sessionId ?? 'none'}");

      return configs;
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason:
        'Critical failure in TextToSessionObjectParser.parse | user=$userId | session=$sessionId',
        fatal: true,
      );
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 🧩 ITEM PARSER
  // ---------------------------------------------------------------------------
  SetItem? _parseItem(String raw, int order) {
    try {
      String line = raw.trim();
      if (line.isEmpty) return null;

      // REST
      final restMatch =
      RegExp(r'(\d{1,2}):(\d{2})\s*rest', caseSensitive: false).firstMatch(line);
      if (restMatch != null) {
        final mm = int.tryParse(restMatch.group(1) ?? '0') ?? 0;
        final ss = int.tryParse(restMatch.group(2) ?? '0') ?? 0;
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
          itemNotes: 'Rest ${mm}:${ss.toString().padLeft(2, '0')}',
          rawTextLine: raw,
          subItems: const [],
        );
      }

      // REPETITIONS (inline, e.g., "4x100m ...")
      int reps = 1;
      final rm = _inlineReps.firstMatch(line);
      if (rm != null) {
        reps = int.tryParse(rm.group(1) ?? '1') ?? 1;
        line = line.substring(rm.end).trimLeft();
      }

      // DISTANCE
      final dm = _distance.firstMatch(line);
      if (dm == null) return null;
      final dist = int.tryParse(dm.group(1) ?? '0') ?? 0;
      DistanceUnit unit = _parseUnit(dm.group(2));
      line = line.substring(dm.end).trimLeft();

      // INTERVAL
      Duration? interval;
      final im = _interval.firstMatch(line);
      if (im != null) {
        final mm = int.tryParse(im.group(1) ?? '0') ?? 0;
        final ss = int.tryParse(im.group(2) ?? '0') ?? 0;
        interval = Duration(minutes: mm, seconds: ss);
        line = line.replaceFirst(im.group(0)!, '').trim();
      }

      // INTENSITY
      IntensityZone? zone;
      final iz = _intensityIndex.firstMatch(line);
      if (iz != null) {
        final idx = int.tryParse(iz.group(1) ?? '0') ?? 0;
        zone = _mapIntensityIndex(idx);
        line = line.replaceFirst(iz.group(0)!, '').trim();
      } else {
        final iw = _intensityWord.firstMatch(line);
        if (iw != null) {
          zone = _mapIntensityWord(iw.group(1)!);
          line = line.replaceFirst(iw.group(0)!, '').trim();
        }
      }

      // STROKE
      Stroke? stroke;
      for (final token in line.split(RegExp(r'\s+'))) {
        final st = _strokeMap[token.toLowerCase()];
        if (st != null) {
          stroke = st;
          break;
        }
      }

      // SWIM WAY
      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      // EQUIPMENT
      List<EquipmentType> detectedEquipment = [];
      final eq = _equipment.firstMatch(raw);
      if (eq != null) {
        final equipmentStrings = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
        detectedEquipment = equipmentStrings.map(_mapEquipment).toList();
        line = line.replaceFirst(eq.group(0)!, '').trim();
      }

      // NOTES (quoted)
      String? notes;
      final q = RegExp(r"'([^']+)'").firstMatch(raw);
      if (q != null) notes = q.group(1);

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
        subItems: const <SubItem>[],
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Error in _parseItem(): "$raw"',
        fatal: false,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🧩 SUB-ITEM PARSER
  // ---------------------------------------------------------------------------
  SubItem? _parseSubItem(String raw, int order) {
    try {
      String line = raw.trim();
      if (line.isEmpty) return null;

      // DISTANCE
      final dm = _distance.firstMatch(line);
      int? dist = dm != null ? int.tryParse(dm.group(1) ?? '0') : null;
      DistanceUnit unit = _parseUnit(dm?.group(2));

      // STROKE
      Stroke? stroke;
      for (final token in line.split(RegExp(r'\s+'))) {
        final st = _strokeMap[token.toLowerCase()];
        if (st != null) {
          stroke = st;
          break;
        }
      }

      // SWIM WAY
      SwimWay way = SwimWay.swim;
      if (_kickWord.hasMatch(line)) way = SwimWay.kick;
      if (_pullWord.hasMatch(line)) way = SwimWay.pull;
      if (_drillWord.hasMatch(line)) way = SwimWay.drill;

      // INTENSITY (optional)
      IntensityZone? zone;
      final iz = _intensityIndex.firstMatch(line);
      if (iz != null) {
        final idx = int.tryParse(iz.group(1) ?? '0') ?? 0;
        zone = _mapIntensityIndex(idx);
      } else {
        final iw = _intensityWord.firstMatch(line);
        if (iw != null) zone = _mapIntensityWord(iw.group(1)!);
      }

      // EQUIPMENT (optional)
      List<EquipmentType> detectedEquipment = [];
      final eq = _equipment.firstMatch(line);
      if (eq != null) {
        final equipmentStrings = eq
            .group(1)!
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
        detectedEquipment = equipmentStrings.map(_mapEquipment).toList();
      }

      // NOTES (quoted)
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
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Error in _parseSubItem(): "$raw"',
        fatal: false,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 LIGHTWEIGHT SUMMARY
  // ---------------------------------------------------------------------------
  ParsedSummary parseWithSummary(String? unparsedText, {String? sessionId}) {
    try {
      final configs = parse(unparsedText, sessionId: sessionId);
      final Map<String, double> metersByGroup = {};
      double totalMeters = 0;
      int totalItems = 0;

      for (final config in configs) {
        final groupNames = config.swimSet?.assignedGroupNames ?? ['all'];
        for (final item in config.swimSet?.items ?? []) {
          final double dist = (item.itemDistance.toDouble() *
              (item.itemRepetition ?? 1) *
              (config.repetitions));
          totalItems++;
          if (item.itemDistance > 0) totalMeters += dist;

          for (final g in groupNames) {
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
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Error in parseWithSummary()',
        fatal: false,
      );
      return ParsedSummary(
        metersByGroup: {},
        totalMeters: 0,
        totalItems: 0,
        totalSections: 0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 HELPERS
  // ---------------------------------------------------------------------------
  DistanceUnit _parseUnit(String? u) {
    final s = (u ?? '').toLowerCase();
    if (s.startsWith('y')) return DistanceUnit.yards;
    if (s.startsWith('k')) return DistanceUnit.kilometers;
    return DistanceUnit.meters;
  }

  IntensityZone? _mapIntensityIndex(int i) {
    switch (i) {
      case 1:
        return IntensityZone.i1;
      case 2:
        return IntensityZone.i2;
      case 3:
        return IntensityZone.i3;
      case 4:
        return IntensityZone.i4;
      case 5:
        return IntensityZone.max;
      default:
        return null;
    }
  }

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

  List<String> _extractGroups(String text) {
    final matches = _groupTag.allMatches(text);
    return matches
        .map((m) => (m.group(1) ?? '').trim())
        .where((x) => x.isNotEmpty)
        .toList();
  }

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

    // exact match
    for (final type in EquipmentType.values) {
      for (final kw in type.parsingKeywords) {
        if (n == kw.toLowerCase()) return type;
      }
    }

    // contains match for flexibility
    for (final type in EquipmentType.values) {
      for (final kw in type.parsingKeywords) {
        if (kw.isNotEmpty && n.contains(kw.toLowerCase())) return type;
      }
    }

    return EquipmentType.other;
  }
}
