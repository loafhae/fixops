import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

class CreateTicketView extends StatefulWidget {
  const CreateTicketView({super.key});

  @override
  State<CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<CreateTicketView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();

  String _selectedCategory = 'ELECTRICAL';
  String _selectedPriority = 'MEDIUM';

  Uint8List? _photoBytes;
  String? _photoFilename;

  final List<String> _categories = [
    'ELECTRICAL',
    'PLUMBING',
    'STRUCTURAL',
    'HVAC',
    'FURNITURE',
    'SAFETY_HAZARD',
    'OTHER',
  ];

  final List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _buildingController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoFilename = file.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Report Facility Issue'),
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
      ),
      body: GlassBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: GlassContainer(
                blur: 24,
                opacity: 0.82,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(220), width: 1.5),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_alert_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Submit Maintenance Request',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Provide location and attach evidence for quick dispatch.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      if (_selectedPriority == 'CRITICAL')
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.2),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'CRITICAL: This report triggers emergency triage for immediate electrical, structural, or life-safety hazards.',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Issue Summary / Title *',
                          hintText: 'e.g. Broken AC unit, live wire exposed, pipe leaking',
                          prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
                              ),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Severity / Priority *',
                                prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primary),
                              ),
                              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setState(() => _selectedPriority = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buildingController,
                              decoration: const InputDecoration(
                                labelText: 'Building / Wing *',
                                hintText: 'e.g. IT Building',
                                prefixIcon: Icon(Icons.business_rounded, color: AppColors.primary),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Building required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              decoration: const InputDecoration(
                                labelText: 'Floor / Room *',
                                hintText: 'e.g. 3rd Floor, Lab 304',
                                prefixIcon: Icon(Icons.meeting_room_outlined, color: AppColors.primary),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Room required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Description of the Issue *',
                          hintText: 'Describe what you observe, how severe it is, and any safety precautions needed...',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please describe the issue' : null,
                      ),
                      const SizedBox(height: 20),

                      // Photo Evidence Attachment Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withAlpha(90),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.secondary.withAlpha(90), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Photo Evidence (Optional but Recommended)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_photoBytes != null) ...[
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _photoBytes!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                        onPressed: () => setState(() {
                                          _photoBytes = null;
                                          _photoFilename = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('File: $_photoFilename', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ] else
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  side: BorderSide(color: AppColors.secondary.withAlpha(120)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                                label: const Text('Attach Incident Photo from Device', style: TextStyle(color: AppColors.textMain)),
                                onPressed: _pickPhoto,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF6433)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: ticketProvider.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;

                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  final newTicket = await ticketProvider.createTicket(
                                    title: _titleController.text.trim(),
                                    description: _descController.text.trim(),
                                    building: _buildingController.text.trim(),
                                    floorRoom: _roomController.text.trim(),
                                    category: _selectedCategory,
                                    priority: _selectedPriority,
                                    photoBytes: _photoBytes,
                                    photoFilename: _photoFilename,
                                  );

                                  if (newTicket != null && mounted) {
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppColors.accentLime,
                                        content: Text('Facility ticket reported successfully!', style: TextStyle(color: AppColors.textMain)),
                                      ),
                                    );
                                  } else if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.primary,
                                        content: Text(ticketProvider.errorMessage ?? 'Failed to submit report'),
                                      ),
                                    );
                                  }
                                },
                          child: ticketProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Submit Ticket & Alert Facilities',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
