import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAuditLogs();
    });
  }

  Color _actionColor(String action) {
    if (action.contains('CREATED')) return Colors.blue;
    if (action.contains('RESOLVED') || action.contains('STATUS')) return Colors.teal;
    if (action.contains('ROLE')) return Colors.purple;
    if (action.contains('ASSIGN')) return Colors.orange;
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Audit Trail (SysAdmin)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Audit Logs',
            onPressed: () => admin.fetchAuditLogs(),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Immutable System Audit Logs',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Text(
                                    'Complete timestamped history of user logins, role modifications, and ticket updates.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Chip(
                                label: Text('${admin.auditLogs.length} Events Logged'),
                                backgroundColor: AppColors.primary.withAlpha(20),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          if (admin.auditLogs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: Text('No audit log entries recorded yet.')),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('User / Actor', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Client IP', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Details / Payload', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: admin.auditLogs.map((log) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(dateFormat.format(log.timestamp), style: const TextStyle(fontSize: 12))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _actionColor(log.action).withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _actionColor(log.action).withAlpha(80)),
                                          ),
                                          child: Text(
                                            log.action,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _actionColor(log.action),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(log.userEmail ?? 'SYSTEM', style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(log.ipAddress ?? '127.0.0.1', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                      DataCell(
                                        SizedBox(
                                          width: 320,
                                          child: Text(
                                            log.details ?? '—',
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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

