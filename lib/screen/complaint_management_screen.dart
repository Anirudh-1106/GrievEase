import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() =>
      _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  String _selectedSort = 'newest';
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      const String baseUrl = "http://192.168.184.119:3000";

      final queryParams = {
        'status': _selectedStatus != 'All' ? _selectedStatus : '',
        'category': _selectedCategory != 'All' ? _selectedCategory : '',
        'sort': _selectedSort == 'newest' ? '-createdAt' : 'createdAt',
      };

      final uri = Uri.parse('$baseUrl/complaints').replace(
        queryParameters:
            queryParams.map((key, value) => MapEntry(key, value.toString()))
              ..removeWhere((key, value) => value.isEmpty),
      );

      final response = await http.get(
        uri,
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

  Future<void> _updateComplaintStatus(
      String complaintId, String newStatus, String comment) async {
    try {
      const String baseUrl = "http://192.168.184.119:3000";

      final response = await http
          .post(
            Uri.parse('$baseUrl/complaints/update/$complaintId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'status': newStatus,
              'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(
            context); // Close the update dialog after successful update
        _fetchComplaints();
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateDialog(Map<String, dynamic> complaint) {
    String selectedStatus = complaint['status'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Complaint Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: ['Pending', 'In Progress', 'Resolved', 'Reopened']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) => selectedStatus = value!,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateComplaintStatus(
              complaint['complaintId'],
              selectedStatus,
              _commentController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Grievance Portal'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analysis'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/reports-analytics');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grievance Portal'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: [
                      'All',
                      'Pending',
                      'In Progress',
                      'Resolved',
                      'Reopened'
                    ]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                        _fetchComplaints();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: [
                      'All',
                      'Infrastructure',
                      'Academics',
                      'Administration',
                      'Hostel',
                      'Others'
                    ]
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _fetchComplaints();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Sort by: '),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSort =
                          _selectedSort == 'newest' ? 'oldest' : 'newest';
                      _fetchComplaints();
                    });
                  },
                  icon: Icon(
                    _selectedSort == 'newest'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  label: Text(_selectedSort == 'newest' ? 'Newest' : 'Oldest'),
                ),
              ],
            ),
          ),

          // Complaints list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _complaints.isEmpty
                        ? const Center(child: Text('No complaints found'))
                        : ListView.builder(
                            itemCount: _complaints.length,
                            itemBuilder: (context, index) {
                              final complaint = _complaints[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(complaint['title']),
                                  subtitle: Text(
                                    '${complaint['category']} • ${complaint['status']}\n'
                                    'Complaint ID: ${complaint['complaintId']}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showUpdateDialog(complaint),
                                  ),
                                  onTap: () => _showComplaintDetails(complaint),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaint Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('ID', complaint['complaintId'] ?? 'N/A'),
                _buildDetailRow('Student Name', complaint['userName'] ?? 'N/A'),
                _buildDetailRow('Registration No.',
                    complaint['registrationNumber'] ?? 'N/A'),
                _buildDetailRow('Category', complaint['category'] ?? 'N/A'),
                _buildDetailRow('Status', complaint['status'] ?? 'N/A'),
                _buildDetailRow('Title', complaint['title'] ?? 'N/A'),
                _buildDetailRow(
                    'Description', complaint['description'] ?? 'N/A'),
                if (complaint['image'] != null &&
                    complaint['image'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Attached Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(complaint['image']),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Failed to load image'),
                        );
                      },
                    ),
                  ),
                ],
                if (complaint['location'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Location: ${complaint['location']['address'] ?? 'Location provided'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: const Text('View Location'),
                    onPressed: () async {
                      final url = complaint['location']['locationLink'];
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
