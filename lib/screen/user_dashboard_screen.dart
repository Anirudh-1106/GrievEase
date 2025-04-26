import 'package:flutter/material.dart';

import 'profile_page.dart';
import 'settings_screen.dart';

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
        ProfilePage(userName: widget.userName),
        const SettingsPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1832), Color(0xFF1F1C2C)], // Updated gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50), // Perfectly curved corners
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50), // Matches the container's curve
          topRight: Radius.circular(50),
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
          selectedItemColor: const Color(0xFF00D4FF),
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Ensures the body extends behind the bottom navigation bar
      body: _pages()[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
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
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1832), Color(0xFF1F1C2C)], // Updated gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kToolbarHeight + 20),
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
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
                        return _buildDashboardCard(
                          icon: Icons.add_circle_outline,
                          title: 'Lodge Complaint',
                          gradientColors: [
                            Color(0xFF6A61D1),
                            Color(0xFF4A47A3)
                          ],
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/submit-complaint',
                            arguments: userName,
                          ),
                        );
                      case 1:
                        return _buildDashboardCard(
                          icon: Icons.history,
                          title: 'Complaint History',
                          gradientColors: [
                            Color(0xFF928DAB),
                            Color(0xFF1F1C2C)
                          ],
                          onTap: () => Navigator.pushNamed(
                              context, '/complaint-history',
                              arguments: userName),
                        );
                      case 2:
                        return _buildDashboardCard(
                          icon: Icons.track_changes,
                          title: 'Track Status',
                          gradientColors: [
                            Color(0xFF00D4FF),
                            Color(0xFF0077B6)
                          ],
                          onTap: () =>
                              Navigator.pushNamed(context, '/track-complaint'),
                        );
                      case 3:
                        return _buildDashboardCard(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          gradientColors: [
                            Color(0xFFFFA726),
                            Color(0xFFFF7043)
                          ],
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardScreen =
        context.findAncestorWidgetOfExactType<UserDashboardScreen>();
    return SettingsScreen(userName: dashboardScreen?.userName ?? 'User');
  }
}
