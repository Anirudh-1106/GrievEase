import 'package:flutter/material.dart';
import '../widgets/custom_dashboard_card.dart';
import 'profile_page.dart'; // Import the correct ProfilePage

class UserDashboardScreen extends StatefulWidget {
  final String userName;

  const UserDashboardScreen({super.key, required this.userName});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> _pages() => <Widget>[
        DashboardPage(userName: widget.userName),
        ProfilePage(userName: widget.userName), // Use the correct ProfilePage
        const SettingsPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages()[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
                'Welcome, $userName!',
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
                            arguments:
                                userName, // Passing the username to complaint screen
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
                              arguments: userName),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Page'));
  }
}
