import 'package:flutter_test/flutter_test.dart';
import 'package:swim_apps_shared/objects/intensity_zones.dart';
import 'package:swim_apps_shared/objects/stroke.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/equipment.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/set_types.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/swim_way.dart';
import 'package:swim_apps_shared/swim_session/generator/text_to_session_parser.dart';

void main() {
  const testUserId = 'user_test';
  late TextToSessionObjectParser parser;

  setUp(() {
    parser = TextToSessionObjectParser(userId: testUserId);
  });

  // ---------------------------------------------------------------------------
  // SECTION HEADERS + STRUCTURE
  // ---------------------------------------------------------------------------

  group('Section parsing', () {
    test('parses warmup, main set, cooldown', () {
      const input = '''
Warm up
4x50 fr

Main Set
4x100 fr

Cool Down
200 easy
''';

      final configs = parser.parse(input);

      expect(configs.length, 3);
      expect(configs[0].swimSet!.type, SetType.warmUp);
      expect(configs[1].swimSet!.type, SetType.mainSet);
      expect(configs[2].swimSet!.type, SetType.coolDown);
    });

    test('handles malformed section headers gracefully', () {
      const input = '''
Warm upper body
4x50 fr
''';

      // Should treat "Warm upper body" as NOT a header → falls into default "main"
      final configs = parser.parse(input);
      expect(configs.length, 1);
      expect(configs.first.swimSet!.type, SetType.mainSet);
    });
  });

  // ---------------------------------------------------------------------------
  // REPETITIONS
  // ---------------------------------------------------------------------------

  group('Repetition parsing', () {
    test('parses inline reps 4x100', () {
      const input = '''
Main set
4x100 fr
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.itemRepetition, 4);
      expect(item.itemDistance, 100);
    });

    test('parses standalone section reps 2x', () {
      const input = '''
Main set
2x
4x50 fr
''';
      final conf = parser.parse(input).first;
      expect(conf.repetitions, 2);
    });

    test('multiplies inline reps with section reps', () {
      const input = '''
Main set
2x
4x25 fr
''';

      final summary = parser.parseWithSummary(input);
      // dist = 4 * 25 * 2 = 200
      expect(summary.totalMeters, 200);
    });

    test('handles weird spacing in reps', () {
      const input = '''
Main set
4 x 100 fr
''';

      final conf = parser.parse(input).first;
      final item = conf.swimSet!.items.first;

      // inlineReps should match "4 x 100"
      expect(item.itemRepetition, 4);
      expect(item.itemDistance, 100);
    });
    test('standalone reps are still recognized even when auto-indented', () {
      // Simulate what autoIndent produces:
      // Two spaces before 2x
      const input = '''
Main set
  2x
  4x50 fr
''';

      final conf = parser.parse(input).first;

      // Repetitions must still be parsed correctly
      expect(conf.repetitions, 2);

      // And item should still have reps applied (2 × 4 × 50 = 400)
      final summary = parser.parseWithSummary(input);
      expect(summary.totalMeters, 400);
    });

    test('standalone reps remain valid with tabs or mixed whitespace', () {
      const input = '''
Main set
\t2x
  4x25 fr
''';

      final conf = parser.parse(input).first;

      // standalone repetition still recognized
      expect(conf.repetitions, 2);

      // inline × standalone multiplication still correct (2 × (4 × 25))
      final summary = parser.parseWithSummary(input);
      expect(summary.totalMeters, 200);
    });
  });

  // ---------------------------------------------------------------------------
  // DISTANCE + INTERVAL + INTENSITY
  // ---------------------------------------------------------------------------

  group('Distance / Interval / Intensity parsing', () {
    test('interval with @', () {
      const input = '''
Main set
100 fr @1:20
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.interval, const Duration(minutes: 1, seconds: 20));
    });

    test('interval without @', () {
      const input = '''
Main set
100 fr 1:40
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.interval, const Duration(minutes: 1, seconds: 40));
    });

    test('intensity i1-i5', () {
      const input = '''
Main set
50 fr i3
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.intensityZone, IntensityZone.i3);
    });

    test('intensity words', () {
      const input = '''
Main set
50 fr easy
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.intensityZone, IntensityZone.i1);
    });

    test('handles distance like "50fr" without spacing', () {
      const input = '''
Main set
4x50fr
''';
      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.itemDistance, 50);
      expect(item.stroke, Stroke.freestyle);
    });
  });

  // ---------------------------------------------------------------------------
  // STROKE DETECTION
  // ---------------------------------------------------------------------------

  group('Stroke parsing', () {
    test('parses butterfly', () {
      const input = '''
Main set
50 fly
''';
      final stroke = parser.parse(input).first.swimSet!.items.first.stroke;
      expect(stroke, Stroke.butterfly);
    });

    test('parses IM', () {
      const input = '''
Main set
100 IM
''';
      final stroke = parser.parse(input).first.swimSet!.items.first.stroke;
      expect(stroke, Stroke.medley);
    });
  });

  // ---------------------------------------------------------------------------
  // SUB-ITEMS
  // ---------------------------------------------------------------------------

  group('Sub-item parsing', () {
    test('detects indented subitems', () {
      const input = '''
Main set
100 fr
  25 kick
  25 drill
''';

      final parent = parser.parse(input).first.swimSet!.items.first;
      expect(parent.subItems!.length, 2);
      expect(parent.subItems![0].swimWay, SwimWay.kick);
      expect(parent.subItems![1].swimWay, SwimWay.drill);
    });

    test('detects bullet and arrow subitems', () {
      const input = '''
Main set
100 fr
- 25 kick
> 25 drill
''';

      final parent = parser.parse(input).first.swimSet!.items.first;
      expect(parent.subItems!.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // REST LINES
  // ---------------------------------------------------------------------------

  group('Rest line parsing', () {
    test('parses rest correctly', () {
      const input = '''
Main set
1:00 rest
''';

      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.swimWay, SwimWay.rest);
      expect(item.itemNotes, contains('Rest'));
    });
  });

  // ---------------------------------------------------------------------------
  // EQUIPMENT
  // ---------------------------------------------------------------------------

  group('Equipment parsing', () {
    test('parses equipment list', () {
      const input = '''
Main set
4x50 fr [fins,paddles]
''';

      final item = parser.parse(input).first.swimSet!.items.first;

      expect(item.equipment, contains(EquipmentType.fins));
      expect(item.equipment, contains(EquipmentType.paddles));
    });

    test('parses spaced equipment list', () {
      const input = '''
Main set
50 fr [ fins , snorkel ]
''';

      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.equipment, contains(EquipmentType.fins));
      expect(item.equipment, contains(EquipmentType.snorkel));
    });
  });

  // ---------------------------------------------------------------------------
  // GROUPS & SWIMMERS
  // ---------------------------------------------------------------------------

  group('Group & swimmer tagging', () {
    test('reads #group tags', () {
      const input = '''
Main set #group A #group B
4x50 fr
''';

      final conf = parser.parse(input).first;
      expect(conf.swimSet!.assignedGroupNames, contains('a'));
      expect(conf.swimSet!.assignedGroupNames, contains('b'));
    });

    test('reads #swimmers tags', () {
      const input = '''
Main set #swimmers Anna,Bob
4x50 fr
''';

      final names = parser.parse(input).first.specificSwimmerIds;
      expect(names, contains('Anna'));
      expect(names, contains('Bob'));
    });
  });

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  group('Summary generation', () {
    test('computes totalMeters correctly', () {
      const input = '''
Warm up
4x50 fr

Main set
3x100 fr
''';

      final summary = parser.parseWithSummary(input);

      // 4x50 = 200, 3x100 = 300 → total = 500
      expect(summary.totalMeters, equals(500));
      expect(summary.metersByGroup['all'], equals(500));
    });

    test('Section reps affect summary', () {
      const input = '''
Main set
2x
4x25 fr
''';

      final summary = parser.parseWithSummary(input);
      expect(summary.totalMeters, equals(200));
    });
  });

  // ---------------------------------------------------------------------------
  // EDGE CASES + NOISE
  // ---------------------------------------------------------------------------

  group('Edge cases / robustness', () {
    test('ignores random noise safely', () {
      const input = '''
Main set
100 fr @1:30 !! @@ ??? RANDOMTEXT
''';

      final item = parser.parse(input).first.swimSet!.items.first;
      expect(item.itemDistance, 100);
      expect(item.interval, const Duration(minutes: 1, seconds: 30));
    });

    test('ignores lines without distance', () {
      const input = '''
Main set
this line has no distance
4x50 fr
''';

      final items = parser.parse(input).first.swimSet!.items;
      expect(items.length, 1);
    });

    test('handles lowercase, uppercase, and mixed strokes', () {
      const input = '''
Main set
50 FreE
50 BR
50 bK
''';

      final items = parser.parse(input).first.swimSet!.items;

      expect(items[0].stroke, Stroke.freestyle);
      expect(items[1].stroke, Stroke.breaststroke);
      expect(items[2].stroke, Stroke.backstroke);
    });
  });

  // ---------------------------------------------------------------------------
  // COMPLEX REAL-WORLD EXAMPLE
  // ---------------------------------------------------------------------------

  test('Large realistic mixed workout parses without errors', () {
    const input = '''
Warm up
4x100 fr i1
8x50 drill
200 IM easy

Pre set #group Senior
4x50 kick @1:10
4x25 fly i3

Main set #group A #swimmers John,Lisa
2x
4x100 fr @1:20 i3
4x50 br  @0:55 i4
4x25 fly @0:30 max

Cool down
200 easy
''';

    final configs = parser.parse(input);
    expect(configs.length, 4); // warmup, preset, mainset, cooldown

    final summary = parser.parseWithSummary(input);
    expect(summary.totalMeters, greaterThan(0));
    expect(summary.totalMeters, greaterThan(1000));
  });
}
