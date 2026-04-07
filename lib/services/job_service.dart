// lib/services/job_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/job_model.dart';

class JobsResult {
  final bool       success;
  final List<Job>  jobs;
  final int        total;
  final String?    error;

  const JobsResult({
    required this.success,
    this.jobs  = const [],
    this.total = 0,
    this.error,
  });
}

class JobActionResult {
  final bool    success;
  final String? error;
  const JobActionResult({required this.success, this.error});
}

class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  final _api = ApiClient();

  // ── GET /technician/jobs/my ───────────────────────────────────────────────

  Future<JobsResult> getMyJobs({
    String? status,
    int page  = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final res   = await _api.get('/technician/jobs/my', params: params);
      final data  = res.data['data'] as Map<String, dynamic>;
      final meta  = res.data['meta'] as Map<String, dynamic>? ?? {};
      final list  = data['jobs'] as List<dynamic>;

      return JobsResult(
        success: true,
        jobs:    list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList(),
        total:   (meta['total'] as num?)?.toInt() ?? list.length,
      );
    } on DioException catch (e) {
      return JobsResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return JobsResult(success: false, error: e.toString());
    }
  }

  // ── GET /technician/jobs/open ─────────────────────────────────────────────

  Future<JobsResult> getOpenJobs({int page = 1, int limit = 20}) async {
    try {
      final res  = await _api.get('/technician/jobs/open',
          params: {'page': page, 'limit': limit});
      final data = res.data['data'] as Map<String, dynamic>;
      final meta = res.data['meta'] as Map<String, dynamic>? ?? {};
      final list = data['jobs'] as List<dynamic>;

      return JobsResult(
        success: true,
        jobs:    list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList(),
        total:   (meta['total'] as num?)?.toInt() ?? list.length,
      );
    } on DioException catch (e) {
      return JobsResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return JobsResult(success: false, error: e.toString());
    }
  }

  // ── GET /technician/jobs/:id ──────────────────────────────────────────────

  Future<Job?> getJob(int id) async {
    try {
      final res = await _api.get('/technician/jobs/$id');
      return Job.fromJson(
          (res.data['data'] as Map<String, dynamic>)['job'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── POST /technician/jobs/:id/assign ─────────────────────────────────────

  Future<JobActionResult> assignJob(int jobId) async {
    try {
      await _api.post('/technician/jobs/$jobId/assign');
      return const JobActionResult(success: true);
    } on DioException catch (e) {
      return JobActionResult(
          success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return JobActionResult(success: false, error: e.toString());
    }
  }

  // ── PATCH /technician/jobs/:id/status ────────────────────────────────────

  Future<JobActionResult> updateJobStatus(int jobId, JobStatus newStatus, {String? notes}) async {
    try {
      await _api.patch('/technician/jobs/$jobId/status', data: {
        'status': newStatus.apiValue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return const JobActionResult(success: true);
    } on DioException catch (e) {
      return JobActionResult(
          success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return JobActionResult(success: false, error: e.toString());
    }
  }
}
