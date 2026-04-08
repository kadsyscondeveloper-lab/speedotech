// lib/viewmodels/support_jobs_viewmodel.dart  [TECHNICIAN APP]

import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../services/support_job_service.dart';
import '../services/technician_tracking_service.dart';

class SupportJobsViewModel extends ChangeNotifier {
  final _jobService      = SupportJobService();
  final _trackingService = TechnicianTrackingService();

  // ── Open jobs (job board) ──────────────────────────────────────────────────
  List<SupportJob> _openJobs     = [];
  bool             _loadingOpen  = false;
  String?          _openError;

  List<SupportJob> get openJobs    => _openJobs;
  bool             get loadingOpen => _loadingOpen;
  String?          get openError   => _openError;

  // ── My assigned jobs ───────────────────────────────────────────────────────
  List<SupportJob> _myJobs     = [];
  bool             _loadingMy  = false;
  String?          _myError;

  List<SupportJob> get myJobs    => _myJobs;
  bool             get loadingMy => _loadingMy;
  String?          get myError   => _myError;

  // ── Active job (currently working on) ─────────────────────────────────────
  SupportJob? _activeJob;
  SupportJob? get activeJob => _activeJob;

  // ── Grab state ─────────────────────────────────────────────────────────────
  bool    _grabbing     = false;
  String? _grabError;

  bool    get grabbing  => _grabbing;
  String? get grabError => _grabError;

  // ── Resolve state ──────────────────────────────────────────────────────────
  bool    _resolving    = false;
  String? _resolveError;
  bool    _resolveSuccess = false;

  bool    get resolving      => _resolving;
  String? get resolveError   => _resolveError;
  bool    get resolveSuccess => _resolveSuccess;

  // ── Tracking state ─────────────────────────────────────────────────────────
  bool    _isTracking      = false;
  String? _trackingError;
  bool get isTracking      => _isTracking;
  String? get trackingError => _trackingError;

  // ── Load open jobs ─────────────────────────────────────────────────────────

  Future<void> loadOpenJobs() async {
    _loadingOpen = true;
    _openError   = null;
    notifyListeners();
    try {
      _openJobs = await _jobService.getOpenJobs();
    } catch (e) {
      _openError = _msg(e);
    } finally {
      _loadingOpen = false;
      notifyListeners();
    }
  }

  // ── Load my jobs ───────────────────────────────────────────────────────────

  Future<void> loadMyJobs() async {
    _loadingMy = true;
    _myError   = null;
    notifyListeners();
    try {
      _myJobs = await _jobService.getMyJobs(status: 'assigned');
      // If technician already has an active job, restore it
      if (_activeJob == null && _myJobs.isNotEmpty) {
        _activeJob = _myJobs.first;
      }
    } catch (e) {
      _myError = _msg(e);
    } finally {
      _loadingMy = false;
      notifyListeners();
    }
  }

  // ── Grab a job ─────────────────────────────────────────────────────────────

  Future<bool> grabJob(SupportJob job) async {
    _grabbing  = true;
    _grabError = null;
    notifyListeners();
    try {
      await _jobService.grabJob(job.ticketId);
      // Move it to my jobs
      _openJobs.removeWhere((j) => j.ticketId == job.ticketId);
      _activeJob = SupportJob.fromJson({
        ...{
          'ticket_id':       job.ticketId,
          'subject':         job.subject,
          'category':        job.category,
          'priority':        job.priority,
          'status':          job.status,
          'tech_job_status': 'assigned',
          'created_at':      job.createdAt.toIso8601String(),
          if (job.customer != null) 'customer': {
            'name':  job.customer!.name,
            'phone': job.customer!.phone,
          },
        }
      });
      _myJobs = [_activeJob!, ..._myJobs];
      _grabbing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _grabError = _msg(e);
      _grabbing  = false;
      notifyListeners();
      return false;
    }
  }

  // ── Resolve a job ──────────────────────────────────────────────────────────

  Future<bool> resolveJob(int ticketId, {String? note}) async {
    _resolving      = true;
    _resolveError   = null;
    _resolveSuccess = false;
    notifyListeners();
    try {
      await _jobService.resolveJob(ticketId, note: note);
      stopTracking();
      _myJobs.removeWhere((j) => j.ticketId == ticketId);
      if (_activeJob?.ticketId == ticketId) _activeJob = null;
      _resolving      = false;
      _resolveSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _resolveError = _msg(e);
      _resolving    = false;
      notifyListeners();
      return false;
    }
  }

  void resetResolveState() {
    _resolveSuccess = false;
    _resolveError   = null;
    notifyListeners();
  }

  // ── Live tracking ──────────────────────────────────────────────────────────

  Future<void> startTracking(int ticketId) async {
    _trackingError = null;
    notifyListeners();

    final ok = await _trackingService.startTracking(
      ticketId: ticketId,
      onError: (msg) {
        _trackingError = msg;
        _isTracking    = false;
        notifyListeners();
      },
      onConnected: () {
        _isTracking = true;
        notifyListeners();
      },
    );

    if (!ok) {
      _trackingError = 'Could not start location tracking.';
      notifyListeners();
    }
  }

  void stopTracking() {
    _trackingService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _msg(Object e) =>
      e is ApiException ? e.message : e.toString().replaceAll('Exception: ', '');

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }
}
