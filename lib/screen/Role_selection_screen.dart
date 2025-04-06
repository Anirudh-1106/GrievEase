import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1832),
      appBar: AppBar(
        title: Text('',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.softLight,
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ).createShader(bounds);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.overlay,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A1832),
                  const Color(0xFF1C3A67).withOpacity(0.9),
                ],
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  Text(
                    'GrievEase',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose your role to continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAnimatedRoleCard(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: 'User',
                        subtitle: 'Submit & Track',
                        gradientColors: const [
                          Color(0xFF4568DC),
                          Color(0xFFB06AB3),
                        ],
                        route: '/login',
                      ),
                      _buildAnimatedRoleCard(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin',
                        subtitle: 'Manage & Review',
                        gradientColors: const [
                          Color(0xFF1E3C72),
                          Color(0xFF2A5298),
                        ],
                        route: '/admin-login',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4568DC),
            const Color(0xFFB06AB3).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4568DC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.hexagon_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 60,
          ),
          const Icon(
            Icons.safety_check_rounded,
            color: Colors.white,
            size: 45,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required String route,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 1, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 160,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Icon(
                              icon,
                              size: 100,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, size: 45, color: Colors.white),
                                const Spacer(),
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
