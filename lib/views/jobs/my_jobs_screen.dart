// lib/views/jobs/my_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/my_jobs_viewmodel.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _filters = [
    {'label': 'All',         'value': null},
    {'label': 'Assigned',    'value': 'assigned'},
    {'label': 'In Progress', 'value': 'in_progress'},
    {'label': 'Completed',   'value': 'completed'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyJobsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MyJobsViewModel>(builder: (context, vm, _) {
      return RefreshIndicator(
        color:       AppColors.primary,
        onRefresh:   vm.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(vm: vm),
            ),

            // ── Filter chips ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterBar(
                filters:       _filters,
                activeFilter:  vm.activeFilter,
                onFilterTap:   vm.setFilter,
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary)),
              )
            else if (vm.error != null)
              SliverFillRemaining(child: _ErrorState(vm.error!, vm.refresh))
            else if (vm.jobs.isEmpty)
              SliverFillRemaining(child: _EmptyState(vm.activeFilter))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final job = vm.jobs[i];
                      return JobCard(
                        job:   job,
                        onTap: () => _openDetail(context, job, vm),
                      );
                    },
                    childCount: vm.jobs.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _openDetail(BuildContext context, Job job, MyJobsViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          jobId:         job.id,
          onStatusChanged: vm.refresh,
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final MyJobsViewModel vm;
  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'My Jobs',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _StatChip(
              icon:  Icons.work_outline,
              label: 'Active',
              count: vm.activeCount,
              color: AppColors.statusAssigned,
            ),
            const SizedBox(width: 10),
            _StatChip(
              icon:  Icons.check_circle_outline,
              label: 'Completed',
              count: vm.completedCount,
              color: AppColors.statusCompleted,
            ),
            const SizedBox(width: 10),
            _StatChip(
              icon:  Icons.list_alt_outlined,
              label: 'Total',
              count: vm.total,
              color: Colors.white70,
            ),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      count;
  final Color    color;
  const _StatChip({required this.icon, required this.label,
      required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color:        Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(
        '$count $label',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ]),
  );
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> filters;
  final String?                    activeFilter;
  final Function(String?)          onFilterTap;
  const _FilterBar({required this.filters, required this.activeFilter,
      required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount:        filters.length,
        itemBuilder:      (ctx, i) {
          final f        = filters[i];
          final isActive = f['value'] == activeFilter;
          return GestureDetector(
            onTap: () => onFilterTap(f['value'] as String?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:  const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:        isActive ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.borderColor,
                ),
                boxShadow: isActive
                    ? [BoxShadow(
                        color:      AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset:     const Offset(0, 2),
                      )]
                    : [],
              ),
              child: Center(
                child: Text(
                  f['label'] as String,
                  style: TextStyle(
                    color:      isActive ? Colors.white : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? filter;
  const _EmptyState(this.filter);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.work_outline, size: 64, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(
          filter == null
              ? 'No jobs assigned yet'
              : 'No ${filter!.replaceAll('_', ' ')} jobs',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pull down to refresh or browse\nopen jobs to self-assign.',
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
