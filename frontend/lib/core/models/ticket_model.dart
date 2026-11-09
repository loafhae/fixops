import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/core/models/user_model.dart';

class AttachmentModel {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final DateTime? uploadedAt;

  AttachmentModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.uploadedAt,
  });

  String get fullUrl => '${AppConfig.serverRootUrl}$filePath';

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? '',
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? 'IMAGE_EVIDENCE',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
    );
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String building;
  final String floorRoom;
  final String category;
  final String priority;
  final String status;
  final String reportedById;
  final String? assignedToId;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? reporter;
  final UserModel? technician;
  final List<AttachmentModel> attachments;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.building,
    required this.floorRoom,
    required this.category,
    required this.priority,
    required this.status,
    required this.reportedById,
    this.assignedToId,
    this.resolutionNotes,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reporter,
    this.technician,
    this.attachments = const [],
  });

  Color get priorityColor {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.priorityCritical;
      case 'HIGH':
        return AppColors.priorityHigh;
      case 'MEDIUM':
        return AppColors.priorityMedium;
      case 'LOW':
      default:
        return AppColors.priorityLow;
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
        return AppColors.statusResolved;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      case 'UNDER_REVIEW':
        return AppColors.statusUnderReview;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      case 'SUBMITTED':
      default:
        return AppColors.statusSubmitted;
    }
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      ticketNumber: json['ticket_number'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      building: json['building'] ?? '',
      floorRoom: json['floor_room'] ?? '',
      category: json['category'] ?? 'OTHER',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'SUBMITTED',
      reportedById: json['reported_by_id'] ?? '',
      assignedToId: json['assigned_to_id'],
      resolutionNotes: json['resolution_notes'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      reporter: json['reporter'] != null
          ? UserModel.fromJson(json['reporter'])
          : null,
      technician: json['technician'] != null
          ? UserModel.fromJson(json['technician'])
          : null,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
