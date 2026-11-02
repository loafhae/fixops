import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/models/user_model.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';

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
        builder: (context, setState) => AlertDialog(
          title: Text('Edit User: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              const Text('Assigned Role (RBAC):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => selectedRole = val!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account Active Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(isActive ? 'User can log in' : 'Access blocked by SysAdmin'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await admin.updateUserRole(user.id, selectedRole, isActive: isActive);
                if (success && context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User account permissions updated successfully!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Access Management (RBAC)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => admin.fetchUsers(),
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'System Accounts & Role-Based Access Control',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage user privileges, technician assignment eligibility, and account activation.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const Divider(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: admin.users.map((u) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(u.email)),
                                    DataCell(Text(u.department)),
                                    DataCell(
                                      Chip(
                                        label: Text(u.role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        backgroundColor: u.isAdmin
                                            ? Colors.indigo.shade50
                                            : (u.isTechnician ? Colors.teal.shade50 : Colors.grey.shade100),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        u.isActive ? 'Active' : 'Disabled',
                                        style: TextStyle(
                                          color: u.isActive ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(u.createdAt != null ? dateFormat.format(u.createdAt!) : '—')),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
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

