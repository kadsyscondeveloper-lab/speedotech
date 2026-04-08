// lib/views/active_job_screen.dart  [TECHNICIAN APP]
//
// Full-screen view for a technician's active (assigned) support job.
// Features:
//   • Customer details + call button
//   • Live location sharing toggle (Socket.io + Geolocator)
//   • Resolve job with optional note
//   • Clean status indicators

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../viewmodels/support_jobs_viewmodel.dart';
import '../services/support_job_service.dart';

class ActiveJobScreen extends StatefulWidget {
  final SupportJob          job;
  final SupportJobsViewModel viewModel;

  const ActiveJobScreen({
    super.key,
    required this.job,
    required this.viewModel,
  });

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _noteCtrl = TextEditingController();
  bool  _showNote = false;

  SupportJobsViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVmChange);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onVmChange() {
    if (_vm.resolveSuccess && mounted) {
      _vm.resetResolveState();
      Navigator.pop(context);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2,'0');
    final min = dt.minute.toString().padLeft(2,'0');
    return '${dt.day} ${m[dt.month-1]} ${dt.year}, $h:$min';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
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
          builder: (context, _) => CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildJobHeader(),
                    const SizedBox(height: 12),
                    _buildCustomerCard(),
                    const SizedBox(height: 12),
                    _buildTrackingCard(),
                    if (_vm.trackingError != null) ...[
                      const SizedBox(height: 8),
                      _ErrorBanner(message: _vm.trackingError!),
                    ],
                    const SizedBox(height: 12),
                    _buildDescriptionCard(),
                    const SizedBox(height: 20),
                    _buildResolveSection(),
                    if (_vm.resolveError != null) ...[
                      const SizedBox(height: 8),
                      _ErrorBanner(message: _vm.resolveError!),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() => SliverAppBar(
    pinned: true,
    backgroundColor: AppColors.primary,
    automaticallyImplyLeading: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Job',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16)),
        Text('#${widget.job.ticketId}',
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    ),
  );

  // ── Job header ────────────────────────────────────────────────────────────

  Widget _buildJobHeader() => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(widget.job.subject,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textDark)),
          ),
          const SizedBox(width: 8),
          _PriorityBadge(priority: widget.job.priority),
        ]),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.category_rounded,     label: widget.job.category),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.access_time_rounded,
            label: 'Assigned ${_fmt(widget.job.jobAssignedAt)}'),
      ],
    ),
  );

  // ── Customer card ─────────────────────────────────────────────────────────

  Widget _buildCustomerCard() {
    final customer = widget.job.customer;
    return _Card(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer?.name ?? 'Customer',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark)),
              if (customer?.phone != null && customer!.phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(customer.phone,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ],
            ],
          ),
        ),
        if (customer?.phone != null && customer!.phone.isNotEmpty)
          GestureDetector(
            onTap: () => _call(customer.phone),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded,
                  color: Color(0xFF4CAF50), size: 20),
            ),
          ),
      ]),
    );
  }

  // ── Tracking card ─────────────────────────────────────────────────────────

  Widget _buildTrackingCard() => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _vm.isTracking
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _vm.isTracking
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
              color: _vm.isTracking
                  ? const Color(0xFF4CAF50)
                  : AppColors.textLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share Live Location',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark)),
                Text(
                  _vm.isTracking
                      ? 'Customer can see your location'
                      : 'Tap to start sharing',
                  style: TextStyle(
                    fontSize: 11,
                    color: _vm.isTracking
                        ? const Color(0xFF4CAF50)
                        : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _vm.isTracking,
            activeColor: const Color(0xFF4CAF50),
            onChanged: (on) {
              if (on) {
                _vm.startTracking(widget.job.ticketId);
              } else {
                _vm.stopTracking();
              }
            },
          ),
        ]),
        if (_vm.isTracking) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text('Broadcasting location every 5 seconds',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ]),
        ],
      ],
    ),
  );

  // ── Description card ──────────────────────────────────────────────────────

  Widget _buildDescriptionCard() => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Description',
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text(widget.job.subject,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey,
                height: 1.5)),
      ],
    ),
  );

  // ── Resolve section ───────────────────────────────────────────────────────

  Widget _buildResolveSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Toggle note input
      GestureDetector(
        onTap: () => setState(() => _showNote = !_showNote),
        child: Row(children: [
          const Text('Add resolution note (optional)',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const Spacer(),
          Icon(
            _showNote ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGrey,
          ),
        ]),
      ),
      if (_showNote) ...[
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'What was done to fix the issue…',
            hintStyle: const TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
      const SizedBox(height: 16),
      _ResolveButton(
        loading: _vm.resolving,
        onResolve: () => _confirmResolve(),
      ),
    ],
  );

  // ── Confirm dialog ────────────────────────────────────────────────────────

  Future<void> _confirmResolve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Resolved?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will close the ticket and notify the customer. '
            'Make sure the issue is fully fixed before confirming.',
            style: TextStyle(color: AppColors.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resolve',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _vm.resolveJob(
        widget.job.ticketId,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );
    }
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
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
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: AppColors.textGrey),
    const SizedBox(width: 6),
    Text(label,
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
  ]);
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (priority) {
      case 'high':   color = const Color(0xFFE53935); break;
      case 'medium': color = const Color(0xFFFB8C00); break;
      default:       color = const Color(0xFF43A047);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style: const TextStyle(
                fontSize: 12, color: AppColors.primary)),
      ),
    ]),
  );
}

class _ResolveButton extends StatelessWidget {
  final bool         loading;
  final VoidCallback onResolve;
  const _ResolveButton({required this.loading, required this.onResolve});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onResolve,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: loading ? AppColors.textLight : AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: loading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Mark as Resolved',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
      ),
    ),
  );
}
