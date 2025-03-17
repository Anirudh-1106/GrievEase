import 'package:flutter/material.dart';

class ComplaintCard extends StatelessWidget {
  final Map<String, String> complaint;

  const ComplaintCard({super.key, required this.complaint});

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getStatusColor(complaint['status']!),
          child: const Icon(Icons.assignment, color: Colors.white),
        ),
        title: Text('Complaint ID: ${complaint['id']}'),
        subtitle: Text('Category: ${complaint['category']}'),
        trailing: Text(
          complaint['status']!,
          style: TextStyle(
            color: getStatusColor(complaint['status']!),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
