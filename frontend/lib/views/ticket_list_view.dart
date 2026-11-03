import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/models/ticket_model.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/views/create_ticket_view.dart';
import 'package:fixops_frontend/views/ticket_detail_view.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

class TicketListView extends StatefulWidget {
  const TicketListView({super.key});

  @override
  State<TicketListView> createState() => _TicketListViewState();
}

class _TicketListViewState extends State<TicketListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isStaffOrStudent = user?.isStaffOrStudent ?? false;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Facility Tickets'),
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
            tooltip: 'Refresh Tickets',
            onPressed: () => ticketProvider.fetchTickets(),
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
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ticketProvider.fetchTickets(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search & Actions Bar
                    Row(
                      children: [
                        Expanded(
                          child: GlassContainer(
                            blur: 16,
                            opacity: 0.75,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            borderRadius: BorderRadius.circular(14),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search tickets by keyword, location, or room...',
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                        onPressed: () {
                                          _searchController.clear();
                                          ticketProvider.setSearchQuery(null);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (val) => ticketProvider.setSearchQuery(val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => ticketProvider.setSearchQuery(_searchController.text),
                            child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Filter Chips Bar (Priority, Status, My Submissions)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (!isStaffOrStudent) ...[
                            _GlassFilterPill(
                              label: 'My Submissions',
                              icon: Icons.person_outline_rounded,
                              isSelected: ticketProvider.myTicketsOnly,
                              activeColor: AppColors.secondary,
                              onTap: () => ticketProvider.toggleMyTickets(!ticketProvider.myTicketsOnly),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _PriorityFilterPill(label: 'All Priorities', value: 'ALL', provider: ticketProvider),
                          _PriorityFilterPill(label: 'Critical', value: 'CRITICAL', color: AppColors.priorityCritical, provider: ticketProvider),
                          _PriorityFilterPill(label: 'High', value: 'HIGH', color: AppColors.priorityHigh, provider: ticketProvider),
                          _PriorityFilterPill(label: 'Medium', value: 'MEDIUM', color: AppColors.priorityMedium, provider: ticketProvider),
                          _PriorityFilterPill(label: 'Low', value: 'LOW', color: AppColors.accentLime, provider: ticketProvider),
                          const SizedBox(width: 16),
                          _StatusFilterPill(label: 'All Statuses', value: 'ALL', provider: ticketProvider),
                          _StatusFilterPill(label: 'Submitted', value: 'SUBMITTED', provider: ticketProvider),
                          _StatusFilterPill(label: 'In Progress', value: 'IN_PROGRESS', activeColor: AppColors.secondary, provider: ticketProvider),
                          _StatusFilterPill(label: 'Resolved', value: 'RESOLVED', activeColor: AppColors.accentLime, provider: ticketProvider),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tickets List
                    if (ticketProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (ticketProvider.tickets.isEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(48),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inbox_rounded, size: 48, color: AppColors.secondary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No facility tickets found matching the criteria.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                            ),
                            const SizedBox(height: 6),
                            const Text('Click "Report Issue" to submit a maintenance request.', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ticketProvider.tickets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final ticket = ticketProvider.tickets[index];
                          return _TicketGlassCard(ticket: ticket);
                        },
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

class _GlassFilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _GlassFilterPill({
    required this.label,
    this.icon,
    required this.isSelected,
    this.activeColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withAlpha(220),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? activeColor.withAlpha(50) : Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMain),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final TicketProvider provider;

  const _PriorityFilterPill({required this.label, required this.value, this.color, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isSelected = (provider.selectedPriority ?? 'ALL') == value;
    final effectiveColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _GlassFilterPill(
        label: label,
        isSelected: isSelected,
        activeColor: effectiveColor,
        onTap: () => provider.setFilterPriority(value),
      ),
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? activeColor;
  final TicketProvider provider;

  const _StatusFilterPill({required this.label, required this.value, this.activeColor, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isSelected = (provider.selectedStatus ?? 'ALL') == value;
    final effectiveColor = activeColor ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _GlassFilterPill(
        label: label,
        isSelected: isSelected,
        activeColor: effectiveColor,
        onTap: () => provider.setFilterStatus(value),
      ),
    );
  }
}

class _TicketGlassCard extends StatelessWidget {
  final TicketModel ticket;

  const _TicketGlassCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCritical = ticket.priority == 'CRITICAL';

    return GlassContainer(
      blur: 18,
      opacity: 0.82,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isCritical ? AppColors.primary.withAlpha(180) : Colors.white.withAlpha(220),
        width: isCritical ? 1.8 : 1.2,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TicketDetailView(ticket: ticket)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ticket Number Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
                  ),
                  child: Text(
                    ticket.ticketNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.priorityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ticket.priorityColor.withAlpha(120), width: 1),
                  ),
                  child: Text(
                    ticket.priority,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: ticket.priorityColor),
                  ),
                ),
                const Spacer(),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ticket.statusColor.withAlpha(120), width: 1),
                  ),
                  child: Text(
                    ticket.status.replaceAll('_', ' '),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: ticket.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${ticket.building} • ${ticket.floorRoom}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (ticket.attachments.isNotEmpty) ...[
                  const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.secondary),
                  Text(
                    '${ticket.attachments.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(dateFormat.format(ticket.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
