import 'package:flutter/material.dart';
import 'api_client.dart';
import 'app_models.dart';
import 'announcements_screen.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'team_screen.dart';
import 'tickets_screen.dart';
import 'app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.apiClient,
    required this.user,
    required this.onLogout,
  });
  final ApiClient apiClient;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  bool loading = true;
  String? errorMessage;
  List<WorkTask> tasks = [];
  List<SupportTicket> tickets = [];
  List<TeamAnnouncement> announcements = [];
  List<TeamMember> members = [];

  @override
  void initState() {
    super.initState();
    loadWorkspace();
  }

  Future<void> loadWorkspace() async {
    if (mounted)
      setState(() {
        loading = true;
        errorMessage = null;
      });
    try {
      final results = await Future.wait([
        widget.apiClient.getTasks(),
        widget.apiClient.getTickets(),
        widget.apiClient.getAnnouncements(),
        widget.apiClient.getUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        tasks = results[0] as List<WorkTask>;
        tickets = results[1] as List<SupportTicket>;
        announcements = results[2] as List<TeamAnnouncement>;
        members = results[3] as List<TeamMember>;
        loading = false;
      });
    } on ApiException catch (error) {
      if (mounted)
        setState(() {
          errorMessage = error.message;
          loading = false;
        });
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
      await loadWorkspace();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (errorMessage != null)
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42, color: muted),
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: loadWorkspace,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                  TextButton(
                    onPressed: logout,
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

    final pages = [
      DashboardScreen(
        tasks: tasks,
        tickets: tickets,
        announcements: announcements,
        user: widget.user,
        selectPage: selectPage,
        refresh: loadWorkspace,
      ),
      TasksScreen(
        tasks: tasks,
        members: members,
        user: widget.user,
        createTask: (values) => perform(() async {
          await widget.apiClient.createTask(values);
        }),
        updateTask: (id, values) => perform(() async {
          await widget.apiClient.updateTask(id, values);
        }),
        deleteTask: (id) => perform(() async {
          await widget.apiClient.deleteTask(id);
        }),
      ),
      TicketsScreen(
        tickets: tickets,
        user: widget.user,
        createTicket: (values) => perform(() async {
          await widget.apiClient.createTicket(values);
        }),
        updateTicket: (id, values) => perform(() async {
          await widget.apiClient.updateTicket(id, values);
        }),
        deleteTicket: (id) => perform(() async {
          await widget.apiClient.deleteTicket(id);
        }),
      ),
      AnnouncementsScreen(
        announcements: announcements,
        user: widget.user,
        createAnnouncement: (values) => perform(() async {
          await widget.apiClient.createAnnouncement(values);
        }),
        acknowledge: (id) => perform(() async {
          await widget.apiClient.acknowledgeAnnouncement(id);
        }),
        deleteAnnouncement: (id) => perform(() async {
          await widget.apiClient.deleteAnnouncement(id);
        }),
      ),
      TeamScreen(
        members: members,
        user: widget.user,
        createUser: (values) => perform(() async {
          await widget.apiClient.createUser(values);
        }),
        updateUser: (id, values) => perform(() async {
          await widget.apiClient.updateUser(id, values);
        }),
        changePassword: (current, next) => perform(() async {
          await widget.apiClient.changePassword(current, next);
        }),
        onLogout: logout,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: selectPage,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE7F0E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'الطلبات',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'الإعلانات',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'الفريق',
          ),
        ],
      ),
    );
  }

  void selectPage(int index) => setState(() => selectedIndex = index);

  Future<void> logout() async {
    await widget.apiClient.logout();
    widget.onLogout();
  }
}
