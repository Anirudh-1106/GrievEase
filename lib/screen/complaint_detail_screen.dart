import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Future<void> _reopenComplaint() async {
    try {
      const String baseUrl = "http://192.168.184.119:3000";

      final response = await http.post(
        Uri.parse(
            '$baseUrl/complaints/reopen/${widget.complaint['complaintId']}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint reopened successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reopen complaint')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint ${widget.complaint['complaintId']}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: const Text('Status'),
                  subtitle: Text(
                    widget.complaint['status'],
                    style: TextStyle(
                      color: widget.complaint['status'] == 'Resolved'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Category'),
                  subtitle: Text(widget.complaint['category']),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Title'),
                  subtitle: Text(widget.complaint['title']),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Description'),
                  subtitle: Text(widget.complaint['description']),
                ),
              ),
              if (widget.complaint['image'] != null &&
                  widget.complaint['image'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attached Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(widget.complaint['image']),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Failed to load image'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.complaint['status'] == 'Resolved')
                Center(
                  child: ElevatedButton(
                    onPressed: _reopenComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reopen Complaint'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
