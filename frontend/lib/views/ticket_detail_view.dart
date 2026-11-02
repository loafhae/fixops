import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/models/ticket_model.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';

class TicketDetailView extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailView({super.key, required this.ticket});

  void _showUpdateStatusDialog(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    String newStatus = ticket.status;
    final notesController = TextEditingController(text: ticket.resolutionNotes ?? '');

    final statuses = ['SUBMITTED', 'UNDER_REVIEW', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Status: #${ticket.ticketNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select New Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => newStatus = val!),
                ),
                const SizedBox(height: 16),
                const Text('Resolution Notes / Progress Update:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Replaced breaker switch, repaired conduit, waiting on spare parts...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ticketProvider.updateStatus(
                  ticket.id,
                  newStatus,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                );
                if (success && context.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket status updated successfully!')),
                  );
                }
              },
              child: const Text('Save Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final steps = ['SUBMITTED', 'UNDER_REVIEW', 'IN_PROGRESS', 'RESOLVED'];
    final currentIndex = steps.indexOf(ticket.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lifecycle Progression', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index % 2 == 1) {
                // Divider line
                final stepIndex = (index ~/ 2) + 1;
                final isDone = currentIndex >= stepIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isDone ? AppColors.primary : Colors.grey.shade300,
                  ),
                );
              } else {
                final stepIndex = index ~/ 2;
                final isDone = currentIndex >= stepIndex;
                final isCurrent = currentIndex == stepIndex;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : (isDone ? AppColors.secondary : Colors.grey.shade300),
                      child: Icon(
                        isDone && !isCurrent ? Icons.check : Icons.circle,
                        size: isDone && !isCurrent ? 14 : 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[stepIndex].replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    final user = auth.currentUser;

    final canManage = user != null && (user.isAdmin || user.isTechnician);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.ticketNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Update Status & Notes',
              onPressed: () => _showUpdateStatusDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket.title,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Submitted on ${dateFormat.format(ticket.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(ticket.priority, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: ticket.priorityColor,
                                ),
                                Chip(
                                  label: Text(ticket.status.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: ticket.statusColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStatusTimeline(),
                        const Divider(height: 32),

                        // Location & Category Grid
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            _InfoItem(icon: Icons.business, label: 'Building', value: ticket.building),
                            _InfoItem(icon: Icons.meeting_room, label: 'Floor / Room', value: ticket.floorRoom),
                            _InfoItem(icon: Icons.category, label: 'Category', value: ticket.category),
                            _InfoItem(
                              icon: Icons.person,
                              label: 'Reported By',
                              value: ticket.reporter?.fullName ?? 'End-User',
                            ),
                            _InfoItem(
                              icon: Icons.handyman,
                              label: 'Assigned Tech',
                              value: ticket.technician?.fullName ?? 'Unassigned',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Issue Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 12),
                        Text(
                          ticket.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        if (ticket.resolutionNotes != null && ticket.resolutionNotes!.isNotEmpty) ...[
                          const Divider(height: 28),
                          const Text('Technician Resolution Notes:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              ticket.resolutionNotes!,
                              style: TextStyle(color: Colors.green.shade900, height: 1.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Photo Evidence Gallery Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Photo Evidence & Attachments',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              '${ticket.attachments.length} attachment(s)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (ticket.attachments.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No photos attached for this report.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.3,
                            ),
                            itemCount: ticket.attachments.length,
                            itemBuilder: (context, idx) {
                              final att = ticket.attachments[idx];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.grey.shade200,
                                  child: Image.network(
                                    att.fullUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.broken_image, color: Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(att.fileName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Technician Action Buttons
                if (canManage && ticket.assignedToId == null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.handyman),
                    label: const Text('Claim This Ticket (Take Ownership)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final success = await ticketProvider.claimTicket(ticket.id, user.id);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You have claimed this repair ticket!')),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          ],
        ),
      ],
    );
  }
}

