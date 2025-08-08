import 'package:flutter/material.dart';

// Import all the main screens so we can navigate to them from the dashboard.
import '/screens/investigator_screen.dart';
import '/screens/pretrial_screen.dart';
import '/screens/sentencing_screen.dart';
import '/screens/corrections_screen.dart';
import '/screens/auditor_screen.dart';
import '/screens/architect_screen.dart';

/// The new home screen for the application, acting as a central dashboard or launchpad.
/// It presents all available modules in a clean, tappable list format.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The AppBar shows the name of the app.
        title: const Text('न्याय सारथी'),
        centerTitle: true,
      ),
      // A ListView ensures the content is scrollable on any screen size.
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // A welcoming header for the dashboard.
          Text(
            "Welcome to the Suite",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Select a module below to begin a simulation.",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // A grid of cards, one for each module, built using our custom widget.
          _DashboardCard(
            icon: Icons.fingerprint,
            title: "Investigator",
            subtitle: "Match biometric evidence to the suspect database.",
            color: Colors.blue,
            // Navigate to the corresponding screen when tapped.
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestigatorScreen())),
          ),
          _DashboardCard(
            icon: Icons.gavel,
            title: "Pre-Trial Analyst",
            subtitle: "Calculate real-time defendant risk scores.",
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PretrialScreen())),
          ),
          _DashboardCard(
            icon: Icons.assessment,
            title: "Sentencing Advisor",
            subtitle: "Get sentence recommendations from historical data.",
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SentencingScreen())),
          ),
          _DashboardCard(
            icon: Icons.gps_fixed,
            title: "Corrections Officer",
            subtitle: "Monitor offender location and curfew compliance.",
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionsScreen())),
          ),
          _DashboardCard(
            icon: Icons.pie_chart,
            title: "Bias Auditor",
            subtitle: "Simulate and visualize algorithmic bias.",
            color: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditorScreen())),
          ),
           _DashboardCard(
            icon: Icons.folder_special,
            title: "System Architect",
            subtitle: "Manage and review digital case files.",
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchitectScreen())),
          ),
        ],
      ),
    );
  }
}

/// A reusable, private card widget for the dashboard grid.
/// This helps keep the main build method clean and avoids code duplication.
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell( // InkWell provides the tappable area and ripple effect.
        onTap: onTap,
        borderRadius: BorderRadius.circular(8), // Match the Card's border radius.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // The '.shade300' has been removed to fix the error.
              // The base color (e.g., Colors.blue) is used directly.
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              // Expanded ensures the text column takes up available space,
              // pushing the arrow to the far right.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}