import 'package:swim_apps_shared/swim_apps_shared.dart';

class SpeedFocus extends TrainingFocus {
  static const int maxPureSpeedVolumeSP1 = 400;
  static const int maxPureSpeedVolumeSP2 = 600;
  static const int maxPureSpeedVolumeSP3 = 800;

  @override
  String get name => 'Speed';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.sp1,
    IntensityZone.sp2,
    IntensityZone.sp3,
    IntensityZone.max,
    IntensityZone.racePace,
  ];

  @override
  String generatePrompt() => """
You are designing a **Speed-focused swim session**.

Key principles:
- Emphasize short, explosive efforts (15–50m) at maximum velocity.
- Prioritize full recovery between reps (1:3 to 1:6 work-rest ratio).
- Use total sprint volume between $maxPureSpeedVolumeSP1–$maxPureSpeedVolumeSP3 meters.
- Keep technique sharp and avoid fatigue deterioration.
- Integrate short resisted sprints or assisted speed when possible.
- Warm-up includes activation drills and short progressive accelerations.
- Main set builds towards maximum velocity segments.
- Cool-down must be easy and promote recovery.

Preferred intensity zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}.
""";
}
