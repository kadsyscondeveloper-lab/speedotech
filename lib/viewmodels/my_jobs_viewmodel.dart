// lib/viewmodels/my_jobs_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

class MyJobsViewModel extends ChangeNotifier {
  final _service = JobService();

  // ── State ─────────────────────────────────────────────────────────────────

  List<Job> _jobs      = [];
  bool      _isLoading = false;
  String?   _error;
  int       _total     = 0;

  // Active filter: null = all, 'assigned', 'in_progress', 'completed'
  String? _activeFilter;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Job>  get jobs          => _jobs;
  bool       get isLoading     => _isLoading;
  String?    get error         => _error;
  int        get total         => _total;
  String?    get activeFilter  => _activeFilter;

  int get activeCount     => _jobs.where((j) =>
    j.status == JobStatus.assigned || j.status == JobStatus.inProgress).length;
  int get completedCount  => _jobs.where((j) => j.status == JobStatus.completed).length;

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(String? filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
    load();
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error     = null;
      notifyListeners();
    }

    final result = await _service.getMyJobs(status: _activeFilter);

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
}
