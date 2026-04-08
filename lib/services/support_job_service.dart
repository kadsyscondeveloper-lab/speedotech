// lib/services/support_job_service.dart  [TECHNICIAN APP]
//
// REST calls for the technician's support-job workflow.
// Base URL and ApiClient should match your technician app setup.

import 'dart:ui';

import 'package:dio/dio.dart';
import '../core/api_client.dart';  // your technician app's ApiClient

// ── Models ────────────────────────────────────────────────────────────────────

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
  final _Customer? customer;

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
    ticketId:      int.tryParse(j['ticket_id'].toString()) ?? 0,
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
        ? _Customer.fromJson(j['customer'] as Map<String, dynamic>)
        : null,
  );
}

class _Customer {
  final String name;
  final String phone;
  const _Customer({required this.name, required this.phone});
  factory _Customer.fromJson(Map<String, dynamic> j) => _Customer(
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

  // GET /technician/support-jobs/open
  Future<List<SupportJob>> getOpenJobs({int page = 1}) async {
    final res = await _api.get('/technician/support-jobs/open',
        params: {'page': page, 'limit': 20});
    final list = res.data['data']['jobs'] as List<dynamic>;
    return list.map((j) => SupportJob.fromJson(j as Map<String, dynamic>)).toList();
  }

  // GET /technician/support-jobs/mine?status=assigned
  Future<List<SupportJob>> getMyJobs({String status = 'assigned'}) async {
    final res = await _api.get('/technician/support-jobs/mine',
        params: {'status': status});
    final list = res.data['data']['jobs'] as List<dynamic>;
    return list.map((j) => SupportJob.fromJson(j as Map<String, dynamic>)).toList();
  }

  // POST /technician/support-jobs/:ticketId/grab
  Future<void> grabJob(int ticketId) async {
    try {
      await _api.post('/technician/support-jobs/$ticketId/grab');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // PATCH /technician/support-jobs/:ticketId/resolve
  Future<void> resolveJob(int ticketId, {String? note}) async {
    try {
      await _api.patch('/technician/support-jobs/$ticketId/resolve',
          data: {if (note != null) 'resolution_note': note});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
