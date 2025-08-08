import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/main.dart'; // Navigate to MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Define states for each animation stage
  final Map<String, bool> _animationStates = {
    'logo': false,
    'step1': false,
    'step2': false,
    'step3': false,
    'step4': false,
    'step5': false,
    'step6': false,
    'tagline': false,
  };

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    // A more complex sequence for a professional feel
    const int logoDelay = 500;
    const int stepInterval = 400;
    const int initialStepDelay = logoDelay + 800;

    _setTimer('logo', logoDelay);
    _setTimer('step1', initialStepDelay);
    _setTimer('step2', initialStepDelay + stepInterval);
    _setTimer('step3', initialStepDelay + (stepInterval * 2));
    _setTimer('step4', initialStepDelay + (stepInterval * 3));
    _setTimer('step5', initialStepDelay + (stepInterval * 4));
    _setTimer('step6', initialStepDelay + (stepInterval * 5));
    _setTimer('tagline', initialStepDelay + (stepInterval * 6) + 500);

    // Final navigation timer
    Timer(const Duration(milliseconds: 6500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  void _setTimer(String key, int delay) {
    Timer(Duration(milliseconds: delay), () {
      if (mounted) setState(() => _animationStates[key] = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0A192F), Theme.of(context).cardColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ==========================================================
            // NEW TEXT-ONLY LOGO WIDGET
            // ==========================================================
            _AnimatedSlideFade(
              show: _animationStates['logo']!,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. The background element: a line representing the scales' bar
                  Container(
                    height: 2,
                    width: 150,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  // 2. The main text, placed on top of the line
                  Container(
                    color: const Color(0xFF0A192F).withOpacity(0.8), // A slightly transparent background to "cut out" the line
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        children: <TextSpan>[
                          const TextSpan(text: 'न्याय', style: TextStyle(letterSpacing: 2)),
                          TextSpan(
                            text: ' सारथी',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary, // Highlight color
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ==========================================================
            // END OF LOGO WIDGET
            // ==========================================================
            
            const SizedBox(height: 50),

            // --- Detailed Feature Showcase ---
            _AnimatedFeature(show: _animationStates['step1']!, icon: Icons.fingerprint, title: "Investigator", description: "Automated biometric evidence matching."),
            _AnimatedFeature(show: _animationStates['step2']!, icon: Icons.gavel, title: "Pre-Trial Analyst", description: "Real-time, data-driven risk assessment."),
            _AnimatedFeature(show: _animationStates['step3']!, icon: Icons.assessment, title: "Sentencing Advisor", description: "Historical data based sentence recommendations."),
            _AnimatedFeature(show: _animationStates['step4']!, icon: Icons.gps_fixed, title: "Corrections Officer", description: "Live offender compliance monitoring."),
            _AnimatedFeature(show: _animationStates['step5']!, icon: Icons.pie_chart, title: "Bias Auditor", description: "Interactive algorithmic bias simulation."),
            _AnimatedFeature(show: _animationStates['step6']!, icon: Icons.folder_special, title: "System Architect", description: "Centralized digital case file management."),
            
            const SizedBox(height: 50),

            // --- Tagline ---
            _AnimatedSlideFade(
              show: _animationStates['tagline']!,
              child: Text(
                "AI-Powered Insights for Modern Justice",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF64FFDA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Reusable Animation Widgets (These are unchanged) ---

/// A widget that animates its child with a fade and upward slide transition.
class _AnimatedSlideFade extends StatelessWidget {
  final bool show;
  final Widget child;
  const _AnimatedSlideFade({required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        transform: Matrix4.translationValues(0, show ? 0 : 20, 0),
        child: child,
      ),
    );
  }
}

/// A custom widget for displaying each feature in an animated way.
class _AnimatedFeature extends StatelessWidget {
  final bool show;
  final IconData icon;
  final String title;
  final String description;

  const _AnimatedFeature({
    required this.show,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedSlideFade(
      show: show,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 16),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: "$title: ", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextSpan(text: description, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}