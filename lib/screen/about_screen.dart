import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'What is GrievEase?',
                Icons.app_shortcut,
                'GrievEase is your comprehensive solution for managing and tracking grievances efficiently. We simplify the process of submitting and resolving complaints while ensuring transparency throughout the journey.',
              ),
              _buildSection(
                'Key Features',
                Icons.star,
                '• Easy complaint submission\n'
                    '• Real-time tracking system\n'
                    '• Secure user profiles\n'
                    '• Complaint history management\n'
                    '• Interactive dashboard',
              ),
              _buildSection(
                'Coming Soon',
                Icons.upcoming,
                '• AI-powered complaint categorization\n'
                    '• Push notifications\n'
                    '• Multi-language support\n'
                    '• Advanced analytics',
              ),
              _buildSection(
                'How to Use',
                Icons.help_outline,
                '1. Submit your complaint through the dashboard:\n'
                    '   • Click on "New Complaint" button\n'
                    '   • Fill in all required details\n'
                    '   • Attach supporting documents if needed\n'
                    '   • Review and submit\n\n'
                    '2. Track your complaint status in real-time:\n'
                    '   • View current status on dashboard\n'
                    '   • Check processing stage\n'
                    '   • See estimated resolution time\n\n'
                    '3. Receive updates on resolution progress:\n'
                    '   • View detailed status updates\n'
                    '   • Communicate with handlers if needed\n\n'
                    '4. Access your complaint history anytime:\n'
                    '   • View all past complaints\n'
                    '   • Check resolution outcomes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
