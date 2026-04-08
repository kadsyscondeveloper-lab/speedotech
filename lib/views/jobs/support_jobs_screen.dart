// lib/views/support_jobs_screen.dart  [TECHNICIAN APP]
//
// Two-tab screen:
//   "Open Jobs"  — job board: all grabbable tickets
//   "My Jobs"    — technician's own assigned jobs
//
// Tapping a job navigates to ActiveJobScreen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/support_jobs_viewmodel.dart';
import '../../services/support_job_service.dart';
import 'active_job_screen.dart';

class SupportJobsScreen extends StatefulWidget {
  const SupportJobsScreen({super.key});

  @override
  State<SupportJobsScreen> createState() => _SupportJobsScreenState();
}

class _SupportJobsScreenState extends State<SupportJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController         _tabs;
  late final SupportJobsViewModel  _vm;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _vm   = SupportJobsViewModel();
    _vm.loadOpenJobs();
    _vm.loadMyJobs();

    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) => NestedScrollView(
            headerSliverBuilder: (_, __) => [_buildAppBar()],
            body: TabBarView(
              controller: _tabs,
              children: [
                _buildOpenJobsList(),
                _buildMyJobsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() => SliverAppBar(
    pinned: true,
    expandedHeight: 120,
    backgroundColor: AppColors.primary,
    automaticallyImplyLeading: false,
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.pin,
      titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 56),
      title: const Text('Support Jobs',
          style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 18)),
      background: Container(color: AppColors.primary),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: () {
          _vm.loadOpenJobs();
          _vm.loadMyJobs();
        },
      ),
    ],
    bottom: TabBar(
      controller: _tabs,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      tabs: [
        Tab(text: 'Open Jobs (${_vm.openJobs.length})'),
        Tab(text: 'My Jobs (${_vm.myJobs.length})'),
      ],
    ),
  );

  // ── Open jobs list ────────────────────────────────────────────────────────

  Widget _buildOpenJobsList() {
    if (_vm.loadingOpen) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.openError != null) {
      return _buildErrorState(_vm.openError!, () => _vm.loadOpenJobs());
    }
    if (_vm.openJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No open jobs',
        sub: 'All tickets have been assigned.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _vm.loadOpenJobs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _vm.openJobs.length,
        itemBuilder: (_, i) => _JobCard(
          job: _vm.openJobs[i],
          action: _GrabButton(
            grabbing: _vm.grabbing,
            onGrab: () => _grabJob(_vm.openJobs[i]),
          ),
        ),
      ),
    );
  }

  // ── My jobs list ──────────────────────────────────────────────────────────

  Widget _buildMyJobsList() {
    if (_vm.loadingMy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.myError != null) {
      return _buildErrorState(_vm.myError!, () => _vm.loadMyJobs());
    }
    if (_vm.myJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.engineering_outlined,
        title: 'No active jobs',
        sub: 'Grab an open job from the board.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _vm.loadMyJobs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _vm.myJobs.length,
        itemBuilder: (_, i) => _JobCard(
          job: _vm.myJobs[i],
          onTap: () => _openActiveJob(_vm.myJobs[i]),
          action: _OpenButton(onTap: () => _openActiveJob(_vm.myJobs[i])),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _grabJob(SupportJob job) async {
    final ok = await _vm.grabJob(job);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job grabbed! Head to My Jobs.'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _tabs.animateTo(1);
    } else if (_vm.grabError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_vm.grabError!),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _openActiveJob(SupportJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveJobScreen(job: job, viewModel: _vm),
      ),
    ).then((_) {
      _vm.loadMyJobs();
      _vm.loadOpenJobs();
    });
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildErrorState(String msg, VoidCallback retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: retry,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey)),
        ]),
      );
}

// ── Job card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final SupportJob  job;
  final Widget?     action;
  final VoidCallback? onTap;

  const _JobCard({required this.job, this.action, this.onTap});

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month-1]}, '
        '${dt.hour.toString().padLeft(2,'0')}:'
        '${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                // Priority dot
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: job.priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(job.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark)),
                ),
                const SizedBox(width: 8),
                _PriorityChip(priority: job.priority),
              ]),
            ),
            // Category + ticket id
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 4, 16, 0),
              child: Row(children: [
                Text('#${job.ticketId}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
                const SizedBox(width: 8),
                Container(width: 3, height: 3,
                    decoration: const BoxDecoration(
                        color: AppColors.textLight, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(job.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey)),
              ]),
            ),
            // Customer info
            if (job.customer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(job.customer!.name,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.phone_rounded,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(job.customer!.phone,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ]),
              ),
            // Footer: timestamp + action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(_fmt(job.jobOpenedAt ?? job.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
                const Spacer(),
                if (action != null) action!,
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (priority) {
      case 'high':   color = const Color(0xFFE53935); break;
      case 'medium': color = const Color(0xFFFB8C00); break;
      default:       color = const Color(0xFF43A047);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _GrabButton extends StatelessWidget {
  final bool         grabbing;
  final VoidCallback onGrab;
  const _GrabButton({required this.grabbing, required this.onGrab});

  @override
  Widget build(BuildContext context) => grabbing
      ? const SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2))
      : GestureDetector(
          onTap: onGrab,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Grab Job',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        );
}

class _OpenButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OpenButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('View',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
      ]),
    ),
  );
}
