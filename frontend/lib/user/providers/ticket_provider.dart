import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/api_service.dart';
import 'package:fixops_frontend/core/models/ticket_model.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCategory;
  String? _selectedPriority;
  String? _selectedStatus;
  String? _searchQuery;
  bool _myTicketsOnly = false;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedCategory => _selectedCategory;
  String? get selectedPriority => _selectedPriority;
  String? get selectedStatus => _selectedStatus;
  bool get myTicketsOnly => _myTicketsOnly;

  final ApiService _api = ApiService();

  void setFilterCategory(String? cat) {
    _selectedCategory = cat;
    fetchTickets();
  }

  void setFilterPriority(String? prio) {
    _selectedPriority = prio;
    fetchTickets();
  }

  void setFilterStatus(String? stat) {
    _selectedStatus = stat;
    fetchTickets();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchTickets();
  }

  void toggleMyTickets(bool val) {
    _myTicketsOnly = val;
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedCategory != null && _selectedCategory != 'ALL') {
        queryParams['category'] = _selectedCategory;
      }
      if (_selectedPriority != null && _selectedPriority != 'ALL') {
        queryParams['priority'] = _selectedPriority;
      }
      if (_selectedStatus != null && _selectedStatus != 'ALL') {
        queryParams['status'] = _selectedStatus;
      }
      if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery!.trim();
      }
      if (_myTicketsOnly) {
        queryParams['my_tickets_only'] = 'true';
      }

      final data = await _api.get('/tickets/', queryParams: queryParams);
      if (data is List) {
        _tickets = data.map((json) => TicketModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketModel?> createTicket({
    required String title,
    required String description,
    required String building,
    required String floorRoom,
    required String category,
    required String priority,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.post(
        '/tickets/',
        body: {
          'title': title,
          'description': description,
          'building': building,
          'floor_room': floorRoom,
          'category': category,
          'priority': priority,
        },
      );

      final newTicket = TicketModel.fromJson(data);

      // If photo attached, upload it
      if (photoBytes != null && photoFilename != null) {
        await _api.uploadFile(
          '/tickets/${newTicket.id}/attachments',
          photoBytes,
          photoFilename,
          fileType: 'IMAGE_EVIDENCE',
        );
      }

      await fetchTickets();
      return newTicket;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
