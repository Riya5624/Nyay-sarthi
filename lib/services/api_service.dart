import 'dart:convert';
import 'package:http/http.dart' as http;

/// A dedicated service class for handling all network communication with the Python backend.
///
/// This class contains static methods for each API endpoint, ensuring that
/// all network logic is centralized and separated from the UI code.
class ApiService {
  // IMPORTANT: Replace with your computer's local IP address.
  // The backend server must be running on your machine for this to work.
  //
  // Common Values:
  // - For a physical Android/iOS device: "http://192.168.1.15:8000" (use your computer's actual IP)
  // - For the official Android Emulator: "http://10.0.2.2:8000"
  // - For running the Flutter app in Chrome: "http://localhost:8000"
  static const String _baseUrl = "http://192.168.29.191:8001";

  /// A private helper method to handle all API errors consistently.
  static Map<String, dynamic> _handleError(dynamic e) {
    // Print the error to the debug console for the developer.
    print("API Service Error: $e");
    // Return a standardized error message for the UI to display.
    return {'status': 'error', 'message': 'Failed to connect to the server. Please ensure the backend is running and the IP address is correct.'};
  }

  // ===================================================================
  // Person 1: Investigator
  // ===================================================================
  static Future<Map<String, dynamic>> getSuspectDatabase() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/investigator/database'));
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> findSuspectByHash(String hash) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/investigator/find_match'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'crime_scene_hash': hash}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================================================================
  // Person 2: Pre-Trial Analyst
  // ===================================================================
  static Future<Map<String, dynamic>> calculateRiskScore({
    required int priors,
    required int age,
    required bool isEmployed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pretrial/calculate_risk'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'prior_offenses': priors, 'age_at_first_arrest': age, 'has_stable_employment': isEmployed}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================================================================
  // Person 3: Sentencing Advisor
  // ===================================================================
  static Future<Map<String, dynamic>> getSentencingRecommendation({
    required String crimeType,
    required int severityScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sentencing/recommend'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'crime_type': crimeType, 'severity_score': severityScore}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================================================================
  // Person 4: Corrections Officer
  // ===================================================================
  static Future<Map<String, dynamic>> checkGpsViolation({
    required double x,
    required double y,
    required int hour,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/corrections/check_violation'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'current_x': x, 'current_y': y, 'current_hour': hour}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================================================================
  // Person 5: Auditor
  // ===================================================================
  static Future<Map<String, dynamic>> runBiasSimulation({
    required double biasMultiplier,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auditor/run_simulation'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'bias_multiplier': biasMultiplier}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ===================================================================
  // Person 6: System Architect
  // ===================================================================
  static Future<Map<String, dynamic>> getAllCases() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/cases'));
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createCase({
    required String caseId,
    required String defendantName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/case/create'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'case_id': caseId, 'defendant_name': defendantName}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getCase(String caseId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/case/$caseId'));
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addEvidence({
    required String caseId,
    required String evidenceItem,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/case/$caseId/add_evidence'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'evidence_item': evidenceItem}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateStatus({
    required String caseId,
    required String newStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/case/$caseId/update_status'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'new_status': newStatus}),
      );
      return json.decode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }
}