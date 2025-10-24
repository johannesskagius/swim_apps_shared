

class SessionGeneratorService {
  /*
  final _uuid = const Uuid();
  final _random = Random();

  // Changed to AdvancedGeneratorConfig as it's typically used internally
  // and holds selectedTrainingFocus. If the constructor needs the base
  // GeneratorConfig for some reason, this can be adjusted.
  // For now, assuming the service is instantiated with the full config it needs.
  // AdvancedGeneratorConfig? config; // Made nullable if not always present at construction

  late final List<MainSetPatternRegistration> _registeredMainSetPatterns;

  // Constructor updated to expect AdvancedGeneratorConfig if that's what's consistently used.
  // If the service is long-lived and config changes per generation, generateSession will take it.
  // For _initializeRegisteredPatterns, it doesn't need config.
  SessionGeneratorService() {
    _initializeRegisteredPatterns();
  }

  void _initializeRegisteredPatterns() {
    // These registrations should list IMainSetPattern instances directly
    _registeredMainSetPatterns = [
      MainSetPatternRegistration(
        name: 'Aerobic Capacity Options',
        suitableFocuses: [SessionFocus.aerobicEndurance, SessionFocus.mixed],
        minDistance: 400,
        maxDistance: 3000,
        suitablePatterns: [
          PyramidPattern(),
          LocoPattern(allowKick: true, allowDrills: true),
          AscendingLadderPattern(),
          DescendingLadderPattern(),
          CruiseIntervalSetPattern(repeatDistance: 100),
        ],
      ),
      MainSetPatternRegistration(
        name: 'Threshold Endurance Options',
        suitableFocuses: [SessionFocus.thresholdEndurance, SessionFocus.mixed],
        minDistance: 300,
        maxDistance: 2500,
        suitablePatterns: [
          PyramidPattern(),
          LocoPattern(allowDrills: true, allowKick: true),
          CruiseIntervalSetPattern(repeatDistance: 100),
          CruiseIntervalSetPattern(repeatDistance: 200),
          // VariableDistanceRoundsPattern( // Example complex pattern
          //   componentsPerRound: [
          //     VariableDistanceRoundsPattern(100, Stroke.freestyle, SwimWay.swim),
          //     VariableDistanceRoundsPatternComponent(50, Stroke.choice, SwimWay.kick),
          //   ],
          //   roundsMultiplierBasedOnDistance: true,
          // )
        ],
      ),
      MainSetPatternRegistration(
        name: 'Race Pace Speed Options',
        suitableFocuses: [SessionFocus.racePaceSpeed, SessionFocus.mixed],
        minDistance: 200,
        maxDistance: 1200,
        suitablePatterns: [
          CruiseIntervalSetPattern(repeatDistance: 50),
          CruiseIntervalSetPattern(repeatDistance: 100),
          // Potentially add ShortRestSprintPattern if you have it
        ],
      ),
      MainSetPatternRegistration(
        name: 'Max Velocity Sprint Options',
        suitableFocuses: [SessionFocus.maxVelocitySprint],
        minDistance: 100,
        maxDistance: 800,
        suitablePatterns: [
          CruiseIntervalSetPattern(repeatDistance: 25),
          CruiseIntervalSetPattern(repeatDistance: 15),
          // Potentially add ShortRestSprintPattern for 15s/25s
        ],
      ),
      MainSetPatternRegistration(
        name: 'Technique & Drill Options',
        suitableFocuses: [
          SessionFocus.technique,
          SessionFocus.recovery,
          SessionFocus.mixed,
        ],
        minDistance: 100,
        maxDistance: 1000,
        suitablePatterns: [
          CruiseIntervalSetPattern(repeatDistance: 50),
          LocoPattern(allowDrills: true, allowKick: true),
          // Configure Loco for technique
        ],
      ),
    ];
  }

  // REPLACES getSelectableUserFocuses()
  List<TrainingFocus> availableTrainingFocuses() {
    return [
      MixedFocus(),
      //AerobicEnduranceFocus(),
      // Assuming ThresholdEnduranceFocus exists
      // ThresholdEnduranceFocus(),
      RacePaceSpeedFocus(),
      // Assuming MaxVelocitySprintFocus exists
      MaxVelocitySprintFocus(),
      TechniqueFocus(),
      IMFocus(),
      RecoveryFocus(),
    ];
  }

  SwimSession generateSession(AdvancedGeneratorConfig currentConfig) {
    int targetTotalDistanceMeters;

    if (currentConfig.mode == 'distance') {
      targetTotalDistanceMeters = _convertToMeters(
        currentConfig.totalDistance!,
        currentConfig.targetDistanceUnit,
      );
    } else {
      final estimatedPlayableTime = Duration(
        minutes: (currentConfig.timeLimitMinutes! * 0.85).round(),
      );
      targetTotalDistanceMeters = _calculateDistance(
        estimatedPlayableTime,
        currentConfig.averageIntervalPer100m,
        currentConfig.targetDistanceUnit,
      ); // Use targetDistanceUnit for calc consistency
    }

    if (targetTotalDistanceMeters < 400) {
      throw Exception(
        "Total distance/time too short for a meaningful swim_session (min 400m or equivalent time).",
      );
    }

    int warmupDistance = 0;
    int cooldownDistance = 0;

    // Use selectedTrainingFocus if available to get the SessionFocus enum
    // config.focus should ideally be set correctly in AdvancedGeneratorConfig constructor
    // based on selectedTrainingFocus.sessionFocusEnum
    SessionFocus sessionFocusEnum = currentConfig.focus;

    if (currentConfig.includeWarmup) {
      warmupDistance =
          (targetTotalDistanceMeters *
                  _getWarmupPercentage(
                    sessionFocusEnum,
                    currentConfig.difficulty,
                  ))
              .roundToNearest(50);
      warmupDistance = max(200, min(warmupDistance, 800));
    }
    if (currentConfig.includeCooldown) {
      cooldownDistance =
          (targetTotalDistanceMeters * _getCooldownPercentage(sessionFocusEnum))
              .roundToNearest(50);
      cooldownDistance = max(100, min(cooldownDistance, 400));
    }

    int mainSetTargetDistance =
        targetTotalDistanceMeters - warmupDistance - cooldownDistance;
    if (mainSetTargetDistance < 200) {
      if (warmupDistance > 200) warmupDistance = max(200, warmupDistance - 100);
      if (cooldownDistance > 100) {
        cooldownDistance = max(100, cooldownDistance - 50);
      }
      mainSetTargetDistance =
          targetTotalDistanceMeters - warmupDistance - cooldownDistance;
      if (mainSetTargetDistance < 200) {
        throw Exception(
          "Not enough distance/time for a main set after allocating warmup/cooldown.",
        );
      }
    }
    mainSetTargetDistance = mainSetTargetDistance.roundToNearest(50);

    List<SwimSet> generatedSets = [];

    // Warmup Generation
    if (currentConfig.includeWarmup && warmupDistance > 0) {
      if (currentConfig.selectedTrainingFocus != null &&
          currentConfig.selectedTrainingFocus!.overrideDefaultWarmup) {
        generatedSets.add(
          currentConfig.selectedTrainingFocus!.generateWarmupSet(
            warmupDistance,
            currentConfig,
            this,
          ),
        );
      } else {
        generatedSets.addAll(
          _generateDefaultWarmupSets(
            warmupDistance,
            currentConfig,
            sessionFocusEnum,
          ),
        );
      }
    }

    // Main Set Generation (using the new method)
    generatedSets.addAll(
      _generateMainSets(mainSetTargetDistance, currentConfig),
    );

    // Cooldown Generation
    if (currentConfig.includeCooldown && cooldownDistance > 0) {
      if (currentConfig.selectedTrainingFocus != null &&
          currentConfig.selectedTrainingFocus!.overrideDefaultCooldown) {
        generatedSets.add(
          currentConfig.selectedTrainingFocus!.generateCooldownSet(
            cooldownDistance,
            currentConfig,
            this,
          ),
        );
      } else {
        generatedSets.addAll(
          _generateDefaultCooldownSets(
            cooldownDistance,
            currentConfig,
            sessionFocusEnum,
          ),
        );
      }
    }

    int currentOrder = 0;
    final setConfigurations = generatedSets.map((swimSet) {
      return SessionSetConfiguration(
        sessionSetConfigId: _uuid.v4(),
        swimSetId: swimSet.setId,
        order: currentOrder++,
        repetitions: 1,
        storedSet: false,
        coachId: currentConfig.coachId ?? '',
        swimSet: swimSet,
        unparsedTextLines: [],
        specificSwimmerIds: [],
        specificGroupIds: [],
      );
    }).toList();

    int finalSessionDistance = setConfigurations.fold<int>(
      0,
      (sum, sc) => sum + (sc.swimSet?.totalSetDistance ?? 0) * sc.repetitions,
    );
    String sessionTitle =
        currentConfig.selectedTrainingFocus?.name ?? sessionFocusEnum.name;

    return SwimSession(
      id: _uuid.v4(),
      title:
          '$sessionTitle Session - ${_convertFromMeters(finalSessionDistance, currentConfig.targetDistanceUnit)}${currentConfig.targetDistanceUnit.name}',
      date: currentConfig.sessionDate,
      coachId: currentConfig.coachId ?? '',
      distanceUnit: currentConfig.targetDistanceUnit,
      setConfigurations: setConfigurations,
      createdAt: DateTime.now(),
      sessionSlot: _getSessionSlot(currentConfig.sessionDate),
      //: finalSessionDistance,
      sets: [],
    );
  }

  // REMOVED _mapTrainingFocusToEnum as AdvancedGeneratorConfig should handle this
  // The 'focus' field in AdvancedGeneratorConfig should be the source SessionFocus enum.
  // Or, `currentConfig.selectedTrainingFocus!.sessionFocusEnum` can be used directly.

  double _getWarmupPercentage(
    SessionFocus focus,
    SessionDifficulty difficulty,
  ) {
    if (focus == SessionFocus.maxVelocitySprint ||
        focus == SessionFocus.racePaceSpeed)
      return 0.25;
    if (difficulty == SessionDifficulty.hard) return 0.20;
    return 0.15;
  }

  double _getCooldownPercentage(SessionFocus focus) {
    if (focus == SessionFocus.recovery) return 0.15;
    return 0.10;
  }

  // Renamed from _generateWarmupSets to avoid conflict if TrainingFocus has its own
  List<SwimSet> _generateDefaultWarmupSets(
    int totalWarmupDist,
    AdvancedGeneratorConfig config,
    SessionFocus currentFocus,
  ) {
    List<SwimSet> warmupSets = [];
    List<SetItem> items = [];
    int remainingDist = totalWarmupDist;
    int actualWarmupDistanceUsed = 0;
    int dist1 = min(remainingDist, (totalWarmupDist * 0.4).roundToNearest(50));
    if (dist1 >= 100) {
      items.add(
        createSetItem(
          itemDistance: dist1,
          repeats: 1,
          stroke: Stroke.choice,
          swimWay: SwimWay.swim,
          interval: config.averageIntervalPer100m,
          //0,8
          notes: "Easy continuous swim",
          intensity: IntensityZone.i2,
          config: config,
        ),
      );
      remainingDist -= dist1;
      actualWarmupDistanceUsed += dist1;
    }
    int dist2 = min(remainingDist, (totalWarmupDist * 0.35).roundToNearest(50));
    if (dist2 >= 100) {
      int reps = (dist2 / 100).floor();
      reps = max(1, reps);
      int kickDist = 50 * reps;
      int drillDist = 50 * reps;
      items.add(
        createSetItem(
          itemDistance: 50,
          repeats: reps,
          stroke: Stroke.choice,
          swimWay: SwimWay.kick,
          equipment: _pickEquipment([
            EquipmentType.kickboard,
          ], config.availableEquipment),
          interval: config.averageIntervalPer100m,
          //0,6,
          intensity: IntensityZone.i2,
          config: config,
        ),
      );
      items.add(
        createSetItem(
          itemDistance: 50,
          repeats: reps,
          stroke: _getRandomPreferredOrDefaultStroke(
            config,
            focus: currentFocus,
          ),
          swimWay: SwimWay.drill,
          interval: config.averageIntervalPer100m,
          //0,65,
          notes: "Technique focus",
          intensity: IntensityZone.i2,
          config: config,
        ),
      );
      remainingDist -= (kickDist + drillDist);
      actualWarmupDistanceUsed += (kickDist + drillDist);
    }
    if (remainingDist >= 100) {
      int buildDistance = remainingDist.roundToNearest(50);
      int reps = (buildDistance / 50).floor();
      reps = max(2, reps);
      int itemDist = 50;
      if (reps * itemDist > buildDistance && buildDistance >= itemDist) {
        reps = (buildDistance / itemDist).floor();
      }
      if (reps * itemDist > 0) {
        items.add(
          createSetItem(
            itemDistance: itemDist,
            repeats: reps,
            stroke: Stroke.freestyle,
            swimWay: SwimWay.swim,
            interval: config.averageIntervalPer100m.multiply(
              1.1 * (remainingDist / 100.0) * 0.9,
            ),
            notes: "Build pace 1-$reps",
            intensity: IntensityZone.i3,
            config: config,
          ),
        );
        remainingDist -= (reps * itemDist);
        actualWarmupDistanceUsed += (reps * itemDist);
      }
    }
    if (remainingDist > 0) {
      items.add(
        createSetItem(
          itemDistance: remainingDist,
          repeats: 1,
          stroke: Stroke.choice,
          swimWay: SwimWay.swim,
          interval: config.averageIntervalPer100m.multiply(
            1.1 * (remainingDist / 100.0),
          ),
          intensity: IntensityZone.i2,
          config: config,
        ),
      );
      actualWarmupDistanceUsed += remainingDist;
    }
    if (items.isNotEmpty) {
      warmupSets.add(
        createSwimSet(
          SetType.warmUp,
          items,
          "Warm-up",
          totalSetDistance: actualWarmupDistanceUsed,
        ),
      );
    }
    return warmupSets;
  }

  List<SwimSet> _generateDefaultCooldownSets(
    int totalCooldownDist,
    AdvancedGeneratorConfig config,
    SessionFocus currentFocus,
  ) {
    List<SetItem> items = [];
    int remainingDist = totalCooldownDist;
    int actualCooldownDistanceUsed = 0;
    int dist1 = min(
      remainingDist,
      (totalCooldownDist * 0.6).roundToNearest(50),
    );
    if (dist1 >= 50) {
      items.add(
        createSetItem(
          itemDistance: dist1,
          repeats: 1,
          stroke: Stroke.choice,
          swimWay: SwimWay.swim,
          interval: config.averageIntervalPer100m.multiply(
            1.25 * (remainingDist / 100.0),
          ),
          notes: "Very easy recovery",
          intensity: IntensityZone.i1,
          config: config,
        ),
      );
      remainingDist -= dist1;
      actualCooldownDistanceUsed += dist1;
    }
    if (remainingDist >= 50) {
      items.add(
        createSetItem(
          itemDistance: remainingDist,
          repeats: 1,
          stroke: _getRandomPreferredOrDefaultStroke(
            config,
            focus: SessionFocus.recovery,
          ),
          swimWay: SwimWay.drill,
          interval: config.averageIntervalPer100m.multiply(
            1.3 * (remainingDist / 100.0),
          ),
          notes: "Easy technique",
          intensity: IntensityZone.i1,
          config: config,
        ),
      );
      actualCooldownDistanceUsed += remainingDist;
      remainingDist = 0;
    }
    if (items.isEmpty && totalCooldownDist > 0) {
      items.add(
        createSetItem(
          itemDistance: totalCooldownDist,
          repeats: 1,
          stroke: Stroke.choice,
          swimWay: SwimWay.swim,
          interval: config.averageIntervalPer100m.multiply(
            1.1 * (remainingDist / 100.0),
          ),
          notes: "Easy cooldown",
          intensity: IntensityZone.i1,
          config: config,
        ),
      );
      actualCooldownDistanceUsed += totalCooldownDist;
    }
    if (items.isNotEmpty) {
      return [
        createSwimSet(
          SetType.coolDown,
          items,
          "Cool-down",
          totalSetDistance: actualCooldownDistanceUsed,
        ),
      ];
    }
    return [];
  }

  List<SwimSet> _generateMainSets(
    int totalMainDist,
    AdvancedGeneratorConfig currentConfig,
  ) {
    if (totalMainDist <= 0) return [];

    if (currentConfig.selectedTrainingFocus == null) {
      print(
        "[SessionGeneratorService] Error: No selectedTrainingFocus in config. Falling back for main set.",
      );
      return [_genericFallbackPattern(totalMainDist, currentConfig, this)];
    }

    // Get broadly suitable patterns based on the SessionFocus enum derived from the selected TrainingFocus
    SessionFocus derivedSessionFocus =
        currentConfig.selectedTrainingFocus!.sessionFocusEnum;

    List<IMainSetPattern> broadlySuitablePatterns = _registeredMainSetPatterns
        .where(
          (reg) =>
              reg.isSuitable(totalMainDist, currentConfig, derivedSessionFocus),
        )
        .expand((reg) => reg.suitablePatterns)
        .toSet()
        .toList();

    if (broadlySuitablePatterns.isEmpty) {
      print(
        "[SessionGeneratorService] No broadly suitable registered patterns found for ${derivedSessionFocus.name}. Trying all registered patterns.", // Assuming displayName extension
      );
      broadlySuitablePatterns = _registeredMainSetPatterns
          .expand((reg) => reg.suitablePatterns)
          .toSet()
          .toList();
    }
    if (broadlySuitablePatterns.isEmpty) {
      print(
        "[SessionGeneratorService] Still no patterns after trying all registered. Critical fallback for main set.",
      );
      return [_genericFallbackPattern(totalMainDist, currentConfig, this)];
    }

    List<IMainSetPattern> focusFilteredPatterns = currentConfig
        .selectedTrainingFocus!
        .filterMainSetPatterns(
          allPatterns: broadlySuitablePatterns,
          targetDistance: totalMainDist,
          config: currentConfig,
        );

    if (focusFilteredPatterns.isNotEmpty) {
      final selectedPatternInstance =
          focusFilteredPatterns[_random.nextInt(focusFilteredPatterns.length)];
      print(
        "[SessionGeneratorService] Selected Main Set Pattern by ${currentConfig.selectedTrainingFocus!.name}: ${selectedPatternInstance.name}",
      );
      try {
        return [
          selectedPatternInstance.generate(totalMainDist, currentConfig),
          // Pass service 'this'
        ];
      } catch (e, s) {
        print(
          "Error generating main set with pattern '${selectedPatternInstance.name}': $e\n$s",
        );
        return [_genericFallbackPattern(totalMainDist, currentConfig, this)];
      }
    } else {
      print(
        "No suitable patterns found by ${currentConfig.selectedTrainingFocus!.name} for $totalMainDist m main set. Falling back.",
      );
      return [_genericFallbackPattern(totalMainDist, currentConfig, this)];
    }
  }

  SwimSet _genericFallbackPattern(
    int totalDistance,
    AdvancedGeneratorConfig config,
    SessionGeneratorService service,
  ) {
    final fallbackCruisePattern = CruiseIntervalSetPattern(
      baseDistance: 100,
      minRepeats: 1,
      maxRepeats: (totalDistance / 100).floor(),
      repeatDistance: 100,
      // Explicitly set if required by CruiseIntervalPattern
    );
    if (fallbackCruisePattern.canGenerate(totalDistance, config)) {
      try {
        print(
          "[SessionGeneratorService] Using generic fallback CruiseIntervalSetPattern for main set.",
        );
        return fallbackCruisePattern.generate(totalDistance, config);
      } catch (e, s) {
        print("Error in generic fallback pattern (CruiseInterval): $e\n$s");
      }
    }
    // Last resort: very simple set
    print(
      "[SessionGeneratorService] Critical fallback: creating minimal placeholder main set.",
    );
    SetItem placeholderItem = service.createSetItem(
      repeats: 1,
      itemDistance: totalDistance.roundToNearest(50),
      stroke: Stroke.freestyle,
      swimWay: SwimWay.swim,
      interval: config.averageIntervalPer100m.multiply(
        totalDistance.roundToNearest(50) / 100.0 * 1.1,
      ),
      // Sligthly easier
      config: config,
      intensity: IntensityZone.i2,
      notes: "Generic fallback set item",
    );
    return service.createSwimSet(
      SetType.mainSet,
      [placeholderItem],
      "Fallback Main Set",
      totalSetDistance: placeholderItem.itemDistance,
    );
  }

  SetItem createSetItem({
    required int repeats,
    required int itemDistance,
    required Stroke stroke,
    required Duration interval,
    required AdvancedGeneratorConfig config, // Use AdvancedGeneratorConfig
    SwimWay swimWay = SwimWay.swim,
    List<EquipmentType>? equipment,
    IntensityZone? intensity,
    String? notes,
    int? rounds, // Added for consistency with IMainSetPattern usage
  }) {
    // Distance conversion handled by SwimSet total distance, itemDistance should be in meters
    // int displayDistance = _convertFromMeters(itemDistance, config.targetDistanceUnit);

    return SetItem(
      id: _uuid.v4(),
      // order: 0, // Order is set when adding to SwimSet or by pattern
      itemRepetition: repeats,
      itemDistance: itemDistance,
      // Store in meters internally
      distanceUnit: DistanceUnit.meters,
      // Internal items are always meters
      stroke: stroke,
      swimWay: swimWay,
      equipment: equipment ?? [],
      intensityZone: intensity,
      interval: interval,
      itemNotes: notes,
      order: 0,
      subItems: null,
    );
  }

  SwimSet createSwimSet(
    SetType type,
    List<SetItem> items,
    String customName, {
    int? totalSetDistance,
  }) {
    int calculatedTotalDistanceMeters = 0;
    List<SetItem> orderedItems = [];
    for (int i = 0; i < items.length; i++) {
      orderedItems.add(items[i].copyWith(order: i));
      calculatedTotalDistanceMeters +=
          (items[i].itemDistance ?? 1) * (items[i].itemRepetition ?? 1);
    }

    return SwimSet(
      setId: _uuid.v4(),
      type: type,
      customTypeName: (type == SetType.custom || type == SetType.mainSet)
          ? customName
          : type.name,
      // Use enum name for others
      items: orderedItems,
      totalSetDistance: totalSetDistance ?? calculatedTotalDistanceMeters,
      // This is in meters
      setNotes: null,
    );
  }

  Stroke _getRandomPreferredOrDefaultStroke(
    AdvancedGeneratorConfig advancedConfig, {
    bool allowChoice = true,
    SessionFocus? focus, // Added focus to guide stroke selection
  }) {
    List<Stroke> choices = [];
    if (advancedConfig.preferredStrokes != null &&
        advancedConfig.preferredStrokes!.isNotEmpty) {
      choices.addAll(advancedConfig.preferredStrokes!);
    }

    SessionFocus currentFocus =
        focus ?? advancedConfig.focus; // Use passed in focus or config's focus

    if (choices.isEmpty) {
      // If no user preferred strokes, use focus-based defaults
      if (currentFocus == SessionFocus.maxVelocitySprint ||
          currentFocus == SessionFocus.racePaceSpeed)
        choices.add(Stroke.freestyle);
      else if (currentFocus == SessionFocus.aerobicEndurance ||
          currentFocus == SessionFocus.thresholdEndurance) {
        choices.addAll([
          Stroke.freestyle,
        ]); // pullbuoy might need to be equipment
      } else {
        choices.addAll([
          Stroke.freestyle,
          Stroke.backstroke,
          Stroke.breaststroke,
        ]);
      }
    }
    if (allowChoice && _random.nextInt(5) == 0) return Stroke.choice;
    if (choices.isEmpty) return Stroke.freestyle; // Absolute fallback

    return choices[_random.nextInt(choices.length)];
  }

  List<EquipmentType>? _pickEquipment(
    List<EquipmentType> preferred,
    List<EquipmentType>? available,
  ) {
    if (available == null || available.isEmpty) return null;
    List<EquipmentType> canUse = preferred
        .where((p) => available.contains(p))
        .toList();
    if (canUse.isNotEmpty) return [canUse[_random.nextInt(canUse.length)]];
    return null;
  }

  int _calculateDistance(
    Duration totalDuration,
    Duration intervalPer100m,
    DistanceUnit unitForOutput,
  ) {
    if (totalDuration.isNegative || totalDuration.inSeconds == 0) return 0;
    if (intervalPer100m.inSeconds == 0) return 0;
    final double hundreds = totalDuration.inSeconds / intervalPer100m.inSeconds;
    int distanceMeters = (hundreds * 100).round();
    // Calculation is done in meters, then converted for output if necessary by the caller (_convertFromMeters)
    // Here, we just return the calculated meters, rounded appropriately.
    return distanceMeters.roundToNearest(
      unitForOutput == DistanceUnit.meters ? 25 : 25,
    );
  }

  int _convertToMeters(int distance, DistanceUnit fromUnit) {
    if (fromUnit == DistanceUnit.yards) return (distance * 0.9144).round();
    if (fromUnit == DistanceUnit.kilometers) return distance * 1000;
    return distance;
  }

  int _convertFromMeters(int distanceMeters, DistanceUnit toUnit) {
    if (toUnit == DistanceUnit.yards) return (distanceMeters / 0.9144).round();
    if (toUnit == DistanceUnit.kilometers) {
      return (distanceMeters / 1000.0).round();
    }
    return distanceMeters;
  }

  SessionSlot _getSessionSlot(DateTime date) {
    if (date.hour < 12) return SessionSlot.morning;
    if (date.hour < 17) return SessionSlot.afternoon;
    return SessionSlot.afternoon; // Corrected
  }*/
}
