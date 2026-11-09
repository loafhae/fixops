import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/core/models/ticket_model.dart';
import 'package:fixops_frontend/shared/widgets/glass_container.dart';

class TicketDetailView extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailView({super.key, required this.ticket});

  Widget _buildStatusTimeline() {
    final steps = ['SUBMITTED', 'UNDER_REVIEW', 'IN_PROGRESS', 'RESOLVED'];
    final currentIndex = steps.indexOf(ticket.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cream.withAlpha(100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withAlpha(80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIFECYCLE PROGRESSION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index % 2 == 1) {
                // Connecting line
                final stepIndex = (index ~/ 2) + 1;
                final isDone = currentIndex >= stepIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.accentLime
                          : Colors.black.withAlpha(25),
                      borderRadius: BorderRadius.circular(2),
                    ),
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
                          : (isDone
                                ? AppColors.accentLime
                                : Colors.white.withAlpha(180)),
                      child: Icon(
                        isDone && !isCurrent
                            ? Icons.check_rounded
                            : (isCurrent
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.circle),
                        size: isDone && !isCurrent ? 14 : 8,
                        color: isCurrent || isDone
                            ? (isDone && !isCurrent
                                  ? const Color(0xFF1B5E20)
                                  : Colors.white)
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[stepIndex].replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textMuted,
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
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text('Ticket #${ticket.ticketNumber}'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(160),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withAlpha(200),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Header Glass Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Submitted on ${dateFormat.format(ticket.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ticket.priorityColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: ticket.priorityColor.withAlpha(
                                        120,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    ticket.priority,
                                    style: TextStyle(
                                      color: ticket.priorityColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ticket.statusColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: ticket.statusColor.withAlpha(120),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    ticket.status.replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: ticket.statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                            _InfoItem(
                              icon: Icons.business_rounded,
                              label: 'Building',
                              value: ticket.building,
                            ),
                            _InfoItem(
                              icon: Icons.meeting_room_rounded,
                              label: 'Floor / Room',
                              value: ticket.floorRoom,
                            ),
                            _InfoItem(
                              icon: Icons.category_rounded,
                              label: 'Category',
                              value: ticket.category,
                            ),
                            _InfoItem(
                              icon: Icons.person_rounded,
                              label: 'Reported By',
                              value: ticket.reporter?.fullName ?? 'End-User',
                            ),
                            _InfoItem(
                              icon: Icons.handyman_rounded,
                              label: 'Assigned Tech',
                              value:
                                  ticket.technician?.fullName ?? 'Unassigned',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Issue Details Glass Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Issue Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textMain,
                          ),
                        ),
                        if (ticket.resolutionNotes != null &&
                            ticket.resolutionNotes!.isNotEmpty) ...[
                          const Divider(height: 28),
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Technician Resolution Notes:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentLime.withAlpha(120),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ticket.resolutionNotes!,
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Photo Evidence & Attachments Glass Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Photo Evidence & Attachments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${ticket.attachments.length} photo(s)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
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
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 38,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No photos attached for this report.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.3,
                                ),
                            itemCount: ticket.attachments.length,
                            itemBuilder: (context, idx) {
                              final att = ticket.attachments[idx];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(220),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Image.network(
                                    att.fullUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.broken_image_rounded,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            att.fileName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
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
                  const SizedBox(height: 24),
                ],
              ),
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

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
