import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/views/dashboard_view.dart';
import 'package:fixops_frontend/views/ticket_list_view.dart';
import 'package:fixops_frontend/views/audit_logs_view.dart';
import 'package:fixops_frontend/views/user_management_view.dart';

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
        selectedIcon: Icons.confirmation_number,
        view: const TicketListView(),
      ),
      if (user != null && !user.isStaffOrStudent)
        _NavItem(
          title: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          view: const DashboardView(),
        ),
      if (user != null && user.isAdmin) ...[
        _NavItem(
          title: 'Audit Trail',
          icon: Icons.history_toggle_off,
          selectedIcon: Icons.history,
          view: const AuditLogsView(),
        ),
        _NavItem(
          title: 'Users & RBAC',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          view: const UserManagementView(),
        ),
      ],
    ];

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    if (isDesktopOrWeb) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop / Web Sidebar
            Container(
              width: 260,
              color: const Color(0xFF0F172A), // Dark slate navy
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.build, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIXOPS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Facility Ops Portal',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // Navigation Links
                  Expanded(
                    child: ListView.builder(
                      itemCount: navItems.length,
                      itemBuilder: (context, idx) {
                        final item = navItems[idx];
                        final isSelected = _selectedIndex == idx;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary.withAlpha(50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected ? Colors.white : Colors.white70,
                              size: 22,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.secondary,
                              child: Text(
                                (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    user?.role ?? 'Role',
                                    style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.logout, size: 16),
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

            // Content Area
            Expanded(child: navItems[_selectedIndex].view),
          ],
        ),
      );
    } else {
      // Mobile View: Bottom Navigation Bar
      return Scaffold(
        body: navItems[_selectedIndex].view,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.selectedIcon),
              label: item.title,
            );
          }).toList(),
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

