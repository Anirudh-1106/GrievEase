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

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    ); // Ensure the controller is initialized here
    _fetchComplaints();
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Dispose of the controller to avoid memory leaks
    super.dispose();
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
            _complaints =
                List<Map<String, dynamic>>.from(data['complaints'] as List);
            _isLoading = false;
            _animationController
                .forward(); // Start animation when data is loaded
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
              ? Center(
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : _complaints.isEmpty
                  ? const Center(
                      child: Text(
                        'No complaints found',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = _complaints[index];
                        return FadeTransition(
                          opacity: _animationController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index / _complaints.length,
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            )),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  complaint['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: ${complaint['status']}',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            complaint['status']),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${complaint['category']}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.deepPurple,
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ComplaintDetailScreen(
                                        complaint: complaint,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchComplaints(); // Refresh if complaint was reopened
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Reopened':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
