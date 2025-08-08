import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the chart package

/// An enhanced dashboard for Person 5: The Auditor.
/// This screen features an interactive bias simulator that allows the user
/// to control the level of bias and see the impact in real-time on a chart.
class AuditorScreen extends StatefulWidget {
  const AuditorScreen({Key? key}) : super(key: key);
  @override
  _AuditorScreenState createState() => _AuditorScreenState();
}

class _AuditorScreenState extends State<AuditorScreen> {
  // --- State Variables ---
  bool _isLoading = true;
  double _biasMultiplier = 2.5; // The initial, default bias level for Group B.
  Map<String, dynamic>? _report; // Holds the full API response from the backend.

  @override
  void initState() {
    super.initState();
    // Run the first audit automatically when the screen loads.
    _runAudit();
  }

  /// The core automation function. Fetches a new simulation result from the backend.
  Future<void> _runAudit() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final response = await ApiService.runBiasSimulation(biasMultiplier: _biasMultiplier);
    
    if (mounted) {
      setState(() {
        _report = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Bias Simulator')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildControlsCard(),
          const SizedBox(height: 24),
          // Show a loading spinner while fetching data.
          if (_isLoading) const Center(child: CircularProgressIndicator())
          // Use an AnimatedSwitcher for a smooth transition when the results appear.
          else AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _report != null && _report!['status'] == 'Success'
                ? _buildResultsCard()
                : const SizedBox.shrink(), // Show nothing if there's an error or no report.
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // UI Builder Helper Widgets
  // ===================================================================

  /// Builds the top card containing the interactive simulation controls.
  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Simulation Controls", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              "Bias Multiplier for Group B (Group A is fixed at 1.5x)",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Row(children: [
              Expanded(
                child: Slider(
                  value: _biasMultiplier,
                  min: 1.0, max: 4.0, divisions: 30,
                  label: _biasMultiplier.toStringAsFixed(1),
                  onChanged: (val) => setState(() => _biasMultiplier = val),
                  // AUTOMATION: Run the audit automatically when the user stops sliding.
                  onChangeEnd: (val) => _runAudit(),
                ),
              ),
              Text(
                "${_biasMultiplier.toStringAsFixed(1)}x",
                style: Theme.of(context).textTheme.titleMedium,
              )
            ]),
          ],
        ),
      ),
    );
  }

  /// Builds the main results card, including the bar chart and impact statement.
  Widget _buildResultsCard() {
    // Safely extract data from the report map.
    final data = _report!['data'];
    final double groupAScore = data['Group A']?.toDouble() ?? 0.0;
    final double groupBScore = data['Group B']?.toDouble() ?? 0.0;
    final double disparity = data['disparity_factor']?.toDouble() ?? 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Audit Results", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            // The bar chart visualization.
            SizedBox(
              height: 200,
              child: BarChart(_buildChartData(groupAScore, groupBScore)),
            ),
            const SizedBox(height: 24),
            // The plain-language impact statement.
            _buildImpactStatement(disparity),
          ],
        ),
      ),
    );
  }

  /// Builds the colored card with the final conclusion text.
  Widget _buildImpactStatement(double disparity) {
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text.rich(
          TextSpan(children: [
            const TextSpan(text: "Impact: On average, a member of Group B is assigned a risk score "),
            TextSpan(
              text: "${disparity.toStringAsFixed(2)}x higher",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const TextSpan(text: " than a member of Group A for similar offenses."),
          ]),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  /// Configures and returns the data for the BarChart widget.
  BarChartData _buildChartData(double scoreA, double scoreB) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      // Set the Y-axis maximum dynamically for better visualization.
      maxY: (scoreA > scoreB ? scoreA : scoreB) * 1.2,
      barTouchData: BarTouchData(enabled: false), // Disable touch interactions.
      titlesData: FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
              Widget text;
              switch (value.toInt()) {
                case 0: text = const Text('Group A', style: style); break;
                case 1: text = const Text('Group B', style: style); break;
                default: text = const Text('', style: style); break;
              }
return text;            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false),
      // Define the two bars.
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
            toY: scoreA,
            color: const Color(0xFF64FFDA), // Group A gets the "good" color.
            width: 40,
            borderRadius: BorderRadius.circular(4),
          )
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
            toY: scoreB,
            color: Colors.redAccent, // Group B gets the "bad" color.
            width: 40,
            borderRadius: BorderRadius.circular(4),
          )
        ]),
      ],
    );
  }
}