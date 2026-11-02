import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';

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
      appBar: AppBar(
        title: const Text('Report Facility Issue'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Submit Maintenance Request',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Provide exact location and attach photo evidence for immediate technician dispatch.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const Divider(height: 32),

                      if (_selectedPriority == 'CRITICAL')
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'CRITICAL: This ticket will trigger emergency triage for structural, electrical, or physical hazards.',
                                  style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Issue Summary / Title *',
                          hintText: 'e.g. Exposed live wire, Restroom water leak, Broken chair',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Severity / Priority *',
                                border: OutlineInputBorder(),
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
                                hintText: 'e.g. IT Building, Admin Hall',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Building required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              decoration: const InputDecoration(
                                labelText: 'Floor / Room Number *',
                                hintText: 'e.g. 3rd Floor, Lab 304',
                                border: OutlineInputBorder(),
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
                          labelText: 'Detailed Description *',
                          hintText: 'Describe the problem, severity, when it started, and any hazards.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Description required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Photo Evidence Section
                      const Text(
                        'Photo Evidence (Recommended):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            if (_photoBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _photoBytes!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _photoFilename ?? 'No photo selected yet',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'PNG, JPG, or JPEG evidence for technician verification.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: Text(_photoBytes == null ? 'Attach Photo' : 'Change Photo'),
                                    onPressed: _pickPhoto,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: ticketProvider.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final created = await ticketProvider.createTicket(
                                  title: _titleController.text,
                                  description: _descController.text,
                                  building: _buildingController.text,
                                  floorRoom: _roomController.text,
                                  category: _selectedCategory,
                                  priority: _selectedPriority,
                                  photoBytes: _photoBytes,
                                  photoFilename: _photoFilename,
                                );
                                if (created != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green.shade800,
                                      content: Text('Ticket #${created.ticketNumber} submitted successfully!'),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        child: ticketProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Submit Ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
