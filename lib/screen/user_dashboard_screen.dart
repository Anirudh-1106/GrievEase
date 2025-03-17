import 'package:flutter/material.dart';
import '../widgets/custom_dashboard_card.dart';

class UserDashboardScreen extends StatefulWidget {
  final String userName;

  const UserDashboardScreen({super.key, required this.userName});

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.userName}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                // ✅ Prevents overflow
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return CustomDashboardCard(
                          icon: Icons.add_circle_outline,
                          title: 'Lodge Complaint',
                          subtitle: '',
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/submit-complaint',
                            arguments: widget
                                .userName, // Passing the username to complaint screen
                          ),
                        );
                      case 1:
                        return CustomDashboardCard(
                          icon: Icons.history,
                          title: 'Complaint History',
                          subtitle: '',
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(
                              context, '/complaint-history',
                              arguments: widget.userName),
                        );
                      case 2:
                        return CustomDashboardCard(
                          icon: Icons.track_changes,
                          title: 'Track Status',
                          subtitle: '',
                          color: Colors.orange,
                          onTap: () =>
                              Navigator.pushNamed(context, '/track-complaint'),
                        );
                      case 3:
                        return CustomDashboardCard(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: '',
                          color: Colors.red,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No new notifications')),
                            );
                          },
                        );
                      default:
                        return const SizedBox();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
