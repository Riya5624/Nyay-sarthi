import 'package:flutter/material.dart';

class ResultDisplayCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultDisplayCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme; // Get the text theme once
    final status = result['status'];
    final message = result['message'] ?? 'An error occurred.';
    final data = result['data'] as Map<String, dynamic>?;

    final bool isSuccess = status == 'success';
    final Color headerColor = isSuccess ? const Color(0xFF64FFDA) : Colors.orangeAccent;
    final IconData headerIcon = isSuccess ? Icons.check_circle : Icons.warning_amber_rounded;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: headerColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Icon(headerIcon, color: headerColor, size: 28),
                const SizedBox(width: 12),
                // CORRECTED: Using titleLarge instead of headline6
                Text(
                  message,
                  style: textTheme.titleLarge?.copyWith(color: headerColor),
                ),
              ],
            ),
            if (isSuccess && data != null) ...[
              const Divider(height: 30, thickness: 0.5),
              // --- Details ---
              // The helper function below is also corrected.
              _buildDetailRow(context, Icons.person_outline, "Name", data['name']),
              _buildDetailRow(context, Icons.badge_outlined, "Suspect ID", data['id']),
              _buildDetailRow(context, Icons.fingerprint, "Fingerprint Details", data['fingerprint_details']),
              _buildDetailRow(context, Icons.location_on_outlined, "Last Known Location", data['last_known_location']),
            ]
          ],
        ),
      ),
    );
  }

  // === CORRECTED HELPER FUNCTION ===
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String? value) {
    final textTheme = Theme.of(context).textTheme; // Get the text theme once

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textTheme.bodyLarge?.color?.withOpacity(0.7), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CORRECTED: Using bodyMedium for the label
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textTheme.bodyLarge?.color?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                // CORRECTED: Using bodyLarge for the value
                Text(
                  value ?? 'N/A',
                  style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}