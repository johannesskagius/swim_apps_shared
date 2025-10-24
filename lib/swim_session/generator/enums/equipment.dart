// Define enums (ideally in their own file or a shared types file)
import 'package:flutter/material.dart';

enum EquipmentType {
  none('No equipment'),
  kickboard('Kickboard'),
  fins('Fins'),
  paddles('Large paddles'),
  largePaddles('Large paddles'),
  mediumPaddles('Medium paddles'),
  smallPaddles('Small paddles'),
  fingerPaddles('Finger paddles'),
  pullBuoy('Pullbouy'),
  snorkel('Snorch'),
  tempoTrainer('Tempo trainer'),
  resistanceBand('Resistance band'),
  parachute('Parachute'),
  wristWeights('Wrist weight'),
  ankleWeights(
    'Ankle weight',
  ), // Could be distinct from general resistance bands for ankles
  weightedVest('Weighted west'), // Or chest weights, vest is more common term
  weightBelt(
    'Weighted belt',
  ), // For adding weights, often for diving or resistance
  other('Other'),
  band('Band'),
  powerRack('Power Rack'),
  sponge('Sponge');

  final String description;

  const EquipmentType(this.description);
}

// Extension for display properties
extension EquipmentTypeDisplayHelper on EquipmentType {
  Color get displayColor {
    // Define a good-sized palette for variety
    final List<Color> palette = [
      Colors.blueGrey[600]!,
      Colors.brown[400]!,
      Colors.deepOrange[400]!,
      Colors.indigo[400]!,
      Colors.lime[700]!,
      Colors.pink[300]!,
      Colors.teal[400]!,
      Colors.amber[600]!,
      Colors.cyan[700]!,
      Colors.green[600]!,
      Colors.purple[400]!,
      Colors.red[500]!,
      Colors.lightBlue[400]!,
      Colors.orange[700]!,
      Colors.yellow[700]!,
      Colors.grey[600]!,
      // Add more colors if needed to avoid too much repetition with many enum values
      Colors.blueAccent[200]!,
      Colors.redAccent[100]!,
      Colors.greenAccent[400]!,
      Colors.purpleAccent[100]!,
    ];

    switch (this) {
      // Specific assignments for common/key equipment
      // case EquipmentType.noEquipment:
      //   return Colors
      //       .grey; // Or Colors.grey[300] if you want it visible but neutral
      case EquipmentType.kickboard:
        return Colors.amber[500]!;
      case EquipmentType.fins:
        return Colors.blue[500]!;
      case EquipmentType.pullBuoy:
        return Colors.green[500]!;
      case EquipmentType
          .paddles: // Generic paddles - for cases where it's not specified by size
        return Colors
            .red[400]!; // Assuming you might have a generic 'paddles' type
      // If not, and it's always sized, this case might not be hit.
      // For now, I'm assigning colors to your specific sized paddles.
      case EquipmentType.largePaddles:
        return Colors.red[700]!;
      case EquipmentType.mediumPaddles:
        return Colors.red[500]!;
      case EquipmentType.smallPaddles:
        return Colors.red[300]!;
      case EquipmentType.fingerPaddles:
        return Colors.pink[400]!;
      case EquipmentType.snorkel:
        return Colors.cyan[400]!;
      case EquipmentType.band:
        return Colors.orange[600]!;
      case EquipmentType.resistanceBand:
        return Colors.deepOrange[500]!;
      case EquipmentType.parachute:
        return Colors.blueGrey[500]!;
      case EquipmentType.tempoTrainer:
        return Colors.purple[500]!;
      case EquipmentType.sponge:
        return Colors.brown[500]!;
      case EquipmentType.wristWeights:
        return palette[0];
      case EquipmentType.ankleWeights:
        return palette[1];
      case EquipmentType.weightedVest:
        return palette[2];
      case EquipmentType.weightBelt:
        return palette[3];
      case EquipmentType.powerRack:
        return palette[4];
      case EquipmentType.other:
        return Colors.grey[500]!;
      case EquipmentType.none:
        return Colors.black;
    }
  }
}

enum SkillLevel { beginner, intermediate, advanced, allLevels }

extension EquipmentTypeParsingHelper on EquipmentType {
  List<String> get parsingKeywords {
    switch (this) {
      case EquipmentType.paddles:
        return ['paddles', 'pads', 'paddle']; // Added specifics
      case EquipmentType.mediumPaddles:
        return [
          'm pads',
          'm paddle',
          'm paddles',
          'm paddles',
        ]; // Added specifics
      case EquipmentType.fins:
        return ['fins', 'fz', 'zoomies', 'fin', 'zoomers'];
      case EquipmentType.pullBuoy:
        return [
          'pullbuoy',
          'pb',
          'buoy',
          'pull buoy', // Added space
        ]; // Removed 'pull' to avoid conflict with SwimWays.pull
      case EquipmentType.snorkel:
        return ['snorkel', 'snork', 'sn', 'center snorkel', 'centre snorkel'];
      case EquipmentType.band: // Often refers to ankle band
        return ['band', 'ankleband', 'ankle band', 'leg band'];
      case EquipmentType.kickboard:
        return ['kickboard', 'board', 'kb', 'kick board']; // Added space
      case EquipmentType.tempoTrainer:
        return ['tempo trainer', 'tt', 'tempo', 'metronome'];
      case EquipmentType.parachute:
        return ['parachute', 'chute', 'para'];

      // Previously commented out, now implemented:
      //   case EquipmentType.dragSox: // If you have this enum value
      //     return ['drag sox', 'sox', 'drag socks', 'socks'];
      //   case EquipmentType.antiPaddles: // If you have this enum value
      //     return ['anti paddles', 'anti-paddles', 'anti pads', 'antipaddles'];

      // Add other equipment
      case EquipmentType.largePaddles:
        return [
          'l paddles',
          'l pads',
          'l paddle',
          'large paddles',
          'big paddles',
        ];
      case EquipmentType.smallPaddles:
        return ['s paddles', 's pads', 's paddle', 'small paddles'];
      case EquipmentType.fingerPaddles:
        return [
          'f paddles',
          'f pads',
          'f paddle',
          'finger paddles',
          'fin paddles',
          // 'fin' could conflict if not careful with parser ordering
          'fingertip paddles',
        ];
      case EquipmentType.resistanceBand: // Could be for in-water or dryland
        return [
          'resistance band',
          'res band',
          'stretch cords',
          'stretchcordz',
          'power band',
          'strength band',
          'theraband',
          // Depending on common usage
        ];
      case EquipmentType.wristWeights:
        return ['wrist weights', 'wrist wt', 'ww'];
      case EquipmentType.ankleWeights:
        return ['ankle weights', 'ankle wt', 'aw'];
      case EquipmentType.weightedVest:
        return ['weighted vest', 'weight vest', 'vest'];
      case EquipmentType.weightBelt:
        return [
          'weight belt',
          'aqua belt',
          'flotation belt',
        ]; // If used for flotation too

      // --- Added Examples for more equipment ---
      case EquipmentType.powerRack: // If you add this enum for tower systems
        return ['power rack', 'tower', 'power tower', 'rack'];
      case EquipmentType.sponge: // Common drag equipment
        return ['sponge', 'drag sponge'];

      case EquipmentType.other:
        return [
          'other',
          'misc',
        ]; // Keep this minimal, rely on parser logic for exclusion.
      // case EquipmentType.noEquipment:
      //   return [''];
      case EquipmentType.none:
        return [''];
    }
  }

  // You also mentioned: // Ensure toShortDisplayString() exists on your EquipmentType enum
  // This would be used for generating text, rather than parsing.
  String toShortDisplayString() {
    switch (this) {
      case EquipmentType.mediumPaddles:
        return "Pads (M)";
      case EquipmentType.fins:
        return "Fins";
      case EquipmentType.pullBuoy:
        return "PB";
      case EquipmentType.snorkel:
        return "Snorkel";
      case EquipmentType.band:
        return "Band";
      case EquipmentType.kickboard:
        return "KB";
      case EquipmentType.tempoTrainer:
        return "TT";
      case EquipmentType.parachute:
        return "Chute";
      case EquipmentType.largePaddles:
        return "Pads (L)";
      case EquipmentType.smallPaddles:
        return "Pads (S)";
      case EquipmentType.fingerPaddles:
        return "Pads (F)";
      case EquipmentType.resistanceBand:
        return "ResBand";
      case EquipmentType.wristWeights:
        return "WristWt";
      case EquipmentType.ankleWeights:
        return "AnkleWt";
      case EquipmentType.weightedVest:
        return "WtVest";
      case EquipmentType.weightBelt:
        return "WtBelt";
      //case EquipmentType.dragSox: return "Sox";
      //case EquipmentType.antiPaddles: return "AntiPads";
      case EquipmentType.powerRack:
        return "PwrRack";
      case EquipmentType.sponge:
        return "Sponge";
      case EquipmentType.other:
        return "Other";
      // case EquipmentType.noEquipment:
      //   return "No equipment";
      case EquipmentType.paddles:
        return "Paddles";
      case EquipmentType.none:
        return 'No equipment';
    }
  }
}
