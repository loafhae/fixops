import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

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
    if (action.contains('CREATED')) return AppColors.secondary;
    if (action.contains('RESOLVED') || action.contains('STATUS')) return const Color(0xFF2E7D32);
    if (action.contains('ROLE') || action.contains('AUTH') || action.contains('LOGIN')) return AppColors.primary;
    if (action.contains('ASSIGN')) return const Color(0xFFFF6433);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Activity Audit Trail (SysAdmin)'),
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
            tooltip: 'Refresh Audit Logs',
            onPressed: () => admin.fetchAuditLogs(),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Immutable System Audit Logs',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                      ),
                                      Text(
                                        'Timestamped audit events of user logins, role changes, and ticket actions.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
                                ),
                                child: Text(
                                  '${admin.auditLogs.length} Events Logged',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          if (admin.auditLogs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text('No audit log entries recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppColors.cream.withAlpha(120)),
                                columns: const [
                                  DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                  DataColumn(label: Text('User / Actor', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                  DataColumn(label: Text('Client IP', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                  DataColumn(label: Text('Details / Payload', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain))),
                                ],
                                rows: admin.auditLogs.map((log) {
                                  final col = _actionColor(log.action);
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(dateFormat.format(log.timestamp), style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: col.withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: col.withAlpha(90)),
                                          ),
                                          child: Text(
                                            log.action,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: col,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(log.userEmail ?? 'SYSTEM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                      DataCell(Text(log.ipAddress ?? '127.0.0.1', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMuted))),
                                      DataCell(
                                        SizedBox(
                                          width: 320,
                                          child: Text(
                                            log.details ?? '—',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMain),
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
