import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'complaint_detail_screen.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  final String userName;

  const ComplaintHistoryScreen({super.key, required this.userName});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      const String baseUrl = "http://192.168.1.100:3000";

      final response = await http.get(
        Uri.parse('$baseUrl/complaints/${widget.userName}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            // Convert the dynamic list to List<Map<String, dynamic>>
            _complaints =
                List<Map<String, dynamic>>.from(data['complaints'] as List);
            _isLoading = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _complaints.isEmpty
                  ? const Center(child: Text('No complaints found'))
                  : ListView.builder(
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = _complaints[index];
                        // Remove userName from display here
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(complaint['title']),
                            subtitle: Text(
                              'Status: ${complaint['status']} • ${complaint['category']}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComplaintDetailScreen(
                                    complaint: complaint,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _fetchComplaints(); // Refresh if complaint was reopened
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
