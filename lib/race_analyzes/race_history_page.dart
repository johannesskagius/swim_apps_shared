import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:swim_apps_shared/race_analyzes/race_comparison_page.dart';

import '../objects/race.dart';
import '../objects/user/coach.dart';
import '../objects/user/swimmer.dart';
import '../objects/user/user.dart';
import '../repositories/analyzes_repository.dart';
import '../repositories/user_repository.dart';

class RaceHistoryPage extends StatefulWidget {
  final String? brandIconAssetPath;
  final String? swimmerId;

  const RaceHistoryPage({super.key, this.brandIconAssetPath, this.swimmerId});

  @override
  State<RaceHistoryPage> createState() => _RaceHistoryPageState();
}

class _RaceHistoryPageState extends State<RaceHistoryPage> {
  final List<String> _selectedRaceIds = [];

  // State variables to manage user roles and selections
  AppUser? _currentUser;
  List<AppUser> _swimmers = [];
  String? _selectedSwimmerId;
  String? _swimmerName; // For displaying the name in the AppBar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<List<AppUser>> _getSwimmersForCoachLocal(String coachId) async {
    final firestore = FirebaseFirestore.instance;

    // 1️⃣ Fetch links for this coach
    final linkSnap = await firestore
        .collection('coach_swimmer_links')
        .where('coachId', isEqualTo: coachId)
        .get();

    final swimmerIds = linkSnap.docs
        .map((d) => d['swimmerId'] as String)
        .toSet();

    if (swimmerIds.isEmpty) return [];

    List<AppUser> swimmers = [];
    final batches = swimmerIds.chunked(10);

    // 2️⃣ Fetch swimmer user docs in batches
    for (final batch in batches) {
      final usersSnap = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (var doc in usersSnap.docs) {
        final user = AppUser.fromJson(doc.id, doc.data());
        if (user is Swimmer) swimmers.add(user);
      }
    }

    return swimmers;
  }

  /// Fetches data based on whether a specific swimmerId is provided or not.
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final userRepo = Provider.of<UserRepository>(context, listen: false);

    try {
      // --- MODIFICATION: Handle pre-selected swimmer ---
      // If a swimmer ID is provided via the widget, load that swimmer's context.
      if (widget.swimmerId != null) {
        final swimmer = await userRepo.getUserDocument(widget.swimmerId!);
        if (mounted) {
          setState(() {
            _selectedSwimmerId = widget.swimmerId;
            _swimmerName = swimmer?.name;
            _isLoading = false;
          });
        }
        return; // Bypass the rest of the logic
      }

      // --- Original logic for the generic history page ---
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final currentUser = await userRepo.getMyProfile();
      if (!mounted) return;

      // --- FIX: Restored missing logic for Coach role ---
      if (currentUser is Coach) {
        final swimmers = await _getSwimmersForCoachLocal(currentUser.id);
        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _swimmers = swimmers;
            _isLoading = false;
          });
        }
      } else if (currentUser is Swimmer) {
        setState(() {
          _currentUser = currentUser;
          _selectedSwimmerId = currentUser.id;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  void _toggleSelection(String raceId) {
    setState(() {
      if (_selectedRaceIds.contains(raceId)) {
        _selectedRaceIds.remove(raceId);
      } else {
        _selectedRaceIds.add(raceId);
      }
    });
  }

  void _navigateToComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaceComparisonPage(
          raceIds: List.from(_selectedRaceIds),
          brandIconAssetPath: widget.brandIconAssetPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raceRepository = Provider.of<AnalyzesRepository>(context);

    // --- MODIFICATION: Dynamic AppBar Title ---
    final appBarTitle = widget.swimmerId != null && _swimmerName != null
        ? '$_swimmerName\'s History'
        : 'Race History';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _buildBody(raceRepository),
      floatingActionButton: _selectedRaceIds.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'race_history_fab',
              onPressed: _navigateToComparison,
              label: Text(_selectedRaceIds.length == 1 ? 'View' : 'Compare'),
              icon: Icon(
                _selectedRaceIds.length == 1
                    ? Icons.details
                    : Icons.compare_arrows,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Builds the main body of the page based on the user's role and loading state.
  Widget _buildBody(AnalyzesRepository raceRepository) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.swimmerId != null) {
      return _buildRacesList(raceRepository, widget.swimmerId!);
    }

    if (_currentUser == null) {
      return const Center(
        child: Text('You must be logged in to view race history.'),
      );
    }

    // If the user is a coach, show a swimmer selector dropdown.
    if (_currentUser is Coach) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSwimmerId,
              hint: const Text('Select a Swimmer'),
              isExpanded: true,
              items: _swimmers.map((swimmer) {
                return DropdownMenuItem(
                  value: swimmer.id,
                  child: Text(swimmer.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSwimmerId = newValue;
                  _selectedRaceIds
                      .clear(); // Reset selection when swimmer changes
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          if (_swimmers.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'You do not have any swimmers assigned to you.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_selectedSwimmerId == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Please select a swimmer to view their race history.',
                ),
              ),
            )
          else
            Expanded(
              child: _buildRacesList(raceRepository, _selectedSwimmerId!),
            ),
        ],
      );
    }

    // If the user is a swimmer, directly show their race list.
    return _buildRacesList(raceRepository, _selectedSwimmerId!);
  }

  Widget _buildRacesList(AnalyzesRepository raceRepository, String userId) {
    return StreamBuilder<List<RaceAnalysis>>(
      stream: raceRepository.getStreamOfRacesForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No races found for this swimmer.'));
        }

        final races = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4 / 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: races.length,
                itemBuilder: (context, index) {
                  final race = races[index];
                  final isSelected = _selectedRaceIds.contains(race.id);
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildRaceTile(race, isSelected),
                  );
                },
              );
            } else {
              return ListView.builder(
                itemCount: races.length,
                itemBuilder: (context, index) {
                  final race = races[index];
                  final isSelected = _selectedRaceIds.contains(race.id);
                  return _buildRaceTile(race, isSelected);
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildRaceTile(RaceAnalysis race, bool isSelected) {
    final raceDateFormatted = race.raceDate != null
        ? DateFormat.yMMMd().format(race.raceDate!)
        : 'No Date';

    final strokeName = race.stroke?.name ?? 'Unknown Stroke';
    final titleText = '${race.raceName} $strokeName';
    final subtitleText = '${race.eventName ?? 'Practice'} • $raceDateFormatted';

    return ListTile(
      title: Text(titleText),
      subtitle: Text(subtitleText),
      onTap: () => _toggleSelection(race.id!),
      tileColor: isSelected
          ? Theme.of(context).primaryColor.withAlpha(15)
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : const Icon(Icons.circle_outlined),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

extension IterableChunk<T> on Iterable<T> {
  List<List<T>> chunked(int size) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < length; i += size) {
      chunks.add(skip(i).take(size).toList());
    }
    return chunks;
  }
}
