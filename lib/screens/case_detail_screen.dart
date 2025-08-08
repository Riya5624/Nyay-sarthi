import 'package:flutter/material.dart';
import '/services/api_service.dart';

/// A dedicated screen to view and manage a single criminal case.
class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({Key? key, required this.caseId}) : super(key: key);

  @override
  _CaseDetailScreenState createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _caseData;
  final _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCaseDetails();
  }

  Future<void> _fetchCaseDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final response = await ApiService.getCase(widget.caseId);
    if (mounted) {
      setState(() {
        _caseData = response['status'] == 'success' ? response['data'] : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _addEvidence() async {
    if (_evidenceController.text.isEmpty || !mounted) return;
    final response = await ApiService.addEvidence(
      caseId: widget.caseId,
      evidenceItem: _evidenceController.text,
    );
    _evidenceController.clear();
    if (response['status'] == 'success') _fetchCaseDetails();
  }

  Future<void> _updateStatus(String newStatus) async {
    if (!mounted) return;
    final response = await ApiService.updateStatus(
      caseId: widget.caseId,
      newStatus: newStatus,
    );
    if (response['status'] == 'success') _fetchCaseDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Case Details: ${widget.caseId}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _caseData == null
              ? const Center(child: Text("Could not load case details."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildEvidenceCard(),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Defendant: ${_caseData!['defendant_name']}", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text("Current Status: ${_caseData!['case_status']}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.cyanAccent)),
      ],
    )));
  }

  Widget _buildStatusCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Update Case Status", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: ['Investigation', 'Pre-Trial', 'Trial', 'Sentenced', 'Closed'].map((status) => 
            ActionChip(
              label: Text(status),
              onPressed: () => _updateStatus(status),
              backgroundColor: _caseData!['case_status'] == status ? Colors.cyanAccent : null,
            )
          ).toList(),
        ),
      ],
    )));
  }

  Widget _buildEvidenceCard() {
    final List evidenceLog = _caseData!['evidence_log'];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Evidence Log", style: Theme.of(context).textTheme.titleMedium),
        const Divider(height: 20),
        if (evidenceLog.isEmpty) const Text("No evidence logged yet."),
        ...evidenceLog.reversed.map((e) => ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(e['evidence_item']),
          subtitle: Text(e['timestamp']),
          dense: true,
        )),
        const SizedBox(height: 16),
        TextField(
          controller: _evidenceController,
          decoration: const InputDecoration(labelText: 'Add new evidence item...'),
          onSubmitted: (_) => _addEvidence(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(onPressed: _addEvidence, child: const Text("ADD EVIDENCE")),
        ),
      ],
    )));
  }
}