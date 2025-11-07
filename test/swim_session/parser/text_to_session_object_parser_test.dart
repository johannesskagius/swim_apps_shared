import 'package:flutter_test/flutter_test.dart';
import 'package:swim_apps_shared/objects/intensity_zones.dart';
import 'package:swim_apps_shared/objects/planned/swim_set.dart';
import 'package:swim_apps_shared/objects/stroke.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/equipment.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/swim_way.dart';
import 'package:swim_apps_shared/swim_session/generator/text_to_session_parser.dart';

void main() {
  const testUserId = 'test_user_123';
  late TextToSessionObjectParser parser;

  setUp(() {
    parser = TextToSessionObjectParser(userId: testUserId);
  });

  group('TextToSessionObjectParser basic parsing', () {
    test('returns empty list for null or blank input', () {
      expect(parser.parse(null), isEmpty);
      expect(parser.parse('   '), isEmpty);
    });

    test('parses a simple warm-up section', () {
      const input = '''
Warm up
4x50 fr @1:00 i2
''';

      final configs = parser.parse(input);

      expect(configs, hasLength(1));
      final conf = configs.first;
      expect(conf.coachId, equals(testUserId));
      expect(conf.swimSet, isA<SwimSet>());
      expect(conf.swimSet!.type?.name.toLowerCase(), contains('warm'));
      expect(conf.swimSet!.items, hasLength(1));

      final item = conf.swimSet!.items.first;
      expect(item.itemDistance, equals(50));
      expect(item.itemRepetition, equals(4));
      expect(item.interval, equals(const Duration(minutes: 1)));
      expect(item.stroke, equals(Stroke.freestyle));
      expect(item.intensityZone, equals(IntensityZone.i2));
    });

    test('detects multiple sections correctly', () {
      const input = '''
Warm up
4x50 fr @1:00 i2

Main set
3x100 fr @1:40 i3
''';
      final configs = parser.parse(input);
      expect(configs, hasLength(2));
      expect(configs[0].swimSet!.type?.name, contains('warm'));
      expect(configs[1].swimSet!.type?.name, contains('main'));
    });

    test('parses inline group and swimmer tags', () {
      const input = '''
Main set #group A #swimmers John, Lisa
4x50 fr i1
''';
      final configs = parser.parse(input);
      expect(configs, hasLength(1));
      final conf = configs.first;
      expect(conf.swimSet!.assignedGroupNames, contains('a'));
      expect(conf.specificSwimmerIds, contains('John'));
      expect(conf.specificSwimmerIds, contains('Lisa'));
    });

    test('handles sub-items correctly', () {
      const input = '''
Main set
3x100 fr
  25 kick
  25 drill
''';
      final configs = parser.parse(input);
      expect(configs, hasLength(1));
      final parent = configs.first.swimSet!.items.first;
      expect(parent.subItems, hasLength(2));
      expect(parent.subItems![0].swimWay, equals(SwimWay.kick));
      expect(parent.subItems![1].swimWay, equals(SwimWay.drill));
    });

    test('parses rest lines correctly', () {
      const input = '''
Main set
1:00 rest
''';
      final configs = parser.parse(input);
      final item = configs.first.swimSet!.items.first;
      expect(item.swimWay, equals(SwimWay.rest));
      expect(item.itemNotes, contains('Rest 1:00'));
    });

    test('correctly detects equipment and notes', () {
      const input = '''
Main set
4x50 fr [fins,paddle] 'descend 1-4'
''';
      final configs = parser.parse(input);
      final item = configs.first.swimSet!.items.first;
      expect(item.equipment, contains(EquipmentType.fins));
      expect(item.itemNotes, contains('descend'));
    });
  });

  group('TextToSessionObjectParser summary generation', () {
    test('produces valid ParsedSummary totals', () {
      const input = '''
Warm up
4x50 fr i1

Main set
2x100 fr i3
''';
      final summary = parser.parseWithSummary(input);
      expect(summary.totalSections, equals(2));
      expect(summary.totalItems, equals(2));
      expect(summary.totalMeters, closeTo(400, 1)); // 600m total
      expect(summary.metersByGroup['all'], equals(400));
    });

    test('handles empty summary gracefully', () {
      final summary = parser.parseWithSummary('');
      expect(summary.totalMeters, equals(0));
      expect(summary.totalItems, equals(0));
      expect(summary.metersByGroup, isEmpty);
    });
  });

  group('Edge cases', () {
    test('handles invalid numeric values gracefully', () {
      const input = '''
Main set
x50 fr
''';
      final configs = parser.parse(input);
      expect(configs, isEmpty);
    });

    test('handles section with standalone repetition line', () {
      const input = '''
Main set
2x
4x25 fly
''';
      final configs = parser.parse(input);
      expect(configs, hasLength(1));
      expect(configs.first.repetitions, equals(2));
    });

    test('ignores unknown tokens safely', () {
      const input = '''
Main set
100 randomword @2:00
''';
      final configs = parser.parse(input);
      expect(configs.first.swimSet!.items.first.stroke, isNull);
    });
  });
}
