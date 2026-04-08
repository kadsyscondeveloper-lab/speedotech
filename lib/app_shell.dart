// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/my_jobs_viewmodel.dart';
import 'viewmodels/open_jobs_viewmodel.dart';
import 'views/jobs/my_jobs_screen.dart';
import 'views/jobs/support_jobs_screen.dart';
import 'views/jobs/open_jobs_screen.dart';
import 'theme/app_theme.dart';
import 'services/tech_auth_service.dart';
import 'core/storage_service.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // ViewModels live here so their state survives tab switches
  late final MyJobsViewModel   _myJobsVM;
  late final OpenJobsViewModel _openJobsVM;

  @override
  void initState() {
    super.initState();
    _myJobsVM   = MyJobsViewModel();
    _openJobsVM = OpenJobsViewModel();
  }

  @override
  void dispose() {
    _myJobsVM.dispose();
    _openJobsVM.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize:     Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TechAuthService().logout();
    widget.onLogout();
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ChangeNotifierProvider.value(
          value: _myJobsVM,
          child: const MyJobsScreen(),
        );
      case 1:
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _openJobsVM),
            // Provide MyJobsVM so OpenJobsScreen can refresh it after assign
            ChangeNotifierProvider.value(value: _myJobsVM),
          ],
          child: const OpenJobsScreen(),
        );
      case 2:
        return _ProfileTab(onLogout: _confirmLogout);

      case 3:
        return const SupportJobsScreen();
      default:
        return ChangeNotifierProvider.value(
          value: _myJobsVM,
          child: const MyJobsScreen(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body:       _buildBody(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap:        (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int          currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    {'icon': Icons.work_outline,   'iconActive': Icons.work,   'label': 'My Jobs'},
    {'icon': Icons.search_outlined, 'iconActive': Icons.search, 'label': 'Open Jobs'},
    {'icon': Icons.person_outline,  'iconActive': Icons.person, 'label': 'Profile'},
    {'icon': Icons.support_outlined, 'iconActive': Icons.support, 'label':"Support Jobs"}
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 64 + bottomPad,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item     = _items[i];
            final isActive = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap:    () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isActive
                            ? item['iconActive'] as IconData
                            : item['icon']       as IconData,
                        key:   ValueKey(isActive),
                        color: isActive ? AppColors.primary : AppColors.textLight,
                        size:  24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color:      isActive ? AppColors.primary : AppColors.textLight,
                        fontSize:   10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final name       = storage.techName       ?? 'Technician';
    final phone      = storage.techPhone      ?? '';
    final employeeId = storage.techEmployeeId ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              top:    MediaQuery.of(context).padding.top + 24,
              left:   20,
              right:  20,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(children: [
              Container(
                width:  80,
                height: 80,
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.2),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.engineering_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 14),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(employeeId.isNotEmpty ? 'EMP-$employeeId' : phone,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ]),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ProfileTile(
                icon:  Icons.phone_outlined,
                title: 'Phone',
                value: phone.isNotEmpty ? '+91 $phone' : '—',
              ),
              const SizedBox(height: 8),
              _ProfileTile(
                icon:  Icons.badge_outlined,
                title: 'Employee ID',
                value: employeeId.isNotEmpty ? employeeId : '—',
              ),
              const SizedBox(height: 24),

              // Logout
              SizedBox(
                width:  double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon:  const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),

              const SizedBox(height: 100), // bottom nav clearance
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   value;
  const _ProfileTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2)),
      ],
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      ]),
    ]),
  );
}
