import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all screens, including the new ones
import '/screens/splash_screen.dart'; // New
import '/screens/dashboard_screen.dart'; // New
import '/screens/investigator_screen.dart';
import '/screens/pretrial_screen.dart';
import '/screens/sentencing_screen.dart';
import '/screens/corrections_screen.dart';
import '/screens/auditor_screen.dart';
import '/screens/architect_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Criminal Justice AI Suite',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0A192F),
        scaffoldBackgroundColor: const Color(0xFF0A192F),
        cardColor: const Color(0xFF172A46),
        colorScheme: const ColorScheme.dark(secondary: Color(0xFF64FFDA)), // For icons
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFFCCD6F6),
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF172A46),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        // ... (other theme properties remain the same)
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF172A46),
          selectedItemColor: Color(0xFF64FFDA),
          unselectedItemColor: Color(0xFF8892B0),
        )
      ),
      // The app now starts with the SplashScreen.
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The main stateful widget that manages the app's navigation state.
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // The list of widgets now starts with the DashboardScreen.
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),    // Index 0 (NEW)
    const InvestigatorScreen(), // Index 1
    const PretrialScreen(),     // Index 2
    const SentencingScreen(),   // Index 3
    const CorrectionsScreen(),  // Index 4
    const AuditorScreen(),      // Index 5
    const ArchitectScreen(),    // Index 6
  ];

  void _onItemTapped(int index) {
    // A small change here: if the user taps a card on the dashboard, we don't
    // want the main navigation to change. So we only update the index if
    // the tap comes from the BottomNavigationBar itself.
    // For simplicity, we can keep the direct setState.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          // The first item is now the "Dashboard"
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Investigator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'Pre-Trial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Sentencing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gps_fixed),
            label: 'Corrections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Auditor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_special),
            label: 'Architect',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}