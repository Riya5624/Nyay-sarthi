import 'dart:async';
import 'package:flutter/material.dart';
import '/services/api_service.dart';

/// A sophisticated dashboard for Person 1: The Investigator.
/// This screen simulates an automated evidence processing workflow.
class InvestigatorScreen extends StatefulWidget {
  const InvestigatorScreen({Key? key}) : super(key: key);

  @override
  _InvestigatorScreenState createState() => _InvestigatorScreenState();
}

class _InvestigatorScreenState extends State<InvestigatorScreen> {
  // --- State Variables ---
  
  // Holds the list of all suspects fetched from the backend.
  List<Map<String, dynamic>> _suspects = [];
  bool _isLoadingDb = true; // True while fetching the initial database.
  bool _isSearching = false; // True during the scanning and API call process.

  // A simulated queue of incoming evidence hashes to be processed.
  final List<String> _evidenceQueue = [
    'F7E8-D9C0-B1A2', // Match for Jane Smith
    'FAKE-HASH-0000', // No Match
    'A1B2-C3D4-E5F6', // Match for John Doe
    '1234-5678-ABCD', // Match for Peter Jones
    'ANOTHER-FAKE-HASH', // No Match
  ];
  int _currentEvidenceIndex = 0; // Tracks our position in the queue.

  // Holds the API response after a search is complete.
  Map<String, dynamic>? _searchResult;
  // Used to highlight the final matched suspect in the list.
  String? _highlightedSuspectId;
  // Used for the visual "scanning" animation.
  String? _scannedSuspectId;

  @override
  void initState() {
    super.initState();
    // Fetch the database as soon as the screen loads.
    _fetchSuspectDatabase();
  }

  /// Fetches the entire suspect list from the backend to display it.
  Future<void> _fetchSuspectDatabase() async {
    final response = await ApiService.getSuspectDatabase();
    if (mounted && response['status'] == 'success') {
      setState(() {
        _suspects = List<Map<String, dynamic>>.from(response['data']);
        _isLoadingDb = false;
      });
    }
  }

  /// Processes the next evidence item from the queue.
  Future<void> _processNextEvidence() async {
    if (_isSearching) return; // Prevent multiple clicks
    if (_currentEvidenceIndex >= _evidenceQueue.length) {
      // Optional: Reset the queue for continuous demo.
      setState(() => _currentEvidenceIndex = 0);
    }

    final hashToProcess = _evidenceQueue[_currentEvidenceIndex];
    setState(() {
      _searchResult = null;
      _highlightedSuspectId = null;
      _isSearching = true;
    });

    // --- Visual Scanning Animation ---
    // This loop creates the effect of the system checking each suspect.
    for (final suspect in _suspects) {
      if (!mounted) return;
      setState(() => _scannedSuspectId = suspect['id']);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // Clear the scanning highlight before showing the final result.
    if (mounted) {
      setState(() => _scannedSuspectId = null);
    }
    // --- End Animation ---

    // Now, make the actual API call.
    final response = await ApiService.findSuspectByHash(hashToProcess);
    
    if (mounted) {
      setState(() {
        _searchResult = response;
        if (response['status'] == 'success') {
          // If a match is found, set the ID to be highlighted permanently.
          _highlightedSuspectId = response['data']['id'];
        }
        _isSearching = false;
        _currentEvidenceIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Processing Dashboard')),
      // Show a loading spinner only for the initial database fetch.
      body: _isLoadingDb
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildControlPanel(),
                const SizedBox(height: 24),
                _buildDatabasePanel(),
                const SizedBox(height: 24),
                _buildResultsPanel(),
              ],
            ),
    );
  }

  // ===================================================================
  // UI Builder Helper Widgets
  // ===================================================================

  /// Builds the top card with the current evidence and processing button.
  Widget _buildControlPanel() {
    String currentHash = _currentEvidenceIndex < _evidenceQueue.length
        ? _evidenceQueue[_currentEvidenceIndex]
        : "Queue Empty";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Processing Queue", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.secondary),
              title: Text("Current Evidence Hash:", style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(currentHash, style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _processNextEvidence,
                icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.biotech),
                label: Text(_isSearching ? 'SEARCHING...' : 'PROCESS NEXT EVIDENCE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds the panel that displays the list of all suspects.
  Widget _buildDatabasePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text("Suspect Database", style: Theme.of(context).textTheme.titleLarge),
        ),
        // Use a SizedBox to give the ListView a fixed height,
        // making the overall layout more stable.
        SizedBox(
          height: 250,
          child: ListView.builder(
            itemCount: _suspects.length,
            itemBuilder: (context, index) {
              final suspect = _suspects[index];
              return _SuspectCard(
                suspect: suspect,
                isMatch: _highlightedSuspectId == suspect['id'],
                isScanning: _scannedSuspectId == suspect['id'],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the panel that shows the final search result.
  Widget _buildResultsPanel() {
    // Don't show anything while the scanning animation is still in its final phase.
    if (_isSearching && _scannedSuspectId == null) {
      return const SizedBox.shrink();
    }
    // If no search has been run yet.
    if (_searchResult == null) {
      return const Card(
        elevation: 0,
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text("Awaiting evidence processing..."),
        ),
      );
    }
    // If a match was found.
    if (_searchResult!['status'] == 'success') {
      return _MatchFoundCard(suspect: _searchResult!['data']);
    } else {
      // If no match was found.
      return Card(
          elevation: 4,
          color: Colors.orange.withOpacity(0.2),
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.orangeAccent),
              borderRadius: BorderRadius.circular(8)),
          child: const ListTile(
            leading: Icon(Icons.error_outline, color: Colors.orangeAccent),
            title: Text("No Match Found"),
            subtitle: Text("The hash does not correspond to any suspect in the database."),
          ));
    }
  }
}

// ===================================================================
// Custom Reusable Widgets for this Screen
// ===================================================================

/// A custom card widget to display a single suspect in the database list.
class _SuspectCard extends StatelessWidget {
  final Map<String, dynamic> suspect;
  final bool isMatch; // Is this the final, confirmed match?
  final bool isScanning; // Is the system currently "looking at" this card?

  const _SuspectCard({required this.suspect, required this.isMatch, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (isMatch) {
      borderColor = Colors.greenAccent;
    } else if (isScanning) {
      borderColor = Colors.yellowAccent;
    } else {
      borderColor = Theme.of(context).cardColor;
    }

    return Card(
      elevation: isMatch ? 8 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: isMatch || isScanning ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(Icons.person_outline, color: isMatch ? Colors.greenAccent : Colors.white70),
        title: Text(suspect['name']),
        subtitle: Text("ID: ${suspect['id']}"),
      ),
    );
  }
}

/// A custom card widget to display the detailed profile of a matched suspect.
class _MatchFoundCard extends StatelessWidget {
  final Map<String, dynamic> suspect;
  const _MatchFoundCard({required this.suspect});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.greenAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 32),
              title: Text("MATCH FOUND!", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.greenAccent)),
            ),
            const Divider(color: Colors.greenAccent),
            Text("Suspect Profile:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text("  Name: ${suspect['name']}"),
            Text("  ID: ${suspect['id']}"),
            Text("  Fingerprint: ${suspect['fingerprint_details']}"),
            Text("  Last Location: ${suspect['last_known_location']}"),
          ],
        ),
      ),
    );
  }
}