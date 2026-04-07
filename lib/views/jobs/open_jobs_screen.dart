// lib/views/jobs/open_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/open_jobs_viewmodel.dart';
import '../../viewmodels/my_jobs_viewmodel.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';

class OpenJobsScreen extends StatefulWidget {
  const OpenJobsScreen({super.key});

  @override
  State<OpenJobsScreen> createState() => _OpenJobsScreenState();
}

class _OpenJobsScreenState extends State<OpenJobsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpenJobsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<OpenJobsViewModel>(builder: (context, vm, _) {
      return RefreshIndicator(
        color:     AppColors.primary,
        onRefresh: vm.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(child: _Header(total: vm.total)),

            // ── Content ──────────────────────────────────────────────────
            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary)),
              )
            else if (vm.error != null)
              SliverFillRemaining(
                child: _ErrorState(vm.error!, vm.refresh),
              )
            else if (vm.jobs.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _OpenJobCard(
                      job: vm.jobs[i],
                      vm:  vm,
                    ),
                    childCount: vm.jobs.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Open job card with assign button ──────────────────────────────────────────

class _OpenJobCard extends StatelessWidget {
  final Job                job;
  final OpenJobsViewModel  vm;
  const _OpenJobCard({required this.job, required this.vm});

  @override
  Widget build(BuildContext context) {
    final assignState = vm.assignStateFor(job.id);
    final isLoading   = assignState == AssignState.loading;

    return JobCard(
      job:   job,
      onTap: () {},     // tap on open jobs just shows the assign button inline
      trailingAction: SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _assign(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:         const EdgeInsets.symmetric(horizontal: 16),
            minimumSize:     Size.zero,
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: isLoading
              ? const SizedBox(
                  width:  16,
                  height: 16,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Assign Me'),
        ),
      ),
    );
  }

  Future<void> _assign(BuildContext context) async {
    final error = vm.assignErrorFor(job.id);
    if (error != null) vm.clearAssignState(job.id);

    final success = await vm.assignJob(job.id);

    if (!context.mounted) return;

    if (success) {
      // Refresh the "My Jobs" list so the newly assigned job appears there
      try {
        context.read<MyJobsViewModel>().refresh();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Job ${job.requestNumber} assigned to you!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.statusCompleted,
          behavior:        SnackBarBehavior.floating,
          shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final msg = vm.assignErrorFor(job.id) ?? 'Could not assign job.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          behavior:        SnackBarBehavior.floating,
          shape:           RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total;
  const _Header({required this.total});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top:    MediaQuery.of(context).padding.top + 16,
      left:   20,
      right:  20,
      bottom: 20,
    ),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.only(
        bottomLeft:  Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Open Jobs',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$total unassigned request${total == 1 ? '' : 's'} available',
          style: TextStyle(
            color:    Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap "Assign Me" to self-assign a job. '
                'It will appear in My Jobs immediately.',
                style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              ),
            ),
          ]),
        ),
      ],
    ),
  );
}

// ── States ────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.task_alt, size: 64, color: AppColors.textLight),
        const SizedBox(height: 16),
        const Text('No open jobs right now',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        const Text(
          'All installation requests have been assigned.\nPull down to refresh.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
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
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon:  const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero,
            padding:     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ]),
    ),
  );
}
