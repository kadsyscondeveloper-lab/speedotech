// lib/views/jobs/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/job_detail_viewmodel.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';

class JobDetailScreen extends StatelessWidget {
  final int          jobId;
  final VoidCallback onStatusChanged;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobDetailViewModel()..load(jobId),
      child: _JobDetailView(onStatusChanged: onStatusChanged),
    );
  }
}

class _JobDetailView extends StatelessWidget {
  final VoidCallback onStatusChanged;
  const _JobDetailView({required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<JobDetailViewModel>(builder: (context, vm, _) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            vm.job?.requestNumber ?? 'Job Detail',
            style: const TextStyle(color: Colors.white),
          ),
          leading: const BackButton(color: Colors.white),
          actions: [
            if (vm.job != null)
              IconButton(
                icon:    const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => vm.load(vm.job!.id),
              ),
          ],
        ),
        body: vm.isLoading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primary))
            : vm.loadError != null
                ? _ErrorState(vm.loadError!, () => vm.load(jobId))
                : vm.job == null
                    ? const _ErrorState('Job not found.', null)
                    : _JobContent(vm: vm, onStatusChanged: onStatusChanged),
      );
    });
  }

  int get jobId => 0; // unused — vm already has the id
}

// ── Main content ──────────────────────────────────────────────────────────────

class _JobContent extends StatefulWidget {
  final JobDetailViewModel vm;
  final VoidCallback       onStatusChanged;
  const _JobContent({required this.vm, required this.onStatusChanged});

  @override
  State<_JobContent> createState() => _JobContentState();
}

class _JobContentState extends State<_JobContent> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.pending:    return AppColors.statusPending;
      case JobStatus.assigned:   return AppColors.statusAssigned;
      case JobStatus.inProgress: return AppColors.statusInProgress;
      case JobStatus.completed:  return AppColors.statusCompleted;
      case JobStatus.cancelled:  return AppColors.statusCancelled;
    }
  }

  IconData _statusIcon(JobStatus s) {
    switch (s) {
      case JobStatus.pending:    return Icons.schedule;
      case JobStatus.assigned:   return Icons.assignment_ind_outlined;
      case JobStatus.inProgress: return Icons.engineering;
      case JobStatus.completed:  return Icons.check_circle_outline;
      case JobStatus.cancelled:  return Icons.cancel_outlined;
    }
  }

  String _nextActionLabel(JobStatus next) {
    switch (next) {
      case JobStatus.inProgress: return 'Mark In Progress';
      case JobStatus.completed:  return 'Mark Completed';
      default:                   return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm  = widget.vm;
    final job = vm.job!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ────────────────────────────────────────────────
          _StatusBanner(
            status:      job.status,
            color:       _statusColor(job.status),
            icon:        _statusIcon(job.status),
          ),

          const SizedBox(height: 16),

          // ── Progress stepper ─────────────────────────────────────────────
          _ProgressStepper(currentStatus: job.status),

          const SizedBox(height: 16),

          // ── Customer card ────────────────────────────────────────────────
          if (job.customer != null)
            _SectionCard(
              title: 'Customer',
              icon:  Icons.person_outline,
              child: _CustomerInfo(job.customer!),
            ),

          const SizedBox(height: 12),

          // ── Address card ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Installation Address',
            icon:  Icons.location_on_outlined,
            child: _AddressInfo(job),
          ),

          const SizedBox(height: 12),

          // ── Timeline card ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Timeline',
            icon:  Icons.history_outlined,
            child: _Timeline(job),
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Notes',
              icon:  Icons.notes_outlined,
              child: Text(job.notes!,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 14, height: 1.5)),
            ),
          ],

          // ── Update status section ──────────────────────────────────────────
          if (vm.canUpdateStatus && vm.nextStatus != null) ...[
            const SizedBox(height: 24),
            _UpdateStatusSection(
              vm:             vm,
              notesCtrl:      _notesCtrl,
              nextStatus:     vm.nextStatus!,
              actionLabel:    _nextActionLabel(vm.nextStatus!),
              onSuccess:      widget.onStatusChanged,
            ),
          ],

          // ── Already done ─────────────────────────────────────────────────
          if (job.status == JobStatus.completed)
            _CompletedBanner(job.completedAt),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final JobStatus status;
  final Color     color;
  final IconData  icon;
  const _StatusBanner({required this.status, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Container(
        width:  48,
        height: 48,
        decoration: BoxDecoration(
          color:  color.withOpacity(0.15),
          shape:  BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Current Status',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text(status.label,
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w800,
                color:      color)),
      ]),
    ]),
  );
}

// ── Progress stepper ──────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final JobStatus currentStatus;
  const _ProgressStepper({required this.currentStatus});

  static const _steps = [
    JobStatus.pending,
    JobStatus.assigned,
    JobStatus.inProgress,
    JobStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == JobStatus.cancelled) return const SizedBox.shrink();

    final currentIndex = _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isDone    = currentIndex > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? AppColors.primary : AppColors.borderColor,
              ),
            );
          }
          // Step dot
          final stepIndex  = i ~/ 2;
          final step       = _steps[stepIndex];
          final isDone     = currentIndex > stepIndex;
          final isCurrent  = currentIndex == stepIndex;

          return _StepDot(step: step, isDone: isDone, isCurrent: isCurrent);
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final JobStatus step;
  final bool      isDone;
  final bool      isCurrent;
  const _StepDot({required this.step, required this.isDone, required this.isCurrent});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width:  isCurrent ? 32 : 24,
        height: isCurrent ? 32 : 24,
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.primary
              : isCurrent
                  ? AppColors.primary
                  : AppColors.borderColor,
          shape: BoxShape.circle,
          boxShadow: isCurrent
              ? [BoxShadow(
                  color:      AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                )]
              : [],
        ),
        child: Icon(
          isDone ? Icons.check : _stepIcon(step),
          color: isDone || isCurrent ? Colors.white : AppColors.textLight,
          size:  isCurrent ? 18 : 14,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        step.label,
        style: TextStyle(
          fontSize:   9,
          color:      isDone || isCurrent ? AppColors.primary : AppColors.textLight,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  IconData _stepIcon(JobStatus s) {
    switch (s) {
      case JobStatus.pending:    return Icons.schedule;
      case JobStatus.assigned:   return Icons.assignment_ind_outlined;
      case JobStatus.inProgress: return Icons.engineering;
      case JobStatus.completed:  return Icons.check_circle_outline;
      default:                   return Icons.circle;
    }
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String  title;
  final IconData icon;
  final Widget  child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textGrey)),
          ]),
        ),
        const Divider(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: child,
        ),
      ],
    ),
  );
}

// ── Customer info ─────────────────────────────────────────────────────────────

class _CustomerInfo extends StatelessWidget {
  final CustomerInfo customer;
  const _CustomerInfo(this.customer);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InfoRow(Icons.person_outline, customer.name,
          bold: true, fontSize: 15),
      if (customer.phone != null) ...[
        const SizedBox(height: 8),
        _InfoRow(Icons.call_outlined, customer.phone!,
            onTap: () => _call(context, customer.phone!)),
      ],
    ],
  );

  void _call(BuildContext context, String phone) {
    // In production wire up url_launcher: launch('tel:$phone')
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call $phone'),
        action:  SnackBarAction(label: 'OK', onPressed: () {}),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Address info ──────────────────────────────────────────────────────────────

class _AddressInfo extends StatelessWidget {
  final Job job;
  const _AddressInfo(this.job);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (job.houseNo.isNotEmpty)
        _InfoRow(Icons.home_outlined, 'House / Flat: ${job.houseNo}'),
      if (job.address.isNotEmpty) ...[
        const SizedBox(height: 6),
        _InfoRow(Icons.location_on_outlined, job.address),
      ],
      const SizedBox(height: 6),
      _InfoRow(Icons.map_outlined, '${job.city}, ${job.state} - ${job.pinCode}'),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _copyAddress(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:        AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.copy_outlined, size: 15, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Copy Address',
                style: TextStyle(
                    color: AppColors.primary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ],
  );

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: job.fullAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  const Text('Address copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final Job job;
  const _Timeline(this.job);

  static String _fmt(DateTime? d) => d != null
      ? DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal())
      : '—';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _TimeRow('Created',      _fmt(job.createdAt)),
      if (job.assignedAt != null)
        _TimeRow('Assigned',   _fmt(job.assignedAt)),
      if (job.scheduledAt != null)
        _TimeRow('Scheduled',  _fmt(job.scheduledAt)),
      if (job.completedAt != null)
        _TimeRow('Completed',  _fmt(job.completedAt),
            color: AppColors.statusCompleted),
    ],
  );
}

class _TimeRow extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  color;
  const _TimeRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textGrey)),
        Text(value,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      color ?? AppColors.textDark,
            )),
      ],
    ),
  );
}

// ── Info row helper ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData   icon;
  final String     text;
  final bool       bold;
  final double     fontSize;
  final VoidCallback? onTap;

  const _InfoRow(this.icon, this.text, {
    this.bold     = false,
    this.fontSize = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.textGrey),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize:   fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color:      onTap != null ? AppColors.primary : AppColors.textDark,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
      ),
    ]),
  );
}

// ── Update status section ─────────────────────────────────────────────────────

class _UpdateStatusSection extends StatelessWidget {
  final JobDetailViewModel vm;
  final TextEditingController notesCtrl;
  final JobStatus  nextStatus;
  final String     actionLabel;
  final VoidCallback onSuccess;
  const _UpdateStatusSection({
    required this.vm,
    required this.notesCtrl,
    required this.nextStatus,
    required this.actionLabel,
    required this.onSuccess,
  });

  Color get _buttonColor {
    return nextStatus == JobStatus.completed
        ? AppColors.statusCompleted
        : AppColors.statusInProgress;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.update_outlined, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Update Status',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textGrey)),
        ]),
        const Divider(height: 16),

        // Notes field
        TextField(
          controller:  notesCtrl,
          onChanged:   vm.setNotes,
          maxLines:    3,
          decoration:  const InputDecoration(
            hintText:       'Add notes (optional)...',
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 12),

        // Error
        if (vm.updateError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(vm.updateError!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 13))),
              ]),
            ),
          ),

        // Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: vm.isUpdating ? null : () => _update(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon:  vm.isUpdating
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, color: Colors.white),
            label: Text(actionLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
      ],
    ),
  );

  Future<void> _update(BuildContext context) async {
    final success = await vm.updateStatus();
    if (!context.mounted) return;

    if (success) {
      onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          nextStatus == JobStatus.completed
              ? '🎉 Job marked as completed!'
              : '🔧 Job is now in progress!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: nextStatus == JobStatus.completed
            ? AppColors.statusCompleted
            : AppColors.statusInProgress,
        behavior: SnackBarBehavior.floating,
        shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

// ── Completed banner ──────────────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  final DateTime? completedAt;
  const _CompletedBanner(this.completedAt);

  @override
  Widget build(BuildContext context) => Container(
    margin:  const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.statusCompleted.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(
          color: AppColors.statusCompleted.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.check_circle, color: AppColors.statusCompleted, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Installation Complete',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.statusCompleted,
                fontSize: 15)),
        if (completedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(completedAt!.toLocal()),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ])),
    ]),
  );
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback? onRetry;
  const _ErrorState(this.message, this.onRetry);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon:  const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ]),
    ),
  );
}
