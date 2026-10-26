import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({
    super.key,
    required this.announcements,
    required this.user,
    required this.createAnnouncement,
    required this.acknowledge,
    required this.deleteAnnouncement,
  });
  final List<TeamAnnouncement> announcements;
  final AppUser user;
  final Future<void> Function(Map<String, dynamic>) createAnnouncement;
  final Future<void> Function(String) acknowledge;
  final Future<void> Function(String) deleteAnnouncement;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeading(
        title: 'إعلانات المؤسسة',
        subtitle: 'التوجيهات والمعلومات المنشورة لفريقك',
        action: user.role == 'employee'
            ? null
            : IconButton(
                tooltip: 'إعلان جديد',
                onPressed: () => create(context),
                icon: const Icon(Icons.add),
              ),
      ),
      Expanded(
        child: announcements.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'لا توجد إعلانات حتى الآن.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: announcements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  final hasAcknowledged = announcement.acknowledgedUserIds
                      .contains(user.id);
                  return SurfacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (user.role == 'admin')
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete')
                                    deleteAnnouncement(announcement.id);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('حذف الإعلان'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          announcement.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'نشره ${announcement.creatorName}  ·  ${arabicDate(announcement.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!hasAcknowledged)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: () => acknowledge(announcement.id),
                              icon: const Icon(Icons.done, size: 18),
                              label: const Text('تم الاطلاع'),
                            ),
                          )
                        else
                          const Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              'تم الاطلاع',
                              style: TextStyle(
                                color: green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );

  Future<void> create(BuildContext context) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AnnouncementFormDialog(),
    );
    if (values != null) await createAnnouncement(values);
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog();

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إعلان جديد'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'اكتب عنواناً واضحاً'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'نص الإعلان'),
              minLines: 4,
              maxLines: 7,
              validator: (value) => value == null || value.trim().length < 3
                  ? 'أدخل نص الإعلان'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'title': titleController.text.trim(),
            'message': messageController.text.trim(),
          });
        },
        child: const Text('نشر'),
      ),
    ],
  );
}
