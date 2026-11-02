import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/models/ticket_model.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/views/create_ticket_view.dart';
import 'package:fixops_frontend/views/ticket_detail_view.dart';

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
      appBar: AppBar(
        title: const Text('Facility Tickets'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tickets',
            onPressed: () => ticketProvider.fetchTickets(),
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
      body: RefreshIndicator(
        onRefresh: () => ticketProvider.fetchTickets(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filters Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tickets by keyword, title, building, or room...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      ticketProvider.setSearchQuery(null);
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (val) => ticketProvider.setSearchQuery(val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => ticketProvider.setSearchQuery(_searchController.text),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (!isStaffOrStudent) ...[
                          FilterChip(
                            label: const Text('My Submissions Only'),
                            selected: ticketProvider.myTicketsOnly,
                            onSelected: (val) => ticketProvider.toggleMyTickets(val),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _PriorityFilterChip(label: 'All Priorities', value: 'ALL', provider: ticketProvider),
                        _PriorityFilterChip(label: 'Critical', value: 'CRITICAL', color: AppColors.priorityCritical, provider: ticketProvider),
                        _PriorityFilterChip(label: 'High', value: 'HIGH', color: AppColors.priorityHigh, provider: ticketProvider),
                        _PriorityFilterChip(label: 'Medium', value: 'MEDIUM', color: AppColors.priorityMedium, provider: ticketProvider),
                        _PriorityFilterChip(label: 'Low', value: 'LOW', color: AppColors.priorityLow, provider: ticketProvider),
                        const SizedBox(width: 16),
                        _StatusFilterChip(label: 'All Statuses', value: 'ALL', provider: ticketProvider),
                        _StatusFilterChip(label: 'Submitted', value: 'SUBMITTED', provider: ticketProvider),
                        _StatusFilterChip(label: 'In Progress', value: 'IN_PROGRESS', provider: ticketProvider),
                        _StatusFilterChip(label: 'Resolved', value: 'RESOLVED', provider: ticketProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tickets List
                  if (ticketProvider.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  else if (ticketProvider.tickets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(60),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No facility tickets found matching the criteria.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          const Text('Click "Report Issue" to submit a maintenance request.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ticketProvider.tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = ticketProvider.tickets[index];
                        return _TicketCard(ticket: ticket);
                      },
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

class _PriorityFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final TicketProvider provider;

  const _PriorityFilterChip({required this.label, required this.value, this.color, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isSelected = (provider.selectedPriority ?? 'ALL') == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color?.withAlpha(50) ?? AppColors.primary.withAlpha(40),
        onSelected: (_) => provider.setFilterPriority(value),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final TicketProvider provider;

  const _StatusFilterChip({required this.label, required this.value, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isSelected = (provider.selectedStatus ?? 'ALL') == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setFilterStatus(value),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ticket.priority == 'CRITICAL'
            ? const BorderSide(color: AppColors.priorityCritical, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TicketDetailView(ticket: ticket)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.ticketNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.priorityColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.priority,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: ticket.priorityColor),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
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
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${ticket.building} • ${ticket.floorRoom}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Spacer(),
                  if (ticket.attachments.isNotEmpty) ...[
                    const Icon(Icons.attach_file, size: 16, color: AppColors.secondary),
                    Text('${ticket.attachments.length}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                  ],
                  Text(dateFormat.format(ticket.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
