import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/views/create_ticket_view.dart';
import 'package:fixops_frontend/views/ticket_detail_view.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

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
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Facility Operations Overview'),
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
            tooltip: 'Refresh Stats',
            onPressed: () {
              admin.fetchStats();
              ticketProvider.fetchTickets();
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFFF6433)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateTicketView()),
            );
          },
        ),
      ),
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                      _KpiGlassCard(
                        title: 'Total Tickets',
                        count: stats?['total_tickets']?.toString() ?? '0',
                        icon: Icons.confirmation_number_outlined,
                        accentColor: AppColors.primary,
                        gradientColors: [Colors.white, const Color(0xFFFFECCB)],
                      ),
                      _KpiGlassCard(
                        title: 'Active Work Orders',
                        count: stats?['open_tickets']?.toString() ?? '0',
                        icon: Icons.pending_actions_rounded,
                        accentColor: AppColors.secondary,
                        gradientColors: [Colors.white, const Color(0xFFFFF1E6)],
                      ),
                      _KpiGlassCard(
                        title: 'Critical Hazards',
                        count: stats?['critical_tickets']?.toString() ?? '0',
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppColors.primary,
                        gradientColors: [Colors.white, const Color(0xFFFFECEB)],
                      ),
                      _KpiGlassCard(
                        title: 'Resolved Repairs',
                        count: stats?['resolved_tickets']?.toString() ?? '0',
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: AppColors.accentLime,
                        textColor: const Color(0xFF2E7D32),
                        gradientColors: [Colors.white, const Color(0xFFF2FDE8)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Critical Hazard Banner (if any)
                  if (criticalTickets.isNotEmpty) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withAlpha(160), width: 1.5),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(220),
                          const Color(0xFFFFECEB).withAlpha(220),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'URGENT HAZARDS REQUIRING IMMEDIATE TRIAGE (${criticalTickets.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: criticalTickets.length,
                            separatorBuilder: (_, _) => Divider(color: AppColors.primary.withAlpha(40), height: 16),
                            itemBuilder: (context, idx) {
                              final ticket = criticalTickets[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  ticket.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
                                ),
                                subtitle: Text(
                                  '${ticket.building} • ${ticket.floorRoom} (${ticket.category})',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TicketDetailView(ticket: ticket)),
                                    );
                                  },
                                  child: const Text('Triage Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // System Administration Server Status Glass Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'System Administration Node Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textMain,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentLime.withAlpha(60),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF55C728), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF2E7D32)),
                                  SizedBox(width: 6),
                                  Text(
                                    'ONLINE / ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Wrap(
                          spacing: 28,
                          runSpacing: 16,
                          children: const [
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGlassCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color accentColor;
  final Color? textColor;
  final List<Color> gradientColors;

  const _KpiGlassCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    this.textColor,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: GlassContainer(
        padding: const EdgeInsets.all(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(220), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withAlpha(210),
            gradientColors[1].withAlpha(180),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withAlpha(100), width: 1),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: textColor ?? accentColor,
              ),
            ),
          ],
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
      ],
    );
  }
}
