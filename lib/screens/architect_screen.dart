import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '/screens/case_detail_screen.dart'; // Import the new detail screen

/// The main hub for Person 6: The System Architect.
/// This screen displays a live list of all cases in the system,
/// allows for the creation of new cases, and navigates to a
/// detailed view for case management.
class ArchitectScreen extends StatefulWidget {
  const ArchitectScreen({Key? key}) : super(key: key);
  @override
  _ArchitectScreenState createState() => _ArchitectScreenState();
}

class _ArchitectScreenState extends State<ArchitectScreen> {
  List<Map<String, dynamic>> _cases = []; // Holds the list of all cases
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the list of cases as soon as the screen is loaded.
    _fetchCases();
  }

  /// Fetches all cases from the backend and updates the UI.
  /// This is the core data-loading function for the hub.
  Future<void> _fetchCases() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final response = await ApiService.getAllCases();
    
    if (mounted && response['status'] == 'success') {
      setState(() {
        _cases = List<Map<String, dynamic>>.from(response['data']);
        _isLoading = false;
      });
    } else {
      // Handle potential errors if the case list can't be fetched.
      setState(() => _isLoading = false);
      // Optionally, show a SnackBar or error message.
    }
  }

  /// Displays a dialog box to get input for creating a new case.
  void _showCreateCaseDialog() {
    final caseIdController = TextEditingController();
    final defendantNameController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // For validation

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Case"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: caseIdController,
                decoration: const InputDecoration(labelText: "Case ID"),
                validator: (value) => value!.isEmpty ? 'Please enter a Case ID' : null,
              ),
              TextFormField(
                controller: defendantNameController,
                decoration: const InputDecoration(labelText: "Defendant Name"),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Validate the form before proceeding.
              if (formKey.currentState!.validate()) {
                await ApiService.createCase(
                  caseId: caseIdController.text,
                  defendantName: defendantNameController.text,
                );
                // Close the dialog and refresh the case list automatically.
                if (mounted) Navigator.pop(context);
                _fetchCases();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Management Hub'),
        // Add a manual refresh button for user convenience.
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCases)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? const Center(
                  child: Text(
                    "No cases found.\nPress the '+' button to create one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              // Display the list of cases using ListView.builder for efficiency.
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) {
                    final caseData = _cases[index];
                    return _CaseListTile(
                      caseData: caseData,
                      // When a case is tapped, navigate to the detail screen.
                      onTap: () async {
                        // The 'await' ensures that when we return from the detail screen,
                        // the case list is refreshed to show any changes.
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => CaseDetailScreen(caseId: caseData['case_id']),
                        ));
                        _fetchCases();
                      },
                    );
                  },
                ),
      // A FloatingActionButton is the standard, intuitive UI pattern for adding a new item.
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCaseDialog,
        child: const Icon(Icons.add),
        tooltip: "Create New Case",
      ),
    );
  }
}

// ===================================================================
// Custom Reusable Widget for the Case List
// ===================================================================

/// A custom widget for displaying a single case in the main list.
/// This makes the main build method cleaner and the code more reusable.
class _CaseListTile extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final VoidCallback onTap;

  const _CaseListTile({required this.caseData, required this.onTap});

  /// A helper function to get a specific color for each case status tag.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'investigation': return Colors.blue.shade300;
      case 'pre-trial': return Colors.orange.shade300;
      case 'trial': return Colors.purple.shade300;
      case 'sentenced': return Colors.red.shade300;
      case 'closed': return Colors.grey.shade600;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.folder_copy_outlined, size: 40, color: Colors.white70),
        title: Text(caseData['case_id'], style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text("Defendant: ${caseData['defendant_name']}"),
        // The status chip provides excellent at-a-glance information.
        trailing: Chip(
          label: Text(
            caseData['case_status'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getStatusColor(caseData['case_status']),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          labelPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}