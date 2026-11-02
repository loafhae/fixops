import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/views/create_ticket_view.dart';
import 'package:fixops_frontend/views/ticket_detail_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchStats();
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    final stats = admin.stats;

    final criticalTickets = ticketProvider.tickets
        .where((t) => t.priority == 'CRITICAL' && t.status != 'RESOLVED')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Operations Overview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              admin.fetchStats();
              ticketProvider.fetchTickets();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketView()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KPI Metric Cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      title: 'Total Tickets',
                      count: stats?['total_tickets']?.toString() ?? '0',
                      icon: Icons.confirmation_number_outlined,
                      color: AppColors.primary,
                    ),
                    _KpiCard(
                      title: 'Active Work Orders',
                      count: stats?['open_tickets']?.toString() ?? '0',
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.secondary,
                    ),
                    _KpiCard(
                      title: 'Critical Hazards',
                      count: stats?['critical_tickets']?.toString() ?? '0',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.priorityCritical,
                    ),
                    _KpiCard(
                      title: 'Resolved Repairs',
                      count: stats?['resolved_tickets']?.toString() ?? '0',
                      icon: Icons.check_circle_outline,
                      color: AppColors.priorityLow,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Critical Hazard Banner
                if (criticalTickets.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emergency, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'URGENT HAZARDS REQUIRING IMMEDIATE TRIAGE (${criticalTickets.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: criticalTickets.length,
                          itemBuilder: (context, idx) {
                            final ticket = criticalTickets[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${ticket.building} • ${ticket.floorRoom} (${ticket.category})'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TicketDetailView(ticket: ticket)),
                                  );
                                },
                                child: const Text('Triage Now'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // System Administration Server Status Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.dns_outlined, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'System Administration Node Status',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _ServerMetric(label: 'Backend Framework', value: 'FastAPI (Python 3.13)'),
                            _ServerMetric(label: 'Database Engine', value: 'SQLite / SQLAlchemy ORM'),
                            _ServerMetric(label: 'Security Layer', value: 'JWT + BCrypt + RBAC'),
                            _ServerMetric(label: 'Storage Pipeline', value: 'Local Disk /uploads/'),
                            _ServerMetric(label: 'Event Auditing', value: 'Active (Timestamped Logs)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withAlpha(25),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ServerMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
      ],
    );
  }
}

