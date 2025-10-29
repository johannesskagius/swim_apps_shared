import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/generator/parsed_summary.dart';
import '../../objects/intensity_zones.dart';
import '../../objects/planned/set_item.dart';
import '../../objects/planned/swim_set.dart';
import '../../objects/planned/swim_set_config.dart';
import '../../objects/planned/sub_item.dart';
import '../../objects/stroke.dart';
import 'enums/distance_units.dart';
import 'enums/set_types.dart';
import 'enums/swim_way.dart';

/// 🧠 Context-unaware parser for AI-generated swim text.
/// It makes no assumptions about coach, swimmers, or Firestore state.
/// Input:  raw text (String)
/// Output: list of SessionSetConfigurations with SwimSets & SetItems
class TextToSessionObjectParser {
  final RegExp _lineBreak = RegExp(r'\r\n?|\n');
  static int _idCounter = 0;
  String _id([String prefix = 'id']) =>
      '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

  // --- SECTION HEADERS ---
  static final RegExp _sectionHeader = RegExp(
    r"^\s*(warm\s*up|main\s*set|cool\s*down|pre\s*set|post\s*set|kick\s*set|pull\s*set|drill\s*set|sprint\s*set|recovery|technique\s*set|main|warmup|cooldown)\b",
    caseSensitive: false,
  );

  // --- TAGS ---
  static final RegExp _groupTag = RegExp(
    r"#group[:\-\s]*([A-Za-z0-9_ ]+?)(?=\s*[\d\'#]|$)",
    caseSensitive: false,
  );
  static final RegExp _swimmerTag = RegExp(
    r"#swimmers?\s+([^#\n\r]+)",
    caseSensitive: false,
  );

  // --- REPETITIONS ---
  static final RegExp _standaloneReps =
  RegExp(r"^\s*(\d+)\s*(?:x|rounds?)\s*$", caseSensitive: false);
  static final RegExp _inlineReps =
  RegExp(r"^\s*(\d+)\s*x\b", caseSensitive: false);

  // --- DISTANCE ---
  static final RegExp _distance = RegExp(r"^\s*(\d+)\s*([A-Za-z]{0,10})");

  // --- INTERVAL ---
  static final RegExp _interval = RegExp(r"@?\s*(\d{1,2}):(\d{2})");

  // --- INTENSITY ---
  static final RegExp _intensityIndex =
  RegExp(r"\bi\s*([1-5])\b", caseSensitive: false);
  static final RegExp _intensityWord = RegExp(
    r"\b(max|easy|moderate|hard|threshold|sp1|sp2|sp3|drill|race|racepace|rp)\b",
    caseSensitive: false,
  );

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

  static final RegExp _kickWord = RegExp(r"\bkick(ing)?\b", caseSensitive: false);
  static final RegExp _pullWord = RegExp(r"\bpull(ing)?\b", caseSensitive: false);
  static final RegExp _drillWord = RegExp(r"\bdrill(s)?\b", caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 MAIN ENTRY POINT
  // ---------------------------------------------------------------------------
  List<SessionSetConfiguration> parse(String? unparsedText) {
    if (unparsedText == null || unparsedText.trim().isEmpty) return [];

    final lines = unparsedText
        .split(_lineBreak)
        .map((l) => l.trim())
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
      if (currentItems.isEmpty) {
        if ((currentConfig!.rawSetTypeHeaderFromText ?? '').isNotEmpty) {
          configs.add(currentConfig!);
        }
        return;
      }

      final swimSet = (currentConfig!.swimSet ??
          SwimSet(setId: _id('set'), type: currentType, items: const []))
          .copyWith(
        items: List.from(currentItems),
        assignedGroupNames: sectionGroups.toList(),
      );

      configs.add(currentConfig!.copyWith(
        repetitions: sectionReps,
        swimSet: swimSet,
        specificGroupIds: sectionGroups.toList(),
        specificSwimmerIds: sectionSwimmers.toList(),
        unparsedTextLines: List.from(unparsedBuffer),
      ));

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

      // 🧩 SECTION HEADER
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
          coachId: "",
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

      // 🧩 STANDALONE REPETITION (e.g., "2x")
      final rep = _standaloneReps.firstMatch(raw);
      if (rep != null) {
        sectionReps *= int.tryParse(rep.group(1) ?? '1') ?? 1;
        continue;
      }

      // 🧩 INLINE TAGS
      sectionGroups.addAll(_extractGroups(raw));
      sectionSwimmers.addAll(_extractSwimmers(raw));

      // 🧩 PARSE ITEM
      final item = _parseItem(raw, itemOrder);
      if (item != null) {
        currentConfig ??= SessionSetConfiguration(
          sessionSetConfigId: _id('ssc'),
          swimSetId: _id('swconf'),
          order: sectionCount,
          repetitions: 1,
          storedSet: false,
          coachId: "",
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
        itemOrder++;
      }
    }

    flushSection();

    if (kDebugMode) {
      final groups =
      configs.expand((c) => c.swimSet?.assignedGroupNames ?? []).toSet();
      debugPrint(
          "✅ Parsed ${configs.length} sections, groups: $groups");
      for (final c in configs) {
        debugPrint(
            "🧩 Parsed config: ${c.swimSet?.type?.name ?? 'No type'}, groups=${c.swimSet?.assignedGroupNames}, items=${c.swimSet?.items.length}");
      }
    }

    return configs;
  }

  // ---------------------------------------------------------------------------
  // 🧩 ITEM PARSER
  // ---------------------------------------------------------------------------
  SetItem? _parseItem(String raw, int order) {
    String line = raw.trim();
    if (line.isEmpty) return null;

    // reps
    int reps = 1;
    final rm = _inlineReps.firstMatch(line);
    if (rm != null) {
      reps = int.tryParse(rm.group(1) ?? '1') ?? 1;
      line = line.substring(rm.end).trimLeft();
    }

    // distance
    final dm = _distance.firstMatch(line);
    if (dm == null) return null;
    final dist = int.tryParse(dm.group(1) ?? '0') ?? 0;
    DistanceUnit unit = _parseUnit(dm.group(2));
    line = line.substring(dm.end).trimLeft();

    // interval
    Duration? interval;
    final im = _interval.firstMatch(line);
    if (im != null) {
      final mm = int.tryParse(im.group(1) ?? '0') ?? 0;
      final ss = int.tryParse(im.group(2) ?? '0') ?? 0;
      interval = Duration(minutes: mm, seconds: ss);
      line = line.replaceFirst(im.group(0)!, '').trim();
    }

    // intensity
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

    // stroke
    Stroke? stroke;
    for (final token in line.split(RegExp(r'\s+'))) {
      final st = _strokeMap[token.toLowerCase()];
      if (st != null) {
        stroke = st;
        break;
      }
    }

    // swimway
    SwimWay? way;
    if (_kickWord.hasMatch(line)) way = SwimWay.kick;
    if (_pullWord.hasMatch(line)) way = SwimWay.pull;
    if (_drillWord.hasMatch(line)) way = SwimWay.drill;
    way ??= SwimWay.swim;

    // notes
    String? notes;
    final q = RegExp(r"'([^']*)'").firstMatch(raw);
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
      equipment: const [],
      itemNotes: notes,
      rawTextLine: raw,
      subItems: const <SubItem>[],
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 LIGHTWEIGHT SUMMARY
  // ---------------------------------------------------------------------------
  ParsedSummary parseWithSummary(String? unparsedText) {
    if (unparsedText == null || unparsedText.trim().isEmpty) {
      return ParsedSummary(
        metersByGroup: {},
        totalMeters: 0,
        totalItems: 0,
        totalSections: 0,
      );
    }

    final configs = parse(unparsedText);
    final Map<String, double> metersByGroup = {};
    double totalMeters = 0;
    int totalItems = 0;

    for (final config in configs) {
      final groupNames = config.swimSet?.assignedGroupNames ?? ["All"];
      for (final item in config.swimSet?.items ?? []) {
        final double dist = (item.itemDistance.toDouble() *
            (item.itemRepetition ?? 1) *
            (config.repetitions));

        totalMeters += dist;
        totalItems++;

        // ✅ normalized group key
        for (final g in groupNames) {
          final key = g.trim().toLowerCase();
          metersByGroup[key] = (metersByGroup[key] ?? 0) + dist;
        }

        for (final sub in item.subItems) {
          final subDist = (sub.subItemDistance.toDouble() *
              (config.repetitions) *
              (item.itemRepetition ?? 1));
          totalMeters += subDist;
          for (final g in groupNames) {
            final key = g.trim().toLowerCase();
            metersByGroup[key] = (metersByGroup[key] ?? 0) + subDist;
          }
        }
      }
    }

    return ParsedSummary(
      metersByGroup: metersByGroup,
      totalMeters: totalMeters,
      totalItems: totalItems,
      totalSections: configs.length,
    );
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
}
