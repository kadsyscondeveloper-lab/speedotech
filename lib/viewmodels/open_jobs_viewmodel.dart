// lib/viewmodels/open_jobs_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

enum AssignState { idle, loading, success, error }

class OpenJobsViewModel extends ChangeNotifier {
  final _service = JobService();

  // ── State ─────────────────────────────────────────────────────────────────

  List<Job>   _jobs         = [];
  bool        _isLoading    = false;
  String?     _error;
  int         _total        = 0;

  // Per-job assign state: job id → AssignState
  final Map<int, AssignState> _assignStates = {};
  final Map<int, String>      _assignErrors = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Job> get jobs      => _jobs;
  bool      get isLoading => _isLoading;
  String?   get error     => _error;
  int       get total     => _total;

  AssignState assignStateFor(int jobId) =>
      _assignStates[jobId] ?? AssignState.idle;

  String? assignErrorFor(int jobId) => _assignErrors[jobId];

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error     = null;
      notifyListeners();
    }

    final result = await _service.getOpenJobs();

    if (result.success) {
      _jobs  = result.jobs;
      _total = result.total;
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(silent: false);

  // ── Self-assign ────────────────────────────────────────────────────────────

  Future<bool> assignJob(int jobId) async {
    _assignStates[jobId] = AssignState.loading;
    _assignErrors.remove(jobId);
    notifyListeners();

    final result = await _service.assignJob(jobId);

    if (result.success) {
      _assignStates[jobId] = AssignState.success;
      // Remove from open list immediately — it's now in my jobs
      _jobs = _jobs.where((j) => j.id != jobId).toList();
      notifyListeners();
      return true;
    } else {
      _assignStates[jobId] = AssignState.error;
      _assignErrors[jobId] = result.error ?? 'Could not assign job. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearAssignState(int jobId) {
    _assignStates.remove(jobId);
    _assignErrors.remove(jobId);
    notifyListeners();
  }
}
