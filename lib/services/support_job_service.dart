// lib/services/support_job_service.dart  [TECHNICIAN APP]

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class JobAddress {
  final String? houseNo;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;

  const JobAddress({
    this.houseNo,
    this.address,
    this.city,
    this.state,
    this.pinCode,
  });

  factory JobAddress.fromJson(Map<String, dynamic> j) => JobAddress(
    houseNo: j['house_no'] as String?,
    address: j['address']  as String?,
    city:    j['city']     as String?,
    state:   j['state']    as String?,
    pinCode: j['pin_code'] as String?,
  );

  /// Human-readable one-liner for display
  String get displayLine {
    final parts = [
      if (houseNo != null && houseNo!.isNotEmpty) houseNo,
      if (address  != null && address!.isNotEmpty)  address,
      if (city     != null && city!.isNotEmpty)     city,
    ];
    return parts.join(', ');
  }

  /// Full string suitable for geocoding query
  String get geocodeQuery {
    final parts = [
      if (houseNo != null && houseNo!.isNotEmpty) houseNo,
      if (address  != null && address!.isNotEmpty)  address,
      if (city     != null && city!.isNotEmpty)     city,
      if (state    != null && state!.isNotEmpty)    state,
      if (pinCode  != null && pinCode!.isNotEmpty)  pinCode,
      'India',
    ];
    return parts.join(', ');
  }

  bool get hasData =>
      (houseNo?.isNotEmpty == true) ||
          (address?.isNotEmpty  == true) ||
          (city?.isNotEmpty     == true);
}

class SupportJob {
  final int      ticketId;
  final String   subject;
  final String   category;
  final String   priority;
  final String   status;
  final String   techJobStatus;
  final DateTime? jobOpenedAt;
  final DateTime? jobAssignedAt;
  final DateTime? jobCompletedAt;
  final DateTime  createdAt;
  final JobCustomer? customer;
  final JobAddress?  address;

  const SupportJob({
    required this.ticketId,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.techJobStatus,
    this.jobOpenedAt,
    this.jobAssignedAt,
    this.jobCompletedAt,
    required this.createdAt,
    this.customer,
    this.address,
  });

  bool get isAssigned  => techJobStatus == 'assigned';
  bool get isCompleted => techJobStatus == 'completed';
  bool get isOpen      => techJobStatus == 'open';

  Color get priorityColor {
    switch (priority) {
      case 'high':   return const Color(0xFFE53935);
      case 'medium': return const Color(0xFFFB8C00);
      default:       return const Color(0xFF43A047);
    }
  }

  factory SupportJob.fromJson(Map<String, dynamic> j) => SupportJob(
    ticketId:      int.tryParse((j['id'] ?? j['ticket_id']).toString()) ?? 0,
    subject:       j['subject']         as String? ?? '',
    category:      j['category']        as String? ?? '',
    priority:      j['priority']        as String? ?? 'medium',
    status:        j['status']          as String? ?? '',
    techJobStatus: j['tech_job_status'] as String? ?? '',
    jobOpenedAt:   j['job_opened_at'] != null
        ? DateTime.tryParse(j['job_opened_at'].toString())?.toLocal()
        : null,
    jobAssignedAt: j['job_assigned_at'] != null
        ? DateTime.tryParse(j['job_assigned_at'].toString())?.toLocal()
        : null,
    jobCompletedAt: j['job_completed_at'] != null
        ? DateTime.tryParse(j['job_completed_at'].toString())?.toLocal()
        : null,
    createdAt: DateTime.tryParse(j['created_at'].toString())?.toLocal() ??
        DateTime.now(),
    customer: j['customer'] != null
        ? JobCustomer.fromJson(j['customer'] as Map<String, dynamic>)
        : null,
    address: j['address'] != null
        ? JobAddress.fromJson(j['address'] as Map<String, dynamic>)
        : null,
  );
}

class JobCustomer {
  final String name;
  final String phone;
  const JobCustomer({required this.name, required this.phone});
  factory JobCustomer.fromJson(Map<String, dynamic> j) => JobCustomer(
    name:  j['name']  as String? ?? '',
    phone: j['phone'] as String? ?? '',
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class SupportJobService {
  static final SupportJobService _i = SupportJobService._();
  factory SupportJobService() => _i;
  SupportJobService._();

  final _api = ApiClient();

  Future<List<SupportJob>> getOpenJobs({int page = 1}) async {
    final res = await _api.get('/technician/support-jobs/open',
        params: {'page': page, 'limit': 20});
    final list = res.data['data']['jobs'] as List<dynamic>;
    return list.map((j) => SupportJob.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<SupportJob>> getMyJobs({String status = 'assigned'}) async {
    final res = await _api.get('/technician/support-jobs/mine',
        params: {'status': status});
    final list = res.data['data']['jobs'] as List<dynamic>;
    return list.map((j) => SupportJob.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> grabJob(int ticketId) async {
    try {
      await _api.post('/technician/support-jobs/$ticketId/grab');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resolveJob(int ticketId, {String? note}) async {
    try {
      await _api.patch('/technician/support-jobs/$ticketId/resolve',
          data: {if (note != null) 'resolution_note': note});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}