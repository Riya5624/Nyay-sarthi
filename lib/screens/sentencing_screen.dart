import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the new chart package

/// An enhanced dashboard for Person 3: The Sentencing Advisor.
/// This screen features real-time, automated sentence recommendations and
/// a visual chart to display the range of historical data.
class SentencingScreen extends StatefulWidget {
  const SentencingScreen({Key? key}) : super(key: key);
  @override
  _SentencingScreenState createState() => _SentencingScreenState();
}

class _SentencingScreenState extends State<SentencingScreen> {
  // --- State Variables ---
  
  // Predefined list of crimes based on the backend's historical dataset.
  final List<String> _crimeTypes = const ['Theft', 'Assault', 'Burglary', 'Fraud', 'Vandalism', 'Espionage'];
  String? _selectedCrimeType;
  double _severityScore = 3.0;
  
  bool _isLoading = true; // Start in loading state for the initial recommendation.
  Map<String, dynamic>? _result; // Holds the full API response.

  @override
  void initState() {
    super.initState();
    // Set a default crime type and fetch the first recommendation automatically.
    _selectedCrimeType = _crimeTypes.first;
    _getRecommendation();
  }

  /// The core automation function. Fetches a new recommendation whenever
  /// an input control is changed by the user.
  Future<void> _getRecommendation() async {
    if (_selectedCrimeType == null || !mounted) return;
    setState(() => _isLoading = true);
    
    final response = await ApiService.getSentencingRecommendation(
      crimeType: _selectedCrimeType!,
      severityScore: _severityScore.round(),
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nyay Sarthi Sentencing Tool')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          // Show a loading spinner while the API call is in progress.
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else AnimatedSwitcher( // Smoothly transition between result cards.
            duration: const Duration(milliseconds: 500),
            child: _result != null ? _buildResultCard() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // UI Builder Helper Widgets
  // ===================================================================

  /// Builds the top card containing the case detail input controls.
  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Case Details", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            // Dropdown for selecting the crime type.
            DropdownButtonFormField<String>(
              value: _selectedCrimeType,
              decoration: const InputDecoration(labelText: 'Crime Type', border: OutlineInputBorder()),
              items: _crimeTypes.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) {
                setState(() => _selectedCrimeType = newValue);
                _getRecommendation(); // AUTOMATION: Get new recommendation on change.
              },
            ),
            const SizedBox(height: 16),
            // Slider for setting the severity score.
            Text("Severity Score", style: Theme.of(context).textTheme.bodyLarge),
            Row(children: [
              Expanded(
                child: Slider(
                  value: _severityScore,
                  min: 1, max: 5, divisions: 4,
                  label: _severityScore.round().toString(),
                  onChanged: (val) => setState(() => _severityScore = val),
                  onChangeEnd: (val) => _getRecommendation(), // AUTOMATION: Get new recommendation on change.
                ),
              ),
              Text(_severityScore.round().toString(), style: Theme.of(context).textTheme.titleMedium)
            ])
          ],
        ),
      ),
    );
  }

  /// Builds the result card, which dynamically changes based on the API response.
  Widget _buildResultCard() {
    // Safely extract data from the response map.
    final status = _result!['status'] ?? 'Error';
    final basis = _result!['basis'] ?? 'No details provided.';
    final data = _result!['data'] as Map<String, dynamic>?;

    // Determine the card's color and icon based on the status.
    Color statusColor;
    IconData statusIcon;
    if (status.contains('Estimated')) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.rule_folder;
    } else if (status.contains('Success')) {
      statusColor = const Color(0xFF64FFDA); // Neon/Cyan
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header with status icon and text.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(statusIcon, color: statusColor, size: 32),
              title: Text(status, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: statusColor)),
            ),
            const Divider(height: 24),
            // If data exists, show the recommendation and chart.
            if (data != null) ...[
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.titleMedium,
                  children: [
                    const TextSpan(text: "Recommended Sentence:\n"),
                    TextSpan(
                      text: "${data['recommendation_months']} months",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                "Based on ${data['case_count']} historical case(s) with a sentence range of:",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // The new historical range chart.
              _buildRangeChart(
                data['min_sentence'].toDouble(),
                data['max_sentence'].toDouble(),
                data['recommendation_months'].toDouble(),
              ),
            ] else
              // If no data, just show the basis text.
              Text(basis, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  /// Builds a simple bar chart to visualize the min-to-max sentence range.
  Widget _buildRangeChart(double min, double max, double avg) {
    // Avoid chart errors if min and max are the same.
    if (min == max) max += 1;

    return SizedBox(
      height: 60,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(show: false), // Hide axis titles
          borderData: FlBorderData(show: false), // Hide chart border
          gridData: FlGridData(show: false),     // Hide grid lines
          barTouchData: BarTouchData(enabled: false), // Disable touch interactions
          // A single bar group representing the full range.
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                fromY: min,
                toY: max,
                color: Theme.of(context).cardColor,
                width: 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
          ],
          // An extra horizontal line to mark the average recommendation.
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: avg,
              color: const Color(0xFF64FFDA),
              strokeWidth: 3,
              dashArray: [10, 5], // Creates a dashed line effect.
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (line) => 'Avg: ${line.y}mo',
                alignment: Alignment.topRight,
                style: const TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.bold)
              ),
            )
          ]),
        ),
      ),
    );
  }
}