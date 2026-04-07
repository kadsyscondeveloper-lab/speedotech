// lib/models/job_model.dart

enum JobStatus {
  pending,
  assigned,
  inProgress,
  completed,
  cancelled;

  static JobStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'assigned':    return JobStatus.assigned;
      case 'in_progress': return JobStatus.inProgress;
      case 'completed':   return JobStatus.completed;
      case 'cancelled':   return JobStatus.cancelled;
      default:            return JobStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case JobStatus.pending:    return 'Pending';
      case JobStatus.assigned:   return 'Assigned';
      case JobStatus.inProgress: return 'In Progress';
      case JobStatus.completed:  return 'Completed';
      case JobStatus.cancelled:  return 'Cancelled';
    }
  }

  String get apiValue {
    switch (this) {
      case JobStatus.inProgress: return 'in_progress';
      case JobStatus.completed:  return 'completed';
      default:                   return name;
    }
  }

  /// The next status a technician can transition to.
  /// Returns null if no further transitions are allowed.
  JobStatus? get nextStatus {
    switch (this) {
      case JobStatus.assigned:   return JobStatus.inProgress;
      case JobStatus.inProgress: return JobStatus.completed;
      default:                   return null;
    }
  }
}

class CustomerInfo {
  final String  name;
  final String? phone;

  const CustomerInfo({required this.name, this.phone});

  factory CustomerInfo.fromJson(Map<String, dynamic> j) => CustomerInfo(
    name:  j['name']  as String? ?? '',
    phone: j['phone'] as String?,
  );
}

class Job {
  final int         id;
  final String      requestNumber;
  final JobStatus   status;
  final String      houseNo;
  final String      address;
  final String      city;
  final String      state;
  final String      pinCode;
  final String?     notes;
  final DateTime?   scheduledAt;
  final DateTime?   completedAt;
  final DateTime?   assignedAt;
  final String?     assignedBy;
  final CustomerInfo? customer;
  final DateTime    createdAt;

  const Job({
    required this.id,
    required this.requestNumber,
    required this.status,
    required this.houseNo,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.notes,
    this.scheduledAt,
    this.completedAt,
    this.assignedAt,
    this.assignedBy,
    this.customer,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id:            int.tryParse(j['id'].toString()) ?? 0,
    requestNumber: j['request_number'] as String? ?? '',
    status:        JobStatus.fromString(j['status'] as String? ?? 'pending'),
    houseNo:       j['house_no']  as String? ?? '',
    address:       j['address']   as String? ?? '',
    city:          j['city']      as String? ?? '',
    state:         j['state']     as String? ?? '',
    pinCode:       j['pin_code']  as String? ?? '',
    notes:         j['notes']     as String?,
    scheduledAt:   _parseDate(j['scheduled_at']),
    completedAt:   _parseDate(j['completed_at']),
    assignedAt:    _parseDate(j['assigned_at']),
    assignedBy:    j['assigned_by'] as String?,
    customer: j['customer'] != null
        ? CustomerInfo.fromJson(j['customer'] as Map<String, dynamic>)
        : null,
    createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
  );

  static DateTime? _parseDate(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  String get fullAddress {
    final parts = <String>[];
    if (houseNo.isNotEmpty) parts.add(houseNo);
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty)    parts.add(city);
    if (state.isNotEmpty)   parts.add(state);
    if (pinCode.isNotEmpty) parts.add(pinCode);
    return parts.join(', ');
  }

  bool get canUpdateStatus => status.nextStatus != null;
}

class TechnicianInfo {
  final int    id;
  final String name;
  final String phone;
  final String employeeId;
  final String? email;
  final int    currentLoad;

  const TechnicianInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.employeeId,
    this.email,
    required this.currentLoad,
  });

  factory TechnicianInfo.fromJson(Map<String, dynamic> j) => TechnicianInfo(
    id:          int.tryParse(j['id'].toString()) ?? 0,
    name:        j['name']         as String? ?? '',
    phone:       j['phone']        as String? ?? '',
    employeeId:  j['employee_id']  as String? ?? '',
    email:       j['email']        as String?,
    currentLoad: (j['current_load'] as num?)?.toInt() ?? 0,
  );
}
