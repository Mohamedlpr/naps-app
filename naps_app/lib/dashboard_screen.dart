import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.tasks,
    required this.tickets,
    required this.announcements,
    required this.user,
    required this.selectPage,
    required this.refresh,
  });
  final List<WorkTask> tasks;
  final List<SupportTicket> tickets;
  final List<TeamAnnouncement> announcements;
  final AppUser user;
  final ValueChanged<int> selectPage;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) {
    final openTasks = tasks.where((task) => !task.complete).length;
    final waitingTickets = tickets
        .where((ticket) => ticket.status != 'resolved')
        .length;
    final pendingAnnouncements = announcements
        .where(
          (announcement) => !announcement.acknowledgedUserIds.contains(user.id),
        )
        .length;
    final nextTasks = tasks.where((task) => !task.complete).take(3).toList();
    final latestAnnouncement = announcements.isEmpty
        ? null
        : announcements.first;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageHeading(
          title: 'مساحة العمل',
          subtitle:
              '${user.branch}  ·  ${_weekdayName(DateTime.now().weekday)}، ${DateTime.now().day} ${_monthName(DateTime.now().month)}',
          action: IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${user.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 9),
                const Text(
                  'عمل الفريق، في مكان واحد.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'تابع المسؤوليات والطلبات والإعلانات المشتركة مع زملائك.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _metric(
                  'مهام مفتوحة',
                  '$openTasks',
                  Icons.checklist_outlined,
                  () => selectPage(1),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _metric(
                  'طلبات قيد المتابعة',
                  '$waitingTickets',
                  Icons.support_agent_outlined,
                  () => selectPage(2),
                ),
              ),
            ],
          ),
        ),
        if (pendingAnnouncements > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 9, 20, 0),
            child: SurfacePanel(
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لديك $pendingAnnouncements إعلاناً لم تقرأه بعد.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => selectPage(3),
                    child: const Text('عرض'),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: SectionTitle(
            'مهام قريبة من موعدها',
            actionLabel: 'كل المهام',
            onAction: () => selectPage(1),
          ),
        ),
        if (nextTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SurfacePanel(child: Text('لا توجد مهام مفتوحة.')),
          )
        else
          ...nextTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SurfacePanel(
                child: Row(
                  children: [
                    const Icon(Icons.circle_outlined, color: green, size: 20),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'المسؤول: ${task.assigneeName}  ·  الموعد: ${arabicDate(task.dueDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: SectionTitle(
            'آخر إعلان',
            actionLabel: 'كل الإعلانات',
            onAction: () => selectPage(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: latestAnnouncement == null
              ? const SurfacePanel(
                  child: Text('لا توجد إعلانات من إدارة المؤسسة.'),
                )
              : SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestAnnouncement.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        latestAnnouncement.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نُشر بواسطة ${latestAnnouncement.creatorName} · ${arabicDate(latestAnnouncement.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: muted, height: 1.6),
          ),
        ],
      ),
    ),
  );

  String _monthName(int month) => const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ][month - 1];
  String _weekdayName(int weekday) => const [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ][weekday - 1];
}
