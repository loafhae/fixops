import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/views/dashboard_view.dart';
import 'package:fixops_frontend/views/ticket_list_view.dart';
import 'package:fixops_frontend/views/audit_logs_view.dart';
import 'package:fixops_frontend/views/user_management_view.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isDesktopOrWeb = MediaQuery.of(context).size.width >= 900;

    // Build navigation items based on role
    final List<_NavItem> navItems = [
      _NavItem(
        title: 'Tickets',
        icon: Icons.confirmation_number_outlined,
        selectedIcon: Icons.confirmation_number_rounded,
        view: const TicketListView(),
      ),
      if (user != null && !user.isStaffOrStudent)
        _NavItem(
          title: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          view: const DashboardView(),
        ),
      if (user != null && user.isAdmin) ...[
        _NavItem(
          title: 'Audit Trail',
          icon: Icons.history_toggle_off_rounded,
          selectedIcon: Icons.history_rounded,
          view: const AuditLogsView(),
        ),
        _NavItem(
          title: 'Users & RBAC',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts_rounded,
          view: const UserManagementView(),
        ),
      ],
    ];

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    if (isDesktopOrWeb) {
      return Scaffold(
        body: GlassBackground(
          child: Row(
            children: [
              // Desktop / Web Frosted Glass Sidebar
              Container(
                width: 270,
                decoration: BoxDecoration(
                  color: AppColors.glassDark,
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withAlpha(35),
                      width: 1.2,
                    ),
                  ),
                ),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      children: [
                        // App Brand Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppColors.primary, AppColors.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(120),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.build_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'FIXOPS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 19,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentLime,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'Facility Ops Portal',
                                    style: TextStyle(
                                      color: Color(0xFFFFA97B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.white.withAlpha(25), height: 1),
                        const SizedBox(height: 18),

                        // Navigation Links
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: navItems.length,
                            itemBuilder: (context, idx) {
                              final item = navItems[idx];
                              final isSelected = _selectedIndex == idx;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.primary.withAlpha(180),
                                            AppColors.secondary.withAlpha(120),
                                          ],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white.withAlpha(80),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    color: isSelected ? Colors.white : Colors.white70,
                                    size: 22,
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onTap: () => setState(() => _selectedIndex = idx),
                                ),
                              );
                            },
                          ),
                        ),

                        // User Profile Box at Sidebar Bottom
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(35), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.fullName ?? 'User',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentLime.withAlpha(40),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.accentLime.withAlpha(100), width: 0.8),
                                          ),
                                          child: Text(
                                            user?.role ?? 'Role',
                                            style: const TextStyle(
                                              color: AppColors.accentLime,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withAlpha(50)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.secondary),
                                  label: const Text('Sign Out', style: TextStyle(fontSize: 12)),
                                  onPressed: () => auth.logout(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content Area
              Expanded(
                child: navItems[_selectedIndex].view,
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile View: Floating Frosted Glass Bottom Navigation Bar
      return Scaffold(
        extendBody: true,
        body: GlassBackground(
          child: navItems[_selectedIndex].view,
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withAlpha(220), width: 1.5),
                ),
                child: BottomNavigationBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  currentIndex: _selectedIndex,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textMuted,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  type: BottomNavigationBarType.fixed,
                  onTap: (idx) => setState(() => _selectedIndex = idx),
                  items: navItems.map((item) {
                    return BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.selectedIcon),
                      label: item.title,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget view;

  _NavItem({required this.title, required this.icon, required this.selectedIcon, required this.view});
}
