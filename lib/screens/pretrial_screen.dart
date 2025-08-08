import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Import the gauge package

/// An enhanced dashboard for Person 2: The Pre-Trial Analyst.
/// This screen features a real-time risk gauge, automated score calculation,
/// and actionable recommendations, providing a professional and usable tool.
class PretrialScreen extends StatefulWidget {
  const PretrialScreen({Key? key}) : super(key: key);

  @override
  _PretrialScreenState createState() => _PretrialScreenState();
}

class _PretrialScreenState extends State<PretrialScreen> {
  // --- State Variables for UI Controls and Data ---
  double _priorOffenses = 2;
  double _ageAtFirstArrest = 25;
  bool _isEmployed = true;

  bool _isLoading = true; // Start in a loading state to fetch the initial score.
  int? _riskScore; // The score received from the backend.

  @override
  void initState() {
    super.initState();
    // Calculate the initial score as soon as the screen loads.
    _updateRiskScore();
  }

  /// This function is the core of the automation. It's called whenever any
  /// input control's value changes, providing real-time feedback.
  Future<void> _updateRiskScore() async {
    // A "mounted" check is a best practice to prevent calling setState on a
    // widget that is no longer in the widget tree.
    if (!mounted) return;
    setState(() => _isLoading = true);

    final response = await ApiService.calculateRiskScore(
      priors: _priorOffenses.round(),
      age: _ageAtFirstArrest.round(),
      isEmployed: _isEmployed,
    );

    if (mounted && response['status'] == 'success') {
      setState(() {
        _riskScore = response['data']['risk_score'];
        _isLoading = false;
      });
    } else {
      // Handle potential API or network errors gracefully.
      setState(() {
        _riskScore = null;
        _isLoading = false;
      });
    }
  }

  /// A helper function to derive a user-friendly "profile" (risk level, color,
  /// and recommendation) from the raw numerical score.
  Map<String, dynamic> _getRiskProfile(int? score) {
    if (score == null) {
      return {'level': 'Error', 'color': Colors.grey, 'recommendation': 'Could not calculate score.'};
    }
    if (score < 5) {
      return {'level': 'Low Risk', 'color': const Color(0xFF64FFDA), 'recommendation': 'Consider Release on Recognizance.'};
    } else if (score < 15) {
      return {'level': 'Medium Risk', 'color': Colors.orangeAccent, 'recommendation': 'Recommend Standard Bail Amount.'};
    } else {
      return {'level': 'High Risk', 'color': Colors.redAccent, 'recommendation': 'Recommend Bail Denial / Remand.'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Risk Assessment')),
      // Use a ListView to ensure the content is scrollable on smaller screens.
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFactorsCard(),
          const SizedBox(height: 24),
          _buildRiskProfileCard(),
        ],
      ),
    );
  }

  // ===================================================================
  // UI Builder Helper Widgets
  // ===================================================================

  /// Builds the top card containing all the input controls.
  Widget _buildFactorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Defendant Factors", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _buildSlider(
              label: "Prior Offenses",
              icon: Icons.history_edu_outlined,
              value: _priorOffenses,
              max: 10,
              onChanged: (val) => setState(() => _priorOffenses = val),
            ),
            _buildSlider(
              label: "Age at First Arrest",
              icon: Icons.cake_outlined,
              value: _ageAtFirstArrest,
              min: 14,
              max: 60,
              onChanged: (val) => setState(() => _ageAtFirstArrest = val),
            ),
            _buildToggle(
              label: "Employment Status",
              icon: Icons.work_outline,
              isSelected: _isEmployed,
              onPressed: (val) => setState(() => _isEmployed = val),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom card which displays the risk gauge and recommendation.
  Widget _buildRiskProfileCard() {
    final profile = _getRiskProfile(_riskScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Text("Risk Profile Summary", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Show a loading spinner while the API call is in progress.
            if (_isLoading)
              const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()))
            else
              // Once loaded, show the gauge and recommendations.
              Column(
                children: [
                  _buildRadialGauge(profile),
                  const SizedBox(height: 24),
                  Text(
                    profile['level'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: profile['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile['recommendation'],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  /// A reusable builder for the slider controls.
  Widget _buildSlider({required String label, required IconData icon, required double value, required Function(double) onChanged, double min = 0, double max = 20}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: value.round().toString(),
                onChanged: onChanged,
                // AUTOMATION: Triggers the API call when the user stops sliding.
                onChangeEnd: (val) => _updateRiskScore(),
              ),
            ),
            Text(value.round().toString(), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }

  /// A reusable builder for the toggle switch control.
  Widget _buildToggle({required String label, required IconData icon, required bool isSelected, required Function(bool) onPressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Unemployed", style: TextStyle(color: !isSelected ? Colors.white : Colors.grey)),
            const SizedBox(width: 10),
            Switch(
              value: isSelected,
              onChanged: (val) {
                onPressed(val);
                // AUTOMATION: Triggers the API call immediately when toggled.
                _updateRiskScore();
              },
              activeColor: const Color(0xFF64FFDA),
            ),
            const SizedBox(width: 10),
            Text("Employed", style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the beautiful radial gauge using the Syncfusion package.
  Widget _buildRadialGauge(Map<String, dynamic> profile) {
    return SizedBox(
      height: 250,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 30, // A sensible maximum for visualization.
            showLabels: false,
            showTicks: false,
            axisLineStyle: const AxisLineStyle(
              thickness: 0.2,
              cornerStyle: CornerStyle.bothCurve,
              color: Color.fromARGB(255, 60, 60, 60),
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            pointers: <GaugePointer>[
              NeedlePointer(
                value: (_riskScore ?? 0).toDouble(),
                enableAnimation: true,
                animationDuration: 800,
                needleStartWidth: 1,
                needleEndWidth: 5,
                needleColor: Colors.white,
                knobStyle: const KnobStyle(
                  knobRadius: 0.08,
                  sizeUnit: GaugeSizeUnit.factor,
                  color: Colors.white
                ),
              ),
            ],
            // Defines the green, yellow, and red color bands.
            ranges: <GaugeRange>[
              GaugeRange(startValue: 0, endValue: 5, color: const Color(0xFF64FFDA), startWidth: 0.2, endWidth: 0.2, sizeUnit: GaugeSizeUnit.factor),
              GaugeRange(startValue: 5, endValue: 15, color: Colors.orangeAccent, startWidth: 0.2, endWidth: 0.2, sizeUnit: GaugeSizeUnit.factor),
              GaugeRange(startValue: 15, endValue: 30, color: Colors.redAccent, startWidth: 0.2, endWidth: 0.2, sizeUnit: GaugeSizeUnit.factor),
            ],
            // Displays the score number in the center of the gauge.
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  (_riskScore ?? '-').toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                angle: 90,
                positionFactor: 0.75,
              )
            ],
          )
        ],
      ),
    );
  }
}