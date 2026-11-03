import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/models/user_model.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchUsers();
    });
  }

  void _showEditRoleDialog(BuildContext context, UserModel user) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    String selectedRole = user.role;
    bool isActive = user.isActive;

    final roles = ['USER', 'TECHNICIAN', 'ADMIN'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit User: ${user.fullName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                const Text('Assigned Role (RBAC):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: const Color(0xFF2E7D32),
                  title: const Text('Account Active Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)),
                  subtitle: Text(isActive ? 'Account active & verified' : 'Access blocked by SysAdmin', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFF6433)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(70),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          final success = await admin.updateUserRole(user.id, selectedRole, isActive: isActive);
                          if (success && context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.accentLime,
                                content: Text('User permissions updated successfully!', style: TextStyle(color: AppColors.textMain)),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('User & Access Management (RBAC)'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(160),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(200), width: 1)),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Users',
            onPressed: () => admin.fetchUsers(),
          ),
        ],
      ),
      body: GlassBackground(
        child: admin.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Accounts & Role-Based Access Control',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                  ),
                                  Text(
                                    'Manage user privileges, technician assignment eligibility, and account status.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.cream.withAlpha(120)),
                              columns: const [
                                DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Role (RBAC)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                              ],
                              rows: admin.users.map((u) {
                                Color roleColor;
                                if (u.isAdmin) {
                                  roleColor = AppColors.primary;
                                } else if (u.isTechnician) {
                                  roleColor = AppColors.secondary;
                                } else {
                                  roleColor = const Color(0xFF6B5854);
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: roleColor.withAlpha(35),
                                            child: Text(
                                              (u.fullName.isNotEmpty ? u.fullName[0] : 'U').toUpperCase(),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(u.email, style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(u.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: roleColor.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: roleColor.withAlpha(90)),
                                        ),
                                        child: Text(
                                          u.role,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: roleColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: u.isActive
                                              ? AppColors.accentLime.withAlpha(45)
                                              : AppColors.primary.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: u.isActive
                                                ? const Color(0xFF55C728)
                                                : AppColors.primary.withAlpha(90),
                                          ),
                                        ),
                                        child: Text(
                                          u.isActive ? 'ACTIVE' : 'BLOCKED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: u.isActive ? const Color(0xFF1B5E20) : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(u.createdAt != null ? dateFormat.format(u.createdAt!) : '—', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                                    DataCell(
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: BorderSide(color: AppColors.primary.withAlpha(90)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.edit_rounded, size: 14),
                                        label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showEditRoleDialog(context, u),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
