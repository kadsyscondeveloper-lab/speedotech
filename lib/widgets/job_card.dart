// lib/widgets/job_card.dart
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class JobCard extends StatelessWidget {
  final Job          job;
  final VoidCallback onTap;
  final Widget?      trailingAction;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:     const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar: status + request number ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        _statusColor(job.status).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  _StatusDot(job.status),
                  const SizedBox(width: 8),
                  Text(
                    job.status.label,
                    style: TextStyle(
                      color:      _statusColor(job.status),
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    job.requestNumber,
                    style: const TextStyle(
                      fontSize:   12,
                      color:      AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer name
                  if (job.customer != null) ...[
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        job.customer!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                          color:      AppColors.textDark,
                        ),
                      ),
                      if (job.customer!.phone != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          job.customer!.phone!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textGrey),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 8),
                  ],

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.fullAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            color:    AppColors.textGrey,
                            height:   1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Notes
                  if (job.notes != null && job.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined,
                            size: 16, color: AppColors.textGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            job.notes!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textGrey),
                            maxLines:  2,
                            overflow:  TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Footer: date + trailing action
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(
                            job.assignedAt ?? job.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight),
                      ),
                      const Spacer(),
                      if (trailingAction != null) trailingAction!
                      else const Icon(Icons.chevron_right,
                          color: AppColors.textLight, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.pending:    return AppColors.statusPending;
      case JobStatus.assigned:   return AppColors.statusAssigned;
      case JobStatus.inProgress: return AppColors.statusInProgress;
      case JobStatus.completed:  return AppColors.statusCompleted;
      case JobStatus.cancelled:  return AppColors.statusCancelled;
    }
  }

  static String _formatDate(DateTime d) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());
}

class _StatusDot extends StatelessWidget {
  final JobStatus status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final color = JobCard._statusColor(status);
    return Container(
      width:  8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
