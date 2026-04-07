// lib/viewmodels/job_detail_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

enum StatusUpdateState { idle, loading, success, error }

class JobDetailViewModel extends ChangeNotifier {
  final _service = JobService();

  // ── State ─────────────────────────────────────────────────────────────────

  Job?               _job;
  bool               _isLoading    = false;
  String?            _loadError;
  StatusUpdateState  _updateState  = StatusUpdateState.idle;
  String?            _updateError;
  String             _notes        = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  Job?              get job         => _job;
  bool              get isLoading   => _isLoading;
  String?           get loadError   => _loadError;
  StatusUpdateState get updateState => _updateState;
  String?           get updateError => _updateError;
  bool              get isUpdating  => _updateState == StatusUpdateState.loading;

  JobStatus?  get nextStatus       => _job?.status.nextStatus;
  bool        get canUpdateStatus  => _job?.canUpdateStatus ?? false;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load(int jobId) async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    _job = await _service.getJob(jobId);
    if (_job == null) _loadError = 'Job not found or not assigned to you.';

    _isLoading = false;
    notifyListeners();
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  void setNotes(String v) { _notes = v; }

  // ── Update status ─────────────────────────────────────────────────────────

  Future<bool> updateStatus() async {
    final next = nextStatus;
    if (_job == null || next == null) return false;

    _updateState = StatusUpdateState.loading;
    _updateError = null;
    notifyListeners();

    final result = await _service.updateJobStatus(
      _job!.id, next,
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
    );

    if (result.success) {
      // Optimistically update local status
      _job = Job(
        id:            _job!.id,
        requestNumber: _job!.requestNumber,
        status:        next,
        houseNo:       _job!.houseNo,
        address:       _job!.address,
        city:          _job!.city,
        state:         _job!.state,
        pinCode:       _job!.pinCode,
        notes:         _notes.trim().isNotEmpty ? _notes.trim() : _job!.notes,
        scheduledAt:   _job!.scheduledAt,
        completedAt:   next == JobStatus.completed ? DateTime.now() : _job!.completedAt,
        assignedAt:    _job!.assignedAt,
        assignedBy:    _job!.assignedBy,
        customer:      _job!.customer,
        createdAt:     _job!.createdAt,
      );
      _updateState = StatusUpdateState.success;
      _notes       = '';
      notifyListeners();
      return true;
    } else {
      _updateState = StatusUpdateState.error;
      _updateError = result.error;
      notifyListeners();
      return false;
    }
  }

  void resetUpdateState() {
    _updateState = StatusUpdateState.idle;
    _updateError = null;
    notifyListeners();
  }
}
