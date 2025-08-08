import 'dart:async';
import 'package:flutter/material.dart';
import '/services/api_service.dart';

/// An enhanced dashboard for Person 4: The Corrections Officer.
/// This screen features a live, automated monitoring system with superior
/// data visualization, including a "Go Live" mode and an animated offender pin.
class CorrectionsScreen extends StatefulWidget {
  const CorrectionsScreen({Key? key}) : super(key: key);

  @override
  _CorrectionsScreenState createState() => _CorrectionsScreenState();
}

// Add TickerProviderStateMixin to the state class to handle animations.
class _CorrectionsScreenState extends State<CorrectionsScreen> with TickerProviderStateMixin {
  // --- State Variables ---
  
  // The offender's position on the screen, updated by user interaction.
  Offset _offenderPosition = const Offset(150, 150);
  double _currentHour = 12.0; // The current time of day (0-23).
  List<String> _violations = ["Status: Awaiting Initial Check"];
  bool _isLoading = true;

  // A GlobalKey is used to get the dimensions of the map widget after it's been rendered.
  final GlobalKey _mapKey = GlobalKey();
  
  // For the "Go Live" feature, which automatically advances time.
  Timer? _liveTimer;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    // A post-frame callback ensures that the widget tree has been built and laid out
    // at least once, so we can safely get the map's dimensions for the first check.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  @override
  void dispose() {
    // IMPORTANT: Always cancel active timers in the dispose method to prevent
    // memory leaks and errors from running code after the widget is removed.
    _liveTimer?.cancel();
    super.dispose();
  }

  /// The core automation function. It calculates the logical coordinates
  /// and calls the backend API to check the offender's status.
  Future<void> _checkStatus() async {
    // "mounted" checks are best practice to prevent calling setState on a disposed widget.
    if (!mounted || _mapKey.currentContext == null) return;
    setState(() => _isLoading = true);

    final RenderBox mapBox = _mapKey.currentContext!.findRenderObject() as RenderBox;
    final logicalX = (_offenderPosition.dx / mapBox.size.width) * 100;
    final logicalY = (_offenderPosition.dy / mapBox.size.height) * 100;

    final response = await ApiService.checkGpsViolation(
      x: logicalX,
      y: logicalY,
      hour: _currentHour.round(),
    );

    if (mounted) {
      setState(() {
        _violations = response['status'] == 'success'
            ? List<String>.from(response['data']['violations'])
            : ["Error: Could not connect to server."];
        _isLoading = false;
      });
    }
  }

  /// Toggles the "Go Live" automated time progression.
  void _toggleLiveMode() {
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        // Start a periodic timer that fires every second.
        _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _currentHour = (_currentHour + 1) % 24; // Advance time by 1 hour
          });
          _checkStatus(); // Check status automatically every "hour"
        });
      } else {
        // If "Go Live" is turned off, cancel the timer.
        _liveTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A helper boolean to easily check if there are any active violations.
    bool hasViolation = _violations.any((v) => v.contains("Violation"));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Offender Monitoring')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOffenderInfoCard(),
            const SizedBox(height: 16),
            _buildMapView(hasViolation),
            const SizedBox(height: 16),
            _buildTimeControls(),
            const SizedBox(height: 16),
            _buildStatusPanel(hasViolation),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // UI Builder Helper Widgets
  // ===================================================================

  /// A simple card to provide context about who is being monitored.
  Widget _buildOffenderInfoCard() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.person_search_outlined, color: Colors.cyanAccent),
        title: Text("Monitoring Offender: Jane Smith"),
        subtitle: Text("Case ID: CC-2025-001"),
      ),
    );
  }

  /// Builds the main interactive map view.
  Widget _buildMapView(bool hasViolation) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTapDown: (details) {
          setState(() => _offenderPosition = details.localPosition);
          _checkStatus();
        },
        onPanUpdate: (details) => setState(() => _offenderPosition = details.localPosition),
        onPanEnd: (details) => _checkStatus(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            key: _mapKey,
            decoration: BoxDecoration(border: Border.all(color: Colors.white38)),
            child: Stack(
              children: [
                // Stylized map grid background.
                CustomPaint(painter: GridPainter(), size: Size.infinite),
                // The Safe Zone visual representation.
                Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: 0.8, heightFactor: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Center(child: Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 40)),
                    ),
                  ),
                ),
                // The offender's pin, which will pulse if there's a violation.
                Positioned(
                  left: _offenderPosition.dx - 15,
                  top: _offenderPosition.dy - 15,
                  child: _PulsingOffenderPin(isViolating: hasViolation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the card containing the time slider and "Go Live" button.
  Widget _buildTimeControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Time of Day: ${_currentHour.round()}:00", style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _currentHour,
              min: 0, max: 23, divisions: 23,
              label: "${_currentHour.round()}:00",
              onChanged: (val) => setState(() => _currentHour = val),
              onChangeEnd: (val) => _checkStatus(),
            ),
            ElevatedButton.icon(
              onPressed: _toggleLiveMode,
              icon: Icon(_isLive ? Icons.pause_circle_filled : Icons.play_circle_filled),
              label: Text(_isLive ? "STOP LIVE MODE" : "GO LIVE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLive ? Colors.redAccent : Colors.cyanAccent,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Builds the dynamic status panel at the bottom.
  Widget _buildStatusPanel(bool hasViolation) {
    return Card(
      elevation: 4,
      color: hasViolation ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: hasViolation ? Colors.redAccent : Colors.greenAccent, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _isLoading
              ? [const ListTile(title: Text("Checking..."), leading: CircularProgressIndicator())]
              : _violations.map((violation) {
                  bool isViolationItem = violation.contains("Violation");
                  return ListTile(
                    leading: Icon(
                      isViolationItem ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: isViolationItem ? Colors.redAccent : Colors.greenAccent,
                    ),
                    title: Text(violation, style: Theme.of(context).textTheme.bodyLarge),
                  );
                }).toList(),
        ),
      ),
    );
  }
}

// ===================================================================
// Custom Reusable Widgets for this Screen
// ===================================================================

/// A custom widget for the offender's pin that pulses when in violation.
/// It's a StatefulWidget because it manages its own AnimationController.
class _PulsingOffenderPin extends StatefulWidget {
  final bool isViolating;
  const _PulsingOffenderPin({required this.isViolating});

  @override
  __PulsingOffenderPinState createState() => __PulsingOffenderPinState();
}

class __PulsingOffenderPinState extends State<_PulsingOffenderPin> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The pulsing effect is only visible if the offender is violating.
          if (widget.isViolating)
            FadeTransition(
              opacity: _animationController,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.5)),
              ),
            ),
          const Icon(Icons.person_pin_circle, color: Colors.redAccent, size: 24),
        ],
      ),
    );
  }
}

/// A custom painter to draw a simple grid background for the map.
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}